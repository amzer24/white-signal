"""Quantize PixelLab assets into WHITE SIGNAL's 1-bit ditherpunk ramp."""
from PIL import Image
import os, sys, shutil
RAMP = [0x0b, 0x23, 0x3a, 0x8a, 0xf2]           # BG, MORTAR, DARK, GRAY, WHITE
BAYER = [[0,8,2,10],[12,4,14,6],[3,11,1,9],[15,7,13,5]]
def quant(path, dither, max_tone=None, gamma=1.0):
    raw_dir = os.path.join(os.path.dirname(path), "raw"); os.makedirs(raw_dir, exist_ok=True)
    raw = os.path.join(raw_dir, os.path.basename(path))
    if not os.path.exists(raw): shutil.copy(path, raw)
    im = Image.open(raw).convert("RGBA"); px = im.load(); w,h = im.size
    ramp = RAMP if max_tone is None else RAMP[:max_tone+1]
    for y in range(h):
        for x in range(w):
            r,g,b,a = px[x,y]
            if a < 128: px[x,y] = (0,0,0,0); continue
            l = (0.299*r+0.587*g+0.114*b)/255.0
            l = l ** gamma
            # position of l within the ramp
            v = l*255
            # find neighbouring ramp tones
            lo = max([t for t in ramp if t <= v], default=ramp[0]); hi = min([t for t in ramp if t >= v], default=ramp[-1])
            if lo == hi: tone = lo
            else:
                f = (v-lo)/(hi-lo)
                thr = (BAYER[y%4][x%4]+0.5)/16.0 if dither else 0.5
                tone = hi if f > thr else lo
            px[x,y] = (tone,tone,tone,255)
    im.save(path)
    return path
if __name__ == "__main__":
    base = r"E:/Godot games/white signal/assets/exploration"
    for n in ["flats","field","stand","wire","array","source"]:
        quant(f"{base}/biomes/{n}-tiles.png", dither=False, max_tone=3)      # play layer: never brighter than GRAY
        quant(f"{base}/biomes/{n}-sky.png", dither=True, max_tone=2, gamma=0.8)  # backdrop: BG..DARK only, dithered like the classic sky
    for n in ["lever","breaker","valve","socket","impeller","brake","archive","protocol","beacon","crank","callpost","door_open","door_shut","memory"]:
        quant(f"{base}/props/{n}.png", dither=False)
    print("quantized")
