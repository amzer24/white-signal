"""Measures what the Spark can actually clear, using the solver on tiny test
levels. These limits are the design rules the level maps are built to."""
import sys
from levelkit import Level, ROWS
from sim import solve


def make(rows):
    w = max(len(r) for r in rows)
    grid = ['.' * w] * (ROWS - len(rows)) + [r.ljust(w, '.') for r in rows]
    return Level('test', {}, grid, [(0, w, 'test')], {})


def gap_level(gap, dash):
    left = 'P' + '.' * 9
    top = '.' * 10 + '.' * gap + '...G'
    ground = '#' * 10 + '.' * gap + '#' * 4
    return make([top.replace('P', '.'), left + '.' * (gap + 4), ground, ground, ground]) if False else \
        make(['.' * (14 + gap - 1) + 'G', 'P' + '.' * (13 + gap), ground, ground, ground])


def run(name, level, no_dash=False):
    import sim
    saved = sim.ACTIONS
    if no_dash:
        sim.ACTIONS = [a for a in saved if not a[2]]
    try:
        path, n, ok = solve(level, max_nodes=60_000)
    finally:
        sim.ACTIONS = saved
    return ok


if __name__ == '__main__':
    print('GAP (tiles)  plain  dash')
    for gap in range(3, 12):
        g = ['#' * 10 + '.' * gap + '#' * 4] * 3
        top = '.' * (10 + gap + 3) + 'G'
        lvl = make([top, 'P' + '.' * (13 + gap)] + g)
        a = run('gap', lvl, no_dash=True)
        b = run('gap', lvl)
        print(f'{gap:>5}        {"yes" if a else "no ":>5}  {"yes" if b else "no"}')
        sys.stdout.flush()
    print('STEP UP (tiles) plain  dash')
    for hgt in range(2, 7):
        rows = []
        for r in range(hgt + 3):
            if r == 0:
                rows.append('.' * 17 + 'G')
            elif r <= hgt:
                rows.append(('P' if r == hgt else '.') + '.' * 11 + '######')
            else:
                rows.append('#' * 18)
        lvl = make(rows)
        a = run('step', lvl, no_dash=True)
        b = run('step', lvl)
        print(f'{hgt:>5}          {"yes" if a else "no ":>5}  {"yes" if b else "no"}')
        sys.stdout.flush()
    print('WALL CLIMB: 2-wide shaft, height (tiles) plain')
    for hgt in (4, 8):
        rows = ['#' * 5 + '.' * 6 + 'G']
        for r in range(hgt):
            rows.append('#' * 5 + '..' + '#' * 5)
        rows[-1] = rows[-1]
        rows.append('#' * 5 + '..' + '#' * 5)
        base = '.' * 5 + 'P.' + '#' * 5
        lvl = make(rows[:1] + rows[1:-1] + ['#####' + 'P.' + '#####', '#' * 12, '#' * 12])
        print(f'{hgt:>5}          {"yes" if run("shaft", lvl, no_dash=True) else "no"}')
