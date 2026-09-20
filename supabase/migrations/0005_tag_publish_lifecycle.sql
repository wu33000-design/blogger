-- Rebuild the static site when tag metadata used by published posts changes.
-- Reuses the Cloudflare deploy hook stored in Supabase Vault.

create or replace function public.trigger_cloudflare_tag_build()
returns trigger
language plpgsql
security definer
set search_path = public, vault, net
as $$
declare
  hook_url text;
  target_id uuid := coalesce(new.id, old.id);
  affects_published boolean := false;
begin
  select exists(
    select 1
    from public.post_tags pt
    join public.posts p on p.id = pt.post_id
    where pt.tag_id = target_id and p.status = 'published'
  ) into affects_published;

  if not affects_published then
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
      'operation','tag-update',
      'tag_id',target_id
    ),
    timeout_milliseconds := 5000
  );

  return coalesce(new, old);
end;
$$;

drop trigger if exists tags_cloudflare_publish_build on public.tags;
create trigger tags_cloudflare_publish_build
after update of name, slug, description on public.tags
for each row execute function public.trigger_cloudflare_tag_build();
