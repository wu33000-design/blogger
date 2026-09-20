# Firebase CMS Development Plan

Status: **Implementation in progress — Phase 0 substantially complete; Phase 1 started**  
Repository: `wu33000-design/blogger`  
Deployment branch: `main`

## 1. Objective

Replace the planned self-hosted Ghost infrastructure with a lightweight, cloud-only CMS built on Firebase while preserving the current Astro static-first publication architecture.

The CMS should reproduce the useful **information architecture, interaction patterns, and writing experience** of Ghost Admin without presenting itself as Ghost or using Ghost branding. The product identity remains **Field Notes CMS**.

Primary goals:

1. Cloud-only; no local hosting requirement.
2. Low operational overhead and a realistic path to near-zero cost at current scale.
3. Ghost-inspired editorial UX: content-first editor, posts list, drafts/published states, tags, metadata drawer, preview and publish.
4. Reader traffic must not depend on Firebase availability or generate Firestore reads per page view.
5. Preserve the existing Astro frontend and its current post data contract wherever practical.
6. Keep deployment credentials and privileged Firebase credentials out of the repository and generated frontend.

## 2. Target architecture

```text
Author
  |
  v
Field Notes CMS (/admin)
  |-- Firebase Authentication
  |-- Cloud Firestore
  |
  +-- later: media upload -> Cloudflare R2

Publish
  |
  v
Authenticated deployment trigger
  |
  v
Astro static build
  |
  |-- reads published content from Firestore at build time
  v
Cloudflare Workers Static Assets
  |
  v
Reader
```

### Architectural boundary

Firebase is the **authoring/data layer**, not the reader-facing runtime.

Readers receive generated static HTML/assets from Cloudflare. A normal page view must not query Firestore.

## 3. Components retained

Keep:

- Astro static site generation.
- GitHub repository and `main` deployment branch.
- Cloudflare Workers Static Assets.
- Current minimalist reader-facing design.
- Existing routes: homepage, articles, topics, RSS, sitemap, robots and 404.
- Existing normalized post shape where possible:
  - `title`
  - `slug`
  - `excerpt`
  - `html`
  - `tags`
  - `authors`
  - `primary_tag`
  - `feature_image`
  - `reading_time`
  - `featured`
  - publication timestamps

Retire after Firebase migration is accepted:

- Ghost runtime.
- MySQL requirement.
- Ghost Docker/Cloud Run deployment plan.
- Ghost Content API as the production content source.

Do not remove the existing preview/mock fallback until the Firebase publishing path is validated end to end.

## 4. CMS UX specification

### 4.1 Navigation

Ghost-inspired structure:

```text
FIELD NOTES

View site

Home
Posts
Pages
Tags

Settings
```

MVP may defer `Pages` if it delays the publishing loop.

### 4.2 Posts screen

Required:

- All / Drafts / Published filters.
- Search by title.
- Title.
- Status.
- Primary topic/tag.
- Updated/published date.
- New Post action.
- Open existing post for editing.

Scheduled publishing is not required for MVP but the data model should not make it difficult to add later.

### 4.3 Editor

The editor is the primary CMS surface.

Layout:

```text
<- Posts                         Preview   Publish

                     Post title

                     Begin writing...
```

Post settings use a right-side drawer containing:

- Slug / URL.
- Publication date.
- Tags.
- Author.
- Excerpt.
- Featured flag.
- Feature image placeholder until media phase.
- SEO/meta fields when added.

### 4.4 Editing model

Do not make a plain textarea the final editor.

MVP block types:

- Paragraph.
- Heading.
- Quote.
- Code.
- Divider.
- Image placeholder / image block when media support lands.

Persist a structured editor representation suitable for re-editing. Generate sanitized/renderable HTML for the Astro publication contract.

## 5. Firestore data model

Initial collections:

### `posts/{postId}`

```text
title
slug
status              draft | published
excerpt
content             structured editor document
html                rendered publication HTML
tagIds[]
authorId
featured
featureImage        nullable
featureImageAlt     nullable
createdAt
updatedAt
publishedAt         nullable
```

Future-compatible optional fields:

```text
scheduledAt
seoTitle
seoDescription
canonicalUrl
```

### `tags/{tagId}`

```text
name
slug
description
createdAt
updatedAt
```

### `users/{uid}`

```text
displayName
role                 admin | editor
createdAt
updatedAt
```

MVP initially supports one administrator, but authorization rules must not assume that only one user can ever exist.

## 6. Authentication and authorization

Use Firebase Authentication for `/admin`.

MVP:

- Sign-in screen.
- Only explicitly authorized users may enter CMS routes.
- Firestore Security Rules deny anonymous writes.
- Published content must not become publicly writable.
- Authorization must be enforced by Firebase rules/backend boundaries, not only hidden UI controls.

Never commit:

- service-account private keys;
- deployment-trigger URLs;
- R2 credentials;
- Firebase secrets requiring server-side confidentiality.

Public Firebase web configuration is not an authorization mechanism; security comes from Authentication and Firestore Security Rules.

## 7. Content adapter

Replace the production Ghost adapter behind the existing data access boundary rather than rewriting reader pages.

Target:

```text
Firestore
   |
   v
Firebase content adapter
   |
   v
normalize()
   |
   v
getPosts()
getTags()
getPostsByTag()
   |
   v
existing Astro pages
```

Only `status == published` records may enter production static generation.

During migration:

1. Firebase configured -> use Firestore.
2. Firebase not configured -> use preview/mock content.
3. Remove Ghost-specific production code only after parity validation.

## 8. Publishing pipeline

Desired user action:

