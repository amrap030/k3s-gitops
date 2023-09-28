import React from "react";
import { DocsThemeConfig } from "nextra-theme-docs";
import { Icon } from "@iconify/react";

const config: DocsThemeConfig = {
  logo: (
    <>
      <Icon icon="logos:kubernetes" height={32} />
      <span style={{ marginLeft: "12px" }}>amrap030/k3s-gitops</span>
    </>
  ),
  project: {
    link: "https://github.com/amrap030/k3s-gitops",
  },
  docsRepositoryBase: "https://github.com/amrap030/k3s-gitops",
  footer: {
    text: "Made with ❤️ Kevin Hertwig © 2023",
  },
};

export default config;
