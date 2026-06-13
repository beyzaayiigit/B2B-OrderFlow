-- 001_rls.sql — Row Level Security (tüm iş tabloları)
-- Migration 001–006 çalıştırıldıktan sonra çalıştırın.

-- ---------------------------------------------------------------------------
-- companies
-- ---------------------------------------------------------------------------
alter table public.companies enable row level security;

drop policy if exists companies_select_authenticated on public.companies;
create policy companies_select_authenticated on public.companies
  for select to authenticated
  using (true);

-- ---------------------------------------------------------------------------
-- profiles
-- ---------------------------------------------------------------------------
alter table public.profiles enable row level security;

drop policy if exists profiles_select_own on public.profiles;
create policy profiles_select_own on public.profiles
  for select to authenticated
  using (id = auth.uid());

drop policy if exists profiles_select_same_company on public.profiles;
create policy profiles_select_same_company on public.profiles
  for select to authenticated
  using (company_id = public.current_company_id());

drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own on public.profiles
  for update to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

-- Insert: yalnızca service_role / dashboard (seed); mobil insert yok

-- ---------------------------------------------------------------------------
-- catalog_models
-- ---------------------------------------------------------------------------
alter table public.catalog_models enable row level security;

drop policy if exists catalog_models_buyer_select_published on public.catalog_models;
create policy catalog_models_buyer_select_published on public.catalog_models
  for select to authenticated
  using (
    status = 'published'
    and public.current_user_role() = 'buyer'
  );

drop policy if exists catalog_models_producer_all on public.catalog_models;
create policy catalog_models_producer_all on public.catalog_models
  for all to authenticated
  using (
    producer_company_id = public.current_company_id()
    and public.current_user_role() = 'producer'
  )
  with check (
    producer_company_id = public.current_company_id()
    and public.current_user_role() = 'producer'
  );

-- ---------------------------------------------------------------------------
-- catalog_color_variants
-- ---------------------------------------------------------------------------
alter table public.catalog_color_variants enable row level security;

drop policy if exists catalog_variants_buyer_select on public.catalog_color_variants;
create policy catalog_variants_buyer_select on public.catalog_color_variants
  for select to authenticated
  using (
    exists (
      select 1 from public.catalog_models m
      where m.id = model_id
        and m.status = 'published'
        and public.current_user_role() = 'buyer'
    )
  );

drop policy if exists catalog_variants_producer_all on public.catalog_color_variants;
create policy catalog_variants_producer_all on public.catalog_color_variants
  for all to authenticated
  using (
    exists (
      select 1 from public.catalog_models m
      where m.id = model_id
        and m.producer_company_id = public.current_company_id()
        and public.current_user_role() = 'producer'
    )
  )
  with check (
    exists (
      select 1 from public.catalog_models m
      where m.id = model_id
        and m.producer_company_id = public.current_company_id()
        and public.current_user_role() = 'producer'
    )
  );

-- ---------------------------------------------------------------------------
-- orders
-- ---------------------------------------------------------------------------
alter table public.orders enable row level security;

drop policy if exists orders_buyer_select on public.orders;
create policy orders_buyer_select on public.orders
  for select to authenticated
  using (
    buyer_company_id = public.current_company_id()
    and public.current_user_role() = 'buyer'
  );

drop policy if exists orders_buyer_insert on public.orders;
create policy orders_buyer_insert on public.orders
  for insert to authenticated
  with check (
    buyer_company_id = public.current_company_id()
    and public.current_user_role() = 'buyer'
    and created_by = auth.uid()
    and status = 'submitted'
  );

drop policy if exists orders_producer_select on public.orders;
create policy orders_producer_select on public.orders
  for select to authenticated
  using (
    producer_company_id = public.current_company_id()
    and public.current_user_role() = 'producer'
  );

drop policy if exists orders_producer_update on public.orders;
create policy orders_producer_update on public.orders
  for update to authenticated
  using (
    producer_company_id = public.current_company_id()
    and public.current_user_role() = 'producer'
  )
  with check (
    producer_company_id = public.current_company_id()
    and public.current_user_role() = 'producer'
  );

