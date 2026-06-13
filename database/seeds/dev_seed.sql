-- dev_seed.sql — Örnek şirketler, profiller, katalog
--
-- ÖNCE: Authentication → Users ile 4 kullanıcı oluşturun.
-- Aşağıdaki UUID değerlerini auth.users id ile değiştirin.
--
-- Çalıştırmadan önce companies yoksa eklenir; varsa id'ler sabitlenir.

-- Sabit şirket UUID'leri (tekrar çalıştırılabilir)
insert into public.companies (id, name, type)
values
  ('a0000000-0000-4000-8000-000000000001', 'Demo Alıcı A.Ş.', 'buyer'),
  ('a0000000-0000-4000-8000-000000000002', 'Demo Üretici San.', 'producer')
on conflict (id) do update set
  name = excluded.name,
  type = excluded.type;

-- Profiller (Auth UUID'lerini değiştirin)

insert into public.profiles (id, company_id, role, full_name, title, email)
values
  (
    '1476f365-193f-443b-a56f-2bf76e1214da'::uuid,
    'a0000000-0000-4000-8000-000000000001',
    'buyer',
    'Demo Alıcı',
    null,
    'buyer@demo-textileflow.test'
  ),
  (
    'fd055b85-02c2-4812-8c51-6ec216f3f00c'::uuid,
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

-- Örnek katalog (üretici) — görseller Storage bağlanınca image_url güncellenir
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
