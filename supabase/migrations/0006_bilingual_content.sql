-- Add optional English translations while keeping Traditional Chinese canonical.
alter table public.posts add column if not exists title_en text;
alter table public.posts add column if not exists excerpt_en text;
alter table public.posts add column if not exists content_en jsonb;
alter table public.posts add column if not exists html_en text;
alter table public.posts add column if not exists feature_image_alt_en text;
alter table public.tags add column if not exists name_en text;
alter table public.tags add column if not exists description_en text;

-- English tag metadata also affects generated English topic pages.
drop trigger if exists tags_cloudflare_publish_build on public.tags;
create trigger tags_cloudflare_publish_build
after update of name, slug, description, name_en, description_en on public.tags
for each row execute function public.trigger_cloudflare_tag_build();