-- ---------------------------------------------------------------------------
-- order_lines
-- ---------------------------------------------------------------------------
alter table public.order_lines enable row level security;

drop policy if exists order_lines_buyer_select on public.order_lines;
create policy order_lines_buyer_select on public.order_lines
  for select to authenticated
  using (
    exists (
      select 1 from public.orders o
      where o.id = order_id
        and o.buyer_company_id = public.current_company_id()
        and public.current_user_role() = 'buyer'
    )
  );

drop policy if exists order_lines_buyer_insert on public.order_lines;
create policy order_lines_buyer_insert on public.order_lines
  for insert to authenticated
  with check (
    exists (
      select 1 from public.orders o
      where o.id = order_id
        and o.buyer_company_id = public.current_company_id()
        and o.created_by = auth.uid()
        and public.current_user_role() = 'buyer'
    )
  );

drop policy if exists order_lines_producer_select on public.order_lines;
create policy order_lines_producer_select on public.order_lines
  for select to authenticated
  using (
    exists (
      select 1 from public.orders o
      where o.id = order_id
        and o.producer_company_id = public.current_company_id()
        and public.current_user_role() = 'producer'
    )
  );

-- ---------------------------------------------------------------------------
-- order_status_events
-- ---------------------------------------------------------------------------
alter table public.order_status_events enable row level security;

drop policy if exists order_status_events_select on public.order_status_events;
create policy order_status_events_select on public.order_status_events
  for select to authenticated
  using (
    exists (
      select 1 from public.orders o
      where o.id = order_id
        and (
          (o.buyer_company_id = public.current_company_id() and public.current_user_role() = 'buyer')
          or (o.producer_company_id = public.current_company_id() and public.current_user_role() = 'producer')
        )
    )
  );

drop policy if exists order_status_events_producer_insert on public.order_status_events;
create policy order_status_events_producer_insert on public.order_status_events
  for insert to authenticated
  with check (
    public.current_user_role() = 'producer'
    and exists (
      select 1 from public.orders o
      where o.id = order_id
        and o.producer_company_id = public.current_company_id()
    )
  );

-- ---------------------------------------------------------------------------
-- order_update_threads & entries
-- ---------------------------------------------------------------------------
alter table public.order_update_threads enable row level security;
alter table public.order_update_entries enable row level security;

drop policy if exists update_threads_select on public.order_update_threads;
create policy update_threads_select on public.order_update_threads
  for select to authenticated
  using (
    exists (
      select 1 from public.orders o
      where o.id = order_id
        and (
          (o.buyer_company_id = public.current_company_id() and public.current_user_role() = 'buyer')
          or (o.producer_company_id = public.current_company_id() and public.current_user_role() = 'producer')
        )
    )
  );

drop policy if exists update_threads_buyer_insert on public.order_update_threads;
create policy update_threads_buyer_insert on public.order_update_threads
  for insert to authenticated
  with check (
    public.current_user_role() = 'buyer'
    and exists (
      select 1 from public.orders o
      where o.id = order_id
        and o.buyer_company_id = public.current_company_id()
    )
  );

drop policy if exists update_entries_select on public.order_update_entries;
create policy update_entries_select on public.order_update_entries
  for select to authenticated
  using (
    exists (
      select 1 from public.order_update_threads t
      join public.orders o on o.id = t.order_id
      where t.id = thread_id
        and (
          (o.buyer_company_id = public.current_company_id() and public.current_user_role() = 'buyer')
          or (o.producer_company_id = public.current_company_id() and public.current_user_role() = 'producer')
        )
    )
  );

drop policy if exists update_entries_insert on public.order_update_entries;
create policy update_entries_insert on public.order_update_entries
  for insert to authenticated
  with check (
    author_id = auth.uid()
    and exists (
      select 1 from public.order_update_threads t
      join public.orders o on o.id = t.order_id
      where t.id = thread_id
        and (
          (public.current_user_role() = 'buyer' and o.buyer_company_id = public.current_company_id())
          or (public.current_user_role() = 'producer' and o.producer_company_id = public.current_company_id())
        )
    )
  );

