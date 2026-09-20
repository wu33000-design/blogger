-- Publishing lifecycle hardening.
-- Rebuild the static site when published content is unpublished or deleted,
-- not only when it is published/republished.

create or replace function public.trigger_cloudflare_publish_build()
returns trigger
language plpgsql
security definer
set search_path = public, vault, net
as $$
declare
  hook_url text;
  should_build boolean := false;
  target_id uuid;
  target_slug text;
begin
  if tg_op = 'DELETE' then
    should_build := old.status = 'published';
    target_id := old.id;
    target_slug := old.slug;
  else
    target_id := new.id;
    target_slug := new.slug;
    should_build :=
      (new.status = 'published' and (
        old.status is distinct from new.status
        or old.published_at is distinct from new.published_at
      ))
      or
      (old.status = 'published' and new.status <> 'published');
  end if;

  if not should_build then
    return coalesce(new, old);
  end if;

  select decrypted_secret into hook_url
  from vault.decrypted_secrets
  where name = 'cloudflare_deploy_hook_url'
  limit 1;

  if hook_url is null or hook_url = '' then
    raise warning 'Cloudflare deploy hook is not configured in Vault';
    return coalesce(new, old);
  end if;

  perform net.http_post(
    url := hook_url,
    headers := '{"Content-Type":"application/json"}'::jsonb,
    body := jsonb_build_object(
      'source','field-notes-cms',
      'operation',lower(tg_op),
      'post_id',target_id,
      'slug',target_slug
    ),
    timeout_milliseconds := 5000
  );

  return coalesce(new, old);
end;
$$;

drop trigger if exists posts_cloudflare_publish_build on public.posts;
create trigger posts_cloudflare_publish_build
after update of status, published_at or delete on public.posts
for each row execute function public.trigger_cloudflare_publish_build();
