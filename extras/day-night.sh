#!/usr/bin/env bash
# Switch between Ink Signal and Ink Signal Night at a local hour boundary.
set -euo pipefail

MODE="${1:-auto}"
DAY_START="${INK_SIGNAL_DAY_START:-7}"
NIGHT_START="${INK_SIGNAL_NIGHT_START:-19}"

case "$MODE" in
  auto)
    hour=$((10#$(date +%H)))
    if (( hour >= DAY_START && hour < NIGHT_START )); then MODE=light; else MODE=night; fi ;;
  light|night) ;;
  *) echo "Usage: $0 [auto|light|night]" >&2; exit 1 ;;
esac

if [[ "$MODE" == "light" ]]; then
  theme="Ink Signal"; wallpaper="poppy"
else
  theme="Ink Signal Night"; wallpaper="magnolia-night"
fi

omarchy theme set "$theme"
dir="$(omarchy theme dir "$theme")"
if [[ -f "$dir/backgrounds/$wallpaper.png" ]]; then
  omarchy theme bg set "$dir/backgrounds/$wallpaper.png"
fi
echo "Ink Signal: $MODE"
