#!/usr/bin/env bash
# Ink Signal for Omarchy — installer.
# Copies the two themes, optionally activates one, and only touches
# Hyprland/Obsidian/Hermes when the matching flag is given.
set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
THEMES_ROOT="$CONFIG_HOME/omarchy/themes"
BACKUP_ROOT="${INK_SIGNAL_BACKUP_DIR:-$STATE_HOME/omarchy/theme-backups}"
THEME_CHOICE="both"
WALLPAPER=""
ACTIVATE=0
GEOMETRY=0
OBSIDIAN=0
HERMES=0
HELPERS=0
TYPOGRAPHY=0
DRY_RUN=0
FORCE=0

usage() {
  cat <<'EOF'
Ink Signal for Omarchy

Usage: ./install.sh [options]

  --theme light|night|both   Install one theme or both (default: both)
  --wallpaper NAME|random    Background for the activated theme
                             (default: poppy for light, magnolia-night for night)
  --activate                 Apply the theme and its background
  --geometry                 Add the hairline Hyprland geometry (gaps 4/8, border 1, radius 4)
  --obsidian                 Sync the Omarchy Obsidian theme and select it
  --hermes                   Publish and activate the Omarchy Hermes skin
  --helpers                  Install ink-signal-cycle and ink-signal-day-night in ~/.local/bin
  --typography               Install the Obsidian type snippet and apply the GTK font stack
  --force                    Replace an existing differing theme, after a backup
  --dry-run                  Print what would happen; change nothing
  --backup-dir DIR           Where to keep pre-change backups
  -h, --help                 Show this help

Nothing is installed system-wide. No sudo is used. Existing themes are never
deleted without a backup and --force.
EOF
}

die() { printf 'error: %s\n' "$*" >&2; exit 1; }
note() { printf '  %s\n' "$*"; }
step() { printf '\n==> %s\n' "$*"; }

while (($#)); do
  case "$1" in
    --theme) [[ $# -ge 2 ]] || die "--theme needs light, night, or both"; THEME_CHOICE="$2"; shift 2 ;;
    --theme=*) THEME_CHOICE="${1#*=}"; shift ;;
    --wallpaper) [[ $# -ge 2 ]] || die "--wallpaper needs a name or random"; WALLPAPER="$2"; shift 2 ;;
    --wallpaper=*) WALLPAPER="${1#*=}"; shift ;;
    --activate) ACTIVATE=1; shift ;;
    --geometry) GEOMETRY=1; shift ;;
    --obsidian) OBSIDIAN=1; shift ;;
    --hermes) HERMES=1; shift ;;
    --helpers) HELPERS=1; shift ;;
    --typography) TYPOGRAPHY=1; shift ;;
    --force) FORCE=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --backup-dir) [[ $# -ge 2 ]] || die "--backup-dir needs a path"; BACKUP_ROOT="$2"; shift 2 ;;
    --backup-dir=*) BACKUP_ROOT="${1#*=}"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown option: $1 (try --help)" ;;
  esac
done

case "$THEME_CHOICE" in
  light) THEMES=(ink-signal) ;;
  night) THEMES=(ink-signal-night) ;;
  both) THEMES=(ink-signal ink-signal-night) ;;
  *) die "--theme must be light, night, or both" ;;
esac

for slug in "${THEMES[@]}"; do
  [[ -f "$REPO_DIR/themes/$slug/colors.toml" ]] || die "missing theme: themes/$slug/colors.toml"
  [[ -d "$REPO_DIR/themes/$slug/backgrounds" ]] || die "missing backgrounds: themes/$slug/backgrounds"
done

if ((ACTIVATE)); then
  command -v omarchy >/dev/null 2>&1 || die "--activate requires the omarchy command"
fi

display_name() {
  case "$1" in
    ink-signal) printf 'Ink Signal' ;;
    ink-signal-night) printf 'Ink Signal Night' ;;
    *) return 1 ;;
  esac
}

