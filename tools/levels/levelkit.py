"""Level file format, tile world and moving-object rules for WHITE SIGNAL.

A level file is a header, then one or more screens of 17 rows each, then an
optional [objects] section. Screens are joined left to right. The legend and the
object rules here are the specification the Godot loader must follow.
"""
import math
import re
from dataclasses import dataclass, field

from physics import TILE, DT, HALF_W, HALF_H, GRAVITY, MAX_FALL

ROWS = 17   # one screen; a level may be any whole number of rows tall

LEGEND = {
    '.': 'empty',
    '#': 'ground',
    '=': 'block',
    '-': 'girder (one-way, stand on top, jump up through)',
    '?': 'bump block: shard',
    'C': 'bump block: CHARGE power-up',
    'U': 'bump block: extra life',
    'h': 'hidden block: extra life (invisible until bumped)',
    'i': 'hidden block: 5 shards (invisible until bumped)',
    'B': 'brick (breaks when bumped while charged)',
    'L': 'loose floor (shakes 0.35 s after you land, then falls)',
    'Z': 'bridge floor (collapses when the lever is pulled)',
    '^': 'spikes',
    'v': 'ceiling spikes',
    'T': 'spike vent (pops up on a clock)',
    'F': 'loose ceiling (drops a chunk when you pass under)',
    'X': 'press (slams down on a clock)',
    'D': 'dropper (2x2, falls when you pass under, rides back up)',
    'm': 'moving girder (a run of m is one platform)',
    '_': 'pressure plate',
    '|': 'gate (a column of | is one gate)',
    'K': 'lever',
    'S': 'spring',
    'R': 'lift ring (refills dash and pops you upward)',
    'o': 'shard',
    'O': 'Pip in glass (3 hidden per level; the rules still call it a big shard)',
    'w': 'walker',
    'k': 'hopper',
    'W': 'warden (world boss, 2x2)',
    'p': 'pipe (down to a bonus room)',
    'P': 'start',
    'M': 'midway beacon (checkpoint)',
    'G': 'goal mast (base tile)',
    # World 2
    '1': 'channel ONE block (solid while channel ONE is live, the start)',
    '2': 'channel TWO block (solid while channel TWO is live)',
    'Y': 'channel switch (bump from below to swap which channel is live)',
    's': 'spiked walker (cannot be stomped or dashed; crush it or bump it from below)',
    'Q': 'fuse (bump from below to blow it; blow them all to bring the relay down)',
    'E': 'relay (3x3 boss cabinet; swaps the channels on a clock while it runs)',
    # World 3
    'f': 'wave flyer (patrols in the air on a sine wave; stomp it) f#k range= amp= period= speed= dir=',
    '>': 'wind blowing right (pushes the Spark; with a gust: header it blows on a clock)',
    '<': 'wind blowing left',
    'u': 'updraft (lifts the Spark)',
    'A': 'sweep arm hub (solid; a bar of static turns around it) arm#k len= speed= start=',
    '%': 'cracked wall (solid; the Arc breaks it, so what is behind it is a secret, never the main route)',
    # look and feel only (the proofs ignore it)
    'J': 'lamp post (lights up when you pass; pushes back the dark)',
    # the village (look and talk only; nothing here is solid)
    'N': 'NPC (npc#k id=<who>; see levels/story/npcs.json)',
    'H': 'door (door#k to=<level> house=<facade> c= r= for where you come out; to=next is the next level)',
    'V': 'switchboard (pick any level you have reached)',
    'b': 'bench',
    'c': 'crate',
    'n': 'antenna mast',
    'g': 'signpost',
}

SOLID = set('#=?CUBLZpFYQEA%')
CHANNEL = {'1': 0, '2': 1}
BUMPABLE = set('?CUhiBYQ')   # blocks that knock out an enemy standing on them
ONE_WAY = set('-')
PERIODIC_DEFAULTS = {
    'X': {'period': 2.0, 'phase': 0.0},
    'T': {'period': 2.0, 'phase': 0.0},
    'm': {'period': 4.0, 'phase': 0.0, 'dx': 4.0, 'dy': 0.0},
}


