# Blogger — Astro + Supabase + Cloudflare

Static-first Field Notes publication. `main` is the production deployment branch.

## Architecture

```text
Field Notes CMS (/admin)
   |-- Supabase Auth
   |-- Postgres + RLS
   |-- Supabase Storage (cms-media)
   |
   +-- Publish lifecycle -> Supabase pg_net -> secret Cloudflare Deploy Hook
                                                |
                                                v
                                      Astro SSG build
                                                |
                                                v
                                  Cloudflare Workers Static Assets
```

Reader requests do not query Supabase. Published rows are read at build time and emitted as static HTML.

## Environment

Browser configuration:

```dotenv
PUBLIC_SUPABASE_URL=
PUBLIC_SUPABASE_PUBLISHABLE_KEY=
```

Build-only credential:

```dotenv
SUPABASE_SERVICE_ROLE_KEY=
SITE_URL=https://your-public-site.example
```

Never expose the service-role key as a `PUBLIC_*` variable.

## Supabase migrations

Apply migrations in numeric order:

1. `0001_cms_mvp.sql` — profiles, posts, tags, post_tags and RLS.
2. `0002_cloudflare_publish_hook.sql` — pg_net publishing hook.
3. `0003_cms_media.sql` — public-read CMS image bucket with editor write policies.
4. `0004_publish_lifecycle.sql` — rebuild on publish, republish, unpublish and deletion of published posts.

Before migration 0002, store the Cloudflare Deploy Hook URL in Supabase Vault under the exact name `cloudflare_deploy_hook_url`. Treat that URL as a secret.

## CMS

Implemented MVP surfaces:

- Supabase Auth + role authorization.
- Posts list, search and draft/published filters.
- Draft creation, autosave, reopen and preview.
- Structured Paragraph, Heading, Quote, Code, Divider and Image blocks.
- Tags and topic pages.
- Slug collision handling.
- Image upload, alt text and caption.
- Static publishing automation.

## Publishing behavior

Only explicit publication lifecycle events rebuild production:

```text
Publish / republish -> rebuild
Unpublish           -> rebuild
Delete published    -> rebuild
Draft autosave      -> no rebuild
Published autosave  -> no rebuild
```

## Local development

```bash
cp .env.example .env
npm install
npm run dev
```

Without build-time Supabase credentials, reader pages use repository preview fixtures. The CMS itself requires the two public Supabase variables.

## Cloudflare

Production branch: `main`

```text
Build command:  npm run build
Deploy command: npx wrangler deploy
```

Keep non-production development on a separate Git branch and merge only accepted batches into `main` to avoid unnecessary production deployments.

## Acceptance checks

Before merging a CMS batch into `main`:

- migrations required by the batch have been applied;
- no service-role key, Vault secret or Deploy Hook URL is committed;
- draft create/save/reopen works;
- structured blocks round-trip without loss;
- image upload/preview works;
- published-only Astro build succeeds;
- homepage, article, topic, RSS, sitemap and 404 routes render;
- publish triggers one fresh Cloudflare build;
- unpublish/delete of published content removes it after the next build.
