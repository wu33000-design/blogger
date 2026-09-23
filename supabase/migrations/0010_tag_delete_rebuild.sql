-- Rebuild before a tag attached to published posts is deleted.
-- AFTER DELETE cannot discover affected posts because post_tags cascades first.

create or replace function public.trigger_cloudflare_tag_delete_build()
returns trigger
language plpgsql
security definer
set search_path = public, vault, net
as $$
declare hook_url text; affects_published boolean := false;
begin
  select exists(
    select 1 from public.post_tags pt
    join public.posts p on p.id = pt.post_id
    where pt.tag_id = old.id and p.status = 'published'
  ) into affects_published;
  if not affects_published then return old; end if;

  select decrypted_secret into hook_url from vault.decrypted_secrets
  where name = 'cloudflare_deploy_hook_url' limit 1;
  if hook_url is null or hook_url = '' then
    raise warning 'Cloudflare deploy hook is not configured in Vault'; return old;
  end if;

  perform net.http_post(
    url := hook_url,
    headers := '{"Content-Type":"application/json"}'::jsonb,
    body := jsonb_build_object('source','field-notes-cms','operation','tag-delete','tag_id',old.id),
    timeout_milliseconds := 5000
  );
  return old;
end;
$$;

drop trigger if exists tags_cloudflare_delete_build on public.tags;
create trigger tags_cloudflare_delete_build
before delete on public.tags
for each row execute function public.trigger_cloudflare_tag_delete_build();
