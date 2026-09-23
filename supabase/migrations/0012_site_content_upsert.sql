-- Make site-content saves create missing keys as well as update existing ones.
-- This keeps newly introduced CMS fields such as site.title self-healing.
create or replace function public.update_site_content(items jsonb)
returns void
language plpgsql
security definer
set search_path=public,vault,net
as $$
declare item jsonb; hook_url text;
begin
  if not public.is_editor() then raise exception 'Not authorized'; end if;
  if jsonb_typeof(items) <> 'array' then raise exception 'items must be an array'; end if;

  for item in select * from jsonb_array_elements(items) loop
    insert into public.site_content (
      key,
      value_zh_hant,
      value_en,
      updated_at,
      updated_by
    )
    values (
      item->>'key',
      coalesce(item->>'value_zh_hant',''),
      nullif(item->>'value_en',''),
      now(),
      auth.uid()
    )
    on conflict (key) do update set
      value_zh_hant=excluded.value_zh_hant,
      value_en=excluded.value_en,
      updated_at=excluded.updated_at,
      updated_by=excluded.updated_by;
  end loop;

  select decrypted_secret into hook_url
  from vault.decrypted_secrets
  where name='cloudflare_deploy_hook_url'
  limit 1;

  if hook_url is not null and hook_url <> '' then
    perform net.http_post(
      url:=hook_url,
      headers:='{"Content-Type":"application/json"}'::jsonb,
      body:='{"source":"field-notes-cms","operation":"site-content-save"}'::jsonb,
      timeout_milliseconds:=5000
    );
  else
    raise warning 'Cloudflare deploy hook is not configured in Vault';
  end if;
end;
$$;

revoke all on function public.update_site_content(jsonb) from public;
grant execute on function public.update_site_content(jsonb) to authenticated;
