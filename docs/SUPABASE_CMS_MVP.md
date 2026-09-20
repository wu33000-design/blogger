# Supabase CMS MVP

Status: **Active MVP direction**  
Previous Firebase implementation: **paused, not production authority**

## Goal

Use Supabase as the complete CMS backend for the first usable Field Notes MVP:

- Supabase Auth for editor login.
- Postgres for posts, tags and profiles.
- Row Level Security for authorization.
- Existing Astro SSG for the reader site.
- Existing Cloudflare static deployment.
- Supabase Storage is available later if MVP media is needed; R2 remains an option.

Reader requests do not depend on Supabase. Astro reads published rows at build time when `SUPABASE_SERVICE_ROLE_KEY` is configured; otherwise the repository preview fixtures remain the fallback.

## MVP architecture

```text
/admin (Astro static UI)
       |
       +--> Supabase Auth
       +--> Supabase Data API
              |
              +--> profiles
              +--> posts
              +--> tags
              +--> post_tags

Publish
   -> later: authenticated deploy trigger
   -> Astro build reads published posts
   -> Cloudflare static output
```

## Environment

Browser:

```text
PUBLIC_SUPABASE_URL
PUBLIC_SUPABASE_PUBLISHABLE_KEY
```

Build only:

```text
SUPABASE_SERVICE_ROLE_KEY
```

Never expose the service-role key to browser code.

## Bootstrap

1. Create a Supabase project.
2. Run `supabase/migrations/0001_cms_mvp.sql` in the SQL Editor.
3. Create the first user in Authentication.
4. Insert that user's UUID into `public.profiles` with `role='admin'`.
5. Configure the two `PUBLIC_SUPABASE_*` values in the Cloudflare build environment.
6. Test login, draft creation, autosave and reopen.

## MVP gates

- [x] Supabase client contract.
- [x] SQL schema.
- [x] RLS policies.
- [x] Admin UI reused from Firebase prototype.
- [ ] Live Supabase project connected.
- [ ] Admin login verified.
- [ ] Draft create/save/reopen verified.
- [ ] Slug uniqueness UX.
- [ ] Tags CRUD.
- [ ] Structured block editor.
- [x] Build-time published-post adapter.
- [x] Publish -> Cloudflare rebuild (migration ready; requires Deploy Hook URL in Supabase Vault).
- [ ] Media.
- [ ] Firebase prototype files removed after Supabase live validation.

## Scope rule

Do not expand the MVP into SSR merely to use Supabase. The current admin can authenticate in the browser while the reader site stays static. Server-side functionality is introduced only where a secret-bearing operation requires it.


<!-- deployment trigger: Supabase environment configured in Cloudflare -->

<!-- deployment trigger: Supabase service-role build credential configured in Cloudflare -->


## Automatic publish deployment

Cloudflare Workers Builds supports Deploy Hooks. Create one for `main`, then store its full URL in Supabase Vault with the exact secret name:

`cloudflare_deploy_hook_url`

Run `supabase/migrations/0002_cloudflare_publish_hook.sql` after the Vault secret exists.

The database trigger runs only when Publish/republish changes `published_at`. Normal editor autosaves do not trigger builds. The hook URL is never exposed to browser code or committed to Git.
