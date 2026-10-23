import mdx from "@astrojs/mdx"
import { unified } from "@astrojs/markdown-remark"
import { defineConfig } from "astro/config"
import remarkDocsLinks from "./src/docs/remark-links"
import rehypeTableScroll from "./src/docs/rehype-table-scroll"

const base = "/v2/"

export default defineConfig({
  site: process.env.CLOUDFLARE_ENV === "production" ? "https://opencode.ai" : "https://dev.opencode.ai",
  base,
  output: "server",
  adapter: await deploymentAdapter(),
  integrations: [mdx()],
  markdown: {
    processor: unified({ remarkPlugins: [[remarkDocsLinks, { base }]], rehypePlugins: [rehypeTableScroll] }),
    shikiConfig: {
      themes: {
        light: "github-light",
        dark: "github-dark",
      },
      transformers: [
        {
          name: "code-block-title",
          root(root) {
            const title = this.options.meta?.__raw?.match(/title="([^"]+)"/)?.[1]
            if (!title) return
            const pre = root.children[0]
            if (!pre || pre.type !== "element") return
            root.children = [
              {
                type: "element",
                tagName: "figure",
                properties: { className: ["astro-code-figure"] },
                children: [
                  {
                    type: "element",
                    tagName: "figcaption",
                    properties: { className: ["astro-code-title"] },
                    children: [{ type: "text", value: title }],
                  },
                  pre,
                ],
              },
            ]
          },
        },
      ],
    },
  },
  vite: {
    server: {
      allowedHosts: true,
    },
  },
})

async function deploymentAdapter() {
  // Avoid loading the deployment runtime during Android-only source checks.
  if (process.platform === "android" && process.argv.includes("check")) return
  const cloudflare = await import("@astrojs/cloudflare")
  return cloudflare.default({ imageService: "passthrough" })
}
