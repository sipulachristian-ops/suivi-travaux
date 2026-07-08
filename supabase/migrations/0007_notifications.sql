-- =============================================================
-- Migration 0007 — Notifications (étape 7)
-- Alertes dans l'application (PRD §5.5) :
--   - la direction est alertée quand un chiffrage est soumis ;
--   - le soumetteur est alerté quand la direction valide ou refuse.
-- (Les échéances proches/dépassées sont calculées en direct dans
--  l'application, sans stockage.)
-- Ajoute aussi l'e-mail dans les profils (pour l'envoi d'e-mails
-- et la future liste des utilisateurs).
-- À exécuter dans le SQL Editor de Supabase.
-- =============================================================

-- 1. L'e-mail de chaque utilisateur, copié depuis le compte de
--    connexion (auth.users n'est pas lisible par l'application).
alter table public.profiles
  add column email text not null default '';

update public.profiles p
set email = coalesce(u.email, '')
from auth.users u
where u.id = p.id;

-- Le trigger de création de profil copie désormais aussi l'e-mail
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, role, email)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', ''),
    coalesce(
      (new.raw_user_meta_data ->> 'role')::public.user_role,
      'responsable_travaux'
    ),
    coalesce(new.email, '')
  );
  return new;
end;
$$;

-- 2. La table des notifications : 1 ligne = 1 alerte pour 1 personne
create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  destinataire uuid not null references public.profiles (id) on delete cascade,
  titre text not null,
  message text not null default '',
  lien text not null default '',          -- page à ouvrir en cliquant
  lue_le timestamptz,                     -- null = pas encore lue
  created_at timestamptz not null default now()
);

create index notifications_destinataire_idx
  on public.notifications (destinataire, lue_le, created_at desc);

alter table public.notifications enable row level security;

-- Chacun ne voit que ses propres notifications
create policy "notifications_lecture_proprietaire"
  on public.notifications for select
  to authenticated
  using (destinataire = auth.uid());

-- Pas de politique INSERT/UPDATE/DELETE : les notifications sont
-- créées par les fonctions SQL (droits élevés) et marquées lues
-- via la fonction dédiée ci-dessous.

-- 3. Marquer ses notifications comme lues (toutes, ou une liste)
create or replace function public.marquer_notifications_lues(
  p_ids uuid[] default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.notifications
  set lue_le = now()
  where destinataire = auth.uid()
    and lue_le is null
    and (p_ids is null or id = any (p_ids));
end;
$$;

-- =============================================================
-- 4. Fonction mise à jour : soumettre un chiffrage.
-- Nouveauté étape 7 : chaque membre de la direction reçoit une
-- notification « Chiffrage à valider » (sauf s'il soumet lui-même).
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
  v_version integer;
  v_numero bigint;
  v_titre text;
  v_auteur_nom text;
begin
  select role into v_role from public.profiles where id = auth.uid();
  if v_role is null or v_role not in ('direction', 'responsable_affaires', 'admin') then
    raise exception 'Votre rôle ne permet pas de soumettre un chiffrage.';
  end if;

  select travail_id, statut, version into v_travail_id, v_statut, v_version
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
  select statut, numero, titre into v_statut_travail, v_numero, v_titre
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

  -- Notification à chaque membre de la direction (PRD §5.5)
  select full_name into v_auteur_nom
  from public.profiles where id = auth.uid();

  insert into public.notifications (destinataire, titre, message, lien)
  select
    p.id,
    'Chiffrage à valider',
    format('T-%s — %s : version %s soumise par %s.',
           v_numero, v_titre, v_version, coalesce(nullif(v_auteur_nom, ''), 'un collègue')),
    '/travaux/' || v_travail_id || '/chiffrages/' || p_chiffrage_id
  from public.profiles p
  where p.role = 'direction' and p.id <> auth.uid();
end;
$$;

-- =============================================================
-- 5. Fonction mise à jour : valider ou refuser un chiffrage.
-- Nouveauté étape 7 : la personne qui a soumis le chiffrage est
-- notifiée de la décision (avec le motif en cas de refus).
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
  v_soumis_par uuid;
  v_version integer;
  v_numero bigint;
  v_titre text;
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

  select travail_id, statut, soumis_par, version
  into v_travail_id, v_statut, v_soumis_par, v_version
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

  -- Notification à la personne qui a soumis (PRD §5.5)
  select numero, titre into v_numero, v_titre
  from public.travaux where id = v_travail_id;

  if v_soumis_par is not null and v_soumis_par <> auth.uid() then
    insert into public.notifications (destinataire, titre, message, lien)
    values (
      v_soumis_par,
      case when p_decision = 'valide'
           then 'Chiffrage validé' else 'Chiffrage refusé' end,
      format('T-%s — %s : la version %s a été %s.',
             v_numero, v_titre, v_version,
             case when p_decision = 'valide' then 'validée'
                  else 'refusée — motif : ' || trim(p_motif) end),
      '/travaux/' || v_travail_id || '/chiffrages/' || p_chiffrage_id
    );
  end if;
end;
$$;
