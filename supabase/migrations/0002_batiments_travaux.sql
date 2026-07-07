-- ============================================================
-- Migration 0002 — Bâtiments et travaux (étape 2)
-- À exécuter dans Supabase : Dashboard → SQL Editor → Run
-- ============================================================

-- 1. Priorités (décision actée : 4 niveaux)
create type public.priorite_travail as enum (
  'basse',
  'normale',
  'haute',
  'urgente'
);

-- 2. Statuts du cycle de vie (PRD §4.1, liste validée)
create type public.statut_travail as enum (
  'a_chiffrer',
  'chiffrage_en_cours',
  'en_attente_validation',
  'valide',
  'refuse',
  'planifie',
  'en_cours',
  'termine'
);

-- 3. Bâtiments (paramètre de référence, géré par l'admin)
create table public.batiments (
  id uuid primary key default gen_random_uuid(),
  nom text not null unique,
  adresse text not null default '',
  actif boolean not null default true,
  created_at timestamptz not null default now()
);

alter table public.batiments enable row level security;

create policy "batiments_lecture_authentifiee"
  on public.batiments for select
  to authenticated
  using (true);

create policy "batiments_gestion_admin_direction"
  on public.batiments for all
  to authenticated
  using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role in ('admin', 'direction')
    )
  )
  with check (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role in ('admin', 'direction')
    )
  );

-- 4. Travaux (PRD §5.1)
create table public.travaux (
  id uuid primary key default gen_random_uuid(),
  numero bigint generated always as identity,          -- n° lisible : T-1, T-2…
  titre text not null,                                  -- intitulé court pour les listes
  nature text not null default '',                      -- catégorie libre (plomberie, électricité…)
  description text not null default '',
  batiment_id uuid not null references public.batiments (id),
  priorite public.priorite_travail not null default 'normale',
  statut public.statut_travail not null default 'a_chiffrer',
  echeance date,
  responsable_id uuid references public.profiles (id),  -- responsable du suivi
  cree_par uuid not null references public.profiles (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index travaux_statut_idx on public.travaux (statut);
create index travaux_batiment_idx on public.travaux (batiment_id);

alter table public.travaux enable row level security;

-- Lecture : tous les rôles connectés (chacun voit la liste)
create policy "travaux_lecture_authentifiee"
  on public.travaux for select
  to authenticated
  using (true);

-- Création : direction, responsable travaux, admin
-- (décision actée : la direction peut aussi créer)
create policy "travaux_creation"
  on public.travaux for insert
  to authenticated
  with check (
    cree_par = auth.uid()
    and exists (
      select 1 from public.profiles
      where id = auth.uid()
        and role in ('direction', 'responsable_travaux', 'admin')
    )
  );

-- Modification : direction, responsable travaux, admin
create policy "travaux_modification"
  on public.travaux for update
  to authenticated
  using (
    exists (
      select 1 from public.profiles
      where id = auth.uid()
        and role in ('direction', 'responsable_travaux', 'admin')
    )
  );

-- Pas de suppression : un travail se clôture (statut « terminé »),
-- il ne s'efface pas (traçabilité).

-- 5. Horodatage automatique des modifications
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create trigger travaux_updated_at
  before update on public.travaux
  for each row
  execute function public.set_updated_at();

-- 6. Bâtiments de départ — ⚠️ REMPLACER par les vrais noms
insert into public.batiments (nom, adresse) values
  ('Bâtiment A', ''),
  ('Bâtiment B', ''),
  ('Bâtiment C', '');
