"""Proves every level in levels/ and draws its design map.

    python tools/levels/build_maps.py            all levels
    python tools/levels/build_maps.py 1-2        one level

For each level the solver must finish it and reach every shard. Maps are
written next to the level files as <name>.png, with a <name>.proof.json report."""
import glob
import json
import os
import sys
import time

from PIL import Image, ImageDraw, ImageFont

import sim
from levelkit import parse, ROWS, LEGEND, Objects
from physics import TILE, HALF_W, HALF_H

ROOT = os.path.normpath(os.path.join(os.path.dirname(__file__), '..', '..'))
S = 2                  # map pixels per game pixel
T = TILE * S
STRIP = 60             # tiles per map row (two screens)
FONT = ImageFont.truetype('consola.ttf', 13)
FONT_B = ImageFont.truetype('consolab.ttf', 18)
FONT_S = ImageFont.truetype('consola.ttf', 10)

BG = (11, 11, 11)
GRID = (26, 26, 26)
DARK = (58, 58, 58)
GRAY = (138, 138, 138)
WHITE = (242, 242, 242)
HAZARD = (230, 72, 72)
ENEMY = (214, 92, 214)
ACT = (240, 176, 64)
PICK = (250, 226, 90)
GOOD = (96, 214, 120)
ROUTE = (80, 200, 240)
DASH = (255, 255, 255)


def draw_tile(d, x, y, ch, lvl, c, r):
    box = (x, y, x + T - 1, y + T - 1)
    cx, cy = x + T // 2, y + T // 2
    if ch == '#':
        above = lvl.at(c, r - 1)
        d.rectangle(box, fill=DARK)
        if above not in '#=':
            d.line((x, y, x + T - 1, y), fill=GRAY, width=3)
    elif ch == '=':
        d.rectangle(box, fill=(72, 72, 72), outline=(40, 40, 40))
        d.point([(x + 4, y + 4), (x + T - 5, y + 4), (x + 4, y + T - 5), (x + T - 5, y + T - 5)], fill=GRAY)
    elif ch == '-':
        d.rectangle((x, y, x + T - 1, y + 8), fill=GRAY)
    elif ch in '?CU':
        d.rectangle(box, fill=(90, 80, 40), outline=ACT, width=2)
        d.text((cx, cy), {'?': '?', 'C': 'C', 'U': '1UP'}[ch], font=FONT_S if ch == 'U' else FONT, fill=PICK, anchor='mm')
    elif ch in 'hi':
        d.rectangle(box, outline=ACT, width=1)
        d.text((cx, cy), ch, font=FONT, fill=ACT, anchor='mm')
    elif ch == 'B':
        d.rectangle(box, fill=(84, 60, 48), outline=(40, 30, 24))
        d.line((x, cy, x + T, cy), fill=(40, 30, 24))
        d.line((cx, y, cx, cy), fill=(40, 30, 24))
    elif ch == 'L':
        d.rectangle(box, fill=(96, 70, 40), outline=ACT)
        d.line((x + 6, y + 4, cx, cy, x + T - 8, y + T - 6), fill=BG, width=2)
    elif ch == 'Z':
        d.rectangle((x, y, x + T - 1, y + 10), fill=(110, 80, 50), outline=ACT)
    elif ch == 'F':
        d.rectangle(box, fill=DARK)
        d.polygon([(x + 6, y + T), (cx, y + T - 10), (x + T - 6, y + T)], fill=HAZARD)
    elif ch == '^':
        for i in range(2):
            d.polygon([(x + i * 16, y + T), (x + i * 16 + 8, y + 12), (x + i * 16 + 16, y + T)], fill=HAZARD)
    elif ch == 'v':
        for i in range(2):
            d.polygon([(x + i * 16, y), (x + i * 16 + 8, y + 20), (x + i * 16 + 16, y)], fill=HAZARD)
    elif ch == 'T':
        d.rectangle((x + 2, y + T - 6, x + T - 3, y + T - 1), fill=(90, 40, 40))
        for i in range(2):
            d.polygon([(x + i * 16 + 2, y + T - 6), (x + i * 16 + 8, y + 10), (x + i * 16 + 14, y + T - 6)], outline=HAZARD)
    elif ch == '_':
        d.rectangle((x + 2, y + T - 6, x + T - 3, y + T - 1), fill=ACT)
    elif ch == '|':
        for i in range(4):
            d.line((x + 5 + i * 7, y, x + 5 + i * 7, y + T), fill=ACT, width=2)
    elif ch == 'K':
        d.line((cx, y + T, cx + 8, y + 6), fill=ACT, width=3)
        d.ellipse((cx + 3, y + 1, cx + 13, y + 11), fill=ACT)
    elif ch == 'S':
        d.rectangle((x + 4, y + T - 10, x + T - 5, y + T - 1), fill=GOOD)
        d.line((x + 6, y + T - 14, x + T - 7, y + T - 14), fill=GOOD, width=3)
    elif ch == 'R':
        d.ellipse((x + 4, y + 4, x + T - 5, y + T - 5), outline=ROUTE, width=3)
    elif ch == 'o':
        d.polygon([(cx, cy - 7), (cx + 5, cy), (cx, cy + 7), (cx - 5, cy)], fill=PICK)
    elif ch == 'O':
        d.polygon([(cx, y + 1), (x + T - 2, cy), (cx, y + T - 2), (x + 1, cy)], fill=PICK, outline=WHITE)
        d.text((cx, cy), 'O', font=FONT_S, fill=BG, anchor='mm')
    elif ch in 'wk':
        d.rounded_rectangle((x + 3, y - 4, x + T - 4, y + T - 1), 4, fill=ENEMY)
        d.rectangle((cx + 2, y + 4, cx + 6, y + 10), fill=BG)
        if ch == 'k':
            d.text((cx - 4, cy + 4), 'k', font=FONT_S, fill=BG, anchor='mm')
    elif ch == 'p':
        d.rectangle((x, y, x + T - 1, y + T - 1), fill=(40, 90, 60), outline=GOOD, width=2)
    elif ch == 'P':
        d.rectangle((x + 10, y + 4, x + T - 10, y + T - 1), fill=WHITE)
    elif ch == 'M':
        d.line((cx, y - 20, cx, y + T), fill=GOOD, width=3)
        d.polygon([(cx, y - 20), (cx + 16, y - 14), (cx, y - 8)], fill=GOOD)
    elif ch == 'G':
        d.line((cx, y - 5 * T, cx, y + T), fill=GOOD, width=4)
        d.polygon([(cx, y - 5 * T), (cx - 20, y - 5 * T + 8), (cx, y - 5 * T + 16)], fill=GOOD)
        d.rectangle((x, y + T - 6, x + T - 1, y + T - 1), fill=GOOD)


