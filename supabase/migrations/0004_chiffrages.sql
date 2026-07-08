-- =============================================================
-- Migration 0004 — Chiffrages (étape 4 : chiffrage manuel)
-- Un travail peut avoir plusieurs chiffrages (versions) ; chaque
-- chiffrage contient des postes (libellé, montant, heures).
-- À exécuter dans le SQL Editor de Supabase.
-- =============================================================

-- 1. Statuts d'un chiffrage. L'étape 4 n'utilise que « brouillon » ;
--    les autres serviront au workflow de validation (étape 5).
create type public.statut_chiffrage as enum (
  'brouillon',
  'soumis',
  'valide',
  'refuse'
);

-- 2. Origine d'un poste (architecture §5) : saisi à la main,
--    proposé par l'IA (étape 6) ou issu d'une recherche web.
create type public.origine_ligne as enum (
  'manuel',
  'ia',
  'web'
);

-- 3. Chiffrages (versionnés : un travail peut être re-chiffré)
create table public.chiffrages (
  id uuid primary key default gen_random_uuid(),
  travail_id uuid not null references public.travaux (id),
  version integer not null,
  statut public.statut_chiffrage not null default 'brouillon',
  auteur uuid not null references public.profiles (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (travail_id, version)
);

create index chiffrages_travail_idx on public.chiffrages (travail_id);

create trigger chiffrages_updated_at
  before update on public.chiffrages
  for each row
  execute function public.set_updated_at();

alter table public.chiffrages enable row level security;

-- Lecture : tous les rôles connectés
create policy "chiffrages_lecture_authentifiee"
  on public.chiffrages for select
  to authenticated
  using (true);

-- Pas de policy d'insertion ni de suppression : un chiffrage se crée
-- uniquement via la fonction creer_chiffrage (ci-dessous), qui garantit
-- le numéro de version et la mise à jour du statut du travail.
-- Un chiffrage ne se supprime jamais (traçabilité).

-- 4. Postes d'un chiffrage
create table public.chiffrage_lignes (
  id uuid primary key default gen_random_uuid(),
  chiffrage_id uuid not null references public.chiffrages (id) on delete cascade,
  position integer not null default 0,          -- ordre d'affichage
  libelle text not null,
  montant numeric(12,2) not null default 0,     -- en euros
  heures numeric(7,2) not null default 0,
  origine public.origine_ligne not null default 'manuel',
  source text not null default '',              -- URL si origine = web
  created_at timestamptz not null default now()
);

create index chiffrage_lignes_chiffrage_idx
  on public.chiffrage_lignes (chiffrage_id);

alter table public.chiffrage_lignes enable row level security;

-- Lecture : tous les rôles connectés
create policy "lignes_lecture_authentifiee"
  on public.chiffrage_lignes for select
  to authenticated
  using (true);

-- Écriture (ajout, modification, suppression de postes) :
-- direction, responsable d'affaires, admin — et uniquement tant que
-- le chiffrage est en brouillon (un chiffrage validé ne bouge plus).
-- Décision actée le 2026-07-08 : la direction peut aussi chiffrer.
create policy "lignes_ecriture_brouillon"
  on public.chiffrage_lignes for all
  to authenticated
  using (
    exists (
      select 1 from public.profiles
      where id = auth.uid()
        and role in ('direction', 'responsable_affaires', 'admin')
    )
    and exists (
      select 1 from public.chiffrages c
      where c.id = chiffrage_id and c.statut = 'brouillon'
    )
  )
  with check (
    exists (
      select 1 from public.profiles
      where id = auth.uid()
        and role in ('direction', 'responsable_affaires', 'admin')
    )
    and exists (
      select 1 from public.chiffrages c
      where c.id = chiffrage_id and c.statut = 'brouillon'
    )
  );

-- =============================================================
-- Fonction : créer un chiffrage pour un travail.
-- « security definer » (droits élevés) car elle doit aussi faire
-- passer le travail « À chiffrer » → « Chiffrage en cours » et le
-- journaliser, y compris pour le responsable d'affaires qui n'a
-- pas le droit de modifier les travaux directement. La fonction
-- vérifie elle-même le rôle de l'appelant.
-- =============================================================
create or replace function public.creer_chiffrage(p_travail_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_role text;
  v_statut public.statut_travail;
  v_version integer;
  v_id uuid;
begin
  select role into v_role from public.profiles where id = auth.uid();
  if v_role is null or v_role not in ('direction', 'responsable_affaires', 'admin') then
    raise exception 'Votre rôle ne permet pas de chiffrer.';
  end if;

  select statut into v_statut
  from public.travaux
  where id = p_travail_id
  for update;

  if v_statut is null then
    raise exception 'Travail introuvable';
  end if;

  -- Un seul brouillon à la fois par travail (les versions suivantes
  -- arriveront avec le re-chiffrage, étape 5).
  if exists (
    select 1 from public.chiffrages
    where travail_id = p_travail_id and statut = 'brouillon'
  ) then
    raise exception 'Un chiffrage en brouillon existe déjà pour ce travail.';
  end if;

  select coalesce(max(version), 0) + 1 into v_version
  from public.chiffrages
  where travail_id = p_travail_id;

  insert into public.chiffrages (travail_id, version, auteur)
  values (p_travail_id, v_version, auth.uid())
  returning id into v_id;

  -- Démarrer un chiffrage fait avancer le travail dans son cycle de vie
  if v_statut = 'a_chiffrer' then
    update public.travaux
    set statut = 'chiffrage_en_cours'
    where id = p_travail_id;

    insert into public.travaux_historique
      (travail_id, ancien_statut, nouveau_statut, auteur)
    values
      (p_travail_id, 'a_chiffrer', 'chiffrage_en_cours', auth.uid());
  end if;

  return v_id;
end;
$$;

-- =============================================================
-- Fonction : remplacer tous les postes d'un chiffrage en une seule
-- opération (tout passe ou rien ne passe). « security invoker » :
-- les règles RLS ci-dessus s'appliquent (rôles autorisés, brouillon).
-- =============================================================
create or replace function public.remplacer_lignes_chiffrage(
  p_chiffrage_id uuid,
  p_lignes jsonb
)
returns void
language plpgsql
security invoker
set search_path = public
as $$
begin
  delete from public.chiffrage_lignes
  where chiffrage_id = p_chiffrage_id;

  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, montant, heures, origine, source)
  select
    p_chiffrage_id,
    t.ordre,
    coalesce(t.ligne->>'libelle', ''),
    coalesce((t.ligne->>'montant')::numeric, 0),
    coalesce((t.ligne->>'heures')::numeric, 0),
    coalesce((t.ligne->>'origine')::public.origine_ligne, 'manuel'),
    coalesce(t.ligne->>'source', '')
  from jsonb_array_elements(coalesce(p_lignes, '[]'::jsonb))
    with ordinality as t(ligne, ordre);
end;
$$;
