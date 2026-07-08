-- =============================================================
-- Migration 0008 — Suivi commercial (étape 7, import Excel)
-- Colonnes demandées par Christian pour reprendre les informations
-- du fichier de suivi CMT (une ligne = un devis) : n° de devis,
-- ordre de service, sous-traitance, rapport, CAT, facturation.
-- Remplies par l'import initial, affichées sur la fiche.
-- À exécuter dans le SQL Editor de Supabase.
-- =============================================================

alter table public.travaux
  add column reference_devis text not null default '',        -- ex. DE00001036
  add column numero_os text not null default '',              -- n° d'ordre de service
  add column montant_os numeric(12,2),                        -- montant OS HT (€)
  add column sous_traitance boolean,                          -- null = non renseigné
  add column nom_sous_traitant text not null default '',
  add column commande_sous_traitance text not null default '',-- ex. CF00005922
  add column commande_materiel text not null default '',      -- commande achat matériel
  add column rapport_intervention text not null default '',   -- ex. Reçu / En attente
  add column cat text not null default '',                    -- ex. Reçu / En attente
  add column facturation text not null default '';            -- ex. OUI / NON
