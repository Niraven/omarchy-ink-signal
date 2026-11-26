#!/usr/bin/env bash
# Remove the Ink Signal themes. Refuses to remove the active theme.
set -euo pipefail

CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
THEMES_ROOT="$CONFIG_HOME/omarchy/themes"
THEME_CHOICE="both"
DRY_RUN=0

usage() {
  cat <<'EOF'
Usage: ./uninstall.sh [--theme light|night|both] [--dry-run]

Removes only the Ink Signal theme directories. It does not switch themes,
remove Obsidian settings, or delete backups.
EOF
}
die() { printf 'error: %s\n' "$*" >&2; exit 1; }
note() { printf '  %s\n' "$*"; }

while (($#)); do
  case "$1" in
    --theme) [[ $# -ge 2 ]] || die "--theme needs light, night, or both"; THEME_CHOICE="$2"; shift 2 ;;
    --theme=*) THEME_CHOICE="${1#*=}"; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
done

case "$THEME_CHOICE" in
  light) THEMES=(ink-signal) ;;
  night) THEMES=(ink-signal-night) ;;
  both) THEMES=(ink-signal ink-signal-night) ;;
  *) die "--theme must be light, night, or both" ;;
esac

display_name() {
  case "$1" in ink-signal) printf 'Ink Signal' ;; ink-signal-night) printf 'Ink Signal Night' ;; esac
}

current="$(omarchy theme current 2>/dev/null || true)"
for slug in "${THEMES[@]}"; do
  if [[ "$current" == "$(display_name "$slug")" ]]; then
    die "$(display_name "$slug") is active; switch to another theme first"
  fi
done

for slug in "${THEMES[@]}"; do
  dest="$THEMES_ROOT/$slug"
  if ((DRY_RUN)); then
    note "would remove $dest"
  elif [[ -d "$dest" ]]; then
    rm -rf -- "$dest"
    note "removed $dest"
  else
    note "not installed: $slug"
  fi
done
printf '\nObsidian and Hermes settings were not changed. Backups are kept.\n'
