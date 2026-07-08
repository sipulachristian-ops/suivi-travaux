-- =============================================================
-- Migration 0010 — Import initial des devis (étape 7)
-- Source : CMT SUIVI P5.xlsx + tri des sites de Christian
-- (TRI_SITES_IMPORT.xlsx), décisions actées le 2026-07-08 :
--   - 1 ligne du fichier = 1 demande, statut déduit de l'état
--     (Réalisé → Terminé, En cours de programmation → Planifié,
--     sinon → Validé) ;
--   - le montant HT devient un chiffrage validé à 1 poste forfait ;
--   - les infos commerciales vont dans les colonnes de la migration
--     0008 ; les nouveaux sites sont créés, les lignes internes
--     (consommables/outillage) sont écartées.
-- Prérequis : migrations 0008 et 0009 exécutées.
-- Ce script refuse de tourner deux fois (garde-fou en tête).
-- =============================================================

do $$
declare
  v_auteur uuid;
  v_bat uuid;
  v_travail uuid;
  v_chiffrage uuid;
begin
  -- L'import est porté par le compte direction de Christian
  select id into v_auteur from public.profiles
  where email = 'c.vunzasipula@jp-facilities.com';
  if v_auteur is null then
    select id into v_auteur from public.profiles
    where role in ('direction', 'admin') limit 1;
  end if;
  if v_auteur is null then
    raise exception 'Aucun profil direction ou admin pour porter l''import.';
  end if;

  -- Garde-fou : ne pas importer deux fois
  if exists (select 1 from public.travaux where reference_devis <> '') then
    raise exception 'Import déjà réalisé (des demandes portent un n° de devis).';
  end if;
  -- 1. Nouveaux bâtiments issus du tri de Christian
  insert into public.batiments (nom, adresse) values
    ('ADP ORLY-terminale 4', ''),
    ('ASEI', ''),
    ('AUDI Paris 16 - Premium Automobiles', ''),
    ('BOUYGUES ENERGIE & SERVICES', ''),
    ('CAP SUD REAL ESTATES', ''),
    ('CCI ESSONNE', ''),
    ('CENTRE HOSPITALIER RIVES DE SEINE', ''),
    ('CONSTRUCTA', ''),
    ('EFS (Etablissement Français du Sang)', ''),
    ('ENSA PARIS VAL DE SEINE', ''),
    ('EPFIF C/O NEXITY PM', ''),
    ('ESEIS', ''),
    ('GIE GROUPE CCI PARIS IDF', ''),
    ('HERMES SELLIER', ''),
    ('HOPITAL ANTOINE BECLERE', ''),
    ('HORUS WORKS & SERVICES', ''),
    ('Jerome LUCBERT', ''),
    ('Knauf Ceiling Solutions', ''),
    ('LA PLATEFORME DU BATIMENT', ''),
    ('MERCURE PARIS GARE DE L''EST', ''),
    ('MERCURE PARIS GARE DU NORD', ''),
    ('MINISTERE DE LA JUSTICE', ''),
    ('Monsieur Alex STAN', ''),
    ('O''TACOS CORPORATION', ''),
    ('PLISSON IMMOBILIER', ''),
    ('QSRP France', ''),
    ('RATP', ''),
    ('RATP REAL ESTATE', ''),
    ('RATP REAL ESTATE RATP EPIC SIEGE', ''),
    ('REGION ILE-DE-FRANCE', ''),
    ('SAS EVANCIA', ''),
    ('SCI FG CORPORATE', ''),
    ('SIXTINE', ''),
    ('SYLVAMETAL BAUDIN CHATEAUNEUF', ''),
    ('THEATRE DE LA PEPINIERE', ''),
    ('VILLE DE PUTEAUX', '')
  on conflict (nom) do nothing;

  -- DE00001036 — AUDI Paris 16 - Premium Automobiles
  select id into v_bat from public.batiments where nom = 'AUDI Paris 16 - Premium Automobiles';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : AUDI Paris 16 - Premium Automobiles';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('AUDI - GARDENNAGE HUMAIN - 03 MARS 2024', v_bat, 'normale', 'valide', v_auteur,
     'DE00001036', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00001036 (reprise Excel)', 1, 'forfait', 840.0, 840.0, 0);

  -- DE00001060 — Jerome LUCBERT
  select id into v_bat from public.batiments where nom = 'Jerome LUCBERT';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : Jerome LUCBERT';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('reparation lucbert jerome', v_bat, 'normale', 'valide', v_auteur,
     'DE00001060', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00001060 (reprise Excel)', 1, 'forfait', 363.66, 363.66, 0);

  -- DE00001064 — ASEI
  select id into v_bat from public.batiments where nom = 'ASEI';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : ASEI';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('TS REMPLACEMENT SONDE', v_bat, 'normale', 'valide', v_auteur,
     'DE00001064', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00001064 (reprise Excel)', 1, 'forfait', 1034.4, 1034.4, 0);

  -- DE00001128 — CONSTRUCTA
  select id into v_bat from public.batiments where nom = 'CONSTRUCTA';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : CONSTRUCTA';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('REMPLACEMENT ROBINETTERIE RESEAU RIA', v_bat, 'normale', 'valide', v_auteur,
     'DE00001128', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00001128 (reprise Excel)', 1, 'forfait', 19198.64, 19198.64, 0);

  -- DE00001146 — SIXTINE
  select id into v_bat from public.batiments where nom = 'SIXTINE';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : SIXTINE';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('Dépannage et entretien de la chaudiére mural', v_bat, 'normale', 'valide', v_auteur,
     'DE00001146', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00001146 (reprise Excel)', 1, 'forfait', 645.3, 645.3, 0);

  -- DE00001202 — VILLE DE PUTEAUX
  select id into v_bat from public.batiments where nom = 'VILLE DE PUTEAUX';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : VILLE DE PUTEAUX';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('Remplacement des batterie de l''onduleur de l''eclairage de sécurité', v_bat, 'normale', 'valide', v_auteur,
     'DE00001202', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00001202 (reprise Excel)', 1, 'forfait', 3627.2, 3627.2, 0);

  -- DE00001281 — Monsieur Alex STAN
  select id into v_bat from public.batiments where nom = 'Monsieur Alex STAN';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : Monsieur Alex STAN';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('Eclairage extérieur', v_bat, 'normale', 'valide', v_auteur,
     'DE00001281', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00001281 (reprise Excel)', 1, 'forfait', 16948.34, 16948.34, 0);

  -- DE00001367 — VILLE DE PUTEAUX
  select id into v_bat from public.batiments where nom = 'VILLE DE PUTEAUX';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : VILLE DE PUTEAUX';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('Remplacement des éclairages de la salle Mozart', v_bat, 'normale', 'valide', v_auteur,
     'DE00001367', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00001367 (reprise Excel)', 1, 'forfait', 5903.38, 5903.38, 0);

  -- DE00001369 — SYLVAMETAL BAUDIN CHATEAUNEUF
  select id into v_bat from public.batiments where nom = 'SYLVAMETAL BAUDIN CHATEAUNEUF';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : SYLVAMETAL BAUDIN CHATEAUNEUF';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('ANNULE - NOUVEAU DEVIS 1446 Chantier Mairie Chatou', v_bat, 'normale', 'valide', v_auteur,
     'DE00001369', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00001369 (reprise Excel)', 1, 'forfait', 29444.0, 29444.0, 0);

  -- DE00001456 — THEATRE DE LA PEPINIERE
  select id into v_bat from public.batiments where nom = 'THEATRE DE LA PEPINIERE';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : THEATRE DE LA PEPINIERE';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('REMPLACEMENT DE LA VANNE GAZ ET DES VANNES DE REMPLISSAGE', v_bat, 'normale', 'valide', v_auteur,
     'DE00001456', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00001456 (reprise Excel)', 1, 'forfait', 2949.6, 2949.6, 0);

  -- DE00001533 — PLISSON IMMOBILIER
  select id into v_bat from public.batiments where nom = 'PLISSON IMMOBILIER';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : PLISSON IMMOBILIER';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('Porte coupe-feu du local SOUS-STATION', v_bat, 'normale', 'valide', v_auteur,
     'DE00001533', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00001533 (reprise Excel)', 1, 'forfait', 1280.5, 1280.5, 0);

  -- DE00001580 — ENSA PARIS VAL DE SEINE
  select id into v_bat from public.batiments where nom = 'ENSA PARIS VAL DE SEINE';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : ENSA PARIS VAL DE SEINE';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('Remplacement de coffret de relayage', v_bat, 'normale', 'valide', v_auteur,
     'DE00001580', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00001580 (reprise Excel)', 1, 'forfait', 1847.0, 1847.0, 0);

  -- DE00001582 — MINISTERE DE LA JUSTICE
  select id into v_bat from public.batiments where nom = 'MINISTERE DE LA JUSTICE';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : MINISTERE DE LA JUSTICE';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('DEPLACEMENT DES UNITES EXTERIEURES', v_bat, 'normale', 'valide', v_auteur,
     'DE00001582', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00001582 (reprise Excel)', 1, 'forfait', 40271.5, 40271.5, 0);

  -- DE00001585 — CICT THEATRE DES BOUFFES DU NORD
  select id into v_bat from public.batiments where nom = 'Théatre des bouffes du Nord';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : Théatre des bouffes du Nord';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('LOT CFO CFA', v_bat, 'normale', 'valide', v_auteur,
     'DE00001585', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00001585 (reprise Excel)', 1, 'forfait', 181162.72, 181162.72, 0);

  -- DE00001592 — SCI CONFLUENCE PARYSEINE
  select id into v_bat from public.batiments where nom = 'Workman Paryseine';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : Workman Paryseine';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('Analyse de potabilité de type D1', v_bat, 'normale', 'valide', v_auteur,
     'DE00001592', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00001592 (reprise Excel)', 1, 'forfait', 2853.5, 2853.5, 0);

  -- DE00001598 — HOPITAL ANTOINE BECLERE
  select id into v_bat from public.batiments where nom = 'HOPITAL ANTOINE BECLERE';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : HOPITAL ANTOINE BECLERE';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('Travaux Supplémentaires', v_bat, 'normale', 'valide', v_auteur,
     'DE00001598', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00001598 (reprise Excel)', 1, 'forfait', 1134.0, 1134.0, 0);

  -- DE00001653 — SYLVAMETAL BAUDIN CHATEAUNEUF
  select id into v_bat from public.batiments where nom = 'SYLVAMETAL BAUDIN CHATEAUNEUF';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : SYLVAMETAL BAUDIN CHATEAUNEUF';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('CREATION DE VIDE SEAU', v_bat, 'normale', 'valide', v_auteur,
     'DE00001653', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00001653 (reprise Excel)', 1, 'forfait', 1670.0, 1670.0, 0);

  -- DE00001654 — HORUS WORKS & SERVICES
  select id into v_bat from public.batiments where nom = 'HORUS WORKS & SERVICES';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : HORUS WORKS & SERVICES';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('TRAITEMENT CLIMATIQUE ET AERAULIQUE REAMENAGEMENT C8-CVC MEN2', v_bat, 'normale', 'valide', v_auteur,
     'DE00001654', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00001654 (reprise Excel)', 1, 'forfait', 27064.0, 27064.0, 0);

  -- DE00001668 — HOPITAL ANTOINE BECLERE
  select id into v_bat from public.batiments where nom = 'HOPITAL ANTOINE BECLERE';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : HOPITAL ANTOINE BECLERE';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('Travaux Supplémentaires', v_bat, 'normale', 'valide', v_auteur,
     'DE00001668', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00001668 (reprise Excel)', 1, 'forfait', 1160.0, 1160.0, 0);

  -- DE00001758 — GIE GROUPE CCI PARIS IDF
  select id into v_bat from public.batiments where nom = 'GIE GROUPE CCI PARIS IDF';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : GIE GROUPE CCI PARIS IDF';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('Remplacement des servomoteurs et corps de vannes', v_bat, 'normale', 'valide', v_auteur,
     'DE00001758', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00001758 (reprise Excel)', 1, 'forfait', 3327.2, 3327.2, 0);

  -- DE00001768 — MERCURE PARIS GARE DE L''EST
  select id into v_bat from public.batiments where nom = 'MERCURE PARIS GARE DE L''EST';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : MERCURE PARIS GARE DE L''EST';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('Dépannage le 3 Février 2025 chambre 309', v_bat, 'normale', 'valide', v_auteur,
     'DE00001768', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00001768 (reprise Excel)', 1, 'forfait', 322.0, 322.0, 0);

  -- DE00001809 — GIE GROUPE CCI PARIS IDF
  select id into v_bat from public.batiments where nom = 'GIE GROUPE CCI PARIS IDF';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : GIE GROUPE CCI PARIS IDF';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('Remise en état du préparateur ECS', v_bat, 'normale', 'termine', v_auteur,
     'DE00001809', '4800131710', 1994.72, null,
     '', '', '',
     'Réçu', 'Reçu', 'OUI')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00001809 (reprise Excel)', 1, 'forfait', 1994.72, 1994.72, 0);

  -- DE00001837 — BOUYGUES ENERGIE & SERVICES
  select id into v_bat from public.batiments where nom = 'BOUYGUES ENERGIE & SERVICES';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : BOUYGUES ENERGIE & SERVICES';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('Travaux de plomberie et divers LA POSTE RODIER', v_bat, 'normale', 'valide', v_auteur,
     'DE00001837', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00001837 (reprise Excel)', 1, 'forfait', 1560.0, 1560.0, 0);

  -- DE00001840 — MERCURE PARIS GARE DE L''EST
  select id into v_bat from public.batiments where nom = 'MERCURE PARIS GARE DE L''EST';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : MERCURE PARIS GARE DE L''EST';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('hotel mercure gare de l''EST- Remplacement de gache électrique', v_bat, 'normale', 'valide', v_auteur,
     'DE00001840', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00001840 (reprise Excel)', 1, 'forfait', 485.79, 485.79, 0);

  -- DE00001874 — REGION ILE-DE-FRANCE
  select id into v_bat from public.batiments where nom = 'REGION ILE-DE-FRANCE';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : REGION ILE-DE-FRANCE';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('DEBROUSSAILLAGE PAVILLON 20/28 RUE DU BAS PAYS ROMAINVILLE', v_bat, 'normale', 'valide', v_auteur,
     'DE00001874', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00001874 (reprise Excel)', 1, 'forfait', 9970.0, 9970.0, 0);

  -- DE00001890 — ADP ORLY-terminale 4
  select id into v_bat from public.batiments where nom = 'ADP ORLY-terminale 4';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : ADP ORLY-terminale 4';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('AO ADP ORLY LOT 6', v_bat, 'normale', 'valide', v_auteur,
     'DE00001890', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00001890 (reprise Excel)', 1, 'forfait', 520528.09, 520528.09, 0);

  -- DE00001891 — ADP ORLY-terminale 4
  select id into v_bat from public.batiments where nom = 'ADP ORLY-terminale 4';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : ADP ORLY-terminale 4';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('AO ADP lot 7 CA', v_bat, 'normale', 'valide', v_auteur,
     'DE00001891', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00001891 (reprise Excel)', 1, 'forfait', 19437.51, 19437.51, 0);

  -- DE00001892 — ADP ORLY-terminale 4
  select id into v_bat from public.batiments where nom = 'ADP ORLY-terminale 4';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : ADP ORLY-terminale 4';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('AO ADP LOT 7 SSI', v_bat, 'normale', 'valide', v_auteur,
     'DE00001892', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00001892 (reprise Excel)', 1, 'forfait', 47426.27, 47426.27, 0);

  -- DE00001893 — ADP ORLY-terminale 4
  select id into v_bat from public.batiments where nom = 'ADP ORLY-terminale 4';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : ADP ORLY-terminale 4';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('AO ADP LOT 8 GTC ELEC', v_bat, 'normale', 'valide', v_auteur,
     'DE00001893', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00001893 (reprise Excel)', 1, 'forfait', 86474.56, 86474.56, 0);

  -- DE00001894 — ADP ORLY-terminale 4
  select id into v_bat from public.batiments where nom = 'ADP ORLY-terminale 4';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : ADP ORLY-terminale 4';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('AO ADP LOT 7 UGCIS', v_bat, 'normale', 'valide', v_auteur,
     'DE00001894', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00001894 (reprise Excel)', 1, 'forfait', 36663.47, 36663.47, 0);

  -- DE00001936 — Datanumia
  select id into v_bat from public.batiments where nom = 'Esset Lavoisier';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : Esset Lavoisier';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('Datanumia : Contrat de maintenance', v_bat, 'normale', 'valide', v_auteur,
     'DE00001936', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00001936 (reprise Excel)', 1, 'forfait', 1513.0, 1513.0, 0);

  -- DE0000194102 — VILLE DE PUTEAUX
  select id into v_bat from public.batiments where nom = 'VILLE DE PUTEAUX';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : VILLE DE PUTEAUX';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('Remise en état du GROUPE FROID CONSERVATOIRE DE PUTEAUX', v_bat, 'normale', 'valide', v_auteur,
     'DE0000194102', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE0000194102 (reprise Excel)', 1, 'forfait', 1758.0, 1758.0, 0);

  -- DE00001942 — CICT THEATRE DES BOUFFES DU NORD
  select id into v_bat from public.batiments where nom = 'Théatre des bouffes du Nord';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : Théatre des bouffes du Nord';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('LOT CFO/CFA', v_bat, 'normale', 'valide', v_auteur,
     'DE00001942', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00001942 (reprise Excel)', 1, 'forfait', 221559.22, 221559.22, 0);

  -- DE00001943 — CICT THEATRE DES BOUFFES DU NORD
  select id into v_bat from public.batiments where nom = 'Théatre des bouffes du Nord';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : Théatre des bouffes du Nord';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('LOT CVC/PLOMBERIE V3', v_bat, 'normale', 'valide', v_auteur,
     'DE00001943', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00001943 (reprise Excel)', 1, 'forfait', 472915.64, 472915.64, 0);

  -- DE00001950 — GIE GROUPE CCI PARIS IDF
  select id into v_bat from public.batiments where nom = 'GIE GROUPE CCI PARIS IDF';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : GIE GROUPE CCI PARIS IDF';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('ESCP Champerret : Remplacement des pompes', v_bat, 'normale', 'valide', v_auteur,
     'DE00001950', '4800133457', 5266.65, false,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00001950 (reprise Excel)', 1, 'forfait', 5266.65, 5266.65, 0);

  -- DE00001970 — SCI CONFLUENCE PARYSEINE
  select id into v_bat from public.batiments where nom = 'Workman Paryseine';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : Workman Paryseine';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('Paryseine contrat de maintenance sur la centrale groupe electrogene', v_bat, 'normale', 'valide', v_auteur,
     'DE00001970', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00001970 (reprise Excel)', 1, 'forfait', 1272.0, 1272.0, 0);

  -- DE00001980 — GIE GROUPE CCI PARIS IDF
  select id into v_bat from public.batiments where nom = 'GIE GROUPE CCI PARIS IDF';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : GIE GROUPE CCI PARIS IDF';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('CCID 94 : Remplacement d''un radiateur', v_bat, 'normale', 'valide', v_auteur,
     'DE00001980', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00001980 (reprise Excel)', 1, 'forfait', 1480.59, 1480.59, 0);

  -- DE00001989 — O''TACOS CORPORATION
  select id into v_bat from public.batiments where nom = 'O''TACOS CORPORATION';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : O''TACOS CORPORATION';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('Programmation et raccordement de la sortie 4 adresse 112 afin d''asserv', v_bat, 'normale', 'valide', v_auteur,
     'DE00001989', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00001989 (reprise Excel)', 1, 'forfait', 985.5, 985.5, 0);

  -- DE00002045 — BOUYGUES ENERGIE & SERVICES
  select id into v_bat from public.batiments where nom = 'BOUYGUES ENERGIE & SERVICES';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : BOUYGUES ENERGIE & SERVICES';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('Régularisation de l''intervention de dégorgement et de pompage La Poste', v_bat, 'normale', 'valide', v_auteur,
     'DE00002045', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00002045 (reprise Excel)', 1, 'forfait', 800.0, 800.0, 0);

  -- DE00002052 — LNA SANTE LA FERTE SOUS JOUARRE
  select id into v_bat from public.batiments where nom = 'LNA La Ferté-sous-jouarre';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : LNA La Ferté-sous-jouarre';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('Modification de raccordement réseau d’eau adoucie pour les machines à', v_bat, 'normale', 'valide', v_auteur,
     'DE00002052', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00002052 (reprise Excel)', 1, 'forfait', 1557.5, 1557.5, 0);

  -- DE00002056 — GIE GROUPE CCI PARIS IDF
  select id into v_bat from public.batiments where nom = 'GIE GROUPE CCI PARIS IDF';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : GIE GROUPE CCI PARIS IDF';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('REMPLACEMENT DES POINTS D''EAU ET MISE EN PLACE SUPPORT DE PROTECTION', v_bat, 'normale', 'valide', v_auteur,
     'DE00002056', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00002056 (reprise Excel)', 1, 'forfait', 494.72, 494.72, 0);

  -- DE00002062 — SAS EVANCIA
  select id into v_bat from public.batiments where nom = 'SAS EVANCIA';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : SAS EVANCIA';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('Crèche Babilou Vigneux Mozart 121 - Ticket n°56117', v_bat, 'normale', 'valide', v_auteur,
     'DE00002062', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00002062 (reprise Excel)', 1, 'forfait', 900.0, 900.0, 0);

  -- DE00002077 — MERCURE PARIS GARE DU NORD
  select id into v_bat from public.batiments where nom = 'MERCURE PARIS GARE DU NORD';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : MERCURE PARIS GARE DU NORD';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('Hôtel MERCURE Dépannage le 06/05/2025', v_bat, 'normale', 'valide', v_auteur,
     'DE00002077', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00002077 (reprise Excel)', 1, 'forfait', 617.0, 617.0, 0);

  -- DE00002080 — GIE GROUPE CCI PARIS IDF
  select id into v_bat from public.batiments where nom = 'GIE GROUPE CCI PARIS IDF';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : GIE GROUPE CCI PARIS IDF';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('L''EA CFI Gambetta - Pose d''un split avec une unité extérieure', v_bat, 'normale', 'valide', v_auteur,
     'DE00002080', '4800135267', 5003.0, null,
     '', '', '',
     '', 'En attente', 'NON')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00002080 (reprise Excel)', 1, 'forfait', 5003.0, 5003.0, 0);

  -- DE00002093 — GIE GROUPE CCI PARIS IDF
  select id into v_bat from public.batiments where nom = 'GIE GROUPE CCI PARIS IDF';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : GIE GROUPE CCI PARIS IDF';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('CCI FERRANDI - Remplacement servomoteur chaufferie', v_bat, 'normale', 'valide', v_auteur,
     'DE00002093', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00002093 (reprise Excel)', 1, 'forfait', 2800.0, 2800.0, 0);

  -- DE00002096 — SCI CONFLUENCE PARYSEINE
  select id into v_bat from public.batiments where nom = 'Workman Paryseine';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : Workman Paryseine';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('SCCI PARYSEINE REMPLACEMENT DES DURITES GE', v_bat, 'normale', 'valide', v_auteur,
     'DE00002096', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00002096 (reprise Excel)', 1, 'forfait', 1037.5, 1037.5, 0);

  -- DE00002099 — CAP SUD REAL ESTATES
  select id into v_bat from public.batiments where nom = 'CAP SUD REAL ESTATES';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : CAP SUD REAL ESTATES';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('ESSET CAPSUD MONTROUGE- REMISE EN ETAT DIVERS PLOMBERIE', v_bat, 'normale', 'valide', v_auteur,
     'DE00002099', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00002099 (reprise Excel)', 1, 'forfait', 3051.94, 3051.94, 0);

  -- DE00002102 — LNA SANTE LA FERTE SOUS JOUARRE
  select id into v_bat from public.batiments where nom = 'LNA La Ferté-sous-jouarre';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : LNA La Ferté-sous-jouarre';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('LNA Ferté-sous-Jouarre - Remplacement du moteur de CTA', v_bat, 'normale', 'valide', v_auteur,
     'DE00002102', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00002102 (reprise Excel)', 1, 'forfait', 4928.11, 4928.11, 0);

  -- DE00002103 — EPFIF C/O NEXITY PM
  select id into v_bat from public.batiments where nom = 'EPFIF C/O NEXITY PM';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : EPFIF C/O NEXITY PM';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('Nexity Péripôle - Contrat de maintenance P2', v_bat, 'normale', 'valide', v_auteur,
     'DE00002103', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00002103 (reprise Excel)', 1, 'forfait', 1791.0, 1791.0, 0);

  -- DE00002116 — LNA SANTE LA FERTE SOUS JOUARRE
  select id into v_bat from public.batiments where nom = 'LNA La Ferté-sous-jouarre';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : LNA La Ferté-sous-jouarre';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('Remplacement filtre magnétique et désembouage du réseau chauffage', v_bat, 'normale', 'valide', v_auteur,
     'DE00002116', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00002116 (reprise Excel)', 1, 'forfait', 16950.3, 16950.3, 0);

  -- DE00002120 — GIE GROUPE CCI PARIS IDF
  select id into v_bat from public.batiments where nom = 'GIE GROUPE CCI PARIS IDF';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : GIE GROUPE CCI PARIS IDF';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('L''EA CFI Gambetta : Pose de 2 caissons VMC', v_bat, 'normale', 'valide', v_auteur,
     'DE00002120', '4800134499', 3516.88, null,
     '', '', '',
     '', 'En attente', 'NON')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00002120 (reprise Excel)', 1, 'forfait', 3516.88, 3516.88, 0);

  -- DE00002147 — LNA SANTE EPINAY SUR SEINE
  select id into v_bat from public.batiments where nom = 'LNA Epinay';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : LNA Epinay';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('Remise en état de la CTA 03 SISMO', v_bat, 'normale', 'valide', v_auteur,
     'DE00002147', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00002147 (reprise Excel)', 1, 'forfait', 2788.75, 2788.75, 0);

  -- DE00002148 — LNA SANTE LA FERTE SOUS JOUARRE
  select id into v_bat from public.batiments where nom = 'LNA La Ferté-sous-jouarre';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : LNA La Ferté-sous-jouarre';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('Remplacement de l''extracteur hors service', v_bat, 'normale', 'valide', v_auteur,
     'DE00002148', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00002148 (reprise Excel)', 1, 'forfait', 3193.72, 3193.72, 0);

  -- DE00002152 — SAS EVANCIA
  select id into v_bat from public.batiments where nom = 'SAS EVANCIA';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : SAS EVANCIA';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('Crèche Babilou Vitry Concorde 273 - Remplacement du moto ventilateur', v_bat, 'normale', 'valide', v_auteur,
     'DE00002152', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00002152 (reprise Excel)', 1, 'forfait', 3432.52, 3432.52, 0);

  -- DE00002213 — EFS (Etablissement Français du Sang)
  select id into v_bat from public.batiments where nom = 'EFS (Etablissement Français du Sang)';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : EFS (Etablissement Français du Sang)';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('EFS - Fourniture d''une trappe de visite', v_bat, 'normale', 'valide', v_auteur,
     'DE00002213', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00002213 (reprise Excel)', 1, 'forfait', 15.6, 15.6, 0);

  -- DE00002258 — GIE GROUPE CCI PARIS IDF
  select id into v_bat from public.batiments where nom = 'GIE GROUPE CCI PARIS IDF';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : GIE GROUPE CCI PARIS IDF';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('CCID 75 Bourse - Remplacement du régulateur', v_bat, 'normale', 'valide', v_auteur,
     'DE00002258', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00002258 (reprise Excel)', 1, 'forfait', 1237.82, 1237.82, 0);

  -- DE00002264 — GIE GROUPE CCI PARIS IDF
  select id into v_bat from public.batiments where nom = 'GIE GROUPE CCI PARIS IDF';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : GIE GROUPE CCI PARIS IDF';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('CCI FERRANDI - Nettoyage CTA "Le 28 restaurant"', v_bat, 'normale', 'termine', v_auteur,
     'DE00002264', '4800135923', 5415.1, true,
     'PHASEO', 'CF00005922', '',
     'Réçu', 'Reçu', 'OUI')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00002264 (reprise Excel)', 1, 'forfait', 5415.1, 5415.1, 0);

  -- DE00002270 — RATP
  select id into v_bat from public.batiments where nom = 'RATP';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : RATP';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('L12 VOLONTAIRE', v_bat, 'normale', 'valide', v_auteur,
     'DE00002270', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00002270 (reprise Excel)', 1, 'forfait', 9580.53, 9580.53, 0);

  -- DE00002276 — GIE GROUPE CCI PARIS IDF
  select id into v_bat from public.batiments where nom = 'GIE GROUPE CCI PARIS IDF';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : GIE GROUPE CCI PARIS IDF';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('REMPLACEMENT CTA BT A ET B PAR CTA DOUBLE FLUX Option Débit variable', v_bat, 'normale', 'valide', v_auteur,
     'DE00002276', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00002276 (reprise Excel)', 1, 'forfait', 683347.52, 683347.52, 0);

  -- DE00002280 — GIE GROUPE CCI PARIS IDF
  select id into v_bat from public.batiments where nom = 'GIE GROUPE CCI PARIS IDF';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : GIE GROUPE CCI PARIS IDF';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('CCID 95 - Remplacement des blocs secours défaillants', v_bat, 'normale', 'valide', v_auteur,
     'DE00002280', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00002280 (reprise Excel)', 1, 'forfait', 480.0, 480.0, 0);

  -- DE00002298 — ESEIS
  select id into v_bat from public.batiments where nom = 'ESEIS';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : ESEIS';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('TRAITEMENT CLIMATIQUE ICI PICARDIE RADIO OPTION REMPLACEMENT PRODUCTIO', v_bat, 'normale', 'valide', v_auteur,
     'DE00002298', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00002298 (reprise Excel)', 1, 'forfait', 79769.8, 79769.8, 0);

  -- DE00002331 — CCI ESSONNE
  select id into v_bat from public.batiments where nom = 'CCI ESSONNE';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : CCI ESSONNE';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('Remplacement d''une cuvette et d''une plaque de déclenchement', v_bat, 'normale', 'termine', v_auteur,
     'DE00002331', '4800135885', 391.04, false,
     '', '', 'CF00005897',
     'En attente', 'En attente', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00002331 (reprise Excel)', 1, 'forfait', 391.04, 391.04, 0);

  -- DE00002343 — QSRP France
  select id into v_bat from public.batiments where nom = 'QSRP France';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : QSRP France';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('QSRP France - Fourniture de 30 badges', v_bat, 'normale', 'valide', v_auteur,
     'DE00002343', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00002343 (reprise Excel)', 1, 'forfait', 390.0, 390.0, 0);

  -- DE00002355 — EFS (Etablissement Français du Sang)
  select id into v_bat from public.batiments where nom = 'EFS (Etablissement Français du Sang)';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : EFS (Etablissement Français du Sang)';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('EFS - Traitement de remise en état', v_bat, 'normale', 'valide', v_auteur,
     'DE00002355', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00002355 (reprise Excel)', 1, 'forfait', 475.15, 475.15, 0);

  -- DE00002376 — LAVOISIER PARIS REAL ESTATE
  select id into v_bat from public.batiments where nom = 'Esset Lavoisier';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : Esset Lavoisier';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('ESSET Lavoisier - Intervention de Grundfos', v_bat, 'normale', 'valide', v_auteur,
     'DE00002376', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00002376 (reprise Excel)', 1, 'forfait', 585.0, 585.0, 0);

  -- DE00002378 — EHI France 5 C/O WorkmanTurnbul
  select id into v_bat from public.batiments where nom = 'Workman Paryseine';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : Workman Paryseine';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('WORKMAN Les Docks : Fourniture et pose des coffrets de sécurité 2', v_bat, 'normale', 'valide', v_auteur,
     'DE00002378', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00002378 (reprise Excel)', 1, 'forfait', 25070.0, 25070.0, 0);

  -- DE00002402 — CCI ESSONNE
  select id into v_bat from public.batiments where nom = 'CCI ESSONNE';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : CCI ESSONNE';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('Remplacement des pompes doubles du groupe froid', v_bat, 'normale', 'termine', v_auteur,
     'DE00002402', '4800137889', 6323.9, false,
     '', '', 'CF00006253',
     'Réçu', 'Reçu', 'NON')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00002402 (reprise Excel)', 1, 'forfait', 6293.9, 6293.9, 0);

  -- DE00002457 — CCI ESSONNE
  select id into v_bat from public.batiments where nom = 'CCI ESSONNE';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : CCI ESSONNE';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('Travaux de réfection réseau EFS Parking hotel consulaire', v_bat, 'normale', 'valide', v_auteur,
     'DE00002457', '4800139045', 2460.38, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00002457 (reprise Excel)', 1, 'forfait', 5315.9, 5315.9, 0);

  -- DE00002471 — EFS (Etablissement Français du Sang)
  select id into v_bat from public.batiments where nom = 'EFS (Etablissement Français du Sang)';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : EFS (Etablissement Français du Sang)';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('EFS - Création d’un groupe avec code activation', v_bat, 'normale', 'valide', v_auteur,
     'DE00002471', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00002471 (reprise Excel)', 1, 'forfait', 445.0, 445.0, 0);

  -- DE00002473 — HOPITAL ANTOINE BECLERE
  select id into v_bat from public.batiments where nom = 'HOPITAL ANTOINE BECLERE';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : HOPITAL ANTOINE BECLERE';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('HOPITAL BECLERE - 4 ème - aile A', v_bat, 'normale', 'valide', v_auteur,
     'DE00002473', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00002473 (reprise Excel)', 1, 'forfait', 7683.95, 7683.95, 0);

  -- DE00002498 — SCI FG CORPORATE
  select id into v_bat from public.batiments where nom = 'SCI FG CORPORATE';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : SCI FG CORPORATE';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('FDGV - Remplacement de 4 télécomandes', v_bat, 'normale', 'valide', v_auteur,
     'DE00002498', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00002498 (reprise Excel)', 1, 'forfait', 1466.08, 1466.08, 0);

  -- DE00002501 — LA PLATEFORME DU BATIMENT
  select id into v_bat from public.batiments where nom = 'LA PLATEFORME DU BATIMENT';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : LA PLATEFORME DU BATIMENT';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('DEPANNAGE WC SANIBROYEUR LPDB Puteaux', v_bat, 'normale', 'valide', v_auteur,
     'DE00002501', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00002501 (reprise Excel)', 1, 'forfait', 380.0, 380.0, 0);

  -- DE00002502 — GIE GROUPE CCI PARIS IDF
  select id into v_bat from public.batiments where nom = 'GIE GROUPE CCI PARIS IDF';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : GIE GROUPE CCI PARIS IDF';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('Sup de V Enghein - Remplacement d''un disconnecteur', v_bat, 'normale', 'valide', v_auteur,
     'DE00002502', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00002502 (reprise Excel)', 1, 'forfait', 489.46, 489.46, 0);

  -- DE00002506 — GIE GROUPE CCI PARIS IDF
  select id into v_bat from public.batiments where nom = 'GIE GROUPE CCI PARIS IDF';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : GIE GROUPE CCI PARIS IDF';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('TRAVAUX DE MISE EN PLACE DE PROTECTION DES RADIANTS', v_bat, 'normale', 'termine', v_auteur,
     'DE00002506', '', null, true,
     'Global service CVC', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00002506 (reprise Excel)', 1, 'forfait', 6090.0, 6090.0, 0);

  -- DE00002513 — HOPITAL ANTOINE BECLERE
  select id into v_bat from public.batiments where nom = 'HOPITAL ANTOINE BECLERE';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : HOPITAL ANTOINE BECLERE';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('Travaux modificatif Hopital Antoine Beclère R+3 Aile A et C', v_bat, 'normale', 'valide', v_auteur,
     'DE00002513', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00002513 (reprise Excel)', 1, 'forfait', 5221.68, 5221.68, 0);

  -- DE00002518 — EFS (Etablissement Français du Sang)
  select id into v_bat from public.batiments where nom = 'EFS (Etablissement Français du Sang)';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : EFS (Etablissement Français du Sang)';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('EFS - Fourniture de 50 badges', v_bat, 'normale', 'valide', v_auteur,
     'DE00002518', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00002518 (reprise Excel)', 1, 'forfait', 263.0, 263.0, 0);

  -- DE00002521 — LAVOISIER PARIS REAL ESTATE
  select id into v_bat from public.batiments where nom = 'Esset Lavoisier';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : Esset Lavoisier';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('ESSET LAVOISIER - Remplacement d''un mitigeur', v_bat, 'normale', 'valide', v_auteur,
     'DE00002521', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00002521 (reprise Excel)', 1, 'forfait', 411.49, 411.49, 0);

  -- DE00002534 — GIE GROUPE CCI PARIS IDF
  select id into v_bat from public.batiments where nom = 'GIE GROUPE CCI PARIS IDF';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : GIE GROUPE CCI PARIS IDF';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('REMPLACEMENT CAISSON VMC', v_bat, 'normale', 'valide', v_auteur,
     'DE00002534', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00002534 (reprise Excel)', 1, 'forfait', 1675.18, 1675.18, 0);

  -- DE00002547 — GIE GROUPE CCI PARIS IDF
  select id into v_bat from public.batiments where nom = 'GIE GROUPE CCI PARIS IDF';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : GIE GROUPE CCI PARIS IDF';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('Isipca - Remplacement de 4 électrovannes', v_bat, 'normale', 'valide', v_auteur,
     'DE00002547', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00002547 (reprise Excel)', 1, 'forfait', 1868.4, 1868.4, 0);

  -- DE00002549 — GIE GROUPE CCI PARIS IDF
  select id into v_bat from public.batiments where nom = 'GIE GROUPE CCI PARIS IDF';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : GIE GROUPE CCI PARIS IDF';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('Isipca - Remplacement d''un climatiseur', v_bat, 'normale', 'valide', v_auteur,
     'DE00002549', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00002549 (reprise Excel)', 1, 'forfait', 2874.79, 2874.79, 0);

  -- DE00002550 — GIE GROUPE CCI PARIS IDF
  select id into v_bat from public.batiments where nom = 'GIE GROUPE CCI PARIS IDF';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : GIE GROUPE CCI PARIS IDF';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('CCI FERRANDI PARIS - Remplacement pompe sur colonne non immergée', v_bat, 'normale', 'valide', v_auteur,
     'DE00002550', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00002550 (reprise Excel)', 1, 'forfait', 7268.25, 7268.25, 0);

  -- DE00002555 — HERMES SELLIER
  select id into v_bat from public.batiments where nom = 'HERMES SELLIER';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : HERMES SELLIER';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('George V - Remplacement d''un ballon de 15 litres', v_bat, 'normale', 'valide', v_auteur,
     'DE00002555', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00002555 (reprise Excel)', 1, 'forfait', 418.0, 418.0, 0);

  -- DE00002557 — GIE GROUPE CCI PARIS IDF
  select id into v_bat from public.batiments where nom = 'GIE GROUPE CCI PARIS IDF';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : GIE GROUPE CCI PARIS IDF';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('L''EA-CFI Orly - Nettoyage des conduits', v_bat, 'normale', 'valide', v_auteur,
     'DE00002557', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00002557 (reprise Excel)', 1, 'forfait', 1050.0, 1050.0, 0);

  -- DE00002575 — GIE GROUPE CCI PARIS IDF
  select id into v_bat from public.batiments where nom = 'GIE GROUPE CCI PARIS IDF';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : GIE GROUPE CCI PARIS IDF';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('ISIPCA - Remplacement de 2 vannes 3 voies', v_bat, 'normale', 'valide', v_auteur,
     'DE00002575', '', null, null,
     '', '', '',
     '', 'Reçu', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00002575 (reprise Excel)', 1, 'forfait', 1719.69, 1719.69, 0);

  -- DE00002582 — RATP REAL ESTATE RATP EPIC SIEGE
  select id into v_bat from public.batiments where nom = 'RATP REAL ESTATE RATP EPIC SIEGE';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : RATP REAL ESTATE RATP EPIC SIEGE';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('TRAVAUX CVC ET PLOMBERIE', v_bat, 'normale', 'valide', v_auteur,
     'DE00002582', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00002582 (reprise Excel)', 1, 'forfait', 34550.0, 34550.0, 0);

  -- DE00002583 — RATP REAL ESTATE
  select id into v_bat from public.batiments where nom = 'RATP REAL ESTATE';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : RATP REAL ESTATE';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('TRAVAUX AGENCEMENT LOCAL COMPRESSEUR', v_bat, 'normale', 'valide', v_auteur,
     'DE00002583', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00002583 (reprise Excel)', 1, 'forfait', 4436.0, 4436.0, 0);

  -- DE00002584 — GIE GROUPE CCI PARIS IDF
  select id into v_bat from public.batiments where nom = 'GIE GROUPE CCI PARIS IDF';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : GIE GROUPE CCI PARIS IDF';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('DEVIS REMPLACEMENT GROUPE UH LOCAL PREPA 028', v_bat, 'normale', 'termine', v_auteur,
     'DE00002584', '4800142113', 9259.68, true,
     'AAB ENERGIE', 'CF00006740', '',
     '', 'Reçu', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00002584 (reprise Excel)', 1, 'forfait', 9259.68, 9259.68, 0);

  -- DE00002588 — GIE GROUPE CCI PARIS IDF
  select id into v_bat from public.batiments where nom = 'GIE GROUPE CCI PARIS IDF';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : GIE GROUPE CCI PARIS IDF';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('RECHERCHE DE FUITES SUR GOUPE PREPA 027', v_bat, 'normale', 'termine', v_auteur,
     'DE00002588', '4800142112', 2870.4, true,
     'AAB ENERGIE', 'CF00006739', '',
     '', 'Reçu', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00002588 (reprise Excel)', 1, 'forfait', 2870.88, 2870.88, 0);

  -- DE00002591 — GIE GROUPE CCI PARIS IDF
  select id into v_bat from public.batiments where nom = 'GIE GROUPE CCI PARIS IDF';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : GIE GROUPE CCI PARIS IDF';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('Contrat P2 CCI 2910', v_bat, 'normale', 'valide', v_auteur,
     'DE00002591', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00002591 (reprise Excel)', 1, 'forfait', 750444.44, 750444.44, 0);

  -- DE00002610 — GIE GROUPE CCI PARIS IDF
  select id into v_bat from public.batiments where nom = 'GIE GROUPE CCI PARIS IDF';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : GIE GROUPE CCI PARIS IDF';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('ISIPCA - VERSAILLES', v_bat, 'normale', 'valide', v_auteur,
     'DE00002610', '', null, null,
     '', '', '',
     '', 'Reçu', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00002610 (reprise Excel)', 1, 'forfait', 36520.7, 36520.7, 0);

  -- DE00002619 — CCI ESSONNE
  select id into v_bat from public.batiments where nom = 'CCI ESSONNE';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : CCI ESSONNE';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('Pépinière Génopole - Maintenance des équipements BT inverseur', v_bat, 'normale', 'planifie', v_auteur,
     'DE00002619', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00002619 (reprise Excel)', 1, 'forfait', 15849.3, 15849.3, 0);

  -- DE00002645 — GIE GROUPE CCI PARIS IDF
  select id into v_bat from public.batiments where nom = 'GIE GROUPE CCI PARIS IDF';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : GIE GROUPE CCI PARIS IDF';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('CCI Montparnasse- REMPLACEMENT DU TE DE VISITE LOCAL MENAGE', v_bat, 'normale', 'valide', v_auteur,
     'DE00002645', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00002645 (reprise Excel)', 1, 'forfait', 926.98, 926.98, 0);

  -- DE00002757 — GIE GROUPE CCI PARIS IDF
  select id into v_bat from public.batiments where nom = 'GIE GROUPE CCI PARIS IDF';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : GIE GROUPE CCI PARIS IDF';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('CCI Montparnasse - POSTE CLARIFICATEUR CIRCUIT EG BATIMENT PARTENAIRE', v_bat, 'normale', 'termine', v_auteur,
     'DE00002757', '', null, true,
     'Guldagil', 'CF00007051', '',
     '', 'En attente', 'NON')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00002757 (reprise Excel)', 1, 'forfait', 3123.97, 3123.97, 0);

  -- DE00002667 — Knauf Ceiling Solutions
  select id into v_bat from public.batiments where nom = 'Knauf Ceiling Solutions';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : Knauf Ceiling Solutions';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('Remplacement de 3 mécanismes WC', v_bat, 'normale', 'valide', v_auteur,
     'DE00002667', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00002667 (reprise Excel)', 1, 'forfait', 1237.77, 1237.77, 0);

  -- DE00002698 — LNA SANTE MORET SUR LOING
  select id into v_bat from public.batiments where nom = 'LNA Moret-sur-loing';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : LNA Moret-sur-loing';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('REMPLACEMENT DE LA SOUPAPE DE SECURITE CHAUDIERE 2', v_bat, 'normale', 'valide', v_auteur,
     'DE00002698', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00002698 (reprise Excel)', 1, 'forfait', 474.0, 474.0, 0);

  -- DE00002701 — CENTRE HOSPITALIER RIVES DE SEINE
  select id into v_bat from public.batiments where nom = 'CENTRE HOSPITALIER RIVES DE SEINE';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : CENTRE HOSPITALIER RIVES DE SEINE';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('Travaux finitions isolation coupe-feu', v_bat, 'normale', 'valide', v_auteur,
     'DE00002701', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00002701 (reprise Excel)', 1, 'forfait', 7800.0, 7800.0, 0);

  -- DE00002775 — LNA SANTE ENNERY
  select id into v_bat from public.batiments where nom = 'LNA Ennery';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : LNA Ennery';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('LNA Ennery - Remplacement coffret et vase', v_bat, 'normale', 'valide', v_auteur,
     'DE00002775', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00002775 (reprise Excel)', 1, 'forfait', 1937.09, 1937.09, 0);

  -- DE00002788 — LAVOISIER PARIS REAL ESTATE
  select id into v_bat from public.batiments where nom = 'Esset Lavoisier';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : Esset Lavoisier';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('Remplacement des prises triphasés pour la nacelle', v_bat, 'normale', 'valide', v_auteur,
     'DE00002788', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00002788 (reprise Excel)', 1, 'forfait', 1835.65, 1835.65, 0);

  -- DE00002804 — RATP REAL ESTATE RATP EPIC SIEGE
  select id into v_bat from public.batiments where nom = 'RATP REAL ESTATE RATP EPIC SIEGE';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : RATP REAL ESTATE RATP EPIC SIEGE';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('Remplacement d''un caisson d''extraction', v_bat, 'normale', 'valide', v_auteur,
     'DE00002804', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00002804 (reprise Excel)', 1, 'forfait', 21000.0, 21000.0, 0);

  -- DE00002815 — GIE GROUPE CCI PARIS IDF
  select id into v_bat from public.batiments where nom = 'GIE GROUPE CCI PARIS IDF';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : GIE GROUPE CCI PARIS IDF';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('Cci ferrandi Saint-Gratien - Télécommandes RMZ 790.', v_bat, 'normale', 'termine', v_auteur,
     'DE00002815', '4800142581', 700.55, null,
     '', '', '',
     'Réçu', 'Reçu', 'OUI')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00002815 (reprise Excel)', 1, 'forfait', 800.55, 800.55, 0);

  -- DE00002828 — GIE GROUPE CCI PARIS IDF
  select id into v_bat from public.batiments where nom = 'GIE GROUPE CCI PARIS IDF';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : GIE GROUPE CCI PARIS IDF';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('CCI VERSAILLES/ CALORIFUGE DES GAINES/ KOKA', v_bat, 'normale', 'valide', v_auteur,
     'DE00002828', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00002828 (reprise Excel)', 1, 'forfait', 8688.4, 8688.4, 0);

  -- DE00003004 — CCI ESIEE IT PONTOISE
  select id into v_bat from public.batiments where nom = 'ESIEE-IT Pontoise';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : ESIEE-IT Pontoise';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('Remplacement pompe de puisage', v_bat, 'normale', 'planifie', v_auteur,
     'DE00003004', '4800144267', null, false,
     '', '', 'eau & vapeur',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00003004 (reprise Excel)', 1, 'forfait', 2259.96, 2259.96, 0);

  -- DE00002900 — CCI ESIEE IT PONTOISE
  select id into v_bat from public.batiments where nom = 'ESIEE-IT Pontoise';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : ESIEE-IT Pontoise';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('Remplacement de la télécommande de la CTA 3', v_bat, 'normale', 'planifie', v_auteur,
     'DE00002900', '4800144266', null, false,
     '', '', 'yess electrique',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00002900 (reprise Excel)', 1, 'forfait', 466.77, 466.77, 0);

  -- DE00002958 — CCI Jouy en JOSAS
  select id into v_bat from public.batiments where nom = 'TECOMAH';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : TECOMAH';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('Travaux de remplacement de la tuyauterie ACIER GALVA', v_bat, 'normale', 'termine', v_auteur,
     'DE00002958', '', null, true,
     'Global CVC BATI SERVICE', '', '',
     '', 'Reçu', '')
  returning id into v_travail;

  -- DE00002863 — HERMES SELLIER
  select id into v_bat from public.batiments where nom = 'HERMES SELLIER';
  if v_bat is null then
    raise exception 'Bâtiment introuvable : HERMES SELLIER';
  end if;
  insert into public.travaux
    (titre, batiment_id, priorite, statut, cree_par,
     reference_devis, numero_os, montant_os, sous_traitance,
     nom_sous_traitant, commande_sous_traitance, commande_materiel,
     rapport_intervention, cat, facturation)
  values
    ('hermes sèvres - Dépannage', v_bat, 'normale', 'valide', v_auteur,
     'DE00002863', '', null, null,
     '', '', '',
     '', '', '')
  returning id into v_travail;
  insert into public.chiffrages
    (travail_id, version, statut, auteur, soumis_le, soumis_par, decide_le, decide_par)
  values (v_travail, 1, 'valide', v_auteur, now(), v_auteur, now(), v_auteur)
  returning id into v_chiffrage;
  insert into public.chiffrage_lignes
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire, montant, heures)
  values (v_chiffrage, 1, 'Montant du devis DE00002863 (reprise Excel)', 1, 'forfait', 393.6, 393.6, 0);
end $$;
