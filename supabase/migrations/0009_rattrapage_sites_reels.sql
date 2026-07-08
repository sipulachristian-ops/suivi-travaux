-- =============================================================
-- Migration 0009 — Rattrapage : les 41 sites réels (étape 7)
-- Constat du 2026-07-08 : la base de production a été créée avec la
-- première version de la migration 0002 (bâtiments d'exemple A/B/C) ;
-- la version avec les 41 sites réels (LISTE_DES_SITES_v2.xlsx) n'a
-- jamais été exécutée. Cette migration :
--   1. insère les 41 sites réels (sans doublon : on ignore un nom
--      déjà présent) ;
--   2. désactive les bâtiments d'exemple A/B/C — ils disparaissent
--      des listes de choix mais les demandes de test qui les utilisent
--      restent intactes (pas de suppression, traçabilité).
-- À exécuter dans le SQL Editor de Supabase.
-- =============================================================

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

-- Les bâtiments d'exemple ne doivent plus être proposés à la création
update public.batiments
set actif = false
where nom in ('Bâtiment A', 'Bâtiment B', 'Bâtiment C');
