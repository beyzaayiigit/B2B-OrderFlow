-- ============================================================
-- 007 — FCM cihaz token'ları
-- ============================================================

create table if not exists public.device_tokens (
  id          uuid default gen_random_uuid() primary key,
  user_id     uuid not null references auth.users(id) on delete cascade,
  fcm_token   text not null,
  platform    text not null default 'android',  -- 'android' | 'ios'
  created_at  timestamptz default now(),
  updated_at  timestamptz default now(),

  constraint device_tokens_user_token_uniq unique (user_id, fcm_token)
);

alter table public.device_tokens enable row level security;

drop policy if exists device_tokens_own on public.device_tokens;
create policy device_tokens_own on public.device_tokens
  for all to authenticated
  using  (user_id = auth.uid())
  with check (user_id = auth.uid());
