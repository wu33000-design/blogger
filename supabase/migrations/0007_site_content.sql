-- Editable site copy for static frontend pages.
create table if not exists public.site_content (
  key text primary key,
  value_zh_hant text not null default '',
  value_en text,
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id)
);

alter table public.site_content enable row level security;

drop policy if exists "editors read site content" on public.site_content;
create policy "editors read site content" on public.site_content for select to authenticated using (public.is_editor());
drop policy if exists "editors update site content" on public.site_content;
create policy "editors update site content" on public.site_content for update to authenticated using (public.is_editor()) with check (public.is_editor());

insert into public.site_content (key,value_zh_hant,value_en) values
('home.eyebrow','田野筆記 / 001','FIELD NOTES / EN'),
('home.headline','留下足夠的空白，讓問題自己出現。','Independent notes on technology, design, research, and human agency.'),
('home.subjects','科技 · 設計 · 研究','Technology · Design · Research'),
('home.intro','關於系統、實踐與人類能動性的獨立筆記。','Independent notes on systems, practice and human agency.'),
('home.about','關於技術、設計與研究的獨立筆記。不是追逐更多資訊，而是保留足夠空間，辨認什麼值得被看見。','Independent notes on technology, design, research, systems, practice, and human agency.'),
('site.footer','獨立數位刊物','Independent digital publication')
on conflict (key) do nothing;

create or replace function public.trigger_cloudflare_site_content_build()
returns trigger language plpgsql security definer set search_path=public,vault,net as $$
declare hook_url text;
begin
 select decrypted_secret into hook_url from vault.decrypted_secrets where name='cloudflare_deploy_hook_url' limit 1;
 if hook_url is null or hook_url='' then raise warning 'Cloudflare deploy hook is not configured in Vault'; return new; end if;
 perform net.http_post(url:=hook_url,headers:='{"Content-Type":"application/json"}'::jsonb,body:=jsonb_build_object('source','field-notes-cms','operation','site-content-update','key',new.key),timeout_milliseconds:=5000);
 return new;
end; $$;
drop trigger if exists site_content_cloudflare_build on public.site_content;
create trigger site_content_cloudflare_build after update of value_zh_hant,value_en on public.site_content for each row execute function public.trigger_cloudflare_site_content_build();
