#!/usr/bin/env bash
# Cycle the Ink Signal wallpapers without changing the theme.
set -euo pipefail

THEME=""
mode_arg="${1:-auto}"
case "$mode_arg" in
  auto|next)
    current="$(omarchy theme current)"
    case "$current" in
      "Ink Signal Night") THEME="Ink Signal Night" ;;
      "Ink Signal") THEME="Ink Signal" ;;
      *) echo "Active theme is '$current'; pass light or night." >&2; exit 1 ;;
    esac ;;
  light) THEME="Ink Signal" ;;
  night) THEME="Ink Signal Night" ;;
  *) echo "Usage: $0 [auto|light|night|next]" >&2; exit 1 ;;
esac

dir="$(omarchy theme dir "$THEME")"
mapfile -t files < <(find "$dir/backgrounds" -maxdepth 1 -type f -name '*.png' | sort)
((${#files[@]} > 0)) || { echo "No wallpapers in $dir/backgrounds" >&2; exit 1; }

mode=light
[[ "$THEME" == "Ink Signal Night" ]] && mode=night
state_dir="${XDG_CACHE_HOME:-$HOME/.cache}/ink-signal"
mkdir -p "$state_dir"
state="$state_dir/cycle-$mode"

next=0
if [[ -f "$state" ]]; then
  read -r index <"$state" || index=0
  [[ "$index" =~ ^[0-9]+$ ]] && next=$(( (index + 1) % ${#files[@]} ))
fi
printf '%s\n' "$next" >"$state"
omarchy theme bg set "${files[$next]}"
echo "Wallpaper: $(basename "${files[$next]}" .png)"
