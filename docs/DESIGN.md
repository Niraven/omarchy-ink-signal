# Design

## System

| Role | Light | Night |
| --- | --- | --- |
| Paper | `#ffffff` | `#050505` |
| Ink | `#171717` | `#f2f2ee` |
| Accent | `#4169e1` | `#8aa7ff` |
| Pale wash | `#8aa7ff` | `#4169e1` |
| Chop | `#d4552f` | `#d4552f` |

The screen is a **Bayer 8×8 ordered dither** at **4 px cells**. Tone comes from dot count, not dot size. There is no error diffusion, no gradient, and no photographic grain. The chop is redrawn at a fixed margin so it never clips.

## Grammar

- **Moon gate** — a thin circular opening; a frame, not a planet.
- **Lattice** — a geometric window screen, complete or deliberately cropped.
- **Seigaiha** — a wave border along the bottom edge.
- **Contour ridge** — a low ink horizon, never a landscape illustration.
- **Chop** — a vermilion square with abstract cut-out marks. The marks are not calligraphy and do not spell anything.

## Subjects

The flowers are **poppy, thistle, bamboo, and magnolia**, not the plum/iris/pine set that appears in common ink portfolios. The abstract studies are a signal bloom, an imaginary contour coast, an orbital diagram, and an isometric node lattice.

## Composition

- Asymmetry: weight on the right, air on the left.
- One hero motif per wallpaper.
- Supporting motifs sit at the edges, never in the icon zone.
- White/black fields are clamped so the desktop stays clean.

## Dither pipeline

1. Source image is contained to 2880×1800 — no cover-crop, so petals and seals do not get cut.
2. A consistent chop is drawn at a fixed margin.
3. Pixels are separated by hue: neutral pixels dither paper/ink; blue-dominant pixels dither royal/pale; red-dominant pixels dither the chop.
4. The result is saved as an optimized PNG.

`tools/dither.py` reproduces steps 1–3 for your own images.
