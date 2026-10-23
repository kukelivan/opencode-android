#!/data/data/com.termux/files/usr/bin/bash
# Упаковка собранного бинарника; установку и публикацию скрипт не выполняет.
set -euo pipefail

: "${PREFIX:?Run inside Termux}"
: "${TMPDIR:?TMPDIR must point to internal Termux storage}"
SOURCE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${1:?Usage: bash termux/package.sh <deb-version>}"
BIN="$SOURCE/dist/opencode-android-arm64"
test "$PREFIX" = /data/data/com.termux/files/usr
test -f "$BIN"
command -v dpkg-deb >/dev/null
command -v python >/dev/null
dpkg --validate-version "$VERSION"

umask 022
STAGE="$(mktemp -d "$TMPDIR/opencode-package.XXXXXX")"
trap 'rm -rf "$STAGE"' EXIT
chmod 755 "$STAGE"
mkdir -p "$STAGE/DEBIAN" "$STAGE$PREFIX/bin" \
  "$STAGE$PREFIX/share/doc/opencode-android"
install -m 755 "$BIN" "$STAGE$PREFIX/bin/opencode"
install -m 644 "$SOURCE/LICENSE" "$STAGE$PREFIX/share/doc/opencode-android/LICENSE"
install -m 644 "$SOURCE/README.md" "$STAGE$PREFIX/share/doc/opencode-android/README.md"
"$STAGE$PREFIX/bin/opencode" --version
SIZE="$(python -c 'import os,sys; print((sum(os.path.getsize(os.path.join(p,n)) for p,_,ns in os.walk(sys.argv[1]) for n in ns)+1023)//1024)' "$STAGE$PREFIX")"
cat > "$STAGE/DEBIAN/control" <<EOF
Package: opencode-android
Version: $VERSION
Architecture: aarch64
Maintainer: kukelivan <kukelivan@users.noreply.github.com>
Depends: ripgrep
Provides: opencode
Conflicts: opencode
Installed-Size: $SIZE
Section: devel
Priority: optional
Homepage: https://github.com/kukelivan/opencode-android
Description: Experimental OpenCode Android/Termux build
 Android ARM64 build with recursive file watching and on-device development tools.
 Uses the Bun, OpenTUI and PTY components from bd-loser's ecosystem.
EOF
mkdir -p "$SOURCE/dist/release"
# GitHub заменяет ~ в именах приложений к релизу на точку.
FILENAME_VERSION="${VERSION//\~/.}"
dpkg-deb -Zxz -z3 --threads-max=2 --root-owner-group --build "$STAGE" \
  "$SOURCE/dist/release/opencode-android_${FILENAME_VERSION}_aarch64.deb"
