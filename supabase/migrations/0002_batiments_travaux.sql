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

-- 6. Sites réels (source : LISTE_DES_SITES_v2.xlsx, juillet 2026)
insert into public.batiments (nom, adresse) values
  ('Campus SAINT GERMAIN EN LAYE - SUP DE V', '51, Boulevard de la Paix 78100 St-Germain en Laye'),
  ('CCID 75', '2, Place de la Bourse, 75002 Paris'),
  ('CCID 78', '21 - 23, Avenue de Paris 78000 Versailles'),
  ('CCID 93', '191, Avenue Paul Vaillant Couturier 93000 Bobigny'),
  ('CCID 94', '8, Place Salvador Allende 94011 Creteil'),
  ('CCID 95', '35, Boulevard du Port 95000 Cergy'),
  ('Ecole de l''image, GOBELINS', '73, Boulevard Saint-Marcel, 75013 Paris'),
  ('ESCP Champerret', '6-8, Avenue de la Porte de Champerret 75017 Paris'),
  ('ESIEE-IT Pontoise', '8, Rue Pierre de Coubertin 95300 Pontoise'),
  ('Esset Lavoisier', '4, Place des Vosges 92400 Courbevoie'),
  ('Ferrandi Paris', '28, Rue de l’Abbé Grégoire, 75006 Paris'),
  ('Ferrandi Saint-Gratien', '17, Boulevard Pasteur 95210 Saint Gratien'),
  ('Friedland', '27, Avenue de Friedland, 75008 Paris'),
  ('GIFAS', '8, Rue Galilée, 75016 Paris'),
  ('Hermès George V', '42, Avenue. George V, 75008 Paris'),
  ('Hermès Sèvres', '17, Rue de Sèvres, 75006 Paris'),
  ('HOTEL CONSULAIRE', '2, Cours Monseigneur Roméro CS 50135 91004 Evry Cedex'),
  ('ISIPCA', '34/36, Rue du Parc de Clagny 78000 Versailles'),
  ('Jeff des Bruges', ''),
  ('L’EA / CFI GAMBETTA', '245, Avenue Gambetta 75020 Paris'),
  ('L''EA CFI ORLY', '5, Place de la Gare des Saules, 94310 Orly'),
  ('LNA Ennery', 'Route de Livilliers, 95300 Ennery'),
  ('LNA Epinay', '1, Place. du Dr Jean Tarrius, 93800 Épinay-sur-Seine'),
  ('LNA La Ferté-sous-jouarre', '20 Bis, Boulevard du 8 Mai 1945, 77260 la Ferté-sous-Jouarre'),
  ('LNA Meaux', '2 Bis, Rue d''Orgemont, 77100 Meaux'),
  ('LNA Moret-sur-loing', 'Ruelle des Masgons, 77250 Moret-sur-Loing'),
  ('Montparnasse', '1-5, Rue Armand Moisant 75015 Paris'),
  ('Musée national de la Marine', '17, Place de Trocadero 75016 Paris'),
  ('NRJ Boileau', '22, Rue de Boileau 75016 Paris'),
  ('NRJ Gauthier', '45, Avenue Theophile Gauthier 75016 Paris'),
  ('Pépinière Génopole', '4, Rue Pierre Fontaine 91000 Evry CS 50135'),
  ('Sup de V Enghien', '24 Bis, Boulevard d’Ormesson 95880 Enghien les Bains'),
  ('Sup de V Rambouillet', '44, Rue Raymond Patenôtre 78120 Rambouillet'),
  ('TECOMAH', 'Chemin de l’Orme Rond, 78350 Jouy en Josas'),
  ('Théatre des bouffes du Nord', ''),
  ('Tocqueville', '47-49, Rue de Tocqueville 75017 Paris'),
  ('Workman - Gennevilliers', '177, Avenue. des Grésillons Gennevilliers'),
  ('Workman - Les Docks', '50, Rue Ardoin, 93400 Saint-Ouen'),
  ('Workman - Magny les hameaux', '1, Rue George Guynemer Magny les Hameaux'),
  ('Workman - Saint Thibault Les Vignes', '2, Rue de la Noue Guimante Saint Thibault des Vignes'),
  ('Workman Paryseine', '3-5, Allée de la Seine 94200 Ivry-sur-Seine')
on conflict (nom) do nothing;
