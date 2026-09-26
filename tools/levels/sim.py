"""Runs the Spark through a level with every moving object, and searches for a
route from start to goal. A route it finds is a proof: every frame of it was
simulated with the game's real movement numbers."""
import heapq
import math
from dataclasses import dataclass, replace

import physics as P
from physics import Body, TILE, DT, HALF_W, HALF_H
from levelkit import ROWS, SOLID, ONE_WAY, CHANNEL, BUMPABLE, Objects

EPS = 0.001
RING_LIFT = 300.0   # a lift ring refills dash and pops you about 3 tiles upward


@dataclass(frozen=True)
class Run:
    body: Body
    t: int = 0
    loose: tuple = ()        # ((c, r), trigger_frame)
    debris: tuple = ()       # (index, trigger_frame)
    droppers: tuple = ()     # (index, trigger_frame)
    plates: tuple = ()       # (plate index, first_press_frame, last_press_frame)
    killed: frozenset = frozenset()
    ring_used: tuple = ()    # (ring index, frame)
    lever: int = -1
    stomp_chain: int = 0
    boarded: tuple = ()      # (mover index, frame) for girders that start when ridden
    toggles: int = 0         # channel switch bumps so far
    fuses: frozenset = frozenset()    # blown fuse cells
    relay_down: int = -1     # frame the relay went down
    pending: frozenset = frozenset()  # channel blocks the Spark is inside; solid once it leaves
    dead: str = ''
    won: bool = False


def has_channels(world):
    """True if the level has channel blocks (cached on the world)."""
    if not hasattr(world, '_has_channel'):
        world._has_channel = any(ch in world.L.grid[r] for ch in CHANNEL for r in range(world.L.rows))
    return world._has_channel


