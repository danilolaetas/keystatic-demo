// @ts-check
import node from "@astrojs/node";
import react from "@astrojs/react";
import starlight from "@astrojs/starlight";
import keystatic from "@keystatic/astro";
import { defineConfig } from "astro/config";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));

// https://astro.build/config
export default defineConfig({
  site: process.env.SITE_URL || "https://d8bdd5ff1df2168d84cb3c157ea334b9.app.cloudhub.etas.com",
  output: "server",
  adapter: node({ mode: "standalone" }),
  security: {
    checkOrigin: false,
  },
  server: { host: "0.0.0.0" },
  vite: {
    resolve: {
      alias: {
        "virtual:keystatic-config": resolve(__dirname, "keystatic.config.ts"),
      },
    },
  },
  integrations: [
    starlight({
      title: "ETAS Docs",
      customCss: [
        "@calponia/common-ui-primereact-theme/theme.css",
        "./src/styles/custom.css",
      ],
      components: {
        Header: "./src/components/overrides/Header.astro",
        Footer: "./src/components/overrides/Footer.astro",
        ThemeProvider: "./src/components/overrides/ThemeProvider.astro",
        PageSidebar: "./src/components/overrides/PageSidebar.astro",
      },
      sidebar: [
        {
          label: "FAQ",
          autogenerate: { directory: "faqs" },
        },
        {
          label: "Release Notes",
          autogenerate: { directory: "releases" },
        },
      ],
    }),
    react(),
    keystatic(),
  ],
});
