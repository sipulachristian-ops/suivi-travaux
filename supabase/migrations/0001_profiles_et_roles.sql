-- ============================================================
-- Migration 0001 — Profils utilisateurs et rôles
-- À exécuter dans Supabase : Dashboard → SQL Editor → Run
-- ============================================================

-- 1. Les 4 rôles de l'application (PRD §3)
create type public.user_role as enum (
  'direction',
  'responsable_travaux',
  'responsable_affaires',
  'admin'
);

-- 2. La table des profils : 1 ligne par compte utilisateur
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text not null default '',
  role public.user_role not null default 'responsable_travaux',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.profiles is
  'Profil applicatif de chaque utilisateur : nom affiché et rôle.';

-- 3. Sécurité niveau ligne (RLS) : activée d'office
alter table public.profiles enable row level security;

-- Tout utilisateur connecté peut lire les profils
-- (nécessaire pour afficher les noms des responsables sur les travaux).
create policy "profiles_lecture_authentifiee"
  on public.profiles for select
  to authenticated
  using (true);

-- Aucune politique INSERT/UPDATE/DELETE pour l'instant :
-- les profils sont créés automatiquement (trigger ci-dessous)
-- et les rôles ne seront modifiables que via l'écran admin (plus tard).

-- 4. Création automatique du profil à chaque nouveau compte
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', ''),
    coalesce(
      (new.raw_user_meta_data ->> 'role')::public.user_role,
      'responsable_travaux'
    )
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row
  execute function public.handle_new_user();
