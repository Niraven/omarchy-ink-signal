#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."

for f in install.sh uninstall.sh extras/*.sh scripts/check.sh; do
  bash -n "$f"
done
PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile tools/dither.py

for theme in ink-signal ink-signal-night; do
  test -s "themes/$theme/colors.toml"
  test -s "themes/$theme/preview.jpg"
  count=$(find "themes/$theme/backgrounds" -maxdepth 1 -type f -name '*.png' | wc -l)
  (( count >= 3 )) || { echo "$theme has only $count wallpapers" >&2; exit 1; }
done

test -s previews/lookbook.jpg
test -s previews/light.jpg
test -s previews/night.jpg

if grep -RIn --exclude-dir=.git --exclude='*.png' --exclude='*.jpg' --exclude='check.sh' -E 'ninoamor|Nino Amor|Niam' .; then
  echo 'personal identifier found in repo' >&2
  exit 1
fi

echo 'ok: scripts parse, themes complete, previews present, no personal identifiers'