```text
Edit
 -> Save draft
 -> Preview
 -> Publish
 -> static build triggered
 -> Firestore published content fetched
 -> Astro generated
 -> Cloudflare deployed
 -> published URL verified
```

Publishing must not expose a reusable deployment credential to browser JavaScript.

Therefore the browser must call an authenticated server-side boundary/function, which then invokes the deployment trigger.

Unpublish/delete must also trigger a rebuild so removed content disappears from static output.

## 9. Preview semantics

Two previews are required conceptually:

1. **Editor preview**: immediate representation of the current draft without publishing.
2. **Deployed preview/production**: static Cloudflare output containing only published content.

Drafts must never accidentally enter the public/static article index.

## 10. Media phase

Do not block the first CMS publishing loop on media.

Phase 2 media target:

```text
CMS
 -> authenticated upload boundary
 -> Cloudflare R2
 -> stable media URL
 -> Firestore metadata
 -> Astro HTML
```

Support:

- Feature image.
- Inline image block.
- Alt text.
- File type/size validation.
- Stable object keys.
- Delete/orphan handling.

R2 credentials must remain server-side.

## 11. Development phases and acceptance gates

### Phase 0 — Architecture migration

- [x] Add Firebase dependencies/configuration.
- [x] Define environment contract.
- [x] Add Firestore schema documentation.
- [x] Add Firestore Security Rules.
- [x] Preserve mock-content fallback.
- [ ] Mark Ghost infrastructure as deprecated, not immediately deleted.

**Gate:** existing public build still succeeds and no secret is committed.

### Phase 1 — Admin shell + authentication

- [x] `/admin/login`.
- [x] Protected `/admin` layout (client-authenticated shell; rules remain authority).
- [x] Ghost-inspired navigation.
- [x] Firebase Auth integration.
- [x] Unauthorized access handling.
- [ ] Sign out.

**Gate:** anonymous user cannot read/write private CMS data through the admin workflow.

### Phase 2 — Posts and tags

- [x] Posts list.
- [x] Draft/published filtering.
- [x] Search.
- [x] Create post.
- [x] Edit post.
- [ ] Tags CRUD.
- [ ] Slug uniqueness validation.
- [x] Autosave draft scaffold (requires live Firebase validation).

**Gate:** draft survives reload and cannot appear on the public site.

### Phase 3 — Editor

- [ ] Structured editor document.
- [ ] Paragraph.
- [ ] Heading.
- [ ] Quote.
- [ ] Code.
- [ ] Divider.
- [ ] HTML renderer.
- [ ] Settings drawer.
- [ ] Draft preview.

**Gate:** save -> reopen -> edit round trip preserves content without structural loss.

### Phase 4 — Firebase -> Astro adapter

- [ ] Build-time Firestore reader.
- [ ] Normalize to current post shape.
- [ ] Published-only query.
- [ ] Tags/topics mapping.
- [ ] Author mapping.
- [ ] Reading-time handling.
- [ ] Existing homepage/article/topic/RSS/sitemap behavior retained.

**Gate:** a Firestore fixture can generate the complete static site without Ghost.

### Phase 5 — Publish automation

- [ ] Publish transition.
- [ ] Server-side authenticated deployment trigger.
- [ ] Build status/error feedback.
- [ ] Edit published post -> rebuild.
- [ ] Unpublish -> rebuild.
- [ ] Delete -> rebuild.

**Gate:** one CMS Publish action produces a verified Cloudflare deployment containing the new article.

### Phase 6 — R2 media

- [ ] Authenticated upload.
- [ ] Feature images.
- [ ] Inline images.
- [ ] Alt text.
- [ ] Media validation.
- [ ] R2 object lifecycle strategy.

**Gate:** media remains valid independently of CMS/editor sessions and appears in generated static output.

### Phase 7 — Hardening

- [ ] Firestore emulator/rules tests.
- [ ] Authentication failure tests.
- [ ] XSS/content rendering tests.
- [ ] Slug collision tests.
- [ ] Publish concurrency/idempotency.
- [ ] Deployment failure recovery.
- [ ] Accessibility review.
- [ ] Mobile admin review.
- [ ] Backup/export procedure.
- [ ] Cost/quota monitoring.

**Gate:** no known P0 publishing, authorization, data-loss or secret-exposure defect.

## 12. Explicit non-goals for MVP

Do not add until the core publishing loop is stable:

- Public user accounts.
- Comments.
- Likes/reactions.
- Membership/paywall.
- Newsletter delivery platform.
- Recommendation algorithm.
- Collaborative real-time editing.
- Complex analytics dashboard.
- Scheduled publishing UI.
- Full media library.
- Ghost plugin compatibility.

## 13. Migration completion criteria

The Ghost path can be removed only when all of the following are true:

- Firebase Auth protects CMS access.
- Firestore rules are validated.
- Posts can be created, edited and reopened.
- Draft preview works.
- Published-only Astro build works.
- Topics/tags, RSS, sitemap and article metadata remain correct.
- Publish triggers Cloudflare deployment.
- Edit/unpublish correctly refreshes static output.
- No privileged credential is exposed to browser bundles or Git.
- At least one real article has completed the full CMS -> Firestore -> Astro -> Cloudflare lifecycle.

## 14. Immediate implementation order

Next development work should proceed in this order:

1. Firebase project/config contract.
2. Firestore rules and data model.
3. `/admin/login` and protected admin shell.
4. Posts list and draft CRUD.
5. Editor.
6. Firebase build-time adapter.
7. Publish automation.
8. R2 media.
9. Hardening and Ghost-code removal.

Do not start R2 or deployment automation before basic authenticated draft CRUD is working.
