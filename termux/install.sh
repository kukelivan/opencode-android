#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

: "${PREFIX:?Run inside Termux}"
SOURCE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN="$SOURCE/dist/opencode-android-arm64"
test -f "$BIN"
if ! command -v rg >/dev/null; then
  printf 'Install the Android search dependency first: pkg install ripgrep\n' >&2
  exit 1
fi
if [ -e "$PREFIX/bin/opencode" ]; then
  BACKUP="$PREFIX/bin/opencode.backup-$(date +%Y%m%d-%H%M%S)"
  cp -L "$PREFIX/bin/opencode" "$BACKUP"
  printf 'Backup: %s\n' "$BACKUP"
fi
install -m 755 "$BIN" "$PREFIX/bin/opencode.new"
"$PREFIX/bin/opencode.new" --version
mv -f "$PREFIX/bin/opencode.new" "$PREFIX/bin/opencode"
printf 'Installed: %s/bin/opencode\nRestart OpenCode to use the new build.\n' "$PREFIX"
