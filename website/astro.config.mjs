// @ts-check
import { defineConfig } from "astro/config";
import starlight from "@astrojs/starlight";

// https://astro.build/config
export default defineConfig({
  site: "https://signet.tylerbutler.com",
  integrations: [
    starlight({
      title: "signet",
      description:
        "Fluid Framework token primitives for Gleam: document-token claims, HS256 JWT signing and verification, and claim validation.",
      logo: {
        src: "./src/assets/seal.svg",
        alt: "signet seal mark",
        replacesTitle: false,
      },
      social: [
        {
          icon: "github",
          label: "GitHub",
          href: "https://github.com/tylerbutler/signet",
        },
      ],
      customCss: [
        "@fontsource-variable/bricolage-grotesque/index.css",
        "@fontsource-variable/literata/index.css",
        "@fontsource-variable/jetbrains-mono/index.css",
        "./src/styles/tokens.css",
        "./src/styles/starlight.css",
      ],
      sidebar: [
        { label: "Quickstart", slug: "quickstart" },
        {
          label: "Reference",
          items: [
            { label: "signet/types", slug: "reference/types" },
            { label: "signet/jwt", slug: "reference/jwt" },
          ],
        },
      ],
      pagination: false,
      lastUpdated: false,
      tableOfContents: { minHeadingLevel: 2, maxHeadingLevel: 3 },
      editLink: {
        baseUrl:
          "https://github.com/tylerbutler/signet/edit/main/website/",
      },
    }),
  ],
});
