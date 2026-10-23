#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
: "${TMPDIR:?Run inside Termux}"
SOURCE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
bash "$SOURCE/termux/setup-tools.sh"
WORK="$(mktemp -d "$TMPDIR/opencode-check.XXXXXX")"
tar --exclude=.git --exclude=node_modules --exclude=dist --exclude=.turbo \
  -C "$SOURCE" -cf - . | tar -C "$WORK" -xf -
python "$SOURCE/termux/restore-links.py" "$SOURCE" "$WORK"
printf 'Development working copy: %s\n' "$WORK"
(
  cd "$WORK"
  bun install
  bun termux/link-tools.ts "$WORK"
  bun run check
)
