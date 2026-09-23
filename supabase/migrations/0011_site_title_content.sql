-- Add editable public site title to structured site content.
insert into public.site_content (key,value_zh_hant,value_en)
values ('site.title','FIELD NOTES','FIELD NOTES')
on conflict (key) do nothing;
