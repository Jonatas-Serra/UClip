#!/usr/bin/env python3
"""Generate icon sizes for electron-builder from a source image.

Usage:
  python scripts/generate_icons.py frontend/assets/icon.png frontend/buildResources
"""
import sys
import os
from PIL import Image

SIZES = [16, 24, 32, 48, 64, 128, 256, 512, 1024]


def generate(src: str, out_dir: str):
    os.makedirs(out_dir, exist_ok=True)
    try:
        img = Image.open(src).convert('RGBA')
    except Exception:
        # create a simple placeholder image
        print('Source image not valid, creating placeholder')
        img = Image.new('RGBA', (1024, 1024), (233, 84, 32, 255))
        # draw a simple 'U' letter
        try:
            from PIL import ImageDraw, ImageFont
            draw = ImageDraw.Draw(img)
            try:
                font = ImageFont.truetype('DejaVuSans-Bold.ttf', 600)
            except Exception:
                font = ImageFont.load_default()
            w, h = draw.textsize('U', font=font)
            draw.text(((1024-w)/2, (1024-h)/2), 'U', fill='white', font=font)
        except Exception:
            pass
    basename = os.path.splitext(os.path.basename(src))[0]
    for s in SIZES:
        out = os.path.join(out_dir, f"{basename}-{s}x{s}.png")
        resized = img.resize((s, s), Image.LANCZOS)
        resized.save(out)
        print('wrote', out)


if __name__ == '__main__':
    if len(sys.argv) != 3:
        print('Usage: generate_icons.py src.png out_dir')
        sys.exit(2)
    generate(sys.argv[1], sys.argv[2])
