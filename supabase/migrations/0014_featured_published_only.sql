-- Featured articles must be published.
-- Clean legacy invalid flags, then enforce the invariant at the database layer.

update public.posts
set featured = false,
    updated_at = now()
where featured = true
  and status <> 'published';

alter table public.posts
  drop constraint if exists posts_featured_requires_published;

alter table public.posts
  add constraint posts_featured_requires_published
  check (featured = false or status = 'published');
