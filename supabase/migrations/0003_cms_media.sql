-- CMS media bucket. Public reads are intentional: published static HTML references
-- immutable public object URLs. Writes remain editor-only through RLS.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'cms-media',
  'cms-media',
  true,
  10485760,
  array['image/jpeg','image/png','image/webp','image/gif','image/avif']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create policy "editors upload cms media"
on storage.objects for insert to authenticated
with check (bucket_id = 'cms-media' and public.is_editor());

create policy "editors update cms media"
on storage.objects for update to authenticated
using (bucket_id = 'cms-media' and public.is_editor())
with check (bucket_id = 'cms-media' and public.is_editor());

create policy "admins delete cms media"
on storage.objects for delete to authenticated
using (bucket_id = 'cms-media' and public.is_admin());
