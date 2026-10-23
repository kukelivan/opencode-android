import mdx from "@astrojs/mdx"
import { defineConfig } from "astro/config"

export default defineConfig({
  site: "https://opencode.ai",
  base: "/posts",
  output: "server",
  adapter: await deploymentAdapter(),
  integrations: [mdx()],
  vite: {
    server: {
      allowedHosts: true,
    },
  },
})

async function deploymentAdapter() {
  // Type checking does not run Workers. Importing the adapter itself loads
  // workerd, which has no Android binary, before Astro can check any source.
  if (process.platform === "android" && process.argv.includes("check")) return
  const cloudflare = await import("@astrojs/cloudflare")
  return cloudflare.default({ imageService: "passthrough" })
}
