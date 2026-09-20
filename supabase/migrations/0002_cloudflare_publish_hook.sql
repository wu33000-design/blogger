-- Trigger a Cloudflare Workers Build when an editor explicitly publishes a post.
-- The deploy-hook URL is stored encrypted in Supabase Vault under
-- the name "cloudflare_deploy_hook_url". Never hard-code it here.

create extension if not exists pg_net with schema extensions;

create or replace function public.trigger_cloudflare_publish_build()
returns trigger
language plpgsql
security definer
set search_path = public, vault, net
as $$
declare
  hook_url text;
begin
  -- Only an explicit publish/republish changes published_at.
  -- Autosaves of an already-published post therefore do not rebuild the site.
  if new.status <> 'published'
     or new.published_at is null
     or (
       old.status = 'published'
       and new.published_at is not distinct from old.published_at
     )
  then
    return new;
  end if;

  select decrypted_secret
    into hook_url
    from vault.decrypted_secrets
   where name = 'cloudflare_deploy_hook_url'
   limit 1;

  if hook_url is null or hook_url = '' then
    raise warning 'Cloudflare deploy hook is not configured in Vault';
    return new;
  end if;

  perform net.http_post(
    url := hook_url,
    headers := '{"Content-Type":"application/json"}'::jsonb,
    body := jsonb_build_object(
      'source', 'field-notes-cms',
      'post_id', new.id,
      'slug', new.slug,
      'published_at', new.published_at
    ),
    timeout_milliseconds := 5000
  );

  return new;
end;
$$;

revoke all on function public.trigger_cloudflare_publish_build() from public, anon, authenticated;

drop trigger if exists posts_cloudflare_publish_build on public.posts;
create trigger posts_cloudflare_publish_build
after update of status, published_at on public.posts
for each row
execute function public.trigger_cloudflare_publish_build();
