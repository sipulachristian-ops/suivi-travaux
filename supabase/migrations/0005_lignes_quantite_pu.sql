-- =============================================================
-- Migration 0005 — Postes en quantité × prix unitaire
-- Retour de Christian après test de l'étape 4 : la saisie
-- « montant global + heures » n'est pas intuitive ; un poste se
-- chiffre comme sur un devis : quantité × prix unitaire, avec
-- une unité (u, h, forfait, m², ml). Le montant est calculé,
-- les heures découlent des lignes en « h ».
-- À exécuter dans le SQL Editor de Supabase.
-- =============================================================

alter table public.chiffrage_lignes
  add column quantite numeric(12,3) not null default 1,
  add column unite text not null default 'u',
  add column prix_unitaire numeric(12,2) not null default 0;

-- Reprise des lignes déjà saisies (données de test de l'étape 4) :
-- l'ancien montant global devient 1 × prix unitaire.
update public.chiffrage_lignes
set prix_unitaire = montant,
    quantite = 1,
    unite = 'u';

-- =============================================================
-- Fonction mise à jour : le montant et les heures de chaque poste
-- sont calculés ici (source de vérité unique) :
--   montant = quantité × prix unitaire
--   heures  = quantité si l'unité est « h », sinon 0
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
    (chiffrage_id, position, libelle, quantite, unite, prix_unitaire,
     montant, heures, origine, source)
  select
    p_chiffrage_id,
    t.ordre,
    coalesce(t.ligne->>'libelle', ''),
    coalesce((t.ligne->>'quantite')::numeric, 1),
    coalesce(t.ligne->>'unite', 'u'),
    coalesce((t.ligne->>'prix_unitaire')::numeric, 0),
    round(
      coalesce((t.ligne->>'quantite')::numeric, 1)
      * coalesce((t.ligne->>'prix_unitaire')::numeric, 0),
      2
    ),
    case
      when coalesce(t.ligne->>'unite', 'u') = 'h'
        then coalesce((t.ligne->>'quantite')::numeric, 0)
      else 0
    end,
    coalesce((t.ligne->>'origine')::public.origine_ligne, 'manuel'),
    coalesce(t.ligne->>'source', '')
  from jsonb_array_elements(coalesce(p_lignes, '[]'::jsonb))
    with ordinality as t(ligne, ordre);
end;
$$;
