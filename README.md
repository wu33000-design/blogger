# Blogger — Astro + Ghost + Cloudflare $0 Architecture

This repository contains a **pure static Astro frontend** for a headless Ghost publication.

## Architecture

- **Frontend:** Astro, static site generation only
- **CMS:** self-hosted Ghost
- **Source:** GitHub
- **Static hosting/CDN:** Cloudflare Pages
- **Media:** Cloudflare R2
- **Database:** external MySQL for Ghost

Astro fetches Ghost content **during the Cloudflare Pages build only**. No Ghost Content API key is exposed to visitors.

## Local development

```bash
cp .env.example .env
npm install
npm run dev
```

Required variables:

```dotenv
GHOST_URL=https://cms.example.com
GHOST_KEY=your_content_api_key
SITE_URL=https://blog.example.com
```

## Cloudflare Pages

Use:

- Production branch: `main`
- Build command: `npm run build`
- Build output directory: `dist`

Environment variables:

| Variable | Required | Purpose |
|---|---:|---|
| `GHOST_URL` | Yes | Public Ghost origin used by Astro at build time |
| `GHOST_KEY` | Yes | Ghost **Content API** key, used only during build |
| `SITE_URL` | Recommended | Canonical public Astro site URL |

Do **not** put Ghost Admin API keys or R2 secret keys in Cloudflare Pages. The static frontend does not need them.

## Ghost → Cloudflare R2 storage

Ghost stores uploads locally by default. For ephemeral/container hosting, install an S3-compatible Ghost storage adapter into the Ghost image and configure it to write to R2.

Cloudflare R2 S3 endpoint:

```
https://<CLOUDFLARE_ACCOUNT_ID>.r2.cloudflarestorage.com
```

Recommended R2 setup:

- bucket: `blog-media`
- storage class: Standard
- API token: Object Read & Write, scoped to this bucket
- public asset domain: preferably `https://media.example.com`
- do not use `r2.dev` as the production asset host

### Ghost config.production.json example

The exact outer key differs by Ghost/storage-adapter generation. Current Ghost supports adapter configuration; many S3 adapters also support the older `storage` block. For `ghost-storage-adapter-s3`, the common configuration is:

```json
{
  "url": "https://cms.example.com",
  "server": {
    "port": 2368,
    "host": "0.0.0.0"
  },
  "database": {
    "client": "mysql2",
    "connection": {
      "host": "MYSQL_HOST",
      "port": 3306,
      "user": "MYSQL_USER",
      "password": "MYSQL_PASSWORD",
      "database": "MYSQL_DATABASE",
      "ssl": {
        "rejectUnauthorized": true
      }
    }
  },
  "storage": {
    "active": "s3",
    "s3": {
      "accessKeyId": "R2_ACCESS_KEY_ID",
      "secretAccessKey": "R2_SECRET_ACCESS_KEY",
      "region": "auto",
      "bucket": "blog-media",
      "endpoint": "https://CLOUDFLARE_ACCOUNT_ID.r2.cloudflarestorage.com",
      "assetHost": "https://media.example.com",
      "forcePathStyle": true
    }
  }
}
```

### Equivalent environment variables

Ghost supports nested configuration using double underscores. Adapter-specific variables vary by adapter implementation, so prefer the adapter's documented names.

For `ghost-storage-adapter-s3`:

```dotenv
AWS_ACCESS_KEY_ID=<R2_ACCESS_KEY_ID>
AWS_SECRET_ACCESS_KEY=<R2_SECRET_ACCESS_KEY>
AWS_DEFAULT_REGION=auto
GHOST_STORAGE_ADAPTER_S3_PATH_BUCKET=blog-media
GHOST_STORAGE_ADAPTER_S3_ENDPOINT=https://<ACCOUNT_ID>.r2.cloudflarestorage.com
GHOST_STORAGE_ADAPTER_S3_ASSET_HOST=https://media.example.com
GHOST_STORAGE_ADAPTER_S3_FORCE_PATH_STYLE=true
```

Ghost itself can be configured with:

```dotenv
url=https://cms.example.com

database__client=mysql2
database__connection__host=<MYSQL_HOST>
database__connection__port=3306
database__connection__user=<MYSQL_USER>
database__connection__password=<MYSQL_PASSWORD>
database__connection__database=<MYSQL_DATABASE>

server__host=0.0.0.0
server__port=2368
```

## Zero-cost deployment roadmap

1. **Create Cloudflare R2**
   - Create a Standard bucket such as `blog-media`.
   - Create an R2 Object Read & Write API token scoped only to that bucket.
   - Attach a custom domain such as `media.example.com`.

2. **Provision MySQL**
   - Ghost's recommended production database is MySQL 8.
   - For a strict hobby-scale $0 deployment, use an always-free MySQL service where available.
   - Keep automated exports/backups because free tiers do not carry production SLAs.

3. **Deploy Ghost**
   - Build a Docker image containing Ghost plus the S3/R2 storage adapter.
   - Configure Ghost database variables and R2 credentials.
   - Ensure the service listens on `0.0.0.0:2368` (or the platform-provided port when required).
   - Create the Ghost owner account and a Custom Integration.
   - Copy the **Content API key**.

4. **Configure this repository**
   - Add the Astro frontend files.
   - Keep `.env` out of Git.
   - Push to `main`.

5. **Create Cloudflare Pages project**
   - Connect this GitHub repository.
   - Build command: `npm run build`
   - Output: `dist`
   - Add `GHOST_URL`, `GHOST_KEY`, and `SITE_URL`.

6. **Deploy**
   - Cloudflare builds every page from Ghost into static HTML.
   - Verify homepage, post routes, canonical URLs, and R2 media URLs.

7. **Publishing workflow**
   - Publishing in Ghost does **not by itself rebuild Cloudflare Pages**.
   - Configure a Ghost webhook or small relay to trigger a Cloudflare Pages Deploy Hook after publish/update/unpublish.
   - This preserves full SSG while keeping content changes automatic.

## $0 caveat

The Astro + Cloudflare Pages + R2 portion can comfortably remain inside free tiers for a small blog. The difficult component is **stateful Ghost itself**, because it needs both application compute and a persistent SQL database.

A free web container with ephemeral disk is acceptable only because media is moved to R2 and the database is external. It is still hobby infrastructure: sleeping, cold starts, lack of SLA, quota changes, and provider policy changes are possible.

For anything business-critical, treat the zero-cost setup as a prototype/hobby deployment rather than guaranteed production infrastructure.


<!-- cloudflare-internal-preview-trigger: 2026-09-20 -->
