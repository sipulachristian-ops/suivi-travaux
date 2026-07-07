-- =============================================================
-- Migration 0003 — Historique des changements de statut
-- Règle métier (PRD) : chaque changement d'état est horodaté
-- et attribué à son auteur. Cette table est le journal d'audit.
-- À exécuter dans le SQL Editor de Supabase.
-- =============================================================

create table public.travaux_historique (
  id uuid primary key default gen_random_uuid(),
  travail_id uuid not null references public.travaux (id),
  ancien_statut public.statut_travail not null,
  nouveau_statut public.statut_travail not null,
  auteur uuid not null references public.profiles (id),
  created_at timestamptz not null default now()
);

create index travaux_historique_travail_idx
  on public.travaux_historique (travail_id);

alter table public.travaux_historique enable row level security;

-- Lecture : tous les rôles connectés (l'historique est consultable)
create policy "historique_lecture_authentifiee"
  on public.travaux_historique for select
  to authenticated
  using (true);

-- Insertion : direction, responsable travaux, admin — et uniquement
-- en son propre nom (auteur = utilisateur connecté)
create policy "historique_insertion"
  on public.travaux_historique for insert
  to authenticated
  with check (
    auteur = auth.uid()
    and exists (
      select 1 from public.profiles
      where id = auth.uid()
        and role in ('direction', 'responsable_travaux', 'admin')
    )
  );

-- Pas de modification ni de suppression : un journal ne se réécrit pas.

-- =============================================================
-- Fonction : changer le statut d'un travail + journaliser,
-- en une seule opération (tout passe ou rien ne passe).
-- « security invoker » : les règles RLS ci-dessus s'appliquent.
-- =============================================================
create or replace function public.changer_statut_travail(
  p_travail_id uuid,
  p_nouveau_statut public.statut_travail
)
returns void
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_ancien public.statut_travail;
begin
  select statut into v_ancien
  from public.travaux
  where id = p_travail_id
  for update;

  if v_ancien is null then
    raise exception 'Travail introuvable';
  end if;

  if v_ancien = p_nouveau_statut then
    return; -- rien à faire
  end if;

  update public.travaux
  set statut = p_nouveau_statut
  where id = p_travail_id;

  insert into public.travaux_historique
    (travail_id, ancien_statut, nouveau_statut, auteur)
  values
    (p_travail_id, v_ancien, p_nouveau_statut, auth.uid());
end;
$$;
