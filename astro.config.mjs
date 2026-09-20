import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';

export default defineConfig({
  site: process.env.SITE_URL || 'https://blogger-internal.wu33000.workers.dev',
  output: 'static',
  trailingSlash: 'never',
  integrations: [sitemap()],
});
