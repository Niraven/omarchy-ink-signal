# Customize

## Change the palette

Edit `themes/ink-signal/colors.toml` or `themes/ink-signal-night/colors.toml`, then:

```bash
omarchy theme refresh
```

Keep contrast: body text should stay at least 4.5:1 against the background. The shipped palettes are tested.

## Add a wallpaper

```bash
python3 -m pip install -r tools/requirements.txt
python3 tools/dither.py source.jpg /tmp/study.png --mode light --cell 4
cp /tmp/study.png themes/ink-signal/backgrounds/study.png
```

For night, use `--mode night`. Use `--fit cover` if you want a full-bleed crop instead of the default contain.

Then install or refresh:

```bash
./install.sh --theme light --force
omarchy theme bg set "$(omarchy theme dir 'Ink Signal')/backgrounds/study.png"
```

## Add a whole variant

1. Copy `themes/ink-signal` to `themes/ink-signal-<name>`.
2. Edit `colors.toml`.
3. Replace the backgrounds.
4. Install with `./install.sh --theme light --force` after adding the slug to the installer, or copy the directory to `~/.config/omarchy/themes/` manually.

## Geometry

`./install.sh --geometry` appends a marked block to `~/.config/hypr/looknfeel.lua`:

```lua
hl.config({
  general = { gaps_in = 4, gaps_out = 8, border_size = 1 },
  decoration = { rounding = 4, dim_inactive = true, dim_strength = 0.12 },
})
```

Remove the block between `# >>> ink-signal geometry` and `# <<< ink-signal geometry` to roll it back.

## Obsidian

`./install.sh --obsidian` runs `omarchy-theme-set-obsidian` and sets `"cssTheme": "Omarchy"` in every vault listed in `~/.config/obsidian/obsidian.json`. It backs up each `appearance.json` first.

## Hermes

`./install.sh --hermes` publishes the generated skin and asks Hermes to activate it. If Hermes is already on a custom skin, Omarchy leaves that choice alone; switch manually with:

```bash
hermes config set display.skin omarchy
```
