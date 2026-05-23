const baseURL =
  process.env.DOCS_BASE_URL ||
  (process.env.NODE_ENV === 'production' ? '/forge/' : '/');
const siteUrl =
  process.env.DOCS_SITE_URL ||
  'https://innovativedevsolutions.github.io/forge';

process.env.NUXT_SITE_URL ||= siteUrl;
process.env.NUXT_PUBLIC_SITE_URL ||= siteUrl;

export default defineNuxtConfig({
  extends: ['docus'],

  site: {
    url: siteUrl
  },

  llms: {
    domain: siteUrl
  },

  robots: {
    robotsTxt: false
  },

  app: {
    baseURL,
    buildAssetsDir: '/_nuxt/'
  },

  nitro: {
    preset: 'static',
    prerender: {
      crawlLinks: true,
      routes: ['/']
    }
  },

  devtools: {
    enabled: false
  },

  compatibilityDate: '2026-04-21'
});
