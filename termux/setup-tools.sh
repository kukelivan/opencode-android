#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

: "${HOME:?Run inside Termux}"
: "${PREFIX:?Run inside Termux}"
SOURCE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLS="${OPENCODE_TERMUX_TOOLS:-$HOME/.local/share/opencode-termux-tools}"
for tool in node npm cargo go clang git python bun; do
  if ! command -v "$tool" >/dev/null; then
    printf 'Missing %s. Install prerequisites: pkg install nodejs-lts rust golang clang git python\n' "$tool" >&2
    exit 1
  fi
done
test "$(uname -m)" = aarch64
test "$(go env GOOS)" = android
mkdir -p "$TOOLS/bin" "$TOOLS/src" "$TOOLS/build/ast-grep"

if [ ! -x "$TOOLS/bin/ast-grep" ] || [ "$("$TOOLS/bin/ast-grep" --version)" != 'ast-grep 0.44.0' ]; then
  CARGO_TARGET_DIR="$TOOLS/build/ast-grep" cargo install ast-grep \
    --version 0.44.0 --locked --root "$TOOLS" --jobs 2
fi

if [ ! -x "$TOOLS/bin/tsc" ] || [ "$("$TOOLS/bin/tsc" --version)" != 'Version 7.0.2' ]; then
  TS_SOURCE="$TOOLS/src/typescript-go-7.0.2"
  if [ ! -d "$TS_SOURCE/.git" ]; then
    git init "$TS_SOURCE"
    git -C "$TS_SOURCE" fetch --depth=1 https://github.com/microsoft/typescript-go.git \
      2bd066d87f5bafd315be9f40889d0a60b9e58e0b
    git -C "$TS_SOURCE" checkout --detach FETCH_HEAD
  fi
  if git -C "$TS_SOURCE" apply --check "$SOURCE/termux/typescript-android.patch"; then
    git -C "$TS_SOURCE" apply "$SOURCE/termux/typescript-android.patch"
  else
    git -C "$TS_SOURCE" apply --reverse --check "$SOURCE/termux/typescript-android.patch"
  fi
  (
    cd "$TS_SOURCE"
    GOMAXPROCS=2 go build -p 2 -trimpath -ldflags='-s -w' -o "$TOOLS/bin/tsc" ./cmd/tsgo
  )
fi

# The Astro compiler has an official WASI implementation. npm's force flag is
# needed only because it labels this portable module cpu=wasm32, not arm64.
npm install --prefix "$TOOLS/wasm" --force --ignore-scripts --no-audit --no-fund \
  @astrojs/compiler-binding-wasm32-wasi@0.3.2
python - "$TOOLS" <<'PY'
import pathlib, sys
root = pathlib.Path(sys.argv[1]) / "wasm/node_modules/@astrojs/compiler-binding-wasm32-wasi"
for name, original in [
    ("astro.wasi.cjs", "__nodePath.parse(process.cwd()).root"),
    ("wasi-worker.mjs", "parse(process.cwd()).root"),
]:
    file = root / name
    text = file.read_text()
    replacement = "process.platform === 'android' ? process.cwd() : " + original
    if replacement not in text:
        if original not in text:
            raise SystemExit(f"Unexpected Astro WASI loader: {file}")
        file.write_text(text.replace(original, replacement, 1))
PY
"$TOOLS/bin/ast-grep" --version
"$TOOLS/bin/tsc" --version
for name in ast-grep sg; do
  if [ ! -e "$PREFIX/bin/$name" ] && [ ! -L "$PREFIX/bin/$name" ]; then
    ln -s "$TOOLS/bin/$name" "$PREFIX/bin/$name"
  fi
done
printf 'Development tools: %s\n' "$TOOLS"
