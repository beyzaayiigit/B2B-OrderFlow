-- dev_seed_minimal.sql — 1 alıcı + 1 üretici (demo)
--
-- 1) Authentication → Users: 2 kullanıcı oluştur, UID kopyala
-- 2) YOUR_BUYER_UID / YOUR_PRODUCER_UID yerine yapıştır
-- 3) SQL Editor'da çalıştır

insert into public.companies (id, name, type)
values
  ('a0000000-0000-4000-8000-000000000001', 'Demo Alıcı A.Ş.', 'buyer'),
  ('a0000000-0000-4000-8000-000000000002', 'Demo Üretici San.', 'producer')
on conflict (id) do update set
  name = excluded.name,
  type = excluded.type;

insert into public.profiles (id, company_id, role, full_name, title, email)
values
  (
    'YOUR_BUYER_UID'::uuid,
    'a0000000-0000-4000-8000-000000000001',
    'buyer',
    'Demo Alıcı',
    null,
    'buyer@demo-textileflow.test'
  ),
  (
    'YOUR_PRODUCER_UID'::uuid,
    'a0000000-0000-4000-8000-000000000002',
    'producer',
    'Demo Üretici',
    null,
    'producer@demo-textileflow.test'
  )
on conflict (id) do update set
  company_id = excluded.company_id,
  role = excluded.role,
  full_name = excluded.full_name,
  title = excluded.title,
  email = excluded.email;

-- Katalog (dev_seed.sql ile aynı)
insert into public.catalog_models (
  id, producer_company_id, code, name, category, status, sort_order
)
values
  (
    'b0000000-0000-4000-8000-000000000001',
    'a0000000-0000-4000-8000-000000000002',
    'MD-2024-X01',
    'Klasik Ağır Kumaş Polo',
    'Polo',
    'published',
    1
  ),
  (
    'b0000000-0000-4000-8000-000000000002',
    'a0000000-0000-4000-8000-000000000002',
    'TX-882-CR',
    'Premium Pamuk Bisiklet Yaka',
    'Tişört',
    'published',
    2
  ),
  (
    'b0000000-0000-4000-8000-000000000003',
    'a0000000-0000-4000-8000-000000000002',
    'HD-140',
    'Kapüşonlu Sweatshirt',
    'Sweatshirt',
    'published',
    3
  )
on conflict (code) do update set
  name = excluded.name,
  category = excluded.category,
  status = excluded.status;

insert into public.catalog_color_variants (model_id, color_name, sort_order)
values
  ('b0000000-0000-4000-8000-000000000001', 'Siyah', 1),
  ('b0000000-0000-4000-8000-000000000001', 'Beyaz', 2),
  ('b0000000-0000-4000-8000-000000000002', 'Lacivert', 1),
  ('b0000000-0000-4000-8000-000000000003', 'Gri', 1)
on conflict (model_id, color_name) do nothing;
