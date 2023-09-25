const withNextra = require("nextra")({
  theme: "nextra-theme-docs",
  themeConfig: "./theme.config.tsx",
});

module.exports = withNextra({
  basePath: "/k3s-gitops",
  output: "export",
  distDir: "dist",
  images: {
    unoptimized: true,
  },
});
