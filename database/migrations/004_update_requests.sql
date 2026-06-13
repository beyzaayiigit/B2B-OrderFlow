-- 004_update_requests.sql — Güncelleme talepleri (revizyon değil)

do $$ begin
  create type public.update_entry_kind as enum (
    'buyer_request',
    'producer_approval',
    'producer_feedback'
  );
exception when duplicate_object then null;
end $$;

create table if not exists public.order_update_threads (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders (id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint order_update_threads_order_unique unique (order_id)
);

drop trigger if exists order_update_threads_set_updated_at on public.order_update_threads;
create trigger order_update_threads_set_updated_at
  before update on public.order_update_threads
  for each row execute function public.set_updated_at();

create table if not exists public.order_update_entries (
  id uuid primary key default gen_random_uuid(),
  thread_id uuid not null references public.order_update_threads (id) on delete cascade,
  kind public.update_entry_kind not null,
  text text,
  author_id uuid not null references public.profiles (id),
  created_at timestamptz not null default now()
);

create index if not exists order_update_entries_thread_idx
  on public.order_update_entries (thread_id, created_at);

-- Yeni entry → thread.updated_at
create or replace function public.touch_update_thread_on_entry()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.order_update_threads
  set updated_at = now()
  where id = new.thread_id;
  return new;
end;
$$;

drop trigger if exists order_update_entries_touch_thread on public.order_update_entries;
create trigger order_update_entries_touch_thread
  after insert on public.order_update_entries
  for each row execute function public.touch_update_thread_on_entry();