@dataclass
class Level:
    name: str
    meta: dict
    grid: list          # list of strings, ROWS long
    screens: list       # (col0, width, title)
    overrides: dict     # "X#1" -> {key: value}
    rooms: dict = field(default_factory=dict)

    @property
    def width(self):
        return len(self.grid[0])

    @property
    def rows(self):
        return len(self.grid)

    def at(self, c, r):
        if r < 0:
            return '.'
        if c < 0 or c >= self.width or r >= self.rows:
            return '#' if (c < 0 or c >= self.width) and r >= 0 else '.'
        return self.grid[r][c]

    def find(self, ch):
        return [(c, r) for c in range(self.width) for r in range(self.rows) if self.grid[r][c] == ch]


def parse(path):
    text = open(path, encoding='utf-8').read().splitlines()
    meta, screens, overrides = {}, [], {}
    rows = []
    i = 0
    title = None
    block = []

    def flush():
        nonlocal block, title
        if not block:
            return
        if rows and len(block) != len(rows):
            raise ValueError(f'{path}: screen "{title}" has {len(block)} rows, needs {len(rows)}')
        if len(block) % ROWS:
            raise ValueError(f'{path}: screen "{title}" has {len(block)} rows, needs a multiple of {ROWS}')
        if not rows:
            rows.extend([''] * len(block))
        w = max(len(line) for line in block)
        block = [line.ljust(w, '.') for line in block]
        for line in block:
            bad = set(line) - set(LEGEND)
            if bad:
                raise ValueError(f'{path}: screen "{title}" has unknown tiles {bad}')
        col0 = len(rows[0])
        for n in range(len(block)):
            rows[n] += block[n]
        screens.append((col0, w, title))
        block = []

    section = 'head'
    for line in text:
        if line.startswith('== '):
            flush()
            title = line.strip('= ').strip()
            section = 'grid'
            continue
        if line.strip() == '[objects]':
            flush()
            section = 'objects'
            continue
        if section == 'head':
            if ':' in line and not line.startswith('#'):
                k, v = line.split(':', 1)
                meta[k.strip()] = v.strip()
        elif section == 'grid':
            if line.strip():
                block.append(line.rstrip('\n'))
        elif section == 'objects':
            m = re.match(r'^\s*(\w+#\d+)\s+(.*)$', line)
            if m:
                kv = dict(p.split('=') for p in m.group(2).split())
                overrides[m.group(1)] = {k: (float(v) if re.match(r'^-?[\d.]+$', v) else v) for k, v in kv.items()}
    flush()
    return Level(meta.get('name', path), meta, rows, screens, overrides)


# ---------------------------------------------------------------- objects

def runs(level, ch, horizontal=True):
    """Group contiguous tiles of `ch` into objects, numbered left to right."""
    seen, out = set(), []
    for c in range(level.width):
        for r in range(level.rows):
            if level.grid[r][c] != ch or (c, r) in seen:
                continue
            cells = []
            if horizontal:
                cc = c
                while cc < level.width and level.grid[r][cc] == ch:
                    cells.append((cc, r)); seen.add((cc, r)); cc += 1
            else:
                rr = r
                while rr < level.rows and level.grid[rr][c] == ch:
                    cells.append((c, rr)); seen.add((c, rr)); rr += 1
            out.append(cells)
    return out


def blocks2x2(level, ch):
    seen, out = set(), []
    for c in range(level.width):
        for r in range(level.rows):
            if level.grid[r][c] == ch and (c, r) not in seen:
                cells = [(c, r), (c + 1, r), (c, r + 1), (c + 1, r + 1)]
                for cell in cells:
                    seen.add(cell)
                out.append((c, r))
    return out


def blocks3x3(level, ch):
    seen, out = set(), []
    for c in range(level.width):
        for r in range(level.rows):
            if level.grid[r][c] == ch and (c, r) not in seen:
                for dc in range(3):
                    for dr in range(3):
                        seen.add((c + dc, r + dr))
                out.append((c, r))
    return out