def draw_objects(d, lvl, o, ox, c0, c1):
    """Moving parts: drawn as travel ranges over the static tiles."""
    def vis(x):
        return c0 * TILE <= x < c1 * TILE

    def X(x):
        return int((x - c0 * TILE) * S + ox[0])

    def Y(y):
        return int(y * S + ox[1])

    for m in o.movers:
        if not vis(m['x']) and not vis(m['x'] + m['dx'] * TILE):
            continue
        x0, y0 = X(m['x']), Y(m['y'])
        x1, y1 = X(m['x'] + m['dx'] * TILE), Y(m['y'] + m['dy'] * TILE)
        w = m['w'] * S
        d.rectangle((x1, y1, x1 + w, y1 + 12), outline=ACT)
        d.rectangle((x0, y0, x0 + w, y0 + 12), fill=ACT)
        d.line((x0 + w / 2, y0 + 6, x1 + w / 2, y1 + 6), fill=ACT, width=2)
        d.text((x0 + 2, y0 - 12), f"m#{m['i']} {m['period']:g}s", font=FONT_S, fill=ACT)
    for p in o.presses:
        if not vis(p['x']):
            continue
        x = X(p['x'])
        d.rectangle((x, Y(p['y0']), x + T - 1, Y(p['y0']) + T - 1), fill=(120, 40, 40), outline=HAZARD, width=2)
        for yy in range(Y(p['y0']) + T, Y(p['y1']) + T, 8):
            d.line((x + 4, yy, x + T - 5, yy), fill=HAZARD)
        d.rectangle((x, Y(p['y1']), x + T - 1, Y(p['y1']) + T - 1), outline=HAZARD)
        d.text((x, Y(p['y0']) - 12), f"X#{p['i']} {p['period']:g}s @{p['phase']:g}", font=FONT_S, fill=HAZARD)
    for v in o.vents:
        if vis(v['x']):
            d.text((X(v['x']), Y(v['y']) - 12), f"T#{v['i']} @{v['phase']:g}", font=FONT_S, fill=HAZARD)
    for dr in o.droppers:
        if not vis(dr['x']):
            continue
        x = X(dr['x'])
        d.rectangle((x, Y(dr['y']), x + 2 * T - 1, Y(dr['y']) + 2 * T - 1), fill=(90, 50, 110), outline=ENEMY, width=2)
        d.text((x + T, Y(dr['y']) + T), 'D', font=FONT_B, fill=WHITE, anchor='mm')
        for yy in range(Y(dr['y']) + 2 * T, Y(dr['y1']) + 2 * T, 10):
            d.line((x + 6, yy, x + 2 * T - 7, yy), fill=ENEMY)
    for db in o.debris:
        if vis(db['x']):
            x = X(db['x']) + T // 2
            for yy in range(Y(db['y']) + T, Y(db['land']), 8):
                d.line((x, yy, x, yy + 3), fill=HAZARD)
    for g in o.gates:
        plate = next((p for p in o.plates if p['i'] == g['plate']), None)
        if plate and vis(g['x']) and vis(plate['c'] * TILE):
            px, py = X(plate['c'] * TILE) + T // 2, Y(plate['r'] * TILE) + T - 4
            gx, gy = X(g['x']) + T // 2, Y(g['y'] + g['h'])
            for i in range(0, 40):
                if i % 2 == 0:
                    a, b = i / 40, (i + 1) / 40
                    d.line((px + (gx - px) * a, py + (gy - py) * a - 30 * (1 - (2 * a - 1) ** 2),
                            px + (gx - px) * b, py + (gy - py) * b - 30 * (1 - (2 * b - 1) ** 2)), fill=ACT, width=2)
            label = 'stays open' if g['open'] == 0 else f"open {g['open']:g}s after release"
            d.text((gx + 8, gy - T * 4), f"gate#{g['i']}: {label}", font=FONT_S, fill=ACT)
    for (c, r) in lvl.find('W'):
        if vis(c * TILE):
            x, y = X(c * TILE), Y(r * TILE)
            d.rectangle((x, y, x + 2 * T - 1, y + 2 * T - 1), fill=ENEMY, outline=WHITE, width=2)
            d.text((x + T, y + T), 'W', font=FONT_B, fill=BG, anchor='mm')
            lo, hi = X((c - 5) * TILE), X((c + 5) * TILE)
            d.line((lo, y - 8, hi, y - 8), fill=ENEMY, width=2)
            d.text((lo, y - 22), 'warden patrol, hops every 2.5 s', font=FONT_S, fill=ENEMY)


