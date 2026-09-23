-- Enforce the invariant that only published posts may be featured.

update public.posts
set featured = false
where status <> 'published'
  and featured = true;

create or replace function public.enforce_published_featured_post()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if new.status <> 'published' then
    new.featured := false;
  end if;
  return new;
end;
$$;

drop trigger if exists posts_enforce_published_featured on public.posts;
create trigger posts_enforce_published_featured
before insert or update of status, featured on public.posts
for each row execute function public.enforce_published_featured_post();

alter table public.posts
  drop constraint if exists posts_featured_requires_published;

alter table public.posts
  add constraint posts_featured_requires_published
  check (not featured or status = 'published');
