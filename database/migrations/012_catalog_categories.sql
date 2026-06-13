-- 012_catalog_categories.sql — Global katalog kategorileri (Supabase Table Editor ile yönetim)

create table if not exists public.catalog_categories (
  id         uuid primary key default gen_random_uuid(),
  name       text not null,
  sort_order int not null default 0,
  is_active  boolean not null default true,
  created_at timestamptz not null default now(),
  constraint catalog_categories_name_unique unique (name),
  constraint catalog_categories_name_not_empty check (length(trim(name)) > 0)
);

create index if not exists catalog_categories_active_sort_idx
  on public.catalog_categories (is_active, sort_order, name);

alter table public.catalog_categories enable row level security;

drop policy if exists catalog_categories_select_active on public.catalog_categories;
create policy catalog_categories_select_active on public.catalog_categories
  for select to authenticated
  using (is_active = true);
