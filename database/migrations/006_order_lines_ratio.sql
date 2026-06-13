-- 006_order_lines_ratio.sql — Beden oran sistemi: qty artık oranı tutar,
-- color_total_qty renk bazında toplam adedi tutar.

alter table public.order_lines
  add column if not exists color_total_qty int not null default 0;

comment on column public.order_lines.qty is
  'Beden oranı (seri poşetindeki dağılım değeri, ör. S:1, M:2).';

comment on column public.order_lines.color_total_qty is
  'Bu renk için toplam sipariş adedi.';