# Resolve a wallpaper from the installed theme, falling back to the repo copy.
wallpaper_path() {
  local slug="$1" requested="$2" dir
  dir="$THEMES_ROOT/$slug/backgrounds"
  [[ -d "$dir" ]] || dir="$REPO_DIR/themes/$slug/backgrounds"

  if [[ -z "$requested" ]]; then
    case "$slug" in
      ink-signal) printf '%s/poppy.png\n' "$dir" ;;
      *) printf '%s/magnolia-night.png\n' "$dir" ;;
    esac
    return
  fi
  if [[ "$requested" == random ]]; then
    find "$dir" -maxdepth 1 -type f -name '*.png' | sort | shuf -n 1
    return
  fi
  local name="${requested%.png}"
  if [[ ! -f "$dir/$name.png" ]]; then
    printf 'error: no wallpaper "%s" in %s\navailable: ' "$name" "$slug" >&2
    find "$dir" -maxdepth 1 -type f -name '*.png' -printf '%f\n' | sed 's/\.png$//' | sort | tr '\n' ' ' >&2
    printf '\n' >&2
    return 1
  fi
  printf '%s/%s.png\n' "$dir" "$name"
}

if ((ACTIVATE)); then
  case "$THEME_CHOICE" in night) active=ink-signal-night ;; *) active=ink-signal ;; esac
  wallpaper_path "$active" "$WALLPAPER" >/dev/null || exit 1
fi

if ((OBSIDIAN || TYPOGRAPHY)); then
  command -v jq >/dev/null 2>&1 || die "--obsidian/--typography requires jq"
fi
if ((OBSIDIAN)); then
  command -v omarchy-theme-set-obsidian >/dev/null 2>&1 || die "--obsidian requires omarchy-theme-set-obsidian"
fi

# Preflight every destination before changing anything.
for slug in "${THEMES[@]}"; do
  dest="$THEMES_ROOT/$slug"
  if [[ -e "$dest" && ! -d "$dest" ]]; then
    die "$dest exists and is not a directory"
  fi
  if [[ -d "$dest" ]] && ! diff -r --no-dereference --exclude=preview.jpg "$REPO_DIR/themes/$slug" "$dest" >/dev/null 2>&1; then
    if ((FORCE == 0 && DRY_RUN == 0)); then
      die "$slug is already installed and differs; rerun with --force to back it up and replace it"
    fi
  fi
done

if ((DRY_RUN)); then
  step "Dry run — no changes"
  for slug in "${THEMES[@]}"; do
    note "would install $slug -> $THEMES_ROOT/$slug"
  done
  if ((ACTIVATE)); then
    case "$THEME_CHOICE" in night) active=ink-signal-night ;; *) active=ink-signal ;; esac
    note "would activate $(display_name "$active")"
    note "would set background $(wallpaper_path "$active" "$WALLPAPER")"
  fi
  ((GEOMETRY)) && note "would add hairline geometry to $HOME/.config/hypr/looknfeel.lua"
  ((OBSIDIAN)) && note "would sync the Omarchy Obsidian theme and select it"
  ((HERMES)) && note "would publish and activate the Omarchy Hermes skin"
  ((HELPERS)) && note "would install helpers in ${XDG_BIN_HOME:-$HOME/.local/bin}"
  ((TYPOGRAPHY)) && note "would enable the Obsidian type snippet and GTK font stack"
  note "backups would go to $BACKUP_ROOT"
  exit 0
fi

STAMP="$(date +%Y%m%dT%H%M%S%z)"
mkdir -p "$THEMES_ROOT" "$BACKUP_ROOT"

step "Installing themes"
for slug in "${THEMES[@]}"; do
  src="$REPO_DIR/themes/$slug"
  dest="$THEMES_ROOT/$slug"
  if [[ -d "$dest" ]]; then
    if diff -r --no-dereference --exclude=preview.jpg "$src" "$dest" >/dev/null 2>&1; then
      note "$slug already current"
      continue
    fi
    backup="$BACKUP_ROOT/$slug-$STAMP"
    cp -a "$dest" "$backup"
    note "backed up $slug -> $backup"
    rm -rf -- "$dest"
  fi
  cp -a "$src" "$dest"
  note "installed $slug"
done

if ((ACTIVATE)); then
  step "Activating"
  case "$THEME_CHOICE" in
    night) active=ink-signal-night ;;
    *) active=ink-signal ;;
  esac
  name="$(display_name "$active")"
  omarchy theme set "$name"
  wp="$(wallpaper_path "$active" "$WALLPAPER")"
  omarchy theme bg set "$wp"
  note "active: $name"
  note "background: $wp"
fi

if ((GEOMETRY)); then
  step "Hairline geometry"
  look="$HOME/.config/hypr/looknfeel.lua"
  if [[ ! -f "$look" ]]; then
    note "skipped: $look not found"
  elif grep -q '^# >>> ink-signal geometry' "$look"; then
    note "already present"
  else
    cp -a "$look" "$BACKUP_ROOT/looknfeel-$STAMP.lua"
    cat >>"$look" <<'EOF'

