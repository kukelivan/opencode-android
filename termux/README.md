# OpenCode dev for Android / Termux

Android port of upstream `dev`, using the native dependency versions from
[`bd-loser/opencode-bionic`, branch `dev`](https://github.com/bd-loser/opencode-bionic/tree/dev).

## Inputs

- Upstream: `anomalyco/opencode`, commit `c93aaae371` (`2.1.2`).
- Runtime: `bd-loser/bun-termux` `1.4.3-patched` (not upstream Linux Bun).
- OpenTUI: `@androidtui/{core,keymap,solid,core-android-arm64}` `0.6.6`.
- Native bun-pty library: `0.4.11`.
- Persistent PTY daemon: `opencode-pty` `0.2.0`, Bionic ARM64 build.
- Runtime search dependency: Termux `ripgrep` (`pkg install ripgrep`).

## Build

Run from Termux with the patched Bun installed:

```bash
bash termux/build.sh
```

The script copies the working tree into a fresh directory under `$TMPDIR`,
installs dependencies there, embeds the Android PTY binaries, and builds a
self-contained executable. The working source checkout can remain in Android
shared storage. The resulting binary is copied to `dist/opencode-android-arm64`.
The script prints the internal executable's path for immediate testing.

The CLI build disables bytecode and code splitting only on Android. It avoids
loading Parcel's glibc watcher binding; recursive watching uses Bun's Android
`fs.watch`, with ignore filtering. Other platforms retain their upstream build
options and watcher backends.

This build omits the web UI assets (`--skip-web-ui`); it provides the terminal
interface, CLI, and API server.

## Install

```bash
bash termux/install.sh
opencode --version
opencode --standalone
```

The installer saves a timestamped backup of the current `$PREFIX/bin/opencode`
before replacing it. Restart the running OpenCode after installation. Android
shared storage does not allow running the artifact directly.

`--standalone` starts a private server. Ordinary `opencode` uses upstream's
managed background service. Android can stop background processes.

To restore the previous version, copy the backup path printed by the installer
back to `$PREFIX/bin/opencode`. A subsequent apt/pkg package upgrade can
overwrite a manually installed binary.

## Verification on Android ARM64

- Compiled binary version and CLI help.
- Isolated API server with a fresh database.
- Persistent PTY creation, actual Bash command execution, and PTY removal.
- File search using the Termux ripgrep fallback.
- Terminal interface rendering inside a real pseudo-terminal.
- Recursive nested-file watcher notifications and ignored-directory filtering.

## Native development tools

```bash
pkg install nodejs-lts rust golang clang git python
bash termux/setup-tools.sh
ast-grep --version
```

The setup script builds ast-grep `0.44.0` for Bionic and native TypeScript
`7.0.2` from its exact upstream source commit. The TypeScript patch prevents a
`fanotify_init` probe that Android terminates with SIGSYS; the normal inotify
backend remains available. Binaries persist under
`$HOME/.local/share/opencode-termux-tools/bin`. The script also exposes
`ast-grep` and `sg` on Termux's PATH when those names are not already installed.

To prepare an internal development copy, restore symbolic links flattened by
Android shared storage, install dependencies, and run the full checks:

```bash
bash termux/check.sh
```

The script prints the working-copy path. In that copy you can run ordinary
commands such as `bun run test:lint-rules` and package-local `bun typecheck`.
After a subsequent `bun install`, rerun `bun termux/link-tools.ts` to restore
the generated Android tool links. The TypeScript platform adapter supports
both its CLI and its JS API, without changing the installed npm package.

On Android, `bun run typecheck` runs every workspace's actual typecheck script
sequentially through Bun, because Turborepo has no Android executable. Failures
are reported rather than skipped. Other platforms retain Turborepo.

The official Astro WASI compiler is also installed, with its preopened path
restricted to the working directory because Android denies opening `/`.
The website configurations load their Cloudflare adapter lazily. On Android,
`astro check` validates their sources without importing the deployment runtime.
Builds and deployment commands still load the real adapter; no mock runtime is
substituted. Cloudflare `workerd` has no Android build, so website deployment
builds still need a supported Cloudflare development environment.

Verified on-device with the prepared internal working copy:

- Full `bun run check`: exit code **0**, including both Astro sites.
- `bun run test:lint-rules`: **6** rule groups passed.
- `bun run test:effect-simplification-rules`: **10** rule groups passed.
- Website `bun run check:generated`: exit code **0**.
- Website deployment `bun run build`: blocked by unsupported Android workerd.

The full check reports existing upstream lint warnings; they are not suppressed
by the Android adapter.
