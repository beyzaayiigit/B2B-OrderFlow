-- 002_catalog.sql — Katalog modelleri ve renk varyantları

do $$ begin
  create type public.catalog_status as enum ('draft', 'published');
exception when duplicate_object then null;
end $$;

create table if not exists public.catalog_models (
  id uuid primary key default gen_random_uuid(),
  producer_company_id uuid not null references public.companies (id),
  code text not null,
  name text not null,
  category text not null,
  status public.catalog_status not null default 'draft',
  measurement_table_json jsonb,
  production_notes text,
  sort_order int,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint catalog_models_code_not_empty check (length(trim(code)) > 0),
  constraint catalog_models_code_unique unique (code)
);

create index if not exists catalog_models_producer_idx
  on public.catalog_models (producer_company_id);

create index if not exists catalog_models_status_idx
  on public.catalog_models (status);

drop trigger if exists catalog_models_set_updated_at on public.catalog_models;
create trigger catalog_models_set_updated_at
  before update on public.catalog_models
  for each row execute function public.set_updated_at();

create table if not exists public.catalog_color_variants (
  id uuid primary key default gen_random_uuid(),
  model_id uuid not null references public.catalog_models (id) on delete cascade,
  color_name text not null,
  image_url text,
  file_size_bytes bigint,
  sort_order int,
  created_at timestamptz not null default now(),
  constraint catalog_color_variants_unique unique (model_id, color_name),
  constraint catalog_color_name_not_empty check (length(trim(color_name)) > 0)
);

create index if not exists catalog_color_variants_model_idx
  on public.catalog_color_variants (model_id);