# >>> ink-signal geometry
hl.config({
  general = { gaps_in = 4, gaps_out = 8, border_size = 1 },
  decoration = { rounding = 4, dim_inactive = true, dim_strength = 0.12 },
})
# <<< ink-signal geometry
EOF
    note "added to $look (backup: $BACKUP_ROOT/looknfeel-$STAMP.lua)"
    hyprctl reload >/dev/null 2>&1 || true
  fi
fi

if ((OBSIDIAN)); then
  step "Obsidian"
  command -v jq >/dev/null 2>&1 || die "--obsidian requires jq"
  command -v omarchy-theme-set-obsidian >/dev/null 2>&1 || die "--obsidian requires omarchy-theme-set-obsidian"
  omarchy-theme-set-obsidian
  mapfile -t vaults < <(jq -r '.vaults | values[].path' "$HOME/.config/obsidian/obsidian.json" 2>/dev/null || true)
  for vault in "${vaults[@]}"; do
    app="$vault/.obsidian/appearance.json"
    [[ -f "$app" ]] || continue
    key="$(printf '%s' "$vault" | tr '/ ' '__')"
    cp -a "$app" "$BACKUP_ROOT/obsidian-appearance-$key-$STAMP.json"
    tmp="$(mktemp)"
    jq '. + {cssTheme:"Omarchy"}' "$app" >"$tmp"
    mv "$tmp" "$app"
    note "selected Omarchy theme in $vault"
  done
fi

if ((TYPOGRAPHY)); then
  step "Typography"
  if [[ -f "$HOME/.config/obsidian/obsidian.json" ]]; then
    mapfile -t vaults < <(jq -r '.vaults | values[].path' "$HOME/.config/obsidian/obsidian.json" 2>/dev/null || true)
    for vault in "${vaults[@]}"; do
      [[ -d "$vault/.obsidian" ]] || continue
      snippets="$vault/.obsidian/snippets"
      mkdir -p "$snippets"
      cp "$REPO_DIR/extras/obsidian-typography.css" "$snippets/ink-signal-typography.css"
      app="$vault/.obsidian/appearance.json"
      [[ -f "$app" ]] || printf '{}\n' >"$app"
      key="$(printf '%s' "$vault" | tr '/ ' '__')"
      cp -a "$app" "$BACKUP_ROOT/obsidian-appearance-$key-$STAMP.json"
      tmp="$(mktemp)"
      jq '. + {enabledCssSnippets: ((.enabledCssSnippets // []) + ["ink-signal-typography"] | unique)}' "$app" >"$tmp"
      mv "$tmp" "$app"
      note "typography snippet enabled in $vault"
    done
  fi
  if command -v gsettings >/dev/null 2>&1; then
    fonts="$BACKUP_ROOT/gtk-fonts-$STAMP.txt"
    : >"$fonts"
    for key in font-name document-font-name monospace-font-name; do
      printf '%s=' "$key" >>"$fonts"
      gsettings get org.gnome.desktop.interface "$key" >>"$fonts"
    done
    gsettings set org.gnome.desktop.interface font-name 'Noto Sans 11'
    gsettings set org.gnome.desktop.interface document-font-name 'Noto Serif 12'
    gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrainsMono Nerd Font 11'
    note "GTK fonts: Noto Sans / Noto Serif / JetBrainsMono Nerd Font"
    note "backup: $fonts"
  else
    note "skipped GTK fonts: gsettings not found"
  fi
fi

if ((HELPERS)); then
  step "Helpers"
  bin="${XDG_BIN_HOME:-$HOME/.local/bin}"
  mkdir -p "$bin"
  install -m755 "$REPO_DIR/extras/cycle-wallpaper.sh" "$bin/ink-signal-cycle"
  install -m755 "$REPO_DIR/extras/day-night.sh" "$bin/ink-signal-day-night"
  note "installed $bin/ink-signal-cycle"
  note "installed $bin/ink-signal-day-night"
fi

if ((HERMES)); then
  step "Hermes skin"
  if command -v omarchy-theme-set-hermes >/dev/null 2>&1; then
    omarchy-theme-set-hermes --activate || note "Hermes skin was published but not activated"
  else
    note "skipped: omarchy-theme-set-hermes not found"
  fi
fi

step "Done"
note "themes: ${THEMES[*]}"
((ACTIVATE)) && note "apply another variant from Super + Alt + A -> Desktop Style -> Theme Previews"
note "backups: $BACKUP_ROOT"
