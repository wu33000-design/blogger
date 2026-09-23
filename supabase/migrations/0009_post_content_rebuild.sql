-- Rebuild the static site when fields used by an already-published post change.
-- Publishing lifecycle transitions remain owned by 0004.

drop trigger if exists posts_cloudflare_content_build on public.posts;

create or replace function public.trigger_cloudflare_post_content_build()
returns trigger
language plpgsql
security definer
set search_path = public, vault, net
as $$
declare hook_url text;
begin
  if old.status <> 'published' or new.status <> 'published' then return new; end if;
  if not (
    old.title is distinct from new.title or old.slug is distinct from new.slug
    or old.excerpt is distinct from new.excerpt or old.content is distinct from new.content
    or old.html is distinct from new.html or old.featured is distinct from new.featured
    or old.feature_image is distinct from new.feature_image
    or old.feature_image_alt is distinct from new.feature_image_alt
    or old.title_en is distinct from new.title_en or old.excerpt_en is distinct from new.excerpt_en
    or old.content_en is distinct from new.content_en or old.html_en is distinct from new.html_en
    or old.feature_image_alt_en is distinct from new.feature_image_alt_en
  ) then return new; end if;

  select decrypted_secret into hook_url from vault.decrypted_secrets
  where name = 'cloudflare_deploy_hook_url' limit 1;
  if hook_url is null or hook_url = '' then
    raise warning 'Cloudflare deploy hook is not configured in Vault'; return new;
  end if;

  perform net.http_post(
    url := hook_url,
    headers := '{"Content-Type":"application/json"}'::jsonb,
    body := jsonb_build_object('source','field-notes-cms','operation','post-content-update','post_id',new.id,'slug',new.slug),
    timeout_milliseconds := 5000
  );
  return new;
end;
$$;

create trigger posts_cloudflare_content_build
after update on public.posts
for each row execute function public.trigger_cloudflare_post_content_build();
