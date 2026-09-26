"""Generates every World 1 and World 2 sprite sheet in assets/world1/.

Run from the project root:  python assets/world1/src/make_sheets.py
Writes <name>.png sheets, sheets.json (frame size, rows, timing) and a 3x
contact sheet to test-user/world1-art/contact.png for review.

Sheet layout: every row is one animation (or one set of static variants),
frames run left to right. sheets.json gives each row's frame count and
per-frame duration in seconds. Nothing here uses a colour outside the four
greys, and pix.C.check() enforces it.
"""
import json
import math
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
from pix import C, K, D, G, W, T, bayer, hash2  # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', '..'))
OUT = os.path.join(ROOT, 'assets', 'world1')
REVIEW = os.path.join(ROOT, 'test-user', 'world1-art')

SHEETS = {}


def A(name, frames, dur=0.1, loop=True, note=''):
    return {'name': name, 'frames': frames, 'dur': dur, 'loop': loop, 'note': note}


def sheet(name, fw, fh, rows, about=''):
    cols = max(len(r['frames']) for r in rows)
    img = Image.new('RGBA', (cols * fw, len(rows) * fh), T)
    anims = {}
    for i, r in enumerate(rows):
        for j, f in enumerate(r['frames']):
            assert (f.w, f.h) == (fw, fh), f'{name}/{r["name"]} frame {j} is {f.w}x{f.h}'
            f.check()
            img.paste(f.im, (j * fw, i * fh))
        dur = r['dur']
        if not isinstance(dur, list):
            dur = [dur] * len(r['frames'])
        anims[r['name']] = {'row': i, 'frames': len(r['frames']), 'dur': dur,
                            'loop': r['loop'], 'note': r['note']}
    img.save(os.path.join(OUT, name + '.png'))
    SHEETS[name] = {'file': name + '.png', 'fw': fw, 'fh': fh, 'about': about,
                    'order': [r['name'] for r in rows], 'anims': anims}


# =================================================================== terrain

def ground(left=False, right=False, top=False, bottom=False, depth=0, alt=0):
    c = C(16, 16)
    c.rect(0, 0, 16, 16, D)
    # brick courses: mortar rows at y=3 and y=11, joints staggered by 4
    for y in (3, 11):
        c.rect(0, y, 16, 1, K)
    for y in range(4, 11):
        c.px(0, y, K)
        c.px(8, y, K)
    for y in list(range(12, 16)) + list(range(0, 3)):
        c.px(4, y, K)
        c.px(12, y, K)
    # worn brick corners catch the light
    for bx in (1, 9):
        c.px(bx, 4, G)
    for bx in (5, 13):
        c.px(bx, 12, G)
    # depth: dither toward black the deeper the tile sits
    base_thr = (1, 2, 3)[depth]
    shade_thr = (3, 7, 10)[depth]
    for y in range(5 if top else 0, 16):
        shade = y in (8, 9, 10) or y in (0, 1, 2) or (depth == 2 and y in (7, 15))
        c.dith(1, y, 15, 1, K, shade_thr if shade else base_thr, only=D)
    if alt == 1:  # missing brick: black cavity with a lit lip
        c.rect(9, 4, 7, 7, K)
        c.rect(9, 4, 7, 1, D)
        c.px(9, 10, G)
    elif alt == 2:  # crack
        c.line(5, 12, 7, 15, K)
        c.line(6, 0, 5, 2, K)
    elif alt == 3:  # fossil relay part (a dead pip)
        c.rect(10, 6, 3, 3, K)
        c.px(11, 7, D)
    if left:
        for y in range(16):
            c.px(0, y, G if (y + (0 if top else 1)) % 3 else D)
    if right:
        for y in range(16):
            c.px(15, y, K)
        c.dith(14, 0, 1, 16, K, 8)
    if top:
        c.rect(0, 0, 16, 2, W)
        c.rect(0, 2, 16, 1, G)
        c.rect(0, 3, 16, 1, K)
        if left:
            c.px(0, 0, T)
            c.px(0, 1, G)
        if right:
            c.px(15, 0, T)
            c.px(15, 1, G)
    if bottom:
        c.rect(0, 14, 16, 2, K)
        c.dith(0, 13, 16, 1, K, 8)
        # a few drips on the underside
        c.px(5, 15, T)
        c.px(11, 15, T)
        if left:
            c.px(0, 15, T)
        if right:
            c.px(15, 15, T)
    return c


def block(lip=True, kind=0):
    c = C(16, 16)
    c.rect(0, 0, 16, 16, D)
    c.dith(1, 1, 14, 14, K, 2)
    c.rect(15, 0, 1, 16, K)   # seams tile into panels
    c.rect(0, 15, 16, 1, K)
    for y in range(16):
        if y % 2 == 0:
            c.px(0, y, G)
    oy = 2 if lip else 0
    for (x, y) in ((2, 2 + oy), (12, 2 + oy), (2, 12), (12, 12)):
        c.px(x, y, G)
        c.px(x + 1, y + 1, K)
    if kind == 1:  # vent slits
        for k in range(3):
            c.rect(5, 5 + oy + k * 2, 6, 1, K)
            c.rect(5, 6 + oy + k * 2, 6, 1, G if k == 2 else D)
    elif kind == 2:  # status pip: the one live pixel on a dead panel
        c.rect(10, 5 + oy, 3, 3, K)
        c.px(11, 6 + oy, W)
    elif kind == 3:  # stencil mark
        c.rect(4, 6 + oy, 8, 1, K)
        c.rect(4, 8 + oy, 5, 1, K)
    if lip:
        c.rect(0, 0, 16, 1, W)
        c.rect(0, 1, 16, 1, G)
        c.rect(15, 0, 1, 2, G)
    return c


def girder(left, right, moving=False, phase=0, lamp=False):
    c = C(16, 16)
    c.rect(0, 0, 16, 1, W)
    c.rect(0, 1, 16, 1, G)
    c.rect(0, 2, 16, 3, D)
    c.rect(0, 5, 16, 1, K)
    if moving:
        # chevrons scroll to show travel
        for base in range(-8, 24, 8):
            x0 = base + phase
            for (dx, dy) in ((0, 2), (1, 3), (0, 4), (1, 2), (2, 3), (1, 4)):
                if 0 <= x0 + dx < 16:
                    c.px(x0 + dx, dy, W if dx else G)
    else:
        for x in range(16):
            for y in range(2, 5):
                if ((x + y) & 3) == 0 or ((x - y) & 3) == 0:
                    c.px(x, y, K)
    if left:
        c.rect(0, 0, 2, 5, G)
        c.px(0, 0, T)
        c.rect(2, 6, 2, 3, D)   # bracket stub
        c.rect(2, 9, 2, 1, K)
        if moving:
            c.px(0, 3, W if lamp else K)
    if right:
        c.rect(14, 0, 2, 5, G)
        c.px(15, 0, T)
        c.rect(12, 6, 2, 3, D)
        c.rect(12, 9, 2, 1, K)
        if moving:
            c.px(15, 3, W if lamp else K)
    return c