def render(lvl, path, report, out):
    o = Objects(lvl)
    strips = (lvl.width + STRIP - 1) // STRIP
    head = 70
    ROWS = lvl.rows
    sh = ROWS * T + 34
    img = Image.new('RGB', (STRIP * T + 40, head + strips * sh + 150), BG)
    d = ImageDraw.Draw(img)
    d.text((20, 14), f"WORLD {lvl.meta.get('world', '')}  .  {lvl.name}", font=FONT_B, fill=WHITE)
    d.text((20, 40), report['line'], font=FONT, fill=GRAY)
    frames = []
    for a, fr, run in path:
        for (x, y) in fr:
            frames.append((x, y, a[2] and run.body.dash_t > 0))
    for s in range(strips):
        c0, c1 = s * STRIP, min(lvl.width, (s + 1) * STRIP)
        ox, oy = 20, head + s * sh + 20
        d.rectangle((ox, oy, ox + (c1 - c0) * T, oy + ROWS * T), fill=BG)
        for c in range(c0, c1 + 1):
            d.line((ox + (c - c0) * T, oy, ox + (c - c0) * T, oy + ROWS * T), fill=GRID)
        for r in range(ROWS + 1):
            d.line((ox, oy + r * T, ox + (c1 - c0) * T, oy + r * T), fill=GRID)
        d.rectangle((ox, oy, ox + (c1 - c0) * T, oy + 2 * T), fill=(18, 18, 22))
        for c in range(c0, c1):
            if c % 5 == 0:
                d.text((ox + (c - c0) * T + 2, oy - 16), str(c), font=FONT_S, fill=GRAY)
        for r in range(ROWS):
            for c in range(c0, c1):
                ch = lvl.grid[r][c]
                if ch not in '.XDW':
                    draw_tile(d, ox + (c - c0) * T, oy + r * T, ch, lvl, c, r)
        draw_objects(d, lvl, o, (ox, oy), c0, c1)
        for col0, w, title in lvl.screens:
            if c0 <= col0 < c1:
                x = ox + (col0 - c0) * T
                d.line((x, oy, x, oy + ROWS * T), fill=GRAY, width=2)
                d.text((x + 6, oy + 6), title, font=FONT, fill=WHITE)
        pts = [(ox + (x / TILE - c0) * T, oy + y * S, dash) for (x, y, dash) in frames if c0 * TILE <= x < c1 * TILE]
        for (x0, y0, _), (x1, y1, dash) in zip(pts, pts[1:]):
            if abs(x1 - x0) < 40:
                d.line((x0, y0, x1, y1), fill=DASH if dash else ROUTE, width=4 if dash else 2)
    # legend
    ly = head + strips * sh + 10
    items = [('route the solver proved', ROUTE), ('dash', DASH), ('hazard', HAZARD), ('enemy', ENEMY),
             ('moves or reacts', ACT), ('pickup', PICK), ('checkpoint, spring, goal', GOOD)]
    x = 20
    for name, col in items:
        d.rectangle((x, ly, x + 16, ly + 16), fill=col)
        d.text((x + 22, ly + 1), name, font=FONT, fill=GRAY)
        x += 40 + len(name) * 8
    used = sorted(set(''.join(lvl.grid)) - {'.'})
    y = ly + 30
    line = '   '.join(f'{ch} {LEGEND[ch]}' for ch in used)
    words, cur = line.split('   '), ''
    for w_ in words:
        if len(cur) + len(w_) > 230:
            d.text((20, y), cur, font=FONT_S, fill=GRAY)
            y += 16
            cur = ''
        cur += w_ + '   '
    d.text((20, y), cur, font=FONT_S, fill=GRAY)
    img.save(out)


