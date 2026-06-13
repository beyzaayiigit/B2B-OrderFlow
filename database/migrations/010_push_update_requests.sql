-- 010 — Güncelleme talepleri için push bildirimleri
--
-- Olaylar:
-- - Alıcı talep gönderir  -> üreticiye push
-- - Üretici onay / geri bildirim -> alıcıya push
-- Body içinde entry.text kısa önizleme gösterilir.

create or replace function public.fn_push_on_update_entry_insert()
returns trigger as $$
declare
  _order_rec      record;
  _target_company uuid;
  _title          text;
  _body           text;
  _snippet        text;
begin
  select
    o.buyer_order_no,
    o.producer_order_no,
    o.buyer_company_id,
    o.producer_company_id,
    cm.name as model_name
  into _order_rec
  from public.order_update_threads t
  join public.orders o on o.id = t.order_id
  left join public.catalog_models cm on cm.id = o.model_id
  where t.id = NEW.thread_id;

  _snippet := nullif(trim(coalesce(NEW.text, '')), '');
  if _snippet is not null then
    _snippet := left(_snippet, 120);
  end if;

  if NEW.kind = 'buyer_request'::public.update_entry_kind then
    _target_company := _order_rec.producer_company_id;
    _title := 'Güncelleme Talebi';
    _body := coalesce(
      _snippet,
      _order_rec.producer_order_no || ' — ' || coalesce(_order_rec.model_name, '')
    );
  elsif NEW.kind = 'producer_approval'::public.update_entry_kind then
    _target_company := _order_rec.buyer_company_id;
    _title := 'Talep Onaylandı';
    _body := coalesce(
      _snippet,
      _order_rec.buyer_order_no || ' — ' || coalesce(_order_rec.model_name, '')
    );
  elsif NEW.kind = 'producer_feedback'::public.update_entry_kind then
    _target_company := _order_rec.buyer_company_id;
    _title := 'Talebe Geri Bildirim';
    _body := coalesce(
      _snippet,
      _order_rec.buyer_order_no || ' — ' || coalesce(_order_rec.model_name, '')
    );
  end if;

  if _target_company is not null then
    perform public.fn_enqueue_push_for_company(
      _target_company,
      _title,
      _body,
      jsonb_build_object(
        'thread_id', NEW.thread_id::text,
        'entry_id', NEW.id::text,
        'kind', NEW.kind::text,
        'order_code', coalesce(_order_rec.buyer_order_no, _order_rec.producer_order_no)
      )
    );
  end if;

  return NEW;
end;
$$ language plpgsql security definer;

drop trigger if exists trg_push_update_entry_insert on public.order_update_entries;
create trigger trg_push_update_entry_insert
  after insert on public.order_update_entries
  for each row
  execute function public.fn_push_on_update_entry_insert();
