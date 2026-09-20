# Blogger — Astro + Ghost + Cloudflare

Static-first publication frontend. `main` is the deployment branch.

## Runtime architecture

```text
Ghost editor
   │ Content API
   ▼
Cloudflare build ──> Astro SSG ──> dist/ ──> Workers Static Assets
                         │
                         └── feature images/media served from R2
```

Readers never need a live Ghost connection. Ghost credentials exist only in the build environment.

## Current review mode

If `GHOST_URL` or `GHOST_KEY` is absent, builds intentionally use `src/data/preview-posts.js`. This keeps the review site deployable before CMS provisioning.

Implemented frontend features include article routes, topics, author/date/reading-time metadata, featured content, RSS, sitemap, robots.txt, Open Graph/Twitter metadata, Article JSON-LD, copy-link sharing, adjacent-article navigation, 404, responsive layout and accessibility basics.

## Cloudflare build

Production branch: `main`

```text
Build command:  npm run build
Deploy command: npx wrangler deploy
```

Set these build variables when Ghost is ready:

```dotenv
GHOST_URL=https://cms.example.com
GHOST_KEY=<Ghost Content API key>
SITE_URL=https://your-public-site.example
```

Use a **Content API key**, never a Ghost Admin API key.

### Publishing trigger

Because this is SSG, a Ghost publish/update/unpublish event must cause a new Cloudflare build.

Preferred flow:

1. Create a Cloudflare build/deploy hook or equivalent authenticated build trigger for this Worker project.
2. In Ghost Admin, create a webhook for `post.published`.
3. Add additional webhooks for `post.edited`, `post.unpublished`, and `post.deleted` when supported by the selected Ghost version/integration.
4. Point those webhooks at the Cloudflare trigger.
5. Publish a test post and verify that a new build reads the new Ghost content before deployment.

Do not store the trigger URL in this repository. Treat it as a deployment credential.

## Media / R2

Ghost should write uploads to R2 through an S3-compatible storage adapter. Keep the bucket credentials with Ghost, not Astro/Cloudflare frontend code. The Content API returns the resulting feature-image/media URLs and Astro emits them into static HTML.

Recommended boundary:

- Ghost: editorial state
- MySQL: persistent CMS data
- R2: persistent media
- Astro: build-time renderer
- Cloudflare Workers Static Assets: reader-facing static site

## Local development

```bash
cp .env.example .env
npm install
npm run dev
```

Without Ghost variables this runs against mock content. With them it reads the real Content API.

## Deployment acceptance check

After every infrastructure change verify:

- Cloudflare build references the latest `main` commit.
- Homepage, article, topic and 404 routes render.
- `/rss.xml`, `/sitemap-index.xml` and `/robots.txt` respond.
- No Ghost Content API key, Admin key, R2 credential or build-trigger URL appears in generated HTML or the repository.
- A Ghost content change produces a fresh static deployment before considering publishing automation complete.

## Zero-cost caveat

The static frontend can fit comfortably within free Cloudflare allowances at small scale. Ghost is stateful and requires application compute plus persistent MySQL; free hosting should be treated as prototype/hobby infrastructure unless its reliability guarantees meet the publication's needs.
