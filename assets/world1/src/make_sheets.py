"""Generates every World 1 to World 4 sprite sheet in assets/world1/.

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


# =================================================================== pips

# Pips are tiny sparks of signal, the Spark's small cousins, that carried
# voices along the line. When it was cut they were caught in the old glass
# insulators. Touch one and the glass breaks and the Pip zips home.

# the glass dome: (row, first x, last x). 12 px wide, 10 rows, the groove for
# the wire pinches it at row 6.
PIP_DOME = [(1, 5, 10), (2, 4, 11), (3, 3, 12), (4, 3, 12), (5, 3, 12), (6, 4, 11),
            (7, 3, 12), (8, 2, 13), (9, 2, 13), (10, 2, 13)]


def _pip_mount(c):
    """The metal pin under the glass and the stub of crossarm it bolts to."""
    c.rect(7, 11, 2, 3, D)
    c.rect(3, 14, 10, 1, D)
    c.px(4, 14, G)                         # bolt heads
    c.px(11, 14, G)
    c.px(7, 11, G)                         # a glint on the pin


def _pip_body(c, x, y, w, h, col=W, shut=False, feet=False, tip=W):
    """Boxy body, rounded on top and flat underneath, two dot eyes low in the
    middle and a one-pixel antenna with a lit tip (tip=None leaves it off).
    Flat bottom and antenna keep it a little creature, never a skull."""
    c.rect(x + 1, y, w - 2, h, col)
    c.rect(x, y + 1, w, h - 1, col)
    ey = y + h // 2
    ex = x + (w - 3) // 2
    if shut:
        c.rect(ex, ey, 3, 1, K)
    else:
        c.px(ex, ey, K)
        c.px(ex + 2, ey, K)
    if tip:
        c.px(x + w // 2, y - 1, G)
        c.px(x + w // 2, y - 2, tip)
    if feet:
        c.px(x + 1, y + h, D)
        c.px(x + w - 2, y + h, D)


def _pip_glass():
    """The dome's pixels and its 1 px glass wall (thick at the crown and lip)."""
    dome = {(x, y) for y, x0, x1 in PIP_DOME for x in range(x0, x1 + 1)}
    wall = {(x, y) for (x, y) in dome if y in (1, 10) or
            any((x + dx, y + dy) not in dome for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))}
    return dome, wall


PIP_SHINE = ((4, 3), (4, 4), (4, 5), (3, 8), (3, 9), (6, 1), (7, 1), (11, 3))


def _pip_glow(c, inside, body, strong=True):
    """A dark grey halo on the glass's inside round the Pip: solid beside it,
    half on the diagonals. Dim, it thins to a dither."""
    for (x, y) in inside:
        if (x, y) in body:
            continue
        d = min(math.hypot(x - bx, y - by) for (bx, by) in body)
        thr = (16 if strong else 6) if d < 1.1 else (8 if strong else 0) if d < 1.5 else 0
        if bayer(x, y) < thr:
            c.px(x, y, D)


def _pip_insulator(c, bx, by, strong=True):
    """Pin, dark glass dome with its wall and shine, glow round a 5x4 Pip whose
    top-left is (bx, by)."""
    _pip_mount(c)
    dome, wall = _pip_glass()
    for (x, y) in dome:
        c.px(x, y, K)
    c.outline(K)
    for (x, y) in wall:
        c.px(x, y, G)
    body = {(x, y) for x in range(bx, bx + 5) for y in range(by, by + 4)} | {(bx + 2, by - 1), (bx + 2, by - 2)}
    _pip_glow(c, dome - wall, body, strong)
    for (x, y) in PIP_SHINE:
        c.px(x, y, W)


def pip_trapped(f):
    """A glass insulator on its pin with a Pip glowing inside. Frame 1 it hops
    and its antenna taps the glass, frame 2 it drifts a pixel, frame 3 it
    flickers dim with its eyes shut."""
    c = C(16, 16)
    bx, by = 5 + (0, 0, 1, 0)[f], 5 + (0, -1, 0, 0)[f]
    _pip_insulator(c, bx, by, strong=(f != 3))
    if f == 1:                             # the shine slides as it knocks the glass
        c.px(11, 3, G)
        c.px(11, 4, W)
    _pip_body(c, bx, by, 5, 4, G if f == 3 else W, shut=(f == 3), tip=G if f == 3 else W)
    return c


# what is left on the pin: the dark lip of the glass with a jagged broken edge
PIP_RIM = ['...g............',
           '...gw......g....',
           '..gdd.g...gdg...',
           '..gddddddddddg..']


def _pip_rim(c):
    _pip_mount(c)
    c.art(0, 7, PIP_RIM)


def _plus(c, x, y, r, arm=G, mid=W):
    for k in range(1, r + 1):
        for (dx, dy) in ((k, 0), (-k, 0), (0, k), (0, -k)):
            c.px(x + dx, y + dy, arm)
    c.px(x, y, mid)


def pip_break(f):
    """The glass cracks with light, bursts into shards that fly out and fall,
    and the Pip flashes white and goes. The last frame is the empty pin and a
    few falling bits."""
    c = C(16, 16)
    if f == 0:
        _pip_insulator(c, 5, 5)
        for (x, y) in ((5, 2), (6, 3), (6, 4), (10, 3), (10, 4), (11, 5), (4, 7), (3, 7),
                       (11, 8), (12, 9), (9, 9), (8, 10)):
            c.px(x, y, W)                  # cracks full of light
        _pip_body(c, 5, 5, 5, 4, W, shut=True)
        c.outline(K)
        return c
    _pip_rim(c)
    _, wall = _pip_glass()
    rim = {(x, y) for y, row in enumerate(PIP_RIM, 7) for x, ch in enumerate(row) if ch != '.'}
    if f <= 2:                             # the dome in seven pieces, flying out and falling
        pieces = (wall | set(PIP_SHINE)) - rim - {(x, 10) for x in range(16)}
        r = 2 * f
        for (x, y) in sorted(pieces):
            if f == 2 and hash2(x, y) % 2:
                continue
            ang = math.atan2(y + 0.5 - 6, x + 0.5 - 8)
            sector = (math.floor((ang + math.pi) / (2 * math.pi) * 7) + 0.5) / 7 * 2 * math.pi - math.pi
            nx = x + round(math.cos(sector) * r)
            ny = y + round(math.sin(sector) * r + 0.25 * f * f)
            shiny = (x, y) in PIP_SHINE or hash2(y, x) % 3 == 0
            c.px(nx, ny, W if shiny else G)
    else:                                  # the last bits, near the edges and dropping
        bits = [((1, 3, G), (14, 2, W), (0, 8, W), (15, 9, G), (2, 13, G), (13, 12, W)),
                ((0, 7, G), (15, 6, W), (1, 14, W), (14, 15, G))][f - 3]
        for (x, y, col) in bits:
            c.px(x, y, col)
    if f == 1:                             # the Pip flares, eyes squeezed shut
        for (x, y, col) in ((2, 6, W), (1, 6, G), (12, 6, W), (13, 6, G), (3, 2, W), (2, 1, G),
                            (11, 2, W), (12, 1, G), (3, 10, W), (11, 10, W)):
            c.px(x, y, col)
        _pip_body(c, 5, 4, 5, 5, W, shut=True)
    elif f == 2:                           # a white star where it was
        _plus(c, 7, 6, 3, W, W)
        c.rect(6, 5, 3, 3, W)
        for (x, y) in ((4, 3), (10, 3), (4, 9), (10, 9)):
            c.px(x, y, G)
    elif f == 3:
        _plus(c, 7, 5, 1, G, W)
    c.outline(K)
    return c


def pip_empty():
    """After the rescue: the pin and the jagged lip of broken glass."""
    c = C(16, 16)
    _pip_rim(c)
    c.outline(K)
    return c


def pip_free(f):
    """The freed Pip, 5x5 in the middle of the frame, antenna tip flickering,
    fizzing a sparkle trail below it as it zips up and away."""
    c = C(16, 16)
    _pip_body(c, 5, 5, 5, 5, W, tip=(W, G, W, G)[f])
    c.outline(K)
    trail = [((7, 12, W), (6, 12, G), (8, 12, G), (7, 13, G), (7, 15, G)),
             ((8, 12, G), (6, 13, W), (8, 15, G)),
             ((7, 12, W), (7, 13, G), (8, 14, W), (6, 15, G)),
             ((6, 12, G), (8, 13, W), (7, 15, W))][f]
    for (x, y, col) in trail:
        c.px(x, y, col)
    return c


def pip_hop(f):
    """A rescued Pip bouncing on the spot, feet on the frame's bottom row:
    stand, squash, spring up stretched, come down."""
    c = C(16, 16)
    x, y, w, h = [(5, 10, 5, 5), (4, 11, 7, 4), (5, 7, 5, 6), (5, 9, 5, 5)][f]
    _pip_body(c, x, y, w, h, W, feet=True)
    c.outline(K)
    if f == 2:                             # a happy fizz by its antenna at the top of the hop
        c.px(10, 4, W)
        c.px(11, 3, G)
    return c


def build_pips():
    sheet('pip', 16, 16, [
        A('trapped', [pip_trapped(f) for f in range(4)], [0.3, 0.12, 0.3, 0.12],
          note='a Pip caught in a glass insulator: rest, hop (antenna taps the glass), drift, dim flicker. '
               'Its 5x4 body is x 5 to 9, y 5 to 8, so its centre is (7.5, 7) from the frame top-left. '
               'The dome is x 2 to 13, y 1 to 10, the pin and crossarm stub below it to row 14'),
        A('break', [pip_break(f) for f in range(5)], 0.05, loop=False,
          note='touched: the glass cracks with light, bursts, the Pip flashes white and is gone, the last '
               'bits fall. Then show empty and send a free Pip up from the same centre'),
        A('empty', [pip_empty()], 0, note='the pin and the jagged dark lip of broken glass, after the rescue'),
        A('free', [pip_free(f) for f in range(4)], 0.08,
          note='the freed Pip zipping home. 5x5 body at x 5 to 9, y 5 to 9 (centre (7.5, 7.5)), antenna tip '
               'flickering, a sparkle trail below it. Move it in code'),
        A('hop', [pip_hop(f) for f in range(4)], 0.12,
          note='a rescued Pip bouncing in the village: stand, squash, spring up, come down. Feet on the '
               'bottom row, centred on x 7.5. Start each Pip on a different frame so a crowd is not in step'),
    ], "Pips: tiny sparks of signal, the Spark's small cousins, caught in the old glass insulators when "
       'the line was cut. Top-left on the tile top-left, like a shard. They float, so the pin needs no pole. '
       'Boxy white body, flat underneath, two dot eyes and a one-pixel antenna, so they never read as enemies.')


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

# Story signatures (docs/research/exploration/notes/story-arc.md, kept in the legacy-archive git tag)
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


def npc_spire(mode, f):
    """Spire the mast rigger: slim, climbing harness, a coil of rope over the
    back shoulder, goggles pushed up on the forehead."""
    c = C(16, 24)
    bob = (0, 0, 1, 1)[f] if mode == 'idle' else (0, -1)[f]
    hy = 7 + bob                             # head centre row
    # coil of rope slung on the back shoulder, behind the body
    cy = 14.5 + bob
    c.ellipse(12, cy, 3.3, 3.9, G)
    c.ellipse(12, cy, 1.3, 1.9, T)
    for y in range(int(cy) - 4, int(cy) + 5):     # twisted strands
        for x in range(8, 16):
            if c.get(x, y) == G and (x + y) % 3 == 0:
                c.px(x, y, D)
    # legs: climbing boots, a little apart
    c.rect(5, 20, 2, 4, D)
    c.rect(8, 20, 2, 4, D)
    # slim body in a dark work suit
    c.rect(4, 12 + bob, 6, 9 - bob, D)
    c.ellipse(7, 12.5 + bob, 3.2, 1.6, D)
    # harness: two shoulder straps, a waist belt and leg loops
    c.rect(5, 12 + bob, 1, 6 - bob, G)
    c.rect(8, 12 + bob, 1, 6 - bob, G)
    c.rect(4, 17, 6, 1, G)
    c.px(5, 19, G)
    c.px(8, 19, G)
    # the coil's sling over the shoulder
    c.line(9, 12 + bob, 11, 12 + bob, G)
    # arm: hangs by the harness, waves while talking
    if mode == 'talk' and f == 1:
        c.rect(2, 9, 1, 4, G)
        c.px(3, 12, G)
    else:
        c.rect(3, 13 + bob, 1, 4, G)
    # round head, shaded at the back
    c.ellipse(7, hy + 0.5, 3.6, 3.5, G)
    c.dith(8, hy - 3, 3, 7, D, 5, only=G)
    _eyes(c, 5, hy + 1, 2, shut=(mode == 'idle' and f == 3))
    c.px(5, hy + 3, D)                       # small smile
    # goggles pushed up onto the forehead: a strap round the crown, inside the
    # round head, and one grey lens at the front. Never white, so the lens
    # cannot read as a second pair of eyes
    for x in range(4, 11):
        if c.get(x, hy - 2) != T:
            c.px(x, hy - 2, D)
    c.art(3, hy - 3, ['kkk', 'kgk', 'kkk'])
    c.px(4, hy - 2, D if (mode == 'idle' and f == 2) else G)
    c.outline(K)
    # carabiner hanging off the belt, in front
    c.art(2, 17, ['gg', 'g.g', '.gg'])
    return c