def opts(level, key, defaults):
    d = dict(defaults)
    d.update(level.overrides.get(key, {}))
    return d


def floor_below(level, c, r):
    rr = r + 1
    while rr < level.rows and level.at(c, rr) not in SOLID:
        rr += 1
    return rr


class Objects:
    """Everything that moves or changes. Positions are pure functions of time
    plus the trigger times recorded in a run state, so the solver can branch."""

    def __init__(self, level):
        L = level
        self.level = L
        self.movers = []
        for i, cells in enumerate(runs(L, 'm'), 1):
            o = opts(L, f'm#{i}', PERIODIC_DEFAULTS['m'])
            c0, r0 = cells[0]
            self.movers.append({'i': i, 'x': c0 * TILE, 'y': r0 * TILE, 'w': len(cells) * TILE, **o})
        self.presses = []
        for i, (c, r) in enumerate(L.find('X'), 1):
            o = opts(L, f'X#{i}', PERIODIC_DEFAULTS['X'])
            bottom = (o['to'] + 1 if 'to' in o else floor_below(L, c, r)) * TILE
            self.presses.append({'i': i, 'x': c * TILE, 'y0': r * TILE, 'y1': bottom - TILE, **o})
        self.vents = []
        for i, (c, r) in enumerate(L.find('T'), 1):
            o = opts(L, f'T#{i}', PERIODIC_DEFAULTS['T'])
            self.vents.append({'i': i, 'x': c * TILE, 'y': r * TILE, **o})
        self.gates = []
        for i, cells in enumerate(runs(L, '|', horizontal=False), 1):
            o = opts(L, f'gate#{i}', {'open': 0.0, 'plate': i})
            c, r = cells[0]
            self.gates.append({'i': i, 'x': c * TILE, 'y': r * TILE, 'h': len(cells) * TILE, **o})
        self.plates = [{'i': i, 'c': c, 'r': r} for i, (c, r) in enumerate(L.find('_'), 1)]
        self.loose = {(c, r): i for i, (c, r) in enumerate(L.find('L'), 1)}
        self.loose_land = {}
        for (c, r) in self.loose:
            land = floor_below(L, c, r)
            # with no floor below (a pit), the piece falls off the bottom of the screen
            fall = (land - 1 - r) * TILE if land < L.rows else (L.rows + 1 - r) * TILE
            frames = fall_frames(fall)
            plate = next((p['i'] for p in self.plates if p['c'] == c and p['r'] < land and p['r'] > r), None)
            self.loose_land[(c, r)] = (frames, plate)
        self.debris = []
        for i, (c, r) in enumerate(L.find('F'), 1):
            land = floor_below(L, c, r)
            self.debris.append({'i': i, 'x': c * TILE, 'y': r * TILE, 'land': land * TILE})
        self.droppers = []
        for i, (c, r) in enumerate(blocks2x2(L, 'D'), 1):
            land = min(floor_below(L, c, r + 1), floor_below(L, c + 1, r + 1))
            self.droppers.append({'i': i, 'x': c * TILE, 'y': r * TILE, 'y1': land * TILE - 2 * TILE})
        self.springs = [(c * TILE, r * TILE) for (c, r) in L.find('S')]
        self.rings = [(c * TILE + 8, r * TILE + 8) for (c, r) in L.find('R')]
        self.walkers = []
        for ch, kind, speed in (('w', 'walker', 45.0), ('k', 'hopper', 45.0), ('s', 'spiky', 35.0),
                                ('f', 'flyer', 40.0)):
            for i, (c, r) in enumerate(L.find(ch), 1):
                o = opts(L, f'{ch}#{i}', dict({'speed': speed, 'dir': -1.0},
                                              **(FLYER_DEFAULTS if ch == 'f' else {})))
                self.walkers.append({'kind': kind, 'i': i, 'x': c * TILE + 8, 'y': (r + 1) * TILE, **o})
        self.walker_paths = [walker_path(L, w) for w in self.walkers]
        self.fuses = L.find('Q')
        relay = blocks3x3(L, 'E')
        self.relay = {'c': relay[0][0], 'r': relay[0][1], **opts(L, 'relay#1', {'period': 2.5})} if relay else None
        # World 3: sweep arms and gusts
        self.arms = []
        for i, (c, r) in enumerate(L.find('A'), 1):
            o = opts(L, f'arm#{i}', {'len': 4.0, 'speed': 90.0, 'start': 0.0})
            self.arms.append({'i': i, 'cx': c * TILE + 8, 'cy': r * TILE + 8, **o})
        g = str(L.meta.get('gust', '')).split(',')
        self.gust = (float(g[0]), float(g[1])) if len(g) == 2 else None

    def arm_dots(self, a, t):
        """Centres of a sweep arm's static balls: one every 8 px out from the hub."""
        ang = math.radians(a['start'] + a['speed'] * t * DT)
        return [(a['cx'] + math.cos(ang) * 8 * k, a['cy'] + math.sin(ang) * 8 * k)
                for k in range(1, int(a['len']) + 1)]

    def gust_on(self, t):
        """Wind tiles blow all the time, or with a `gust: period,on` header only
        for the first `on` seconds of every `period`."""
        if self.gust is None:
            return True
        return (t * DT) % self.gust[0] < self.gust[1]

    # periodic -----------------------------------------------------------
    def mover_rect(self, m, t):
        u = 0.5 - 0.5 * math.cos(2 * math.pi * (t * DT / m['period'] + m['phase']))
        return (m['x'] + u * m['dx'] * TILE, m['y'] + u * m['dy'] * TILE, m['w'], 6.0)

    def press_y(self, p, t):
        """Rest up, 0.3 s shake, slam in 0.12 s, hold 0.35 s, rise."""
        s = (t * DT / p['period'] + p['phase']) % 1.0 * p['period']
        rest = p['period'] - 0.12 - 0.35 - 0.6
        if s < rest:
            return p['y0']
        s -= rest
        if s < 0.12:
            return p['y0'] + (p['y1'] - p['y0']) * s / 0.12
        s -= 0.12
        if s < 0.35:
            return p['y1']
        s -= 0.35
        return p['y1'] - (p['y1'] - p['y0']) * s / 0.6

    def vent_up(self, v, t):
        s = (t * DT / v['period'] + v['phase']) % 1.0
        return s >= 0.6  # down 60 % of the cycle, up 40 %


