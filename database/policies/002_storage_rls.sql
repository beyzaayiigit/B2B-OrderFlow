-- 002_storage_rls.sql — catalog-images bucket RLS
-- Path: {producer_company_id}/{model_code}/{filename}

-- Okuma: giriş yapmış herkes (alıcı katalog + üretici)
drop policy if exists catalog_images_select on storage.objects;
create policy catalog_images_select on storage.objects
  for select to authenticated
  using (bucket_id = 'catalog-images');

-- Yükleme / güncelleme / silme: yalnızca kendi şirket prefix'i (üretici)
drop policy if exists catalog_images_producer_insert on storage.objects;
create policy catalog_images_producer_insert on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'catalog-images'
    and public.current_user_role() = 'producer'
    and (storage.foldername(name))[1] = public.current_company_id()::text
  );

drop policy if exists catalog_images_producer_update on storage.objects;
create policy catalog_images_producer_update on storage.objects
  for update to authenticated
  using (
    bucket_id = 'catalog-images'
    and public.current_user_role() = 'producer'
    and (storage.foldername(name))[1] = public.current_company_id()::text
  );

drop policy if exists catalog_images_producer_delete on storage.objects;
create policy catalog_images_producer_delete on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'catalog-images'
    and public.current_user_role() = 'producer'
    and (storage.foldername(name))[1] = public.current_company_id()::text
  );