class World:
    def __init__(self, level):
        self.L = level
        self.o = Objects(level)
        self.run = None
        goals = level.find('G')
        self.goal = goals[0] if goals else (level.width, 0)
        self.lever_cells = level.find('K')
        self.warden = level.find('W')[:1]
        self.bumped = []

    # --- solidity ------------------------------------------------------
    def loose_state(self, cell, t):
        for c, f in self.run.loose:
            if c == cell:
                return 'fallen' if t >= f + 21 else 'shaking'
        return 'still'

    def gate_open(self, g, t):
        for i, first, last in self.run.plates:
            if i == g['plate']:
                if t < first + 15:
                    return False
                if g['open'] == 0.0:
                    return True
                return t <= last + int(g['open'] * 60)
        return False

    def channel(self, t, run=None):
        """0 while channel ONE is live, 1 for TWO. A running relay swaps them on its
        clock. Once it is down the channel stays where it was. Otherwise the
        switches decide."""
        run = run or self.run
        rl = self.o.relay
        if rl:
            n = int(rl['period'] * 60)
            return ((t if run.relay_down < 0 else run.relay_down) // n) % 2
        return run.toggles % 2

    def solid(self, c, r, t):
        ch = self.L.at(c, r)
        if ch in CHANNEL:
            return CHANNEL[ch] == self.channel(t) and (c, r) not in self.run.pending
        if ch == 'L':
            return self.loose_state((c, r), t) != 'fallen'
        if ch == 'Z':
            return self.run.lever < 0 or t < self.run.lever + 18 + 4 * abs(c - self.lever_cells[0][0])
        if ch == '|':
            g = self.gate_for(c, r)
            if g.get('relay'):
                return not (self.run.relay_down >= 0 and t >= self.run.relay_down + 15)
            return not self.gate_open(g, t)
        return ch in SOLID

    def gate_for(self, c, r):
        for g in self.o.gates:
            if g['x'] == c * TILE and g['y'] <= r * TILE < g['y'] + g['h']:
                return g

    def dropper_y(self, d, t):
        trig = next((f for i, f in self.run.droppers if i == d['i']), None)
        if trig is None or t < trig + 15:
            return d['y'], False
        s = t - trig - 15
        y, vy, n = d['y'], 0.0, 0
        while n < s and y < d['y1']:
            vy = min(420.0, vy + 1400.0 * DT)
            y = min(d['y1'], y + vy * DT)
            n += 1
        if y < d['y1']:
            return y, True
        s -= n + 90  # waits 1.5 s on the floor
        if s <= 0:
            return d['y1'], False
        return max(d['y'], d['y1'] - 50.0 * DT * s), False

    def board_time(self, i):
        return next((f for k, f in self.run.boarded if k == i), None)

    def mover_rect(self, m, t):
        """start=ride girders wait at their start until stood on, then make one
        trip and stop at the far end."""
        if m.get('start') != 'ride':
            return self.o.mover_rect(m, t)
        tb = self.board_time(m['i'])
        u = 0.0 if tb is None else min(1.0, (t - tb) * DT / (m['period'] / 2))
        u = 0.5 - 0.5 * math.cos(math.pi * u)
        return (m['x'] + u * m['dx'] * TILE, m['y'] + u * m['dy'] * TILE, m['w'], 6.0)

    def press_y(self, p, t):
        """sync=<mover> presses rest until that girder is boarded, then run
        their cycle from the boarding moment."""
        if 'sync' not in p:
            return self.o.press_y(p, t)
        tb = self.board_time(int(str(p['sync']).lstrip('m')))
        return p['y0'] if tb is None else self.o.press_y(p, t - tb)

    def rects(self, t):
        """Moving solids: (x, y, w, h, one_way)."""
        out = []
        for m in self.o.movers:
            x, y, w, h = self.mover_rect(m, t)
            out.append((x, y, w, h, True, ('m', m['i'])))
        for d in self.o.droppers:
            y, _ = self.dropper_y(d, t)
            out.append((d['x'], y, 2 * TILE, 2 * TILE, False, ('d', d['i'])))
        return out

    # --- movement --------------------------------------------------------
    def move(self, x, y, vx, vy):
        t = self.run.t + 1
        floor = on_wall = False
        wall_dir, wall_top = 0, 0.0
        nx = x + vx * DT
        top, bot = y - HALF_H, y + HALF_H - EPS
        if vx != 0:
            lead = nx + (HALF_W if vx > 0 else -HALF_W)
            c = math.floor((lead - (EPS if vx > 0 else 0)) / TILE)
            for r in range(math.floor(top / TILE), math.floor(bot / TILE) + 1):
                if self.solid(c, r, t):
                    nx = c * TILE - HALF_W if vx > 0 else (c + 1) * TILE + HALF_W
                    on_wall, wall_dir = True, (1 if vx > 0 else -1)
                    rr = r
                    while self.solid(c, rr - 1, t):
                        rr -= 1
                    wall_top = rr * TILE
                    vx = 0.0
                    break
            for (rx, ry, rw, rh, one_way, _) in self.rects(t):
                if one_way or not (top < ry + rh and bot > ry):
                    continue
                if vx > 0 and x + HALF_W <= rx + EPS and nx + HALF_W > rx:
                    nx, vx, on_wall, wall_dir, wall_top = rx - HALF_W, 0.0, True, 1, ry
                elif vx < 0 and x - HALF_W >= rx + rw - EPS and nx - HALF_W < rx + rw:
                    nx, vx, on_wall, wall_dir, wall_top = rx + rw + HALF_W, 0.0, True, -1, ry
        ny = y + vy * DT
        left, right = nx - HALF_W, nx + HALF_W - EPS
        cols = range(math.floor(left / TILE), math.floor(right / TILE) + 1)
        if vy > 0:
            r = math.floor((ny + HALF_H) / TILE)
            prev_feet = y + HALF_H
            for c in cols:
                ch = self.L.at(c, r)
                if self.solid(c, r, t) or (ch in ONE_WAY and prev_feet <= r * TILE + EPS):
                    ny, vy, floor = r * TILE - HALF_H, 0.0, True
                    break
            for (rx, ry, rw, rh, one_way, _) in self.rects(t):
                if right > rx and left < rx + rw and prev_feet <= ry + 4 and ny + HALF_H >= ry:
                    ny, vy, floor = ry - HALF_H, 0.0, True
        elif vy < 0:
            r = math.floor((ny - HALF_H) / TILE)
            for c in cols:
                if self.solid(c, r, t):
                    self.bumped.append((c, r))
                    ny, vy = (r + 1) * TILE + HALF_H, 0.0
                    break
        return nx, ny, floor, on_wall, wall_dir, wall_top, vx, vy

    # --- one frame of everything ----------------------------------------
    def on_girder_only(self, x, y):
        """Everything under the feet is thin girder: nothing solid, not a moving girder."""
        t = self.run.t
        r = math.floor((y + HALF_H + 1.0) / TILE)
        cols = range(math.floor((x - HALF_W) / TILE), math.floor((x + HALF_W - EPS) / TILE) + 1)
        if any(self.solid(c, r, t) for c in cols) or not any(self.L.at(c, r) in ONE_WAY for c in cols):
            return False
        return not any(x + HALF_W > rx and x - HALF_W < rx + rw and abs(y + HALF_H - ry) < 1.5
                       for (rx, ry, rw, rh, _, _) in self.rects(t))

    def advance(self, run, dir_, jump, dash, down=False):
        self.run = run
        b = run.body
        t = run.t
        # carried by a moving girder or a rising dropper
        if b.floor:
            for (rx, ry, rw, rh, _, key) in self.rects(t):
                if b.x + HALF_W > rx and b.x - HALF_W < rx + rw and abs(b.y + HALF_H - ry) < 1.5:
                    m = self.o.movers[key[1] - 1] if key[0] == 'm' else None
                    if m and m.get('start') == 'ride' and self.board_time(m['i']) is None:
                        run = replace(run, boarded=run.boarded + ((m['i'], t),))
                        self.run = run
                    nx, ny, *_ = next(r for r in self.rects(t + 1) if r[5] == key)
                    b = replace(b, x=b.x + nx - rx, y=b.y + ny - ry)
        self.bumped = []
        nb = P.step(b, dir_, jump, dash, self, down)
        t += 1
        run = replace(run, body=nb, t=t)
        self.run = run
        return self.after_move(run)

    def after_move(self, run):
        b, t, L, o = run.body, run.t, self.L, self.o
        px0, py0, px1, py1 = b.x - HALF_W, b.y - HALF_H, b.x + HALF_W, b.y + HALF_H

        def hit(x0, y0, x1, y1):
            return px0 < x1 and px1 > x0 and py0 < y1 and py1 > y0

        changes = {}
        # blocks struck from below: switches, fuses, and any enemy standing on top
        killed = set(run.killed)
        toggles, fuses = run.toggles, set(run.fuses)
        for cell in self.bumped:
            ch = L.at(*cell)
            if ch == 'Y':
                toggles += 1
            elif ch == 'Q':
                fuses.add(cell)
            if ch in BUMPABLE:
                for n in range(len(o.walkers)):
                    wx, wy = self.walker_xy(n, t)
                    if n not in killed and abs(wx - (cell[0] * TILE + 8)) < 12 and abs(wy - cell[1] * TILE) < 2:
                        killed.add(n)
        if toggles != run.toggles:
            changes['toggles'] = toggles
        if len(fuses) != len(run.fuses):
            changes['fuses'] = frozenset(fuses)
            if o.relay and len(fuses) == len(o.fuses) and run.relay_down < 0:
                changes['relay_down'] = t
        # channel blocks the Spark is inside when they turn solid stay open until it leaves
        if has_channels(self):
            nxt = replace(run, toggles=toggles, relay_down=changes.get('relay_down', run.relay_down))
            live_next, live_now = self.channel(t + 1, nxt), self.channel(t, run)
            pend = set()
            for c in range(math.floor(px0 / TILE), math.floor((px1 - EPS) / TILE) + 1):
                for r in range(math.floor(py0 / TILE), math.floor((py1 - EPS) / TILE) + 1):
                    ch = L.at(c, r)
                    if ch in CHANNEL and CHANNEL[ch] == live_next and \
                            ((c, r) in run.pending or CHANNEL[ch] != live_now):
                        pend.add((c, r))
            if pend != set(run.pending):
                changes['pending'] = frozenset(pend)
        # loose floors: triggered by standing on them
        if b.floor:
            r = math.floor((b.y + HALF_H + 1) / TILE)
            for c in range(math.floor(px0 / TILE), math.floor((px1 - EPS) / TILE) + 1):
                if L.at(c, r) == 'L' and all(cell != (c, r) for cell, _ in run.loose):
                    changes.setdefault('loose', list(run.loose)).append(((c, r), t))
        # a falling loose floor crushes the Spark if it comes down on top of it
        for cell, f in run.loose:
            fall = t - f - 21
            if 0 <= fall < o.loose_land[cell][0]:
                ly = cell[1] * TILE + 0.5 * P.GRAVITY * (fall * DT) ** 2
                if hit(cell[0] * TILE + 2, ly + 2, cell[0] * TILE + 14, ly + 14) and py0 > ly + 6:
                    return replace(run, dead='loose floor', **self._fix(changes))
        # plates: pressed by the Spark or by fallen loose floor
        plates = {i: [f, l] for i, f, l in run.plates}
        for p in o.plates:
            x0, y0 = p['c'] * TILE, p['r'] * TILE + TILE - 4
            pressed = b.floor and hit(x0, y0 - 2, x0 + TILE, y0 + 4)
            for cell, f in changes.get('loose', run.loose):
                frames, plate = o.loose_land[cell]
                if plate == p['i'] and t >= f + 21 + frames:
                    pressed = True
            if pressed:
                if p['i'] in plates:
                    plates[p['i']][1] = t
                else:
                    plates[p['i']] = [t, t]
        new_plates = tuple((i, f, l) for i, (f, l) in sorted(plates.items()))
        if new_plates != run.plates:
            changes['plates'] = new_plates
        # loose ceilings: triggered when the Spark passes under
        for d in o.debris:
            if abs(b.x - (d['x'] + 8)) < 20 and b.y > d['y'] and all(i != d['i'] for i, _ in run.debris):
                changes.setdefault('debris', list(run.debris)).append((d['i'], t))
        for i, f in run.debris:
            d = o.debris[i - 1]
            s = t - f - 24
            if s >= 0:
                y = d['y'] + 0.5 * P.GRAVITY * (s * DT) ** 2
                if y < d['land'] and hit(d['x'] + 2, y + 2, d['x'] + 14, y + 14):
                    return replace(run, dead='loose ceiling', **self._fix(changes))
        # droppers
        for d in o.droppers:
            if all(i != d['i'] for i, _ in run.droppers) and d['x'] - 8 < b.x < d['x'] + 40 and b.y > d['y']:
                changes.setdefault('droppers', list(run.droppers)).append((d['i'], t))
            y, falling = self.dropper_y(d, t)
            if falling and hit(d['x'], y, d['x'] + 32, y + 32) and b.y > y + 16:
                return replace(run, dead='dropper', **self._fix(changes))
        # static hazards
        c0, c1 = math.floor(px0 / TILE), math.floor((px1 - EPS) / TILE)
        r0, r1 = math.floor(py0 / TILE), math.floor((py1 - EPS) / TILE)
        for c in range(c0, c1 + 1):
            for r in range(r0, r1 + 1):
                ch = L.at(c, r)
                if ch == '^' and hit(c * TILE + 2, r * TILE + 6, c * TILE + 14, r * TILE + 16):
                    return replace(run, dead='spikes', **self._fix(changes))
                if ch == 'v' and hit(c * TILE + 2, r * TILE, c * TILE + 14, r * TILE + 10):
                    return replace(run, dead='spikes', **self._fix(changes))
        for v in o.vents:
            if o.vent_up(v, t) and hit(v['x'] + 2, v['y'] + 6, v['x'] + 14, v['y'] + 16):
                return replace(run, dead='spike vent', **self._fix(changes))
        for p in o.presses:
            y = self.press_y(p, t)
            if y > p['y0'] + 1 and hit(p['x'], p['y0'], p['x'] + TILE, y + TILE):
                return replace(run, dead='press', **self._fix(changes))
        # springs
        for sx, sy in o.springs:
            top = sy + 4
            if px1 > sx and px0 < sx + TILE and top - 10 < py1 < top + 26 and b.vy > -50:
                vy = -(P.SPRING_POWER + min(80.0, abs(b.vx) * 0.3))
                b = replace(b, vy=vy, spring_t=0.3, buffer=0.0, coyote=0.0)
        # dash rings
        used = dict(run.ring_used)
        for i, (rx, ry) in enumerate(o.rings):
            if (i not in used or t - used[i] > 120) and abs(b.x - rx) < 12 and abs(b.y - ry) < 12:
                used[i] = t
                b = replace(b, dash_ready=True, vy=min(b.vy, -RING_LIFT), spring_t=0.2)
                changes['ring_used'] = tuple(sorted(used.items()))
        # walkers, hoppers and spiked walkers
        chain = 0 if b.floor else run.stomp_chain
        for n, w in enumerate(o.walkers):
            if n in killed:
                continue
            wx, wy = self.walker_xy(n, t)
            if self.walker_dropped(run, wx, wy, t):
                killed.add(n)
                continue
            if abs(wx - b.x) > 40:
                continue
            if hit(wx - 7, wy - 18, wx + 7, wy):
                if w['kind'] == 'spiky':
                    return replace(run, dead='spiky', **self._fix(changes))
                if b.dash_t > 0:
                    killed.add(n)
                elif b.vy > 60 and (py1 - (wy - 18)) < 10:
                    killed.add(n)
                    chain += 1
                    vy = -(P.JUMP_VEL if b.held else P.STOMP_BOUNCE) - 40 * (chain - 1)
                    b = replace(b, vy=vy, floor=False)
                else:
                    return replace(run, dead='walker', **self._fix(changes))
        if killed != set(run.killed):
            changes['killed'] = frozenset(killed)
        changes['stomp_chain'] = chain
        # warden
        if self.warden and (run.lever < 0 or t < run.lever + 30):
            wx, wy = self.warden_pos(t)
            if hit(wx + 2, wy + 2, wx + 30, wy + 32):
                return replace(run, dead='warden', **self._fix(changes))
        # lever
        for c, r in self.lever_cells:
            if run.lever < 0 and hit(c * TILE, r * TILE, c * TILE + TILE, r * TILE + TILE):
                changes['lever'] = t
        # goal mast: 5 tiles tall above the base
        gc, gr = self.goal
        if gc < L.width and hit(gc * TILE + 4, (gr - 5) * TILE, gc * TILE + 12, gr * TILE + TILE):
            return replace(run, body=b, won=True, **self._fix(changes))
        if b.y > L.rows * TILE + 24:
            return replace(run, dead='fell', **self._fix(changes))
        return replace(run, body=b, **self._fix(changes))

    def walker_xy(self, n, t):
        w, path = self.o.walkers[n], self.o.walker_paths[n]
        wx, wy = path[min(t, len(path) - 1)], w['y']
        if w['kind'] == 'hopper':
            s = (t % 96) * DT
            wy -= max(0.0, 220 * s - 0.5 * P.GRAVITY * s * s) if s < 0.48 else 0.0
        return wx, wy

    def walker_dropped(self, run, wx, wy, t):
        """A walker is lost when the floor under it falls away, or when something
        heavy lands on it: a falling loose floor, a press, a dropper or a loose
        ceiling chunk."""
        def on(x0, y0, x1, y1):
            return wx - 7 < x1 and wx + 7 > x0 and wy - 18 < y1 and wy > y0
        for p in self.o.presses:
            y = self.press_y(p, t)
            if y > p['y0'] + 1 and on(p['x'], p['y0'], p['x'] + TILE, y + TILE):
                return True
        for d in self.o.droppers:
            y, falling = self.dropper_y(d, t)
            if falling and on(d['x'], y, d['x'] + 32, y + 32):
                return True
        for i, f in run.debris:
            d = self.o.debris[i - 1]
            s = t - f - 24
            if s >= 0:
                y = d['y'] + 0.5 * P.GRAVITY * (s * DT) ** 2
                if y < d['land'] and on(d['x'] + 2, y + 2, d['x'] + 14, y + 14):
                    return True
        c, r = int(wx // TILE), int(wy // TILE)
        ch = self.L.at(c, r)
        if ch == 'L' and self.loose_state((c, r), t) == 'fallen':
            return True
        if ch == 'Z' and not self.solid(c, r, t):
            return True
        for cell, f in run.loose:
            fall = t - f - 21
            if 0 <= fall < self.o.loose_land[cell][0]:
                ly = cell[1] * TILE + 0.5 * P.GRAVITY * (fall * DT) ** 2
                lx = cell[0] * TILE
                if wx - 7 < lx + 14 and wx + 7 > lx + 2 and wy - 18 < ly + 14 and wy > ly + 2 and wy - 9 > ly + 8:
                    return True
        return False

    def warden_pos(self, t):
        c, r = self.warden[0]
        x0 = c * TILE
        lo = x0 - 5 * TILE
        hi = x0 + 3 * TILE
        span = hi - lo
        s = (t * 40.0 * DT) % (2 * span)
        x = lo + (s if s < span else 2 * span - s)
        hop = (t % 150) * DT
        y = r * TILE - (max(0.0, 250 * hop - 0.5 * P.GRAVITY * hop * hop) if hop < 0.55 else 0.0)
        return x, y

    @staticmethod
    def _fix(ch):
        out = {}
        for k, v in ch.items():
            out[k] = tuple(v) if isinstance(v, list) else v
        return out


# ------------------------------------------------------------------ search

ACTIONS = [(d, j, False) for d in (1, 0, -1) for j in (True, False)] + [(1, True, True), (1, False, True), (-1, True, True), (-1, False, True), (0, False, True)]
CHUNK = 4
WAIT = (0, False, False, 30)   # stand still for half a second, like a player waiting for a platform
DROP = (0, True, False, CHUNK, True)   # hold Down and jump: drop through a thin girder


def solve(level, start=None, max_nodes=250_000, weight=2.5, target=None, run0=None, until_col=None, stand=False,
          reach=None, tcycle=None, drop=False):
    """Search for a route to the goal mast, to touch `target` (c, r), or to stand
    past column `until_col`. `run0` continues from an earlier route's end state. `drop` lets the search use
    Down + jump to drop through girders (collectable checks only: the main route
    is replayed in Godot, whose route format has no Down)."""
    w = World(level)
    if run0 is None:
        sc, sr = start or level.find('P')[0]
        run0 = Run(Body(sc * TILE + 8, (sr + 1) * TILE - HALF_H - 0.5))
    run = run0
    if until_col is not None:
        target = (until_col, 0)
    gx = (target or w.goal)[0] * TILE + 8
    periods = [int(round(o['period'] * 4)) for o in w.o.movers + w.o.presses + w.o.vents
               + ([w.o.relay] if w.o.relay else [])]
    cycle = math.lcm(*periods) if periods else 1   # in quarter seconds
    if tcycle:   # also tell apart moments by time, so waiting for enemies to line up counts
        cycle = math.lcm(cycle, tcycle)

    def key(r):
        b = r.body
        tb = (r.t // 15) % cycle
        return (int(b.x // 3), int(b.y // 3), int(b.vx // 30), int(b.vy // 45), b.floor, b.dash_ready,
                b.held, b.dash_t > 0, tb, frozenset(c for c, _ in r.loose), r.plates and tuple(p[0] for p in r.plates),
                r.lever >= 0, len(r.debris), len(r.droppers), len(r.killed), r.boarded,
                r.toggles % 2, len(r.fuses), r.relay_down >= 0, r.pending)

    # when aiming at a cell (not a column), height counts too: tall levels hide
    # shards and waypoints above or below the Spark
    gy = target[1] * TILE + 8 if target is not None and until_col is None else None

    def h(r):
        dx = max(0.0, abs(gx - r.body.x) - 8) / P.MAX_RUN * 60
        if gy is None:
            return dx
        return max(dx, max(0.0, abs(gy - r.body.y) - 8) / 250.0 * 60)

    frontier = [(h(run) * weight, 0, run, None)]
    parents = {}
    seen = {key(run)}
    best = run
    n = 0
    counter = 1
    while frontier and n < max_nodes:
        _, _, cur, _ = heapq.heappop(frontier)
        n += 1
        if abs(cur.body.x - gx) < abs(best.body.x - gx):
            best = cur
        acts = ACTIONS + [WAIT] if cur.body.floor else ACTIONS
        if drop and cur.body.floor:
            acts = acts + [DROP]
        for a in acts:
            d, j, dash = a[:3]
            if dash and (not cur.body.dash_ready or cur.body.dash_t > 0):
                continue
            nxt = cur
            frames = []
            for f in range(a[3] if len(a) > 3 else CHUNK):
                nxt = w.advance(nxt, d, j, dash and f == 0, len(a) > 4 and f == 0)
                frames.append((nxt.body.x, nxt.body.y))
                if nxt.dead or nxt.won:
                    break
            if nxt.dead:
                continue
            k = key(nxt)
            if k in seen and not nxt.won:
                continue
            seen.add(k)
            parents[id(nxt)] = (cur, a, frames)
            if reach is not None:
                done = reach(nxt.body.x, nxt.body.y)
            elif until_col is not None:
                done = nxt.won or (nxt.body.floor and nxt.body.x - HALF_W >= until_col * TILE)
            else:
                done = (nxt.won and not target) or (target and touches(nxt.body, target) and (nxt.body.floor or not stand))
            if done:
                return trace(nxt, parents), n, True
            heapq.heappush(frontier, (nxt.t + weight * h(nxt), counter, nxt, None))
            counter += 1
    return trace(best, parents), n, False


def touches(b, cell):
    """True when the Spark overlaps the pickup box of a shard in `cell` (the game's
    box is inset 3 px from the tile), so a touch here is a real pickup."""
    c, r = cell
    return b.x + HALF_W > c * TILE + 3 and b.x - HALF_W < c * TILE + 13 and \
        b.y + HALF_H > r * TILE + 3 and b.y - HALF_H < r * TILE + 13


def trace(run, parents):
    path = []
    while id(run) in parents:
        prev, a, frames = parents[id(run)]
        path.append((a, frames, run))
        run = prev
    path.reverse()
    return path
