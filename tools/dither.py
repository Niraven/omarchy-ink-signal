#!/usr/bin/env python3
"""Apply the Ink Signal ordered dither to any image.

Examples:
  python3 tools/dither.py in.jpg out.png --mode light
  python3 tools/dither.py in.jpg out.png --mode night --fit cover --cell 4
"""
from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
from PIL import Image

BAYER8 = np.array([
    [0, 32, 8, 40, 2, 34, 10, 42],
    [48, 16, 56, 24, 50, 18, 58, 26],
    [12, 44, 4, 36, 14, 46, 6, 38],
    [60, 28, 52, 20, 62, 30, 54, 22],
    [3, 35, 11, 43, 1, 33, 9, 41],
    [51, 19, 59, 27, 49, 17, 57, 25],
    [15, 47, 7, 39, 13, 45, 5, 37],
    [63, 31, 55, 23, 61, 29, 53, 21],
], dtype=np.float32) / 64.0

PALETTES = {
    'light': ((255, 255, 255), (23, 23, 23), (65, 105, 225), (138, 167, 255), (212, 85, 47)),
    'night': ((5, 5, 5), (242, 242, 238), (138, 167, 255), (65, 105, 225), (212, 85, 47)),
}


def fit(im: Image.Image, width: int, height: int, mode: str, how: str) -> Image.Image:
    im = im.convert('RGB')
    if how == 'cover':
        scale = max(width / im.width, height / im.height)
    else:
        scale = min(width / im.width, height / im.height)
    im = im.resize((round(im.width * scale), round(im.height * scale)), Image.Resampling.LANCZOS)
    bg = PALETTES[mode][0]
    canvas = Image.new('RGB', (width, height), bg)
    canvas.paste(im, ((width - im.width) // 2, (height - im.height) // 2))
    return canvas


def ordered(im: Image.Image, mode: str, cell: int = 4) -> Image.Image:
    a = np.asarray(im).astype(np.float32)
    h, w = a.shape[:2]
    r, g, b = a[..., 0].reshape(-1), a[..., 1].reshape(-1), a[..., 2].reshape(-1)
    lum = (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255.0
    blue = np.clip((b - (r + g) / 2) / 90.0, 0, 1)
    is_blue = (blue > .16) & (b > 60)
    red = np.clip((r - (g + b) / 2) / 80.0, 0, 1)
    is_red = (red > .12) & (r > 70)

    yy = (np.arange(h)[:, None] // cell) % 8
    xx = (np.arange(w)[None, :] // cell) % 8
    thr = np.broadcast_to(BAYER8[yy, xx], (h, w)).reshape(-1)

    paper, ink, royal, pale, chop = PALETTES[mode]
    out = np.empty((h * w, 3), dtype=np.uint8)
    out[:] = paper
    ink_sel = lum < .5
    white_sel = ~ink_sel & ~is_blue
    if mode == 'light':
        out[white_sel] = paper
        out[ink_sel] = ink
    else:
        out[white_sel] = ink
        out[ink_sel] = paper
    if mode == 'light':
        royal_sel = is_blue & (blue * 1.15 > thr)
        pale_sel = is_blue & ~royal_sel & (blue * 1.2 > thr)
    else:
        royal_sel = is_blue & (blue * 1.15 > thr)
        pale_sel = is_blue & ~royal_sel & (blue * .5 > thr)
    out[royal_sel] = royal
    out[pale_sel] = pale
    out[is_red & (red * 1.25 > thr)] = chop
    return Image.fromarray(out.reshape(h, w, 3), 'RGB')


def main() -> None:
    p = argparse.ArgumentParser(description='Ink Signal ordered dither')
    p.add_argument('input', type=Path)
    p.add_argument('output', type=Path)
    p.add_argument('--mode', choices=('light', 'night'), default='light')
    p.add_argument('--width', type=int, default=2880)
    p.add_argument('--height', type=int, default=1800)
    p.add_argument('--cell', type=int, default=4)
    p.add_argument('--fit', choices=('contain', 'cover'), default='contain')
    args = p.parse_args()

    im = fit(Image.open(args.input), args.width, args.height, args.mode, args.fit)
    result = ordered(im, args.mode, args.cell)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    result.save(args.output, 'PNG', optimize=True)
    print(f'{args.output}  {result.width}x{result.height}  {args.output.stat().st_size} bytes')


if __name__ == '__main__':
    main()