PATTERNS = [None, 8, 16, 24, 40]   # jump held throughout, or re-pressed every N frames


def run_pattern(w, run, pattern, frames, goal, trail=None):
    """Hold right with a simple jump rhythm until `goal(run)` or death."""
    r = run
    for f in range(frames):
        jump = True if pattern is None else (f % pattern) < pattern // 2
        r = w.advance(r, 1, jump, False)
        if trail is not None:
            trail.append(((1, jump, False), [(r.body.x, r.body.y)], r))
        if r.dead:
            return None
        if goal(r):
            return r
    return None


def probe(lvl, path, cell, frames=600):
    """Cheap first check: from each nearby screen start on the proven route,
    hold right with a simple jump rhythm and see if the Spark touches `cell`."""
    w = sim.World(lvl)
    starts = [next((st[2] for st in path if st[2].body.floor and st[2].body.x >= s0 * TILE), None)
              for s0, _, _ in lvl.screens if s0 <= cell[0]]
    for run in [s for s in starts[-3:] if s]:
        for pattern in PATTERNS:
            if run_pattern(w, run, pattern, frames, lambda r: sim.touches(r.body, cell)):
                return True
    return False


def check_collectables(lvl, path, extra=()):
    """Every small shard must be collectable and every bump block hittable from
    below. Whatever the main route or the big-shard routes pass through counts
    straight away. For the rest, search from the last proven standing point before
    it, then try the simple timed runs, and count everything those pass through."""
    def pickup(c, r):   # the game's pickup box for a shard
        return lambda x, y: (x - HALF_W < c * TILE + 13 and x + HALF_W > c * TILE + 3
                             and y - HALF_H < r * TILE + 13 and y + HALF_H > r * TILE + 3)

    def bump(c, r):     # the Spark's head meets the underside of the block
        bottom = (r + 1) * TILE
        return lambda x, y: (x - HALF_W < c * TILE + TILE and x + HALF_W > c * TILE
                             and bottom - 1.0 <= y - HALF_H <= bottom + 0.01)

    items = {('o', c, r): pickup(c, r) for c, r in lvl.find('o')}
    for ch in '?CUhi':
        items.update({(ch, c, r): bump(c, r) for c, r in lvl.find(ch)})
    got = set()

    def mark(steps):
        for _, frames, _ in steps:
            for x, y in frames:
                for k, fn in items.items():
                    if k not in got and fn(x, y):
                        got.add(k)

    mark(path)
    for steps in extra:
        mark(steps)
    for k, fn in sorted(items.items(), key=lambda kv: kv[0][1]):
        if k in got:
            continue
        col = k[1]
        before = [st[2] for st in path if st[2].body.floor and st[2].body.x < (col - 2) * TILE]
        # cheap searches first; the last, slow one handles skill moves like a stomp chain
        for run0, nodes, wgt in ([(before[-1], 40_000, 2.5)] if before else []) + [(None, 40_000, 2.5)] +                 ([(before[-1], 400_000, 1.2)] if before else []):
            seg, _, ok = sim.solve(lvl, run0=run0, max_nodes=nodes, reach=fn, target=(col, k[2]), weight=wgt,
                                   tcycle=64 if wgt < 2 else None, drop=True)
            if ok:
                mark(seg)
            if k in got:
                break
        if k not in got and k[0] == 'o' and probe(lvl, path, (col, k[2])):
            got.add(k)

    def report(chars):
        mine = [k for k in items if k[0] in chars]
        return {'total': len(mine), 'reachable': sum(k in got for k in mine),
                'missing': [[k[1], k[2]] for k in mine if k not in got]}
    return report('o'), report('?CUhi')


