#!/usr/bin/env python3
"""Generate the provisional GlassVideo app icon in CI."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

SIZE = 1024
out = Path("GlassVideo/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png")
out.parent.mkdir(parents=True, exist_ok=True)

im = Image.new("RGB", (SIZE, SIZE))
px = im.load()
for y in range(SIZE):
    t = y / (SIZE - 1)
    base = (int(12 + 28 * t), int(17 - 4 * t), int(39 + 29 * t))
    for x in range(SIZE):
        px[x, y] = base

glow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
gd = ImageDraw.Draw(glow)
gd.ellipse((120, 120, 620, 620), fill=(65, 222, 255, 70))
gd.ellipse((420, 400, 980, 960), fill=(178, 91, 255, 75))
glow = glow.filter(ImageFilter.GaussianBlur(95))
im = Image.alpha_composite(im.convert("RGBA"), glow)

tile = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
d = ImageDraw.Draw(tile)
d.rounded_rectangle((210, 210, 814, 814), radius=150,
                    fill=(255, 255, 255, 24),
                    outline=(235, 240, 255, 145), width=13)
d.rounded_rectangle((275, 275, 749, 287), radius=6, fill=(255, 255, 255, 70))
d.rounded_rectangle((275, 737, 749, 749), radius=6, fill=(255, 255, 255, 42))

mask = Image.new("L", (SIZE, SIZE), 0)
ImageDraw.Draw(mask).polygon([(415, 350), (415, 674), (685, 512)], fill=255)
grad = Image.new("RGBA", (SIZE, SIZE))
gp = grad.load()
for y in range(SIZE):
    for x in range(SIZE):
        t = max(0.0, min(1.0, (x + y * 0.25) / (SIZE * 1.25)))
        gp[x, y] = (int(78 + 143 * t), int(229 - 125 * t), int(250 - 18 * t), 255)
grad.putalpha(mask)
tile = Image.alpha_composite(tile, grad)
im = Image.alpha_composite(im, tile).convert("RGB")
im.save(out, "PNG", optimize=True)
print(f"Generated {out}")
