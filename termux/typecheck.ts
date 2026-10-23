import { fileURLToPath } from "node:url"

// Run the same workspace typecheck scripts without Turborepo's missing Android
// executable. Sequential scheduling bounds memory usage on a phone.
const command =
  process.platform === "android"
    ? ["bun", "run", "--workspaces", "--sequential", "--no-exit-on-error", "--if-present", "typecheck"]
    : ["bun", "turbo", "typecheck", "--concurrency=3"]
const child = Bun.spawn(command, {
  cwd: fileURLToPath(new URL("..", import.meta.url)),
  stdin: "inherit",
  stdout: "inherit",
  stderr: "inherit",
})
process.exit(await child.exited)
