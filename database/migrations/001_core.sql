-- 001_core.sql — Şirketler, profiller, yardımcı fonksiyonlar
-- Supabase SQL Editor'de ilk dosya olarak çalıştırın.

create extension if not exists "pgcrypto";

do $$ begin
  create type public.company_type as enum ('buyer', 'producer');
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.user_role as enum ('buyer', 'producer');
exception when duplicate_object then null;
end $$;

create table if not exists public.companies (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  type public.company_type not null,
  created_at timestamptz not null default now()
);

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  company_id uuid not null references public.companies (id),
  role public.user_role not null,
  full_name text not null,
  title text,
  email text not null,
  created_at timestamptz not null default now()
);

create index if not exists profiles_company_id_idx on public.profiles (company_id);

create or replace function public.current_profile()
returns public.profiles
language sql
stable
security definer
set search_path = public
as $$
  select * from public.profiles where id = auth.uid();
$$;

create or replace function public.current_user_role()
returns public.user_role
language sql
stable
security definer
set search_path = public
as $$
  select role from public.profiles where id = auth.uid();
$$;

create or replace function public.current_company_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select company_id from public.profiles where id = auth.uid();
$$;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;