NPCS = [
    ('mast', npc_mast, 'Old Mast, the keeper: tall, stooped, cloak, long antenna, cane'),
    ('tally', npc_tally, 'Tally, the trader: round body, big pack of parts, lamp on the pack'),
    ('wren', npc_wren, 'Wren, a listener kid: small, oversized headphones'),
    ('brace', npc_brace, 'Brace, the lineworker: hard hat, hook stick, notched isolation handle on the belt'),
    ('dot', npc_dot, 'Dot, the switch operator: boxy body, one lamp for a head that blinks when talking'),
    ('hum', npc_hum, 'Hum, the relay technician: heavy transformer torso, fins, small arms'),
    ('spire', npc_spire, 'Spire, the mast rigger: climbing harness, coiled rope over the back shoulder, '
                         'goggles pushed up. Added for World 3'),
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


# =================================================================== World 3: The Aerials

# Broadcast masts high above a drowned city at dawn. Wind carries the signal.
# Open sky, lattice towers, guy wires, catwalks and dishes over cloud banks.
# The game tints each world's four greys (World 3 is a pale violet dawn), so
# everything here is drawn in the same greys. Hazards keep white to a rim or a
# pixel: solid white is the Spark's colour.

def ground_w3(left=False, right=False, top=False, bottom=False, depth=0, alt=0):
    """Mast platform ground: a riveted deck plate on top, lattice steel with X
    cross-bracing below. The bays are dark, not open sky, so it reads solid."""
    c = C(16, 16)
    c.rect(0, 0, 16, 16, K)
    if depth < 2:                            # far lattice glimpsed in the bays
        c.dith(0, 0, 16, 16, D, 1)
    lit = depth < 2                          # deep steel loses its highlights
    steel = G if lit else D
    y0 = 6 if top else 2                     # first row of the bay under the deck or chord
    # X brace, corner to corner of the bay: dark beams with a lit upper edge
    if lit:
        c.line(3, y0, 15, 14, G)
        c.line(14, y0, 2, 14, G)
    c.line(2, y0, 15, 15, D)
    c.line(15, y0, 2, 15, D)
    # gusset plate where the braces cross, with a rivet
    my = (y0 + 15) // 2
    c.rect(7, my - 1, 3, 3, D)
    c.px(8, my, steel)
    # vertical post at the bay's left edge
    c.rect(0, 0, 2, 16, D)
    c.rect(0, 0, 1, 16, steel)
    for y in range(3, 16, 5):
        c.px(1, y, K)                        # bolt holes up the post
    if not top:
        # horizontal chord along the top of the bay: angle iron with rivets
        c.rect(0, 0, 16, 2, D)
        c.rect(0, 0, 16, 1, steel)
        for x in (4, 12):
            c.px(x, 1, K)
        c.rect(0, 0, 3, 3, D)                # corner gusset
        c.px(1, 1, steel)
    if alt == 2:                             # a snapped brace, one arm hangs loose
        c.line(15, y0, 2, 15, K)
        c.line(14, y0, 2, 14, K)
        c.line(15, y0, 12, y0 + 5, D)
        c.line(2, 15, 5, 12, D)
        c.px(12, y0 + 6, G)
        c.rect(7, my - 1, 3, 3, D)
        c.px(8, my, steel)
    elif alt == 1 and not top:               # a junction box bolted to the lattice
        c.rect(5, 6, 7, 6, D)
        c.frame(5, 6, 7, 6, K)
        c.rect(6, 7, 5, 1, G if lit else D)
        c.rect(7, 9, 3, 1, K)
        c.px(6, 10, G)
        c.px(10, 10, G)
    if top:
        # deck plate: white lip you stand on, then riveted plate
        c.rect(0, 0, 16, 1, W)
        c.rect(0, 1, 16, 1, G)
        c.rect(0, 2, 16, 3, D)
        for x in range(2, 16, 4):
            c.px(x, 3, G)
            c.px(x + 1, 4, K)
        c.rect(0, 5, 16, 1, K)               # shadow under the deck edge
        if alt == 1:                         # grating panel: slots in the deck
            for x in range(4, 12, 2):
                c.rect(x, 2, 1, 3, K)
            c.px(3, 3, D)
            c.px(12, 3, D)
        elif alt == 3:                       # tie-off eye for a rigger's rope
            c.rect(9, 2, 4, 3, K)
            c.art(9, 2, ['.gg.', 'g..g', '.gg.'])
            c.px(5, 3, D)
    if left:
        for y in range(16):
            c.px(0, y, G if (y + (0 if top else 1)) % 3 else D)
    if right:
        c.rect(15, 0, 1, 16, K)
        c.dith(14, 0, 1, 16, K, 8)
    if top:
        if left:
            c.px(0, 0, T)
            c.px(0, 1, G)
        if right:
            c.px(15, 0, T)
            c.px(15, 1, G)
    if bottom:
        # bottom flange of the platform, rivets, and two notches below
        c.rect(0, 13, 16, 3, D)
        c.rect(0, 13, 16, 1, steel)
        c.rect(0, 15, 16, 1, K)
        for x in (3, 7, 11):
            c.px(x, 14, K)
        c.px(5, 15, T)
        c.px(12, 15, T)
        if left:
            c.px(0, 15, T)
        if right:
            c.px(15, 15, T)
    return c


def block_w3(lip=True, kind=0):
    """Riveted mast-panel crate: a steel box with a riveted flange and a braced face."""
    c = C(16, 16)
    c.rect(0, 0, 16, 16, D)
    c.rect(15, 0, 1, 16, K)
    c.rect(0, 15, 16, 1, K)
    c.rect(0, 0, 1, 15, G)
    oy = 2 if lip else 0
    # recessed face inside the flange
    fy = 3 + oy
    c.rect(3, fy, 10, 13 - fy, K)
    c.dith(3, fy, 10, 13 - fy, D, 4)
    c.rect(3, fy, 10, 1, K)
    c.rect(3, fy, 1, 13 - fy, K)
    # rivets round the flange
    for (x, y) in ((1, 1 + oy), (7, 1 + oy), (13, 1 + oy), (1, 7 + oy // 2), (13, 7 + oy // 2),
                   (1, 13), (7, 13), (13, 13)):
        c.px(x, y, G)
        c.px(x + 1, y + 1, K)
    if kind == 1:  # louvres
        for k in range(3):
            c.rect(4, fy + 1 + k * 3, 8, 1, K)
            c.rect(4, fy + 2 + k * 3, 8, 1, G if k == 2 else D)
    else:
        # cross-brace on the face, like the lattice
        c.line(4, fy + 1, 11, 12, D)
        c.line(11, fy + 1, 4, 12, D)
        if kind == 2:  # status pip: the one live pixel on the crate
            my = (fy + 1 + 12) // 2
            c.rect(6, my - 1, 4, 3, K)
            c.px(7, my, W)
            c.px(8, my, G)
        elif kind == 3:  # stencilled mast: a little lattice tower
            c.art(5, fy + 1 - (1 if lip else 0), ['...g..', '..ggg.', '..g.g.', '.gg.gg', '.g...g', 'gg...g'])
    if lip:
        c.rect(0, 0, 16, 1, W)
        c.rect(0, 1, 16, 1, G)
        c.rect(15, 0, 1, 2, G)
    return c


# ------------------------------------------------------------------ Aerials backdrop

W3_CABLE_Y = 58      # the shared cable meets every piece edge at this row
W3_CLOUD_Y = 104     # the cloud bank's top meets every piece edge at this row
W3_CLOUDS = [        # (bumps across the piece, height) for each piece's cloud tops
    [(3, 5), (8, 2)],
    [(2, 4), (7, 2)],
    [(5, 6), (11, 2)],
    [(4, 4), (9, 2)],
]


def _w3_cable(c, posts):
    """The one cable every piece carries, strung between posts [(x, y), ...]. It
    is dithered, like the far cables of the Switchyard."""
    for (x0, y0), (x1, y1) in zip(posts, posts[1:]):
        sag = 6 * (x1 - x0) / 95
        for x in range(x0, x1 + 1):
            u = (x - x0) / max(1, x1 - x0)
            y = y0 + (y1 - y0) * u + sag * 4 * u * (1 - u)
            if bayer(x, 0) < 12:
                c.px(x, int(round(y)), D)


def _w3_clouds(c, piece):
    """Cloud bank along the bottom. Its top is at W3_CLOUD_Y at both edges, so
    any piece joins any other. A sparse grey rim catches the dawn."""
    waves = W3_CLOUDS[piece]
    tops = []
    for x in range(96):
        u = math.pi * (x + 0.5) / 96
        tops.append(W3_CLOUD_Y - sum(a * abs(math.sin(n * u)) for n, a in waves))
    for x in range(96):
        top = int(round(tops[x]))
        # soft upper fringe
        for y in (top - 2, top - 1):
            if bayer(x, y) < (3 if y == top - 2 else 8):
                c.px(x, y, D)
        for y in range(top, 128):
            c.px(x, y, D)
        # the dawn rim: a few grey flecks on the first solid rows
        for y in (top, top + 1):
            if bayer(x, y) < (5 if y == top else 1):
                c.px(x, y, G)
        # a second, lower layer of billows, and the bank darkens with depth
        low = int(round(W3_CLOUD_Y + 10 - sum(a * 0.6 * abs(math.sin((n + 1) * u)) for n, a in waves)))
        if bayer(x, low) < 6:
            c.px(x, low, K)
        for y in range(low + 1, 128):
            if bayer(x, y) < min(10, 2 + (y - low) // 3):
                c.px(x, y, K)


def _guyed_mast(c, cx, top, hw_top=1, hw_base=2, light=True, rings=()):
    """A thin guyed lattice mast from row `top` down into the clouds, tip light lit."""
    for y in range(top + 6, 128):
        hw = hw_top if y < (top + 128) // 2 else hw_base
        c.px(cx - hw, y, D)
        c.px(cx + hw, y, D)
        if (y - top) % 4 == 0:
            c.rect(cx - hw, y, hw * 2 + 1, 1, D)
        elif (y - top) % 4 == 2:
            c.px(cx, y, D)
    c.rect(cx, top + 1, 1, 5, D)             # the aerial whip above the lattice
    for (ry, rw) in rings:                    # catwalk rings with a handrail
        c.rect(cx - rw, ry, rw * 2 + 1, 1, D)
        for x in range(cx - rw, cx + rw + 1, 2):
            c.px(x, ry - 1, D)
        c.px(cx - rw, ry - 2, D)
        c.px(cx + rw, ry - 2, D)
    if light:                                 # tip light, drawn lit
        c.px(cx, top, W)
        for (dx, dy) in ((-1, 0), (1, 0), (0, -1)):
            c.px(cx + dx, top + dy, G)


def _guy_wire(c, x0, y0, x1, y1):
    n = max(abs(x1 - x0), abs(y1 - y0))
    for i in range(n + 1):
        x = int(round(x0 + (x1 - x0) * i / n))
        y = int(round(y0 + (y1 - y0) * i / n))
        if bayer(x, y) < 8:
            c.px(x, y, D)


def _rot_ellipse(c, cx, cy, rx, ry, ang, col, only=None):
    ca, sa = math.cos(ang), math.sin(ang)
    r = int(max(rx, ry)) + 2
    for y in range(int(cy) - r, int(cy) + r + 1):
        for x in range(int(cx) - r, int(cx) + r + 1):
            dx, dy = x + 0.5 - cx, y + 0.5 - cy
            u = (dx * ca + dy * sa) / rx
            v = (-dx * sa + dy * ca) / ry
            if u * u + v * v <= 1.0 and (only is None or c.get(x, y) == only):
                c.px(x, y, col)


def backdrop_w3(piece):
    """96x128 far silhouettes above the clouds, dark and dither only, with lit
    tip lights on the masts. Bottoms sit on row 127, inside the cloud bank."""
    c = C(96, 128)
    posts = [(0, W3_CABLE_Y), (95, W3_CABLE_Y)]
    if piece == 0:    # broadcast masts: one tall with guy wires, one short behind
        _guyed_mast(c, 70, 44, 1, 1, rings=((78, 3),))
        _guyed_mast(c, 34, 6, 1, 2, rings=((40, 4), (72, 5)))
        for (gy, gx) in ((22, 22), (50, 30)):
            _guy_wire(c, 34, gy, 34 - gx, W3_CLOUD_Y)
            _guy_wire(c, 34, gy, 34 + gx, W3_CLOUD_Y)
        # side lamps part way up, grey (only the tips are lit)
        c.px(31, 40, G)
        c.px(37, 40, G)
        # drum antennas on the short mast
        for (dx, dy) in ((-4, 60), (4, 64)):
            c.ellipse(70 + dx, dy, 1.6, 3, D)
    elif piece == 1:  # a big dish on a lattice gantry, with a catwalk
        for lx in (28, 64):
            _lattice_leg(c, lx, 66, 127, 2, 4, fill=3)
        _truss(c, 24, 62, 68, 67, 8)
        c.rect(22, 59, 50, 1, D)             # catwalk and handrail
        for x in range(22, 72, 3):
            c.px(x, 60, D)
            c.px(x, 61, D)
        # yoke up to the back of the dish
        for (a, b) in ((40, 46), (41, 47), (52, 50), (51, 49)):
            c.line(a, 58, b, 40, D)
        c.rect(44, 48, 8, 1, D)
        c.rect(45, 39, 6, 3, D)
        # the dish tilted up and to the left, concave face dark
        ang = -0.62
        _rot_ellipse(c, 44, 34, 19, 7, ang, D)
        _rot_ellipse(c, 43, 33, 16, 5, ang, K)
        c.dith(20, 14, 50, 40, D, 3, only=K)
        # feed horn on three struts, out along the dish's axis
        fx, fy = 36, 22
        for (sx, sy) in ((32, 38), (54, 26), (43, 34)):
            c.line(sx, sy, fx, fy, D)
        c.rect(fx - 1, fy - 2, 3, 3, D)
        c.px(fx - 1, fy - 2, W)              # the feed's warning lamp, lit
        # a short service mast at the gantry end
        _guyed_mast(c, 70, 38, 1, 1, light=True)
    elif piece == 2:  # drowned rooftops poking up through the cloud bank
        # flat block with a water tank
        c.rect(6, 86, 20, 42, D)
        c.rect(5, 85, 22, 1, D)
        c.rect(10, 74, 9, 8, D)
        c.ellipse(14.5, 74, 4.5, 2, D)
        c.rect(11, 82, 1, 3, D)
        c.rect(17, 82, 1, 3, D)
        # tall stepped tower with a spire and a lit window
        c.rect(34, 72, 18, 56, D)
        c.rect(37, 62, 12, 10, D)
        c.rect(40, 54, 6, 8, D)
        c.rect(42, 40, 2, 14, D)
        c.px(42, 39, D)
        for y in range(76, 100, 5):
            for x in range(36, 50, 4):
                c.rect(x, y, 2, 3, K)
        for x in range(39, 47, 3):
            c.rect(x, 64, 1, 3, K)
        c.px(44, 81, W)                      # someone is still home
        # domed hall
        c.ellipse(66, 92, 10, 8, D)
        c.rect(56, 92, 21, 36, D)
        c.rect(65, 81, 2, 4, D)
        # low block with a leaning aerial
        c.rect(80, 94, 11, 34, D)
        c.line(84, 94, 88, 78, D)
        c.line(86, 86, 90, 84, D)
        for x in (58, 64, 70, 82, 86):
            c.rect(x, 97, 2, 3, K)
        # a wisp of cloud across the tower's middle
        for x in range(26, 62):
            u = (x - 26) / 36
            y = int(round(90 - 2 * math.sin(u * math.pi)))
            for yy in range(y, y + 3):
                if bayer(x, yy) < (10 if yy == y + 1 else 4):
                    c.px(x, yy, D if yy != y else G)
    else:             # a pylon line marching over the clouds, carrying the cable
        for (cx, t) in ((20, 50), (70, 50)):
            _lattice_leg(c, cx, t, 127, 1, 8, fill=2)
            c.line(cx, t - 6, cx - 2, t, D)
            c.line(cx, t - 6, cx + 2, t, D)
            c.rect(cx - 9, t + 2, 14, 1, D)   # cross-arm, long side toward the cable
            c.line(cx - 9, t + 2, cx - 2, t + 6, D)
            c.line(cx + 4, t + 2, cx + 2, t + 5, D)
            c.rect(cx - 9, t + 3, 1, W3_CABLE_Y - t - 3, D)   # insulator string
            c.px(cx - 10, W3_CABLE_Y - 3, D)
            c.px(cx - 8, W3_CABLE_Y - 3, D)
        # a smaller pylon further off, between them
        _lattice_leg(c, 45, 80, 127, 1, 4, fill=1)
        c.rect(41, 83, 9, 1, D)
        posts = [(0, W3_CABLE_Y), (11, W3_CABLE_Y), (61, W3_CABLE_Y), (95, W3_CABLE_Y)]
    _w3_cable(c, posts)
    _w3_clouds(c, piece)
    return c


# ------------------------------------------------------------------ flyer

FLYER_WINGS = {   # left wing, 5x5, feathers on the outer edge; the right wing mirrors it
    'up': ['g.g..', 'gggg.', '.gggd', '..ggd', '...dd'],
    'mid': ['.....', '.gggd', 'ggggd', 'g.g.d', '.....'],
    'down': ['...dd', '..ggd', '.gggd', 'gggg.', 'g.g..'],
}
FLYER_WING_Y = {'up': -3, 'mid': -1, 'down': 1}   # box top, relative to the body top


def flyer(f, mode='fly'):
    """Wave flyer: the walker's white striped NOISE blob and black box eye, with
    two small grey wings. No legs: it only flies."""
    c = C(16, 16)
    wing = {'fly': ('up', 'mid', 'down', 'mid')[f], 'tell': 'mid'}.get(mode, 'down')
    lift = {'up': 1, 'mid': 0, 'down': -1}[wing] if mode == 'fly' else 0
    squash = 1 if mode == 'tell' else 0
    y0 = 5 - lift + squash
    static_body(c, 3, y0, 10, 8 - squash, f, eye_side=-1, eye=(3, 3),
                eye_mode='wide' if mode == 'tell' else 'open', flash=(mode == 'tell' and f % 2 == 1))
    # antenna, like the walker's
    c.px(9, y0 - 1, D)
    c.px(10, y0 - 2, G if mode != 'tell' else W)
    # wings hinge at the body's upper corners
    art = FLYER_WINGS[wing]
    wy = y0 + FLYER_WING_Y[wing]
    c.art(0, wy, art)
    c.art(11, wy, [r[::-1] for r in art])
    # two little tucked feet
    c.rect(5, y0 + 8 - squash, 2, 1, D)
    c.rect(9, y0 + 8 - squash, 2, 1, D)
    c.outline(K)
    return c


def flyer_flat():
    """Stomped: the flat blob, x eye, wings drooped either side."""
    c = C(16, 16)
    static_body(c, 2, 11, 12, 4, 0, eye=(3, 2), eye_mode='x', round_=1)
    c.art(0, 12, ['gg', '.gd', '..d'])
    c.art(13, 12, ['.gg', 'dg.', 'd..'])
    c.rect(1, 15, 14, 1, D)
    c.outline(K)
    return c


# ------------------------------------------------------------------ sweep arm (a fire bar of static)

def sweep_pivot(f):
    """Riveted hub the arm turns on. The spokes turn 45 degrees each frame."""
    c = C(16, 16)
    c.rect(1, 1, 14, 14, D)
    c.dith(2, 2, 12, 12, K, 3)
    c.rect(1, 1, 14, 1, G)
    c.rect(1, 1, 1, 14, G)
    c.rect(1, 14, 14, 1, K)
    c.rect(14, 1, 1, 14, K)
    for (x, y) in ((2, 2), (12, 2), (2, 12), (12, 12)):
        c.px(x, y, G)
        c.px(x + 1, y + 1, K)
    c.ellipse(8, 8, 5, 5, K)
    c.ellipse(8, 8, 4.4, 4.4, G)
    c.ellipse(8, 8, 3.4, 3.4, D)
    if f == 0:
        c.rect(5, 7, 6, 2, G)
        c.rect(7, 5, 2, 6, G)
    else:
        c.line(5, 5, 10, 10, G)
        c.line(10, 5, 5, 10, G)
        c.line(6, 5, 10, 9, G)
        c.line(9, 5, 5, 9, G)
    c.rect(7, 7, 2, 2, K)
    c.px(7, 7, G)
    return c


SWEEP_DOT = [
    ['..wgw...', '.g...gw.', 'w.kdkk.g', 'g.kkdk.w', 'w.dkkk.g', 'g.kkdk..', '.wg...w.', '...gwg..'],
    ['...wgw..', '.wg...g.', 'g.kkdk.w', 'w.dkkk.g', 'g.kkkd.w', '..kdkk.g', '.w...gw.', '..gwg...'],
]


def sweep_dot(f):
    """A crackling static ball: dark core, broken white rim. 8x8 centred in the
    16x16 frame. Never solid white, so it cannot be mistaken for the Spark."""
    c = C(16, 16)
    c.ellipse(8, 8, 3.2, 3.2, K)
    rows = SWEEP_DOT[f]
    # the gap between the core and the rim stays dark too
    c.art(4, 4, [r.replace('.', 'k') if 1 < i < 6 else r for i, r in enumerate(rows)])
    for i, r in enumerate(rows):
        if 1 < i < 6:
            for j in (0, 7):
                if r[j] == '.':
                    c.px(4 + j, 4 + i, T)
    return c


# ------------------------------------------------------------------ wind

def _wind_streak(c, x, y, n, horizontal=True, head_white=True):
    """A thin streak, head first. Horizontal streaks blow left (head on the
    left), vertical ones rise (head on top). Wraps round the 16 px frame so a
    field of frames tiles seamlessly."""
    for i in range(n):
        col = W if (i == 0 and head_white) else (D if i == n - 1 else G)
        if horizontal:
            c.px((x + i) % 16, y % 16, col)
        else:
            c.px(x % 16, (y + i) % 16, col)


# streaks per frame: (x, y, length, white head). Each frame moves them 4 px, so
# four frames make one seamless loop.
WIND_SIDE = [(2, 3, 7, True), (9, 8, 5, False), (5, 13, 6, True)]
WIND_UP = [(3, 2, 6, True), (8, 9, 5, False), (13, 5, 7, True)]


def wind_side(f):
    c = C(16, 16)
    for (x, y, n, w) in WIND_SIDE:
        _wind_streak(c, x - f * 4, y, n, True, w and (f + x) % 2 == 0)
    return c


def wind_up(f):
    c = C(16, 16)
    for (x, y, n, w) in WIND_UP:
        _wind_streak(c, x, y - f * 4, n, False, w and (f + y) % 2 == 0)
    return c


def wind_tell(f):
    """Gust tell: the streaks draw back and bunch up, then crowd together with
    white heads, ready to blow left."""
    c = C(16, 16)
    sets = [
        [(3, 4, 6, False), (8, 8, 5, False), (4, 12, 6, False)],
        [(6, 5, 5, True), (8, 8, 4, False), (6, 11, 5, True)],
        [(4, 6, 4, True), (2, 8, 6, True), (4, 10, 4, True), (9, 7, 3, False), (9, 9, 3, False)],
    ][f]
    for (x, y, n, w) in sets:
        _wind_streak(c, x, y, n, True, w)
    return c


# ------------------------------------------------------------------ wind vane

def wind_vane(f, spinning=True):
    """Windsock on a riveted pole: marks a wind zone. 16x32, feet on the bottom
    row. Blowing, the sock streams left and ripples, and the pole lamp is white.
    Still, the sock hangs limp and the lamp is dark."""
    c = C(16, 32)
    px_ = 12                                   # pole column (2 wide)
    # base plate bolted to the deck
    c.rect(9, 29, 7, 3, D)
    c.rect(9, 29, 7, 1, G)
    c.px(10, 30, K)
    c.px(14, 30, K)
    # pole with rivet bands
    c.rect(px_, 4, 2, 25, D)
    c.rect(px_, 4, 1, 25, G)
    for y in (12, 20):
        c.rect(px_ - 1, y, 4, 1, G)
    # lamp on the top: white while the wind blows
    c.rect(px_, 2, 2, 2, W if spinning else G)
    if spinning:
        # the sock: a hoop at the pole, then banded cloth tapering to the tail.
        # The centre line ripples, more toward the tail, a quarter wave a frame
        for x in range(1, px_):
            u = (px_ - 1 - x) / (px_ - 2)          # 0 at the hoop, 1 at the tail
            mid = 7 + u * 2.2 * math.sin(f * math.pi / 2 + u * 4.0)
            half = 3 - u * 1.6
            band = ((px_ - 1 - x) // 3) % 2 == 0
            col = G if band else D
            for y in range(int(round(mid - half)), int(round(mid + half))):
                c.px(x, y, col)
        c.rect(px_ - 1, 4, 1, 6, G)            # the hoop
        if f % 2:                               # frayed tail flicks
            c.px(0, int(round(7 + 2.2 * math.sin(f * math.pi / 2 + 4.0))), D)
    else:
        # limp: hangs down the pole from the hoop, a slight curl at the tail
        c.rect(px_ - 1, 4, 1, 3, G)
        for y in range(5, 17):
            u = (y - 5) / 11
            w = int(round(3 - u * 1.5))
            col = G if ((y - 5) // 3) % 2 == 0 else D
            c.rect(px_ - 1 - w, y, w, 1, col)
        c.px(px_ - 3, 17, D)
    c.outline(K)
    return c


def build_aerials():
    rows = [
        A('top', [ground_w3(left=True, top=True), ground_w3(top=True), ground_w3(right=True, top=True),
                  ground_w3(left=True, right=True, top=True)], 0,
          note='top-left, top, top-right, one-wide column top'),
        A('mid', [ground_w3(left=True, depth=1), ground_w3(depth=1), ground_w3(right=True, depth=1),
                  ground_w3(left=True, right=True, depth=1)], 0, note='second row down: left, fill, right, column'),
        A('deep', [ground_w3(left=True, depth=2), ground_w3(depth=2), ground_w3(right=True, depth=2),
                   ground_w3(left=True, right=True, depth=2)], 0, note='third row and below'),
        A('bottom', [ground_w3(left=True, bottom=True, depth=2), ground_w3(bottom=True, depth=2),
                     ground_w3(right=True, bottom=True, depth=2),
                     ground_w3(left=True, right=True, top=True, bottom=True)], 0,
          note='underside for ceilings and floating ground. The last one is a single tile'),
        A('alt', [ground_w3(top=True, alt=1), ground_w3(top=True, alt=3), ground_w3(depth=1, alt=2),
                  ground_w3(depth=2, alt=1)], 0, note='drop-in swaps for variety, pick by hash of world tile x,y'),
    ]
    sheet('ground_w3', 16, 16, rows,
          'Aerials ground `#`: a riveted mast-platform deck on top, lattice steel with X cross-bracing below. '
          'Same layout as `ground`. Variants: deck grating, rope tie-off eye, a snapped brace, a junction box.')
    sheet('block_w3', 16, 16, [
        A('lip', [block_w3(True, 0), block_w3(True, 1), block_w3(True, 2), block_w3(True, 3)], 0,
          note='top of a stack: plain, vent, live pip, stencil'),
        A('stacked', [block_w3(False, 0), block_w3(False, 1), block_w3(False, 2), block_w3(False, 3)], 0,
          note='a block with another block above it'),
    ], 'Aerials block `=`: riveted mast-panel crates. Same layout as `block`. Use a live pip rarely.')
    sheet('backdrop_w3', 96, 128, [
        A('pieces', [backdrop_w3(k) for k in range(4)], 0,
          note='0 broadcast masts, 1 dish on a gantry, 2 rooftops in the cloud bank, 3 pylon line'),
    ], 'Aerials far silhouettes, like `backdrop_w2`: far layer, parallax 0.2x, 70% opacity, every bottom on one '
       'horizon line. Lay the pieces edge to edge, one every 96 px, with no gaps: every piece carries the same '
       'cable and the same cloud-bank line at its edges, so they join in any order. Mast tips are drawn lit. '
       'Never put the same piece twice in a row.')
    sheet('flyer', 16, 16, [
        A('fly', [flyer(f) for f in range(4)], 0.1,
          note='faces left, flip for right. Wings up, level, down, level. The body bobs with the beat'),
        A('turn', [flyer(0, 'tell'), flyer(1, 'tell')], 0.06,
          note='2 frames at the end of its patrol before it turns: squash, eye wide, body flickers'),
        A('stomped', [flyer_flat()], 0, note='hold 0.3 s, then fx burst. Drop it to the floor first if it was stomped in the air'),
    ], 'Wave flyer: the walker blob with two small wings. It flies a sine wave on its patrol and can be stomped. '
       'Same frame size and rows as `walker`, with `fly` in place of `walk`.')
    sheet('sweep_arm', 16, 16, [
        A('pivot', [sweep_pivot(0), sweep_pivot(1)], 0.25, note='riveted hub. The arm turns about frame pixel (8, 8)'),
        A('dot', [sweep_dot(0), sweep_dot(1)], 0.08,
          note='one static ball on the arm: 8x8 art centred in the frame. Draw at ball centre - (8, 8), '
               'one every 8 px out from the hub centre'),
    ], 'Sweep arm: a fire bar made of static. A chain of dots turns about the hub. The dots have a dark core and '
       'a crackling white rim, so they never read as the solid-white Spark.')
    sheet('wind', 16, 16, [
        A('side', [wind_side(f) for f in range(4)], 0.07,
          note='streaks blowing left: flip for rightward wind. Each frame moves them 4 px, and frames tile'),
        A('up', [wind_up(f) for f in range(4)], 0.07, note='rising streaks. Each frame moves them 4 px up, and frames tile'),
        A('gust_tell', [wind_tell(f) for f in range(3)], 0.15, loop=False,
          note='the streaks draw back and bunch up. Play for the 0.45 s before a gust, flipped like `side`'),
    ], 'Wind-zone particles. Thin grey streaks with a few white heads, so they read as air, not as static walkers.')
    sheet('wind_vane', 16, 32, [
        A('spin', [wind_vane(f) for f in range(4)], 0.08,
          note='wind blowing: the sock streams left and ripples, lamp lit. Mirror for rightward wind'),
        A('still', [wind_vane(0, spinning=False)], 0, note='no wind: the sock hangs limp, lamp dark'),
    ], 'Wind vane prop: a windsock on a short riveted pole. It marks a wind zone. Anchor top-left at '
       '(cell x, cell y - 16), so the base plate sits on the cell floor. Faces left like every sprite: '
       'the sock points the way the wind blows.')


# =================================================================== Title screen

# The title is a live night scene over the flats (docs/research/
# title-screen-2026-09-26.md, L1 to L8): a hand-made wordmark that the Spark
# lights letter by letter, far and mid parallax strips, telegraph poles for the
# signal wire, and a tiny answering light on the horizon. The sky is left empty
# so the menu text stays readable.

LOGO_W, LOGO_H = 240, 44
LOGO_TOP = 12        # cap top row of the letters inside the frame (letters end on row 39)
LOGO_CAP = 28        # letter height in px (14 rows of 2 px cells)
LOGO_GAP = 2         # px between letters in a word
LOGO_SPACE = 10      # px between WHITE and SIGNAL

# Letters on a 2 px grid, stroke two cells (4 px), 14 cells tall.
LOGO_GLYPHS = {
    'W': ['##........##', '##........##', '##........##', '##........##', '##........##',
          '##...##...##', '##...##...##', '##..####..##', '##..####..##', '##.##..##.##',
          '##.##..##.##', '####....####', '###......###', '##........##'],
    'H': ['##......##'] * 6 + ['##########'] * 2 + ['##......##'] * 6,
    'I': ['######'] * 2 + ['..##..'] * 10 + ['######'] * 2,
    'T': ['##########'] * 2 + ['....##....'] * 12,
    'E': ['#########'] * 2 + ['##.......'] * 4 + ['#######..'] * 2 + ['##.......'] * 4 + ['#########'] * 2,
    'S': ['..########', '.#########', '###.......', '##........', '##........', '###.......',
          '.########.', '.########.', '.......###', '........##', '........##', '.......###',
          '#########.', '########..'],
    'G': ['..########', '.#########', '###.......', '##........', '##........', '##........',
          '##...#####', '##...#####', '##......##', '##......##', '##......##', '###....###',
          '.########.', '..######..'],
    'A': ['..######..', '.########.', '###....###', '##......##', '##......##', '##......##',
          '##########', '##########', '##......##', '##......##', '##......##', '##......##',
          '##......##', '##......##'],
    'L': ['##.......'] * 12 + ['#########'] * 2,
}
LOGO_WORD = 'WHITE SIGNAL'
LOGO_ANTENNA_LETTER = 6    # the I of SIGNAL (letters counted without the space) carries the antenna


def _logo_glyph(ch):
    """Letter as a set of (x, y) pixels, and its width in px."""
    if ch == 'N':   # the diagonal steps one cell every two rows, three cells wide
        rows = []
        for r in range(14):
            s = 1 + round(r * 6 / 13)
            rows.append(''.join('#' if (x < 2 or x > 7 or s <= x <= s + 2) else '.' for x in range(10)))
    else:
        rows = LOGO_GLYPHS[ch]
    px_ = set()
    for j, row in enumerate(rows):
        for i, cell in enumerate(row):
            if cell == '#':
                for dy in (0, 1):
                    for dx in (0, 1):
                        px_.add((i * 2 + dx, j * 2 + dy))
    return px_, len(rows[0]) * 2


def logo_layout():
    """[(char, x0, width)] for every letter, centred in the 240 px frame."""
    items, x = [], 0
    for ch in LOGO_WORD:
        if ch == ' ':
            x += LOGO_SPACE - LOGO_GAP
            continue
        _, w = _logo_glyph(ch)
        items.append([ch, x, w])
        x += w + LOGO_GAP
    total = x - LOGO_GAP
    off = (LOGO_W - total) // 2
    for it in items:
        it[1] += off
    return items


def _logo_mask():
    """Letter pixels in frame coordinates, plus the antenna's mast column."""
    mask = set()
    for ch, x0, _w in logo_layout():
        pts, _ = _logo_glyph(ch)
        for (x, y) in pts:
            mask.add((x0 + x, LOGO_TOP + y))
    return mask


def _logo_antenna_x():
    _ch, x0, w = logo_layout()[LOGO_ANTENNA_LETTER]
    return x0 + w // 2 - 1          # left column of the 2 px mast


def _ring(mask, dist):
    """Pixels exactly `dist` away from the mask (Chebyshev distance)."""
    out = set()
    for (x, y) in mask:
        for dy in range(-dist, dist + 1):
            for dx in range(-dist, dist + 1):
                if max(abs(dx), abs(dy)) == dist:
                    out.add((x + dx, y + dy))
    near = set()
    for d in range(dist):
        for (x, y) in mask:
            for dy in range(-d, d + 1):
                for dx in range(-d, d + 1):
                    near.add((x + dx, y + dy))
    return out - near - mask


def _logo_antenna():
    """Mast, spark and wave pixels of the antenna on the I of SIGNAL. `waves`
    is the inner arc and the outer arc, as two pixel sets."""
    ax = _logo_antenna_x()
    mast = {(ax + dx, y) for dx in (0, 1) for y in range(6, LOGO_TOP)}
    spark = {(ax + dx, y) for dx in (0, 1) for y in (2, 3, 4, 5)} | {(ax + dx, y) for dx in (-1, 2) for y in (3, 4)}
    waves = []
    cx, cy = ax + 1.0, 4.0
    for r in (5.0, 8.5):
        arc = set()
        for y in range(0, 11):
            for x in range(ax - 11, ax + 13):
                dx, dy = x + 0.5 - cx, y + 0.5 - cy
                d = math.hypot(dx, dy)
                if abs(d - r) < 0.5 and abs(dy) <= abs(dx) * 1.1:
                    arc.add((x, y))
        waves.append(arc)
    return ax, mast, spark, waves


def title_logo(state):
    """The wordmark. `unlit`: dead tube lettering, a dark grey rim and a dark
    antenna. `lit`: white letters with broadcast scanlines toward the foot, a
    grey inner shade on the right and bottom, a black outline and a dark drop
    shadow, and a live antenna with its spark. Its two wave arcs pulse in
    `title_logo_antenna`, drawn over this. `glow`: a soft halo only, to draw
    under `lit`. All three share one origin, so the lit one can be revealed
    over the unlit one column by column."""
    c = C(LOGO_W, LOGO_H)
    mask = _logo_mask()
    ax, mast, spark, _waves = _logo_antenna()
    shape = mask | mast | spark
    if state == 'glow':                  # a 2 px Bayer halo just outside the outline
        for (x, y) in _ring(shape, 2):
            if bayer(x, y) < 10:
                c.px(x, y, D)
        for (x, y) in _ring(shape, 3):
            if bayer(x, y) < 3:
                c.px(x, y, D)
        return c
    # black outline round everything, so the logo holds over any backdrop
    for (x, y) in _ring(shape, 1):
        c.px(x, y, K)
    if state == 'unlit':
        for (x, y) in mask:
            edge = any((x + dx, y + dy) not in mask for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
            if edge:
                c.px(x, y, D)
        for (x, y) in mast:
            c.px(x, y, D if x == ax else K)
        for (x, y) in spark:
            c.px(x, y, K)
        c.rect(ax, 3, 2, 2, D)            # the dead bulb
        return c
    # lit: a drop shadow one right and two down, under the outline
    for (x, y) in mask:
        for (dx, dy) in ((1, 2), (2, 2), (1, 3)):
            q = (x + dx, y + dy)
            if q not in mask and c.get(*q)[3] == 0:
                c.px(q[0], q[1], D)
    for (x, y) in mask:
        ly = y - LOGO_TOP
        col = W
        if (ly >= 13 and ly % 4 == 1) or (ly >= 21 and ly % 2 == 1):
            col = G                      # scanlines thicken toward the foot
        if (x + 1, y) not in mask or (x, y + 1) not in mask:
            col = G                      # inner shade, right and bottom
        c.px(x, y, col)
    for (x, y) in mast:
        c.px(x, y, W if x == ax else G)
    for (x, y) in spark:
        c.px(x, y, W)
    c.px(ax + 1, 5, G)
    return c


LOGO_ANTENNA_W, LOGO_ANTENNA_H = 24, 12


def title_logo_antenna(level, inner=None, outer=None):
    """The antenna's spark and wave arcs, cut to a 24x12 frame centred on the
    mast, to draw over the lit logo. `level` is the spark: 0 dim, 1 mid, 2
    bright. `inner` and `outer` are each arc's grey, or None when it is off."""
    ax, _mast, spark, (arc_in, arc_out) = _logo_antenna()
    ox = ax + 1 - LOGO_ANTENNA_W // 2
    c = C(LOGO_ANTENNA_W, LOGO_ANTENNA_H)
    for (x, y) in spark:
        core = x in (ax, ax + 1) and y in (3, 4)
        if level == 2:
            col = G if (x, y) == (ax + 1, 5) else W
        else:
            col = (G, W)[level] if core else (D, G)[level]
        c.px(x - ox, y, col)
    for arc, col in ((arc_in, inner), (arc_out, outer)):
        if col:
            for (x, y) in arc:
                c.px(x - ox, y, col)
    return c


# ------------------------------------------------------------------ title backdrop strips

TITLE_STRIP_W = 320
TITLE_STRIP_H = 64
TITLE_FAR_LAND = 50      # far strip: solid land from this row down
TITLE_CALLER_MAST = (206, 6)   # tip of the caller's mast in the far strip


def _wrapped(draw):
    """Run a draw function three times, 320 px apart, so anything that crosses
    an edge comes back on the other side and the strip tiles seamlessly."""
    def run(c):
        for ox in (-TITLE_STRIP_W, 0, TITLE_STRIP_W):
            draw(c, ox)
    return run


def _dead_mast(c, cx, top, base, hw_base=2, arms=()):
    """A thin dead lattice mast, no light: whip, lattice, crossarms."""
    c.rect(cx, top, 1, 4, D)
    for y in range(top + 4, base):
        hw = 1 if y < top + (base - top) // 2 else hw_base
        c.px(cx - hw, y, D)
        c.px(cx + hw, y, D)
        if (y - top) % 4 == 0:
            c.rect(cx - hw, y, hw * 2 + 1, 1, D)
        elif (y - top) % 4 == 2:
            c.px(cx, y, D)
    for (ay, aw) in arms:
        c.rect(cx - aw, ay, aw * 2 + 1, 1, D)
        c.px(cx - aw, ay + 1, D)
        c.px(cx + aw, ay + 1, D)


def _far_cable(c, x0, y0, x1, y1, sag):
    for x in range(x0, x1 + 1):
        u = (x - x0) / max(1, x1 - x0)
        y = y0 + (y1 - y0) * u + sag * 4 * u * (1 - u)
        if bayer(x, 0) < 10:
            c.px(x, int(round(y)), D)


def title_far():
    """Far strip: a dead city of masts on the horizon. Dark grey on
    transparent, windows black. One mast (the caller's) is the tallest and its
    tip is where the answering light blinks."""
    c = C(TITLE_STRIP_W, TITLE_STRIP_H)
    land = TITLE_FAR_LAND

    def draw(c, ox):
        # low blocks along the horizon: (x, width, height)
        for (x, w, h) in ((4, 14, 6), (22, 9, 10), (34, 20, 4), (70, 12, 8), (86, 6, 13), (96, 16, 5),
                          (128, 22, 7), (154, 8, 11), (176, 18, 5), (222, 14, 9), (240, 10, 5),
                          (262, 20, 8), (286, 7, 12), (298, 18, 4)):
            c.rect(ox + x, land - h, w, h, D)
            for wy in range(land - h + 2, land - 1, 3):     # dead windows
                for wx in range(x + 2, x + w - 2, 4):
                    if hash2(wx, wy) % 3 == 0:
                        c.px(ox + wx, wy, K)
        # water tank on legs, and a dome
        c.rect(ox + 74, land - 14, 6, 4, D)
        c.px(ox + 75, land - 10, D)
        c.px(ox + 78, land - 10, D)
        c.ellipse(ox + 240 + 5, land - 5, 5, 3, D)
        # masts: (x, top, arms)
        _dead_mast(c, ox + 28, 22, land, 2, arms=((28, 3),))
        _dead_mast(c, ox + 112, 30, land, 1)
        _dead_mast(c, ox + TITLE_CALLER_MAST[0], TITLE_CALLER_MAST[1], land, 2, arms=((14, 4), (26, 3)))
        _dead_mast(c, ox + 292, 26, land, 2, arms=((32, 3),))
        # a dish on a short stand
        c.rect(ox + 160, land - 20, 1, 9, D)
        c.line(ox + 156, land - 11, ox + 160, land - 16, D)
        c.line(ox + 164, land - 11, ox + 160, land - 16, D)
        for k in range(6):
            c.px(ox + 155 + k, land - 25 + k, D)
            c.px(ox + 156 + k, land - 25 + k, D)
        c.px(ox + 161, land - 20, D)
        # a snapped mast leaning on its guy wire
        c.line(ox + 250, land - 1, ox + 262, land - 24, D)
        c.line(ox + 251, land - 1, ox + 263, land - 24, D)
        for k in range(2, 22, 4):
            c.px(ox + 250 + k * 12 // 23 + 2, land - 1 - k, D)
        # guy wires off the caller mast and the first mast
        mx, mt = TITLE_CALLER_MAST
        for (gy, gx) in ((10, 20), (22, 30)):
            for s in (-1, 1):
                x1 = mx + s * gx
                n = max(abs(x1 - mx), land - (mt + gy))
                for i in range(n + 1):
                    x = int(round(mx + (x1 - mx) * i / n))
                    y = int(round(mt + gy + (land - mt - gy) * i / n))
                    if bayer(x, y) < 6:
                        c.px(ox + x, y, D)
        # cables slung between masts
        _far_cable(c, ox + 28, 28, ox + 112, 32, 5)
        _far_cable(c, ox + 112, 32, ox + mx, 22, 6)
        _far_cable(c, ox + mx, 22, ox + 292, 32, 5)
        _far_cable(c, ox + 292, 32, ox + 28 + TITLE_STRIP_W, 28, 6)

    _wrapped(draw)(c)
    # the land: a soft dithered top, then solid to the bottom
    for x in range(TITLE_STRIP_W):
        for y in (land - 2, land - 1):
            if c.get(x, y)[3] == 0 and bayer(x, y) < (4 if y == land - 2 else 10):
                c.px(x, y, D)
    c.rect(0, land, TITLE_STRIP_W, TITLE_STRIP_H - land, D)
    for x in range(TITLE_STRIP_W):                 # a faint seam of lighter ground
        if bayer(x, land + 1) < 3:
            c.px(x, land + 1, G)
    return c


def _mid_top(x):
    """Hill line of the mid strip. Whole sine periods across 320 px, so it tiles."""
    u = 2 * math.pi * x / TITLE_STRIP_W
    return 40 - 7 * math.sin(u + 0.6) - 4 * math.sin(3 * u + 1.9) - 1.5 * math.sin(7 * u + 0.4)


def title_mid():
    """Mid strip: low black hills with a dark grey rim, fence lines and a lone
    dead tree. The hills read against the far land behind them."""
    c = C(TITLE_STRIP_W, TITLE_STRIP_H)
    tops = [int(round(_mid_top(x))) for x in range(TITLE_STRIP_W)]
    for x in range(TITLE_STRIP_W):
        t = tops[x]
        c.rect(x, t, 1, TITLE_STRIP_H - t, K)
        c.px(x, t, D)                               # the rim
        if bayer(x, t + 1) < 6:
            c.px(x, t + 1, D)
        if hash2(x, 77) % 23 == 0:                  # grass tufts on the rim
            c.px(x, t - 1, D)
        if hash2(x, 91) % 41 == 0:
            c.px(x, t, G)

    def top(x):
        return tops[x % TITLE_STRIP_W]

    def draw(c, ox):
        # fence runs: posts every 11 px, two slack wires
        for (x0, x1) in ((8, 118), (196, 300)):
            posts = list(range(x0, x1 + 1, 11))
            for px_ in posts:
                t = top(px_)
                c.rect(ox + px_, t - 6, 1, 7, D)
                c.px(ox + px_, t - 6, G if hash2(px_, 5) % 3 == 0 else D)
            for (a, b) in zip(posts, posts[1:]):
                for wire in (4, 2):
                    ya, yb = top(a) - wire, top(b) - wire
                    for x in range(a + 1, b):
                        u = (x - a) / (b - a)
                        y = ya + (yb - ya) * u + 1.2 * 4 * u * (1 - u)
                        if bayer(x, wire) < 11:
                            c.px(ox + x, int(round(y)), D)
            # one post leans where the fence gave up
        # dead tree: black trunk, dark grey edge, bare branches
        tx = 160
        t = top(tx)
        c.rect(ox + tx, t - 16, 2, 17, K)
        c.rect(ox + tx, t - 16, 1, 17, D)
        for (x0, y0, x1, y1) in ((tx, t - 10, tx - 6, t - 18), (tx + 1, t - 13, tx + 7, t - 20),
                                 (tx - 3, t - 14, tx - 5, t - 21), (tx + 4, t - 16, tx + 4, t - 22),
                                 (tx, t - 16, tx + 1, t - 24)):
            c.line(ox + x0, y0, ox + x1, y1, D)
        # a small shed with a dead window
        sx = 140
        st = top(sx + 6)
        c.rect(ox + sx, st - 9, 12, 10, K)
        c.rect(ox + sx - 1, st - 10, 14, 1, D)
        c.px(ox + sx - 1, st - 9, D)
        c.px(ox + sx + 12, st - 9, D)
        c.rect(ox + sx, st - 9, 1, 9, D)
        c.rect(ox + sx + 7, st - 7, 2, 2, D)

    _wrapped(draw)(c)
    return c


# ------------------------------------------------------------------ telegraph pole, caller light

POLE_W, POLE_H = 24, 64
POLE_WIRE = ((3, 4), (20, 4))    # where the wire meets the left and right insulators


def title_pole(kind=0):
    """Telegraph pole, 24x64, foot on the bottom row. A crossarm near the top
    with a glass insulator at each end, climbing pegs, a number plate. Kind 1
    adds a transformer can for variety."""
    c = C(POLE_W, POLE_H)
    cx = 10                                      # pole x (4 wide: 10..13)
    # the post: grey lit edge on the left, black on the right, a few knots
    c.rect(cx, 3, 4, 58, D)
    c.rect(cx, 3, 1, 58, G)
    c.rect(cx + 3, 3, 1, 58, K)
    c.rect(cx, 2, 4, 1, G)                       # cut top
    for (x, y) in ((cx + 1, 21), (cx + 2, 38), (cx + 1, 52)):
        c.px(x, y, K)
    # crossarm with two braces
    c.rect(1, 7, 22, 2, D)
    c.rect(1, 7, 22, 1, G)
    c.rect(1, 9, 22, 1, K)
    c.line(4, 10, cx - 1, 15, D)
    c.line(19, 10, cx + 4, 15, D)
    # glass insulators: a bell on a pin at each end of the crossarm
    for ix in (2, 19):
        c.rect(ix, 4, 3, 3, G)
        c.px(ix + 1, 4, W)                        # the glint where the wire sits
        c.rect(ix, 6, 3, 1, D)
        c.px(ix - 1, 6, D)
        c.px(ix + 3, 6, D)
    # climbing pegs, alternating sides
    for k, y in enumerate(range(22, 50, 6)):
        if k % 2:
            c.rect(cx + 4, y, 2, 1, D)
        else:
            c.rect(cx - 2, y, 2, 1, G)
    # number plate
    c.rect(cx, 30, 4, 3, G)
    c.px(cx + 1, 31, K)
    c.px(cx + 2, 31, D)
    if kind == 1:                                # transformer can on a bracket
        c.rect(cx + 4, 20, 2, 1, D)
        c.rect(cx + 5, 14, 6, 11, D)
        c.rect(cx + 5, 14, 1, 11, G)
        c.rect(cx + 10, 14, 1, 11, K)
        c.rect(cx + 5, 13, 6, 1, G)
        for y in (17, 21):
            c.rect(cx + 6, y, 4, 1, K)
        c.px(cx + 7, 12, G)                      # bushing, with a lead to the crossarm
        c.line(cx + 7, 11, 20, 7, D)
    # the foot: a mound of earth and grass
    c.rect(cx - 3, 61, 10, 3, K)
    c.rect(cx - 2, 60, 8, 1, K)
    c.rect(cx - 3, 61, 10, 1, D)
    for (x, y) in ((cx - 4, 62), (cx - 2, 59), (cx + 5, 59), (cx + 7, 62), (cx + 8, 61)):
        c.px(x, y, D)
    return c


def title_caller(f):
    """The caller: a far light that answers. 7x7 art, centre at frame pixel
    (3, 3). Off is a single dark pixel, so it never quite disappears."""
    c = C(8, 8)
    cx = cy = 3
    if f == 0:
        c.px(cx, cy, D)
    elif f == 1:
        c.px(cx, cy, G)
        for (dx, dy) in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            c.px(cx + dx, cy + dy, D)
    elif f == 2:
        c.px(cx, cy, W)
        for (dx, dy) in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            c.px(cx + dx, cy + dy, G)
        for (dx, dy) in ((2, 0), (-2, 0), (0, 2), (0, -2), (3, 0), (-3, 0)):
            c.px(cx + dx, cy + dy, D)
    else:
        c.px(cx, cy, G)
        for (dx, dy) in ((1, 0), (-1, 0)):
            c.px(cx + dx, cy + dy, D)
    return c


def build_title():
    sheet('title_logo', LOGO_W, LOGO_H, [
        A('unlit', [title_logo('unlit')], 0,
          note='before the Spark passes: dark grey rims, dead antenna'),
        A('lit', [title_logo('lit')], 0,
          note='after it passes. Same origin as unlit: draw it over unlit, clipped from frame x 0 to the Spark. '
               'The antenna\'s wave arcs are in title_logo_antenna'),
        A('glow', [title_logo('glow')], 0,
          note='soft halo only. Draw it under lit, revealed with the same clip'),
    ], 'Title wordmark WHITE SIGNAL on one line, letters 28 px tall on frame rows 12 to 39. All three rows '
       'share one origin: top-left = ((view width - 240) / 2, 26), so the letters sit at screen y 38 to 65. The '
       'antenna on the I of SIGNAL fills rows 0 to 11. Reveal left to right by drawing glow and lit with a '
       'source rect from frame x 0 to (Spark x - frame x). Letters run from frame x 4 to 235.')
    sheet('title_logo_antenna', LOGO_ANTENNA_W, LOGO_ANTENNA_H, [
        A('pulse', [title_logo_antenna(2, G), title_logo_antenna(2, D, G), title_logo_antenna(1, None, D),
                    title_logo_antenna(0), title_logo_antenna(1)], [0.32, 0.32, 0.32, 0.64, 0.07],
          note='the spark flares with the inner arc, the outer arc follows as the inner fades, then a short '
               'dark gap and a rise. 1.67 s, half the caller\'s blink loop: play it from 3.0 s on the title '
               'clock so every other flare lands on the caller\'s blink'),
        A('steady', [title_logo_antenna(2, G, D)], 0,
          note='with reduced flashes: the spark lit and both arcs on, held'),
    ], 'The logo antenna transmitting: its spark and two wave arcs, so the lit logo carries no arcs of its own. '
       'Draw it over the lit logo once the reveal is done, top-left = logo top-left + '
       f'({_logo_antenna_x() + 1 - LOGO_ANTENNA_W // 2}, 0). The spark pixels are opaque, so each frame repaints '
       'the lit spark underneath.')
    sheet('title_scene', TITLE_STRIP_W, TITLE_STRIP_H, [
        A('far', [title_far()], 0,
          note='dead masts on the horizon, land from row 50. Parallax 2 px/s'),
        A('mid', [title_mid()], 0,
          note='black hills with a dark grey rim, fences, a dead tree and a shed. Parallax 5 px/s'),
    ], 'Title night scene strips, 320x64, sky transparent over a black sky. Placement at 480x270 (the same y on '
       'wide screens): far top at y 160, mid top at y 188. Fill from the far strip\'s bottom (y 224) down with '
       'dark grey, draw mid over it, then fill from the mid strip\'s bottom (y 252) down with black. The far land '
       'starts at its row 50 (y 210), so the wire at y 190 runs against open sky. Both strips wrap every 320 px: '
       'draw at x = 320 k - (scroll mod 320). The caller\'s mast tip is far-strip pixel (206, 6).')
    sheet('title_pole', POLE_W, POLE_H, [
        A('pole', [title_pole(0), title_pole(1)], 0,
          note='0 plain, 1 with a transformer can. Use 1 about every fourth pole'),
    ], 'Telegraph pole for the title wire. Top-left = (pole x, wire y - 4): with the wire at y 190 the foot lands '
       'on y 249. The wire is drawn in code as a 1 px mid-grey line: straight across each pole from the left '
       'insulator (frame pixel 3, 4) to the right one (20, 4), then from one pole\'s right insulator to the next '
       'pole\'s left insulator, sagging as y = wire y + 6 * 4u(1 - u) for u from 0 to 1. Space poles 160 px '
       'apart and scroll them with the near layer (10 px/s). The Spark stands on that same curve.')
    sheet('title_caller', 8, 8, [
        A('blink', [title_caller(f) for f in range(4)], [3.0, 0.08, 0.16, 0.1],
          note='off, rising, on, fading. One blink every 3.3 s'),
        A('blink_gray', [title_caller(f).recolor(W, G) for f in range(4)], [3.0, 0.08, 0.16, 0.1],
          note='the same blink with the white centre turned GRAY, for the intro cards where only the Spark '
               'is white (cards 8 and 10)'),
    ], 'The caller, the tiny answering light on the horizon. 7x7 art, centre at frame pixel (3, 3). Draw it on '
       'the caller mast tip: frame top-left = far strip origin + (203, 3).')


# =================================================================== the Arc

# The Arc is the Spark's attack: a short throw of static about 20 px forward.
# These sheets face RIGHT (the requested exception to the face-left rule):
# mirror them when the Spark faces left.

def _jag(pts, seed, amp=1):
    """Break a path into a jagged bolt: every 3 px, kick the point sideways by
    up to `amp` px, picked by a hash so it is the same every run."""
    out = [pts[0]]
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        n = max(1, int(max(abs(x1 - x0), abs(y1 - y0)) // 3))
        dx, dy = x1 - x0, y1 - y0
        ln = max(1e-6, math.hypot(dx, dy))
        nx, ny = -dy / ln, dx / ln
        for i in range(1, n + 1):
            t = i / n
            k = 0 if i == n else (hash2(seed + i, len(out)) % (2 * amp + 1)) - amp
            if k == 0 and i != n:
                k = amp if (i + seed) % 2 else -amp
            out.append((int(round(x0 + dx * t + nx * k)), int(round(y0 + dy * t + ny * k))))
    return out


def _bolt(c, pts, core=W, fringe=G, seed=0):
    """Draw a jagged bolt: a 1 px core with a crackling fringe beside it."""
    lit = set()
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        tmp = C(c.w, c.h)
        tmp.line(x0, y0, x1, y1, core)
        for y in range(c.h):
            for x in range(c.w):
                if tmp.p[x, y][3]:
                    lit.add((x, y))
    for (x, y) in lit:
        c.px(x, y, core)
    if fringe is not None:
        for (x, y) in lit:
            for (dx, dy) in ((0, -1), (0, 1), (1, 0), (-1, 0)):
                q = (x + dx, y + dy)
                if q not in lit and c.get(*q)[3] == 0 and hash2(q[0] * 3 + seed, q[1]) % 3:
                    c.px(q[0], q[1], fringe)
    return lit


def _arc_point(ang, r, cx=0.0, cy=8.0):
    a = math.radians(ang)
    return (cx + r * math.cos(a), cy + r * math.sin(a))


def _trail(c, a0, a1, r0, r1, thr, cx=0.0, cy=8.0):
    """The swept crescent behind the bolt: a dark grey Bayer wash between two
    angles and two radii."""
    for y in range(c.h):
        for x in range(c.w):
            dx, dy = x + 0.5 - cx, y + 0.5 - cy
            r = math.hypot(dx, dy)
            a = math.degrees(math.atan2(dy, dx))
            if r0 <= r <= r1 and a0 <= a <= a1 and c.get(x, y)[3] == 0 and bayer(x, y) < thr:
                c.px(x, y, D)


def _bolt_path(c, pts, core=W, fringe=G, skip=(), thick=False):
    """A zigzag bolt through fixed vertices. The core is 1 px, or 2 px tall
    with `thick`, where the lower row turns grey. A grey spark sits just
    outside every kink so the corners look hot. Segments in `skip` are left
    out, for a bolt that is breaking up."""
    lit = set()
    for i, ((x0, y0), (x1, y1)) in enumerate(zip(pts, pts[1:])):
        if i in skip:
            continue
        t = C(c.w, c.h)
        t.line(x0, y0, x1, y1, W)
        lit |= {(x, y) for y in range(c.h) for x in range(c.w) if t.p[x, y][3]}
    if thick:
        for (x, y) in sorted(lit):
            if (x, y + 1) not in lit:
                c.px(x, y + 1, G)
    for (x, y) in lit:
        c.px(x, y, core)
    if fringe is not None:
        for i, (x, y) in enumerate(pts[1:-1], 1):
            up = y < pts[i - 1][1] and y < pts[i + 1][1]
            q = (x, y - 1) if up else (x, y + (2 if thick else 1))
            if c.get(*q)[3] == 0:
                c.px(q[0], q[1], fringe)
    return lit


def arc_swing(f):
    """24x16, facing right. The Spark's front edge is at frame x 1 and its feet
    on the bottom row. The bolt leaves its hand at about (2, 8) and sweeps from
    up-forward, to straight ahead, to down-forward as it breaks up."""
    c = C(24, 16)
    if f == 0:      # wind-up: a knot of static at the hand, a short bolt kicks up and out
        _bolt_path(c, [(3, 7), (5, 4), (7, 5), (10, 1)])
        c.rect(1, 7, 3, 3, W)
        c.px(0, 8, G)
        c.px(4, 10, G)
        c.outline(K)
    elif f == 1:    # the arc swings up and over, reaching forward
        _bolt_path(c, [(2, 8), (5, 4), (8, 5), (10, 2), (14, 3), (16, 1), (19, 2)], thick=True)
        _bolt_path(c, [(10, 2), (12, 6)], core=G, fringe=None)
        c.rect(1, 7, 2, 3, W)
        c.outline(K)
        _trail(c, -75, -40, 6, 12, 5, 0, 10)
    elif f == 2:    # full reach: a crackling zigzag of static about 20 px ahead
        _bolt_path(c, [(2, 8), (6, 5), (9, 9), (13, 5), (16, 9), (19, 6), (22, 8)], thick=True)
        _bolt_path(c, [(13, 5), (14, 2)], core=G, fringe=None)       # forks
        _bolt_path(c, [(16, 9), (18, 12)], core=G, fringe=None)
        c.rect(1, 7, 2, 3, W)
        for (dx, dy) in ((0, -1), (0, 1), (1, 0)):                    # crackle at the tip
            c.px(22 + dx, 8 + dy, W)
        c.outline(K)
        _trail(c, -45, -12, 9, 19, 6, 0, 10)
    else:           # it breaks up: grey segments sag forward and down, a few white flecks
        _bolt_path(c, [(3, 9), (7, 11), (10, 9), (14, 12), (17, 10), (21, 13)], core=G, fringe=D, skip=(1, 3))
        for (x, y) in ((9, 8), (18, 9), (22, 14), (6, 13)):
            c.px(x, y, W)
        _trail(c, 5, 30, 10, 19, 3, 0, 10)
    return c


def arc_hit(f):
    """16x16 spark burst where the Arc connects, centred on frame pixel (8, 8).
    Jagged rays, so it reads as static, not as the round stomp burst."""
    c = C(16, 16)
    cx, cy = 8, 8
    rays = [(0, 7), (90, 7), (180, 7), (270, 7), (45, 5), (135, 5), (225, 5), (315, 5)]
    if f == 0:
        for i, (a, r) in enumerate(rays):
            ex, ey = _arc_point(a, r, cx, cy)
            pts = _jag([(cx, cy), (int(round(ex)), int(round(ey)))], 60 + i, 1 if r > 5 else 0)
            _bolt(c, pts, core=W if r > 5 else G, fringe=G if r > 5 else None, seed=i)
        c.rect(cx - 1, cy - 1, 3, 3, W)
    elif f == 1:
        for i, (a, r) in enumerate(rays):
            sx, sy = _arc_point(a, 3, cx, cy)
            ex, ey = _arc_point(a + 8, r + 1, cx, cy)
            pts = _jag([(int(round(sx)), int(round(sy))), (int(round(ex)), int(round(ey)))], 80 + i, 1)
            _bolt(c, pts, core=G, fringe=D if r > 5 else None, seed=i)
            if r > 5:
                c.px(int(round(ex)), int(round(ey)), W)
        c.px(cx, cy, G)
    else:
        for i, (a, r) in enumerate(rays):
            ex, ey = _arc_point(a + 15, r + (1 if r > 5 else 2), cx, cy)
            x, y = int(round(ex)), int(round(ey))
            c.px(x, y, G if r > 5 else D)
            if r > 5:
                c.px(x + (1 if x > cx else -1), y, D)
    return c


# ------------------------------------------------------------------ cracked walls

# One crack pattern for every world, drawn over that world's deep tile. Black
# fissures split the tile into chunks, and every chunk gets a grey bevel on the
# edges that face a fissure from below or the right, so the pieces stand out on
# the dark deep tiles of all three worlds. Two chips are knocked out, and one
# faint white glint sits where the fissures meet.
CRACK_PATHS = [
    [(7, 0), (6, 3), (8, 6), (7, 10), (9, 13), (8, 15)],     # main fissure, top to foot
    [(8, 6), (4, 7), (2, 9), (0, 9)],                        # branch left
    [(7, 10), (11, 10), (13, 12), (15, 12)],                 # branch right, low
    [(6, 3), (10, 2), (12, 4), (15, 4)],                     # branch right, high
]
CRACK_CHIPS = [(2, 12, 2, 2), (12, 7, 2, 1)]
CRACK_GLINT = (8, 6)


def _crack_mask():
    m = set()
    for path in CRACK_PATHS:
        for (x0, y0), (x1, y1) in zip(path, path[1:]):
            t = C(16, 16)
            t.line(x0, y0, x1, y1, K)
            m |= {(x, y) for y in range(16) for x in range(16) if t.p[x, y][3]}
    for (x, y, w, h) in CRACK_CHIPS:
        m |= {(x + i, y + j) for i in range(w) for j in range(h)}
    return m


def _crack_overlay(c):
    m = _crack_mask()
    for (x, y) in m:
        c.px(x, y, K)
    for y in range(16):
        for x in range(16):
            if (x, y) in m:
                continue
            if (x - 1, y) in m or (x, y - 1) in m:
                c.px(x, y, G)                 # lit bevel: the chunk edge below or right of a fissure
            elif (x + 1, y) in m or (x, y + 1) in m:
                if c.get(x, y) != K:
                    c.px(x, y, D)             # shadowed edge on the other side
    c.px(CRACK_GLINT[0], CRACK_GLINT[1], W)
    return c


def crack_tile(style, left=False, right=False):
    """A cracked wall that sits flush inside a wall of `style`: the deep tile of
    that ground with the crack drawn over it. Edge columns come from the ground
    tile, so the lit left edge and the dark right edge still line up."""
    make = {'w1': ground, 'w2': ground_w2, 'w3': ground_w3, 'w4': ground_w4}[style]
    base = make(left=left, right=right, depth=2)
    c = base.copy()
    c = _crack_overlay(c)
    for y in range(16):
        if left:
            c.px(0, y, base.get(0, y))
        if right:
            c.px(15, y, base.get(15, y))
            c.px(14, y, base.get(14, y))
    return c


def crack_break(f):
    """Generic break, the same for all three worlds (the world tint does the
    rest). 0 the cracks flare white, 1 the tile splits into chunks, 2 the
    chunks burst out and drop, 3 dust settles."""
    c = C(16, 16)
    chunks = [(0, 0, 7, 7), (8, 0, 8, 6), (0, 8, 6, 8), (7, 7, 9, 9)]
    if f == 0:
        c.rect(0, 0, 16, 16, D)
        c.dith(0, 0, 16, 16, K, 6)
        for (x, y) in _crack_mask():
            c.px(x, y, W)
        c.rect(7, 5, 3, 3, W)
    elif f == 1:
        pushes = [(-1, -1), (1, -1), (-1, 1), (1, 1)]
        for (x, y, w, h), (dx, dy) in zip(chunks, pushes):
            c.rect(x + dx, y + dy, w - 1, h - 1, D)
            c.rect(x + dx, y + dy, w - 1, 1, G)
            c.rect(x + dx + w - 2, y + dy + 1, 1, h - 2, K)
            c.px(x + dx + 1, y + dy + h - 2, K)
    elif f == 2:
        for (x, y, s) in ((0, 1, 4), (11, 0, 4), (1, 10, 4), (11, 10, 5), (6, 5, 3), (7, 12, 2)):
            c.rect(x, y, s, s - 1, D)
            c.rect(x, y, s, 1, G)
            c.px(x + s - 1, y + s - 2, K)
        c.dith(3, 12, 10, 4, D, 5)
    else:
        for (x, y) in ((2, 14), (12, 13), (7, 15), (4, 12), (10, 15)):
            c.rect(x, y, 2, 1, D)
            c.px(x, y - 1, G if (x + y) % 3 == 0 else D)
        c.dith(1, 10, 14, 6, D, 2)
    return c


# ------------------------------------------------------------------ Arc icons

ARC_GLYPH = [   # 10x10, faces right: a knot of static at the Spark's hand, thrown out as a zigzag
    '..........',
    '..........',
    '.....w....',
    '....www..w',
    '.ww.w.ww.w',
    'wwwww..www',
    'wwgw....w.',
    '.gg.......',
    '..........',
    '..........',
]


def arc_hud(ready=True):
    """10x10 at the frame's top-left, with a black outline where it fits. Not
    ready, it goes dark grey but keeps its shape."""
    c = C(16, 16)
    g = C(10, 10)
    g.art(0, 0, ARC_GLYPH)
    if not ready:
        g.recolor(W, D)
        g.recolor(G, D)
    g.outline(K)
    c.paste(g, 0, 0)
    return c


def arc_pickup(f):
    """16x16 Arc pickup: the HUD glyph in a dark cell with a grey rim. A spark
    runs round the rim a quarter turn a frame, and the zigzag's tip flickers.
    Bob it in code."""
    c = C(16, 16)
    c.ellipse(8, 8, 7.6, 7.6, K)
    c.ellipse(8, 8, 7.0, 7.0, G)
    c.ellipse(8, 8, 6.1, 6.1, K)
    for y in range(16):                        # a dark grey wash inside the rim
        for x in range(16):
            if c.get(x, y) == K and math.hypot(x + 0.5 - 8, y + 0.5 - 8) < 5.6 and bayer(x, y) < 3:
                c.px(x, y, D)
    rows = [r for r in ARC_GLYPH[2:8]]
    if f % 2:
        rows = [r[:9] + '.' for r in rows]     # the tip flickers
        rows[1] = rows[1][:8] + 'g.'
    c.art(3, 5, rows)
    a = math.radians(-120 + f * 90)
    sx, sy = int(math.floor(8 + 6.6 * math.cos(a))), int(math.floor(8 + 6.6 * math.sin(a)))
    c.px(sx, sy, W)
    return c


def build_arc():
    sheet('arc', 24, 16, [
        A('swing', [arc_swing(f) for f in range(4)], [0.02, 0.04, 0.06, 0.08], loop=False,
          note='wind-up, sweep, full reach, break-up. Frames 1 and 2 cover 0.02 to 0.12 s, the hit window. '
               'Keep drawing to 0.2 s so the break-up shows'),
    ], 'The Arc, the Spark\'s attack: a short throw of static about 20 px forward. Faces RIGHT (the exception '
       'to the face-left rule): mirror it when the Spark faces left. Frame x 1 is the Spark\'s front column and '
       'row 15 its bottom row, so the knot at the hand overlaps the body by 1 px. With the standard 12 px body '
       '(J.spark, body x from floor(feet x - 6)): facing right, top-left = (feet x + 4, feet y - 16). Facing left, '
       'draw it mirrored at (feet x - 28, feet y - 16). A fair hitbox is frame x 2 to 23, y 1 to 13, live on '
       'frames 1 and 2.')
    sheet('arc_hit', 16, 16, [
        A('hit', [arc_hit(f) for f in range(3)], [0.03, 0.05, 0.07], loop=False,
          note='where the Arc connects. Centre on the contact point'),
    ], 'Arc hit burst. Centre on the contact point: top-left = contact - (8, 8). Jagged rays, so it reads as '
       'static, not as the round stomp burst.')
    sheet('crack', 16, 16, [
        A('w1', [crack_tile('w1', left=True), crack_tile('w1'), crack_tile('w1', right=True),
                 crack_tile('w1', left=True, right=True)], 0,
          note='World 1 ground: left, fill, right, column (the same columns as ground)'),
        A('w2', [crack_tile('w2', left=True), crack_tile('w2'), crack_tile('w2', right=True),
                 crack_tile('w2', left=True, right=True)], 0,
          note='World 2 ground_w2: left, fill, right, column'),
        A('w3', [crack_tile('w3', left=True), crack_tile('w3'), crack_tile('w3', right=True),
                 crack_tile('w3', left=True, right=True)], 0,
          note='World 3 ground_w3: left, fill, right, column'),
        A('break', [crack_break(f) for f in range(4)], [0.04, 0.06, 0.08, 0.1], loop=False,
          note='the Arc breaks it: flare, split, burst, dust. Same for every world. Spawn 4 brick_debris '
               'chunks on frame 1 if you want pieces flying clear of the tile'),
        A('w4', [crack_tile('w4', left=True), crack_tile('w4'), crack_tile('w4', right=True),
                 crack_tile('w4', left=True, right=True)], 0,
          note='World 4 ground_w4: left, fill, right, column. After break, so the older rows keep their places'),
    ], 'Cracked wall the Arc breaks. Each is the deep tile of that world\'s ground with a crack over it, so it '
       'sits flush in a wall. Pick the row by world and the column by open sides, like ground. There is no '
       'top-lip version: keep a normal ground tile on top of a cracked stack.')
    sheet('arc_icon', 16, 16, [
        A('hud', [arc_hud(True), arc_hud(False)], 0,
          note='0 ready, 1 not ready. 10x10 art at the frame top-left: draw the frame at (x, 3) in the 16 px HUD bar'),
        A('pickup', [arc_pickup(f) for f in range(4)], 0.1,
          note='pickup for the tutorial: the glyph in a ringed cell. A spark runs round the rim and the tip '
               'flickers. Bob +-1 px in code'),
    ], 'Arc HUD icon and pickup. The glyph faces right like the Arc: a knot of static and the zigzag it throws. '
       'It lies flat, so it never reads as the upright CHARGE bolt.')


# =================================================================== the story intro

# The new-game intro (docs/story/intro-shots.md, section 3, N1 to N8). From
# card 5 on the Spark is the only pure white thing on screen, so everything
# here that shows in those cards tops out at GRAY: the lantern, the rings, the
# lit wire, the keeper's window, the far gate's lamp, and Old Mast's eyes and
# antenna lamp. Only the listener and the crew (cards 2 to 4), the static
# (cards 3 and 4) and the close-up Spark keep white.

def _dot_eyes(c, x, y, gap=2, col=W, shut=False):
    """Two dot eyes on a black visor band, like _eyes, in any colour."""
    c.rect(x - 1, y, gap + 3, 1, K)
    if not shut:
        c.px(x, y, col)
        c.px(x + gap, y, col)


# ------------------------------------------------------------------ N1 intro_npc

def _lantern(c, x, y):
    """Hand lantern, 3x5, top-left (x, y): a DARK bail, cap and base round
    GRAY glass. Its centre (where the code hangs the light) is (x + 1, y + 2)."""
    c.px(x + 1, y, D)                      # bail
    c.rect(x, y + 1, 3, 1, D)              # cap
    c.rect(x, y + 2, 3, 2, G)              # glass
    c.rect(x, y + 4, 3, 1, D)              # base
    return (x + 1, y + 2)


def _mast_cloak(c, top=11, hem=22, hump=(10, 12), lean=0):
    """Old Mast's cloak from npc_mast: narrow at the shoulders, wide at the
    hem, a hump on the back, a fold down the front. `lean` pushes the upper
    cloak forward (left) for the bent-over pose."""
    n = hem - top
    for y in range(top, hem + 1):
        k = y - top
        shift = lean * (n - k) // max(1, n)
        left = 5 - k * 2 // 11 - shift
        right = 11 + k * 2 // 11 - shift // 2
        c.rect(left, y, right - left + 1, 1, G)
    c.ellipse(hump[0], hump[1], 3, 2.5, G)
    c.dith(8, top, 6, n + 1, D, 8, only=G)
    c.rect(7 - lean // 2, top + 2, 1, n - 2, D)       # fold down the front
    c.rect(4, hem, 8, 1, D)


def _mast_head(c, hy, hx=0, sway=0, eyes='open', antenna=True):
    """Old Mast's hood, face and antenna from npc_mast, shifted by hx. Eyes
    and the antenna lamp are GRAY here, not white."""
    if antenna:
        for (x, y) in ((8, hy - 2), (8, hy - 3), (9, hy - 4), (9, hy - 5), (10 + sway, hy - 6)):
            c.px(x + hx, y, D)
        c.px(10 + sway + hx, hy - 7, G)
    c.ellipse(7.5 + hx, hy + 1.5, 3.2, 2.8, D)
    c.ellipse(6 + hx, hy + 2, 2.6, 2.2, G)
    ey = hy + (3 if eyes == 'down' else 2)  # looking down: the band drops a row
    for x in range(3 + hx, 8 + hx):         # a shadowed brow, so GRAY eyes still stand off the GRAY face
        if c.get(x, ey - 1) == G:
            c.px(x, ey - 1, D)
    _dot_eyes(c, 4 + hx, ey, 2, G, shut=(eyes == 'shut'))
    c.px(5 + hx, hy + 4, G)                # whiskers
    c.px(4 + hx, hy + 4, G)


def _mast_cane_back(c, tip_x=14, top=15):
    """The cane in Mast's back hand: a short crook over the hand, the shaft
    planted beside the back of the cloak."""
    c.px(13, top, G)                       # hand and crook
    c.px(14, top - 1, G)
    c.px(13, top - 1, G)
    c.line(14, top, tip_x, 23, G)


def intro_mast(mode, f):
    """Old Mast carrying a lantern: npc_mast's body, hood and antenna, the
    lantern held forward in his front hand and the cane in his back hand.
    Returns the canvas and the lantern centre in frame pixels."""
    c = C(16, 24)
    if mode == 'look':
        # bent over the Spark: the hood drops forward and down, the lantern
        # hangs low near the ground
        bob = (0, 1)[f]
        _mast_cloak(c, top=12, hem=22, hump=(10, 12 + bob), lean=2)
        c.rect(5, 23, 2, 1, D)
        c.rect(9, 23, 2, 1, D)
        _mast_cane_back(c, 14, 16)
        for (x, y) in ((7, 9 + bob), (8, 8 + bob), (8, 7 + bob), (9, 6), (10 + bob, 5)):   # antenna curling back
            c.px(x, y, D)
        c.px(10 + bob, 4, G)
        _mast_head(c, 11 + bob, hx=-2, eyes='down', antenna=False)
        c.rect(3, 16, 2, 1, G)                 # the front arm reaching down to the lantern
        c.px(2, 17, G)
        centre = _lantern(c, 0, 18)
        c.outline(K)
        return c, centre
    if mode == 'walk':
        nod = (0, 1, 0, 1)[f]
        feet = ((4, 10), (6, 8), (5, 10), (6, 9))[f]
        tip = (15, 14, 13, 14)[f]              # the cane tip plants behind, then swings through
        _mast_cloak(c)
        c.rect(feet[0], 23, 2, 1, D)
        c.rect(feet[1], 23, 2, 1, D)
        _mast_cane_back(c, tip)
        _mast_head(c, 8 + nod, sway=(0, 1, 1, 0)[f])
    else:
        # stand: the lantern held out at chest height, bobbing 1 px on its bail
        _mast_cloak(c)
        c.rect(5, 23, 2, 1, D)
        c.rect(9, 23, 2, 1, D)
        _mast_cane_back(c)
        _mast_head(c, 8, sway=f)
    c.rect(3, 13, 2, 1, G)                     # the front arm held out, the lantern hanging from the hand
    c.px(2, 13, G)
    centre = _lantern(c, 0, 14 + (f if mode == 'stand' else 0))
    c.outline(K)
    return c, centre


LISTENER_BODY = [   # 16 wide, rows 15 to 23: sitting, knees drawn up in front, an arm round them
    '....gg..gggd....',
    '...gggggggggd...',
    '...ggdgggggggd..',
    '...gg.dggggggd..',
    '...gg..gggggdd..',
    '...gg..ggggggd..',
    '...gg.gggggggd..',
    '..ggg.gggggggd..',
    '..gggg.ggggggd..',
]


def intro_listener(f):
    """A generic listener sitting on the ground, knees up, small headphones:
    grey, shaded dark on the back half so it reads against dark ground,
    white dot eyes. Faces left. Frame 1 tilts the
    head up at a passing pulse."""
    c = C(16, 24)
    c.art(0, 15, LISTENER_BODY)
    c.dith(8, 15, 7, 9, D, 7, only=G)          # the back half in shadow, like Old Mast's cloak
    c.rect(3, 18, 2, 1, D)                     # the fold behind the knee
    c.px(6, 16, D)                             # the arm's cuff
    up = f == 1
    hx, hy = (9, 11) if not up else (10, 10)    # head centre; tilted up it rides higher and back
    c.ellipse(hx, hy + 0.5, 3.4, 3.1, G)
    c.dith(hx + 1, hy - 3, 4, 8, D, 5, only=G)
    c.rect(hx - 1, hy + 3, 3, 1, G)             # neck
    if up:
        _dot_eyes(c, hx - 2, hy - 1, 2)
    else:
        _dot_eyes(c, hx - 3, hy + 1, 2)
    # small headphones: a band arched over the crown and a small cup at each side
    for x in range(hx - 2, hx + 3):
        c.px(x, hy - 4, G)
    c.px(hx - 3, hy - 3, G)
    c.px(hx + 3, hy - 3, G)
    for x in (hx - 4, hx + 3):
        c.rect(x, hy - 1, 1, 3, D)
    c.outline(K)
    c.px(hx - 4, hy, G)                         # the cup's grille catches the light
    return c


INTRO_MAST_ROWS = (('walk', 4), ('stand', 2), ('look', 2))


def intro_lantern_note(mode):
    cs = [intro_mast(mode, f)[1] for f in range(dict(INTRO_MAST_ROWS)[mode])]
    if len(set(cs)) == 1:
        return f'lantern centre ({cs[0][0]}, {cs[0][1]}) on every frame'
    return 'lantern centre ' + ', '.join(f'({x}, {y})' for (x, y) in cs) + ' on frames ' + \
        ', '.join(str(i) for i in range(len(cs)))


# ------------------------------------------------------------------ N2 intro_poles

IP_W, IP_H = 48, 64
IP_POLE_X = 12                  # title_pole art sits 12 px in, so its (3, 4) insulator lands on (15, 4)
IP_CONTACTS = ((15, 4), (32, 4))
IP_ROD_X = 20                   # the operating rod, just left of the pole
IP_PIVOT = (20, 52)             # where the handle lever turns on the rod
IP_CREW_AT = (1, 40)            # the crew's 16x24 box inside the frame, feet on row 63


def _switch_head(c, state):
    """The isolation switch at the pole top. The jaw sits on the left
    insulator, the hinge on the right one. closed: the blade lies across the
    contacts. lift: the free end has left the jaw. open: the blade stands
    raised from the hinge and the jaw is scorched."""
    jx, jy = IP_CONTACTS[0]
    hx, hy = IP_CONTACTS[1]
    # jaw: two small prongs on the left insulator
    c.px(jx - 1, jy - 2, G)
    c.px(jx + 1, jy - 2, G)
    c.px(jx - 1, jy - 1, D)
    c.px(jx + 1, jy - 1, D)
    # hinge block on the right insulator
    c.rect(hx - 1, jy - 3, 3, 3, D)
    c.px(hx, jy - 2, K)
    c.px(hx - 1, jy - 3, G)
    if state == 'closed':
        c.rect(jx, jy - 1, hx - jx, 1, W)
        c.rect(jx + 1, jy - 2, hx - jx - 2, 1, G)
    elif state == 'lift':                      # the free end has just left the jaw
        c.line(hx - 1, jy - 2, jx + 2, jy - 4, W)
        c.line(hx - 1, jy - 1, jx + 2, jy - 3, G)
    else:                                      # thrown open: the blade stands up steeply off the hinge
        c.line(hx - 1, jy - 2, hx - 6, jy - 4, W)
        c.line(hx - 1, jy - 1, hx - 7, jy - 4, G)
        c.line(hx, jy - 2, hx - 5, jy - 4, W)
    if state == 'open':
        for (x, y) in ((jx - 2, jy - 1), (jx, jy - 2), (jx + 2, jy - 3), (jx - 1, jy - 3), (jx + 2, jy - 1)):
            c.px(x, y, D)                      # scorch round the jaw
        c.px(jx - 1, jy - 2, D)
        c.px(jx + 1, jy - 2, D)


def _rod_and_handle(c, lever):
    """Operating rod down the pole to the notched isolation handle. `lever`
    is 0 (up, level, ready), 1 (halfway down) or 2 (pulled right down)."""
    rx = IP_ROD_X
    c.rect(rx - 1, 10, 3, 3, D)                # gearbox under the crossarm
    c.rect(rx - 1, 10, 3, 1, G)
    c.rect(rx, 13, 1, 46, G)                   # the rod
    for y in (24, 40, 57):                     # stand-off brackets to the pole
        c.px(rx + 1, y, D)
    c.rect(rx - 1, 58, 3, 2, D)                # foot bracket
    px_, py = IP_PIVOT
    c.rect(px_ - 1, py - 1, 3, 3, D)           # pivot boss
    c.px(px_, py, K)
    # lever with a T grip at the end and the notch tooth underneath
    if lever == 0:
        c.rect(px_ - 5, py, 5, 1, G)
        c.rect(px_ - 6, py - 1, 1, 3, G)
        c.px(px_ - 3, py + 1, G)
        c.px(px_ - 3, py, K)                   # the notch
        return (px_ - 6, py)
    if lever == 1:
        c.line(px_ - 1, py + 1, px_ - 4, py + 3, G)
        c.line(px_ - 6, py + 2, px_ - 4, py + 5, G)
        c.px(px_ - 3, py + 3, K)
        return (px_ - 5, py + 4)
    c.line(px_, py + 1, px_ - 2, py + 5, G)
    c.rect(px_ - 4, py + 5, 3, 1, G)
    c.px(px_ - 1, py + 3, K)
    return (px_ - 3, py + 5)


def _crew(pose, f, hand):
    """The crew listener, 16x24, facing RIGHT toward the pole: a work coat
    with a light stripe, a hard hat, white dot eyes. `hand` is the handle grip
    in this box's coordinates, or None when the hands are off it."""
    c = C(16, 24)
    drop = {'ready': (0, 1)[f], 'grip': 1, 'lean': 1, 'heave': 2, 'down': 3, 'hold': 3,
            'after': (1, 2)[f]}[pose]
    back = {'lean': 2, 'heave': 1}.get(pose, 0)
    bow = pose == 'after'
    body_top = 12 + drop
    # legs, bent more the lower the crouch
    leg_h = 3 if drop < 2 else 2
    c.rect(4 - back, 24 - leg_h, 2, leg_h, D)
    c.rect(8, 24 - leg_h, 2, leg_h, D)
    if drop >= 2:
        c.rect(3 - back, 23, 2, 1, D)          # the back foot braced
    # work coat to the knees, a light stripe across, a belt
    c.rect(3 - back, body_top, 8, 22 - leg_h - body_top + 1, D)
    c.ellipse(7 - back, body_top + 0.5, 3.8, 1.8, D)
    c.rect(3 - back, body_top + 3, 8, 1, G)
    c.rect(3 - back, body_top + 6, 8, 1, K)
    # hard hat and the face in its shadow
    hy = 7 + drop + (1 if bow else 0)
    hx = 7 - back + (1 if bow else 0)
    c.ellipse(hx + 0.5, hy, 3.6, 2.6, G)
    c.rect(hx, hy - 2, 1, 3, D)                # ridge
    c.rect(hx - 3, hy + 1, 9, 1, G)            # brim, longer at the front (right)
    c.rect(hx - 2, hy + 2, 6, 3, D)
    c.rect(hx - 2, hy + 4, 6, 1, G)            # chin strap
    if bow:
        _dot_eyes(c, hx, hy + 3, 2, shut=True)
    else:
        _dot_eyes(c, hx, hy + 3, 2)
    c.px(hx + 1, hy - 1, W)                    # hat shine
    # arms
    sx, sy = 9 - back, body_top + 1
    if hand is None:
        c.rect(sx, sy, 1, 5, G)                # hanging at the side
    else:
        c.line(sx, sy, hand[0] - 1, hand[1], G)
        if pose != 'ready':                    # both hands on it
            c.line(sx - 1, sy + 2, hand[0] - 1, hand[1] + 1, G)
        c.px(hand[0], hand[1], G)
    c.outline(K)
    return c


def intro_switch(pose, f=0):
    """48x64: the telegraph pole with an isolation switch at the top, the
    operating rod and handle, and the crew listener on the left."""
    c = C(IP_W, IP_H)
    c.paste(title_pole(0), IP_POLE_X, 0)
    head = {'ready': 'closed', 'grip': 'closed', 'lean': 'closed', 'heave': 'lift',
            'down': 'open', 'hold': 'open', 'after': 'open'}[pose]
    lever = {'ready': 0, 'grip': 0, 'lean': 0, 'heave': 1, 'down': 2, 'hold': 2, 'after': 2}[pose]
    _switch_head(c, head)
    grip = _rod_and_handle(c, lever)
    ox, oy = IP_CREW_AT
    hand = None if pose == 'after' else (grip[0] - ox, grip[1] - oy)
    c.paste(_crew(pose, f, hand), ox, oy)
    return c


LEAN = math.tan(math.radians(12))


def _lean_x(y, d):
    """Horizontal offset of the leaning post at row y (the foot, row 60, stays put)."""
    return d * int(round((60 - y) * LEAN))


def dead_pole(kind):
    """48x64, no crew, no wire, no white. 0 leans left about 12 degrees, 1
    leans right, 2 is a snapped stump about 24 px tall. Returns the canvas and
    the two insulator wire seats (None for the stump)."""
    c = C(IP_W, IP_H)
    cx = IP_POLE_X + 10                        # post columns cx..cx+3 at the foot
    if kind == 2:
        top = 40
        c.rect(cx, top, 4, 61 - top, D)
        c.rect(cx, top, 1, 61 - top, G)
        c.rect(cx + 3, top, 1, 61 - top, K)
        # snapped top: splinters of different heights
        for (dx, h, col) in ((0, 3, G), (1, 5, D), (2, 2, D), (3, 4, K)):
            c.rect(cx + dx, top - h, 1, h, col)
        c.px(cx + 1, top - 6, D)
        c.px(cx + 2, top - 3, K)
        c.px(cx + 1, 52, K)
        c.rect(cx - 2, 46, 2, 1, G)            # a climbing peg
        c.rect(cx + 4, 52, 2, 1, D)
        # the broken-off top lies in the grass beside it
        c.rect(cx + 7, 60, 9, 2, D)
        c.rect(cx + 7, 60, 9, 1, G)
        c.rect(cx + 15, 59, 1, 3, D)
        c.px(cx + 6, 61, D)
        seats = None
    else:
        d = -1 if kind == 0 else 1
        for y in range(3, 61):                 # the post, lit on its left edge
            x = cx + _lean_x(y, d)
            c.rect(x, y, 4, 1, D)
            c.px(x, y, G)
            c.px(x + 3, y, K)
        c.rect(cx + _lean_x(2, d), 2, 4, 1, G)
        for y in (21, 38, 52):                 # knots
            c.px(cx + _lean_x(y, d) + 1 + (y == 38), y, K)
        for k, y in enumerate(range(22, 50, 6)):
            x = cx + _lean_x(y, d)
            if k % 2:
                c.rect(x + 4, y, 2, 1, D)
            else:
                c.rect(x - 2, y, 2, 1, G)
        x = cx + _lean_x(31, d)                # number plate
        c.rect(x, 30, 4, 3, G)
        c.px(x + 1, 31, K)
        c.px(x + 2, 31, D)
        # the crossarm, tilted with the post: grey top, dark face, black underside
        pcx = cx + 1.5 + d * (60 - 8) * LEAN
        slope = d * LEAN                        # rows per column along the arm
        for i in range(-10, 12):
            x = int(math.floor(pcx + i + 0.5)) - 1
            y = int(round(8 + (i - 0.5) * slope))
            c.px(x, y - 1, G)
            c.px(x, y, D)
            c.px(x, y + 1, K)
        # braces from under the arm to the post
        for s in (-1, 1):
            ax = int(round(pcx + s * 8))
            ay = int(round(8 + s * 8 * slope)) + 2
            bx = cx + _lean_x(15, d) + (-1 if s < 0 else 4)
            c.line(ax, ay, bx, 15, D)
        # insulators on the arm ends: the seat is the top-centre pixel
        seats = []
        for s in (-8.5, 8.5):
            ix = int(round(pcx + s))
            iy = int(round(8 + s * slope)) - 4
            c.rect(ix - 1, iy, 3, 2, G)
            c.rect(ix - 1, iy + 2, 3, 1, D)
            c.px(ix - 2, iy + 2, D)
            c.px(ix + 2, iy + 2, D)
            seats.append((ix, iy))
    # the foot: a mound of earth and grass, as title_pole
    c.rect(cx - 3, 61, 10, 3, K)
    c.rect(cx - 2, 60, 8, 1, K)
    c.rect(cx - 3, 61, 10, 1, D)
    for (x, y) in ((cx - 4, 62), (cx - 2, 59), (cx + 5, 59), (cx + 7, 62), (cx + 8, 61)):
        c.px(x, y, D)
    return c, seats


# ------------------------------------------------------------------ N3 intro_static

def _static_mass(c, rows, f, seed=0):
    """Fill spans of striped noise: rows is {y: (x0, x1)}. Stripes are two
    WHITE rows to one DARK row, crawling with the frame, with DARK tears."""
    for y, (x0, x1) in rows.items():
        for x in range(x0, x1 + 1):
            col = W if (y + f) % 3 else D
            if col == W and ((x + f * 3 + y * 5 + seed) % 9) < 2:
                col = D
            c.px(x, y, col)


def _static_spikes(c, rows, f, seed, up=True):
    """Teeth along the top (or bottom) edge of the mass."""
    ys = sorted(rows)
    y = ys[0] if up else ys[-1]
    x0, x1 = rows[y]
    for x in range(x0, x1 + 1):
        h = hash2(x * 7 + seed, f + (0 if up else 50)) % 5
        if h >= 3:
            for k in range(1, h - 1):
                c.px(x - (k if up else -k) // 2, y - k if up else y + k, W if k == 1 else G)


def intro_static(mode, f):
    """32x16, centred on the wire at row 8. crawl: a jagged striped scribble
    riding the wire, leaning left the way it moves. stall: piled up against a
    gap whose edge is at frame x 14, sparks spitting forward. die: flecks
    going GRAY, then DARK, then gone."""
    c = C(32, 16)
    j = [hash2(f * 13 + k, 3) % 3 - 1 for k in range(16)]      # per-row jitter
    if mode == 'crawl':
        # a wave of noise breaking forward: the crest (rows 4 to 6) leads,
        # the belly and the tail drag behind, every row jittering per frame
        rows = {}
        for y in range(2, 15):
            lead = 3 + int(abs(y - 5) * 0.9) + (1 if y > 11 else 0) + (0 if 4 <= y <= 6 else j[y])
            tail = 23 - abs(y - 8) // 2 + j[15 - y]
            rows[y] = (lead, tail)
        _static_mass(c, rows, f)
        for k in range(2):                     # scratches through the mass, sliding back each frame
            x0 = 9 + k * 7 + (f * 2) % 7
            for i in range(10):
                x, y = x0 - i // 3, 3 + i
                if rows.get(y) and rows[y][0] < x < rows[y][1]:
                    c.px(x, y, K)
        _static_spikes(c, rows, f, 11, True)
        _static_spikes(c, rows, f, 23, False)
        for k in range(3):                     # torn strands trailing behind
            y = (4, 8, 11)[k] + (hash2(k, f) % 2)
            x = rows[y][1] + 2 + hash2(k, f + 9) % 2
            ln = 2 + hash2(k, f + 4) % 4
            c.rect(x, y, ln, 1, W if k != 1 else G)
            if ln > 3:
                c.px(x + ln + 1, y, G)
        for k in range(2):                     # a spit of noise ahead of the crest
            c.px(1 + (f + k) % 2, 3 + k * 3 + f % 2, W if k == 0 else G)
        ex = rows[5][0] + 1                    # one eye in the crest, like the walkers
        c.rect(ex, 4, 4, 3, K)
        c.px(ex, 5, W)
        c.outline(K)
        return c
    if mode == 'stall':
        rows = {}
        for y in range(1, 15):
            top_bulge = 2 if y < 5 else 0
            lead = 15 + (y % 2) + j[y] // 2 + (1 if y > 11 else 0) - (top_bulge if f % 2 else 0)
            tail = 27 - abs(y - 8) // 2 + j[15 - y]
            rows[y] = (max(14, lead), tail)
        _static_mass(c, rows, f, seed=5)
        _static_spikes(c, rows, f, 31, True)
        # a second lump climbing over the first
        for y in range(0, 4):
            for x in range(18 + f, 24 + f - y):
                c.px(x, y, W if (y + f) % 2 else D)
        # sparks spitting forward into the gap
        for k in range(5):
            x = 1 + hash2(k, f * 5) % 12
            y = 3 + hash2(k + 7, f * 5) % 10
            c.px(x, y, W if k % 2 == 0 else G)
            if k < 2:
                c.px(x + 1, y + (1 if y < 8 else -1), G)
        c.line(13, 7 + f % 2, 10, 5 + f, W)        # an arc jumping at the cut end
        ex = rows[6][0] + 2
        c.rect(ex, 6, 3, 2, K)
        c.px(ex, 6, W)
        c.outline(K)
        return c
    # die: 0 the mass breaks into chunks, 1 GRAY flecks, 2 DARK flecks, 3 almost gone
    if f == 0:
        for (x, y, w, h) in ((15, 3, 5, 3), (21, 5, 6, 3), (16, 8, 4, 4), (22, 10, 5, 3), (18, 1, 3, 2)):
            for yy in range(y, y + h):
                c.rect(x, yy, w, 1, W if yy % 2 else D)
        c.outline(K)
        return c
    pts = [(14, 2), (19, 1), (25, 3), (29, 7), (26, 12), (20, 14), (15, 11), (12, 6), (22, 7), (17, 5)]
    spread = f * 2
    col = {1: G, 2: D, 3: D}[f]
    for i, (x, y) in enumerate(pts):
        if f == 3 and i % 3:
            continue
        dx = (x - 20) * spread // 6
        dy = (y - 7) * spread // 6
        c.px(x + dx, y + dy, col)
        if f == 1 and i % 2 == 0:
            c.px(x + dx + 1, y + dy, col)
    return c


# ------------------------------------------------------------------ N4 spark_close

# The Spark at twice game scale, the same design as J.spark (juice.gd): a
# white block with a black outline, a black visor with a GRAY pupil at its
# back end, a nub on the back of the head, a GRAY flicker trailing behind,
# black leg gaps and the antenna dot above the head. Every 1x measure is
# doubled, the outline stays 1 px. 48x48 frames: 32x32 left no room for the
# flicker (10 px behind the body) or the flare's rays.
SC = 48
SC_FEET = (24, 47)


def _spark_close(c, w, h, body=W, visor='open', legs='stand', fl=0, flick=G, pip=W, nub=None,
                 core=None, corner=0, dx=0):
    """Draw the close-up Spark facing left on c. w x h is the body (24x28
    standing), its bottom row on SC_FEET's row, centred on SC_FEET's x.
    corner rounds the two top corners (a curled body). core is (rx, ry,
    colour), a glow low in the back of a dim body. pip is the antenna dot's
    colour, or None."""
    fx, fy = SC_FEET
    bx = fx - w // 2 + dx
    by = fy + 1 - h
    b = C(c.w, c.h)
    for y in range(by, by + h):
        for x in range(bx, bx + w):
            if corner and y < by + corner:
                for cx0 in (bx + corner - 0.5, bx + w - corner - 0.5):
                    if (x < bx + corner and cx0 < bx + w / 2) or (x >= bx + w - corner and cx0 > bx + w / 2):
                        if math.hypot(x - cx0, y - (by + corner - 0.5)) > corner + 0.2:
                            break
                else:
                    b.px(x, y, body)
                continue
            b.px(x, y, body)
    if nub is not None:                        # the nub on the back of the head (right side)
        b.rect(bx + w, by + 2, 1, 6, nub)
    b.outline(K)
    c.paste(b, 0, 0)
    if core is not None:
        rx, ry, col = core
        c.ellipse(bx + w * 0.62, by + h - ry - 3, rx, ry, col, only=body)
    vx = bx + 4
    if visor == 'open':
        c.rect(vx, by + 6, 8, 6, K)
        c.rect(vx + 6, by + 6, 2, 2, G)
    elif visor == 'half':
        c.rect(vx, by + 8, 8, 4, K)
        c.rect(vx + 6, by + 8, 2, 2, G)
    elif visor == 'closed':
        c.rect(vx, by + 7, 8, 1, K)
    if flick is not None:                      # the trailing flicker behind (right)
        sx = bx + w + 2
        c.rect(sx, by + 8 + 2 * fl, 6, 4, flick)
        c.rect(sx + 4, by + 10 - 2 * fl, 4, 2, flick)
    nw = 6 if w >= 24 else 4
    if legs == 'stand':
        c.rect(bx + 4, by + h - 4, nw, 4, K)
        c.rect(bx + w - 4 - nw, by + h - 4, nw, 4, K)
    elif legs == 'sit':
        c.rect(bx + 4, by + h - 2, nw, 2, K)
        c.rect(bx + w - 4 - nw, by + h - 2, nw, 2, K)
    if pip is not None:                        # the antenna dot: a ring with a black centre
        px_ = bx + w // 2 - 2
        c.rect(px_ - 1, by - 11, 8, 8, K)
        c.rect(px_, by - 10, 6, 6, pip)
        c.rect(px_ + 2, by - 8, 2, 2, K)
    return bx, by


def _rays(c, cx, cy, r0, r1, col, tip=None, angles=(), thick=()):
    """Straight rays from radius r0 to r1 round (cx, cy) at the given angles
    (degrees, 0 = right, -90 = up). Rays in `thick` are 2 px wide. Only on
    empty pixels, so they never cross the body or the antenna dot."""
    for a_deg in angles:
        a = math.radians(a_deg)
        steps = int(max(1, (r1 - r0) * 2))
        pts = []
        for s in range(steps + 1):
            r = r0 + (r1 - r0) * s / steps
            pts.append((int(round(cx + r * math.cos(a))), int(round(cy + r * math.sin(a)))))
        for (x, y) in pts:
            for (ox, oy) in ((0, 0),) + (((0, 1) if abs(math.sin(a)) < 0.5 else (1, 0)),) * (a_deg in thick):
                if c.get(x + ox, y + oy) == T:
                    c.px(x + ox, y + oy, col)
        if tip is not None:
            x, y = pts[-1]
            if c.get(x, y) == col:
                c.px(x, y, tip)


def spark_close(mode, f):
    c = C(SC, SC)
    if mode == 'curled':
        _spark_close(c, 24, 14, body=G, visor='closed', legs=None, fl=0, flick=D, pip=None, nub=G,
                     core=(2.5 + f, 1.2 + f, W), corner=4)
    elif mode == 'stir':
        if f == 0:      # a twitch: the back hunches up a pixel, the flicker jumps, the core bigger
            _spark_close(c, 24, 15, body=G, visor='closed', legs=None, fl=1, flick=D, pip=None, nub=G,
                         core=(4.5, 2.4, W), corner=4)
        elif f == 1:    # half the body white, raised a little, the antenna dot comes on grey
            bx, by = _spark_close(c, 24, 18, body=G, visor='closed', legs=None, fl=0, flick=G, pip=G, nub=G,
                                  corner=3)
            for y in range(by + 3, by + 18):
                for x in range(bx, bx + 24):
                    if c.get(x, y) == G and (x < bx + 12 or (x < bx + 16 and bayer(x, y) < 8)):
                        c.px(x, y, W)
        else:           # the eye opens, the body is white but for the back of the head
            bx, by = _spark_close(c, 24, 20, body=W, visor='half', legs=None, fl=1, flick=G, pip=G, nub=W,
                                  corner=2)
            c.dith(bx + 16, by, 8, 7, G, 6, only=W)
    elif mode == 'flare':
        cx = SC_FEET[0]
        if f == 0:      # pops upright, stretched thin and tall, a full burst of rays
            _spark_close(c, 20, 32, visor='open', legs='stand', fl=1, pip=W, nub=W)
            _rays(c, cx - 0.5, 30, 14, 23, W, tip=G, angles=(180, 0, -135, -45, 135, 45, -160, -20),
                  thick=(180, 0, -135, -45))
        elif f == 1:    # standing tall, the rays breaking away from the body
            _spark_close(c, 24, 28, visor='open', legs='stand', fl=0, pip=W, nub=W)
            _rays(c, cx - 0.5, 32, 17, 23, W, tip=G, angles=(180, 0, -135, -45, 135, 45, -160, -20),
                  thick=(180, 0))
        elif f == 2:    # the rays shrink back in, grey, the Spark settling
            _spark_close(c, 24, 26, visor='open', legs='sit', fl=1, pip=W, nub=W)
            _rays(c, cx - 0.5, 34, 16, 19, G, angles=(180, 0, -135, -45, 135, 45))
        else:           # settled: a sitting Spark, a few grey flecks left over
            _spark_close(c, 24, 24, visor='open', legs='sit', fl=0, pip=W, nub=W)
            for (x, y) in ((7, 30), (41, 32), (9, 42), (40, 44), (12, 22), (36, 21)):
                c.px(x, y, G)
    else:               # sit: alert, facing the wire, the flicker moving
        _spark_close(c, 24, 24, visor='open', legs='sit', fl=f, pip=W, nub=W)
    return c


# ------------------------------------------------------------------ N5 intro_wire_close

def _cable_row(c, x0, x1, lit=False, twist=0):
    """The thick cable centred on row 16: a 3 px core (rows 15 to 17, a GRAY
    top edge over DARK) between black edges, or lit: a GRAY core whose black
    edges turn DARK, with a DARK glow dither above and below."""
    for x in range(x0, x1 + 1):
        if lit:
            c.px(x, 14, D)
            c.px(x, 15, G)
            c.px(x, 16, G)
            c.px(x, 17, G if (x + twist) % 4 else D)
            c.px(x, 18, D)
            for y in (12, 13, 19, 20):
                if bayer(x, y) < (6 if y in (13, 19) else 2):
                    c.px(x, y, D)
        else:
            c.px(x, 14, K)
            c.px(x, 15, G)
            c.px(x, 16, D)
            c.px(x, 17, D if (x + twist) % 4 else K)
            c.px(x, 18, K)


def _cable_join(c, x, lit=False):
    """An insulation join: a sleeve a pixel proud of the cable, 3 px long."""
    c.rect(x, 13, 3, 7, K if not lit else D)
    c.rect(x, 14, 3, 1, G)
    c.rect(x, 15, 3, 3, G if lit else D)
    c.rect(x + 2, 14, 1, 5, K if not lit else D)


def wire_close(v, lit=False):
    c = C(32, 32)
    _cable_row(c, 0, 31, lit, twist=v)
    for x in ((6, 22) if v == 0 else (14,)):
        _cable_join(c, x, lit)
    return c


def wire_end_close(lit=False):
    """The cut end: the cable arrives from the right and its core stops at
    frame (4, 16), with frayed strands splaying out of the cut insulation."""
    c = C(32, 32)
    _cable_row(c, 10, 31, lit)
    _cable_join(c, 24, lit)
    c.rect(9, 14, 1, 5, G if lit else D)       # the cut face of the insulation
    c.px(9, 15, G)
    strand = G
    for (x0, y0, x1, y1) in ((8, 16, 4, 16), (8, 15, 5, 13), (8, 15, 3, 12), (8, 17, 5, 19), (8, 17, 2, 20),
                             (7, 16, 3, 14), (7, 16, 4, 18)):
        c.line(x0, y0, x1, y1, strand if (x1 + y1) % 2 == 0 or lit else D)
    c.px(4, 16, G)                             # the tip
    if lit:
        for (x, y) in ((2, 15), (3, 17), (1, 13), (5, 21), (2, 18), (6, 11)):
            c.px(x, y, D)
    return c


GRASS = [   # per frame: tufts as (x, [(dx, height, lean), ...])
    [(4, [(0, 9, -1), (2, 13, 0), (4, 7, 1)]), (15, [(0, 5, -1), (1, 8, 0)]), (23, [(0, 11, -1), (2, 16, 1), (4, 9, 1), (5, 5, 1)])],
    [(3, [(0, 6, -1), (2, 10, 1)]), (11, [(0, 14, -1), (2, 18, 0), (3, 11, 1), (5, 7, 1)]), (24, [(0, 8, 0), (2, 5, 1)])],
    [(6, [(0, 12, -1), (1, 17, -1), (3, 10, 0), (5, 6, 1)]), (18, [(0, 7, 0), (2, 9, 1)]), (26, [(0, 5, -1), (1, 6, 1)])],
    [(2, [(0, 7, 0), (1, 5, 1)]), (9, [(0, 9, -1), (2, 6, 0)]), (19, [(0, 15, -1), (1, 20, 0), (3, 13, 1), (5, 8, 1)])],
]


def grass_close(v):
    """Grass tufts at twice game scale: DARK blades with a black shadow edge
    on the right and a few GRAY tips, rooted in a dithered DARK band, bottoms
    on row 31. Every tuft stays inside x 1 to 30 and the band is the same at
    both edges, so frames tile in any order."""
    c = C(32, 32)
    c.rect(0, 29, 32, 3, D)
    c.dith(0, 29, 32, 3, K, 5)
    for (x, blades) in GRASS[v]:
        for i, (dx, h, lean) in enumerate(blades):
            bx = x + dx
            pts = []
            for k in range(h):
                pts.append((bx + (lean * k * k) // (h * 3), 29 - k))
            for j, (xx, y) in enumerate(pts):
                c.px(xx, y, D)
                if j < h // 3 and h > 8:
                    c.px(xx - 1, y, D)
            for (xx, y) in pts:                  # the shadow edge
                if c.get(xx + 1, y) == T:
                    c.px(xx + 1, y, K)
            tx, ty = pts[-1]
            if (i + v) % 2 == 0 or h > 14:
                c.px(tx, ty, G)
                if h > 12:
                    c.px(pts[-2][0], pts[-2][1], G)
            c.px(tx, ty - 1, K) if c.get(tx, ty - 1) == T else None
    return c


def ring_close(f):
    """A ring of light running along the cable: a GRAY bead in a black rim and
    a DARK halo that pulses, centred on (16, 16), with a tail behind it
    (right) fading from GRAY to DARK."""
    c = C(32, 32)
    halo = (6.5, 8.5, 7.5)[f]
    bead = (2.6, 3.3, 2.6)[f]
    cx = cy = 16.5
    for y in range(32):
        for x in range(32):
            d = math.hypot(x + 0.5 - cx, y + 0.5 - cy)
            if bead + 1.2 < d <= halo and bayer(x, y) < (10 if d < halo - 1.5 else 4):
                c.px(x, y, D)
    for x in range(19, 31):                    # the tail along the cable
        if x < 23 or (x < 27 and bayer(x, 16) < 10) or bayer(x, 16) < 4:
            c.px(x, 16, G if x < 24 else D)
            if x < 22:
                c.px(x, 15, G)
                c.px(x, 17, D)
    c.ellipse(cx, cy, bead + 1.0, bead + 1.0, K)
    c.ellipse(cx, cy, bead, bead, G)
    if f == 1:                                 # the pulse: a darker heart as it swells
        c.px(16, 16, D)
    return c


def ring_pop_close(f):
    """The ring reaches the tip and bursts into four GRAY flecks, centred on (16, 16)."""
    c = C(32, 32)
    if f == 0:
        c.ellipse(16.5, 16.5, 3.4, 3.4, D)
        c.ellipse(16.5, 16.5, 2.4, 2.4, G)
        for (dx, dy) in ((1, 1), (-1, 1), (1, -1), (-1, -1)):
            for k in (3, 4):
                c.px(16 + dx * k, 16 + dy * k, G)
    elif f == 1:
        for (dx, dy) in ((1, 1), (-1, 1), (1, -1), (-1, -1)):
            c.rect(16 + dx * 5 - (1 if dx < 0 else 0), 16 + dy * 5 - (1 if dy < 0 else 0), 2, 2, G)
            c.px(16 + dx * 3, 16 + dy * 3, D)
        c.px(16, 16, D)
    else:
        for (dx, dy) in ((1, 1), (-1, 1), (1, -1), (-1, -1)):
            c.px(16 + dx * 8, 16 + dy * 8, G)
            c.px(16 + dx * 6, 16 + dy * 6, D)
    return c


# ------------------------------------------------------------------ N6 intro_far

def _roof_left(c, y):
    for x in range(c.w):
        if c.get(x, y) != T:
            return x
    return None


KEEPER_BRACKET_ROW = 20


def keeper_night(f):
    """The keeper's house (house facade 0) as a night silhouette: the same
    outline and position, every grey one step darker, the lit window GRAY
    with its black mullions and the broken diagonal. A wire bracket on the
    roof's left edge takes the line from the hill. Frame 1 flickers the window."""
    src = facade(0)
    c = C(64, 64)
    for y in range(64):
        for x in range(64):
            col = src.get(x, y)
            if col == W:
                col = G
            elif col == G:
                col = D
            elif col == D and bayer(x, y) < 5:
                col = K
            c.px(x, y, col)
    # the window: panes back to GRAY (they were white), flickering on frame 1
    wx, wy, n = 6, 34, 13
    for y in range(wy, wy + n):
        for x in range(wx, wx + n):
            if src.get(x, y) == W:
                c.px(x, y, D if (f == 1 and bayer(x, y) < 8) else G)
    c.rect(wx - 2, wy + n + 1, n + 4, 1, G if f == 0 else D)   # the sill catches the window's light
    # wire bracket: a short arm out of the roof edge with a GRAY insulator on it
    y = KEEPER_BRACKET_ROW
    edge = _roof_left(c, y)
    c.rect(edge - 2, y + 1, 3, 1, D)
    c.px(edge - 2, y, G)
    c.px(edge - 3, y + 1, K)
    c.px(edge - 2, y - 1, K)
    c.px(edge - 1, y, K)
    return c


def keeper_bracket():
    """The wire bracket's insulator pixel on keeper_night."""
    return (_roof_left(facade(0), KEEPER_BRACKET_ROW) - 2, KEEPER_BRACKET_ROW)


GATE_FAR_CX = 16      # the gate's centre column: the art fills frame x 0 to 31


def gate_far():
    """The World 1 gate transmitter seen from far off: an open DARK lattice
    about 32x60 on a base hut, foot on row 63, one GRAY lamp pixel at the
    top. The lattice stays see-through; only its lower part, where it stands
    in front of the far buildings, gets a black edge."""
    c = C(64, 64)
    cx = GATE_FAR_CX
    base, top = 56, 12

    def leg_x(y, s):
        return int(round(cx + s * (2 + (y - top) * 8.5 / (base - top))))
    for y in range(top, base):                 # the two legs
        c.px(leg_x(y, -1), y, D)
        c.px(leg_x(y, 1), y, D)
    for y in range(top + 1, base):             # a faint mesh between the legs
        for x in range(leg_x(y, -1) + 1, leg_x(y, 1)):
            if bayer(x, y) < 2:
                c.px(x, y, D)
    girts = list(range(top, base + 1, 6))
    for y in girts:                            # horizontal girts
        c.rect(leg_x(y, -1), y, leg_x(y, 1) - leg_x(y, -1) + 1, 1, D)
    for i, (y0, y1) in enumerate(zip(girts, girts[1:])):   # zigzag bracing, one diagonal a panel
        a, b = (-1, 1) if i % 2 == 0 else (1, -1)
        c.line(leg_x(y0, a), y0, leg_x(y1, b), y1, D)
    for (y, w) in ((18, 7), (32, 9), (46, 11)):   # crossarms with drop ends
        c.rect(cx - w, y, w * 2 + 1, 1, D)
        c.px(cx - w, y + 1, D)
        c.px(cx + w, y + 1, D)
    for (x, y, s) in ((cx - 9, 34, -1), (cx + 11, 48, 1)):   # ring antennas
        for k in range(-2, 3):
            c.px(x + s * (1 if abs(k) < 2 else 0), y + k, D)
    c.rect(cx, 3, 1, top - 3, D)               # the whip, with two small bars
    for y in (6, 9):
        c.rect(cx - 1, y, 3, 1, D)
    c.px(cx, 2, G)                             # the one lamp
    # base hut
    c.rect(cx - 11, base, 23, 8, D)
    c.dith(cx - 11, base + 1, 23, 7, K, 5, only=D)
    c.rect(cx - 1, base + 3, 3, 5, K)          # door
    edge = c.copy().outline(K)
    for y in range(44, 64):                    # a black edge outside the silhouette, low down only
        for x in range(64):
            inside = y < base and leg_x(y, -1) < x < leg_x(y, 1)
            if c.get(x, y) == T and edge.get(x, y) == K and not inside:
                c.px(x, y, K)
    return c


GATE_FAR_LAMP = (GATE_FAR_CX, 2)


# ------------------------------------------------------------------ N7 intro_window

WIN_W, WIN_H = 320, 176
WIN_OPEN = (12, 10, 308, 150)       # x0, y0, x1, y1: the transparent opening, x1 and y1 not included
WIN_MULLION = (146, 150)            # x0, x1 (not included)
WIN_TRANSOM = (44, 48)              # y0, y1 (not included)


def intro_window():
    """The keeper's window from inside: the casing, mullion, transom and sill
    in DARK with GRAY edges catching the night outside. The upper left pane
    carries the broken diagonal mullion. The lower right pane stays clear."""
    c = C(WIN_W, WIN_H)
    x0, y0, x1, y1 = WIN_OPEN
    # casing round the opening, wood grain in black dither
    c.rect(0, 0, WIN_W, y1, D)
    c.dith(0, 0, WIN_W, y1, K, 4, only=D)
    c.frame(0, 0, WIN_W, y1, K)
    c.rect(x0, y0, x1 - x0, y1 - y0, T)
    # inner edges: GRAY where the casing faces the opening, black on the far side
    c.rect(x0 - 1, y0 - 1, x1 - x0 + 2, 1, G)
    c.rect(x0 - 1, y0 - 1, 1, y1 - y0 + 1, G)
    c.rect(x1, y0 - 1, 1, y1 - y0 + 1, K)
    c.rect(x0 - 2, y0 - 2, x1 - x0 + 4, 1, K)
    c.rect(x0 - 2, y0 - 2, 1, y1 - y0 + 2, K)
    # mullion and transom, 4 px, GRAY lit edges on the top and left
    m0, m1 = WIN_MULLION
    t0, t1 = WIN_TRANSOM
    c.rect(m0, y0, m1 - m0, y1 - y0, D)
    c.rect(x0, t0, x1 - x0, t1 - t0, D)
    c.rect(m0, y0, 1, y1 - y0, G)
    c.rect(m1 - 1, y0, 1, y1 - y0, K)
    c.rect(x0, t0, x1 - x0, 1, G)
    c.rect(x0, t1 - 1, x1 - x0, 1, K)
    c.rect(m0, t0, 1, t1 - t0, G)
    # a latch on the mullion
    c.rect(m0 - 2, 96, 2, 5, D)
    c.rect(m0 - 2, 96, 1, 5, G)
    c.px(m0 - 3, 98, G)
    # the broken diagonal in the upper left pane: corner to corner, snapped
    # two thirds of the way, the broken end hanging down
    ax, ay, bx, by = x0, y0, m0 - 1, t0 - 1
    snap0, snap1 = 0.62, 0.8
    n = bx - ax
    for i in range(n + 1):
        u = i / n
        if snap0 < u < snap1:
            continue
        x = ax + i
        y = int(round(ay + (by - ay) * u))
        c.px(x, y - 1, G)
        c.px(x, y, D)
        c.px(x, y + 1, D)
        c.px(x, y + 2, K)
    hx = ax + int(n * snap0)
    hy = int(round(ay + (by - ay) * snap0))
    for k in range(9):                          # the hanging end
        x = hx + (k // 4)
        c.px(x, hy + 2 + k, D)
        c.px(x + 1, hy + 2 + k, K)
        c.px(x - 1, hy + 2 + k, G if k < 6 else D)
    # the sill: its top edge on row 150 is the surface the Spark sits on
    c.rect(0, y1, WIN_W, WIN_H - y1, D)
    c.rect(0, y1, WIN_W, 1, G)
    c.dith(0, y1 + 1, WIN_W, 5, G, 2)
    c.rect(0, y1 + 6, WIN_W, 1, G)             # nosing
    c.rect(0, y1 + 7, WIN_W, 3, D)
    c.rect(0, y1 + 10, WIN_W, 1, K)
    c.rect(4, y1 + 11, WIN_W - 8, WIN_H - y1 - 11, D)   # the apron below
    c.dith(4, y1 + 11, WIN_W - 8, WIN_H - y1 - 11, K, 7, only=D)
    c.rect(4, y1 + 11, WIN_W - 8, 1, K)
    c.rect(0, y1 + 11, 4, WIN_H - y1 - 11, T)
    c.rect(WIN_W - 4, y1 + 11, 4, WIN_H - y1 - 11, T)
    c.rect(0, y1, 1, 11, K)
    c.rect(WIN_W - 1, y1, 1, 11, K)
    return c


# ------------------------------------------------------------------ build

def build_intro():
    mast = {m: [intro_mast(m, f)[0] for f in range(n)] for (m, n) in INTRO_MAST_ROWS}
    sheet('intro_npc', 16, 24, [
        A('listener_sit', [intro_listener(0), intro_listener(1)], 0,
          note='a generic listener sitting on the ground, knees up, small headphones, white dot eyes. '
               '0 looks ahead, 1 tilts the head up at a passing pulse. Card 2'),
        A('mast_lantern_walk', mast['walk'], 0.2,
          note='Old Mast walking slowly, the lantern held forward in his front hand and the cane in his back hand. '
               + intro_lantern_note('walk') + '. Card 9'),
        A('mast_lantern_stand', mast['stand'], 0.4,
          note='standing, the lantern held out at chest height, swaying 1 px. ' + intro_lantern_note('stand')
               + '. Card 9 and the hand-off'),
        A('mast_lantern_look', mast['look'], 0.5,
          note='bent over, looking down, the lantern low near the ground. ' + intro_lantern_note('look')
               + '. Hand-off'),
    ], 'Intro people. Anchor like npc: top-left (cell x, cell y - 8), feet on the floor (feet centre = frame x 8, '
       'row 23). Face left, mirror for right. Old Mast is drawn on his npc body, so he lines up with mast_idle. '
       'His eyes and antenna lamp are GRAY here and his lantern is GRAY glass in a DARK cage, because from card 5 '
       'on only the Spark is white. The code hangs the lantern light on the lantern centre given in each row.')
    seats = [dead_pole(k)[1] for k in (0, 1)]
    sheet('intro_poles', IP_W, IP_H, [
        A('switch_ready', [intro_switch('ready', 0), intro_switch('ready', 1)], 0.5,
          note='a pole with an isolation switch at the top (blade closed across the contacts), an operating rod '
               'down the pole to a notched handle, and a crew listener in a work coat and hard hat with one hand '
               'on it'),
        A('switch_pull', [intro_switch(p) for p in ('grip', 'lean', 'heave', 'down', 'hold')],
          [0.1, 0.1, 0.15, 0.1, 0.25], loop=False,
          note='grip, lean, heave (the blade leaves the jaw), down (blade open, the jaw scorched DARK), hold. '
               'The crew is still holding the handle down on the last frame'),
        A('switch_after', [intro_switch('after', 0), intro_switch('after', 1)], 0.6,
          note='the switch open, the crew with the head bowed and the hands off the handle'),
        A('dead', [dead_pole(k)[0] for k in range(3)], 0,
          note=f'no crew, no wire, no white. 0 leans left about 12 degrees, wire seats at frame {seats[0][0]} and '
               f'{seats[0][1]}. 1 leans right, wire seats at frame {seats[1][0]} and {seats[1][1]}. 2 a snapped '
               'stump about 24 px tall with its broken top in the grass. Hand-drawn, not rotated in code'),
    ], 'Intro poles, the same pole as title_pole moved 12 px right in a wider frame. Top-left = (pole x - 12, '
       'wire y - 4). The switch contacts and the insulators sit at frame (15, 4) and (32, 4), and the foot is on '
       'row 63 (screen y 249 with the wire at 190). The switch blade opens between the contacts, so leave the '
       'wire gap from frame x 15 to 32 (screen 203 to 220 for the pole at x 200). The crew faces RIGHT, toward '
       'the pole, so draw these rows unmirrored. Only the switch rows have white (the crew\'s eyes, the blade, '
       'the insulator glints), for cards 3 and 4.')
    sheet('intro_static', 32, 16, [
        A('crawl', [intro_static('crawl', f) for f in range(4)], 0.06,
          note='the noise: a jagged striped scribble with one eye, riding the wire and leaning left the way it '
               'moves'),
        A('stall', [intro_static('stall', f) for f in range(3)], 0.08,
          note='piled up against a gap, climbing over itself, sparks spitting forward. The pile\'s front face is '
               'frame x 14, the gap edge when the static stops at x 222'),
        A('die', [intro_static('die', f) for f in range(4)], 0.1, loop=False,
          note='breaks into chunks, then flecks that go GRAY, then DARK, then gone. Stop drawing after it ends'),
    ], 'The noise that came down the line. Centre it on the wire: top-left = (x - 16, wire y - 8). White and '
       'DARK stripes and teeth, like the walkers, so it never reads as the Spark or the Arc.')
    sheet('spark_close', SC, SC, [
        A('curled', [spark_close('curled', f) for f in range(2)], 1.2,
          note='squashed low (24x14), curled, visor closed to a 1 px line. Mostly GRAY with a small WHITE core '
               'that grows 1 px on frame 1. No antenna dot yet'),
        A('stir', [spark_close('stir', f) for f in range(3)], 0,
          note='held one at a time, one per ring: 0 a twitch, the core bigger. 1 half the body white, raised. '
               '2 the eye half open, the body white. The antenna dot comes on GRAY on 1 and 2'),
        A('flare', [spark_close('flare', f) for f in range(4)], [0.06, 0.06, 0.1, 0.12], loop=False,
          note='white rays burst round the body as it pops upright, then shrink back into a sitting Spark. The '
               'antenna dot is WHITE from here on'),
        A('sit', [spark_close('sit', f) for f in range(2)], 0.5,
          note='sitting up, alert, facing the wire, the trailing flicker moving'),
    ], 'The Spark close up, twice the size of the in-game block (body 24x28 standing), the same design as J.spark: '
       'white body, black outline, black visor with a GRAY pupil, the nub on the back of the head, the GRAY '
       'trailing flicker and the antenna dot. 48x48 frames so the flicker and the rays fit. Anchor bottom-centre: '
       'feet at frame (24, 47), so top-left = (feet x - 24, feet y - 47). Faces left: mirror it to face right.')
    sheet('intro_wire_close', 32, 32, [
        A('grass', [grass_close(v) for v in range(4)], 0,
          note='grass tufts, DARK blades with a black shadow edge and a few GRAY tips, bottoms on row 31. Tile edge '
               'to edge in any order'),
        A('wire', [wire_close(0), wire_close(1)], 0,
          note='the cable lying straight across, centred on row 16: a 3 px core with insulation joins, DARK with '
               'a GRAY top edge. Tiles left to right'),
        A('wire_end', [wire_end_close()], 0,
          note='the cut end: the cable arrives from the right, frayed strands splay from the cut, the tip is '
               'frame (4, 16)'),
        A('wire_lit', [wire_close(0, lit=True), wire_end_close(lit=True)], 0,
          note='0 the wire tile lit, 1 the wire_end tile lit: the core GRAY, a thin DARK glow above and below. '
               'No white'),
        A('ring', [ring_close(f) for f in range(3)], 0.06,
          note='a ring of light running along the cable: a GRAY bead in a black rim and a DARK halo that pulses, centred on '
               '(16, 16), with a short tail behind it (right). Never white'),
        A('ring_pop', [ring_pop_close(f) for f in range(3)], 0.05, loop=False,
          note='the ring reaches the tip and bursts into four GRAY flecks, centred on (16, 16)'),
    ], 'The close-up set pieces at twice game scale. The cable centre is frame row 16 on wire, wire_end and '
       'wire_lit, so with the tiles at y 200 the cable centre is screen y 216.')
    bx, by = keeper_bracket()
    wcx, wcy = 6 + 6, 34 + 6
    sheet('intro_far', 64, 64, [
        A('keeper_night', [keeper_night(0), keeper_night(1)], [0.8, 0.15],
          note=f'house facade 0 as a night silhouette, the lit window (with its broken diagonal mullion) GRAY. '
               f'1 flickers the window. Window centre frame ({wcx}, {wcy}). The wire bracket\'s insulator is '
               f'frame ({bx}, {by}): hang the wire from the hill there'),
        A('gate_far', [gate_far()], 0,
          note=f'the World 1 gate transmitter far off: an open DARK lattice about 32x60 on a base hut, black-edged low '
               f'down where it stands in front of the far buildings, one GRAY '
               f'lamp pixel at frame {GATE_FAR_LAMP}. The art fills frame x 0 to 31 (centre column '
               f'{GATE_FAR_CX}) with its foot on row 63'),
    ], 'Night silhouettes where the normal art would show white. keeper_night has the same anchor as house: '
       'top-left = (door cell x - 24, door cell y - 48). gate_far stands on the horizon: its foot is row 63.')
    sheet('intro_window', WIN_W, WIN_H, [
        A('frame', [intro_window()], 0,
          note='the keeper\'s window seen from inside, DARK with GRAY edges'),
    ], 'The keeper\'s window from inside, one 320x176 frame. The opening is transparent from frame (12, 10) to '
       '(308, 150), not including x 308 or y 150. The mullion covers frame x 146 to 149 and the transom rows 44 '
       'to 47. The upper left pane carries the broken diagonal mullion. The lower right pane (x 170 to 300, '
       'y 60 to 148) is clear. The sill runs from row 150 to 175 and its top edge, row 150, is the surface the '
       'Spark sits on.')


# =================================================================== the Howl

# The antagonist: the howling noise that once filled the line, every voice it
# swallowed fed back on itself, pooled deep underground after the line was
# cut. It is intro_static grown vast: a heap of billows rising from below,
# each billow with the same crust of WHITE and DARK stripes and teeth along
# its top, a dimmer GRAY and DARK body that darkens inward, torn strands and
# cut wire poking out, and a dark hollow where the face sits, so the two
# WHITE eyes glow. The billows at the back are a step dimmer than the front.

HOWL_W, HOWL_H = 96, 64
HOWL_EYES = ((36, 29), (59, 29))         # eye centres, the same in every frame
HOWL_MOUTH = (47.5, 43)                  # centre of the mouth gap

_HOWL_BLOBS = (                          # the silhouette: (cx, cy, rx, ry, wobble phase)
    (26, 18, 12, 9, 0.4), (41, 12, 12, 6, 1.9), (57, 11, 13, 6, 3.1), (72, 17, 12, 9, 4.4),
    (13, 31, 8, 9, 5.6), (83, 30, 8, 9, 0.9),
    (48, 68, 30, 50, 0.0), (48, 29, 30, 14, 1.1), (18, 35, 11, 8, 1.3), (78, 35, 11, 8, 2.6),
    (24, 50, 9, 8, 4.1), (72, 51, 9, 8, 5.3),
)

_HOWL_BILLOWS = (                        # billows inside the heap whose lit tops show
    (31, 24, 11, 7, 0.9), (48, 19, 11, 6, 2.2), (65, 23, 11, 7, 3.5),
    (16, 40, 10, 8, 1.3), (80, 40, 10, 8, 2.6),
    (26, 56, 12, 8, 4.1), (70, 57, 12, 8, 5.3), (48, 60, 10, 6, 0.3),
)

_HOWL_WIRES = (                          # from inside the heap out to the cut tip
    ((19, 42), (10, 46), (5, 44), (3, 39)),
    ((77, 42), (86, 46), (91, 44), (93, 39)),
    ((24, 16), (16, 11), (10, 8), (6, 3)),
    ((72, 15), (82, 10), (88, 8), (92, 3)),
    ((26, 54), (16, 57), (11, 55), (6, 58), (3, 62)),
    ((70, 54), (80, 58), (86, 56), (91, 60)),
)

_HOWL_SLIT = ((0, 1), (1, 2), (2, 2), (3, 3), (4, 3), (5, 3), (6, 3), (7, 3), (8, 2), (9, 2), (10, 1))

_HOWL_FLECKS = ((4, 20, 3), (89, 18, 3), (18, 8, 3), (78, 7, 3), (8, 13, 2), (91, 11, 2))

_HOWL_EYE = (                            # the left eye, centre at column 5, row 2
    'www........',
    'wwwwwww....',
    'wwwwwwwwww.',
    '.wwwwwwwwww',
    '...wwwwww..',
)


def _line_pts(x0, y0, x1, y1):
    pts = []
    dx, dy = abs(x1 - x0), -abs(y1 - y0)
    sx, sy = (1 if x0 < x1 else -1), (1 if y0 < y1 else -1)
    err = dx + dy
    while True:
        pts.append((x0, y0))
        if x0 == x1 and y0 == y1:
            return pts
        e2 = 2 * err
        if e2 >= dy:
            err += dy
            x0 += sx
        if e2 <= dx:
            err += dx
            y0 += sy


def _howl_mask(blobs, w, h, f, n, grow=0.0, sink=0.0, seed=0, tear=6):
    """One layer's silhouette: the union of wobbling ellipses, its edge
    roughened per frame and a few rows slid sideways (sync tears). Returns a
    set of (x, y)."""
    ph = 2 * math.pi * f / n
    bs = []
    for (cx, cy, rx, ry, p) in blobs:
        bs.append((cx + math.cos(ph + p) * 0.9, cy + sink + math.sin(ph + p) * 1.3,
                   rx + grow + math.sin(ph + p * 2) * 0.9, ry + grow / 2 + math.cos(ph + p) * 0.9))
    m = set()
    for y in range(h):
        hh = hash2(y * 5 + seed, f + 40)
        sh = (hh % 5 - 2) if hh % tear == 0 else 0
        for x in range(w):
            xx = x - sh
            v = max(1 - ((xx + .5 - cx) / rx) ** 2 - ((y + .5 - cy) / ry) ** 2 for (cx, cy, rx, ry) in bs)
            v += ((hash2(xx // 2, y * 3 + f * 97 + seed) % 100) / 100 - 0.5) * 0.08
            if v > 0:
                m.add((x, y))
    return m


def _howl_depth(mask, h):
    """Steps from each mask pixel to the outside. The bottom edge counts as
    inside: the heap carries on below the frame."""
    d, q = {}, []
    for (x, y) in mask:
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            if y + dy < h and (x + dx, y + dy) not in mask:
                d[(x, y)] = 0
                q.append((x, y))
                break
    i = 0
    while i < len(q):
        x, y = q[i]
        i += 1
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            p = (x + dx, y + dy)
            if p in mask and p not in d:
                d[p] = d[(x, y)] + 1
                q.append(p)
    return d


def _howl_body(c, mask, depth, f, lit, fade=46, seed=0, hollow=None, seam=False):
    """Colour one billow layer: a striped crust like intro_static (two bright
    rows to one DARK row, with DARK tears), GRAY and DARK stripes inside that
    darken toward the core, snow dashes that jump every frame, and a fade to
    black toward the bottom. lit 2 is awake, 1 is a step dimmer (asleep, or
    the back billows), 0 dimmer again. hollow is (cx, cy, rx, ry), a darker
    patch for the face. seam puts a black line where this layer's edge lies
    over an earlier one."""
    hi, mid = ((G, D), (G, D), (W, G))[lit]
    for (x, y) in mask:
        d = depth[(x, y)]
        s = (y + f) % 3
        crust = 3 if y < 30 else 2 if y < 44 else 1
        torn = ((x + f * 3 + y * 5 + seed) % 9) < 2
        if seam and d == 0 and c.get(x, y)[3]:
            c.px(x, y, K)
            continue
        if d < crust:
            col = hi if s and not torn else D
        elif d < crust + 3:
            col = mid if s and not torn else D
        elif d < crust + 8:
            col = mid if s == 1 and not torn else D
        else:
            col = D if s else K
            if s == 1 and hash2(x + seed, y * 7 + f * 131) % 7 == 0:
                col = mid
        # snow: short dashes that jump every frame
        if d >= crust and hash2(x // 3 + y * 13 + seed, f * 17 + y) % 19 == 0:
            col = hi if d < crust + 8 else mid
        if hollow:
            hx, hy, hrx, hry = hollow
            e = ((x + .5 - hx) / hrx) ** 2 + ((y + .5 - hy) / hry) ** 2
            if e < 1 and d >= crust and bayer(x, y) < int((1 - e) * 26):
                col = D if s == 1 else K
                if s == 1 and hash2(x * 3 + seed, y + f * 53) % 11 == 0:
                    col = G
        if y >= fade and bayer(x, y) < (y - fade):
            col = D if col in (W, G) else K
        if y >= fade + 8 and bayer(x, y) < (y - fade - 8) * 2:
            col = K
        c.px(x, y, col)


def _howl_teeth(c, mask, f, seed, col, amount=5, top=40):
    """Teeth along a layer's top edge, leaning like intro_static's: col at
    the root, GRAY above."""
    tops = {}
    for (x, y) in mask:
        if x not in tops or y < tops[x]:
            tops[x] = y
    for x, y in tops.items():
        if y > top:
            continue
        hh = hash2(x * 7 + seed, f) % 8
        if hh >= 7 - amount // 2:
            for k in range(1, 2 + hh % 3):
                c.px(x - k // 2, y - k, col if k == 1 else G)


def _howl_strands(c, mask, w, h, f, seed, lit, count=8, reach=6):
    """Torn strands streaming off the sides."""
    rows = {}
    for (x, y) in mask:
        a, b = rows.get(y, (w, -1))
        rows[y] = (min(a, x), max(b, x))
    for k in range(count):
        y = 14 + hash2(k + seed, f * 3) % (h - 26)
        if y not in rows:
            continue
        side = -1 if k % 2 == 0 else 1
        x = (rows[y][0] if side < 0 else rows[y][1]) + side * (2 + hash2(k, f + 9) % 2)
        ln = 2 + hash2(k + seed, f + 4) % reach
        col = (W if lit >= 2 else G) if k % 3 else G
        for i in range(ln):
            if 0 < x + side * i < w - 1:
                c.px(x + side * i, y, col)
        if ln > 3 and 0 < x + side * (ln + 1) < w - 1:
            c.px(x + side * (ln + 1), y, G)


def _howl_wire(c, pts, mask, f, n, k, lit):
    """A cut wire: a black tangle where it runs through the static, GRAY with
    DARK joins outside, a frayed tip that sparks WHITE when awake."""
    ph = 2 * math.pi * f / n
    m = len(pts) - 1
    sway = [(round(x + (i / m) ** 2 * math.sin(ph + k * 1.9) * 1.6),
             round(y + (i / m) ** 2 * math.cos(ph + k * 1.9) * 1.1)) for i, (x, y) in enumerate(pts)]
    line = []
    for i in range(m):
        seg = _line_pts(*sway[i], *sway[i + 1])
        line += seg if not line else seg[1:]
    for i, (x, y) in enumerate(line):
        if (x, y) in mask:
            c.px(x, y, K)
        else:
            c.px(x, y, D if i % 4 == 0 else G)
    (tx, ty), (px_, py_) = line[-1], line[-3]
    dx, dy = tx - px_, ty - py_
    for (ax, ay) in ((dx - dy, dy + dx), (dx + dy, dy - dx)):   # two strands splay 45 degrees
        c.px(tx + (ax > 0) - (ax < 0), ty + (ay > 0) - (ay < 0), G)
    if lit >= 2 and (f + k) % 2 == 0:
        c.px(tx + (dx > 0) - (dx < 0), ty + (dy > 0) - (dy < 0), W)


def _howl_eyes(c, open_, col=W, pupil=True, wide=False):
    """open_ 0 is a 1 px slit, 1 half open, 2 full. A ring one step dimmer
    than the eye surrounds it, so it reads as glowing out of the dark face."""
    eye = set()
    if open_ == 0:                           # shut: a slanted lid line in a black band
        for side, (cx, cy) in zip((1, -1), HOWL_EYES):
            for (i, r) in _HOWL_SLIT:
                eye.add((cx + side * (i - 5), cy + r - 2))
        for (x, y) in eye:
            for dx in (-2, -1, 0, 1, 2):
                for dy in (-2, -1, 0, 1, 2):
                    c.px(x + dx, y + dy, K)
        for (x, y) in eye:
            c.px(x, y, col)
        return
    for side, (cx, cy) in zip((1, -1), HOWL_EYES):
        for r, row in enumerate(_HOWL_EYE):
            if abs(r - 2) > open_:
                continue
            for i, ch in enumerate(row):
                if ch == 'w':
                    eye.add((cx + side * (i - 5), cy + r - 2))
        if wide and open_ >= 2:              # flare: the eye stretches a row taller
            for i in range(3, 9):
                eye.add((cx + side * (i - 5), cy + 3))
    ring = set()
    for (x, y) in eye:
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                if (x + dx, y + dy) not in eye:
                    ring.add((x + dx, y + dy))
    for (x, y) in ring:
        c.px(x, y, G if col == W else D)
    for (x, y) in eye:
        c.px(x, y, col)
    if pupil and open_ >= 1 and col == W:
        for side, (cx, cy) in zip((1, -1), HOWL_EYES):
            c.px(cx + side, cy, K)
            c.px(cx + side, cy + 1, K)


def _howl_mouth(c, f, amt):
    """A jagged gap of static: a black maw with a ragged WHITE top lip and a
    GRAY bottom lip, jagged teeth of noise (WHITE root, GRAY tip, like the
    teeth on the crust) and a few torn scanlines, the swallowed voices,
    jumping inside."""
    cx, cy = HOWL_MOUTH
    hw = 9 + amt * 6
    gap = {}
    for x in range(int(cx - hw), int(cx + hw) + 2):
        u = (x + .5 - cx) / hw
        if abs(u) >= 1:
            continue
        half = 0.5 + amt * 4.5 * math.sqrt(1 - u * u)
        y0 = int(round(cy - half * 0.8)) + (x + f) % 2
        y1 = int(round(cy + half)) - (x + f + 1) % 2
        gap[x] = (y0, max(y0, y1))
    for x, (y0, y1) in gap.items():
        for y in range(y0 - 2, y1 + 3):
            c.px(x, y, K)
    for x, (y0, y1) in gap.items():
        c.px(x, y0 - 1, W)                     # the lips
        c.px(x, y1 + 1, G)
    for x, (y0, y1) in gap.items():
        open_ = y1 - y0
        j = (x - int(cx - hw)) % 3
        tl = (0, 1, 2 + hash2(x // 3, f * 7) % 2)[j] if open_ > 1 else 0
        for k in range(min(tl, open_ - 1)):     # teeth hanging from the top lip
            c.px(x, y0 + k, W if k == 0 else G)
        bl = (1 + hash2(x // 3, f * 7 + 3) % 2, 0, 0)[j] if open_ > 3 else 0
        for k in range(bl):                     # shorter ones rising from the bottom lip
            c.px(x, y1 - k, G)
    for k in range(2):                          # the voices: torn scanlines inside
        y = int(cy) + 1 + k * 2 - (f % 2)
        x0 = int(cx) - 6 + hash2(k, f * 5) % 6
        for x in range(x0, x0 + 2 + hash2(k + 3, f) % 5):
            if x in gap and gap[x][0] + 2 < y < gap[x][1] - 1:
                c.px(x, y, G if k else W)


def _howl_sparks(c, mask, w, h, f, seed, count, lit):
    """Flecks flung off the edge."""
    edge = sorted(p for p in mask if p[1] < h - 20 and any(
        (p[0] + dx, p[1] + dy) not in mask for dx, dy in ((1, 0), (-1, 0), (0, -1))))
    if not edge:
        return
    for k in range(count):
        x, y = edge[hash2(k + seed, f * 13) % len(edge)]
        ox = x + (-1 if x < w // 2 else 1) * (2 + hash2(k, f + 3) % 4)
        oy = y - 1 - hash2(k + 5, f) % 4
        if (ox, oy) not in mask:
            c.px(ox, oy, (W if lit >= 2 else G) if k % 2 == 0 else G)


def _howl_billows(c, mask, depth, billows, f, n, lit, sink=0.0, grow=0.0, seed=0, hollow=None, fade=46):
    """The lit tops of billows inside the heap: a black seam over a short
    crust of the same stripes as the outer edge, so the mass reads as roiling
    lumps. Skipped where it would cross the face."""
    ph = 2 * math.pi * f / n
    hi = W if lit >= 2 else G
    for (cx, cy, rx, ry, p) in billows:
        cx += math.cos(ph + p) * 0.9
        cy += sink + math.sin(ph + p) * 1.3 - grow / 2
        for x in range(int(cx - rx), int(cx + rx) + 1):
            u = (x + .5 - cx) / rx
            if abs(u) >= 0.9:
                continue
            ye = int(round(cy - ry * math.sqrt(1 - u * u)))
            if hollow:
                hx, hy, hrx, hry = hollow
                if ((x + .5 - hx) / hrx) ** 2 + ((ye + .5 - hy) / hry) ** 2 < 1.1:
                    continue
            if depth.get((x, ye - 1), 0) < 2:
                continue
            c.px(x, ye - 1, K)
            for k in range(3 if abs(u) < 0.6 else 2):
                y = ye + k
                if (x, y) not in mask:
                    break
                s = (y + f) % 3
                col = hi if s and ((x + f * 3 + y * 5 + seed) % 9) >= 2 else D
                if y >= fade and bayer(x, y) < (y - fade):
                    col = D if col in (W, G) else K
                c.px(x, y, col)


def _howl_heap(c, layers, w, h, f, n, lit, grow=0.0, sink=0.0, seed=0, hollow=None, fade=46,
               teeth=5, face_layer=-1):
    """Draw the billow layers back to front, each with teeth on its top edge.
    The back layer (when there is more than one) is dimmer: GRAY crust over
    a DARK body. Returns the union mask."""
    union = set()
    for i, blobs in enumerate(layers):
        back = i == 0 and len(layers) > 1
        m = _howl_mask(blobs, w, h, f, n, grow, sink, seed + i * 17)
        d = _howl_depth(m, h)
        _howl_body(c, m, d, f, 0 if back else lit, fade, seed + i,
                   hollow if i == face_layer % len(layers) else None, seam=i > 0)
        _howl_teeth(c, m, f, seed + 11 + i, G if back or lit < 2 else W, amount=teeth)
        union |= m
    return union


def _howl_flecks(c, mask, f, lit, count):
    """Chunks of static torn off the top, drifting up and dimming over the
    loop: two stripes, the lower one DARK."""
    for k, (x, y, w) in enumerate(_HOWL_FLECKS[:count]):
        t = (f + k) % 4
        yy = y - t * 2
        col = (W, W, G, D)[t] if lit >= 2 else (G, G, D, D)[t]
        for i in range(w - (t > 1)):
            if (x + i, yy) not in mask:
                c.px(x + i + t % 2, yy, col)
            if (x + i, yy + 1) not in mask and i < w - 1:
                c.px(x + i + t % 2, yy + 1, D)


def howl(mode, f):
    """96x64. sleep: dim and settled 2 px low, the eyes GRAY slits. wake:
    the eyes light and open, the heap rises and flares, the last frame is
    idle 0. idle: awake, eyes WHITE. speak: idle with the mouth gap."""
    n = 4
    lit, sink, grow, eyes, eye_col, wide, sparks, teeth, reach, pupil = 2, 0, 0.0, 2, W, False, 3, 5, 6, True
    mouth, flecks, strands = 0.0, 4, 8
    if mode == 'sleep':
        lit, sink, eyes, eye_col, sparks, teeth, reach, flecks = 1, 2, 0, G, 0, 3, 4, 2
    elif mode == 'wake':
        if f == 5:
            return howl('idle', 0)
        flecks, strands = (2, 4, 6, 6, 5)[f], (8, 8, 10, 14, 10)[f]
        lit, sink, grow, eyes, eye_col, wide, sparks, teeth, reach, pupil = (
            (1, 2, 0.0, 0, W, False, 1, 3, 4, False),
            (2, 1, 0.5, 1, W, False, 3, 5, 6, True),
            (2, 0, 1.2, 2, W, True, 6, 7, 8, True),
            (2, 0, 2.0, 2, W, True, 10, 9, 10, True),
            (2, 0, 1.0, 2, W, False, 5, 6, 7, True),
        )[f]
    elif mode == 'speak':
        mouth = (0.35, 0.8, 1.0, 0.6)[f]
        reach = 8
    ph = f % n
    c = C(HOWL_W, HOWL_H)
    ex = (HOWL_EYES[0][0] + HOWL_EYES[1][0]) / 2 + .5
    hollow = (ex, 35, 22, 12)
    mask = _howl_heap(c, (_HOWL_BLOBS,), HOWL_W, HOWL_H, ph, n, lit, grow, sink, seed=3, hollow=hollow,
                      teeth=teeth)
    _howl_billows(c, mask, _howl_depth(mask, HOWL_H), _HOWL_BILLOWS, ph, n, lit, sink, grow, seed=5,
                  hollow=hollow)
    for k, wire in enumerate(_HOWL_WIRES):
        _howl_wire(c, wire, mask, ph, n, k, lit)
    _howl_strands(c, mask, HOWL_W, HOWL_H, ph, 23, lit, count=strands, reach=reach)
    _howl_flecks(c, mask, ph, lit, flecks)
    c.outline(K)
    _howl_eyes(c, eyes, eye_col, pupil=pupil, wide=wide)
    if mouth:
        _howl_mouth(c, f, mouth)
    _howl_sparks(c, mask, HOWL_W, HOWL_H, ph, 31, sparks, lit)
    return c


_HOWL_FAR_BLOBS = (
    (16, 29, 11, 17, 0.0), (9, 18, 5, 4, 2.1), (23, 17, 5, 4, 4.2), (16, 13, 5, 3, 1.0),
)
HOWL_FAR_EYES = ((12, 16), (13, 16), (19, 16), (20, 16))


def howl_far(f):
    """32x24: the Howl far off, a smudge of static peeking up out of the dark
    with two WHITE eye pixels. The eyes dip to GRAY on frame 2."""
    c = C(32, 24)
    _howl_heap(c, (_HOWL_FAR_BLOBS,), 32, 24, f, 4, 1, seed=8, hollow=(16.5, 17, 7, 3), fade=18, teeth=4)
    c.outline(K)
    for (x, y) in HOWL_FAR_EYES:
        c.px(x, y, G if f == 2 else W)
    return c


def build_howl():
    sheet('howl', HOWL_W, HOWL_H, [
        A('sleep', [howl('sleep', f) for f in range(4)], 0.14,
          note='asleep, dim and settled 2 px low: the static churns, the edges flicker, the eyes are GRAY slits'),
        A('wake', [howl('wake', f) for f in range(6)], 0.1, loop=False,
          note='the slits light WHITE and open, the heap rises and flares outward (widest on 3), then settles. '
               'Frame 5 is idle 0'),
        A('idle', [howl('idle', f) for f in range(4)], 0.12,
          note='awake: two WHITE eyes glowing out of the dark face, the static churning, mouth closed'),
        A('speak', [howl('speak', f) for f in range(4)], 0.08,
          note=f'idle with a jagged black gap for a mouth, WHITE and GRAY teeth of noise on its lips, opening and '
               f'closing, centred on frame ({HOWL_MOUTH[0]:g}, {HOWL_MOUTH[1]})'),
    ], f'The Howl, the antagonist: the noise that once filled the line, every voice it swallowed fed back on '
       f'itself, grown vast underground. The same striped static as intro_static, heaped up in billows and '
       f'rising from below. Eye centres are frame {HOWL_EYES[0]} and {HOWL_EYES[1]} in every frame. The heap '
       f'runs off the bottom edge and fades to black there, so draw it with its bottom row on or below the floor '
       f'or a dark band. It faces the viewer, so it needs no mirrored copy.')
    sheet('howl_far', 32, 24, [
        A('watch', [howl_far(f) for f in range(4)], 0.2,
          note='a smudge of static peeking up out of the dark, the eyes two WHITE pixel pairs at frame x 12-13 '
               'and 19-20 on row 16. The eyes dip to GRAY on frame 2'),
    ], 'The Howl far off, watching from the dark, for cutscenes. Its bottom rows fade to black, so it can sit '
       'on a dark horizon or in a pit.')


# =================================================================== title key art

# The Spark on a cliff at the right of the title, looking out over the land
# toward the caller, the scarf streaming in the wind. She is drawn exactly as
# spark_close (twice game size), with the trailing flicker grown into a scarf.
# The cliff is a DARK promontory that sinks into black, so she is the only
# white thing in the lower half.

HERO = 64
HERO_FEET = (24, 59)       # bottom-centre body pixel; the ground's top row is one below it


def _hero_body(c, w=24, h=28, lift=0, visor='open', legs='stand'):
    """The close-up Spark facing left, feet on HERO_FEET, with spark_close's
    measures: white body, 1 px black outline, the nub on the back of the
    head, black visor with a GRAY pupil at its back end, black leg gaps and
    the antenna dot. lift raises it off the ground."""
    fx, fy = HERO_FEET
    bx = fx - w // 2
    by = fy + 1 - h - lift
    b = C(c.w, c.h)
    b.rect(bx, by, w, h, W)
    b.rect(bx + w, by + 2, 1, 6, W)            # the nub
    b.outline(K)
    vx = bx + 4
    if visor == 'open':
        b.rect(vx, by + 6, 8, 6, K)
        b.rect(vx + 6, by + 6, 2, 2, G)
    elif visor == 'turn':                      # a quarter turn toward us: the visor slides back 2 px
        b.rect(vx + 2, by + 6, 8, 6, K)
        b.rect(vx + 6, by + 6, 2, 2, G)
    elif visor == 'face':                      # looking out of the screen: visor and pupil centred
        b.rect(bx + 8, by + 6, 8, 6, K)
        b.rect(bx + 11, by + 8, 2, 2, G)
    elif visor == 'squint':                    # braced to jump: the visor narrows
        b.rect(vx, by + 8, 8, 4, K)
        b.rect(vx + 6, by + 8, 2, 2, G)
    elif visor == 'low':                       # diving: the visor slides forward and down
        b.rect(vx - 2, by + 7, 8, 6, K)
        b.rect(vx + 4, by + 7, 2, 2, G)
    elif visor == 'blink':                     # eyes shut: the visor closes to a 1 px line
        b.rect(vx, by + 9, 8, 1, K)
    if legs == 'stand':
        b.rect(bx + 4, by + h - 4, 6, 4, K)
        b.rect(bx + w - 10, by + h - 4, 6, 4, K)
    elif legs == 'sit':
        b.rect(bx + 4, by + h - 2, 6, 2, K)
        b.rect(bx + w - 10, by + h - 2, 6, 2, K)
    elif legs == 'air':                        # tucked: the back leg drawn up
        b.rect(bx + 4, by + h - 4, 6, 4, K)
        b.rect(bx + w - 10, by + h - 6, 6, 6, K)
    elif legs == 'reach':                      # pushing off: long thin leg gaps
        b.rect(bx + 4, by + h - 6, 4, 6, K)
        b.rect(bx + w - 8, by + h - 6, 4, 6, K)
    px_ = bx + w // 2 - 2                      # the antenna dot
    b.rect(px_ - 1, by - 11, 8, 8, K)
    b.rect(px_, by - 10, 6, 6, W)
    b.rect(px_ + 2, by - 8, 2, 2, K)
    c.paste(b, 0, 0)
    return bx, by


def _hero_pulse(c, bx, by, w, level):
    """Antenna pulse: small arcs either side of the dot, like the logo's
    antenna. 1 = GRAY arcs close in, 2 = DARK arcs further out."""
    px_ = bx + w // 2 - 2
    cy = by - 7
    if level == 1:
        pts, col = ((-3, -2), (-4, -1), (-4, 0), (-3, 1)), G
    else:
        pts, col = ((-5, -3), (-6, -2), (-6, -1), (-6, 0), (-6, 1), (-5, 2)), D
    for (dx, dy) in pts:
        c.px(px_ + dx, cy + dy, col)
        c.px(px_ + 5 - dx, cy + dy, col)


def _hero_scarf(c, x0, y0, phase, length=26, rise=0.15, amp=2.2, t0=8.0, t1=2.0, lam=20.0):
    """The trailing flicker grown into a scarf. It leaves the back of the
    body with its top row at (x0, y0), t0 px deep, and streams right,
    tapering to a t1 px point. A travelling wave (phase 0..1 per cycle)
    ripples it, and the falling face of each ripple is DARK so the cloth reads
    as folded. rise tilts it up (px per px). GRAY, DARK underside, black
    outline."""
    s = C(c.w, c.h)
    for i in range(length):
        u = i / max(1, length - 1)
        a = 2 * math.pi * (i / lam - phase)
        amp_i = amp * min(1.0, u * 1.4)
        yc = y0 + t0 / 2 - rise * i + amp_i * math.sin(a)
        t = t1 + (t0 - t1) * (1 - u) ** 0.9
        ya = int(math.floor(yc - t / 2 + 0.5))
        yb = ya + max(1, int(round(t)))
        fold = amp_i > 0.7 and math.cos(a) < -0.6
        for y in range(ya, yb):
            s.px(x0 + i, y, D if fold else G)
        if not fold and yb - ya >= 3:
            s.px(x0 + i, yb - 1, D)
    s.outline(K)
    c.paste(s, 0, 0)


def _hero_answer(c, bx, by, w):
    """The antenna answering the far caller: both rings of arcs at once and a
    GRAY halo round the dot, one step brighter than the idle pulse."""
    _hero_pulse(c, bx, by, w, 1)
    _hero_pulse(c, bx, by, w, 2)
    px_ = bx + w // 2 - 2
    for x in range(px_ - 1, px_ + 7):
        c.px(x, by - 12, G)
        c.px(x, by - 3, G)
    for y in range(by - 11, by - 3):
        c.px(px_ - 2, y, G)
        c.px(px_ + 7, y, G)


def title_hero(mode, f):
    c = C(HERO, HERO)
    if mode in ('blink', 'answer'):
        # idle frame for frame, so the game can swap either in without the scarf jumping
        h = 28 - (1 if f in (3, 4, 5) else 0)
        bx = HERO_FEET[0] - 12
        by = HERO_FEET[1] + 1 - h
        _hero_scarf(c, bx + 25, by + 5, f / 4.0)
        _hero_body(c, 24, h, visor='blink' if mode == 'blink' else 'open')
        if mode == 'answer':
            _hero_answer(c, bx, by, 24)
        elif f in (0, 1):
            _hero_pulse(c, bx, by, 24, f + 1)
        return c
    if mode in ('idle', 'look'):
        # look is idle with the visor turned toward us, frame for frame, so it
        # can stand in for one pass of idle without the scarf stopping
        h = 28 - (1 if f in (3, 4, 5) else 0)     # a breath: sinks 1 px for three frames
        bx = HERO_FEET[0] - 12
        by = HERO_FEET[1] + 1 - h
        visor = 'open' if mode == 'idle' else ('turn', 'face', 'face', 'face', 'face', 'face', 'face', 'turn')[f]
        _hero_scarf(c, bx + 25, by + 5, f / 4.0)
        _hero_body(c, 24, h, visor=visor)
        if f in (0, 1):
            _hero_pulse(c, bx, by, 24, f + 1)
    elif f == 0:        # leap: crouch, squashed wide and low, visor narrowed
        bx, by = HERO_FEET[0] - 13, HERO_FEET[1] + 1 - 22
        _hero_scarf(c, bx + 27, by + 4, 0.25, length=24, rise=0.3)
        _hero_body(c, 26, 22, visor='squint', legs='sit')
    elif f == 1:        # spring: stretched tall, off the lip, grit kicked back
        bx, by = HERO_FEET[0] - 10, HERO_FEET[1] + 1 - 32 - 3
        _hero_scarf(c, bx + 21, by + 5, 0.5, length=24, rise=-0.5, amp=1.5)
        _hero_body(c, 20, 32, lift=3, legs='reach')
        for (x, y, col) in ((31, 59, G), (34, 58, D), (37, 60, G), (29, 61, D), (39, 61, D), (33, 62, G)):
            c.px(x, y, col)
    elif f == 2:        # airborne: tucked, the scarf thrown out straight behind
        bx, by = HERO_FEET[0] - 12, HERO_FEET[1] + 1 - 26 - 8
        _hero_scarf(c, bx + 25, by + 5, 0.75, length=28, rise=0.05, amp=2.6)
        _hero_body(c, 24, 26, lift=8, legs='air')
    else:               # diving: long and low, the scarf streaming up behind
        bx, by = HERO_FEET[0] - 14, HERO_FEET[1] + 1 - 22 - 6
        _hero_scarf(c, bx + 29, by + 3, (0.0, 0.5)[f - 3], length=24, rise=(0.75, 0.85)[f - 3], amp=1.5)
        _hero_body(c, 28, 22, lift=6, visor='low', legs='air')
    return c


# ------------------------------------------------------------------ title_cliff

CLIFF_W, CLIFF_H = 160, 128
CLIFF_TIP = 30             # the level top of the tip, frame x 12 to 45: the Spark stands here
CLIFF_FILL_W = 32
CLIFF_FILL_TOP = 34        # the plateau from frame x 76 on, and the fill tile's top row
CLIFF_PERIOD_X = 96        # from here on the rock repeats every 32 px, like the fill
# the world-side face: (row, leftmost rock column), straight lines between
CLIFF_FACE = ((30, 13), (31, 12), (33, 12), (34, 14),           # the tip's blunt front
              (44, 36), (50, 38),                                # the wedge underside, a dark recess
              (51, 29), (53, 27), (61, 28), (63, 31), (66, 38),  # the second slab
              (67, 35), (69, 33), (84, 36), (87, 40), (90, 45),  # the third
              (91, 43), (93, 41), (127, 50))                     # the base, falling into the dark
# joints between the slabs: polylines, level with a 32 px wobble from x 96 on
CLIFF_SEAMS = (((14, 34), (36, 44), (70, 49), (96, 50)),
               ((38, 66), (70, 69), (96, 70)),
               ((45, 90), (80, 92), (96, 92)),
               ((50, 114), (96, 114)))


def _cliff_top(x):
    if x < 46:
        return CLIFF_TIP
    if x < 76:
        return CLIFF_TIP + int(round((CLIFF_FILL_TOP - CLIFF_TIP) * (1 - math.cos(math.pi * (x - 46) / 30.0)) / 2))
    return CLIFF_FILL_TOP


def _cliff_face(y):
    if y < CLIFF_FACE[0][0]:
        return None
    for (r0, x0), (r1, x1) in zip(CLIFF_FACE, CLIFF_FACE[1:]):
        if r0 <= y <= r1:
            return int(round(x0 + (x1 - x0) * (y - r0) / max(1, r1 - r0)))
    return CLIFF_FACE[-1][1]


def _cliff_seam(x, k):
    pts = CLIFF_SEAMS[k]
    if x >= pts[-1][0]:
        w = x % 32
        return pts[-1][1] + (1 if 6 <= w < 17 else 0) - (1 if 24 <= w < 28 else 0)
    if x < pts[0][0]:
        return None
    for (xa, ya), (xb, yb) in zip(pts, pts[1:]):
        if xa <= x <= xb:
            return int(round(ya + (yb - ya) * (x - xa) / max(1, xb - xa)))
    return None


def _cliff_slab(x, y):
    """0 = the top slab, 1 to 4 below each joint."""
    s = 0
    for k in range(len(CLIFF_SEAMS)):
        sy = _cliff_seam(x, k)
        if sy is not None and y > sy:
            s = k + 1
    return s


def _cliff_rock(c, x0, x1, xoff=0, top_of=_cliff_top, face_of=_cliff_face):
    """Rock for canvas columns x0..x1 (canvas x + xoff = piece column): DARK
    at the top, sinking into black by Bayer dither as it goes down, the slab
    fronts staying lit a little longer. Joints show near the face only, and
    black chips scatter through the DARK."""
    for x in range(x0, x1):
        X = x + xoff
        for y in range(top_of(X), CLIFF_H):
            fx = face_of(y)
            if fx is None or X < fx:
                continue
            into = X - fx
            dk = (y - 50) * 0.42 - max(0, 18 - into) * 0.45
            if _cliff_slab(X, y) == 0:
                dk = min(dk, 1.0)
            c.px(x, y, K if bayer(X, y) < max(0, min(16, int(dk))) else D)
    for k in range(len(CLIFF_SEAMS)):
        for x in range(x0, x1):
            X = x + xoff
            y = _cliff_seam(X, k)
            if y is None:
                continue
            fx = face_of(y)
            if fx is None or X < fx or c.get(x, y) == T:
                continue
            into = X - fx
            if into > 44 or (into > 30 and bayer(X, y) < into - 30):
                continue
            c.px(x, y, K)
            for d in (1, 2, 3):                # shadow under the slab above, deepest at the face
                if c.get(x, y + d) == D and (into < 22 - d * 5 or bayer(X, y + d) < 9 - d * 3):
                    c.px(x, y + d, K)
    # chips: one chance per 8x6 cell; the hash repeats every 32 px from x 96 on
    for x in range(x0 - 8, x1 + 8):
        X = x + xoff
        if X % 8:
            continue
        hx = X % 32 if X >= CLIFF_PERIOD_X else X + 1000
        for y in range(CLIFF_TIP, CLIFF_H, 6):
            h = hash2(hx, y)
            if h % 3:
                continue
            cx = X + (h >> 4) % 6
            cy = y + (h >> 8) % 5
            slope = ((h >> 14) % 3) - 1
            for i in range(2 + (h >> 12) % 3):
                px_ = (cx + i - 128) % 32 if (xoff and X >= 128) else cx + i - xoff
                py = cy + (i * slope) // 2
                if x0 <= px_ < x1 and c.get(px_, py) == D:
                    c.px(px_, py, K)
                    if i == 0 and cy < 60 and c.get(px_, py - 1) == D:
                        c.px(px_, py - 1, G)       # a catch-light on the upper lip
    return c


def _cliff_pole(c, px_):
    """The last pole of the old line, snapped short, twice the valley poles'
    size: its crossarm fallen against it and a cut cable end blown right."""
    base = _cliff_top(px_ + 3)
    top = base - 24
    c.rect(px_, top, 6, base - top + 1, D)
    c.rect(px_, top, 1, base - top + 1, G)
    c.rect(px_ + 5, top, 1, base - top + 1, K)
    for (dx, h, col) in ((0, 4, G), (1, 7, D), (2, 3, D), (3, 6, D), (4, 2, K), (5, 4, K)):
        c.rect(px_ + dx, top - h, 1, h, col)          # the splintered top
    c.px(px_ + 3, top + 9, K)
    c.rect(px_ - 3, top + 12, 3, 2, G)                  # a climbing peg
    bx, by = px_ + 5, top + 3
    for i in range(22):                                 # the crossarm, from its last bolt down to the grass
        x = bx - i
        y = by + int(round(i * 0.9))
        if y >= _cliff_top(x) - 1:
            break
        c.px(x, y - 1, G)
        c.px(x, y, D)
        c.px(x, y + 1, K)
    c.rect(bx - 1, by - 1, 2, 2, G)
    for i in range(16):                                 # the cut cable
        x = px_ + 6 + i
        y = top + 1 + int(round(2.5 * math.sin(i / 4.0) + i * 0.35))
        c.px(x, y, G if i < 10 else D)
    c.px(px_ + 22, top + 6, D)


def title_cliff_edge():
    c = C(CLIFF_W, CLIFF_H)
    _cliff_rock(c, 0, CLIFF_W)
    # rim light down the face: the front of each slab, never the undersides
    for y in range(CLIFF_TIP, CLIFF_H):
        fx = _cliff_face(y)
        prev = _cliff_face(y - 1) if y > CLIFF_TIP else fx
        if (prev is not None and fx > prev) or c.get(fx, y) == T:
            continue
        s = _cliff_slab(fx, y)
        if s <= 2:
            c.px(fx, y, G)
            if s == 0 or (s == 1 and bayer(fx + 1, y) < 8):
                c.px(fx + 1, y, G)
        else:
            c.px(fx, y, G if (s == 3 and bayer(fx, y) < 8) else D)
    # ledge tops: where a slab steps out, its top catches the light
    for (ly, n) in ((51, 10), (67, 6), (91, 4)):
        fx = _cliff_face(ly)
        for i in range(n):
            if c.get(fx + i, ly) != T:
                c.px(fx + i, ly, G if (i < n - 3 or bayer(fx + i, ly) < 8) else D)
    # the top surface: a GRAY rim, brightest on the tip
    for x in range(CLIFF_W):
        t = _cliff_top(x)
        if c.get(x, t) == T:
            continue
        c.px(x, t, G if (x < 50 or bayer(x, t) < max(4, 10 - (x - 50) // 12)) else D)
        if x < 46 and bayer(x, t + 1) < 10:
            c.px(x, t + 1, G)
    _cliff_pole(c, 118)
    c.outline(K)
    return c


def title_cliff_fill():
    """The plateau past the piece: a 32 px tile at the frame's top-left that
    repeats seamlessly and carries on from the piece's column 159."""
    c = C(CLIFF_W, CLIFF_H)
    t = C(CLIFF_FILL_W, CLIFF_H)
    _cliff_rock(t, 0, CLIFF_FILL_W, xoff=128, top_of=lambda X: CLIFF_FILL_TOP,
                face_of=lambda y: -999 if y >= CLIFF_FILL_TOP else None)
    for x in range(CLIFF_FILL_W):
        t.px(x, CLIFF_FILL_TOP, G if bayer(x + 128, CLIFF_FILL_TOP) < 4 else D)
    t.outline(K)
    c.paste(t, 0, 0)
    return c


def title_cliff_grass(f):
    """Tufts along the top, blown right. Thin DARK blades with GRAY tips and
    no outline. The sway walks through the tufts, so neighbours never move
    together."""
    c = C(CLIFF_W, CLIFF_H)
    tufts = ((44, 3, 5), (50, 6, 9), (60, 3, 6), (82, 5, 8), (100, 6, 10), (136, 5, 8), (150, 4, 6))   # all on the rock, none past the lip
    for n_t, (gx, n, hgt) in enumerate(tufts):
        for k in range(n):
            x = gx + k * 2 - n
            t = _cliff_top(x) - 1
            hh = hgt - (3 if k % 2 else 0) - (2 if k in (0, n - 1) else 0)
            sway = (0, 1, 2, 1)[(f + n_t + k // 3) % 4]
            for j in range(hh):
                u = (j + 1) / hh
                c.px(x + int(round((sway + 2.0) * u * u)), t - j,
                     G if (j == hh - 1 and (k + n_t) % 2 == 0) else D)
    return c


def build_keyart():
    sheet('title_hero', HERO, HERO, [
        A('idle', [title_hero('idle', f) for f in range(8)], 0.12,
          note='standing on the cliff tip looking out, the scarf streaming right in two ripples per loop, a 1 px '
               'breath on frames 3 to 5, and the antenna pulsing on frames 0 and 1 (GRAY arcs, then DARK arcs '
               'further out)'),
        A('look', [title_hero('look', f) for f in range(8)], 0.12, loop=False,
          note='the same frames as idle with the visor turned toward us: a quarter turn, six frames looking out '
               'of the screen, a quarter turn back. Play it in place of one pass of idle every 6 to 10 s, starting '
               'as idle wraps to frame 0, so the scarf never stops'),
        A('leap', [title_hero('leap', f) for f in range(5)], [0.1, 0.06, 0.1, 0.1, 0.1], loop=False,
          note='on START: crouch, spring (off the lip, grit kicked back), airborne and tucked, then two diving '
               'frames with the scarf streaming up. Holds the last frame. The frames already lift her 3 to 8 px. '
               'From the start of frame 2 (0.16 s) move the feet point too: with u = (t - 0.16) / 0.55 and '
               '(x0, y0) the feet point on the tip, x = x0 - 96u, y = y0 - 56u + 140u^2 (a short rise, then down '
               'into the valley). Close the circle on the feet point + (0, -18)'),
        A('blink', [title_hero('blink', f) for f in range(8)], 0.12,
          note='idle frame for frame with the visor shut to a 1 px line. Swap in for about 0.12 s every few '
               'seconds, using the idle frame the clock is on'),
        A('answer', [title_hero('answer', f) for f in range(8)], 0.12,
          note='idle frame for frame with the antenna answering: both rings of arcs and a GRAY halo round the '
               'dot. Flicker it against idle just after the far caller blinks, so the two lights talk'),
    ], 'The Spark on the title cliff, twice game size: the same body, visor, nub and antenna dot as spark_close, '
       'with the trailing flicker grown into a GRAY scarf that streams behind her. Faces left, toward the land. '
       'Anchor: feet at frame (24, 59), the bottom-centre body pixel, so top-left = (feet x - 24, feet y - 59) '
       'and the ground\'s top row is feet y + 1. On the cliff the feet go at screen (hx + 347, 171).')
    sheet('title_cliff', CLIFF_W, CLIFF_H, [
        A('edge', [title_cliff_edge()], 0,
          note='the promontory: a thick top slab jutting left to a blunt tip, a wedge of shadow under it, three '
               'slabs stepping down and back, rim light on the world side, the snapped last pole of the old line '
               'on the plateau. The tip\'s level top is frame row 30 from frame x 12 to 45'),
        A('grass', [title_cliff_grass(f) for f in range(4)], 0.16,
          note='tufts along the top blowing right. Same origin as edge: draw over it, before the Spark'),
        A('fill', [title_cliff_fill()], 0,
          note='the plateau carried on to the right: a 32x128 tile at the frame\'s top-left (the rest is empty). '
               'Draw it from the piece\'s right edge every 32 px until past the view\'s right edge. It joins the '
               'piece and itself seamlessly'),
    ], 'The cliff the Spark stands on, at the right of the title. DARK rock that sinks into black by row 90, '
       'with GRAY rim light, so she is the only white thing below the logo. Top-left = (hx + 320, 142) with '
       'hx = (view width - 480) / 2, so at 480 wide it fills x 320 to 479 and y 142 to 269: the tip at screen '
       'y 172, x hx + 332 to hx + 365. On wider views draw fill tiles from hx + 480 to the right edge. Draw '
       'after the poles and wire (it hides them where they pass behind it) and before the logo and menu.')


# =================================================================== World 4: Dead Air

# The deep telephone exchange under the whole network, where every cut line
# ends. No wind, no daylight, dead equipment everywhere: switching racks,
# cable trays, switchboards nobody answers. Eerie and quiet, never gory. The
# game tints each world's four greys, so everything here uses the same four.
# Danger reads from shape and motion, not colour: the turret's eye, the
# jagged bolt, the ghost's face and the crawling wall of static.

W4_LAMP_X = (3, 11)      # left column of each 4x4 dead lamp on a deep rack panel, 8 px apart
W4_LAMP_Y = 4            # their top row


def _w4_lamp(c, x, y, glint=G, lens=K):
    """4x4 indicator lamp: a round bezel round a dark lens, one glint on the glass."""
    c.art(x, y, ['.dd.', 'dkkd', 'dkkd', '.dd.'])
    c.rect(x + 1, y + 1, 2, 2, lens)
    if glint is not None:
        c.px(x + 1, y + 1, glint)


def _w4_tray(c, y0, n, steel, cut=None):
    """A cable tray from row y0: n cables of 2 px (a lit top with the twist of
    the strands, a dark underside), bound by a tie every 8 px, lying on a
    slotted side rail. It runs the full width, so trays join across tiles.
    cut is (cable, x0, x1): that cable is cut away between x0 and x1."""
    for k in range(n):
        y = y0 + k * 2
        hi, lo = (steel, D) if k % 2 == 0 else (D, K)
        c.rect(0, y, 16, 1, hi)
        c.rect(0, y + 1, 16, 1, lo)
        for x in range((k * 3 + 1) % 4, 16, 4):
            c.px(x, y + 1, K if k % 2 == 0 else D)
    for x in (6, 14):                           # cable ties: a band round the bundle
        c.rect(x, y0, 1, n * 2, D)
        c.px(x, y0, steel)
    if cut:
        k, x0, x1 = cut
        c.rect(x0, y0 + k * 2, x1 - x0 + 1, 2, K)
    ry = y0 + n * 2
    c.rect(0, ry, 16, 1, steel)                 # side rail: lit edge, slots below
    c.rect(0, ry + 1, 16, 1, D)
    for x in range(2, 16, 4):
        c.px(x, ry + 1, K)
    return ry + 2


def ground_w4(left=False, right=False, top=False, bottom=False, depth=0, alt=0):
    """Exchange floor: a riveted tread plate on top with a cable tray slung
    under it, a second tray in the row below, then rack panels with rows of
    dead indicator lamps. Every row below the top starts on the same steel
    rail and a post runs down the left of every tile, so any depth stacks on
    any other and every tile joins its neighbours."""
    c = C(16, 16)
    c.rect(0, 0, 16, 16, K)
    lit = depth < 2
    steel = G if lit else D
    if not top:                                 # the rail each row hangs from, with bolt holes
        c.rect(0, 0, 16, 2, D)
        c.rect(0, 0, 16, 1, steel)
        for x in (5, 13):
            c.px(x, 1, K)
    if top:
        _w4_tray(c, 7, 2, steel)
    elif depth == 1:
        _w4_tray(c, 4, 3, steel, cut=(1, 8, 10) if alt == 2 else None)
        if alt == 2:                            # a cut cable: one end droops out of the tray, frayed
            c.px(11, 6, G)                      # the far end, cut clean
            c.art(6, 6, ['gd', '.d', '.d', '.d', '.d', 'd.', 'd.', 'dg', 'g.'])
    else:
        # a rack panel: a row of dead indicator lamps over a row of label slots
        c.rect(2, 3, 14, 11, D)
        c.dith(2, 4, 14, 10, K, 3)
        c.rect(2, 13, 14, 1, K)
        for lx in W4_LAMP_X:
            _w4_lamp(c, lx, W4_LAMP_Y + 1)
            c.rect(lx, 10, 4, 1, K)
            c.rect(lx, 11, 4, 1, D)
        for x in (2, 15):                       # rivets at the panel's corners
            c.px(x, 3, D)
            c.px(x, 12, K)
        if alt == 1:                            # a panel pulled out: a dark slot, loose wires
            c.rect(10, 3, 6, 10, K)
            c.line(11, 3, 12, 9, D)
            c.line(14, 3, 13, 7, D)
            c.px(12, 10, G)
            c.px(13, 8, G)
    # a dark post down the left of every tile, bolt holes up it (like ground_w3)
    c.rect(0, 0, 2, 16, D)
    for y in range(3, 16, 5):
        c.px(1, y, K)
    if top:
        # deck: the white lip you stand on, then a tread plate with rivets
        c.rect(0, 0, 16, 1, W)
        c.rect(0, 1, 16, 1, G)
        c.rect(0, 2, 16, 3, D)
        for x in range(0, 16, 8):
            c.px(x + 2, 2, G)                   # raised treads, leaning in turn
            c.px(x + 3, 3, G)
            c.px(x + 6, 3, G)
            c.px(x + 7, 2, G)
        for x in (0, 8):                        # rivets where the plates butt
            c.px(x, 4, G)
            c.px(x + 1, 4, K)
        c.rect(0, 5, 16, 1, K)                  # shadow under the deck edge
        if alt == 1:                            # grating: slots through the plate
            c.rect(2, 2, 12, 3, D)
            for x in range(3, 13, 2):
                c.rect(x, 2, 1, 3, K)
        elif alt == 3:                          # a dead floor lamp set in the plate
            c.rect(9, 2, 5, 3, K)
            c.art(9, 2, ['.dd.', 'dkgd', '.dd.'])
    if left:
        for y in range(16):
            c.px(0, y, G if (y + (0 if top else 1)) % 3 else D)
    if right:
        c.rect(15, 0, 1, 16, K)
        c.dith(14, 0, 1, 16, K, 8)
    if top:
        if left:
            c.px(0, 0, T)
            c.px(0, 1, G)
        if right:
            c.px(15, 0, T)
            c.px(15, 1, G)
    if bottom:
        # the underside: a riveted flange, and a cable slung along beneath it
        c.rect(0, 12, 16, 2, D)
        c.rect(0, 12, 16, 1, steel)
        for x in (4, 12):
            c.px(x, 13, K)
        c.rect(0, 14, 16, 2, K)
        for x in range(16):
            c.px(x, 14 + (1 if 5 <= x <= 10 else 0), D)
        c.rect(0, 15, 5, 1, T)
        c.rect(11, 15, 5, 1, T)
        c.px(7, 15, G)
        if left:
            c.px(0, 14, T)
        if right:
            c.px(15, 14, T)
    return c


def block_w4(lip=True, kind=0):
    """Relay rack panel: a steel front between two rack ears with screw holes.
    Along its top a dead lamp and a label, below them a small perforated
    grille (or louvres, or a stencil)."""
    c = C(16, 16)
    c.rect(0, 0, 16, 16, D)
    c.rect(15, 0, 1, 16, K)
    c.rect(0, 15, 16, 1, K)
    c.rect(0, 0, 1, 15, G)
    oy = 2 if lip else 0
    for y in (2 + oy, 12):                      # the rack ears' screw holes
        for ex in (2, 13):
            c.px(ex, y, K)
    c.rect(3, oy, 1, 15 - oy, K)                # the front sits between the ears
    c.rect(12, oy, 1, 15 - oy, K)
    c.rect(4, oy, 8, 15 - oy, D)
    c.rect(4, oy, 8, 1, G if not lip else D)
    ty = 2 + oy                                 # the top row: dead lamp on the left, label beside it
    if kind == 2:
        c.art(4, ty - 1, ['.g.', 'gwg', '.g.'])  # the one live lamp on the panel
    else:
        c.art(4, ty - 1, ['.d.', 'dkd', '.g.'])
        c.px(5, ty, K)
    c.rect(8, ty, 3, 1, G)
    c.rect(8, ty + 1, 3, 1, K)
    gy = ty + 3
    if kind == 1:                               # louvres
        for k in range(3 if lip else 4):
            c.rect(5, gy + k * 2, 6, 1, K)
            c.rect(5, gy + k * 2 + 1, 6, 1, G if k == (2 if lip else 3) else D)
    elif kind == 3:                             # stencilled handset, standing on end
        c.art(6, gy, ['.gg', 'gg.', 'g..', 'gg.', '.gg'] if lip else ['.gg', 'gg.', 'g..', 'g..', 'gg.', '.gg'])
    else:                                       # perforated grille
        for yy in range(gy, 13):
            for xx in range(5, 11):
                if (xx + yy) % 2 == 0:
                    c.px(xx, yy, K)
    if lip:
        c.rect(0, 0, 16, 1, W)
        c.rect(0, 1, 16, 1, G)
        c.rect(15, 0, 1, 2, G)
    return c


# ------------------------------------------------------------------ Dead Air backdrop

W4_TRAY_Y = 24       # the overhead cable tray meets every piece edge at this row
W4_FLOOR_Y = 116     # the far floor's top row, the same across every piece


def _w4_far_tray(c, x0, x1, y, bundle=True):
    """A far ladder tray from x0 to x1 at row y: two rails, a rung wherever x
    is a multiple of 6 (so trays line up across piece edges), and a dithered
    bundle of cable lying in it."""
    c.rect(x0, y, x1 - x0 + 1, 1, D)
    c.rect(x0, y + 3, x1 - x0 + 1, 1, D)
    for x in range(x0, x1 + 1):
        if x % 6 == 0:
            c.rect(x, y, 1, 4, D)
        if bundle:
            if bayer(x, y - 1) < 10:
                c.px(x, y - 1, D)
            if bayer(x, y - 2) < 3:
                c.px(x, y - 2, D)


def _w4_floor(c):
    """The far floor: a hard edge at W4_FLOOR_Y, then a dither that thickens
    toward the bottom. The same in every piece."""
    c.rect(0, W4_FLOOR_Y, 96, 1, D)
    for y in range(W4_FLOOR_Y + 1, 128):
        for x in range(96):
            if bayer(x, y) < 2 + (y - W4_FLOOR_Y) // 2:
                c.px(x, y, D)


def _w4_sag(c, x0, y0, x1, y1, sag, col=D, thick=1, dith=16):
    """A hanging cable from (x0, y0) to (x1, y1), sagging `sag` px at the middle."""
    for x in range(min(x0, x1), max(x0, x1) + 1):
        u = (x - x0) / max(1, x1 - x0)
        y = int(round(y0 + (y1 - y0) * u + sag * 4 * u * (1 - u)))
        for t in range(thick):
            if bayer(x, y + t) < dith:
                c.px(x, y + t, col)


def _w4_frayed(c, x, y0, y1, glint=True):
    """A cut cable hanging straight down from y0, splayed into strands at y1."""
    c.rect(x, y0, 1, y1 - y0, D)
    c.px(x - 1, y1, D)
    c.px(x + 1, y1, D)
    c.px(x - 1, y1 + 1, D)
    c.px(x + 2, y1 + 1, D)
    c.px(x, y1 + 1, G if glint else D)


def _w4_rack(c, x, w, top, glints=()):
    """A far rack cabinet standing on the floor: side rails, a cap, and shelves
    of relays every 6 px. glints are (shelf, relay) that catch a little light."""
    c.rect(x, top, w, W4_FLOOR_Y - top, D)
    c.rect(x - 1, top, w + 2, 2, D)
    c.rect(x + 2, top + 3, w - 4, W4_FLOOR_Y - top - 5, K)
    for k, y in enumerate(range(top + 8, W4_FLOOR_Y - 3, 6)):
        c.rect(x + 2, y, w - 4, 1, D)           # the shelf
        for xx in range(x + 3, x + w - 3, 2):   # relays standing on it
            c.px(xx, y - 1, D)
            if bayer(xx, y - 2) < 8:
                c.px(xx, y - 2, D)
        for (sk, r) in glints:
            if sk == k:
                c.px(x + 3 + r * 2, y - 2, G)


def backdrop_w4(piece):
    """96x128 far shapes of the exchange, dark and dither only, with a few
    GRAY glints. Every piece carries the same overhead tray and the same floor
    line at its edges, so any piece joins any other."""
    c = C(96, 128)
    if piece == 0:    # a bank of switching racks, all one height, and a dimmer bank behind
        for x in range(1, 95, 11):
            for yy in range(58, W4_FLOOR_Y):
                for xx in range(x, x + 10):
                    if bayer(xx, yy) < (6 if xx in (x, x + 9) or yy < 60 else 3):
                        c.px(xx, yy, D)
        for i, (x, gl) in enumerate(((5, ((1, 2),)), (19, ()), (33, ((4, 1), (0, 3))), (47, ()),
                                     (68, ((2, 3),)), (82, ()))):
            _w4_rack(c, x, 12, 44, glints=gl)
            if i % 2 == 0:
                c.rect(x + 6, W4_TRAY_Y + 4, 1, 44 - W4_TRAY_Y - 4, D)   # a cable up to the tray
        c.rect(61, 40, 1, W4_FLOOR_Y - 40, D)    # a rolling ladder in the aisle
        c.rect(65, 44, 1, W4_FLOOR_Y - 44, D)
        for y in range(46, W4_FLOOR_Y, 5):
            c.rect(61, y, 5, 1, D)
        c.px(61, 39, D)
    elif piece == 1:  # drooping bundles of cut cable under the tray
        _w4_sag(c, 4, W4_TRAY_Y + 4, 42, W4_TRAY_Y + 4, 34, thick=2)
        _w4_sag(c, 30, W4_TRAY_Y + 4, 74, W4_TRAY_Y + 4, 52, thick=2)
        _w4_sag(c, 58, W4_TRAY_Y + 4, 92, W4_TRAY_Y + 4, 26, thick=2)
        _w4_sag(c, 14, W4_TRAY_Y + 4, 64, W4_TRAY_Y + 4, 64, thick=1, dith=10)
        for (x, y1, gl) in ((22, 70, True), (48, 96, False), (81, 62, True), (36, 52, False)):
            _w4_frayed(c, x, W4_TRAY_Y + 4, y1, gl)
        # a cable drum on the floor with a cut end trailing off it
        c.ellipse(70, W4_FLOOR_Y - 9, 9, 9, D)
        c.ellipse(70, W4_FLOOR_Y - 9, 6, 6, K)
        c.ellipse(70, W4_FLOOR_Y - 9, 2.5, 2.5, D)
        c.dith(62, W4_FLOOR_Y - 16, 16, 12, D, 5, only=K)
        _w4_sag(c, 70, W4_FLOOR_Y - 1, 90, W4_FLOOR_Y - 1, -2)
        c.px(91, W4_FLOOR_Y - 2, G)
        # a dead lamp hung on a flex
        c.rect(12, W4_TRAY_Y + 4, 1, 36, D)
        c.art(9, W4_TRAY_Y + 40, ['.ddddd.', 'ddddddd', '.dkkkd.', '..kgk..'])
    elif piece == 2:  # the dead switchboard wall: rows of jack holes, empty stools
        c.rect(6, 36, 84, 64, D)
        c.rect(5, 34, 86, 2, D)
        c.rect(10, 42, 76, 50, K)
        for y in range(44, 90, 4):
            for x in range(12, 85, 3):
                c.px(x, y, D)                    # jack bezel
                if hash2(x, y) % 23 == 0:
                    c.px(x, y + 1, G)            # a jack that catches a little light
            if (y // 4) % 3 == 0:
                c.dith(11, y + 2, 74, 1, D, 6)   # a strip of dead lamps
        for x in range(14, 86, 12):              # label plates along the cornice
            c.rect(x, 38, 8, 2, K)
        for (a, b, s) in ((18, 36, 12), (48, 57, 7), (66, 80, 10)):   # cords left plugged in
            _w4_sag(c, a, 60, b, 72, s, dith=12)
        c.rect(4, 100, 88, 3, D)                 # the desk and its legs
        c.dith(4, 100, 88, 1, G, 3)
        for x in (8, 86):
            c.rect(x, 103, 2, W4_FLOOR_Y - 103, D)
        for x in range(16, 84, 9):               # plugs waiting on the desk
            c.rect(x, 98, 2, 2, D)
        for sx in (26, 58):                      # two empty stools
            c.rect(sx, 106, 9, 2, D)
            c.rect(sx + 4, 108, 1, W4_FLOOR_Y - 108, D)
            c.rect(sx + 1, W4_FLOOR_Y - 1, 7, 1, D)
    else:             # a stair of cable trays climbing from the floor to the overhead run
        steps = ((2, 30, 98), (22, 50, 80), (42, 70, 62), (62, 90, 44))
        for i, (x0, x1, y) in enumerate(steps):
            _w4_far_tray(c, x0, x1, y)
            for sx in (x0 + 2, x1 - 2):          # stands down to the floor, further back
                for yy in range(y + 4, W4_FLOOR_Y):
                    if bayer(sx, yy) < (16 if i == 0 else 9):
                        c.px(sx, yy, D)
            if i:                                 # the cables drop a step at each bend
                px_ = steps[i - 1][1]
                c.line(x0 + 1, y - 1, px_ - 3, steps[i - 1][2] - 1, D)
                c.line(x0 + 2, y - 1, px_ - 2, steps[i - 1][2] - 1, D)
        c.rect(88, W4_TRAY_Y + 4, 1, 40, D)       # hangers from the overhead run to the top step
        c.rect(91, W4_TRAY_Y + 4, 1, 40, D)
        c.px(89, 60, G)
        _w4_frayed(c, 56, 66, 88, True)           # a cable cut off a step
    _w4_far_tray(c, 0, 95, W4_TRAY_Y)
    for x in range(0, 96, 24):
        c.px(x + 3, W4_TRAY_Y, G)                # a glint on the rail every 24 px
    _w4_floor(c)
    return c


# ------------------------------------------------------------------ relay turret

TURRET_EYE = (3, 8)       # centre of the eye lens, box at rest
TURRET_MUZZLE = (0, 8)    # the bolt leaves here, just in front of the eye


def _turret_box(eye, lens_glow=False):
    """The turret body on its own canvas: a riveted steel box with a hood over
    the eye and cooling slits. eye is the lens colours (ring, centre)."""
    b = C(16, 16)
    b.rect(4, 2, 11, 11, D)
    b.rect(4, 2, 11, 1, G)                    # lit top edge
    b.rect(14, 3, 1, 10, K)                   # shadowed back
    b.rect(4, 12, 11, 1, K)
    b.rect(1, 3, 5, 2, D)                     # the hood jutting over the eye
    b.rect(1, 3, 5, 1, G)
    b.px(1, 4, K)
    for (x, y) in ((6, 4), (12, 4), (6, 10), (12, 10)):
        b.px(x, y, G)
        b.px(x + 1, y + 1, K)
    for y in (6, 8):                          # cooling slits
        b.rect(8, y, 4, 1, K)
        b.rect(8, y + 1, 4, 1, G if y == 8 else D)
    # the eye: a round socket on the left face
    cx, cy = TURRET_EYE
    b.art(cx - 2, cy - 2, ['.ddd.', 'dkkkd', 'dkkkd', 'dkkkd', '.ddd.'])
    ring, mid = eye
    b.rect(cx - 1, cy - 1, 3, 3, ring)
    b.px(cx, cy, mid)
    if lens_glow:                             # the socket rim catches the glow
        for (x, y) in ((cx - 1, cy - 2), (cx, cy - 2), (cx + 1, cy - 2), (cx - 2, cy), (cx - 1, cy + 2),
                       (cx, cy + 2), (cx + 1, cy + 2)):
            b.px(x, y, G)
    b.outline(K)
    return b


def turret(mode, f=0):
    """16x16 relay turret bolted to the floor, facing left: one round eye on
    its left face, which the bolt leaves from. The mount stays put, and the
    box kicks 1 px back (right) when it fires."""
    c = C(16, 16)
    # the mount plate, bolted down
    c.rect(3, 13, 13, 3, D)
    c.rect(3, 13, 13, 1, G)
    c.rect(3, 15, 13, 1, K)
    for x in (5, 13):
        c.px(x, 14, G)
        c.px(x + 1, 14, K)
    c.outline(K)
    dx, glow = 0, False
    if mode == 'idle':
        eye = ((K, D), (K, G))[f]
    elif mode == 'tell':
        eye = ((D, G), (G, W), (W, W))[f]
        glow = f == 2
    else:
        eye = ((W, W), (G, W))[f]
        dx, glow = 1, f == 0
    c.paste(_turret_box(eye, glow), dx, 0)
    ex, ey = TURRET_EYE[0] + dx, TURRET_EYE[1]
    if mode == 'idle' and f == 0:
        c.px(ex - 1, ey - 1, D)               # a faint glint on the dead glass
    if mode == 'tell' and f == 2:
        c.px(0, ey, G)                         # the glow spills out in front
    if mode == 'fire':
        # the recoil flash: a jagged star of signal at the muzzle
        pts = (((0, ey, W), (1, ey, W), (1, ey - 1, W), (1, ey + 1, W), (0, ey - 2, G), (0, ey + 2, G),
                (1, ey - 3, D), (1, ey + 3, D), (2, ey - 2, G), (2, ey + 2, G)),
               ((0, ey, G), (1, ey - 1, G), (1, ey + 1, D), (0, ey - 3, D), (0, ey + 2, D)))[f]
        for (x, y, col) in pts:
            c.px(x, y, col)
    return c


# ------------------------------------------------------------------ the bolt

BOLT_HEAD = (1, 3)       # the centre of the bright tip, travelling left
BOLT_TIP = ['.w.', 'www', '..w']                       # a twisted, jagged tip, 3 px tall
BOLT_Y = (3, 3, 2, 2, 3, 4, 4, 3, 2, 2, 3, 4, 4)       # the zigzag's row for x = 3 to 15
BOLT_GAPS = ({9, 13}, {8, 11, 14}, {10, 13, 15}, {9, 12})


def bolt_shot(mode, f=0):
    """16x8 shot of signal travelling left: a bright jagged tip 3 px tall and
    a thin zigzag tail of short runs that breaks up and flickers. pop: it
    bursts into dots against a wall on its left."""
    c = C(16, 8)
    if mode == 'fly':
        hx, hy = BOLT_HEAD
        tip = BOLT_TIP if f % 2 == 0 else [r[::-1] for r in BOLT_TIP[::-1]]
        c.art(hx - 1, hy - 1, tip)
        for i, y in enumerate(BOLT_Y):
            x = 3 + i
            if x in BOLT_GAPS[f]:
                continue
            if x > 11 and (x + f) % 2:
                y += -1 if y > 3 else 1      # the far tail jitters
            col = W if x < 5 else G if x < 10 else D
            c.px(x, y, col)
        c.px(5 + f % 2, 3 + (1 if f < 2 else -1), G)   # a spark jumping off the first kink
        c.outline(K)
    else:
        spots = (((1, 3, W), (0, 3, W), (2, 3, W), (1, 2, W), (1, 4, W), (0, 1, G), (3, 1, G), (0, 5, G),
                  (3, 5, G), (4, 3, G), (6, 2, D), (7, 4, D)),
                 ((2, 1, W), (1, 5, W), (4, 2, G), (4, 5, G), (0, 3, G), (6, 3, G), (3, 0, D), (2, 7, D),
                  (8, 3, D)),
                 ((4, 0, G), (3, 6, G), (7, 1, D), (7, 5, D), (1, 7, D), (9, 3, D)))[f]
        for (x, y, col) in spots:
            c.px(x, y, col)
        if f == 0:
            c.outline(K)
    return c


# ------------------------------------------------------------------ echo, the static ghost

ECHO_EYES = ((4, 5), (7, 5))     # top pixel of each 1x2 eye, facing left, at rest
ECHO_MOUTH = (5, 8)              # top-left of the 2x2 open mouth
ECHO_MITT = ['w.w', 'www', 'www', '.g.']   # a hand held up, fingers first; both hands use it


def _echo_body(f, dx=0, dy=0, low=0, n=4, crown=True):
    """The ghost before its outline: a round GRAY head with a WHITE crown, a
    ragged hem, three tail wisps that trail off to the lower right and wave,
    one torn scanline and a couple of specks. Returns a canvas."""
    c = C(16, 16)
    ph = 2 * math.pi * f / n
    cx, cy, r = 7.5 + dx, 6.5 + dy + low, 5.4 - low * 0.4
    body = set()
    for y in range(16):
        for x in range(16):
            if math.hypot(x + .5 - cx, (y + .5 - cy) * (1.0 + low * 0.08)) <= r:
                body.add((x, y))
    # ragged hem: the bottom edge frays, a different column each frame
    for x in range(16):
        col = [y for (xx, y) in body if xx == x]
        if not col:
            continue
        bot = max(col)
        if (x + f) % 3 == 0:
            body.discard((x, bot))
        elif (x * 2 + f) % 5 == 0 and bot < 15:
            body.add((x, bot + 1))
    for (x, y) in body:
        c.px(x, y, G)
    # the crown catches the light
    for x in range(int(4 + dx), int(11 + dx) if crown else 0):
        top = min((y for (xx, y) in body if xx == x), default=None)
        if top is not None:
            c.px(x, top, W)
            if 8 + dx <= x <= 9 + dx:
                c.px(x, top + 1, W)
    # tail wisps: tapering, waving, DARK toward the tips, broken near the end
    wisps = (((11.5, 8.5), (14.0, 9.5), (15.6, 11.0), 1.2), ((10.5, 10.5), (13.0, 12.0), (14.8, 13.6), 1.0),
             ((7.5, 11.5), (9.0, 13.0), (10.6, 14.2), 0.7))
    for k, (p0, p1, p2, amp) in enumerate(wisps):
        for i in range(10):
            t = i / 9
            x = (1 - t) ** 2 * p0[0] + 2 * t * (1 - t) * p1[0] + t * t * p2[0] + dx
            y = (1 - t) ** 2 * p0[1] + 2 * t * (1 - t) * p1[1] + t * t * p2[1] + dy + low
            y += math.sin(ph + t * 3 + k) * amp * t
            xi, yi = int(round(x - .5)), int(round(y - .5))
            if t > 0.75 and (i + f + k) % 3 == 0:
                continue                         # the tip breaks up
            c.px(xi, yi, G if t < 0.5 else D)
            if k < 2 and t < 0.55:
                c.px(xi, yi + 1, G if t < 0.3 else D)   # the wisps are thicker at the root
    # one torn scanline crawling down the back of the body
    ty = int(cy) + 3 + (0, 1, 2, 1)[f % 4]
    for x in range(int(cx) + 1, 16):
        if c.get(x, ty) == G and (x + f) % 3 != 0:
            c.px(x, ty, D)
    # specks of static: one on the body, one shed off a wisp
    sx, sy = int(cx) + 3 + f % 2, int(cy) + 1 + (f * 3) % 3
    if c.get(sx, sy) == G:
        c.px(sx, sy, W)
    return c


def _echo_face(c, dx=0, dy=0):
    for (ex, ey) in ECHO_EYES:
        c.rect(ex + dx, ey + dy, 1, 2, K)
    mx, my = ECHO_MOUTH
    c.rect(mx + dx, my + dy, 2, 2, K)


def echo(mode, f=0):
    """16x16 ghost of static, facing left. drift: face out, O mouth, tail
    wisps trailing, bobbing. hide: both wispy hands over its face,
    shivering. knocked: it tears apart and scatters into specks."""
    if mode == 'drift':
        dy = (0, -1, -1, 0)[f]
        c = _echo_body(f, 0, dy)
        c.px(1, 8 + dy, G)                      # a little arm held out in front
        c.px(2, 8 + dy, G)
        c.px(1, 7 + dy + f % 2, G)
        c.outline(K)
        _echo_face(c, 0, dy)
        return c
    if mode == 'hide':
        dx = (0, 1, 0, -1)[f]
        c = _echo_body(f, dx, 0, low=1, crown=False)
        for k, hx in enumerate((2, 7)):         # two pale hands over the eyes, body showing between
            rows = list(ECHO_MITT)
            if (f + k) % 2:                     # the fingers tremble
                rows[0] = '.w.'
            c.art(hx + dx, 6, rows)
        c.outline(K)
        return c
    # knocked: the shape tears into slices, then scatters into specks of static
    c = C(16, 16)
    base = _echo_body(0)
    _echo_face(base)
    pts = [(x, y, base.get(x, y)) for y in range(16) for x in range(16) if base.get(x, y)[3]]
    if f == 0:
        for (x, y, col) in pts:
            sh = (1, 1, -1, -1, 2, 2, -1, -1)[(y // 2) % 8]
            c.px(x + sh, y, D if col == G and (x + y) % 4 == 0 else col)
        c.outline(K)
        return c
    keep = (3, 4, 6, 10)[f - 1]
    spread = (1.35, 1.8, 2.25, 2.6)[f - 1]
    for (x, y, col) in pts:
        h = hash2(x * 3 + 1, y * 5 + 2)
        if h % keep:
            continue
        nx = int(round(8 + (x + .5 - 8) * spread + (h % 3 - 1)))
        ny = int(round(8 + (y + .5 - 8) * spread - f))
        speck = ((W if h % 8 == 0 else G) if col != D else D, G if h % 3 == 0 else D,
                 G if h % 5 == 0 else D, D)[f - 1]
        c.px(nx, ny, speck)
        if f == 1 and h % 2 == 0:
            c.px(nx + 1, ny, D)                 # torn scanline bits
    return c


# ------------------------------------------------------------------ the wall of static

SW_ROWS = 'BKMDBDKMBKDMBDKD'     # each row's look: Bright, Mid, Dark, blacK scan gap. Lit rows sit between dark ones
SW_RUNS = {                      # per look: (colour, shortest run, longest run), taken in turn
    'B': ((G, 4, 8), (D, 1, 3), (G, 2, 5), (K, 1, 2)),
    'M': ((G, 2, 4), (D, 2, 5), (G, 1, 3), (D, 3, 5)),
    'D': ((D, 4, 8), (G, 1, 2), (D, 2, 5), (K, 1, 2)),
    'K': ((K, 3, 7), (D, 2, 4)),
}
SW_REACH = {'B': 2, 'M': 1, 'D': -1, 'K': -2}   # how far each look juts out past a wall's front


def _sw_row(y):
    """A row of static as 16 colours: runs of each colour in turn, their
    lengths and starting point picked by a hash of the row, wrapped round
    the 16 px so it tiles."""
    runs = SW_RUNS[SW_ROWS[y]]
    row = []
    k = 0
    while len(row) < 16:
        col, lo, hi = runs[k % len(runs)]
        row += [col] * (lo + hash2(k * 7 + 3, y * 11 + 5) % (hi - lo + 1))
        k += 1
    row = row[:16]
    if row[15] == runs[0][0]:
        row[15] = runs[1][0]                   # keep a break where the row wraps
    off = hash2(y, 29) % 16
    return row[off:] + row[:off]


SW_ROW_COLS = [_sw_row(y) for y in range(16)]


def _sw_dir(y):
    return 1 if hash2(y % 16, 9) % 2 else -1


def _sw_px(x, y, f):
    """The colour of the living static at (x, y) on frame f, wrapped to 16 px
    both ways. Each row crawls 4 px a frame, left or right by a hash, so it
    comes round to where it started after 4 frames."""
    x, y = x % 16, y % 16
    col = SW_ROW_COLS[y][(x - _sw_dir(y) * 4 * f) % 16]
    if col == G and hash2(x * 5 + f * 31, y * 3 + f * 17) % 19 == 0:
        col = W                               # flecks that jump every frame
    return col


def _sw_edge(a, f, mid):
    """Where the solid static ends at position a along its edge on frame f:
    three slow waves plus a per-position kick. Wraps every 16 px."""
    ph = f * math.pi / 2
    e = (mid + 0.8 * math.sin(2 * math.pi * a / 16 + ph + 0.7)
         + 1.2 * math.sin(2 * math.pi * 2 * a / 16 - ph + 2.1)
         + 0.9 * math.sin(2 * math.pi * 3 * a / 16 + 2 * ph + 4.0))
    return e + (hash2(a, f + 3) % 3) - 1


def static_wall(mode, f):
    """16x16 living static. body tiles both ways. edge_up is the ragged crest
    of a rising wall: solid below, torn streaks floating above it, clear at the
    top. edge_right is the ragged front of a wall moving right: the lit rows
    jut out further than the dark ones, streak heads lead, clear beyond."""
    c = C(16, 16)
    for y in range(16):
        for x in range(16):
            col = _sw_px(x, y, f)
            if mode == 'body':
                c.px(x, y, col)
                continue
            if mode == 'edge_up':
                top = max(6, min(11, int(round(_sw_edge(x, f, 8.5)))))
                d = y - top                           # rows below the crest
                if d < 0:
                    # above the crest only lit streaks survive, torn into pieces
                    u = (x - _sw_dir(y) * 4 * f) % 16
                    reach = 1 + hash2(u // 3, y * 5 + 1) % 4
                    if col in (G, W) and -d <= reach:
                        c.px(x, y, col if -d < reach else D)
                    continue
                if d == 0:
                    col = W if hash2(x + y * 16, f) % 4 == 0 else G   # the lit rim of the crest
                elif d == 1 and col in (D, K):
                    col = G if col == D else D
            else:
                front = int(round(_sw_edge(y, f, 8.5) + SW_REACH[SW_ROWS[y]]))
                front = max(5, min(12, front))
                d = front - x                         # columns behind the front
                if d < 0:
                    # one more torn piece of a lit row a little ahead of the front
                    if SW_ROWS[y] in 'BM' and 2 <= -d <= 3 + hash2(y, f) % 2 and col in (G, W) and x < 15:
                        c.px(x, y, G if -d == 2 else D)
                    continue
                if d == 0:
                    col = W if SW_ROWS[y] == 'B' else G if SW_ROWS[y] == 'M' else col
            c.px(x, y, col)
    return c


# ------------------------------------------------------------------ the heart of the line

RING_W, RING_H = 96, 64
RING_CORE = (48, 29)             # centre of the cracked glass core
RING_CORE_R = 13.5               # 27 px across
RING_R = 19                      # the Sparks sit on a circle 38 px across
RING_ANGLES = (180, 225, 270, 315, 0, 45, 90, 135)   # clockwise from the empty place on the left
RING_PLACES = [(RING_CORE[0] + int(round(RING_R * math.cos(math.radians(a)))),
                RING_CORE[1] + int(round(RING_R * math.sin(math.radians(a))))) for a in RING_ANGLES]
RING_EMPTY = RING_PLACES[0]      # where the player's Spark joins
RING_CRACK = ((48, 16), (46, 20), (49, 24), (47, 28), (50, 32), (48, 36), (49, 42))
RING_BRANCHES = (((47, 28), (43, 31)), ((50, 32), (54, 34)), ((49, 24), (52, 21)))
RING_LEAKS = ((48, 14, 0, -1), (49, 44, 0, 1), (45, 16, -1, -1), (52, 19, 1, -1))   # (x, y, dx, dy) off the ends


def _ring_spark(c, cx, cy, col=W, tip=W, eyes=True, ghost=False):
    """A small Spark of the line centred on (cx, cy): a 7x5 body rounded at
    every corner, a little bigger than a Pip, two dot eyes and a one-pixel
    antenna. ghost draws only a faint dotted outline: the empty place."""
    x0, y0 = cx - 3, cy - 2
    if ghost:
        for (x, y) in ((x0 + 1, y0 - 1), (x0 + 3, y0 - 1), (x0 + 5, y0 - 1), (x0 - 1, y0 + 1),
                       (x0 - 1, y0 + 3), (x0 + 7, y0 + 1), (x0 + 7, y0 + 3), (x0 + 1, y0 + 5),
                       (x0 + 3, y0 + 5), (x0 + 5, y0 + 5)):
            c.px(x, y, D)
        return
    s = C(RING_W, RING_H)
    s.rect(x0 + 1, y0, 5, 5, col)
    s.rect(x0, y0 + 1, 7, 3, col)
    if eyes:
        s.px(cx - 1, cy, K)
        s.px(cx + 1, cy, K)
    s.px(cx, y0 - 1, G if col == W else col)
    s.px(cx, y0 - 2, tip)
    s.outline(K)
    c.paste(s, 0, 0)


def _ring_crack_pts():
    crack = set()
    for (x0, y0), (x1, y1) in zip(RING_CRACK, RING_CRACK[1:]):
        crack |= set(_line_pts(x0, y0, x1, y1))
    for (p0, p1) in RING_BRANCHES:
        crack |= set(_line_pts(*p0, *p1))
    return crack


def _ring_core(c, state, f):
    """The glass core. state: 'cracked' (dark glass, the crack glowing dimly
    and static seeping out of it), 'flare' (the crack full of light as it
    seals), 'whole' (sealed, lit from inside)."""
    cx, cy = RING_CORE
    r = RING_CORE_R
    disc = {(x, y) for y in range(RING_H) for x in range(RING_W)
            if math.hypot(x + .5 - cx, y + .5 - cy) <= r}
    wall = {(x, y) for (x, y) in disc if any((x + dx, y + dy) not in disc
                                             for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))}
    whole = state == 'whole'
    for (x, y) in disc:
        c.px(x, y, K)
    for (x, y) in disc - wall:
        d = math.hypot(x + .5 - cx, y + .5 - cy)
        if whole:                              # lit from inside: brightest at the heart
            if bayer(x, y) < max(0, int(17 - d * 1.25)):
                c.px(x, y, G)
            if d < 2.6 or (d < 4.2 and bayer(x, y) < 8):
                c.px(x, y, W)
        else:                                  # dark glass, a slow swirl of trapped static
            a = math.atan2(y + .5 - cy, x + .5 - cx)
            if (a * 2 + d * 0.45 - f * 0.9) % (2 * math.pi) < 1.1 and bayer(x, y) < 5 and d > 3:
                c.px(x, y, D)
    for (x, y) in wall:                        # the glass wall, lit from the top left
        up = (x + .5 - cx) + (y + .5 - cy) < 0
        c.px(x, y, W if whole else (G if up else D))
    c.outline(K)
    for (x, y) in ((cx - 9, cy - 5), (cx - 9, cy - 4), (cx - 8, cy - 7), (cx - 7, cy - 8), (cx - 6, cy - 9),
                   (cx - 5, cy - 9), (cx - 7, cy - 3)):
        c.px(x, y, W)                          # shine on the glass
    c.px(cx + 8, cy + 6, W if whole else G)
    if whole:
        return
    crack = _ring_crack_pts()
    if state == 'flare':
        for (x, y) in crack:
            for (dx, dy) in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                if (x + dx, y + dy) in disc and (x + dx, y + dy) not in crack:
                    c.px(x + dx, y + dy, G)
        for (x, y) in crack:
            c.px(x, y, W)
        return
    # cracked: a dim glow in the split, brighter at the kinks
    main = set()
    for (x0, y0), (x1, y1) in zip(RING_CRACK, RING_CRACK[1:]):
        main |= set(_line_pts(x0, y0, x1, y1))
    for (x, y) in crack:
        c.px(x, y, G if (x, y) in main else D)
    for (x, y) in RING_CRACK[1:-1]:
        c.px(x, y, W if (x + y + f) % 4 == 0 else G)
    for (x, y) in RING_CRACK[::2]:
        c.px(x, y + 1, G)
    # static seeping out: torn dashes leave the crack, drift out and up, and fade
    for k, (x, y) in enumerate(sorted(crack)[1::4]):
        t = (f + k) % 4
        side = -1 if k % 2 else 1
        if t == 3:
            continue
        sx, sy = x + side * (2 + t * 2), y - t
        for i in range(2 if t < 2 else 1):
            c.px(sx + side * i, sy, (G, G, D)[t] if i == 0 else D)
    for k, (x, y, dx, dy) in enumerate(RING_LEAKS):   # and out of the ends of the crack
        t = (f + k * 2) % 4
        if t < 3:
            c.px(x + dx * t, y + dy * t, G if t == 0 else D)


def _ring_stand(c):
    """The insulator pin the core sits on, its base plate on the floor, and the
    cut lines that run in along the floor and end here."""
    cx = RING_CORE[0]
    top = RING_CORE[1] + 13
    c.rect(cx - 5, top, 10, 3, D)              # collar
    c.rect(cx - 5, top, 10, 1, G)
    c.rect(cx - 3, top + 3, 6, 58 - top - 3, D)   # pin
    c.rect(cx - 3, top + 3, 1, 58 - top - 3, G)
    c.rect(cx + 2, top + 3, 1, 58 - top - 3, K)
    c.rect(cx - 16, 58, 32, 6, D)               # base plate
    c.rect(cx - 16, 58, 32, 1, G)
    c.rect(cx - 16, 63, 32, 1, K)
    for x in (cx - 13, cx - 6, cx + 5, cx + 12):
        c.px(x, 60, G)
        c.px(x + 1, 61, K)
    for side in (-1, 1):                       # cut lines running in along the floor
        x0 = 6 if side < 0 else 89
        x1 = cx - 17 if side < 0 else cx + 16
        for x in range(min(x0, x1), max(x0, x1) + 1):
            c.px(x, 61, D)
            c.px(x, 62, K)
            if x % 5 == 0:
                c.px(x, 61, G)
        c.px(x0 - side, 60, G)                  # frayed ends
        c.px(x0 - side, 62, D)
    c.outline(K)


def _ring_circle(c, upto=None, col=G, head=W, faint=False):
    """The circle the Sparks sit on. faint draws it as a dark dither. upto is
    how far round the light has run, in degrees clockwise from the empty place."""
    cx, cy = RING_CORE
    pts = []
    for i in range(0, 720):
        a = 180 + i / 2
        x = int(math.floor(cx + RING_R * math.cos(math.radians(a))))
        y = int(math.floor(cy + RING_R * math.sin(math.radians(a))))
        if not pts or pts[-1][:2] != (x, y):
            pts.append((x, y, i / 2))
    for (x, y, deg) in pts:
        if c.get(x, y) not in (T, K):
            continue
        if faint:
            if bayer(x, y) < 6:
                c.px(x, y, D)
        elif upto is None or deg <= upto:
            c.px(x, y, head if upto is not None and upto - 20 < deg <= upto else col)


def line_heart(mode, f):
    """96x64: the heart of the line, the goal of the last level. A cracked glass
    core on an insulator pin, seven small Sparks round it and one empty place
    on the left where the player joins. Its base sits on the frame's bottom row."""
    c = C(RING_W, RING_H)
    _ring_stand(c)
    lit_sparks = 0                               # how many places, from the empty one, are lit
    core, circle, rays = 'cracked', 'faint', 0
    if mode == 'close':
        core = ('cracked', 'cracked', 'cracked', 'flare', 'whole', 'whole')[f]
        lit_sparks = (1, 3, 6, 8, 8, 8)[f]
        circle = (None, 90, 225, 360, 'full', 'full')[f]
        rays = (0, 0, 0, 0, 3, 6)[f]
    elif mode == 'lit':
        core, lit_sparks, circle, rays = 'whole', 8, 'full', (3, 5, 4, 6)[f]
    _ring_core(c, core, f)
    if circle == 'faint':
        _ring_circle(c, faint=True)
    elif circle == 'full':
        _ring_circle(c)
    elif circle is not None:
        _ring_circle(c, upto=circle)
    for i, (px_, py_) in enumerate(RING_PLACES):
        if i == 0 and mode == 'wait':
            _ring_spark(c, px_, py_, ghost=True)  # the empty place: a faint dotted outline
            continue
        if i < lit_sparks:
            _ring_spark(c, px_, py_, W, tip=W if (mode != 'lit' or (f + i) % 2 == 0) else G)
        else:                                     # weak: GRAY, one or two dipping to DARK
            weak = (i + f) % 4 == 0 or (i * 3 + f) % 7 == 0
            _ring_spark(c, px_, py_, D if weak else G, tip=D if weak else G, eyes=not weak or f % 2 == 0)
    if mode == 'close' and f == 0:               # the new Spark arrives with a flash
        ex, ey = RING_EMPTY
        for (dx, dy) in ((-6, 0), (-5, -4), (-5, 4), (0, -6), (0, 7), (-7, -2), (-7, 2)):
            if c.get(ex + dx, ey + dy) == T:
                c.px(ex + dx, ey + dy, G if abs(dx) + abs(dy) > 6 else W)
    if rays:
        cx, cy = RING_CORE
        angles = [a + 22.5 for a in range(0, 360, 45) if a not in (45, 90)]
        long_ = [a for k, a in enumerate(angles) if (k + f) % 2 == 0]
        _rays(c, cx, cy, RING_R + 5, RING_R + 5 + rays, G, tip=W, angles=[a for a in angles if a not in long_])
        _rays(c, cx, cy, RING_R + 5, RING_R + 7 + rays, G, tip=W, angles=long_)
    return c


def build_dead_air():
    rows = [
        A('top', [ground_w4(left=True, top=True), ground_w4(top=True), ground_w4(right=True, top=True),
                  ground_w4(left=True, right=True, top=True)], 0,
          note='top-left, top, top-right, one-wide column top'),
        A('mid', [ground_w4(left=True, depth=1), ground_w4(depth=1), ground_w4(right=True, depth=1),
                  ground_w4(left=True, right=True, depth=1)], 0, note='second row down: left, fill, right, column'),
        A('deep', [ground_w4(left=True, depth=2), ground_w4(depth=2), ground_w4(right=True, depth=2),
                   ground_w4(left=True, right=True, depth=2)], 0, note='third row and below'),
        A('bottom', [ground_w4(left=True, bottom=True, depth=2), ground_w4(bottom=True, depth=2),
                     ground_w4(right=True, bottom=True, depth=2),
                     ground_w4(left=True, right=True, top=True, bottom=True)], 0,
          note='underside for ceilings and floating ground. The last one is a single tile'),
        A('alt', [ground_w4(top=True, alt=1), ground_w4(top=True, alt=3), ground_w4(depth=1, alt=2),
                  ground_w4(depth=2, alt=1)], 0, note='drop-in swaps for variety, pick by hash of world tile x,y'),
    ]
    sheet('ground_w4', 16, 16, rows,
          'Dead Air ground `#`: a riveted tread-plate floor on top with a cable tray slung under it, a second '
          'tray below that, then rack panels with rows of dead indicator lamps. Same layout as `ground`. '
          'Variants: floor grating, a dead floor lamp, a cut cable drooping out of its tray, a pulled rack panel.')
    sheet('block_w4', 16, 16, [
        A('lip', [block_w4(True, 0), block_w4(True, 1), block_w4(True, 2), block_w4(True, 3)], 0,
          note='top of a stack: plain, vent, live pip, stencil'),
        A('stacked', [block_w4(False, 0), block_w4(False, 1), block_w4(False, 2), block_w4(False, 3)], 0,
          note='a block with another block above it'),
    ], 'Dead Air block `=`: relay rack panels, each with a small grille and a dead lamp. Same layout as `block`. '
       'Use the live pip (the one lit lamp) rarely.')
    sheet('backdrop_w4', 96, 128, [
        A('pieces', [backdrop_w4(k) for k in range(4)], 0,
          note='0 banks of switching racks, 1 drooping bundles of cut cable, 2 a dead switchboard wall with '
               'empty stools, 3 a stair of cable trays'),
    ], f'Dead Air far shapes, like `backdrop_w3`: far layer, parallax 0.2x, 70% opacity, every bottom on one '
       f'horizon line. Lay the pieces edge to edge, one every 96 px, with no gaps: every piece carries the same '
       f'overhead cable tray (row {W4_TRAY_Y}) and the same floor line (row {W4_FLOOR_Y}) at its edges, so they '
       f'join in any order. DARK with a few GRAY glints, so it sits far back. Never put the same piece twice '
       f'in a row.')
    sheet('turret', 16, 16, [
        A('idle', [turret('idle', f) for f in range(2)], 0.3,
          note='faces left, flip for right. The eye is dim, with a faint flicker'),
        A('tell', [turret('tell', f) for f in range(3)], 0.1, loop=False,
          note='0.3 s before each shot: the eye brightens to WHITE and the socket rim catches the glow'),
        A('fire', [turret('fire', f) for f in range(2)], 0.08, loop=False,
          note=f'a jagged flash at the muzzle and the box kicks 1 px back. Spawn the bolt on frame 0 at frame '
               f'pixel {TURRET_MUZZLE}. The mount does not move'),
    ], f'Relay turret: a steel box bolted to the floor that fires a bolt of signal out of the round eye on its '
       f'left face. Top-left on the tile top-left, the mount plate on the bottom three rows. Eye centre at frame '
       f'pixel {TURRET_EYE}, and the bolt leaves from {TURRET_MUZZLE}. Mirrored, those are '
       f'({15 - TURRET_EYE[0]}, {TURRET_EYE[1]}) and ({15 - TURRET_MUZZLE[0]}, {TURRET_MUZZLE[1]}).')
    sheet('bolt', 16, 8, [
        A('fly', [bolt_shot('fly', f) for f in range(4)], 0.05,
          note='travelling left, flip for right. The head stays put, the broken tail flickers'),
        A('pop', [bolt_shot('pop', f) for f in range(3)], 0.05, loop=False,
          note='it hits a wall on its left and bursts into dots. Play it where the head stopped'),
    ], f'The turret\'s bolt: a short jagged streak of signal, a bright head 3 px tall and a thin broken tail, '
       f'so it never reads as a white blob or as the Spark. The head\'s centre is frame pixel {BOLT_HEAD}: '
       f'draw at top-left = head - {BOLT_HEAD}, and keep the head on the turret\'s muzzle row when it spawns. '
       f'A fair hitbox is frame x 0 to 6, y 2 to 4.')
    sheet('echo', 16, 16, [
        A('drift', [echo('drift', f) for f in range(4)], 0.12,
          note='faces left, flip it to face the player. Face out, open O mouth, tail wisps trailing. It drifts '
               'toward the player while the player looks away'),
        A('hide', [echo('hide', f) for f in range(4)], 0.15,
          note='the player is looking at it: both wispy hands over its face, the body shivers 1 px'),
        A('knocked', [echo('knocked', f) for f in range(5)], 0.07, loop=False,
          note='hit by the Arc: it tears into slices, then scatters into specks of static and is gone'),
    ], 'Echo: a ghost made of static, pale and ragged, with a round face. Like a Boo, it creeps up while the '
       'player looks away and hides its face when looked at. Round and GRAY with a WHITE sheen, two eyes and '
       'an O mouth, no legs and no antenna, so it never reads as the Spark or a walker. The body sits in frame '
       'x 2 to 13, y 1 to 12, the tail trails to (15, 14).')
    sheet('static_wall', 16, 16, [
        A('body', [static_wall('body', f) for f in range(4)], 0.08,
          note='dense crawling static. Tiles seamlessly both ways: fill the wall with it'),
        A('edge_up', [static_wall('edge_up', f) for f in range(4)], 0.08,
          note='the ragged crest on top of a rising wall. Its lower rows match body, clear above the crest'),
        A('edge_right', [static_wall('edge_right', f) for f in range(4)], 0.08,
          note='the ragged front of a wall moving right. Its left columns match body, clear to the right'),
    ], 'Wall of living static that rises up a shaft or chases from the left. Play all three rows on the same '
       'clock so the edges line up with the body. Rows 13 to 15 of edge_up match body exactly, and so do '
       'columns 0 to 4 of edge_right. The top 4 rows of edge_up and the last column of edge_right stay clear.')
    sheet('ring', RING_W, RING_H, [
        A('wait', [line_heart('wait', f) for f in range(4)], 0.2,
          note=f'seven weak Sparks flicker round the cracked core, static seeping from the crack. The empty place '
               f'is centred on frame pixel {RING_EMPTY}'),
        A('close', [line_heart('close', f) for f in range(6)], 0.12, loop=False,
          note='a Spark fills the empty place, a line of light runs round the circle, the crack flares and '
               'seals, everything brightens. Then play lit'),
        A('lit', [line_heart('lit', f) for f in range(4)], 0.1,
          note='whole and bright, short rays pulsing out'),
    ], f'The heart of the line, the goal of the last level: a cracked glass core like a big insulator on its '
       f'pin, seven small Sparks on a circle round it and one empty place on the left where the player joins. '
       f'Its base plate is on the bottom row, so draw it with top-left = (centre x - 48, floor y - 64). Core '
       f'centre {RING_CORE}, the Sparks on a circle of radius {RING_R} round it. The empty place is centred on '
       f'{RING_EMPTY}: hide the player\'s Spark there when close starts. It faces the viewer, so it needs no '
       f'mirrored copy.')


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
    build_pips()
    build_enemies()
    build_markers()
    build_backdrop()
    build_fx()
    build_switchyard()
    build_atmosphere()
    build_village()
    build_aerials()
    build_title()
    build_arc()
    build_intro()
    build_howl()
    build_keyart()
    build_dead_air()
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
                                         'npc': readme.VILLAGE, 'ground_w3': readme.WORLD3,
                                         'title_logo': readme.TITLE, 'arc': readme.ARC,
                                         'intro_npc': readme.STORY,
                                         'title_hero': readme.KEYART, 'ground_w4': readme.WORLD4})
    contact()
    print(f'{len(SHEETS)} sheets written to {OUT}')


if __name__ == '__main__':
    main()
