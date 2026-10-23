import { mkdir, rm, symlink } from "node:fs/promises"
import path from "node:path"
import os from "node:os"

if (process.platform !== "android" || process.arch !== "arm64") {
  throw new Error("This tool adapter requires Android ARM64")
}
const root = path.resolve(process.argv[2] ?? process.cwd())
const tools = process.env.OPENCODE_TERMUX_TOOLS ?? path.join(os.homedir(), ".local/share/opencode-termux-tools")
const pkg = await Bun.file(path.join(root, "package.json")).json()
const astVersion = pkg.devDependencies["@ast-grep/cli"]
const tsVersion = pkg.workspaces.catalog["@typescript/native"].replace("npm:typescript@", "")
for (const [name, expected] of [
  ["ast-grep", `ast-grep ${astVersion}`],
  ["tsc", `Version ${tsVersion}`],
]) {
  const result = Bun.spawnSync([path.join(tools, "bin", name), "--version"])
  if (result.exitCode !== 0 || result.stdout.toString().trim() !== expected) {
    throw new Error(`Missing or mismatched ${name}. Run bash termux/setup-tools.sh first.`)
  }
}

// Native TypeScript's CLI and JS API both resolve this platform package. The
// compiler embeds its standard libraries, so the executable is sufficient.
const native = path.join(root, "node_modules/@typescript/typescript-android-arm64")
await mkdir(path.join(native, "lib"), { recursive: true })
await Bun.write(
  path.join(native, "package.json"),
  JSON.stringify(
    {
      name: "@typescript/typescript-android-arm64",
      version: tsVersion,
      exports: { "./package.json": "./package.json" },
    },
    null,
    2,
  ) + "\n",
)
await rm(path.join(native, "lib/tsc"), { force: true })
await symlink(path.join(tools, "bin/tsc"), path.join(native, "lib/tsc"))

// Bun links CLI shims before their unsupported npm postinstall can run. Replace
// only generated bin links; leave installed package contents untouched.
for (const name of ["ast-grep", "sg"]) {
  await rm(path.join(root, "node_modules/.bin", name), { force: true })
  await symlink(path.join(tools, "bin", name), path.join(root, "node_modules/.bin", name))
}
const wasm = path.join(tools, "wasm/node_modules/@astrojs/compiler-binding-wasm32-wasi")
if (await Bun.file(path.join(wasm, "package.json")).exists()) {
  const target = path.join(root, "node_modules/@astrojs/compiler-binding-wasm32-wasi")
  await mkdir(path.dirname(target), { recursive: true })
  await rm(target, { recursive: true, force: true })
  await symlink(wasm, target)
}
console.log(`Android development tools linked in ${root}`)
