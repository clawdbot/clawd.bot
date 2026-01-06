import { defineConfig } from 'astro/config';

export default defineConfig({
  site: 'https://clawd.bot',
  output: 'static',
  build: {
    assets: 'assets'
  }
});
