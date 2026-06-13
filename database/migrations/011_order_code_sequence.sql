-- 011_order_code_sequence.sql — Birleşik SPRS-0000001 sipariş kodu (boş veritabanı)

create sequence if not exists public.order_code_seq start 1;

create or replace function public.next_order_code()
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  n bigint;
begin
  n := nextval('public.order_code_seq');
  return 'SPRS-' || lpad(n::text, 7, '0');
end;
$$;

revoke all on function public.next_order_code() from public;
grant execute on function public.next_order_code() to authenticated;
