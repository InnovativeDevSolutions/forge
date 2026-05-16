const repoUrl =
  process.env.DOCS_REPO_URL ||
  'https://github.com/InnovativeDevSolutions/forge';
const repoBranch = process.env.DOCS_REPO_BRANCH || 'master';
const siteUrl =
  process.env.DOCS_SITE_URL ||
  'https://innovativedevsolutions.github.io/forge';

export default defineAppConfig({
  site: {
    name: 'Forge Framework',
    description:
      'Persistent Arma 3 framework with Rust services, SurrealDB storage, and browser-backed client UIs.',
    url: siteUrl,
    socials: {
      github: 'InnovativeDevSolutions/forge'
    }
  },
  github: {
    url: repoUrl,
    branch: repoBranch,
    rootDir: 'docus'
  },
  footer: {
    credits: 'Copyright © 2025-2026 Forge Framework',
    links: [
      {
        icon: 'simple-icons:github',
        href: repoUrl,
        target: '_blank'
      }
    ]
  }
});