def build_terrain():
    rows = [
        A('top', [ground(left=True, top=True), ground(top=True), ground(right=True, top=True),
                  ground(left=True, right=True, top=True)], 0,
          note='top-left, top, top-right, one-wide column top'),
        A('mid', [ground(left=True, depth=1), ground(depth=1), ground(right=True, depth=1),
                  ground(left=True, right=True, depth=1)], 0, note='second row down: left, fill, right, column'),
        A('deep', [ground(left=True, depth=2), ground(depth=2), ground(right=True, depth=2),
                   ground(left=True, right=True, depth=2)], 0, note='third row and below'),
        A('bottom', [ground(left=True, bottom=True, depth=2), ground(bottom=True, depth=2),
                     ground(right=True, bottom=True, depth=2),
                     ground(left=True, right=True, top=True, bottom=True)], 0,
          note='underside for ceilings and floating ground. The last one is a single tile'),
        A('alt', [ground(top=True, alt=1), ground(top=True, alt=3), ground(depth=1, alt=2),
                  ground(depth=2, alt=1)], 0, note='drop-in swaps for variety, pick by hash of world tile x,y'),
    ]
    sheet('ground', 16, 16, rows, 'Ground `#`. Pick the column by left/right neighbours, the row by depth below the surface.')

    sheet('block', 16, 16, [
        A('lip', [block(True, 0), block(True, 1), block(True, 2), block(True, 3)], 0,
          note='top of a stack: plain, vent, live pip, stencil'),
        A('stacked', [block(False, 0), block(False, 1), block(False, 2), block(False, 3)], 0,
          note='a block with another block above it'),
    ], 'Block `=`: relay panelling. Use a live pip rarely (one per screen at most).')

    sheet('girder', 16, 16, [
        A('static', [girder(True, False), girder(False, False), girder(False, True), girder(True, True)], 0,
          note='left end, middle, right end, single. Solid part is the top 6 px'),
    ], 'Girder `-`: one-way ledge, 6 px deep.')

    frames = []
    for piece in ((True, False), (False, False), (False, True)):
        frames.append([girder(piece[0], piece[1], True, ph, lamp=(ph // 2) % 2 == 0) for ph in (0, 2, 4, 6)])
    sheet('moving_girder', 16, 16, [
        A('left', frames[0], 0.08), A('middle', frames[1], 0.08), A('right', frames[2], 0.08),
    ], 'Moving girder `m`. Play frames forward while it moves right or down, backward while it moves left or up. '
       'Hold the current frame while it pauses at an end. End lamps blink with the scroll.')


# =================================================================== bump blocks

ICON_SHARD = ['..w..', '.www.', 'wwkww', '.www.', '..w..']
ICON_CHARGE = ['..www', '.ww..', 'wwwww', '..ww.', '.ww..', 'ww...']
ICON_LIFE = ['.wwwww', 'gwwkkw', '.wwwww', '.wwwww', '.w..w.']


def bump_face(icon, glint=-1, lit=True, icon_dy=0, icon_col=None, flash=False):
    c = C(16, 16)
    c.rect(0, 0, 16, 16, K)
    c.rect(1, 1, 14, 14, D)
    c.dith(2, 2, 12, 12, K, 3, only=D)
    if lit:
        c.rect(1, 1, 14, 1, W)
        c.rect(1, 1, 1, 14, W)
        c.rect(2, 14, 13, 1, G)
        c.rect(14, 2, 1, 13, G)
    for (x, y) in ((3, 3), (12, 3), (3, 12), (12, 12)):
        c.px(x, y, G)
    if glint >= 0:
        for x in range(2, 14):
            for y in range(2, 14):
                if x + y in (glint, glint + 1) and c.get(x, y) in (D, K):
                    c.px(x, y, G if x + y == glint + 1 else W)
    if icon:
        h = len(icon)
        w = len(icon[0])
        ix = 8 - (w + 1) // 2
        iy = 8 - (h + 1) // 2 + icon_dy
        # a dark well behind the icon so it pops
        c.rect(ix - 1, iy - 1, w + 2, h + 2, K)
        rows = icon if icon_col is None else [r.replace('w', icon_col) for r in icon]
        c.art(ix, iy, rows)
    if flash:
        c.rect(1, 1, 14, 14, W)
        c.frame(0, 0, 16, 16, K)
        c.art(8 - 3, 8 - 3 + icon_dy, [r.replace('w', 'k').replace('g', 'k') for r in icon])
    return c


def used_block():
    c = C(16, 16)
    c.rect(0, 0, 16, 16, K)
    c.rect(1, 1, 14, 14, D)
    c.dith(1, 1, 14, 14, K, 6, only=D)
    c.rect(1, 1, 14, 1, G)
    for (x, y) in ((3, 3), (12, 3), (3, 12), (12, 12)):
        c.px(x, y, G)
    c.rect(6, 6, 4, 4, K)
    return c


def charge_sparks(c, f):
    pts = [(1, 1), (14, 1), (14, 14), (1, 14)]
    x, y = pts[f % 4]
    for dx, dy in ((0, 0), (-1, 0), (1, 0), (0, -1), (0, 1)):
        c.px(x + dx, y + dy, W)
    return c


def build_bumps():
    dur = [1.1, 0.06, 0.06, 0.06]
    shard = [bump_face(ICON_SHARD, g) for g in (-1, 6, 13, 20)]
    shard[0] = bump_face(ICON_SHARD)
    charge = [charge_sparks(bump_face(ICON_CHARGE, g), i) for i, g in enumerate((-1, 6, 13, 20))]
    life = [bump_face(ICON_LIFE, -1), bump_face(ICON_LIFE, -1, icon_col='g'), bump_face(ICON_LIFE, -1),
            bump_face(ICON_LIFE, 13)]
    hit = [bump_face(ICON_SHARD, flash=True, icon_dy=-1), bump_face(ICON_SHARD, icon_dy=-1), used_block(), used_block()]
    sheet('bump_block', 16, 16, [
        A('shard', shard, dur, note='`?` idle: hold, then a glint sweeps the face'),
        A('charge', charge, 0.12, note='`C` idle tell: a spark runs round the corners'),
        A('life', life, [0.5, 0.08, 0.12, 0.08], note='`U` idle tell: the little Spark icon beats'),
        A('hit', hit, [0.05, 0.06, 0.1, 0.1], loop=False,
          note='on bump: white flash, icon jumps, then used. Hop the whole tile 4 px up for 0.1 s in code'),
        A('used', [used_block()], 0, note='empty block'),
    ], 'Bump blocks `?` `C` `U`. The icon tells you what is inside.')

    # hidden block reveal
    f0 = C(16, 16)
    f1 = C(16, 16)
    f1.rect(0, 0, 16, 16, W)
    f1.frame(0, 0, 16, 16, K)
    for (x, y) in ((0, 0), (15, 0), (0, 15), (15, 15)):
        f1.px(x, y, T)
    f2 = C(16, 16)
    f2.frame(0, 0, 16, 16, W)
    f2.frame(1, 1, 14, 14, K)
    f2.rect(2, 2, 12, 12, D)
    f2.art(5, 5, ICON_LIFE)
    f3 = bump_face(ICON_LIFE, 13)
    sheet('hidden_block', 16, 16, [
        A('hidden', [f0], 0, note='invisible, solid only from below'),
        A('reveal', [f1, f2, f3, used_block()], [0.05, 0.07, 0.12, 0.1], loop=False,
          note='white pop, outline forms, 1UP face, then used'),
    ], 'Hidden block `h`.')


# =================================================================== brick

def brick(crack=0):
    c = C(16, 16)
    c.rect(0, 0, 16, 16, K)
    for (y0, off) in ((0, 0), (8, 4)):
        for x0 in range(-8 + off, 16, 8):
            # one brick: x0+1..x0+7, y0+1..y0+7
            for x in range(x0 + 1, x0 + 8):
                for y in range(y0 + 1, y0 + 8):
                    if 0 <= x < 16:
                        c.px(x, y, D)
            for x in range(x0 + 1, x0 + 8):
                c.px(x, y0 + 1, G)
                c.px(x, y0 + 7, K)
            for y in range(y0 + 1, y0 + 7):
                c.px(x0 + 1, y, G)
            c.px(x0 + 1, y0 + 1, W)
            c.px(x0 + 2, y0 + 1, W)
            c.px(x0 + 1, y0 + 2, W)
            c.dith(max(0, x0 + 3), y0 + 5, 4, 2, K, 6, only=D)
    c.rect(0, 0, 16, 1, W)
    if crack >= 1:
        c.line(8, 1, 6, 6, K)
        c.line(6, 6, 9, 11, K)
        c.line(9, 11, 7, 15, K)
    if crack >= 2:
        c.line(2, 4, 6, 6, K)
        c.line(9, 11, 14, 9, K)
        c.px(7, 5, W)
        c.px(8, 10, W)
    return c


def debris(k):
    base = C(8, 8)
    base.art(0, 0, ['.gwwg...', 'gdddgg..', 'dddddd..', 'kddddd..', '.kkddk..', '...kk...', '........', '........'])
    return base.rot90(k).shifted(1, 1) if k else base.shifted(1, 1)


def build_brick():
    sheet('brick', 16, 16, [
        A('idle', [brick(0)], 0),
        A('bumped', [brick(1), brick(0)], [0.08, 0.1], loop=False,
          note='bumped while not charged: hops, a crack flashes, heals'),
        A('break', [brick(1), brick(2)], [0.04, 0.04], loop=False,
          note='bumped while charged: two crack frames, then spawn 4 debris and remove the tile'),
    ], 'Brick `B`.')
    sheet('brick_debris', 8, 8, [
        A('spin', [debris(k) for k in range(4)], 0.06,
          note='4 chunks fly out (up-left, up-right, down-left, down-right) and spin through these frames'),
    ], 'Brick debris.')


# =================================================================== loose floor, bridge

def loose(stage=0):
    """stage 0 still, 1 cracking, 2 about to go, 3 splitting (falling)."""
    c = C(16, 16)
    c.rect(0, 0, 16, 12, D)
    c.dith(1, 4, 14, 8, K, 4, only=D)
    c.rect(0, 0, 16, 2, W)
    c.rect(0, 2, 16, 1, G)
    c.rect(0, 11, 16, 1, K)
    # ragged underside: it is a slab resting on nothing
    for x, h in enumerate((2, 3, 1, 2, 3, 2, 1, 3, 2, 2, 3, 1, 2, 3, 2, 1)):
        c.rect(x, 12, 1, h - 1 if h > 1 else 0, D)
        c.px(x, 11 + h - 1, K)
    # seams split the lip into three pieces: reads as not solid ground
    for x in (5, 11):
        c.rect(x, 0, 1, 3, K)
    c.line(5, 3, 4, 7, K)
    c.line(11, 3, 12, 8, K)
    if stage >= 1:
        c.line(4, 7, 6, 10, K)
        c.line(12, 8, 10, 11, K)
        c.px(8, 6, K)
        c.px(8, 7, K)
        c.rect(1, 0, 3, 1, G)
    if stage >= 2:
        c.rect(6, 0, 4, 2, G)
        c.rect(12, 0, 3, 1, G)
        c.line(8, 3, 8, 10, K)
        c.px(3, 15, D)
        c.px(13, 15, G)
    if stage >= 3:
        n = C(16, 16)
        left = C(16, 16)
        right = C(16, 16)
        for y in range(16):
            for x in range(16):
                col = c.get(x, y)
                if col[3]:
                    (left if x < 8 else right).px(x, y, col)
        n.paste(left.shifted(0, 1), 0, 0)
        n.paste(right.shifted(0, 2), 0, 0)
        return n
    return c


def rubble(v=0):
    c = C(16, 16)
    if v == 0:
        c.art(0, 8, [
            '.......gg.......',
            '......gddg......',
            '...gg.dddd.gw...',
            '..gddgddkdgdd...',
            '.gdddddddddddg..',
            'gddkdddddkddddg.',
            'dddddkdddddddkdd',
            'kkkkkkkkkkkkkkkk',
        ])
    else:
        c.art(0, 10, [
            '....gg....gw....',
            '..gdddg.gdddg...',
            '.gdddkddddkddg..',
            'gdddddddddddddg.',
            'dddkddddkdddddgd',
            'kkkkkkkkkkkkkkkk',
        ])
    return c


def bridge(stage=0):
    c = C(16, 16)
    # deck: planks 4 px wide
    c.rect(0, 0, 16, 1, W)
    c.rect(0, 1, 16, 5, D)
    for x in range(0, 16, 4):
        c.px(x, 1, K)
        c.rect(x, 2, 1, 4, K)
        c.px(x + 1, 1, G)
        c.px(x + 2, 1, G)
    c.rect(0, 6, 16, 1, K)
    # truss under the deck
    for x in range(16):
        y = 7 + (x % 8 if x % 8 < 4 else 7 - x % 8)
        c.px(x, y, D)
    c.rect(0, 7, 16, 1, D)
    c.px(0, 11, G)
    c.px(8, 11, G)
    if stage == 1:  # stressed: planks drop a pixel, bolts pop
        n = C(16, 16)
        n.paste(c, 0, 0)
        n.rect(4, 0, 4, 7, T)
        piece = C(16, 16)
        for y in range(7):
            for x in range(4, 8):
                piece.px(x, y + 1, c.get(x, y))
        n.paste(piece, 0, 0)
        n.px(3, 0, G)
        n.px(12, 1, K)
        return n
    if stage == 2:  # snapped: two halves tilt down
        n = C(16, 16)
        for y in range(16):
            for x in range(16):
                col = c.get(x, y)
                if col[3]:
                    dy = (x // 3) if x < 8 else ((15 - x) // 3)
                    n.px(x, y + dy, col)
        return n
    return c


def plank(k):
    c = C(16, 16)
    base = C(16, 16)
    base.rect(2, 7, 12, 1, W)
    base.rect(2, 8, 12, 2, D)
    base.rect(2, 10, 12, 1, K)
    base.px(6, 8, K)
    base.px(10, 8, K)
    if k == 0:
        return base
    if k == 2:
        return base.flip_v()
    c.paste(base.rot90(1 if k == 1 else 3), 0, 0)
    return c


def build_loose():
    sheet('loose_floor', 16, 16, [
        A('still', [loose(0)], 0, note='split lip and ragged underside set it apart from ground'),
        A('shake', [loose(1), loose(2)], 0.06,
          note='0.35 s after landing: alternate these and jitter the tile +-1 px x'),
        A('fall', [loose(3)], 0, note='while it drops'),
        A('rubble', [rubble(0), rubble(1)], 0,
          note='landed. 0 = on flat floor, 1 = resting on a plate (lower, holds it down)'),
    ], 'Loose floor `L`.')
    sheet('bridge', 16, 16, [
        A('intact', [bridge(0)], 0),
        A('stress', [bridge(1), bridge(0)], 0.05, note='lever pulled: each tile shudders before it goes'),
        A('snap', [bridge(2)], 0, note='tile breaks in two and falls, 0.06 s after the tile before it'),
        A('plank', [plank(k) for k in range(4)], 0.07, note='debris planks tumble as they fall'),
    ], 'Bridge floor `Z`. Collapse runs as a chain from the lever end.')


# =================================================================== spikes and vents

def spikes(bright=True, glint=False):
    c = C(16, 16)
    tip = W if bright else G
    for x0 in (0, 8):
        for y in range(6, 14):
            half = (y - 6) // 2
            for x in range(x0 + 4 - half - 1, x0 + 4 + half + 1):
                c.px(x, y, tip if x < x0 + 4 else G)
        c.px(x0 + 3, 5, tip)
    c.outline(K)
    c.rect(0, 14, 16, 2, D)
    c.rect(0, 14, 16, 1, G)
    c.rect(0, 15, 16, 1, K)
    if glint:
        c.px(3, 3, W)
        c.px(3, 2, G)
        c.px(2, 3, G)
        c.px(4, 3, G)
    return c


def vent(stage):
    """0 down, 1 warn a, 2 warn b, 3 half up, 4 up, 5 up glint."""
    c = C(16, 16)
    rise = {0: 0, 1: 2, 2: 3, 3: 6, 4: 11, 5: 11}[stage]
    if rise:
        sp = spikes(True, stage == 5)
        top = C(16, 16)
        for y in range(14):
            for x in range(16):
                col = sp.get(x, y)
                if col[3]:
                    top.px(x, y + (9 - rise), col)
        # cut to the grille line
        for y in range(13, 16):
            top.rect(0, y, 16, 1, T)
        c.paste(top, 0, 0)
    # grille plate on the floor: two dark slots the teeth come out of
    c.rect(0, 12, 16, 1, K)
    c.rect(0, 13, 16, 1, G)
    c.rect(0, 14, 16, 1, D)
    c.rect(0, 15, 16, 1, K)
    for x in (2, 3, 4, 5, 10, 11, 12, 13):
        c.px(x, 13, K)
        c.px(x, 14, K)
    c.px(0, 14, G)
    c.px(15, 14, G)
    c.px(8, 14, G)
    if stage == 0:
        c.px(3, 14, D)
        c.px(11, 14, D)
    if stage in (1, 2):  # warning: tips glint in the slots, grille rattles
        c.px(3, 13, W)
        c.px(11, 13, W)
        c.px(4 if stage == 1 else 2, 12, W)
        c.px(12 if stage == 1 else 10, 12, W)
        c.px(0 if stage == 1 else 15, 13, W)
    return c


def build_spikes():
    sheet('spikes', 16, 16, [
        A('floor', [spikes(True), spikes(False), spikes(True, True)], [0.16, 0.16, 0.08],
          note='blink bright/dim, occasional glint'),
        A('ceiling', [spikes(True).flip_v(), spikes(False).flip_v(), spikes(True, True).flip_v()],
          [0.16, 0.16, 0.08], note='same, hung from a ceiling'),
    ], 'Spikes `^` and ceiling spikes `v`. Danger reads from the teeth and the blink, not colour.')
    sheet('spike_vent', 16, 16, [
        A('down', [vent(0)], 0),
        A('warn', [vent(1), vent(2)], 0.07,
          note='last 0.3 s of the down phase: tips peek, grille rattles. Shake tile +-1 px'),
        A('rise', [vent(3), vent(4)], 0.04, loop=False),
        A('up', [vent(4), vent(5)], [0.2, 0.06]),
        A('retract', [vent(3), vent(0)], 0.05, loop=False),
    ], 'Spike vent `T`. Up 40% of the cycle.')


# =================================================================== loose ceiling

def ceiling_tile(stage):
    """0 intact, 1 cracking, 2 gone (hole left)."""
    c = ground(bottom=True, depth=1)
    # the chunk: a lighter wedge hanging from the underside, cut off by a crack
    for y in range(6, 16):
        half = 6 - max(0, y - 10)
        for x in range(8 - half, 8 + half):
            c.px(x, y, D)
    c.dith(3, 8, 10, 8, K, 3, only=D)
    crack = [(1, 7), (3, 6), (5, 8), (8, 6), (11, 8), (13, 6), (15, 7)]
    for (a, b) in zip(crack, crack[1:]):
        c.line(a[0], a[1], b[0], b[1], K)
    for y in range(11, 16):
        half = 6 - (y - 10)
        c.px(8 - half - 1, y, T)
        c.px(8 + half, y, T)
        c.px(8 - half, y, G)
        c.px(8 + half - 1, y, G)
    c.rect(6, 15, 4, 1, G)
    c.px(7, 15, W)
    c.rect(3, 15, 1, 1, T)
    c.rect(12, 15, 1, 1, T)
    c.px(7, 9, G)
    c.px(8, 9, G)
    if stage == 1:
        for (a, b) in zip(crack, crack[1:]):
            c.line(a[0], a[1] + 1, b[0], b[1] + 1, W)
        c.px(8, 15, W)
    if stage == 2:
        for y in range(7, 16):
            for x in range(16):
                if y > 7 + abs(x - 8) // 2 and 1 < x < 15:
                    c.px(x, y, T)
        for x in range(2, 15):
            c.px(x, 7 + abs(x - 8) // 2 + 1, K)
            c.px(x, 7 + abs(x - 8) // 2, G)
    return c


def trickle(f):
    c = C(16, 16)
    pts = [(7, 1 + f * 3), (9, 3 + f * 4), (8, 6 + f * 3), (6, 9 + f * 2)]
    for i, (x, y) in enumerate(pts):
        if y < 16:
            c.px(x, y, G if i % 2 else D)
    c.px(8, f * 5 % 16, W)
    return c


def chunk(k):
    c = C(16, 16)
    base = C(16, 16)
    base.art(2, 2, [
        '..gwwwg.....',
        '.gddddddg...',
        'gddkdddddg..',
        'dddddddkdd..',
        '.dkdddddd...',
        '..ddkddd....',
        '...dddd.....',
        '....kk......',
    ])
    base.outline(K)
    return base.rot90(k) if k else base


def build_ceiling():
    sheet('loose_ceiling', 16, 16, [
        A('intact', [ceiling_tile(0)], 0, note='a chunk outline hangs from the underside'),
        A('crack', [ceiling_tile(1), ceiling_tile(0)], 0.05,
          note='the 0.4 s tell: flicker these while the dust trickles below'),
        A('empty', [ceiling_tile(2)], 0, note='after the chunk drops'),
        A('dust', [trickle(f) for f in range(4)], 0.08, note='draw in the tile below the ceiling during the tell'),
        A('chunk', [chunk(k) for k in range(4)], 0.07, note='falling chunk tumbles'),
        A('landed', [rubble(1)], 0, note='chunk becomes rubble'),
    ], 'Loose ceiling `F`.')


# =================================================================== press

def press_head(stage):
    """0 rest, 1 warn a, 2 warn b, 3 slam, 4 hold."""
    c = C(16, 16)
    c.rect(1, 0, 14, 11, D)
    c.dith(2, 2, 12, 8, K, 3, only=D)
    c.rect(1, 0, 14, 1, G)
    c.rect(1, 0, 1, 11, G)
    c.rect(14, 0, 1, 11, K)
    # bolts
    c.px(3, 2, G)
    c.px(12, 2, G)
    # warning lamp
    lamp = W if stage in (1, 2, 3) else K
    c.rect(6, 3, 4, 4, K)
    c.rect(7, 4, 2, 2, lamp)
    if stage == 2:
        c.rect(6, 3, 4, 1, W)
        c.px(5, 5, W)
        c.px(10, 5, W)
    # teeth: the crushing face is a saw edge
    c.rect(0, 11, 16, 1, K)
    for x0 in range(0, 16, 4):
        tooth = W if stage in (2, 3) else G
        c.rect(x0, 12, 4, 1, tooth)
        c.rect(x0 + 1, 13, 2, 1, tooth)
        c.px(x0 + 1, 14, tooth if stage != 4 else G)
        c.px(x0 + 3, 12, K)
        c.px(x0 + 2, 14, K)
    c.outline(K)
    if stage == 3:  # speed streaks on the sides
        for y in (1, 4, 7):
            c.px(0, y, W)
            c.px(15, y + 1, W)
    return c


def press_shaft(mount=False):
    c = C(16, 16)
    for y in range(16):
        c.px(5, y, K)
        c.px(6, y, G)
        c.px(7, y, W)
        c.px(8, y, G)
        c.px(9, y, D)
        c.px(10, y, K)
    c.rect(5, 7, 6, 2, D)
    c.rect(5, 7, 6, 1, G)
    c.px(4, 7, K)
    c.px(11, 7, K)
    if mount:
        c.rect(1, 0, 14, 5, D)
        c.rect(1, 0, 14, 1, K)
        c.rect(1, 4, 14, 1, K)
        c.rect(1, 3, 14, 1, G)
        c.px(3, 2, G)
        c.px(12, 2, G)
    return c


def press_dust(f):
    c = C(48, 16)
    r = [2, 4, 5, 5][f]
    spread = [4, 9, 14, 18][f]
    col = [W, W, G, D][f]
    for side in (-1, 1):
        cx = 24 + side * spread
        c.ellipse(cx, 15 - r / 2, r, r * 0.7, col)
        c.ellipse(cx + side * 3, 14.5 - r / 3, r * 0.6, r * 0.5, col)
        if f < 3:
            c.ellipse(cx - side * 1, 14 - r / 2, r * 0.45, r * 0.4, G if col == W else D)
    if f == 0:
        c.rect(16, 15, 16, 1, W)
    if f >= 2:
        c.dith(0, 0, 48, 16, T, 6 if f == 2 else 10)
    return c


def build_press():
    sheet('press', 16, 16, [
        A('rest', [press_head(0)], 0),
        A('warn', [press_head(1), press_head(2)], 0.05,
          note='0.3 s before the slam: lamp lights, teeth whiten. Shake the head +-1 px x at 20 Hz'),
        A('slam', [press_head(3)], 0, note='while travelling down (0.12 s)'),
        A('hold', [press_head(4)], 0, note='pinned to the floor for 0.35 s, then rises in rest frame'),
        A('shaft', [press_shaft(False), press_shaft(True)], 0,
          note='0 = piston, tile it from the mount down to the head. 1 = ceiling mount'),
    ], 'Press `X`. Head is 16x16 and slides. The shaft stretches behind it.')
    sheet('press_dust', 48, 16, [
        A('puff', [press_dust(f) for f in range(4)], [0.04, 0.06, 0.08, 0.1], loop=False,
          note='centre on the head, bottom on the floor'),
    ], 'Press slam dust.')


# =================================================================== dropper

def dropper(state):
    """idle, blink, tell_a, tell_b, fall, land, rise_a, rise_b"""
    c = C(32, 32)
    top = 3 if state == 'land' else 0
    body_h = 32 - top
    c.rect(1, top, 30, body_h - 2, D)
    c.dith(2, top + 3, 28, body_h - 6, K, 3, only=D)
    # rideable lip
    c.rect(1, top, 30, 2, W)
    c.rect(1, top + 2, 30, 1, G)
    c.rect(1, top, 1, body_h - 2, G)
    c.rect(30, top + 1, 1, body_h - 3, K)
    for (x, y) in ((4, top + 5), (27, top + 5), (4, 25), (27, 25)):
        c.px(x, y, G)
    # crushing underside
    by = 29
    c.rect(1, by - 1, 30, 1, K)
    for x0 in range(1, 31, 5):
        c.rect(x0, by, 4, 1, G)
        c.rect(x0 + 1, by + 1, 2, 1, G if state not in ('fall', 'tell_b') else W)
    # face plate
    fy = top + 9 if state != 'land' else top + 8
    c.rect(6, fy - 2, 20, 12, K)
    c.rect(7, fy - 1, 18, 10, D)
    # eyes
    def eye(x, mode):
        if mode == 'half':
            c.rect(x, fy + 3, 6, 3, K)
            c.rect(x + 1, fy + 4, 2, 1, G)
        elif mode == 'shut':
            c.rect(x, fy + 4, 6, 1, K)
        elif mode == 'wide':
            c.rect(x, fy + 1, 6, 6, K)
            c.rect(x + 2, fy + 4, 2, 2, W)
        elif mode == 'wide2':
            c.rect(x, fy, 6, 7, K)
            c.rect(x + 2, fy + 4, 2, 2, W)
            c.px(x + 2, fy + 3, G)
        elif mode == 'angry':
            c.rect(x, fy + 2, 6, 4, K)
            c.rect(x + 2, fy + 3, 2, 2, W)
        elif mode == 'calm':
            c.rect(x, fy + 4, 6, 1, K)
            c.px(x, fy + 3, K)
            c.px(x + 5, fy + 3, K)
    mode = {'idle': 'half', 'blink': 'shut', 'tell_a': 'wide', 'tell_b': 'wide2', 'fall': 'angry',
            'land': 'angry', 'rise_a': 'calm', 'rise_b': 'calm'}[state]
    eye(8, mode)
    eye(18, mode)
    # brows
    if state in ('fall', 'land'):
        c.line(8, fy + 1, 13, fy + 2, W)
        c.line(18, fy + 2, 23, fy + 1, W)
    elif state in ('tell_a', 'tell_b'):
        c.rect(8, fy - 1, 6, 1, G)
        c.rect(18, fy - 1, 6, 1, G)
    if state == 'tell_b':  # strain marks on the sides
        for y in (8, 14, 20):
            c.px(0, y, W)
            c.px(31, y + 2, W)
    if state == 'rise_b':
        c.px(15, 1, W)
        c.px(16, 0, G)
    c.rect(0, 0, 32, 32, T) if False else None
    c.outline(K)
    return c


def dropper_dust(f):
    c = C(48, 16)
    d = press_dust(f)
    c.paste(d, 0, 0)
    return c


def build_dropper():
    order = ['idle', 'blink', 'tell_a', 'tell_b', 'fall', 'land', 'rise_a', 'rise_b']
    fr = {s: dropper(s) for s in order}
    sheet('dropper', 32, 32, [
        A('idle', [fr['idle'], fr['blink'], fr['idle']], [2.0, 0.1, 0.4], note='half-lidded, blinks now and then'),
        A('tell', [fr['tell_a'], fr['tell_b']], 0.06,
          note='you passed under: eyes snap open, strain marks. Shake +-1 px for 0.15 s before it drops'),
        A('fall', [fr['fall']], 0, note='teeth whiten while it falls'),
        A('land', [fr['land'], fr['fall']], [0.1, 0.1], loop=False,
          note='squash on impact (shake screen 2 px, spawn press_dust). Waits 1.5 s'),
        A('rise', [fr['rise_a'], fr['rise_b']], 0.3, note='rides slowly back up, eyes closed: safe to ride'),
    ], 'Dropper `D` (2x2). The top 2 px are a white lip because you ride it.')


# =================================================================== plate, gate, lever, spring

def plate(state):
    c = C(16, 16)
    c.rect(0, 14, 16, 2, D)
    c.rect(0, 15, 16, 1, K)
    if state == 0:  # up
        c.rect(2, 11, 12, 3, D)
        c.rect(2, 11, 12, 1, W)
        c.rect(2, 12, 12, 1, G)
        c.px(7, 13, K)
        c.px(8, 13, K)
    elif state == 1:  # half
        c.rect(2, 12, 12, 2, D)
        c.rect(2, 12, 12, 1, W)
    else:  # down: flush, lit channel shows it is holding
        c.rect(2, 13, 12, 1, G)
        c.rect(5, 14, 6, 1, W)
    c.outline(K)
    return c


def gate_piece(kind, state=0):
    c = C(16, 16)
    if kind == 'bars':
        for x in (3, 7, 11):
            c.rect(x, 0, 2, 16, G)
            c.px(x, 0, W)
            c.rect(x + 1, 0, 1, 16, D)
        c.rect(2, 7, 12, 2, D)
        c.rect(2, 7, 12, 1, G)
        c.outline(K)
    elif kind == 'foot':
        for x in (3, 7, 11):
            c.rect(x, 0, 2, 12, G)
            c.rect(x + 1, 0, 1, 12, D)
            c.rect(x, 12, 2, 2, W)
            c.px(x, 14, W)
        c.outline(K)
    elif kind == 'cap':  # housing above the gate, with the state lamp
        c.rect(0, 0, 16, 16, D)
        c.dith(1, 1, 14, 14, K, 4, only=D)
        c.frame(0, 0, 16, 16, K)
        c.rect(1, 1, 14, 1, G)
        c.rect(2, 12, 12, 3, K)
        lamp = {0: K, 1: W, 2: G, 3: W}[state]
        c.rect(6, 4, 4, 4, K)
        c.rect(7, 5, 2, 2, lamp)
        if state == 3:
            c.px(5, 6, G)
            c.px(10, 6, G)
            c.px(7, 3, G)
            c.px(8, 3, G)
    return c


def lever(pos):
    """0 = off (leaning left), 1 = mid, 2 = on (leaning right)."""
    c = C(16, 16)
    c.rect(3, 12, 10, 4, D)
    c.rect(3, 12, 10, 1, G)
    c.rect(3, 15, 10, 1, K)
    c.px(5, 14, G)
    c.px(10, 14, G)
    ends = {0: (4, 3), 1: (8, 2), 2: (12, 3)}
    ex, ey = ends[pos]
    c.line(8, 11, ex, ey + 2, G)
    c.line(8, 11, ex + (1 if pos == 0 else 0), ey + 3, G if pos != 2 else W)
    c.rect(ex - 1, ey, 3, 3, W)
    c.outline(K)
    if pos == 2:
        c.rect(6, 13, 4, 1, W)
    return c


def spring(state):
    """0 rest, 1 compressed, 2 extended."""
    c = C(16, 16)
    top = {0: 7, 1: 11, 2: 3}[state]
    # coil between the pad and the base
    y = top + 3
    k = 0
    while y < 13:
        x0, x1 = (3, 12) if k % 2 == 0 else (4, 11)
        c.rect(x0, y, x1 - x0 + 1, 1, G if k % 2 == 0 else W)
        y += 2 if state != 1 else 1
        k += 1
    c.rect(1, top, 14, 3, D)
    c.rect(1, top, 14, 1, W)
    c.rect(1, top + 1, 14, 1, G)
    c.rect(1, 13, 14, 3, D)
    c.rect(1, 13, 14, 1, G)
    c.rect(1, 15, 14, 1, K)
    c.outline(K)
    if state == 0:
        c.px(7, top - 2, G)
        c.px(8, top - 2, G)
    return c


def build_switches():
    sheet('plate', 16, 16, [
        A('up', [plate(0)], 0),
        A('press', [plate(1), plate(2)], 0.04, loop=False),
        A('down', [plate(2)], 0, note='held by the Spark, an enemy or rubble'),
        A('release', [plate(1), plate(0)], 0.05, loop=False),
    ], 'Pressure plate `_`.')
    sheet('gate', 16, 16, [
        A('pieces', [gate_piece('bars'), gate_piece('foot')], 0,
          note='0 = bar section (repeat), 1 = foot (bottom tile). The whole gate slides up into its cap'),
        A('cap_closed', [gate_piece('cap', 0)], 0, note='cap sits in the ceiling above the gate'),
        A('cap_opening', [gate_piece('cap', 1), gate_piece('cap', 2)], 0.06,
          note='blinks while the gate rises (0.4 s) and during the last second of a timed gate'),
        A('cap_open', [gate_piece('cap', 3)], 0),
    ], 'Gate `|`. Bars are hard verticals so they read as a wall.')
    sheet('lever', 16, 16, [
        A('off', [lever(0)], 0),
        A('pull', [lever(0), lever(1), lever(2)], [0.05, 0.06, 0.1], loop=False),
        A('on', [lever(2)], 0),
    ], 'Lever `K`.')
    sheet('spring', 16, 16, [
        A('rest', [spring(0)], 0),
        A('bounce', [spring(1), spring(2), spring(0)], [0.05, 0.08, 0.1], loop=False,
          note='compress on contact, launch on the extended frame'),
    ], 'Spring `S`.')


# =================================================================== ring, shards, pickups

def ring(f, used=False, flash=False):
    c = C(24, 24)
    cx, cy = 12, 12
    for y in range(24):
        for x in range(24):
            d = math.hypot(x + 0.5 - cx, y + 0.5 - cy)
            if 5.0 <= d <= 7.2:
                if used:
                    if bayer(x, y) < 8:
                        c.px(x, y, D)
                else:
                    c.px(x, y, W if d < 6.2 else G)
            elif 8.5 <= d <= 9.5 and not used:
                ang = math.atan2(y + 0.5 - cy, x + 0.5 - cx)
                seg = int(((ang + math.pi) / (2 * math.pi)) * 8 + f * 0.5) % 4
                if seg == 0 and bayer(x, y) < 10:
                    c.px(x, y, G)
    if not used:
        # orbiting pip
        a = f / 4 * 2 * math.pi
        c.px(int(cx + math.cos(a) * 6), int(cy + math.sin(a) * 6), K)
        # up-arrow core
        c.art(10, 9, ['.ww.', 'wwww', '.ww.', '.ww.'] if f % 2 == 0 else ['.ww.', 'wwww', '.gg.', '.gg.'])
    if flash:
        c.ellipse(12, 12, 8, 8, W)
        c.ellipse(12, 12, 4, 4, T)
    c.outline(K)
    return c


def shard(f, big=False):
    size = 24 if big else 16
    c = C(size, size)
    cx = size // 2
    h = 9 if big else 5
    widths = [h, h - 1, h - 3, 1, h - 3, h - 1]
    w = widths[f]
    for y in range(-h, h + 1):
        half = int(w * (1 - abs(y) / (h + 0.5)) + 0.5)
        for x in range(-half, half + 1):
            col = W
            if x > 0 and f in (1, 2):
                col = G
            if x < 0 and f in (4, 5):
                col = G
            c.px(cx + x, cx + y, col)
    if w > 1:
        c.px(cx, cx, K)
        if big:
            c.rect(cx - 1, cx - 3, 3, 7, K)
            c.rect(cx - 3, cx - 1, 7, 3, K)
            c.rect(cx - 1, cx - 1, 3, 3, W)
            c.px(cx, cx, K)
    c.outline(K)
    if big:  # crown pips mark it as a big shard
        c.px(cx - 6, 2, G)
        c.px(cx + 6, 2, G)
        c.px(cx, 0, W)
    return c


def sparkle(f):
    c = C(8, 8)
    n = [1, 3, 2, 1][f]
    col = [W, W, G, G][f]
    for k in range(-n, n + 1):
        c.px(3 + k, 3, col)
        c.px(3, 3 + k, col)
    c.px(3, 3, W)
    if f == 1:
        for (x, y) in ((2, 2), (4, 2), (2, 4), (4, 4)):
            c.px(x, y, G)
    return c


def charge_item(f):
    c = C(16, 16)
    c.rect(4, 3, 8, 11, W)
    c.rect(6, 2, 4, 1, W)
    c.art(5, 4, ['..kk..'[:6], '.kk...', 'kkkkk.', '..kk..', '.kk...', 'kk....'][:6])
    c.art(5, 4, ['..kk', '.kk.', 'kkkk', '..kk', '.kk.', 'kk..'])
    c.outline(K)
    pts = [(2, 4), (13, 7), (2, 11), (13, 2)]
    x, y = pts[f % 4]
    c.px(x, y, W)
    c.px(x, y - 1, G)
    c.px(x, y + 1, G)
    return c


def life_item(f):
    c = C(16, 16)
    y = 4 if f == 0 else 3
    c.rect(4, y, 8, 9, W)
    c.rect(8, y + 2, 3, 2, K)
    c.px(8, y + 2, G)
    c.rect(2, y + 3, 2, 2, G)
    c.rect(5, y + 9, 2, 1, W)
    c.rect(9, y + 9, 2, 1, W)
    c.outline(K)
    return c


def build_pickups():
    sheet('lift_ring', 24, 24, [
        A('idle', [ring(f) for f in range(4)], 0.1, note='centre on the tile centre'),
        A('pop', [ring(0, flash=True), ring(0, used=True)], [0.06, 0.1], loop=False),
        A('used', [ring(0, used=True)], 0, note='spent until the Spark touches ground'),
    ], 'Lift ring `R`.')
    sheet('shard', 16, 16, [
        A('spin', [shard(f) for f in range(6)], [0.4, 0.08, 0.06, 0.05, 0.06, 0.08], note='bob +-2 px in code'),
    ], 'Shard `o`.')
    sheet('big_shard', 24, 24, [
        A('spin', [shard(f, True) for f in range(6)], [0.5, 0.08, 0.06, 0.05, 0.06, 0.08]),
    ], 'Big shard `O`. Draw fx sparkles around it.')
    sheet('pickups', 16, 16, [
        A('charge', [charge_item(f) for f in range(4)], 0.08, note='CHARGE cell that rises out of a C block'),
        A('life', [life_item(f) for f in range(2)], 0.2, note='1UP: a little Spark'),
    ], 'Items that come out of bump blocks.')


# =================================================================== enemies

def static_body(c, x0, y0, w, h, f, eye_side=-1, eye=(3, 3), eye_mode='open', flash=False, round_=2):
    """NOISE body: rounded block of static stripes (W/G rows) with one eye."""
    for y in range(h):
        for x in range(w):
            # round the corners
            if (y < round_ or y >= h - 1) and (x < round_ - (y if y < round_ else 0) or x >= w - round_ + (y if y < round_ else 0)):
                if y < round_ and (x + y < round_ or (w - 1 - x) + y < round_):
                    continue
            col = W if (y + f) % 3 else G
            if flash:
                col = G if (y + f) % 3 else D
            # static tears: a broken segment that crawls with the frame
            if (y + f) % 3 == 0 and ((x + f * 3 + y * 5) % 11) < 2:
                col = D
            c.px(x0 + x, y0 + y, col)
    ew, eh = eye
    ex = x0 + (2 if eye_side < 0 else w - 2 - ew)
    ey = y0 + max(2, h // 3)
    if eye_mode == 'open':
        c.rect(ex, ey, ew, eh, K)
        c.px(ex + (0 if eye_side < 0 else ew - 1), ey + eh // 2, W)
    elif eye_mode == 'wide':
        c.rect(ex - 1, ey - 1, ew + 2, eh + 2, K)
        c.px(ex + ew // 2, ey + eh // 2, W)
    elif eye_mode == 'up':
        c.rect(ex, ey, ew, eh, K)
        c.px(ex + ew // 2, ey, W)
    elif eye_mode == 'x':
        c.line(ex, ey, ex + ew - 1, ey + eh - 1, K)
        c.line(ex, ey + eh - 1, ex + ew - 1, ey, K)
    elif eye_mode == 'shut':
        c.rect(ex, ey + eh // 2, ew, 1, K)


def walker(f, mode='walk'):
    c = C(16, 16)
    squash = 1 if mode == 'tell' else 0
    y0 = 3 + squash
    static_body(c, 2, y0, 12, 10 - squash, f, eye_side=-1, eye=(3, 3),
                eye_mode='wide' if mode == 'tell' else 'open', flash=(mode == 'tell' and f % 2 == 1))
    # antenna
    c.px(10, y0 - 1, D)
    c.px(10, y0 - 2, D)
    c.px(11, y0 - 3, G if mode != 'tell' else W)
    # legs
    legs = {0: ((4, 2), (10, 2)), 1: ((3, 3), (10, 1)), 2: ((4, 2), (10, 2)), 3: ((4, 1), (11, 3))}
    if mode == 'walk':
        (lx, lh), (rx, rh) = legs[f]
    else:
        (lx, lh), (rx, rh) = ((3, 2), (11, 2))
    c.rect(lx, 13, 2, lh, D)
    c.rect(rx, 13, 2, rh, D)
    c.outline(K)
    return c


def walker_flat():
    c = C(16, 16)
    static_body(c, 1, 11, 14, 4, 0, eye=(3, 2), eye_mode='x', round_=1)
    c.rect(0, 15, 16, 1, D)
    c.outline(K)
    return c


def hopper(mode, f=0):
    c = C(16, 16)
    y0 = {'idle': 4 + (f % 2), 'crouch': 7, 'jump': 1, 'fall': 2, 'land': 6, 'flat': 11}[mode]
    h = {'idle': 7, 'crouch': 6, 'jump': 8, 'fall': 7, 'land': 6, 'flat': 4}[mode]
    w = 10 if mode != 'flat' else 12
    x0 = 3 if mode != 'flat' else 2
    static_body(c, x0, y0, w, h, f, eye_side=-1, eye=(2, 3) if mode != 'flat' else (2, 2),
                eye_mode={'crouch': 'up', 'flat': 'x', 'jump': 'open', 'fall': 'wide'}.get(mode, 'open'),
                flash=(mode == 'crouch' and f % 2 == 1))
    if mode != 'flat':
        # two antennae
        c.px(x0 + 3, y0 - 1, D)
        c.px(x0 + 7, y0 - 1, D)
        c.px(x0 + 3, y0 - 2, G)
        c.px(x0 + 7, y0 - 2, G)
        # coil legs
        ly = y0 + h
        coil = {'idle': 16 - ly, 'crouch': 16 - ly, 'jump': 5, 'fall': 3, 'land': 16 - ly}[mode]
        for k in range(coil):
            for lx in (x0 + 2, x0 + w - 3):
                c.px(lx + (1 if k % 2 else 0), ly + k, G if k % 2 else D)
        if mode in ('jump', 'fall'):
            c.rect(x0 + 1, ly + coil, 3, 1, D)
            c.rect(x0 + w - 4, ly + coil, 3, 1, D)
    c.outline(K)
    if mode == 'crouch':  # strain ticks
        c.px(0, 9 + f % 2, W)
        c.px(15, 10 - f % 2, W)
    return c


def warden(mode, f=0):
    c = C(32, 32)
    y0 = {'walk': 6 + (f % 2), 'crouch': 11, 'hop': 2, 'fall': 5, 'hurt': 8}[mode]
    h = {'walk': 20, 'crouch': 16, 'hop': 20, 'fall': 19, 'hurt': 18}[mode]
    x0, w = 5, 22
    if mode == 'crouch':
        x0, w = 4, 24
    static_body(c, x0, y0, w, h, f, eye_side=-1, eye=(6, 5),
                eye_mode={'crouch': 'up', 'fall': 'wide', 'hurt': 'x'}.get(mode, 'open'),
                flash=(mode == 'crouch' and f % 2 == 1) or mode == 'hurt', round_=4)
    # a dark visor band: the warden is armoured
    c.rect(x0 + 1, y0 + h - 6, w - 2, 2, D)
    c.rect(x0 + 1, y0 + h - 6, w - 2, 1, K)
    # horns / antenna mast
    if mode == 'fall':
        c.line(x0 + 4, y0, x0 + 1, y0 - 4, D)
        c.line(x0 + w - 5, y0, x0 + w - 1, y0 - 3, D)
        c.px(x0 + 1, y0 - 5, W)
        c.px(x0 + w - 1, y0 - 4, W)
    else:
        c.line(x0 + 4, y0, x0 + 3, y0 - 4, D)
        c.line(x0 + w - 5, y0, x0 + w - 4, y0 - 4, D)
        c.px(x0 + 3, y0 - 5, W if mode == 'crouch' else G)
        c.px(x0 + w - 4, y0 - 5, W if mode == 'crouch' else G)
    # feet
    fy = y0 + h
    if mode == 'walk':
        lf = (x0 + 2, 32 - fy - (1 if f in (1,) else 0))
        rf = (x0 + w - 8, 32 - fy - (1 if f in (3,) else 0))
        for (fx, fh) in (lf, rf):
            c.rect(fx, fy, 6, max(1, fh), D)
            c.rect(fx, fy, 6, 1, G)
        if f == 1:
            c.rect(x0 + 2, 30, 6, 2, T)
        if f == 3:
            c.rect(x0 + w - 8, 30, 6, 2, T)
    elif mode == 'crouch':
        c.rect(x0 + 1, fy, 8, 32 - fy, D)
        c.rect(x0 + w - 9, fy, 8, 32 - fy, D)
    elif mode == 'hop':
        c.rect(x0 + 3, fy, 6, 3, D)
        c.rect(x0 + w - 9, fy, 6, 3, D)
    elif mode == 'fall':
        c.rect(x0 - 2, fy - 2, 5, 3, D)
        c.rect(x0 + w - 3, fy, 5, 3, D)
        # flailing arms
        c.line(x0 - 1, y0 + 6, x0 - 4, y0 + 2 + (f % 2) * 3, G)
        c.line(x0 + w, y0 + 6, x0 + w + 3, y0 + 1 + ((f + 1) % 2) * 3, G)
    elif mode == 'hurt':
        c.rect(x0 + 2, fy, 6, 32 - fy, D)
        c.rect(x0 + w - 8, fy, 6, 32 - fy, D)
    c.outline(K)
    if mode == 'crouch':
        for y in (14, 20):
            c.px(1, y + f % 2, W)
            c.px(30, y + 1 - f % 2, W)
    return c


def build_enemies():
    sheet('walker', 16, 16, [
        A('walk', [walker(f) for f in range(4)], 0.12, note='faces left, flip for right'),
        A('turn', [walker(0, 'tell'), walker(1, 'tell')], 0.06,
          note='2 frames at a wall or ledge before it turns: squash, eye wide, body flickers'),
        A('stomped', [walker_flat()], 0, note='hold 0.3 s, then fx burst'),
    ], 'Walker `w`: a NOISE blob. Static stripes crawl, so it never reads as the solid-white Spark.')
    sheet('hopper', 16, 16, [
        A('idle', [hopper('idle', 0), hopper('idle', 1)], 0.2),
        A('crouch', [hopper('crouch', 0), hopper('crouch', 1), hopper('crouch', 2)], 0.08,
          note='tell before every hop (0.24 s): squats, eye looks up, strain ticks'),
        A('jump', [hopper('jump', 0)], 0),
        A('fall', [hopper('fall', 0)], 0),
        A('land', [hopper('land', 0)], 0.08, loop=False),
        A('stomped', [hopper('flat', 0)], 0),
    ], 'Hopper `k`.')
    sheet('warden', 32, 32, [
        A('walk', [warden('walk', f) for f in range(4)], 0.16, note='faces left'),
        A('hop_tell', [warden('crouch', f) for f in range(3)], 0.08,
          note='crouches for 0.3 s before each hop: this is the window to run under'),
        A('hop', [warden('hop', 0)], 0),
        A('fall', [warden('fall', f) for f in range(2)], 0.1, note='bridge gone: flails as it drops'),
        A('hurt', [warden('hurt', f) for f in range(2)], 0.06),
    ], 'Warden `W` (2x2), world boss.')


# =================================================================== pipe, beacon, mast

def pipe(kind, f=0):
    c = C(32, 16)
    if kind == 'mouth':
        c.rect(0, 2, 32, 7, D)
        c.rect(0, 2, 32, 1, W)
        c.rect(0, 3, 32, 1, G)
        c.rect(0, 8, 32, 1, K)
        c.rect(0, 2, 1, 7, G)
        c.rect(31, 2, 1, 7, K)
        # dark throat seen from the front
        c.rect(4, 0, 24, 2, K)
        c.rect(3, 1, 26, 1, K)
        for x in (6, 12, 19, 25):
            c.px(x, 5, G)
            c.px(x + 1, 6, K)
        c.rect(2, 9, 28, 7, D)
        c.rect(2, 9, 2, 7, G)
        c.rect(28, 9, 2, 7, K)
        for x in range(8, 26, 6):
            c.rect(x, 9, 1, 7, K)
        # draught: dust pulled into the mouth
        if f == 1:
            c.px(10, 0, G)
            c.px(21, 1, D)
        c.outline(K)
    else:
        c.rect(2, 0, 28, 16, D)
        c.rect(2, 0, 2, 16, G)
        c.rect(28, 0, 2, 16, K)
        for x in range(8, 26, 6):
            c.rect(x, 0, 1, 16, K)
        c.rect(4, 7, 24, 2, K)
        c.rect(4, 7, 24, 1, G)
        c.outline(K)
    return c


def beacon(state, f=0):
    """dark, ignite_a, ignite_b, lit (f 0..2)."""
    c = C(16, 32)
    # base plinth
    c.rect(4, 28, 8, 4, D)
    c.rect(4, 28, 8, 1, G)
    lit = state != 'dark'
    # pole
    c.rect(7, 8, 2, 20, G if lit else D)
    c.px(7, 8, W if lit else G)
    # lamp head
    c.rect(4, 3, 8, 6, D)
    c.rect(5, 4, 6, 4, K)
    if state == 'ignite_a':
        c.rect(3, 2, 10, 8, W)
    elif state == 'ignite_b':
        c.rect(5, 4, 6, 4, W)
        c.rect(4, 3, 8, 1, W)
    elif state == 'lit':
        c.rect(6, 5, 4, 2, W)
        c.px(5, 5, G)
        c.px(10, 6, G)
    # pennant
    if lit:
        wave = [(0, 1, 2, 2), (1, 2, 2, 1), (1, 1, 1, 2)][f % 3]
        for i in range(5):
            h = 4 - i * 0.6
            yy = 11 + wave[i % 4] - 1
            c.rect(9 + i, yy, 1, max(1, int(h)), W if i < 3 else G)
    else:
        c.rect(9, 10, 1, 5, D)
        c.rect(10, 11, 1, 4, D)
        c.rect(11, 12, 1, 2, D)
    c.outline(K)
    return c


def mast_piece(kind, f=0):
    c = C(16, 16)
    if kind == 'pole':
        c.rect(7, 0, 2, 16, G)
        c.rect(7, 0, 1, 16, W)
        c.px(6, 8, K)
        c.px(9, 8, K)
        c.rect(6, 7, 4, 1, D)
    elif kind == 'top':
        c.rect(7, 8, 2, 8, G)
        c.rect(7, 8, 1, 8, W)
        c.ellipse(8, 5, 4, 4, W)
        c.ellipse(9, 6, 2, 2, G)
        c.px(6, 3, K) if f == 1 else c.px(6, 3, W)
        c.line(8, 0, 8, 1, G)
        c.outline(K)
        if f == 1:
            c.px(1, 5, G)
            c.px(14, 5, G)
            c.px(8, 0, W)
    elif kind == 'base':
        c.rect(2, 6, 12, 10, D)
        c.dith(3, 8, 10, 7, K, 4, only=D)
        c.rect(2, 6, 12, 1, W)
        c.rect(2, 7, 12, 1, G)
        c.rect(7, 0, 2, 6, G)
        c.rect(7, 0, 1, 6, W)
        c.rect(5, 10, 6, 3, K)
        c.rect(6, 11, 4, 1, W if f else D)
        c.outline(K)
    return c


def flag(f, lit=False):
    """24x16. Column 23 lines up with the pole's lit column (x 7 of a pole tile)."""
    c = C(24, 16)
    col = W if lit else G
    shade = G if lit else D
    for i in range(15):
        x = 22 - i  # hangs to the left of the pole
        wave = int(round(math.sin(f * math.pi / 2 - i * 0.5) * (i / 14) * 1.5))
        top = 3 + wave
        for y in range(8):
            if i >= 12 and 3 <= y <= 4 + (i - 12):
                continue  # swallowtail notch
            c.px(x, top + y, col if y < 6 else shade)
        c.px(x, top, W if lit else col)
    # signal ring cut into the banner
    rx = 15
    c.rect(rx, 5, 3, 3, K)
    c.px(rx + 1, 6, col)
    c.outline(K)
    c.rect(23, 0, 1, 16, T)
    return c


def build_markers():
    sheet('pipe', 32, 16, [
        A('mouth', [pipe('mouth', 0), pipe('mouth', 1)], [0.6, 0.15], note='sits on the top pipe tile'),
        A('body', [pipe('body')], 0, note='repeat below the mouth'),
    ], 'Pipe `p` (2 tiles wide). Press down on the mouth to enter.')
    sheet('beacon', 16, 32, [
        A('dark', [beacon('dark')], 0),
        A('ignite', [beacon('ignite_a'), beacon('ignite_b')], [0.05, 0.08], loop=False,
          note='with fx light_up ring and a 2 px shake'),
        A('lit', [beacon('lit', f) for f in range(3)], 0.15),
    ], 'Midway beacon `M`. Anchor bottom-centre on the tile it stands on.')
    sheet('mast', 16, 16, [
        A('pieces', [mast_piece('base'), mast_piece('pole'), mast_piece('top', 0)], 0,
          note='0 base (the G tile), 1 pole (stack 6 up), 2 top'),
        A('top_lit', [mast_piece('top', 0), mast_piece('top', 1)], 0.2, note='after you touch the mast'),
        A('base_lit', [mast_piece('base', 1)], 0),
    ], 'Goal mast `G`.')
    sheet('mast_flag', 24, 16, [
        A('wave', [flag(f) for f in range(4)], 0.14,
          note='draw at pole tile x - 16 so the pennant hangs left of the pole'),
        A('lit', [flag(f, True) for f in range(4)], 0.08, note='touched: lights and slides down the pole'),
    ], 'Goal mast pennant.')


# =================================================================== gate transmitter backdrop

def transmitter(f, awake=False):
    w, h = 128, 224
    c = C(w, h)
    cx = 64
    top, base = 36, 208

    def half_at(y):
        return 5 + (y - top) / (base - top) * 44

    # body: sparse dither between the legs reads as a far silhouette
    for y in range(top, base):
        hw = int(half_at(y))
        for x in range(cx - hw, cx + hw + 1):
            if bayer(x, y) < 3:
                c.px(x, y, D)
    # legs, two px thick
    for y in range(top, base):
        hw = int(half_at(y))
        for side in (-1, 1):
            c.px(cx + side * hw, y, D)
            c.px(cx + side * (hw - 1), y, D)
    # sections: a beam and X braces every 16 px
    y = top
    while y < base - 1:
        y2 = min(y + 16, base - 1)
        a, b = int(half_at(y)), int(half_at(y2))
        c.rect(cx - a, y, a * 2 + 1, 1, D)
        c.line(cx - a, y, cx + b, y2, D)
        c.line(cx + a, y, cx - b, y2, D)
        y = y2
    # service platforms with rails
    for (yy, ww) in ((78, 30), (126, 40), (174, 50)):
        c.rect(cx - ww, yy, ww * 2 + 1, 2, D)
        for x in range(cx - ww, cx + ww + 1, 4):
            c.px(x, yy - 1, D)
            c.px(x, yy - 2, D)
        c.rect(cx - ww, yy - 3, ww * 2 + 1, 1, D)
    # two dishes on arms
    for (dx, dy, r, side) in ((-30, 100, 11, -1), (34, 148, 13, 1)):
        ox, oy = cx + dx, dy
        c.ellipse(ox, oy, r * 0.55, r, D)
        c.ellipse(ox - side * 2, oy, r * 0.4, r - 2, T)
        c.line(ox, oy, ox + side * r, oy, D)
        c.px(ox + side * (r + 1), oy, D)
        c.line(ox, oy, cx + side * int(half_at(oy)), oy, D)
    # spire with rungs
    c.rect(cx - 1, 12, 3, top - 12, D)
    for yy in range(14, top, 4):
        c.rect(cx - 3, yy, 7, 1, D)
    c.rect(cx - 6, 22, 13, 1, D)
    c.rect(cx - 9, 30, 19, 1, D)
    # base bunker
    c.rect(cx - 56, base, 113, 16, D)
    c.dith(cx - 56, base + 2, 113, 14, K, 6, only=D)
    c.rect(cx - 56, base, 113, 1, K)
    c.rect(cx - 6, base + 6, 12, 10, K)
    # the one lit pixel
    c.px(cx, 9, W)
    c.px(cx, 10, G)
    c.px(cx, 11, D)
    # signal arcs crackle off the tip
    if f > 0:
        r = [0, 7, 12, 17][f]
        for a in range(180, 360, 2):
            ang = math.radians(a)
            x = int(round(cx + math.cos(ang) * r))
            yy = int(round(10 + math.sin(ang) * r * 0.55))
            if (a // 8 + f) % 3 != 0:
                c.px(x, yy, W if awake else G)
    if awake:
        for yy in range(top + 2, base, 3):
            c.px(cx, yy, G)
        for (yy, ww) in ((78, 30), (126, 40), (174, 50)):
            c.px(cx - ww, yy - 4, W)
            c.px(cx + ww, yy - 4, W)
        c.rect(cx - 3, base + 8, 6, 1, G)
    return c


def build_backdrop():
    sheet('gate_transmitter', 128, 224, [
        A('dormant', [transmitter(0), transmitter(1), transmitter(2), transmitter(3)], [3.2, 0.07, 0.07, 0.09],
          note='far layer, parallax 0.2x. Dark silhouette, one lit pixel. Arcs crackle about every 4 s'),
        A('awake', [transmitter(0, True), transmitter(1, True), transmitter(2, True), transmitter(3, True)],
          [0.8, 0.07, 0.07, 0.09], note='after the Gate is lit: arcs every second, frame lamps on'),
    ], 'Gate transmitter backdrop landmark for 1-4. Draw at 70% opacity behind the play layer.')


# =================================================================== effects

def fx_dust(f):
    c = C(16, 8)
    spread = [2, 4, 6, 7, 7][f]
    r = [1.6, 2.2, 2.2, 1.6, 1.0][f]
    col = [W, W, G, G, D][f]
    for side in (-1, 1):
        c.ellipse(8 + side * spread, 7 - r * 0.6, r, r * 0.8, col)
    return c


def fx_burst(f):
    c = C(32, 32)
    r = [3, 7, 10, 12, 13][f]
    for a in range(8):
        ang = a * math.pi / 4 + (math.pi / 8 if a % 2 else 0)
        L = r if a % 2 == 0 else r - 3
        inner = max(1, r - 5)
        x0 = 16 + math.cos(ang) * inner
        y0 = 16 + math.sin(ang) * inner
        x1 = 16 + math.cos(ang) * L
        y1 = 16 + math.sin(ang) * L
        c.line(int(x0), int(y0), int(x1), int(y1), W if f < 3 else G)
    if f < 2:
        c.ellipse(16, 16, 3 - f, 3 - f, W)
    if f >= 2:
        for y in range(32):
            for x in range(32):
                d = math.hypot(x + 0.5 - 16, y + 0.5 - 16)
                if abs(d - (r - 2)) < 0.6 and bayer(x, y) < 8:
                    c.px(x, y, D if f == 4 else G)
    return c


def fx_glow(f):
    """CHARGE glow around the 12x14 Spark (centred)."""
    c = C(24, 24)
    x0, y0, w, h = 5, 4, 14, 16
    for y in range(24):
        for x in range(24):
            inside = x0 <= x < x0 + w and y0 <= y < y0 + h
            dx = max(x0 - x, 0, x - (x0 + w - 1))
            dy = max(y0 - y, 0, y - (y0 + h - 1))
            d = max(dx, dy)
            if inside:
                continue
            if d == 1:
                if (x + y + f) % 4 != 0:
                    c.px(x, y, W if (x + y + f) % 4 == 1 else G)
            elif d == 2 or d == 3:
                if bayer(x + f, y) < (6 if d == 2 else 2):
                    c.px(x, y, G if d == 2 else D)
    # crackle
    pts = [(3, 6), (20, 9), (4, 18), (19, 3)]
    x, y = pts[f % 4]
    c.rect(x - 1, y, 3, 1, W)
    c.rect(x, y - 1, 1, 3, W)
    return c


def fx_light(f):
    c = C(48, 48)
    r = [4, 9, 14, 19, 23][f]
    for y in range(48):
        for x in range(48):
            d = math.hypot(x + 0.5 - 24, y + 0.5 - 24)
            if abs(d - r) < (1.2 if f < 3 else 0.7):
                if f < 2 or bayer(x, y) < (12 if f < 4 else 6):
                    c.px(x, y, W if f < 3 else G)
    if f == 0:
        c.ellipse(24, 24, 3, 3, W)
    return c


def fx_hint(f):
    c = C(8, 8)
    c.art(1, 1 + f, ['wwwww', '.www.', '..w..'])
    c.outline(K)
    return c


def fx_skid(f):
    c = C(8, 8)
    pts = [[(6, 6), (4, 7)], [(5, 5), (2, 6), (6, 7)], [(3, 4), (1, 6)], [(1, 3)]][f]
    for (x, y) in pts:
        c.px(x, y, W if f < 2 else G)
    return c


def build_fx():
    sheet('fx_dust', 16, 8, [
        A('land', [fx_dust(f) for f in range(5)], 0.04, loop=False, note='landing: centre under the feet'),
    ], 'Landing and jump dust.')
    sheet('fx_skid', 8, 8, [A('skid', [fx_skid(f) for f in range(4)], 0.04, loop=False)], 'Turn skid puff.')
    sheet('fx_burst', 32, 32, [
        A('stomp', [fx_burst(f) for f in range(5)], [0.03, 0.04, 0.05, 0.06, 0.06], loop=False,
          note='stomp, enemy pop, shard collect'),
    ], 'Stomp burst.')
    sheet('fx_sparkle', 8, 8, [A('twinkle', [sparkle(f) for f in range(4)], 0.06, loop=False)], 'Shard sparkle.')
    sheet('fx_charge_glow', 24, 24, [
        A('glow', [fx_glow(f) for f in range(4)], 0.07, note='centre on the Spark, draw behind it'),
    ], 'CHARGE aura.')
    sheet('fx_light', 48, 48, [
        A('ring', [fx_light(f) for f in range(5)], 0.05, loop=False, note='beacon light-up, ring pop, mast touch'),
    ], 'Light-up ring.')
    sheet('fx_hint', 8, 8, [A('down', [fx_hint(0), fx_hint(1)], 0.3)], 'Down arrow over a pipe.')


# =================================================================== World 2: The Switchyard
#
# A dead relay yard where the broadcast line splits into two channels.
# Channel ONE is always horizontal bars, channel TWO is always a diamond, on
# the blocks, the switch and the relay boss, so the two read apart in greys.

MARK_ONE = ['wwwww', '.....', 'wwwww', '.....', 'wwwww']
MARK_TWO = ['..w..', '.w.w.', 'w.w.w', '.w.w.', '..w..']
FACE_ONE = ['gggggggggg', '', '', 'gggggggggg', '', '', 'gggggggggg']
FACE_TWO = [
    '....gg....',
    '...g..g...',
    '..g....g..',
    '.g......g.',
    'g...gg...g',
    'g...gg...g',
    '.g......g.',
    '..g....g..',
    '...g..g...',
    '....gg....',
]


def _mark(c, x, y, rows, col, shadow=None):
    """Draws a mark pattern in `col`, with an optional 1 px drop shadow down-right."""
    if shadow is not None:
        for j, row in enumerate(rows):
            for i, ch in enumerate(row):
                if ch != '.' and c.get(x + i + 1, y + j + 1) != col:
                    c.px(x + i + 1, y + j + 1, shadow)
    for j, row in enumerate(rows):
        for i, ch in enumerate(row):
            if ch != '.':
                c.px(x + i, y + j, col)


def _face(ch):
    return (FACE_ONE, 3, 5) if ch == 1 else (FACE_TWO, 3, 4)


def _dashes(c, col, on=2, off=2):
    for i in range(16):
        if i % (on + off) < on:
            for (x, y) in ((i, 0), (i, 15), (0, i), (15, i)):
                c.px(x, y, col)


def chan_block(ch, state):
    """state: solid, off, arm0, arm1, arm2 (arm frames run from outline to solid)."""
    c = C(16, 16)
    rows, fx, fy = _face(ch)
    if state == 'off':
        _dashes(c, D)
        # grey corner brackets keep the outline findable over a dark backdrop
        for (x, y, dx, dy) in ((0, 0, 1, 1), (15, 0, -1, 1), (0, 15, 1, -1), (15, 15, -1, -1)):
            c.px(x, y, G)
            c.px(x + dx, y, G)
            c.px(x, y + dy, G)
        _mark(c, fx, fy, rows, D)
        return c
    if state == 'arm0':
        _dashes(c, G)
        for (x, y) in ((0, 0), (15, 0), (0, 15), (15, 15)):
            c.px(x, y, W)
        _mark(c, fx, fy, rows, G)
        return c
    if state == 'arm1':
        c.frame(0, 0, 16, 16, G)
        c.dith(1, 1, 14, 14, D, 5)
        for (x, y) in ((0, 0), (15, 0), (0, 15), (15, 15)):
            c.px(x, y, W)
        _mark(c, fx, fy, rows, G)
        return c
    # arm2 and solid share the body
    c.rect(0, 0, 16, 16, K)
    c.rect(1, 1, 14, 14, D)
    if state == 'arm2':
        c.dith(1, 1, 14, 14, K, 6, only=D)
        c.frame(0, 0, 16, 16, G)
        c.rect(1, 0, 14, 1, G)
        for (x, y) in ((0, 0), (15, 0)):
            c.px(x, y, W)
        _mark(c, fx, fy, rows, G, shadow=K)
        return c
    c.dith(1, 2, 14, 13, K, 3, only=D)
    c.rect(0, 0, 16, 1, W)
    c.rect(1, 1, 14, 1, G)
    c.px(0, 0, G)
    c.px(15, 0, G)
    c.rect(1, 2, 1, 13, G)       # lit left edge
    c.rect(14, 2, 1, 13, K)      # shaded right edge
    _mark(c, fx, fy, rows, G, shadow=K)
    return c


def chan_switch(ch, state='idle', f=0):
    """Bump-from-below switch showing the live channel's mark. state: idle, hit."""
    c = C(16, 16)
    c.rect(0, 0, 16, 16, K)
    c.rect(1, 1, 14, 14, D)
    c.dith(2, 2, 12, 12, K, 3, only=D)
    c.rect(1, 1, 14, 1, G)
    c.rect(1, 1, 1, 14, G)
    c.rect(2, 14, 13, 1, K)
    # bolts, then up-pointing notches on the underside say "hit me from below"
    for (x, y) in ((3, 3), (12, 3)):
        c.px(x, y, G)
    for x in (4, 11):
        c.px(x, 14, G)
        c.px(x - 1, 14, D)
        c.px(x + 1, 14, D)
    # window with the lit mark
    c.rect(4, 2, 7, 7, K)
    mark = MARK_ONE if ch == 1 else MARK_TWO
    # rocker slot under the window: rocker sits on the live channel's side
    c.rect(4, 10, 7, 3, K)
    rx = 4 if ch == 1 else 8
    if state == 'idle':
        _mark(c, 5, 3, mark, W)
        c.rect(rx, 11, 3, 1, G)
        c.px(rx if ch == 1 else rx + 2, 11, W if f == 0 else G)
        if f == 1:  # slow pulse: the window rim glows
            for (x, y) in ((4, 2), (10, 2), (4, 8), (10, 8)):
                c.px(x, y, G)
        return c
    # hit
    if f == 0:
        c.rect(1, 1, 14, 14, W)
        c.frame(0, 0, 16, 16, K)
        c.rect(4, 2, 7, 7, K)
        c.rect(4, 10, 7, 3, K)
    elif f == 1:
        c.rect(1, 1, 14, 14, G)
        c.frame(0, 0, 16, 16, K)
        c.frame(1, 1, 14, 14, W)
        c.rect(4, 2, 7, 7, K)
        c.rect(4, 5, 7, 1, W)     # the mark wipes across
        c.rect(4, 10, 7, 3, K)
        c.rect(6, 11, 3, 1, W)    # rocker mid-throw
    else:
        c.rect(4, 5, 7, 1, G)
        c.rect(6, 11, 3, 1, G)
    return c


SPIKE_TOOTH = ['..w..', '.wgd.', '.ggd.', 'gggdd']


def spiky(f, mode='walk'):
    """Spiked walker: the walker's NOISE body with a row of teeth on top."""
    c = C(16, 16)
    squash = 1 if mode == 'tell' else 0
    y0 = 5 + squash
    eye_mode = {'tell': 'wide', 'fall': 'wide', 'knocked': 'x'}.get(mode, 'open')
    static_body(c, 2, y0, 12, 8 - squash, f, eye_side=-1, eye=(3, 3), eye_mode=eye_mode,
                flash=(mode == 'tell' and f % 2 == 1))
    # teeth: three grey saw teeth. Only the tips catch white, so the silhouette
    # stays a jagged grey crown and never a white blob
    for i, x0 in enumerate((2, 6, 10)):
        rows = [r.replace('w', 'g') for r in SPIKE_TOOTH]
        c.art(x0, y0 - 4, rows)
        lit = mode in ('tell', 'fall') or (mode == 'walk' and i == 2 - f % 3)
        c.px(x0 + 2, y0 - 4, W if lit else G)
    # an armour band where the teeth are bolted on
    c.rect(3, y0, 10, 1, D)
    # legs
    legs = {0: ((4, 2), (10, 2)), 1: ((3, 3), (10, 1)), 2: ((4, 2), (10, 2)), 3: ((4, 1), (11, 3))}
    if mode == 'walk':
        (lx, lh), (rx, rh) = legs[f]
    elif mode == 'fall':
        (lx, lh), (rx, rh) = ((2, 3), (12, 3))
    elif mode == 'knocked':
        (lx, lh), (rx, rh) = ((4, 1), (10, 1))
    else:
        (lx, lh), (rx, rh) = ((3, 2), (11, 2))
    c.rect(lx, 13, 2, lh, D)
    c.rect(rx, 13, 2, lh if mode == 'fall' else rh, D)
    c.outline(K)
    if mode == 'tell':  # strain ticks either side
        c.px(0, 9 + f % 2, W)
        c.px(15, 10 - f % 2, W)
    if mode == 'knocked':
        return c.flip_v()
    return c


def fuse(state, f=0):
    """Fuse socket hung from the ceiling. state: live, blow (f 0..3), blown."""
    c = C(16, 16)
    # socket block bolted to the ceiling
    c.rect(2, 0, 12, 3, D)
    c.rect(2, 3, 12, 1, G)
    c.px(4, 1, K)
    c.px(11, 1, K)
    # spring clips down to the caps
    for x in (3, 12):
        c.rect(x, 4, 1, 3, G)
    # cartridge: metal caps either end of a glass tube
    dead = state == 'blown' or (state == 'blow' and f >= 2)
    cap = D if state == 'blown' else G
    for x0 in (1, 12):
        c.rect(x0, 7, 3, 6, cap)
        c.rect(x0 + 1, 7, 1, 6, D if state != 'blown' else K)   # a ridge
        c.rect(x0, 12, 3, 1, K)
    c.rect(4, 8, 8, 4, D)
    c.rect(4, 11, 8, 1, K)
    c.rect(5, 8, 3, 1, D if dead else G)   # glass glint
    fil = [(4, 10), (5, 9), (6, 10), (7, 9), (8, 10), (9, 9), (10, 10), (11, 9)]
    if state == 'live':
        for (x, y) in fil:
            c.px(x, y, G)
        sx, sy = fil[2] if f == 0 else fil[5]
        c.px(sx, sy, W)
        if f == 1:  # a spark drips below
            c.px(sx, 13, G)
            c.px(sx - 1, 15, D)
    elif state == 'blow':
        if f == 0:  # the filament flares, rays out
            c.rect(4, 8, 8, 3, W)
            c.rect(7, 9, 2, 1, K)
            for (x, y) in ((0, 9), (15, 10), (7, 14), (9, 15), (2, 14), (13, 14)):
                c.px(x, y, W)
        elif f == 1:  # glass bursts, sparks fly
            c.dith(4, 8, 8, 3, G, 8)
            c.line(4, 8, 6, 10, K)
            c.line(11, 8, 9, 10, K)
            for (x, y) in ((0, 12), (15, 6), (4, 15), (11, 15), (0, 5), (15, 4)):
                c.px(x, y, W)
            c.px(8, 13, G)
        elif f == 2:  # smoke
            c.rect(4, 8, 8, 3, K)
            c.px(4, 10, G)
            c.px(11, 9, G)
            c.ellipse(6, 14, 2.2, 1.6, D)
            c.ellipse(10, 14.5, 1.8, 1.4, G)
            c.px(2, 15, G)
            c.px(14, 13, G)
        else:
            c.rect(4, 8, 8, 3, K)
            c.px(4, 10, D)
            c.px(11, 9, G)
            c.ellipse(7, 15, 2, 1.2, D)
            c.dith(5, 13, 6, 3, T, 8)
            c.px(13, 15, D)
    else:  # blown: black glass, cracked, filament stubs
        c.rect(4, 8, 8, 3, K)
        c.px(4, 10, D)
        c.px(5, 9, D)
        c.px(11, 9, D)
        c.line(7, 8, 8, 10, D)
        c.px(9, 8, G)
    c.outline(K)
    return c


# ------------------------------------------------------------------ relay boss

RELAY_LAMPS = (13, 24, 35)   # lamp centres (x); all at y 16


def relay_lamp(c, cx, lit):
    """7x7 lamp socket centred on (cx, 16). Opaque, so an overlay fully covers it."""
    x0, y0 = cx - 3, 13
    c.rect(x0, y0, 7, 7, K)
    c.rect(x0 + 1, y0 + 1, 5, 5, D)
    if lit:
        c.rect(x0 + 1, y0 + 2, 5, 3, G)
        c.rect(x0 + 2, y0 + 1, 3, 5, G)
        c.rect(x0 + 2, y0 + 2, 3, 3, W)
        c.px(x0 + 4, y0 + 4, G)
    else:
        c.dith(x0 + 1, y0 + 1, 5, 5, K, 8, only=D)
        c.line(x0 + 1, y0 + 2, x0 + 5, y0 + 4, K)
        c.px(x0 + 2, y0 + 2, G)
        c.px(x0 + 4, y0 + 5, G)
    for (x, y) in ((x0, y0), (x0 + 6, y0), (x0, y0 + 6), (x0 + 6, y0 + 6)):
        c.px(x, y, T)


def relay(state, f=0):
    """48x48 relay cabinet. state: idle, tell, swap, overload, dead."""
    c = C(48, 48)
    dead = state == 'dead'
    burnt = dead or state == 'overload'   # overload only starts once all three lamps are gone
    lift = 1 if state == 'tell' and f == 1 else 0
    # feet
    for fx in (6, 35):
        c.rect(fx, 44 - lift, 7, 4 + lift, D)
        c.rect(fx, 44 - lift, 7, 1, G)
    # insulator bushings on the roof: ribbed stacks
    for bx in (10, 36):
        for y in range(1, 7):
            w = 5 if y % 2 else 3
            c.rect(bx - w // 2, y, w, 1, G if y % 2 else D)
        c.px(bx, 0, D)
    if dead:  # one bushing snapped
        c.rect(34, 0, 5, 4, T)
        c.line(34, 5, 37, 3, D)
    # roof
    c.rect(1, 7, 46, 3, D)
    c.rect(1, 7, 46, 1, G)
    c.rect(1, 9, 46, 1, K)
    # body
    c.rect(3, 10, 42, 34, D)
    c.dith(4, 11, 40, 32, K, 3, only=D)
    c.rect(3, 10, 1, 34, G)
    c.rect(44, 10, 1, 34, K)
    for (x, y) in ((6, 12), (41, 12), (6, 41), (41, 41)):
        c.px(x, y, G)
    # lamps
    for cx in RELAY_LAMPS:
        relay_lamp(c, cx, lit=not burnt)
    # face window: ONE on the left, TWO on the right, the armature between
    c.rect(8, 23, 32, 17, K)
    c.frame(8, 23, 32, 17, D)
    c.rect(8, 39, 32, 1, G)
    _mark(c, 11, 26, MARK_ONE, G)
    _mark(c, 32, 26, MARK_TWO, G)
    # contact jaws
    c.rect(17, 25, 2, 4, G)
    c.rect(29, 25, 2, 4, G)
    # coil with windings that crawl to show the hum
    phase = f % 4 if state == 'idle' else 0
    for y in range(33, 38):
        for x in range(20, 28):
            c.px(x, y, G if (y + phase) % 2 else D)
    c.rect(19, 33, 1, 5, K)
    c.rect(28, 33, 1, 5, K)
    # armature bar: sits on the coil, lifts during the tell
    ay = 31
    if state == 'tell':
        ay = 31 - (f + 1)
    elif state == 'swap' and f == 0:
        ay = 28
    if dead:
        c.line(16, 30, 30, 34, G)
        c.line(16, 31, 30, 35, D)
    else:
        c.rect(16, ay, 16, 2, G)
        c.rect(16, ay, 16, 1, W if state in ('tell', 'swap') else G)
        if ay + 2 < 33:
            c.rect(23, ay + 2, 2, 33 - ay - 2, D)
    if state == 'idle':
        # hum: a tick either side of the coil, and a crackle on a bushing tip
        c.px(18 if f % 2 == 0 else 29, 35 + (f // 2), G)
        c.px(10 if f < 2 else 36, 0, G)
    if state == 'tell':
        # arcs jump from the armature to the jaws, strain ticks on the sides
        for k in range(f + 1):
            c.px(17 + k, ay - 1 - (k % 2), W)
            c.px(30 - k, ay - 1 - ((k + 1) % 2), W)
        for y in (18, 30):
            c.px(0, y + f % 2, W)
            c.px(47, y + 1 - f % 2, W)
        c.px(10, 0, W if f != 1 else G)
        c.px(36, 0, W if f == 1 else G)
    if state == 'swap':
        if f == 0:  # the window flashes: rim white, marks light
            c.frame(8, 23, 32, 17, W)
            c.dith(9, 24, 30, 15, G, 6, only=K)
            _mark(c, 11, 26, MARK_ONE, W)
            _mark(c, 32, 26, MARK_TWO, W)
            c.line(18, 27, 29, 27, W)
        else:
            c.frame(8, 23, 32, 17, G)
            _mark(c, 11, 26, MARK_ONE, G)
            _mark(c, 32, 26, MARK_TWO, G)
            c.px(22, 29, W)
            c.px(26, 28, G)
    if state == 'overload':
        arcs = [
            [(10, 1), (14, 8), (12, 16), (18, 24)],
            [(36, 1), (31, 9), (35, 17), (29, 25)],
        ]
        if f in (0, 1, 3):
            for a in arcs:
                for p, q in zip(a, a[1:]):
                    c.line(p[0], p[1], q[0], q[1], W if f != 3 else G)
        if f == 1 or f == 3:
            c.frame(8, 23, 32, 17, W)
            c.dith(9, 24, 30, 15, G, 8 if f == 1 else 4, only=K)
        sparks = [
            [(0, 14), (47, 20), (2, 40), (45, 6)],
            [(1, 8), (46, 30), (0, 34), (47, 12), (24, 1)],
            [(3, 4), (44, 3), (0, 26)],
            [(0, 18), (47, 36), (22, 2), (30, 0)],
            [(2, 30), (46, 24)],
            [(45, 16)],
        ][f]
        for (x, y) in sparks:
            c.px(x, y, W if f < 4 else G)
        if f >= 2:  # cracks spread
            c.line(4, 20, 9, 23, K)
            c.line(40, 40, 44, 34, K)
            if f >= 3:
                c.line(3, 30, 8, 28, K)
                c.line(40, 12, 44, 16, K)
                c.line(22, 10, 25, 13, K)
        if f >= 2:  # smoke off the roof
            n = f - 1
            c.ellipse(16, 5 - n * 0.5, 2 + n * 0.6, 1.5 + n * 0.4, D)
            c.ellipse(31, 4 - n * 0.4, 1.5 + n * 0.5, 1.2 + n * 0.3, G if f < 4 else D)
        if f >= 4:
            c.dith(4, 11, 40, 32, K, 4 + (f - 4) * 2, only=D)
    if dead:
        c.dith(4, 11, 40, 32, K, 9, only=D)
        c.rect(3, 10, 1, 34, D)
        c.rect(1, 7, 46, 1, D)
        for (a, b) in (((4, 18), (10, 24)), ((10, 24), (8, 29)), ((42, 11), (38, 17)),
                       ((38, 17), (43, 22)), ((24, 40), (27, 43)), ((30, 10), (28, 13))):
            c.line(a[0], a[1], b[0], b[1], K)
        c.px(5, 19, G)
        c.px(41, 12, G)
        c.rect(8, 23, 32, 1, K)       # the window frame has sagged
        c.line(8, 24, 39, 26, D)
    c.outline(K)
    return c


def relay_lamps(blown):
    c = C(48, 48)
    for i, cx in enumerate(RELAY_LAMPS):
        relay_lamp(c, cx, lit=i >= blown)
    return c


# ------------------------------------------------------------------ Switchyard terrain

def ground_w2(left=False, right=False, top=False, bottom=False, depth=0, alt=0):
    """Rail yard ground: rail and sleepers on top, gravel ballast, cable ducts below."""
    c = C(16, 16)
    c.rect(0, 0, 16, 16, D)
    # gravel: pebbles picked by a hash so the pattern is fixed per pixel
    dark = (3, 7, 11)[depth]
    c.dith(0, 0, 16, 16, K, dark, only=D)
    for y in range(16):
        for x in range(16):
            h = hash2(x + depth * 31 + alt * 7, y + 101)
            if h % 37 == 0:
                c.px(x, y, G if depth < 2 else D)
                c.px(x + 1, y, D)
                if depth < 2:
                    c.px(x, y + 1, K)
    if depth == 1:  # cable duct running along the yard
        c.rect(0, 6, 16, 1, G)
        c.rect(0, 7, 16, 6, K)
        c.rect(0, 13, 16, 1, D)
        c.rect(0, 9, 16, 1, G)     # cables
        c.rect(0, 11, 16, 1, D)
        c.rect(0, 8, 16, 1, D)
        c.rect(7, 7, 2, 6, D)      # clamp every 16 px
        c.px(7, 7, G)
        c.rect(7, 12, 2, 1, K)
    if alt == 1 and top:  # rail joint: fishplate with bolts
        c.rect(5, 2, 6, 2, G)
        c.px(6, 2, K)
        c.px(9, 2, K)
    elif alt == 2:  # a split duct and a hanging cable end
        c.rect(9, 7, 7, 6, K)
        c.line(9, 9, 12, 11, G)
        c.px(12, 12, D)
        c.px(3, 14, K)
    elif alt == 3 and top:  # a missing sleeper, ballast washed out
        pass
    elif alt == 1 and not top:  # a buried rail stub
        c.rect(3, 9, 10, 2, D)
        c.rect(3, 9, 10, 1, G)
        c.px(12, 10, K)
    if top:
        # rail head, web and foot run the full width, so rails join across tiles
        c.rect(0, 0, 16, 1, W)
        c.rect(0, 1, 16, 1, G)
        c.rect(0, 2, 16, 1, K)
        c.rect(0, 3, 16, 1, D)
        for x in range(0, 16, 4):
            c.px(x + 1, 3, G)
        c.rect(0, 4, 16, 1, K)
        # sleeper ends every 8 px, sitting in the ballast. The gaps between
        # them are dark so the sleepers read as a row of blocks
        c.rect(0, 5, 16, 3, K)
        c.dith(0, 5, 16, 3, D, 3)
        sleepers = (1, 9) if alt != 3 else (1,)
        for sx in sleepers:
            c.rect(sx, 5, 6, 3, D)
            c.rect(sx, 5, 6, 1, G)
            c.rect(sx, 7, 6, 1, K)
            c.px(sx + 2, 6, K)
        if alt == 3:
            c.dith(9, 5, 6, 3, K, 8)
            c.px(11, 6, G)
        if alt == 1:
            c.rect(5, 2, 6, 2, G)
            c.px(6, 2, K)
            c.px(9, 2, K)
            c.px(8, 0, G)          # the joint gap in the rail head
    if left:
        for y in range(16):
            c.px(0, y, G if (y + (0 if top else 1)) % 3 else D)
    if right:
        c.rect(15, 0, 1, 16, K)
        c.dith(14, 0, 1, 16, K, 8)
    if top:
        if left:  # buffer stop: the rail ends in a block
            c.px(0, 0, T)
            c.rect(0, 1, 2, 3, G)
            c.px(0, 1, W)
        if right:
            c.px(15, 0, T)
            c.rect(14, 1, 2, 3, G)
            c.px(15, 3, K)
    if bottom:
        c.rect(0, 13, 16, 3, K)
        c.dith(0, 12, 16, 1, K, 8)
        # a cable loop sags out of the underside
        c.px(5, 13, D)
        c.px(6, 14, D)
        c.px(7, 14, G)
        c.px(8, 13, D)
        c.px(12, 15, T)
        c.px(2, 15, T)
        if left:
            c.px(0, 15, T)
        if right:
            c.px(15, 15, T)
    return c


def block_w2(lip=True, kind=0):
    """Switch-box cabinet: hinge on the left, latch on the right."""
    c = C(16, 16)
    c.rect(0, 0, 16, 16, D)
    c.dith(1, 1, 14, 14, K, 3)
    c.rect(15, 0, 1, 16, K)
    c.rect(0, 15, 16, 1, K)
    c.rect(0, 0, 1, 15, G)
    oy = 2 if lip else 0
    # door seam, hinges and latch
    c.frame(2, 2 + oy, 11, 12 - oy, K)
    c.rect(3, 3 + oy, 9, 1, D)
    for hy in (4 + oy, 11):
        c.px(1, hy, G)
        c.px(2, hy, G)
    c.rect(13, 6 + oy // 2, 1, 4, G)
    c.px(13, 9 + oy // 2, K)
    if kind == 1:  # louvres
        for k in range(3):
            c.rect(4, 5 + oy + k * 2, 7, 1, K)
            c.rect(4, 6 + oy + k * 2, 7, 1, G if k == 2 else D)
    elif kind == 2:  # indicator: the one live pixel on the box
        c.rect(8, 5 + oy, 3, 3, K)
        c.px(9, 6 + oy, W)
        c.rect(4, 5 + oy, 3, 1, D)
    elif kind == 3:  # stencilled bolt: HIGH VOLTAGE
        c.art(5, 5 + oy - (1 if lip else 0), ['..g', '.g.', 'ggg', '.g.', 'g..'])
    else:  # label plate
        c.rect(4, 5 + oy, 6, 2, D)
        c.rect(4, 5 + oy, 6, 1, G)
    if lip:
        c.rect(0, 0, 16, 1, W)
        c.rect(0, 1, 16, 1, G)
        c.rect(15, 0, 1, 2, G)
    return c


# ------------------------------------------------------------------ Switchyard backdrop

def _truss(c, x0, y0, x1, y1, seg=8):
    """A horizontal lattice beam from (x0, y0) to (x1, y0), y1 = its bottom chord."""
    c.rect(x0, y0, x1 - x0 + 1, 1, D)
    c.rect(x0, y1, x1 - x0 + 1, 1, D)
    x = x0
    k = 0
    while x < x1:
        x2 = min(x + seg, x1)
        if k % 2 == 0:
            c.line(x, y0, x2, y1, D)
        else:
            c.line(x, y1, x2, y0, D)
        c.rect(x, y0, 1, y1 - y0 + 1, D)
        x = x2
        k += 1
    c.rect(x1, y0, 1, y1 - y0 + 1, D)


def _lattice_leg(c, cx, top, base, top_hw, base_hw, fill=2):
    """Tapered lattice tower between y top and base, centred on cx."""
    def hw(y):
        return top_hw + (y - top) / max(1, base - top) * (base_hw - top_hw)
    for y in range(top, base + 1):
        h = int(hw(y))
        for x in range(cx - h, cx + h + 1):
            if bayer(x, y) < fill:
                c.px(x, y, D)
        c.px(cx - h, y, D)
        c.px(cx + h, y, D)
    y = top
    while y < base:
        y2 = min(y + 10, base)
        a, b = int(hw(y)), int(hw(y2))
        c.rect(cx - a, y, a * 2 + 1, 1, D)
        c.line(cx - a, y, cx + b, y2, D)
        c.line(cx + a, y, cx - b, y2, D)
        y = y2
    return hw


def _span_cables(c):
    """Cables straight across a non-pylon piece, meeting the pylon's cables at both edges."""
    for (edge_y, dip, dith) in ((16, 3, 12), (38, 3, 16), (58, 3, 16)):
        for x in range(96):
            u = (x - 47.5) / 47.5
            if bayer(x, 0) < dith:
                c.px(x, int(round(edge_y + dip * (1 - u * u))), D)


def backdrop_w2(piece):
    """96x128 far silhouettes, dark and dither only. Bottoms sit on row 127."""
    c = C(96, 128)
    if piece == 0:  # relay tower: lattice mast with drum antennas
        cx = 48
        _lattice_leg(c, cx, 20, 127, 3, 22)
        c.rect(cx, 4, 1, 16, D)
        for y in range(6, 20, 3):
            c.rect(cx - 1, y, 3, 1, D)
        # platforms
        for (y, w) in ((34, 12), (70, 18)):
            c.rect(cx - w, y, w * 2 + 1, 1, D)
            for x in range(cx - w, cx + w + 1, 3):
                c.px(x, y - 1, D)
        # drum antennas hung off the platforms
        for (dx, dy, r) in ((-14, 28, 5), (15, 26, 5), (-21, 62, 6), (21, 64, 6)):
            c.ellipse(cx + dx, dy, r * 0.6, r, D)
            c.dith(cx + dx - 2, dy - r, 4, r * 2, K, 8, only=D)
            c.line(cx + dx, dy, cx + (3 if dx > 0 else -3), dy, D)
        # relay hut at the foot
        c.rect(cx - 30, 112, 61, 16, D)
        c.dith(cx - 30, 114, 61, 14, K, 6, only=D)
        c.rect(cx - 30, 111, 61, 1, D)
        c.rect(cx - 4, 118, 8, 10, K)
    elif piece == 1:  # pylon, cables sag to both edges so repeats join up
        cx = 48
        _lattice_leg(c, cx, 14, 127, 2, 16)
        c.line(cx, 4, cx - 3, 14, D)
        c.line(cx, 4, cx + 3, 14, D)
        for (y, reach) in ((24, 30), (44, 26)):
            # cross-arm: a thin truss out to both tips
            c.rect(cx - reach, y, reach * 2 + 1, 1, D)
            c.line(cx - reach, y, cx - 4, y + 4, D)
            c.line(cx + reach, y, cx + 4, y + 4, D)
            for side in (-1, 1):
                tip = cx + side * reach
                c.rect(tip, y + 1, 1, 4, D)     # insulator string
                c.px(tip - 1, y + 2, D)
                c.px(tip + 1, y + 2, D)
                # cable from the insulator to the frame edge, flat at the edge
                edge = 0 if side < 0 else 95
                sag = 9
                span = abs(edge - tip)
                for x in range(min(tip, edge), max(tip, edge) + 1):
                    u = abs(edge - x) / span
                    cy = y + 5 + sag * (1 - u * u)
                    c.px(x, int(round(cy)), D)
        # earth wire off the peak
        for side in (-1, 1):
            edge = 0 if side < 0 else 95
            span = abs(edge - cx)
            for x in range(min(cx, edge), max(cx, edge) + 1):
                u = abs(edge - x) / span
                if bayer(x, 0) < 12:
                    c.px(x, int(round(4 + 12 * (1 - u * u))), D)
    elif piece == 2:  # signal gantry over the tracks
        for lx in (8, 84):
            _lattice_leg(c, lx + 2, 58, 127, 3, 4, fill=3)
        _truss(c, 4, 54, 91, 62, 8)
        c.rect(4, 51, 88, 1, D)
        for x in range(4, 92, 4):     # walkway handrail
            c.px(x, 52, D)
            c.px(x, 53, D)
        # signal heads hang under the beam, lamps dark
        for sx in (24, 44, 64):
            c.rect(sx + 3, 63, 2, 3, D)
            c.rect(sx, 66, 8, 16, D)
            c.dith(sx, 66, 8, 16, K, 4, only=D)
            for ly in (68, 73, 78):
                c.rect(sx + 2, ly, 4, 3, K)
                c.px(sx + 1, ly, D)
                c.rect(sx + 1, ly - 1, 6, 1, D)
        # ladder up one leg
        for y in range(66, 127, 4):
            c.rect(14, y, 3, 1, D)
        c.rect(14, 62, 1, 65, D)
        c.rect(16, 62, 1, 65, D)
    else:  # relay hut with bushings and a short lattice mast
        c.rect(10, 92, 76, 36, D)
        c.dith(10, 94, 76, 34, K, 5, only=D)
        c.rect(8, 90, 80, 2, D)
        for x in (24, 44, 64):     # windows, dark
            c.rect(x, 100, 8, 6, K)
            c.rect(x, 106, 8, 1, D)
        c.rect(46, 112, 10, 16, K)
        # bushings on the roof
        for bx in (20, 32, 76):
            for y in range(74, 90):
                w = 5 if y % 3 == 0 else 3
                c.rect(bx - w // 2, y, w, 1, D)
        c.line(20, 74, 32, 76, D)
        c.line(32, 76, 46, 72, D)
        # short mast with one dish
        _lattice_leg(c, 60, 40, 89, 1, 6)
        c.ellipse(66, 52, 3.5, 6, D)
        c.dith(64, 46, 5, 12, K, 8, only=D)
        c.line(60, 52, 64, 52, D)
        # cable trough out of the hut, down to the edges
        c.rect(0, 122, 10, 2, D)
        c.rect(86, 118, 10, 2, D)
    if piece != 1:
        _span_cables(c)
    return c


def build_switchyard():
    arm = [0.1, 0.1, 0.1]
    rows = []
    for ch, nm in ((1, 'one'), (2, 'two')):
        rows += [
            A(nm + '_solid', [chan_block(ch, 'solid')], 0, note='live channel: stand on it'),
            A(nm + '_off', [chan_block(ch, 'off')], 0, note='dim dashed outline, pass through'),
            A(nm + '_arm', [chan_block(ch, 'arm0'), chan_block(ch, 'arm1'), chan_block(ch, 'arm2')], arm,
              note='flickers from outline to solid. Play for the 0.3 s before a clocked block turns solid'),
        ]
    sheet('channel_block', 16, 16, rows,
          'Channel blocks `1` and `2`. ONE carries horizontal bars, TWO a diamond, the same marks as the switch.')
    sheet('channel_switch', 16, 16, [
        A('one', [chan_switch(1, 'idle', 0), chan_switch(1, 'idle', 1)], 0.45,
          note='ONE is live: bars lit, rocker thrown left'),
        A('two', [chan_switch(2, 'idle', 0), chan_switch(2, 'idle', 1)], 0.45,
          note='TWO is live: diamond lit, rocker thrown right'),
        A('hit', [chan_switch(1, 'hit', k) for k in range(3)], 0.05, loop=False,
          note='on bump: flash, then show the other idle. Hop the tile 4 px up for 0.1 s in code'),
    ], 'Channel switch `Y`. Bump it from below to swap which channel is solid.')
    sheet('spiky', 16, 16, [
        A('walk', [spiky(f) for f in range(4)], 0.12, note='faces left, flip for right. A glint runs along the teeth'),
        A('turn', [spiky(0, 'tell'), spiky(1, 'tell')], 0.06,
          note='2 frames at a wall or ledge before it turns: squash, eye wide, teeth bristle'),
        A('knocked', [spiky(0, 'knocked')], 0, note='upside down: hit from below or crushed. Falls off screen'),
        A('fall', [spiky(0, 'fall')], 0, note='walked off a ledge'),
    ], 'Spiked walker: the walker body with teeth on top. It cannot be stomped.')
    sheet('fuse', 16, 16, [
        A('live', [fuse('live', 0), fuse('live', 1)], 0.3, note='a small spark runs along the filament'),
        A('blow', [fuse('blow', k) for k in range(4)], 0.06, loop=False,
          note='bumped from below: flare, glass bursts, smoke'),
        A('blown', [fuse('blown')], 0, note='dead socket'),
    ], 'Fuse `Q`: a socket hung from the ceiling. Bump it from below to blow it.')
    sheet('relay', 48, 48, [
        A('idle', [relay('idle', f) for f in range(4)], 0.12, note='the coil hums'),
        A('tell', [relay('tell', f) for f in range(3)], 0.1,
          note='0.3 s before each swap: armature lifts, arcs, strain ticks. Shake the sprite +-1 px x in code'),
        A('swap', [relay('swap', f) for f in range(2)], 0.05, loop=False, note='the swap flash'),
        A('lamps', [relay_lamps(k) for k in range(4)], 0,
          note='0, 1, 2 or 3 lamps blown. Draw over idle, tell and swap at the same position'),
        A('overload', [relay('overload', f) for f in range(6)], 0.08, loop=False,
          note='last lamp gone: arcs, sparks, cracks, smoke'),
        A('dead', [relay('dead')], 0, note='dark and cracked'),
    ], 'Relay (3x3), World 2 boss. Anchor top-left on its tile. It swaps the channels on a clock.')
    rows = [
        A('top', [ground_w2(left=True, top=True), ground_w2(top=True), ground_w2(right=True, top=True),
                  ground_w2(left=True, right=True, top=True)], 0,
          note='top-left, top, top-right, one-wide column top'),
        A('mid', [ground_w2(left=True, depth=1), ground_w2(depth=1), ground_w2(right=True, depth=1),
                  ground_w2(left=True, right=True, depth=1)], 0, note='second row down: left, fill, right, column'),
        A('deep', [ground_w2(left=True, depth=2), ground_w2(depth=2), ground_w2(right=True, depth=2),
                   ground_w2(left=True, right=True, depth=2)], 0, note='third row and below'),
        A('bottom', [ground_w2(left=True, bottom=True, depth=2), ground_w2(bottom=True, depth=2),
                     ground_w2(right=True, bottom=True, depth=2),
                     ground_w2(left=True, right=True, top=True, bottom=True)], 0,
          note='underside for ceilings and floating ground. The last one is a single tile'),
        A('alt', [ground_w2(top=True, alt=1), ground_w2(top=True, alt=3), ground_w2(depth=1, alt=2),
                  ground_w2(depth=2, alt=1)], 0, note='drop-in swaps for variety, pick by hash of world tile x,y'),
    ]
    sheet('ground_w2', 16, 16, rows,
          'Switchyard ground `#`: rail and sleepers on top, gravel and a cable duct below. Same layout as `ground`.')
    sheet('block_w2', 16, 16, [
        A('lip', [block_w2(True, 0), block_w2(True, 1), block_w2(True, 2), block_w2(True, 3)], 0,
          note='top of a stack: plain, vent, live pip, stencil'),
        A('stacked', [block_w2(False, 0), block_w2(False, 1), block_w2(False, 2), block_w2(False, 3)], 0,
          note='a block with another block above it'),
    ], 'Switchyard block `=`: switch boxes. Same layout as `block`. Use a live pip rarely.')
    sheet('backdrop_w2', 96, 128, [
        A('pieces', [backdrop_w2(k) for k in range(4)], 0,
          note='0 relay tower, 1 pylon, 2 signal gantry, 3 relay hut'),
    ], 'Switchyard far silhouettes. Far layer, parallax 0.2x, 70% opacity, every bottom on one horizon line. '
       'Lay the pieces edge to edge, one every 96 px, with no gaps: every piece carries the same three cables '
       'at its edges, so they join in any order. Mostly pylons (1), with a tower, gantry or hut (0, 2, 3) '
       'every third or fourth slot, picked by a hash of the slot number. Never put two of the same non-pylon '
       'piece side by side.')


# =================================================================== atmosphere: lamps, light, weather, fog

# The lamp bulb is centred on frame pixel corner (8, 8). With the lamp drawn at
# (cell x, cell y - 16) the light_mask top-left lands on (cell x - 120, cell y
# - 136), a multiple of 4, so the mask's Bayer steps line up with the world's.
LAMP_BULB = (8, 8)


def _lamp_halo(c, near, far, flash=False):
    """Dithered glow round the bulb, only on empty pixels. near/far are Bayer
    thresholds (0..16) for the inner and outer ring."""
    cx, cy = LAMP_BULB
    for y in range(1, 16):
        for x in range(1, 15):
            if c.get(x, y) != T:
                continue
            d = math.hypot(x + 0.5 - cx, y + 0.5 - cy)
            if d < 4.2:
                if bayer(x, y) < near:
                    c.px(x, y, W if flash else G)
            elif d < 6.6:
                if bayer(x, y) < far:
                    c.px(x, y, G if flash else D)


def lamp(state, f=0):
    """off, ignite (f 0..4), on (f 0..3). 16x32, bottom row on the lamp cell's floor."""
    c = C(16, 32)
    if state == 'ignite':
        bulb = ['spark', 'flash', 'drop', 'on', 'on'][f]
    elif state == 'on':
        bulb = 'dip' if f == 2 else 'on'
    else:
        bulb = 'off'
    lit = bulb in ('flash', 'on', 'dip')
    # plinth with a status window
    c.rect(5, 28, 6, 4, D)
    c.rect(5, 28, 6, 1, G)
    c.rect(4, 31, 8, 1, D)
    c.rect(7, 29, 2, 2, K)
    if lit:
        c.px(7, 29, W)
        c.px(8, 29, G)
    # post: dark when off, lit down its left edge by the bulb when on
    c.rect(7, 11, 2, 17, D)
    c.rect(8, 11, 1, 17, K)
    for y in (15, 22):
        c.px(7, y, G)
    if lit:
        for y in range(11, 28):
            if y < 15 or bayer(7, y) < max(0, 16 - (y - 11) * 2):
                c.px(7, y, G)
    # collar, cage and hood
    c.rect(5, 10, 6, 1, D)
    c.px(5, 10, G)
    for x in (5, 10):
        c.rect(x, 6, 1, 4, D)
    c.rect(4, 4, 8, 2, D)
    c.rect(5, 3, 6, 1, G if lit else D)
    c.rect(4, 5, 8, 1, K)
    # bulb, 4x4 with rounded corners
    if bulb == 'off':
        c.rect(6, 6, 4, 4, G)
        for (x, y) in ((6, 6), (9, 6), (6, 9), (9, 9), (9, 8), (8, 9)):
            c.px(x, y, D)
    elif bulb == 'spark':
        c.rect(6, 6, 4, 4, G)
        c.px(7, 7, W)
        c.px(8, 8, W)
    elif bulb == 'drop':
        c.rect(6, 6, 4, 4, D)
        c.px(8, 7, W)
    else:
        c.rect(6, 6, 4, 4, W)
        if bulb == 'dip':
            c.px(8, 8, G)
            c.px(9, 9, G)
    for (x, y) in ((6, 6), (9, 6), (6, 9), (9, 9)):
        if c.get(x, y) == W:
            c.px(x, y, G)
    c.outline(K)
    if bulb == 'flash':
        _lamp_halo(c, 10, 6, flash=True)
    elif bulb == 'spark':
        _lamp_halo(c, 2, 0)
    elif lit:
        if state == 'ignite':
            near, far = {3: (6, 2), 4: (10, 4)}[f]
        else:
            near, far = [(10, 4), (9, 3), (6, 2), (11, 5)][f]
        _lamp_halo(c, near, far)
    return c


LIGHT_RADII = (56, 88, 120)
LIGHT_FRAME = 256


def light_mask(r):
    """White = lit, transparent = unlit. Solid to half the radius, then eight
    Bayer steps to nothing at the edge."""
    c = C(LIGHT_FRAME, LIGHT_FRAME)
    cx = cy = LIGHT_FRAME / 2
    r_in = r * 0.5
    for y in range(LIGHT_FRAME):
        for x in range(LIGHT_FRAME):
            d = math.hypot(x + 0.5 - cx, y + 0.5 - cy)
            if d <= r_in:
                c.px(x, y, W)
            elif d < r:
                level = math.ceil((r - d) / (r - r_in) * 8)
                if bayer(x, y) < level * 2:
                    c.px(x, y, W)
    return c


def _streak(c, x, y, n, dim=False):
    """A rain streak falling down-left, 1 px left per 2 px down. Tail at the top."""
    for i in range(n):
        col = D if (dim or i < n // 2) else G
        c.px(x - (i + 1) // 2, y + i, col)


def rain(v):
    c = C(16, 16)
    for (x, y, n, dim) in [
        [(11, 2, 9, False)],
        [(12, 1, 7, False), (6, 8, 5, False)],
        [(9, 3, 6, False), (14, 9, 4, True)],
        [(5, 1, 4, False), (13, 5, 5, False), (8, 10, 4, True)],
    ][v]:
        _streak(c, x, y, n, dim)
    return c


def static_fleck(v):
    c = C(16, 16)
    for (x, y, col) in [
        [(8, 8, W)],
        [(7, 8, W), (8, 8, G)],
        [(6, 8, W), (7, 8, W), (8, 8, G)],
        [(6, 7, G), (8, 8, W), (9, 8, W)],
    ][v]:
        c.px(x, y, col)
    return c


def splash(f):
    """Bottom row is the floor surface, centred on the hit (x 7..8)."""
    c = C(16, 16)
    pts = [
        [(7, 15, G), (8, 15, G), (6, 15, D), (9, 15, D), (6, 14, G), (9, 14, G), (7, 13, D), (8, 13, D)],
        [(6, 15, D), (7, 15, D), (8, 15, D), (9, 15, D), (5, 13, G), (10, 13, G), (4, 12, D), (11, 12, D),
         (7, 11, G), (6, 14, D), (9, 14, D)],
        [(3, 14, D), (12, 14, D), (2, 15, D), (13, 15, D), (4, 13, G), (11, 13, G), (7, 12, D)],
    ][f]
    for (x, y, col) in pts:
        c.px(x, y, col)
    return c


FOG_WAVES = [
    ([(1, 0.35), (3, 0.2)], [(1, 1.5)]),
    ([(2, 0.35), (1, -0.25)], [(2, 1.2)]),
    ([(1, -0.35), (4, 0.15)], [(1, -1.5), (3, 0.6)]),
    ([(3, 0.3), (2, -0.2)], [(2, -1.2)]),
]


def fog(v):
    """Sparse dark dither, densest low in the band. Every wave is a whole number
    of periods across 32 px and is zero at the edges, so a frame tiles with
    itself and with any other frame."""
    c = C(32, 16)
    dens, bob = FOG_WAVES[v]
    for x in range(32):
        u = 2 * math.pi * (x + 0.5) / 32
        m = 0.75 + sum(a * math.sin(n * u) for n, a in dens)
        peak = 10.5 + sum(a * math.sin(n * u) for n, a in bob)
        for y in range(16):
            dy = y + 0.5 - peak
            prof = max(0.0, 1.0 - (-dy / 7.0 if dy < 0 else dy / 9.0))
            thr = int(round(max(0.0, m) * prof * 7))
            if bayer(x, y) < thr:
                c.px(x, y, D)
    return c


def build_atmosphere():
    sheet('lamp', 16, 32, [
        A('off', [lamp('off')], 0, note='dark post, grey unlit bulb'),
        A('ignite', [lamp('ignite', f) for f in range(5)], 0.05, loop=False,
          note='the Spark walks past: the bulb sputters on, flashes, then settles. Then play on'),
        A('on', [lamp('on', f) for f in range(4)], 0.15, note='steady glow, the bulb dips once per loop'),
    ], "Signal lamp post. Anchor top-left on the tile above the lamp's cell (cell x, cell y - 16), so the "
       'plinth stands on the lamp cell\'s floor. The bulb centre is frame pixel (8, 8): centre `light_mask` '
       'there, which puts the mask top-left at (cell x - 120, cell y - 136).')
    sheet('light_mask', LIGHT_FRAME, LIGHT_FRAME, [
        A('disc', [light_mask(r) for r in LIGHT_RADII], 0,
          note='0 small (radius 56), 1 medium (radius 88), 2 large (radius 120)'),
    ], 'Light circle for dark areas. **This is a mask, not art.** `#f2f2f2` means lit and transparent means '
       'unlit: use it to cut the darkness away (or as a light texture), never draw it as colour. Solid out to '
       'half the radius, then eight Bayer steps to nothing at the edge. Frames are 256x256 so the large radius '
       'fits. Centre the frame on the light: top-left = light position - (128, 128).')
    sheet('weather', 16, 16, [
        A('rain', [rain(v) for v in range(4)], 0,
          note='streaks falling down-left. Scroll them 1 px left for every 2 px down so they move along their slant'),
        A('static', [static_fleck(v) for v in range(4)], 0,
          note='1 to 3 px signal flecks. Flash each one for a frame or two, centred at frame pixel (8, 8)'),
        A('splash', [splash(f) for f in range(3)], 0.05, loop=False,
          note='a drop hits the ground: bottom row on the floor surface, frame x 7-8 on the hit'),
    ], 'Weather particles. The game scatters and scrolls these itself. Rain and splashes are grey and dark only.')
    sheet('fog', 32, 16, [
        A('band', [fog(v) for v in range(4)], 0,
          note='tile edge to edge in any order, low in a deep drop. Scroll slowly sideways in code'),
    ], 'Fog band: sparse dark dither that tiles seamlessly left to right. Every frame joins every other.')


# =================================================================== Last Relay: the village hub

# The village is built into a relay station that still works. Villagers are
# "listeners": grey and dark bodies with two small white dot eyes, round tops
# and no teeth, so they never read as the white striped NOISE enemies. White is
# kept for eyes, lamps and lit windows.
#
# Where an animation's art is smaller than its sheet's frame (the house door,
# the 8x8 bubble parts), the art sits at the frame's top-left and the rest is
# transparent. Drawing the frame at the art's own top-left is then correct.

# Story signatures (docs/research/exploration/notes/story-arc.md)
MAINT_MARK = ['..g', 'g.g', 'g..', 'gg.']            # two-part maintenance mark
HANDLE_SMALL = ['ggg', '.g.', '.g.', '.gg', '.g.']   # notched isolation handle, belt size


def _eyes(c, x, y, gap=2, shut=False):
    """Two friendly dot eyes on a dark visor band. x is the front (left) eye."""
    c.rect(x - 1, y, gap + 3, 1, K)
    if not shut:
        c.px(x, y, W)
        c.px(x + gap, y, W)


def npc_mast(mode, f):
    """Old Mast: tall, stooped, cloaked, long antenna, leans on a cane."""
    c = C(16, 24)
    nod = (0, 0, 1, 0)[f] if mode == 'idle' else (0, 1)[f]
    sway = (0, 1, 1, 0)[f] if mode == 'idle' else 0
    hy = 8 + nod
    # cloak: narrow at the shoulders, wide at the hem, hump on the back
    for y in range(11, 23):
        left = 5 - (y - 11) * 2 // 11
        right = 11 + (y - 11) * 2 // 11
        c.rect(left, y, right - left + 1, 1, G)
    c.ellipse(10, 12, 3, 2.5, G)
    c.dith(8, 11, 6, 12, D, 8, only=G)
    c.rect(7, 13, 1, 9, D)                 # fold down the front
    c.rect(6, 11, 3, 1, G)                 # clasp at the collar
    c.rect(4, 22, 8, 1, D)
    c.rect(5, 23, 2, 1, D)
    c.px(2, 12, G)                         # cane crook
    c.rect(9, 23, 2, 1, D)
    # antenna from the back of the hood, curling back, lamp tip
    for (x, y) in ((8, hy - 2), (8, hy - 3), (9, hy - 4), (9, hy - 5), (10 + sway, hy - 6)):
        c.px(x, y, D)
    c.px(10 + sway, hy - 7, W)
    # hood and face, leaning forward of the cloak
    c.ellipse(7.5, hy + 1.5, 3.2, 2.8, D)
    c.ellipse(6, hy + 2, 2.6, 2.2, G)
    _eyes(c, 4, hy + 2, 2, shut=(mode == 'idle' and f == 2))
    c.px(5, hy + 4, G)   # whiskers
    c.px(4, hy + 4, G)
    # cane with a hand on it
    c.rect(2, 13, 1, 11, G)
    c.px(3, 12, G)
    c.px(3, 13 + (1 if mode == 'talk' and f == 1 else 0), G)
    c.outline(K)
    return c


def npc_tally(mode, f):
    """Tally the trader: round body under a big pack of parts with a lamp on top."""
    c = C(16, 24)
    bob = (0, 0, 1, 1)[f] if mode == 'idle' else (0, -1)[f]
    by = 16 + bob
    # pack behind (right), parts sticking out
    c.rect(8, by - 9, 7, 12, D)
    c.dith(9, by - 8, 5, 11, K, 5, only=D)
    c.rect(13, by - 12, 1, 3, G)          # pipe
    c.ellipse(10.5, by - 10, 1.8, 1.8, D)  # wheel
    c.px(10, by - 10, K)
    c.rect(8, by - 4, 7, 1, G)             # strap
    c.rect(11, by - 1, 2, 2, G)            # pocket buckle
    # lamp on the pack
    lamp_on = not (mode == 'idle' and f == 2)
    c.rect(11, by - 15, 3, 1, D)
    c.rect(11, by - 14, 3, 2, W if lamp_on else G)
    c.px(12, by - 16, D)
    # round body
    c.ellipse(6, by, 4.6, 5, G)
    c.dith(7, by - 5, 4, 11, D, 6, only=G)
    _eyes(c, 3, by - 2, 2, shut=(mode == 'idle' and f == 3))
    c.px(3, by, D)                          # smile corner
    # arm: waves while talking
    if mode == 'talk' and f == 1:
        c.rect(1, by - 4, 1, 3, G)
    else:
        c.rect(1, by + 1, 2, 1, G)
    # feet
    c.rect(3, 21 + max(0, bob), 2, 3 - max(0, bob), D)
    c.rect(7, 21 + max(0, bob), 2, 3 - max(0, bob), D)
    c.outline(K)
    return c


def npc_wren(mode, f):
    """Wren: a small listener kid with oversized headphones."""
    c = C(16, 24)
    bob = (0, 1, 0, 0)[f] if mode == 'idle' else (0, -1)[f]
    hy = 13 + bob
    # body and legs
    c.ellipse(7.5, 19.5 + max(0, bob) * 0.5, 2.8, 2.4, D)
    c.rect(6, 21, 1, 3, D)
    c.rect(9, 21, 1, 3, D)
    if bob < 0:
        c.rect(6, 23, 1, 1, T)
        c.rect(9, 23, 1, 1, T)
    # big head
    c.ellipse(7.5, hy, 3.8, 3.4, G)
    c.dith(9, hy - 3, 3, 7, D, 5, only=G)
    _eyes(c, 5, hy, 2, shut=(mode == 'idle' and f == 3))
    c.outline(K)
    # headphone band arched clear of the head, and two big round cups
    for (x, y) in ((2, hy - 3), (3, hy - 4), (4, hy - 5), (5, hy - 6), (6, hy - 6), (7, hy - 6), (8, hy - 6),
                   (9, hy - 6), (10, hy - 6), (11, hy - 5), (12, hy - 4), (13, hy - 3)):
        c.px(x, y, G)
    for cx in (1, 11):
        c.rect(cx, hy - 2, 4, 5, K)
        c.rect(cx + 1, hy - 3, 2, 7, K)
        c.rect(cx + 1, hy - 2, 2, 5, G)
        c.px(cx + (0 if cx < 7 else 3), hy, G)
        c.rect(cx + 1, hy - 1, 2, 3, D)
    c.px(12, hy, W if not (mode == 'idle' and f == 2) else G)   # cup light
    return c


def npc_brace(mode, f):
    """Brace the lineworker: hard hat, hook stick, notched isolation handle on the belt."""
    c = C(16, 24)
    br = (0, 0, 1, 1)[f] if mode == 'idle' else 0
    tilt = 1 if mode == 'talk' and f == 1 else 0
    # hook stick held at the back: insulated bands, hook at the top
    for y in range(4, 24):
        c.px(13, y, G if (y // 3) % 2 else D)
    c.px(13 - tilt, 3, D)
    c.px(13 - tilt, 2, D)
    c.px(12 - tilt, 1, D)
    c.px(11 - tilt, 1, D)
    c.px(11 - tilt, 2, D)
    # body: work suit with a light stripe
    c.rect(4, 12 + br, 7, 9 - br, D)
    c.ellipse(7.5, 12.5 + br, 3.6, 1.8, D)
    c.rect(4, 14 + br, 7, 1, G)
    c.rect(4, 17, 7, 1, K)                 # belt
    c.rect(4, 21, 2, 3, D)
    c.rect(8, 21, 2, 3, D)
    c.rect(11, 13 + br, 2, 1, G)           # arm to the stick
    # hard hat (round dome, brim to the front), then the face under it
    c.ellipse(7, 7 + br, 3.6, 2.6, G)
    c.rect(7, 5 + br, 1, 4, D)             # hat ridge
    c.rect(2, 8 + br, 9, 1, G)             # brim
    c.rect(4, 9 + br, 6, 3, D)             # face in the brim's shadow
    c.rect(4, 11 + br, 6, 1, G)            # chin strap
    _eyes(c, 5, 10 + br, 2, shut=(mode == 'idle' and f == 3))
    c.px(6, 6 + br, W)                     # hat shine
    c.outline(K)
    # notched isolation handle hanging off the belt, in front
    c.art(1, 17, HANDLE_SMALL)
    c.px(2, 20, K)                         # the notch
    c.px(1, 17, W)
    return c


def npc_dot(mode, f):
    """Dot the switch operator: boxy body of toggles, one lamp for a head."""
    c = C(16, 24)
    # legs and box body
    c.rect(4, 21, 2, 3, D)
    c.rect(10, 21, 2, 3, D)
    c.rect(3, 11, 10, 10, G)
    c.rect(11, 11, 2, 10, D)
    c.rect(4, 13, 5, 5, D)                 # switch panel
    for i, x in enumerate((5, 7)):
        up = (i + f) % 2 == 0 if mode == 'talk' else i == 0
        c.px(x, 14 if up else 16, G)
        c.px(x, 15, K)
    c.rect(4, 19, 7, 1, D)
    c.rect(1, 14, 2, 1, G)                 # arms
    c.rect(13, 14, 2, 1, G)
    # neck and lamp head
    c.rect(7, 8, 2, 3, D)
    c.rect(6, 8, 4, 1, K)
    if mode == 'talk' and f == 1:
        c.ellipse(8, 5, 3, 3, D)
        c.px(8, 5, K)
        c.px(7, 4, G)
    else:
        c.ellipse(8, 5, 3, 3, G)
        glow = (1, 1, 2, 1)[f] if mode == 'idle' else 3
        c.ellipse(8, 5, glow, glow, W)
    c.outline(K)
    if mode == 'talk' and f == 0:          # blink halo
        for (x, y) in ((3, 2), (12, 2), (2, 5), (13, 5), (3, 8), (12, 8), (7, 0), (8, 0)):
            c.px(x, y, G)
    return c


def npc_hum(mode, f):
    """Hum the relay technician: heavy transformer torso, cooling fins, small arms."""
    c = C(16, 24)
    shake = 1 if mode == 'idle' and f == 1 else 0
    # legs
    c.rect(3, 21, 3, 3, D)
    c.rect(9, 21, 3, 3, D)
    # torso: rounded top, fins on the back
    c.rect(2, 10 + shake, 12, 11 - shake, D)
    c.rect(3, 9 + shake, 10, 1, D)
    for y in range(11 + shake, 20):
        for x in (10, 12):
            c.px(x, y, G if (y + f) % 2 else K)
        c.px(11, y, K)
    c.rect(3, 11 + shake, 6, 6, G)         # face plate
    c.dith(3, 15 + shake, 6, 2, D, 8, only=G)
    _eyes(c, 4, 13 + shake, 2, shut=(mode == 'idle' and f == 3))
    c.rect(2, 18, 8, 1, K)
    # two bushings on top with round caps
    for i, bx in enumerate((4, 9)):
        for y in range(5 + shake, 9 + shake):
            c.rect(bx, y, 2, 1, G if y % 2 else D)
        c.rect(bx, 4 + shake, 2, 1, G)
        lit = (mode == 'talk' and i == f) or (mode == 'idle' and f == 2 and i == 1)
        if lit:
            c.px(bx, 4 + shake, W)
            c.px(bx + 1, 4 + shake, W)
    # small arms
    c.rect(1, 14 + shake, 1, 3, G)
    c.rect(14, 14 + shake, 1, 2, G)
    if mode == 'talk' and f == 1:
        c.rect(1, 12, 1, 5, T)
        c.rect(0, 12, 1, 3, G)
    c.outline(K)
    return c


NPCS = [
    ('mast', npc_mast, 'Old Mast, the keeper: tall, stooped, cloak, long antenna, cane'),
    ('tally', npc_tally, 'Tally, the trader: round body, big pack of parts, lamp on the pack'),
    ('wren', npc_wren, 'Wren, a listener kid: small, oversized headphones'),
    ('brace', npc_brace, 'Brace, the lineworker: hard hat, hook stick, notched isolation handle on the belt'),
    ('dot', npc_dot, 'Dot, the switch operator: boxy body, one lamp for a head that blinks when talking'),
    ('hum', npc_hum, 'Hum, the relay technician: heavy transformer torso, fins, small arms'),
]


# ------------------------------------------------------------------ houses

DOOR = (24, 32)   # door position inside a 64x64 facade


def door_art(open_=False):
    """The door as a 16x32 sprite at the top-left of a 64x64 frame."""
    c = C(64, 64)
    c.rect(0, 0, 16, 32, G)                # jambs and lintel
    c.rect(0, 0, 16, 1, D)
    if open_:
        c.rect(1, 1, 14, 31, K)
        # warm light spills across the floor inside
        c.dith(2, 22, 12, 10, D, 8)
        c.dith(3, 27, 10, 5, G, 6)
        c.rect(12, 1, 3, 31, D)            # the leaf, swung in
        c.rect(12, 1, 1, 31, G)
    else:
        c.rect(1, 1, 14, 31, D)
        for x in (5, 10):
            c.rect(x, 2, 1, 29, K)
        c.dith(1, 1, 14, 31, K, 3, only=D)
        c.ellipse(8, 7, 2.5, 2.5, G)       # porthole
        c.ellipse(8, 7, 1.5, 1.5, K)
        c.rect(2, 17, 2, 2, G)             # handle
        c.rect(1, 31, 14, 1, K)
    return c


def _wall(c, x, y, w, h, thr=3):
    c.rect(x, y, w, h, D)
    c.dith(x, y, w, h, K, thr, only=D)


def _siding(c, x, y, w, h, step=4):
    """Corrugated siding: dark vertical ribs."""
    for xx in range(x + 2, x + w - 1, step):
        c.rect(xx, y, 1, h, K)


def _rivets(c, x0, x1, y):
    for x in range(x0, x1 + 1, 6):
        c.px(x, y, G)


def _mark_at(c, x, y):
    c.art(x, y, MAINT_MARK)


def keeper_window(c, x, y, lit=True):
    """The window people care about: four panes and one diagonal mullion, snapped."""
    n = 13
    bg = W if lit else D
    c.rect(x - 1, y - 1, n + 2, n + 2, K)
    c.rect(x, y, n, n, bg)
    c.rect(x + n // 2, y, 1, n, K)                   # upright
    c.rect(x, y + n // 2, n, 1, K)                   # transom
    for i in range(n):                               # the diagonal, top-left to bottom-right...
        c.px(x + i, y + i, K)
    for i in (8, 9, 10):                             # ...snapped out in the last pane
        c.px(x + i, y + i, bg)
    c.px(x + 8, y + 10, K)                           # the broken end hangs down
    c.px(x + 8, y + 11, K)
    c.rect(x - 2, y + n + 1, n + 4, 1, G)            # sill
    c.rect(x - 1, y - 2, n + 2, 1, D)                # lintel


def isolation_handle(c, x, y, lit=False):
    """Wall-mounted notched isolation handle, 7x12, on a back plate."""
    c.rect(x, y, 7, 12, D)
    c.frame(x, y, 7, 12, K)
    c.rect(x + 3, y + 2, 1, 8, G)            # spindle
    c.rect(x + 1, y + 2, 5, 2, G)            # T grip
    c.px(x + 4, y + 3, K)                    # the notch
    c.px(x + 1, y + 2, W if lit else G)
    c.rect(x + 2, y + 9, 3, 2, K)            # socket


def facade(kind):
    c = C(64, 64)
    if kind == 0:   # keeper's house: round roof, the lit window, the mark by the door
        _wall(c, 3, 24, 58, 40)
        _siding(c, 3, 26, 58, 38, 5)
        # round roof
        c.ellipse(32, 26, 31, 17, D)
        c.rect(0, 26, 64, 38, T)
        _wall(c, 3, 26, 58, 38)
        _siding(c, 3, 27, 58, 37, 5)
        c.dith(2, 9, 60, 17, K, 6, only=D)
        for x in range(1, 63):     # lit rim along the arch
            for y in range(8, 27):
                if c.get(x, y) != T and c.get(x, y - 1) == T:
                    c.px(x, y, G)
                    break
        c.rect(0, 25, 64, 2, G)
        c.rect(0, 27, 64, 1, K)
        # porthole up in the roof, dark
        c.ellipse(32, 17, 3.5, 3.5, G)
        c.ellipse(32, 17, 2.5, 2.5, K)
        # small aerial on the roof, lamp at the tip
        c.rect(50, 6, 1, 8, D)
        c.line(50, 7, 47, 4, D)
        c.line(50, 7, 53, 4, D)
        c.px(50, 5, W)
        keeper_window(c, 6, 34)
        _mark_at(c, 44, 38)
        c.rect(44, 50, 12, 6, D)          # planter box by the door
        c.rect(44, 50, 12, 1, G)
        c.rect(0, 62, 64, 2, D)
    elif kind == 1:   # shop: awning, hanging sign, parts rack
        _wall(c, 2, 20, 60, 44)
        _siding(c, 2, 28, 60, 36, 6)
        c.ellipse(32, 20, 29, 6, D)
        c.dith(4, 14, 56, 6, K, 6, only=D)
        c.rect(2, 19, 60, 1, G)
        # striped awning with a scalloped edge
        for x in range(0, 64):
            col = G if (x // 4) % 2 else D
            c.rect(x, 22, 1, 5, col)
            if x % 4 in (1, 2):
                c.px(x, 27, col)
        c.rect(0, 21, 64, 1, K)
        # hanging sign on a bracket: a gear, the parts trade
        c.rect(44, 30, 14, 1, D)
        c.px(46, 31, D)
        c.px(55, 31, D)
        c.rect(44, 32, 14, 9, D)
        c.frame(44, 32, 14, 9, G)
        c.ellipse(51, 36.5, 2.6, 2.6, G)
        c.px(51, 36, K)
        for (dx, dy) in ((0, -3), (0, 3), (-3, 0), (3, 0)):
            c.px(51 + dx, 36 + dy, G)
        # parts rack right of the door
        c.rect(42, 44, 18, 19, K)
        c.frame(42, 44, 18, 19, G)
        for y in (50, 56):
            c.rect(43, y, 16, 1, G)
        for (x, y, col) in ((44, 47, D), (47, 46, G), (51, 47, D), (55, 48, G), (45, 53, G), (49, 52, D),
                            (54, 53, D), (44, 59, D), (48, 58, G), (53, 59, D)):
            c.rect(x, y, 3, 3, col)
        c.px(56, 46, W)            # one bulb on the rack still glows
        # small lit shop window with shelf silhouettes
        c.rect(6, 34, 14, 12, K)
        c.rect(7, 35, 12, 10, W)
        c.rect(7, 40, 12, 1, D)
        for x in (8, 12, 15):
            c.rect(x, 38, 2, 2, D)
        c.rect(9, 42, 2, 3, D)
        c.rect(14, 43, 3, 2, D)
        c.rect(5, 46, 16, 1, G)
        c.rect(0, 62, 64, 2, D)
    elif kind == 2:   # radio shack: low hut, tall lattice antenna, round window
        _wall(c, 6, 30, 50, 34)
        _siding(c, 6, 32, 50, 32, 5)
        c.ellipse(31, 30, 26, 7, D)
        c.dith(6, 23, 50, 7, K, 6, only=D)
        c.rect(5, 29, 52, 1, G)
        c.rect(5, 30, 52, 1, K)
        # tall antenna from the roof to the top of the frame
        for y in range(3, 26):
            hw = 1 + (y - 3) // 8
            c.px(48 - hw, y, D)
            c.px(48 + hw, y, D)
            if y % 4 == 0:
                c.rect(48 - hw, y, hw * 2 + 1, 1, D)
        c.rect(48, 0, 1, 3, G)
        c.px(48, 0, W)
        for side in (-1, 1):     # guy wires
            c.line(48, 8, 48 + side * 14, 28, D)
        # dish on the roof
        c.ellipse(16, 22, 4, 3, G)
        c.ellipse(17, 22, 2.5, 2, D)
        c.rect(17, 25, 1, 3, D)
        # round lit window
        c.ellipse(14, 44, 5, 5, K)
        c.ellipse(14, 44, 4, 4, W)
        c.rect(10, 44, 9, 1, K)
        c.rect(14, 40, 1, 9, K)
        # speaker grille by the door
        c.rect(43, 38, 8, 8, K)
        for y in range(39, 45, 2):
            c.rect(44, y, 6, 1, D)
        c.rect(0, 62, 64, 2, D)
    elif kind == 3:   # switch hut: boxy, cables off roof insulators, isolation handle
        _wall(c, 5, 26, 54, 38, 4)
        for y in range(28, 64, 6):
            c.rect(5, y, 54, 1, K)
            _rivets(c, 7, 57, y + 1)
        c.rect(3, 24, 58, 3, G)
        c.rect(3, 26, 58, 1, K)
        c.ellipse(32, 24, 28, 3, G)
        c.rect(0, 25, 64, 1, T)
        c.rect(3, 24, 58, 2, G)
        # three insulators on the roof, cables sagging off to both edges
        tops = (14, 32, 50)
        for ix in tops:
            for y in range(15, 24):
                c.rect(ix - (1 if y % 2 else 0), y, 3 if y % 2 else 1, 1, G if y % 2 else D)
        spans = ((0, 20, 14, 15), (14, 15, 32, 15), (32, 15, 50, 15), (50, 15, 63, 20))
        for (x0, y0, x1, y1) in spans:
            for x in range(x0, x1 + 1):
                t = (x - x0) / float(x1 - x0)
                c.px(x, int(round(y0 + (y1 - y0) * t + 3 * (1 - (2 * t - 1) ** 2))), D)
        # cable down the wall into a junction box
        c.rect(58, 27, 1, 10, D)
        c.rect(52, 36, 8, 7, D)
        c.frame(52, 36, 8, 7, K)
        c.px(54, 38, W)
        isolation_handle(c, 43, 38, lit=True)
        _mark_at(c, 44, 52)
        # small dark window, one pane catching light
        c.rect(9, 36, 10, 8, K)
        c.rect(10, 37, 8, 6, D)
        c.rect(13, 37, 1, 6, K)
        c.rect(10, 40, 8, 1, K)
        c.px(11, 38, G)
        c.rect(0, 62, 64, 2, D)
    else:   # plain house: pitched roof, chimney, one dim window
        _wall(c, 7, 30, 50, 34)
        _siding(c, 7, 32, 50, 32, 6)
        for y in range(10, 31):
            hw = 3 + (y - 10) * 28 // 20
            c.rect(32 - hw, y, hw * 2 + 1, 1, D)
            c.px(32 - hw, y, G)
            c.px(32 + hw, y, K)
        c.dith(8, 12, 48, 18, K, 7, only=D)
        c.rect(3, 30, 58, 1, G)
        c.rect(3, 31, 58, 1, K)
        c.rect(44, 12, 5, 10, D)           # chimney
        c.rect(43, 11, 7, 1, G)
        c.dith(43, 2, 8, 8, D, 3)          # a little smoke
        c.ellipse(32, 20, 2.5, 2.5, K)     # attic vent
        c.rect(30, 20, 5, 1, D)
        # curtained window, dim
        c.rect(43, 38, 10, 10, K)
        c.rect(44, 39, 8, 8, G)
        c.dith(44, 39, 8, 8, D, 6, only=G)
        c.rect(47, 39, 2, 8, K)
        c.rect(42, 48, 12, 1, G)
        _mark_at(c, 12, 44)
        c.rect(0, 62, 64, 2, D)
    c.paste(_crop(door_art(False), 0, 0, 16, 32), DOOR[0], DOOR[1])
    c.outline(K)
    return c


def _crop(c, x, y, w, h):
    n = C(w, h)
    for yy in range(h):
        for xx in range(w):
            n.p[xx, yy] = c.get(x + xx, y + yy)
    return n


# ------------------------------------------------------------------ interior tiles

def _panel(c, rivets=False):
    c.rect(0, 0, 16, 16, D)
    c.dith(0, 0, 16, 16, K, 4, only=D)
    c.rect(15, 0, 1, 16, K)
    c.rect(0, 15, 16, 1, K)
    c.rect(0, 0, 1, 15, G)
    c.dith(0, 0, 1, 15, D, 8)
    if rivets:
        for (x, y) in ((2, 2), (12, 2), (2, 12), (12, 12)):
            c.px(x, y, G)
            c.px(x + 1, y + 1, K)
    return c


def interior(kind):
    c = C(16, 16)
    if kind == 2:     # floor boards: lit lip on top
        c.rect(0, 0, 16, 16, D)
        c.rect(0, 0, 16, 1, W)
        c.rect(0, 1, 16, 1, G)
        c.rect(0, 2, 16, 1, K)
        for y in (7, 12):
            c.rect(0, y, 16, 1, K)
        for (x, y0, y1) in ((5, 3, 6), (13, 3, 6), (1, 8, 11), (9, 8, 11), (5, 13, 15), (13, 13, 15)):
            c.rect(x, y0, 1, y1 - y0 + 1, K)
        c.dith(0, 3, 16, 13, K, 3, only=D)
        return c
    _panel(c, rivets=(kind == 1))
    if kind == 3:     # window, lit
        c.rect(2, 2, 12, 11, K)
        c.rect(3, 3, 10, 9, W)
        c.rect(7, 3, 2, 9, K)
        c.rect(3, 7, 10, 1, K)
        c.rect(1, 13, 14, 1, G)
    elif kind == 4:   # shelf with parts
        c.rect(1, 10, 14, 1, G)
        c.rect(1, 11, 14, 1, K)
        c.rect(3, 12, 1, 2, D)
        c.rect(12, 12, 1, 2, D)
        c.rect(2, 6, 3, 4, G)              # jar
        c.rect(2, 6, 3, 1, D)
        c.ellipse(8, 8, 2, 2, D)           # coil
        c.px(8, 8, G)
        c.rect(11, 7, 3, 3, D)             # bulb in a box
        c.px(12, 8, W)
        c.rect(1, 3, 14, 1, G)             # upper shelf
        c.rect(3, 1, 2, 2, D)
        c.rect(9, 1, 4, 2, G)
    elif kind in (5, 6, 7):   # counter, left, middle, right
        c.rect(0, 5, 16, 11, D)
        c.dith(0, 7, 16, 9, K, 5, only=D)
        c.rect(0, 5, 16, 1, W)
        c.rect(0, 6, 16, 1, G)
        c.rect(0, 7, 16, 1, K)
        for x in (4, 11):
            c.rect(x, 8, 1, 8, K)
        if kind == 5:
            c.rect(0, 5, 1, 11, K)
            c.px(0, 5, G)
        if kind == 7:
            c.rect(15, 5, 1, 11, K)
            c.px(15, 5, G)
        if kind == 6:
            c.rect(6, 10, 4, 3, K)         # cash drawer
            c.px(7, 11, G)
            c.rect(9, 2, 3, 3, G)          # a part left on the counter
            c.px(10, 3, K)
    elif kind == 8:   # hanging lamp
        c.rect(7, 0, 1, 6, K)
        c.rect(5, 6, 6, 1, G)
        c.rect(4, 7, 8, 2, D)
        c.rect(4, 7, 8, 1, G)
        c.rect(6, 9, 4, 2, W)
        c.dith(3, 11, 10, 4, G, 3)
    elif kind == 9:   # schematic pinned to the wall, with a maintenance mark
        c.rect(2, 2, 12, 11, G)
        c.rect(2, 2, 12, 1, W)
        c.rect(4, 5, 5, 1, K)
        c.rect(8, 5, 1, 4, K)
        c.rect(8, 8, 4, 1, K)
        c.rect(4, 5, 1, 5, K)
        c.rect(3, 9, 3, 1, K)
        c.px(11, 7, K)
        c.px(11, 9, K)
        c.art(10, 9, ['..d', 'd.d', 'd..'])
        c.px(7, 2, K)                      # pin
    elif kind == 10:  # doorway out: dark arch, daylight at the threshold
        c.ellipse(8, 5, 6, 5, G)
        c.rect(2, 5, 12, 11, G)
        c.ellipse(8, 5.5, 5, 4.5, K)
        c.rect(3, 5, 10, 11, K)
        c.dith(3, 9, 10, 7, D, 6)
        c.dith(3, 13, 10, 3, G, 5)
    return c


# ------------------------------------------------------------------ speech bubble and prompt

# The bubble is a 9-slice of 8x8 parts: dark fill, grey rim, white text on top.
BUBBLE_TL = ['..gggggg', '.gkkkkkk', 'gkkkkkkk', 'gkkkkkkk', 'gkkkkkkk', 'gkkkkkkk', 'gkkkkkkk', 'gkkkkkkk']
BUBBLE_TAIL = ['kkkkkkkk'] * 7 + ['ggkkkkgg', '.gkkkkg.', '.gkkkg..', '..gkkg..', '..gkg...', '..gg....',
                                  '..g.....']


def bubble_part(k):
    c = C(16, 16)
    p = C(8, 8)
    tl = C(8, 8)
    tl.art(0, 0, BUBBLE_TL)
    if k == 9:
        c.art(0, 0, BUBBLE_TAIL)
        return c
    col, row = k % 3, k // 3
    if (col, row) == (1, 1):
        p.rect(0, 0, 8, 8, K)
    elif col != 1 and row != 1:
        p = tl
        if col == 2:
            p = p.flip_h()
        if row == 2:
            p = p.flip_v()
    elif row != 1:   # top or bottom edge
        p.rect(0, 0, 8, 8, K)
        p.rect(0, 0, 8, 1, G)
        if row == 2:
            p = p.flip_v()
    else:            # left or right edge
        p.rect(0, 0, 8, 8, K)
        p.rect(0, 0, 1, 8, G)
        if col == 2:
            p = p.flip_h()
    c.paste(p, 0, 0)
    return c


def prompt(f):
    c = C(16, 16)
    y = 1 + f
    c.rect(3, y, 10, 11, K)
    c.frame(3, y, 10, 11, G)
    for (x, yy) in ((3, y), (12, y), (3, y + 10), (12, y + 10)):
        c.px(x, yy, T)
    c.art(5, y + 2, ['..ww..', '..ww..', '..ww..', 'wwwwww', '.wwww.', '..ww..', '......'])
    c.art(6, y + 11, ['gggg', '.gg.'])
    return c


# ------------------------------------------------------------------ switchboard

JACKS = [(8 + i * 5, 9 + j * 4) for j in range(3) for i in range(4)]


def switchboard(mode, f=0):
    """32x32 level-select switchboard: jack field, patch cords, desk of plugs."""
    c = C(32, 32)
    # cabinet with a rounded top, desk shelf, legs
    c.rect(4, 6, 24, 18, D)
    c.ellipse(16, 6, 12, 3, D)
    c.rect(5, 6, 22, 1, G)
    c.rect(6, 8, 20, 14, K)
    c.rect(2, 24, 28, 3, G)
    c.rect(2, 26, 28, 1, D)
    c.rect(4, 27, 3, 5, D)
    c.rect(25, 27, 3, 5, D)
    c.rect(7, 27, 18, 2, D)
    # nameplate lamp on the crest
    c.rect(14, 3, 4, 2, G)
    # jack field
    lit_a = {0, 3, 5, 6, 9, 10}
    lit_b = {1, 2, 4, 7, 8, 11}
    lit = set()
    if mode == 'idle':
        lit = lit_a if f == 0 else lit_b
    elif mode == 'use':
        lit = ({5}, {5, 6}, set(range(12)))[f]
    for i, (x, y) in enumerate(JACKS):
        c.rect(x, y + 1, 2, 2, D)
        c.px(x, y + 1, G)
        c.px(x, y, W if i in lit else D)
    # patch cords drooping between jacks
    for (a, b) in ((0, 5), (2, 7), (8, 10)):
        (x0, y0), (x1, y1) = JACKS[a], JACKS[b]
        for k in range(0, 9):
            t = k / 8.0
            x = int(round(x0 + (x1 - x0) * t))
            y = int(round(y0 + 2 + (y1 - y0) * t + 3 * (1 - (2 * t - 1) ** 2)))
            c.px(x, y, G)
    # plugs waiting on the desk
    for x in (8, 13, 22):
        c.rect(x, 22, 2, 2, G)
    # use: a plug rises to a jack, sparks, then the whole board lights
    if mode == 'use':
        tx, ty = JACKS[6]
        py = (20, ty + 1, ty + 1)[f]
        c.rect(tx, py, 2, 2, G)
        c.line(tx, py + 2, 18, 23, G)
        if f == 1:
            for (dx, dy) in ((-2, 0), (3, 0), (0, -2), (1, 3)):
                c.px(tx + dx, ty + 1 + dy, W)
    c.outline(K)
    return c


# ------------------------------------------------------------------ shop items, props

def shop_icon(k):
    c = C(16, 16)
    if k == 0:     # extra life: a small Spark with a +
        c.art(2, 6, ICON_LIFE)
        c.art(9, 2, ['.w.', 'www', '.w.'])
    elif k == 1:   # CHARGE start: a charged cell
        c.rect(5, 2, 6, 1, G)
        c.rect(4, 3, 8, 11, D)
        c.frame(4, 3, 8, 11, G)
        c.art(5, 5, ICON_CHARGE)
    elif k == 2:   # shard compass: a dial with a shard for a needle
        c.ellipse(8, 8, 6, 6, G)
        c.ellipse(8, 8, 5, 5, D)
        for (x, y) in ((8, 3), (3, 8), (12, 8), (8, 12)):
            c.px(x, y, G)
        c.art(8, 4, ['..w', '.ww', 'www', 'ww.'])
        c.art(5, 8, ['.g', 'g.'])
        c.px(8, 8, K)
    elif k == 3:   # lantern
        c.rect(6, 1, 4, 1, G)
        c.px(5, 2, G)
        c.px(10, 2, G)
        c.rect(5, 3, 6, 2, D)
        c.rect(5, 5, 6, 7, W)
        c.rect(5, 5, 1, 7, G)
        c.rect(10, 5, 1, 7, G)
        c.rect(7, 5, 1, 7, D)
        c.rect(4, 12, 8, 2, D)
    else:          # sold out: an empty tag crossed out
        c.rect(3, 4, 10, 8, D)
        c.frame(3, 4, 10, 8, G)
        c.px(3, 4, T)
        c.px(12, 4, T)
        c.line(4, 5, 11, 10, G)
        c.line(11, 5, 4, 10, G)
    c.outline(K)
    return c


def village_prop(k):
    c = C(16, 16)
    if k == 0:     # bench
        c.rect(1, 9, 14, 2, G)
        c.rect(1, 9, 14, 1, W)
        c.rect(12, 3, 2, 6, D)             # back posts
        c.rect(11, 4, 4, 1, G)
        c.rect(11, 6, 4, 1, G)
        c.rect(2, 11, 2, 5, D)
        c.rect(12, 11, 2, 5, D)
        c.rect(4, 13, 8, 1, D)
    elif k == 1:   # signpost THE LINE, pointing right (do not mirror)
        c.rect(5, 12, 2, 4, D)
        c.rect(0, 1, 13, 11, G)
        for y in range(1, 12):
            reach = 13 + min(y - 1, 11 - y) // 2
            c.rect(13, y, max(0, reach - 13), 1, G)
        c.art(1, 2, ['kkk.k.k.kkk', '.k..kkk.kk.', '.k..k.k.k..', '.k..k.k.kkk'])
        c.art(1, 7, ['k..k.kk..kkk', 'k..k.k.k.kk.', 'k..k.k.k.k..', 'kk.k.k.k.kkk'])
    elif k == 2:   # crate
        c.rect(1, 3, 14, 13, D)
        c.frame(1, 3, 14, 13, G)
        c.line(2, 4, 13, 14, G)
        c.rect(1, 9, 14, 1, G)
        _mark_at(c, 3, 10)
    elif k == 3:   # hanging lantern
        c.rect(7, 0, 2, 3, D)
        c.rect(5, 3, 6, 2, D)
        c.rect(5, 5, 6, 6, W)
        c.rect(5, 5, 1, 6, G)
        c.rect(10, 5, 1, 6, G)
        c.rect(5, 11, 6, 1, D)
        c.px(7, 12, D)
    elif k == 4:   # short antenna mast
        c.rect(7, 2, 1, 12, D)
        c.rect(5, 5, 5, 1, G)
        c.rect(6, 8, 3, 1, G)
        c.px(7, 1, W)
        c.rect(4, 14, 7, 2, D)
        c.rect(4, 14, 7, 1, G)
    else:          # cable reel
        c.ellipse(8, 9, 6.5, 6.5, D)
        c.ellipse(8, 9, 5, 5, G)
        for r in (4, 2.8):
            c.ellipse(8, 9, r, r, D)
            c.ellipse(8, 9, r - 0.8, r - 0.8, G)
        c.ellipse(8, 9, 1.5, 1.5, K)
        c.line(13, 12, 15, 15, G)
    c.outline(K)
    return c


# ------------------------------------------------------------------ village backdrop

def _cable(c, y=40, sag=4):
    """The one cable every piece carries at its edges, so pieces join in any order."""
    for x in range(96):
        u = (x - 47.5) / 47.5
        if bayer(x, 0) < 12:
            c.px(x, int(round(y + sag * (1 - u * u))), D)


def _roof_house(c, x, w, base, ridge, chimney=None):
    for y in range(ridge, base):
        hw = min(w // 2, (y - ridge) * 3 // 2 + 1)
        c.rect(x + w // 2 - hw, y, hw * 2, 1, D)
    c.rect(x, base, w, 128 - base, D)
    if chimney is not None:
        c.rect(x + chimney, ridge + 2, 3, 8, D)


def backdrop_village(piece):
    """96x128 far rooftops and aerials, dark and dither only. Bottoms on row 127."""
    c = C(96, 128)
    _cable(c)
    if piece == 0:    # two pitched houses and a chimney with smoke
        _roof_house(c, 6, 36, 98, 80, chimney=24)
        _roof_house(c, 44, 44, 92, 70, chimney=8)
        c.dith(50, 50, 8, 18, D, 3)
        c.rect(0, 112, 96, 16, D)
        c.px(62, 100, W)
        c.px(63, 100, W)
    elif piece == 1:  # domed relay hall with a dish
        c.ellipse(48, 96, 34, 22, D)
        c.rect(14, 96, 68, 32, D)
        c.ellipse(64, 70, 7, 4, D)
        c.rect(63, 72, 2, 6, D)
        c.rect(46, 64, 2, 10, D)
        c.rect(0, 112, 96, 16, D)
        c.px(30, 104, W)
    elif piece == 2:  # tall aerial with guy wires and a hut at the foot
        cx = 48
        for y in range(10, 112):
            hw = 1 + (y - 10) // 25
            c.px(cx - hw, y, D)
            c.px(cx + hw, y, D)
            if y % 6 == 0:
                c.rect(cx - hw, y, hw * 2 + 1, 1, D)
        c.rect(cx, 2, 1, 8, D)
        for side in (-1, 1):
            for x in range(0, 40):
                if bayer(cx + side * x, 0) < 10:
                    c.px(cx + side * x, 30 + x * 2, D)
        _roof_house(c, 8, 26, 104, 94)
        c.rect(0, 112, 96, 16, D)
        c.px(cx, 2, W)
    else:             # terrace of small houses with a water tank
        _roof_house(c, 2, 28, 100, 88)
        _roof_house(c, 30, 30, 94, 80, chimney=20)
        _roof_house(c, 62, 32, 102, 90)
        c.rect(70, 70, 16, 12, D)
        c.ellipse(78, 70, 8, 3, D)
        c.rect(72, 82, 1, 8, D)
        c.rect(83, 82, 1, 8, D)
        c.rect(0, 112, 96, 16, D)
        c.px(42, 98, W)
        c.px(76, 106, W)
    # dark unlit windows give the masses a lived-in texture
    for (x, y) in {0: ((14, 100), (26, 104), (52, 96), (74, 100)), 1: ((22, 100), (40, 98), (58, 100), (70, 104)),
                   2: ((14, 106), (26, 106)), 3: ((10, 102), (40, 90), (50, 90), (70, 104), (84, 106))}[piece]:
        if c.get(x, y) == D:
            c.rect(x, y, 2, 3, K)
    # the ground band sinks toward black; the buildings stay solid dark grey
    for y in range(112, 128):
        for x in range(96):
            if c.get(x, y) == D and bayer(x, y) < 2 + (y - 112) // 4:
                c.px(x, y, K)
    return c


def build_village():
    rows = []
    for (nid, fn, _desc) in NPCS:
        rows.append(A(nid + '_idle', [fn('idle', f) for f in range(4)], 0.2, note=_desc))
        rows.append(A(nid + '_talk', [fn('talk', f) for f in range(2)], 0.12))
    sheet('npc', 16, 24, rows,
          'Last Relay villagers ("listeners"). Anchor top-left at (cell x, cell y - 8), so the feet sit on the '
          'floor of the cell. Face left, mirror for right. Grey bodies, two white dot eyes, round tops, no '
          'teeth, so they never read as the white striped enemies.')
    sheet('house', 64, 64, [
        A('facades', [facade(k) for k in range(5)], 0,
          note='0 keeper (lit window with the broken diagonal mullion), 1 shop, 2 radio shack, 3 switch hut '
               '(isolation handle), 4 plain house. Top-left = (door cell x - 24, door cell y - 48)'),
        A('door', [door_art(False), door_art(True)], 0,
          note='0 closed, 1 open. The door is 16x32 at the top-left of the frame: draw the frame at '
               '(door cell x, door cell y - 16), exactly over the door painted on the facade'),
    ], 'Village house fronts, static. The door is centred on the bottom edge: door cell x - 24 is the facade '
       'left edge and the facade bottom sits on the door cell\'s floor. Houses do not mirror.')
    sheet('interior', 16, 16, [
        A('tiles', [interior(k) for k in range(11)], 0,
          note='0 wall, 1 wall rivets, 2 floor top, 3 window lit, 4 shelf, 5 counter left, 6 counter middle, '
               '7 counter right, 8 hanging lamp, 9 schematic, 10 doorway out. All opaque over the wall'),
    ], 'Inside rooms. Every tile but the floor carries the wall panel behind it, so they drop into one grid.')
    sheet('bubble', 16, 16, [
        A('parts', [bubble_part(k) for k in range(10)], 0,
          note='9-slice of 8x8 parts at the top-left of each frame: 0 TL, 1 top, 2 TR, 3 left, 4 fill, '
               '5 right, 6 BL, 7 bottom, 8 BR. Step 8 px. 9 tail: 8x16, draw it in place of one bottom part '
               'and it hangs 7 px below'),
        A('prompt', [prompt(0), prompt(1)], 0.4,
          note='press down to talk or enter. Centre over the NPC or door, bottom 4 px above its top'),
    ], 'Speech bubble and talk prompt. Dark fill, grey rim, white text goes on top.')
    sheet('switchboard', 32, 32, [
        A('idle', [switchboard('idle', 0), switchboard('idle', 1)], 0.5, note='jack lamps blink'),
        A('use', [switchboard('use', f) for f in range(3)], 0.08, loop=False,
          note='a plug goes into a jack, sparks, then every lamp lights'),
    ], 'Level-select switchboard in the village. Top-left = (cell x - 8, cell y - 16): centred on its cell, '
       'standing on the floor.')
    sheet('shop_items', 16, 16, [
        A('icons', [shop_icon(k) for k in range(5)], 0,
          note='0 extra life, 1 CHARGE start, 2 shard compass, 3 lantern, 4 sold out'),
    ], "Tally's shop items.")
    sheet('village_props', 16, 16, [
        A('props', [village_prop(k) for k in range(6)], 0,
          note='0 bench, 1 signpost THE LINE (points right, do not mirror), 2 crate, 3 hanging lantern '
               '(top-left under the beam), 4 short antenna mast, 5 cable reel'),
    ], 'Village props. Bottoms on the cell floor unless the note says otherwise.')
    sheet('backdrop_village', 96, 128, [
        A('pieces', [backdrop_village(k) for k in range(4)], 0,
          note='0 pitched houses, 1 domed relay hall, 2 tall aerial, 3 terrace with water tank'),
    ], 'Last Relay far rooftops and aerials, like `backdrop_w2`: far layer, parallax 0.2x, 70% opacity, every '
       'bottom on one horizon line. Lay the pieces edge to edge, one every 96 px: each carries the same '
       'cable and ground band at its edges, so they join in any order. A tiny lit window or two per piece.')


# =================================================================== review

def contact():
    items = []
    for name, s in SHEETS.items():
        img = Image.open(os.path.join(OUT, s['file']))
        items.append((name, img))
    pad = 6
    width = 900
    x = y = pad
    rowh = 0
    placements = []
    for name, img in items:
        w, h = img.size
        if x + w + pad > width:
            x = pad
            y += rowh + 12
            rowh = 0
        placements.append((name, img, x, y + 8))
        x += max(w, 40) + pad
        rowh = max(rowh, h + 8)
    height = y + rowh + 12
    out = Image.new('RGBA', (width, height), (24, 24, 30, 255))
    from PIL import ImageDraw
    dr = ImageDraw.Draw(out)
    for name, img, px, py in placements:
        bg = Image.new('RGBA', img.size, (11, 11, 11, 255))
        # checker to show transparency
        for yy in range(0, img.size[1], 4):
            for xx in range(0, img.size[0], 4):
                if (xx // 4 + yy // 4) % 2:
                    bg.paste((20, 20, 26, 255), (xx, yy, xx + 4, yy + 4))
        bg.alpha_composite(img)
        out.paste(bg, (px, py))
        dr.text((px, py - 9), name, fill=(200, 200, 90, 255))
    out = out.resize((width * 3, height * 3), Image.NEAREST)
    os.makedirs(REVIEW, exist_ok=True)
    out.save(os.path.join(REVIEW, 'contact.png'))


def main():
    os.makedirs(OUT, exist_ok=True)
    build_terrain()
    build_bumps()
    build_brick()
    build_loose()
    build_spikes()
    build_ceiling()
    build_press()
    build_dropper()
    build_switches()
    build_pickups()
    build_enemies()
    build_markers()
    build_backdrop()
    build_fx()
    build_switchyard()
    build_atmosphere()
    build_village()
    with open(os.path.join(OUT, 'sheets.json'), 'w', encoding='utf-8') as fh:
        json.dump(SHEETS, fh, indent=1)
    # the same manifest as a GDScript constant, so Godot needs no JSON at runtime
    slim = {k: {'file': v['file'], 'fw': v['fw'], 'fh': v['fh'],
                'anims': {n: {'row': a['row'], 'frames': a['frames'], 'dur': a['dur'], 'loop': a['loop']}
                          for n, a in v['anims'].items()}} for k, v in SHEETS.items()}
    gd = os.path.join(ROOT, 'scripts', 'world1', 'sheet_data.gd')
    nl = chr(10)
    with open(gd, 'w', encoding='utf-8', newline=nl) as fh:
        fh.write('extends RefCounted' + nl)
        fh.write('## Generated by assets/world1/src/make_sheets.py. Do not edit by hand.' + nl)
        fh.write('## sheet -> {file, fw, fh, anims: {name -> {row, frames, dur[], loop}}}' + nl + nl)
        fh.write('const SHEETS := ' + json.dumps(slim, indent=chr(9)) + nl)
    import readme
    readme.write(SHEETS, OUT, sections={'channel_block': readme.WORLD2, 'lamp': readme.ATMOSPHERE,
                                         'npc': readme.VILLAGE})
    contact()
    print(f'{len(SHEETS)} sheets written to {OUT}')


if __name__ == '__main__':
    main()
