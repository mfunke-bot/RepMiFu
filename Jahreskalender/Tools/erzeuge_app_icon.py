import sys
from PIL import Image, ImageDraw
out = sys.argv[1]
K = 4; N = 1024 * K
img = Image.new("RGB", (N, N))
d = ImageDraw.Draw(img)
# Hintergrund: vertikaler Verlauf Blau
top, bot = (40, 92, 180), (18, 44, 110)
for y in range(N):
    t = y / (N - 1)
    d.line([(0, y), (N, y)], fill=tuple(int(top[i] + (bot[i] - top[i]) * t) for i in range(3)))
s = lambda v: int(v * K)
# Schatten
sh = Image.new("L", (N, N), 0); ds = ImageDraw.Draw(sh)
ds.rounded_rectangle([s(182), s(232), s(862), s(892)], radius=s(70), fill=90)
from PIL import ImageFilter
sh = sh.filter(ImageFilter.GaussianBlur(s(18)))
img.paste((8, 20, 60), (0, 0), sh)
# Blatt
x0, y0, x1, y1 = s(172), s(210), s(852), s(870)
d.rounded_rectangle([x0, y0, x1, y1], radius=s(70), fill=(255, 255, 255))
# roter Kopf
kopf_unten = s(370)
d.rounded_rectangle([x0, y0, x1, kopf_unten], radius=s(70), fill=(214, 40, 40))
d.rectangle([x0, kopf_unten - s(70), x1, kopf_unten], fill=(214, 40, 40))
# Ringe
for cx in (s(342), s(682)):
    d.rounded_rectangle([cx - s(26), s(160), cx + s(26), s(280)], radius=s(26), fill=(235, 235, 240))
    d.rounded_rectangle([cx - s(14), s(172), cx + s(14), s(268)], radius=s(14), fill=(170, 170, 180))
# Raster 7 x 5
cols, rows = 7, 5
gx0, gy0, gx1, gy1 = s(222), s(415), s(802), s(825)
cw = (gx1 - gx0) / cols; ch = (gy1 - gy0) / rows
rot = {(0, 0), (4, 2), (2, 4)}        # markierte Feiertage
for r in range(rows):
    for c in range(cols):
        cx = gx0 + c * cw; cy = gy0 + r * ch
        box = [cx + s(8), cy + s(8), cx + cw - s(8), cy + ch - s(8)]
        if (c, r) in rot:
            col = (214, 40, 40)
        elif c >= 5:
            col = (200, 205, 215)
        else:
            col = (228, 231, 238)
        d.rounded_rectangle(box, radius=s(14), fill=col)
img.resize((1024, 1024), Image.LANCZOS).save(out, "PNG")
