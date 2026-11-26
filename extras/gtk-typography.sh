#!/usr/bin/env bash
# Apply or restore the Ink Signal GTK font stack.
set -euo pipefail

ACTION="${1:-apply}"
BACKUP_ROOT="${XDG_STATE_HOME:-$HOME/.local/state}/omarchy/typography-backups"
KEYS=(font-name document-font-name monospace-font-name)
VALUES=("Noto Sans 11" "Noto Serif 12" "JetBrainsMono Nerd Font 11")

usage() {
  cat <<'EOF'
Usage: ./extras/gtk-typography.sh [apply|restore|status] [backup-dir]

apply    Save the current GTK font names and set the Ink Signal stack.
restore  Restore a backup (defaults to the newest).
status   Print the current GTK font names.
EOF
}
die() { printf 'error: %s\n' "$*" >&2; exit 1; }
need_gsettings() { command -v gsettings >/dev/null 2>&1 || die 'gsettings not found'; }

case "$ACTION" in
  apply)
    need_gsettings
    stamp="$(date +%Y%m%dT%H%M%S%z)"
    dir="$BACKUP_ROOT/$stamp"
    mkdir -p "$dir"
    for i in "${!KEYS[@]}"; do
      gsettings get org.gnome.desktop.interface "${KEYS[$i]}" >"$dir/${KEYS[$i]}.txt"
      gsettings set org.gnome.desktop.interface "${KEYS[$i]}" "${VALUES[$i]}"
    done
    printf 'GTK fonts applied. Backup: %s\n' "$dir"
    ;;
  restore)
    need_gsettings
    dir="${2:-}"
    if [[ -z "$dir" ]]; then
      dir="$(find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort | tail -1)"
    fi
    [[ -d "$dir" ]] || die "no backup directory found"
    for key in "${KEYS[@]}"; do
      [[ -f "$dir/$key.txt" ]] || die "missing $dir/$key.txt"
      value="$(sed "s/^'//; s/'$//" "$dir/$key.txt")"
      gsettings set org.gnome.desktop.interface "$key" "$value"
    done
    printf 'GTK fonts restored from %s\n' "$dir"
    ;;
  status)
    need_gsettings
    for key in "${KEYS[@]}"; do
      printf '%s: ' "$key"
      gsettings get org.gnome.desktop.interface "$key"
    done
    ;;
  -h|--help|help) usage ;;
  *) usage >&2; exit 1 ;;
esac