def parse_via(text):
    """Waypoints 'c,r' (stand in that cell) or 'bc,r' (bump that block from
    below, for switches and fuses), separated by '|'."""
    out = []
    for p in str(text).split('|'):
        if p:
            kind = 'b' if p.startswith('b') else 's'
            c, r = (int(v) for v in p.lstrip('b').split(','))
            out.append((kind, c, r))
    return out


def solve_leg(lvl, run0, wp, nodes):
    kind, c, r = wp
    if kind == 'b':
        bottom = (r + 1) * TILE
        reach = lambda x, y: (x - HALF_W < c * TILE + TILE and x + HALF_W > c * TILE
                              and bottom - 1.0 <= y - HALF_H <= bottom + 0.01)
        return sim.solve(lvl, run0=run0, target=(c, r), reach=reach, max_nodes=nodes)
    return sim.solve(lvl, run0=run0, target=(c, r), stand=True, max_nodes=nodes)


def prove(lvl):
    """Chain the search screen by screen, carrying the exact state (time, fallen
    floors, plates, enemies) across each boundary. If a screen fails from where
    the previous one ended, retry both screens together from the earlier start."""
    t0 = time.time()
    bounds = [col0 + w for col0, w, _ in lvl.screens][:-1] + [None]
    segs = []            # (start_run, path) per solved screen
    nodes, ok, stuck, i = 0, True, None, 0
    # optional designer waypoints for the main route: route#1 via=155,11|b160,10
    route_via = parse_via(lvl.overrides.get('route#1', {}).get('via', ''))
    while i < len(bounds):
        run0 = segs[-1][1][-1][2] if segs and segs[-1][1] else (segs[-1][0] if segs else None)
        lo = lvl.screens[i][0]
        pre, seg_ok = [], True
        for wp in [v for v in route_via if lo <= v[1] < lo + lvl.screens[i][1]]:
            leg, n, seg_ok = solve_leg(lvl, run0, wp, 300_000)
            nodes += n
            pre += leg
            run0 = leg[-1][2] if leg else run0
        seg, n, seg_ok2 = sim.solve(lvl, run0=run0, until_col=bounds[i], max_nodes=250_000)
        if not seg_ok2 and run0 is not None:
            # the search can miss simple timed runs (ring chains); try those
            w = sim.World(lvl)
            for pattern in PATTERNS:
                end, trail = bounds[i], []
                won = run_pattern(w, run0, pattern, 900, lambda r: r.won if end is None else
                                  (r.body.floor and r.body.x - 6 >= end * TILE), trail)
                if won:
                    seg, seg_ok2 = trail, True
                    break
        seg, seg_ok = pre + seg, seg_ok and seg_ok2
        nodes += n
        if not seg_ok and segs:
            start, _ = segs.pop()
            seg, n, seg_ok = sim.solve(lvl, run0=start, until_col=bounds[i], max_nodes=250_000)
            nodes += n
            run0 = start
        if not seg_ok:
            ok = False
            far = seg[-1][2].body if seg else None
            stuck = [round(far.x / TILE, 1), round(far.y / TILE, 1)] if far else None
            segs.append((run0, seg))
            break
        segs.append((run0, seg))
        i += 1
    path = [step for _, seg in segs for step in seg]
    secs = path[-1][2].t / 60 if path else 0
    result = {'finished': ok, 'route_seconds': round(secs, 1), 'nodes': nodes, 'shards': {}}
    big_routes = []
    if not ok:
        result['stuck_at'] = stuck
    for k, (c, r) in enumerate(lvl.find('O'), 1):
        # optional designer waypoints: O#2 via=16,13|13,11 (proved one leg at a time)
        via = str(lvl.overrides.get(f'O#{k}', {}).get('via', ''))
        legs = parse_via(via) + [('o', c, r)]
        # start from the nearest proven point before the first leg, then further back
        first = legs[0][1]
        screen0 = max(s0 for s0, _, _ in lvl.screens if s0 <= first)
        before = [st[2] for st in path if st[2].body.floor and st[2].body.x < (first - 1) * TILE]
        tries = [before[-1] if before else None]
        prev = [s0 for s0, _, _ in lvl.screens if s0 < screen0]
        if prev:
            tries.append(next((st[2] for st in path if st[2].body.floor and st[2].body.x >= prev[-1] * TILE), None))
        ok2 = probe(lvl, path, (c, r))
        for run0 in ([] if ok2 else tries):
            for leg in legs:
                if leg[0] == 'o':   # the shard itself: touch it, standing or not
                    seg, n2, ok2 = sim.solve(lvl, target=(c, r), run0=run0, max_nodes=100_000)
                else:
                    seg, n2, ok2 = solve_leg(lvl, run0, leg, 300_000)
                if not ok2:
                    break
                big_routes.append(seg)
                run0 = seg[-1][2] if seg else run0
            if ok2:
                break
        if not ok2 and len(legs) == 1 and tries[0] is not None:
            # last try: a slow, thorough search for skill moves like a stomp chain
            seg, n2, ok2 = sim.solve(lvl, target=(c, r), run0=tries[0], max_nodes=400_000, weight=1.2, tcycle=64)
            if ok2:
                big_routes.append(seg)
        result['shards'][f'{c},{r}'] = ok2
    result['small_shards'], result['blocks'] = check_collectables(lvl, path, big_routes)
    result['solve_seconds'] = round(time.time() - t0, 1)
    return path, result


