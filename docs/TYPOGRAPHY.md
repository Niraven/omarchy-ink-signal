# Typography

Ink Signal uses three roles, not three unrelated fonts:

| Role | Family | Used for |
| --- | --- | --- |
| Display | **Noto Serif** | headings, preview titles, document titles |
| UI / body | **Noto Sans** | app UI, body copy, controls |
| Code / data | **JetBrainsMono Nerd Font** | terminal, code, labels, bar |

Fallbacks are deliberate: `Noto Serif → Liberation Serif → Georgia → serif`, `Noto Sans → Adwaita Sans → Liberation Sans → sans-serif`, `JetBrainsMono Nerd Font → JetBrains Mono → monospace`.

## Install the fonts

On Arch/Omarchy:

```bash
sudo pacman -S noto-fonts noto-fonts-cjk ttf-jetbrains-mono-nerd
fc-cache -f
```

The theme does not bundle fonts; it uses the system stack so text stays consistent with the rest of the desktop.

## Obsidian

The theme handles colors; this snippet handles type. Copy `extras/obsidian-typography.css` into `<vault>/.obsidian/snippets/ink-signal-typography.css` and enable **Ink Signal — typography** under **Settings → Appearance → CSS snippets**.

`./install.sh --typography` does that for every vault in `~/.config/obsidian/obsidian.json` and enables the snippet. It backs up each `appearance.json` first.

What it changes:

- `--font-text-theme` and `--font-interface-theme` → Noto Sans.
- `--font-monospace-theme` → JetBrainsMono Nerd Font.
- Heading families → Noto Serif, weight 600, slightly tight tracking.
- Blockquotes → Noto Serif italic.
- Line height → 1.65.

It deliberately does **not** change heading sizes, colors, or spacing; those belong to the theme.

## GTK apps

```bash
./extras/gtk-typography.sh apply
./extras/gtk-typography.sh status
./extras/gtk-typography.sh restore
```

`apply` saves the current values under `~/.local/state/omarchy/typography-backups/` and sets:

- `font-name`: `Noto Sans 11`
- `document-font-name`: `Noto Serif 12`
- `monospace-font-name`: `JetBrainsMono Nerd Font 11`

`restore` uses the newest backup unless you pass a directory.

## What stays mono

The Omarchy bar and terminal remain on **JetBrainsMono Nerd Font** on purpose: the bar is icon-heavy, and the terminal is code. Making the shell proportional would break Nerd Font glyph metrics. The contrast between serif notes, sans UI, and mono shell is the system, not an inconsistency.

## Live state

On this machine:

- GTK UI: Noto Sans 11.
- GTK documents: Noto Serif 12.
- GTK monospace: JetBrainsMono Nerd Font 11.
- Obsidian: Omarchy theme + `ink-signal-typography` snippet enabled.
- Terminal/Omarchy bar: JetBrainsMono Nerd Font.
