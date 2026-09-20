-- Field Notes CMS MVP
-- Supabase Auth + Postgres + Row Level Security.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '',
  role text not null default 'editor' check (role in ('admin','editor')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.tags (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  description text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.posts (
  id uuid primary key default gen_random_uuid(),
  title text not null default '',
  slug text not null unique,
  status text not null default 'draft' check (status in ('draft','published')),
  excerpt text not null default '',
  content jsonb not null default '{"version":1,"blocks":[]}'::jsonb,
  html text not null default '',
  author_id uuid not null references public.profiles(id),
  featured boolean not null default false,
  feature_image text,
  feature_image_alt text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  published_at timestamptz
);

create table if not exists public.post_tags (
  post_id uuid not null references public.posts(id) on delete cascade,
  tag_id uuid not null references public.tags(id) on delete cascade,
  primary key (post_id,tag_id)
);

alter table public.profiles enable row level security;
alter table public.posts enable row level security;
alter table public.tags enable row level security;
alter table public.post_tags enable row level security;

create or replace function public.is_editor()
returns boolean language sql stable security definer set search_path=public
as $$ select exists(select 1 from public.profiles where id=auth.uid() and role in ('admin','editor')); $$;

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path=public
as $$ select exists(select 1 from public.profiles where id=auth.uid() and role='admin'); $$;

create policy "profiles self read" on public.profiles for select to authenticated using (id=auth.uid() or public.is_admin());
create policy "profiles admin write" on public.profiles for all to authenticated using (public.is_admin()) with check (public.is_admin());

create policy "editors read posts" on public.posts for select to authenticated using (public.is_editor());
create policy "editors create posts" on public.posts for insert to authenticated with check (public.is_editor() and author_id=auth.uid());
create policy "editors update posts" on public.posts for update to authenticated using (public.is_editor()) with check (public.is_editor());
create policy "admins delete posts" on public.posts for delete to authenticated using (public.is_admin());

create policy "editors read tags" on public.tags for select to authenticated using (public.is_editor());
create policy "editors create tags" on public.tags for insert to authenticated with check (public.is_editor());
create policy "editors update tags" on public.tags for update to authenticated using (public.is_editor()) with check (public.is_editor());
create policy "admins delete tags" on public.tags for delete to authenticated using (public.is_admin());

create policy "editors read post tags" on public.post_tags for select to authenticated using (public.is_editor());
create policy "editors write post tags" on public.post_tags for insert to authenticated with check (public.is_editor());
create policy "editors delete post tags" on public.post_tags for delete to authenticated using (public.is_editor());

-- No anon policies: the public website remains static and does not query Supabase.