def main():
    want = sys.argv[1:] or None
    files = sorted(glob.glob(os.path.join(ROOT, 'levels', '*', '*.txt')))
    for f in files:
        name = os.path.splitext(os.path.basename(f))[0]
        if want and name not in want:
            continue
        lvl = parse(f)
        if lvl.meta.get('hub'):   # the village has nothing to prove
            continue
        path, res = prove(lvl)
        o_total = len(lvl.find('O'))
        o_ok = sum(res['shards'].values())
        shards = sum(''.join(lvl.grid).count(ch) for ch in 'o?')
        state = 'FINISHABLE' if res['finished'] or not lvl.find('G') else f"STUCK near tile {res.get('stuck_at')}"
        res['line'] = (f"{lvl.width} tiles ({lvl.width * TILE}px, {len(lvl.screens)} screens)  .  {state}"
                       f"  .  fastest proven route {res['route_seconds']}s  .  big shards reachable {o_ok}/{o_total}"
                       f"  .  small shards reachable {res['small_shards']['reachable']}/{res['small_shards']['total']}"
                       f"  .  blocks hittable {res['blocks']['reachable']}/{res['blocks']['total']}"
                       f"  .  {shards} shards  .  owns: {lvl.meta.get('owns', '-')}")
        print(name, res['line'], flush=True)
        with open(os.path.splitext(f)[0] + '.proof.json', 'w') as fh:
            json.dump(res, fh, indent=1)
        # the proven route as button presses, one entry per frame, so the game
        # can replay it (scripts/world1/w1_replay_test.gd)
        frames = []
        for a, fr, _ in path:
            for k in range(len(fr)):
                frames.append(f"{a[0] + 1}{int(a[1])}{int(a[2] and k == 0)}")
        with open(os.path.splitext(f)[0] + '.route.json', 'w') as fh:
            json.dump({'finished': res['finished'], 'frames': ''.join(frames)}, fh)
        render(lvl, path, res, os.path.splitext(f)[0] + '.png')


if __name__ == '__main__':
    main()
