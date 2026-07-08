-- =============================================================
-- Migration 0006 — Workflow de validation (étape 5)
-- Soumission d'un chiffrage à la direction, validation ou refus
-- motivé, nouvelle version après refus. Chaque étape est tracée
-- (qui, quand) et le statut du travail suit le circuit :
-- Chiffrage en cours → En attente de validation → Validé / Refusé.
-- À exécuter dans le SQL Editor de Supabase.
-- =============================================================

-- 1. Traçabilité sur le chiffrage : qui a soumis, qui a décidé,
--    quand, et le motif en cas de refus (refus toujours motivé).
alter table public.chiffrages
  add column soumis_le timestamptz,
  add column soumis_par uuid references public.profiles (id),
  add column decide_le timestamptz,
  add column decide_par uuid references public.profiles (id),
  add column motif_refus text not null default '';

-- =============================================================
-- 2. Fonction : soumettre un chiffrage à la direction.
-- « security definer » (droits élevés) car elle fige le chiffrage
-- et fait passer le travail « En attente de validation », y compris
-- pour le responsable d'affaires qui n'a pas le droit de modifier
-- les travaux directement. La fonction vérifie elle-même le rôle.
-- =============================================================
create or replace function public.soumettre_chiffrage(p_chiffrage_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_role text;
  v_travail_id uuid;
  v_statut public.statut_chiffrage;
  v_statut_travail public.statut_travail;
begin
  select role into v_role from public.profiles where id = auth.uid();
  if v_role is null or v_role not in ('direction', 'responsable_affaires', 'admin') then
    raise exception 'Votre rôle ne permet pas de soumettre un chiffrage.';
  end if;

  select travail_id, statut into v_travail_id, v_statut
  from public.chiffrages
  where id = p_chiffrage_id
  for update;

  if v_travail_id is null then
    raise exception 'Chiffrage introuvable';
  end if;

  if v_statut <> 'brouillon' then
    raise exception 'Ce chiffrage a déjà été soumis.';
  end if;

  if not exists (
    select 1 from public.chiffrage_lignes where chiffrage_id = p_chiffrage_id
  ) then
    raise exception 'Ajoutez au moins un poste avant de soumettre.';
  end if;

  -- Garde-fou : une seule soumission en attente par travail
  if exists (
    select 1 from public.chiffrages
    where travail_id = v_travail_id and statut = 'soumis'
  ) then
    raise exception 'Un chiffrage est déjà en attente de validation pour ce travail.';
  end if;

  update public.chiffrages
  set statut = 'soumis',
      soumis_le = now(),
      soumis_par = auth.uid()
  where id = p_chiffrage_id;

  -- Le travail passe « En attente de validation » (journalisé)
  select statut into v_statut_travail
  from public.travaux
  where id = v_travail_id
  for update;

  if v_statut_travail <> 'en_attente_validation' then
    update public.travaux
    set statut = 'en_attente_validation'
    where id = v_travail_id;

    insert into public.travaux_historique
      (travail_id, ancien_statut, nouveau_statut, auteur)
    values
      (v_travail_id, v_statut_travail, 'en_attente_validation', auth.uid());
  end if;
end;
$$;

-- =============================================================
-- 3. Fonction : valider ou refuser un chiffrage soumis.
-- Règle métier (PRD) : seule la direction valide ou refuse,
-- et un refus est toujours motivé. Un chiffrage décidé ne bouge
-- plus jamais (nouvelle version en cas de refus).
-- =============================================================
create or replace function public.decider_chiffrage(
  p_chiffrage_id uuid,
  p_decision public.statut_chiffrage,   -- 'valide' ou 'refuse'
  p_motif text default ''
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_role text;
  v_travail_id uuid;
  v_statut public.statut_chiffrage;
  v_statut_travail public.statut_travail;
  v_nouveau public.statut_travail;
begin
  select role into v_role from public.profiles where id = auth.uid();
  if v_role is null or v_role <> 'direction' then
    raise exception 'Seule la direction peut valider ou refuser un chiffrage.';
  end if;

  if p_decision not in ('valide', 'refuse') then
    raise exception 'Décision invalide.';
  end if;

  if p_decision = 'refuse' and coalesce(trim(p_motif), '') = '' then
    raise exception 'Un refus doit être motivé.';
  end if;

  select travail_id, statut into v_travail_id, v_statut
  from public.chiffrages
  where id = p_chiffrage_id
  for update;

  if v_travail_id is null then
    raise exception 'Chiffrage introuvable';
  end if;

  if v_statut <> 'soumis' then
    raise exception 'Ce chiffrage n''est pas en attente de validation.';
  end if;

  update public.chiffrages
  set statut = p_decision,
      decide_le = now(),
      decide_par = auth.uid(),
      motif_refus = case when p_decision = 'refuse' then trim(p_motif) else '' end
  where id = p_chiffrage_id;

  -- Le travail suit la décision (journalisé)
  v_nouveau := case when p_decision = 'valide'
                    then 'valide'::public.statut_travail
                    else 'refuse'::public.statut_travail end;

  select statut into v_statut_travail
  from public.travaux
  where id = v_travail_id
  for update;

  if v_statut_travail <> v_nouveau then
    update public.travaux
    set statut = v_nouveau
    where id = v_travail_id;

    insert into public.travaux_historique
      (travail_id, ancien_statut, nouveau_statut, auteur)
    values
      (v_travail_id, v_statut_travail, v_nouveau, auth.uid());
  end if;
end;
$$;

-- =============================================================
-- 4. Fonction mise à jour : créer un chiffrage.
-- Nouveautés étape 5 :
--   - impossible de créer un brouillon tant qu'une version est en
--     attente de validation (la direction doit d'abord décider) ;
--   - la nouvelle version est pré-remplie avec les postes de la
--     version précédente (re-chiffrage après refus sans tout
--     ressaisir) ;
--   - après un refus, le travail repart en « Chiffrage en cours »
--     (journalisé), comme depuis « À chiffrer ».
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

  -- Un seul brouillon à la fois par travail
  if exists (
    select 1 from public.chiffrages
    where travail_id = p_travail_id and statut = 'brouillon'
  ) then
    raise exception 'Un chiffrage en brouillon existe déjà pour ce travail.';
  end if;

  -- Pas de nouveau brouillon tant qu'une version attend la décision
  if exists (
    select 1 from public.chiffrages
    where travail_id = p_travail_id and statut = 'soumis'
  ) then
    raise exception 'Un chiffrage est déjà en attente de validation pour ce travail.';
  end if;

  select coalesce(max(version), 0) + 1 into v_version
  from public.chiffrages
  where travail_id = p_travail_id;

  insert into public.chiffrages (travail_id, version, auteur)
  values (p_travail_id, v_version, auth.uid())
  returning id into v_id;

  -- Nouvelle version pré-remplie avec les postes de la précédente
  if v_version > 1 then
    insert into public.chiffrage_lignes
      (chiffrage_id, position, libelle, quantite, unite, prix_unitaire,
       montant, heures, origine, source)
    select
      v_id, l.position, l.libelle, l.quantite, l.unite, l.prix_unitaire,
      l.montant, l.heures, l.origine, l.source
    from public.chiffrage_lignes l
    join public.chiffrages c on c.id = l.chiffrage_id
    where c.travail_id = p_travail_id and c.version = v_version - 1;
  end if;

  -- Démarrer (ou reprendre après refus) un chiffrage fait avancer
  -- le travail dans son cycle de vie
  if v_statut in ('a_chiffrer', 'refuse') then
    update public.travaux
    set statut = 'chiffrage_en_cours'
    where id = p_travail_id;

    insert into public.travaux_historique
      (travail_id, ancien_statut, nouveau_statut, auteur)
    values
      (p_travail_id, v_statut, 'chiffrage_en_cours', auth.uid());
  end if;

  return v_id;
end;
$$;