def fall_frames(dist):
    y, vy, n = 0.0, 0.0, 0
    while y < dist:
        vy = min(MAX_FALL, vy + GRAVITY * DT)
        y += vy * DT
        n += 1
    return n


FLYER_DEFAULTS = {'range': 6.0, 'amp': 12.0, 'period': 2.0}


def walker_path(level, w, frames=60 * 700):
    """Walkers turn at walls and at ledges, so their route is a fixed loop. It is
    walked until the third turn, then that back-and-forth repeats, so a walker
    keeps moving for the longest level timer (600 s). A flyer ignores the ground
    and swings `range` tiles out from where it starts and back."""
    if w['kind'] == 'flyer':
        span = w['range'] * TILE
        if span <= 0:
            return [w['x']] * frames
        n = max(1, int(span / (w['speed'] * DT) + 0.5))   # frames for one leg
        return [w['x'] + w['dir'] * span * (1 - abs((k % (2 * n)) / n - 1)) for k in range(frames)]
    xs, turns = [], []
    x, d = w['x'], w['dir']
    row = int(w['y'] // TILE) - 1
    while len(xs) < frames:
        nx = x + d * w['speed'] * DT
        edge = nx + d * 7
        c = int(edge // TILE)
        wall = level.at(c, row) in SOLID or level.at(c, row) in '|'
        ground_under = level.at(c, row + 1) in SOLID or level.at(c, row + 1) in ONE_WAY
        if wall or not ground_under:
            d = -d
            turns.append(len(xs))
        else:
            x = nx
        xs.append(x)
        if len(turns) == 3:
            loop = xs[turns[0] + 1:turns[2] + 1]
            while len(xs) < frames:
                xs.extend(loop)
    return xs[:frames]
