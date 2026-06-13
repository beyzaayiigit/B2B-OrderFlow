-- 003_orders.sql — Siparişler, satırlar, durum geçmişi

do $$ begin
  create type public.order_status as enum (
    'submitted',
    'approved',
    'in_production',
    'shipped'
  );
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.production_stage as enum (
    'cutting',
    'sewing',
    'packing',
    'logistics'
  );
exception when duplicate_object then null;
end $$;

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  buyer_order_no text not null,
  producer_order_no text not null,
  buyer_company_id uuid not null references public.companies (id),
  producer_company_id uuid not null references public.companies (id),
  model_id uuid not null references public.catalog_models (id),
  status public.order_status not null default 'submitted',
  production_stage public.production_stage,
  location_label text,
  total_qty int not null default 0,
  ordered_at timestamptz not null default now(),
  due_at date not null,
  buyer_note text,
  created_by uuid not null references public.profiles (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint orders_buyer_order_no_unique unique (buyer_order_no),
  constraint orders_producer_order_no_unique unique (producer_order_no),
  constraint orders_total_qty_non_negative check (total_qty >= 0)
);

create index if not exists orders_buyer_company_idx on public.orders (buyer_company_id);
create index if not exists orders_producer_company_idx on public.orders (producer_company_id);
create index if not exists orders_status_idx on public.orders (status);
create index if not exists orders_ordered_at_idx on public.orders (ordered_at desc);
create index if not exists orders_due_at_idx on public.orders (due_at);

drop trigger if exists orders_set_updated_at on public.orders;
create trigger orders_set_updated_at
  before update on public.orders
  for each row execute function public.set_updated_at();

create table if not exists public.order_lines (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders (id) on delete cascade,
  color_name text not null,
  size text not null,
  qty int not null,
  color_total_qty int not null default 0,
  constraint order_lines_unique unique (order_id, color_name, size),
  constraint order_lines_qty_positive check (qty > 0)
);

create index if not exists order_lines_order_id_idx on public.order_lines (order_id);

create table if not exists public.order_status_events (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders (id) on delete cascade,
  from_status public.order_status,
  to_status public.order_status not null,
  actor_id uuid references public.profiles (id),
  note text,
  created_at timestamptz not null default now()
);

create index if not exists order_status_events_order_id_idx
  on public.order_status_events (order_id, created_at desc);

-- Sipariş oluşturulunca ilk durum kaydı
create or replace function public.log_initial_order_status()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.order_status_events (order_id, from_status, to_status, actor_id)
  values (new.id, null, new.status, new.created_by);
  return new;
end;
$$;

drop trigger if exists orders_log_initial_status on public.orders;
create trigger orders_log_initial_status
  after insert on public.orders
  for each row execute function public.log_initial_order_status();

-- Durum değişince geçmiş + orders.status güncelleme (tek transaction içinde uygulama da yapabilir)
create or replace function public.log_order_status_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if old.status is distinct from new.status then
    insert into public.order_status_events (
      order_id, from_status, to_status, actor_id
    )
    values (new.id, old.status, new.status, auth.uid());
  end if;
  return new;
end;
$$;

drop trigger if exists orders_log_status_change on public.orders;
create trigger orders_log_status_change
  after update of status on public.orders
  for each row execute function public.log_order_status_change();
