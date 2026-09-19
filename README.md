# Blogger — Astro + Ghost + Cloudflare $0 Architecture

This repository contains a **pure static Astro frontend** for a headless Ghost publication.

> Internal review deployment is currently using local mock content so the frontend can be reviewed before Ghost is connected.

## Current deployment

- **Frontend:** Astro static site generation
- **Source:** GitHub `main`
- **Hosting:** Cloudflare Workers Static Assets
- **CMS:** Ghost (planned build-time content source)
- **Media:** Cloudflare R2 (planned)
- **Database:** external MySQL for Ghost

Astro fetches Ghost content at build time only. When `GHOST_URL` and `GHOST_KEY` are absent, the current review build uses `src/data/preview-posts.js`.

## Local development

```bash
cp .env.example .env
npm install
npm run dev
```

Optional Ghost variables:

```dotenv
GHOST_URL=https://cms.example.com
GHOST_KEY=your_content_api_key
SITE_URL=https://blog.example.com
```

## Cloudflare Workers build

Use:

- Production branch: `main`
- Build command: `npm run build`
- Deploy command: `npx wrangler deploy`
- Static asset directory: `dist` (configured in `wrangler.jsonc`)

The internal review UI can build without Ghost credentials. When Ghost is connected, use a **Content API** key only; never expose a Ghost Admin API key to the frontend.

## Ghost → Cloudflare R2

For the eventual Ghost service, store media in R2 through an S3-compatible Ghost storage adapter rather than relying on ephemeral container storage.

Recommended separation:

- Ghost: editorial CMS
- external MySQL: persistent CMS data
- R2: persistent media
- Astro: build-time content consumer
- Cloudflare Workers Static Assets: generated public/review frontend

## Publishing workflow

After Ghost integration, publishing or updating an article must trigger a new Astro build. A Ghost webhook can call the deployment/build mechanism so the generated static site stays synchronized with the CMS.

## Zero-cost caveat

Astro and small static deployments can fit comfortably within Cloudflare free allowances. Ghost is the difficult part of a strict $0 architecture because it requires application compute plus persistent SQL. Treat free Ghost hosting as prototype/hobby infrastructure unless the selected provider offers the reliability required by the publication.
