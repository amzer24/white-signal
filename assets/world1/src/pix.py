"""Tiny 4-grey pixel canvas used by make_sheets.py.

Only four greys exist: K #0b0b0b, D #3a3a3a, G #8a8a8a, W #f2f2f2, plus
transparency. Dither uses the same 4x4 Bayer matrix as scripts/draw_util.gd.
Every sheet frame is tile aligned (16 px), so frame-local Bayer coordinates
equal world coordinates mod 4 and the pattern never swims when scrolled.
"""
from PIL import Image

K = (11, 11, 11, 255)
D = (58, 58, 58, 255)
G = (138, 138, 138, 255)
W = (242, 242, 242, 255)
T = (0, 0, 0, 0)
PALETTE = {K, D, G, W, T}
CH = {'.': T, 'k': K, 'd': D, 'g': G, 'w': W}

BAYER = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]


def bayer(x, y):
    return BAYER[((y & 3) << 2) | (x & 3)]


def hash2(x, y):
    h = (x * 374761393 + y * 668265263) & 0xffffffff
    h = ((h ^ (h >> 13)) * 1274126177) & 0xffffffff
    return (h ^ (h >> 16)) & 0x7fffffff


class C:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.im = Image.new('RGBA', (w, h), T)
        self.p = self.im.load()

    # -- basic
    def px(self, x, y, c):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.p[x, y] = c

    def get(self, x, y):
        if 0 <= x < self.w and 0 <= y < self.h:
            return self.p[x, y]
        return T

    def rect(self, x, y, w, h, c):
        for yy in range(y, y + h):
            for xx in range(x, x + w):
                self.px(xx, yy, c)

    def frame(self, x, y, w, h, c):
        self.rect(x, y, w, 1, c)
        self.rect(x, y + h - 1, w, 1, c)
        self.rect(x, y, 1, h, c)
        self.rect(x + w - 1, y, 1, h, c)

    def dith(self, x, y, w, h, c, thr, only=None):
        """Set c where bayer < thr (0..16). `only` restricts to pixels of that colour."""
        for yy in range(y, y + h):
            for xx in range(x, x + w):
                if bayer(xx, yy) < thr and (only is None or self.get(xx, yy) == only):
                    self.px(xx, yy, c)

    def line(self, x0, y0, x1, y1, c):
        dx, dy = abs(x1 - x0), -abs(y1 - y0)
        sx, sy = (1 if x0 < x1 else -1), (1 if y0 < y1 else -1)
        err = dx + dy
        while True:
            self.px(x0, y0, c)
            if x0 == x1 and y0 == y1:
                break
            e2 = 2 * err
            if e2 >= dy:
                err += dy
                x0 += sx
            if e2 <= dx:
                err += dx
                y0 += sy

    def ellipse(self, cx, cy, rx, ry, c, only=None):
        for yy in range(int(cy - ry) - 1, int(cy + ry) + 2):
            for xx in range(int(cx - rx) - 1, int(cx + rx) + 2):
                dx = (xx + 0.5 - cx) / rx
                dy = (yy + 0.5 - cy) / ry
                if dx * dx + dy * dy <= 1.0 and (only is None or self.get(xx, yy) == only):
                    self.px(xx, yy, c)

    def art(self, x, y, rows):
        for j, row in enumerate(rows):
            for i, ch in enumerate(row):
                if ch in CH and ch != '.':
                    self.px(x + i, y + j, CH[ch])

    def outline(self, c=K, diag=False):
        src = self.im.copy().load()
        nb = [(1, 0), (-1, 0), (0, 1), (0, -1)]
        if diag:
            nb += [(1, 1), (-1, 1), (1, -1), (-1, -1)]
        for y in range(self.h):
            for x in range(self.w):
                if src[x, y][3] != 0:
                    continue
                for dx, dy in nb:
                    xx, yy = x + dx, y + dy
                    if 0 <= xx < self.w and 0 <= yy < self.h and src[xx, yy][3] != 0 and src[xx, yy] != c:
                        self.p[x, y] = c
                        break
        return self

    def paste(self, other, x, y):
        for yy in range(other.h):
            for xx in range(other.w):
                col = other.p[xx, yy]
                if col[3]:
                    self.px(x + xx, y + yy, col)
        return self

    def copy(self):
        n = C(self.w, self.h)
        n.im = self.im.copy()
        n.p = n.im.load()
        return n

    def flip_h(self):
        n = C(self.w, self.h)
        n.im = self.im.transpose(Image.FLIP_LEFT_RIGHT)
        n.p = n.im.load()
        return n

    def flip_v(self):
        n = C(self.w, self.h)
        n.im = self.im.transpose(Image.FLIP_TOP_BOTTOM)
        n.p = n.im.load()
        return n

    def rot90(self, k=1):
        n = C(self.w, self.h)
        img = self.im
        for _ in range(k % 4):
            img = img.transpose(Image.ROTATE_90)
        n.im = img
        n.p = n.im.load()
        return n

    def shifted(self, dx, dy):
        n = C(self.w, self.h)
        return n.paste(self, dx, dy)

    def recolor(self, a, b):
        for y in range(self.h):
            for x in range(self.w):
                if self.p[x, y] == a:
                    self.p[x, y] = b
        return self

    def check(self):
        for y in range(self.h):
            for x in range(self.w):
                col = self.p[x, y]
                if col[3] == 0:
                    continue
                assert col in PALETTE, f'off-palette pixel {col} at {x},{y}'
