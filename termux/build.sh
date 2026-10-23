#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

SOURCE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
: "${PREFIX:?Run inside Termux}"
: "${TMPDIR:?TMPDIR must point to internal Termux storage}"
for tool in bun python curl tar file git rg; do
  command -v "$tool" >/dev/null
done
test "$(uname -m)" = aarch64
test "$(bun --version)" = 1.4.3

# Copy the working tree, including local changes, to a fresh directory. Android
# shared storage cannot host executable dependencies or node_modules symlinks.
BUILD="$(mktemp -d "$TMPDIR/opencode-android.XXXXXX")"
tar --exclude=.git --exclude=node_modules --exclude=dist --exclude=.turbo \
  -C "$SOURCE" -cf - . | tar -C "$BUILD" -xf -
python "$SOURCE/termux/restore-links.py" "$SOURCE" "$BUILD"
printf 'Build tree: %s\n' "$BUILD"

export OPENCODE_CHANNEL="${OPENCODE_CHANNEL:-dev}"
REVISION="$(git -C "$SOURCE" -c safe.directory="$SOURCE" rev-parse --short=10 HEAD)"
export OPENCODE_VERSION="${OPENCODE_VERSION:-$(python -c 'import json,sys; print(json.load(open(sys.argv[1]))["version"])' "$SOURCE/package.json")-dev.android.$REVISION}"

(
  cd "$BUILD"
  bun install
  TOOLS="${OPENCODE_TERMUX_TOOLS:-$HOME/.local/share/opencode-termux-tools}"
  if [ -x "$TOOLS/bin/ast-grep" ] && [ -x "$TOOLS/bin/tsc" ]; then
    bun termux/link-tools.ts "$BUILD"
  fi
)

# Match the Android fork's dev pins. Both npm Linux prebuilts link glibc.
curl -fL --retry 3 \
  https://github.com/bd-loser/bun-termux/releases/download/bun-pty-v0.4.11/librust_pty_arm64_bionic.so \
  -o "$BUILD/bun-pty-bionic.so"
python - "$BUILD" <<'PY'
import pathlib, shutil, sys
root = pathlib.Path(sys.argv[1])
for target in (root / "node_modules").glob("**/bun-pty/rust-pty/target/release/librust_pty_arm64.so"):
    shutil.copyfile(root / "bun-pty-bionic.so", target)
PY

mkdir -p "$BUILD/node_modules/@opencode-ai/pty-linux-arm64-gnu/bin"
curl -fL --retry 3 \
  https://github.com/bd-loser/bun-termux/releases/download/opencode-pty-v0.2.0/opencode-pty-android-aarch64 \
  -o "$BUILD/node_modules/@opencode-ai/pty-linux-arm64-gnu/bin/opencode-pty"
chmod 755 "$BUILD/node_modules/@opencode-ai/pty-linux-arm64-gnu/bin/opencode-pty"
python - "$BUILD" <<'PY'
import json, pathlib, sys
target = pathlib.Path(sys.argv[1]) / "node_modules/@opencode-ai/pty-linux-arm64-gnu/package.json"
target.write_text(json.dumps({
    "name": "@opencode-ai/pty-linux-arm64-gnu",
    "version": "0.2.0",
    "exports": {"./package.json": "./package.json", "./bin/opencode-pty": "./bin/opencode-pty"}
}, indent=2) + "\n")
PY

(
  cd "$BUILD"
  bun packages/cli/script/build.ts --target=opencode-linux-arm64 --skip-install --skip-web-ui
)
BIN="$BUILD/packages/cli/dist/cli-linux-arm64/bin/opencode"
"$BIN" --version
"$BIN" --help
mkdir -p "$SOURCE/dist"
cp "$BIN" "$SOURCE/dist/opencode-android-arm64"
cp "$BUILD/bun.lock" "$SOURCE/bun.lock"
sha256sum "$SOURCE/dist/opencode-android-arm64"
printf 'Artifact: %s/dist/opencode-android-arm64\nExecutable: %s\n' "$SOURCE" "$BIN"
