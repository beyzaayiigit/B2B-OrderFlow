-- ============================================================
-- 008 — Push bildirim kuyruğu + sipariş trigger'ları
-- ============================================================

create table if not exists public.push_queue (
  id          uuid default gen_random_uuid() primary key,
  recipient_id uuid not null references auth.users(id) on delete cascade,
  title       text not null,
  body        text not null,
  data        jsonb default '{}',
  sent        boolean default false,
  created_at  timestamptz default now()
);

alter table public.push_queue enable row level security;

drop policy if exists push_queue_service_only on public.push_queue;
create policy push_queue_service_only on public.push_queue
  for all to service_role
  using (true)
  with check (true);

-- ----------------------------------------------------------------
-- Yardımcı: Bir şirketteki tüm kullanıcılara push kuyruğuna yaz
-- ----------------------------------------------------------------
create or replace function public.fn_enqueue_push_for_company(
  _company_id uuid,
  _title text,
  _body text,
  _data jsonb default '{}'
)
returns void as $$
begin
  insert into public.push_queue (recipient_id, title, body, data)
  select distinct p.id, _title, _body, _data
  from public.profiles p
  inner join public.device_tokens dt on dt.user_id = p.id
  where p.company_id = _company_id;
end;
$$ language plpgsql security definer;

-- ----------------------------------------------------------------
-- Yeni sipariş oluşturulduğunda → üreticiye bildirim (INSERT)
-- ----------------------------------------------------------------
create or replace function public.fn_push_on_order_insert()
returns trigger as $$
declare
  _model_name text;
begin
  select cm.name into _model_name
    from public.catalog_models cm
   where cm.id = NEW.model_id;

  perform public.fn_enqueue_push_for_company(
    NEW.producer_company_id,
    'Yeni Sipariş',
    NEW.producer_order_no || ' — ' || coalesce(_model_name, ''),
    jsonb_build_object(
      'order_code', NEW.producer_order_no,
      'status', NEW.status::text
    )
  );

  return NEW;
end;
$$ language plpgsql security definer;

drop trigger if exists trg_push_order_insert on public.orders;
create trigger trg_push_order_insert
  after insert on public.orders
  for each row
  execute function public.fn_push_on_order_insert();

-- ----------------------------------------------------------------
-- Sipariş durumu değiştiğinde → karşı tarafa bildirim (UPDATE)
-- ----------------------------------------------------------------
create or replace function public.fn_push_on_order_status()
returns trigger as $$
declare
  _model_name   text;
  _title        text;
  _target_co    uuid;
  _order_code   text;
begin
  if OLD.status = NEW.status then
    return NEW;
  end if;

  select cm.name into _model_name
    from public.catalog_models cm
   where cm.id = NEW.model_id;

  -- Üretici aksiyonu → alıcıya bildirim
  if NEW.status in ('approved', 'in_production', 'shipped') then
    _target_co := NEW.buyer_company_id;
    _order_code := NEW.buyer_order_no;
    _title := case NEW.status::text
      when 'approved'      then 'Sipariş Onaylandı'
      when 'in_production' then 'Üretime Alındı'
      when 'shipped'       then 'Sevk Edildi'
    end;
  end if;

  if _target_co is not null then
    perform public.fn_enqueue_push_for_company(
      _target_co,
      _title,
      _order_code || ' — ' || coalesce(_model_name, ''),
      jsonb_build_object(
        'order_code', _order_code,
        'status', NEW.status::text
      )
    );
  end if;

  return NEW;
end;
$$ language plpgsql security definer;

drop trigger if exists trg_push_order_status on public.orders;
create trigger trg_push_order_status
  after update on public.orders
  for each row
  execute function public.fn_push_on_order_status();
