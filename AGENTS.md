<!-- BEGIN:nextjs-agent-rules -->
# This is NOT the Next.js you know

This version has breaking changes — APIs, conventions, and file structure may all differ from your training data. Read the relevant guide in `node_modules/next/dist/docs/` before writing any code. Heed deprecation notices.
<!-- END:nextjs-agent-rules -->

# Suivi des travaux (JP Facilities)

Application web de suivi des travaux de maintenance sur bâtiments :
création/suivi des travaux, chiffrage assisté par IA, workflow de
validation par la direction.

## Documents de référence (à consulter en cas de doute)

Dans `C:\Users\Christian.SIPULA\jp-facilities\METHODES - JP FACILITIES - Documents\_DOCUMENTS CLAUDE\_Suivi des travaux\` :
- `PRD_Suivi_Travaux.md` — le quoi et le pourquoi (v0.2, décisions actées).
- `Architecture_Technique.md` — le comment (stack, modèle de données).
- `Technique-PRD.md` — consignes de travail détaillées avec Christian.

## Contexte développeur

Christian développe **seul** et est **non-technique**. Règles d'or :
- Expliquer sans jargon, avancer par **petites étapes testables**.
- **Demander avant** : choix structurants, modifications de structure de la
  base, nouvel outil. Ne jamais inventer une décision non tranchée.
- **Jamais de secret dans le code** (variables d'environnement uniquement).
- Recommander une option plutôt que lister des choix à l'aveugle.
- En début de session : rappeler où on en est, proposer la prochaine action.

## Stack (décidée, ne pas changer sans accord)

Next.js 16 (App Router, TypeScript) · Tailwind v4 + shadcn/ui ·
Supabase (PostgreSQL + Auth + Storage) · API Claude pour le chiffrage IA ·
Vercel. Détails d'infra :
- Le composant Button installé est la variante **Base UI** : liens via
  `render={<Link … />}`, PAS `asChild`.
- Next 16 : le middleware s'appelle **`src/proxy.ts`** (session + protection
  des pages, voir `src/lib/supabase/middleware.ts`).
- Migrations SQL dans `supabase/migrations/` — **exécutées à la main par
  Christian** dans le SQL Editor de Supabase (pas de CLI Supabase).
- Clés locales dans `.env.local` (non versionné) ; en production, variables
  d'environnement Vercel.

## Déploiement

- GitHub : `sipulachristian-ops/suivi-travaux` (privé). Chaque push sur
  `main` déploie automatiquement en production.
- Production : https://suivi-travaux-nu.vercel.app
- Préview locale : port 3005 (config `suivi-travaux` dans le launch.json du
  dossier `_PERSO\_CLAUDE`, ou `npm run dev`).

## Feuille de route — ne passer à l'étape suivante qu'après validation de Christian

1. ✅ **Fondations** — Next.js, Supabase, Vercel, auth + rôles (terminée le 2026-07-07).
2. ✅ **Gestion des travaux** — créer, lister, filtrer ; vue liste (validée par Christian le 2026-07-08).
3. ✅ **Vue Kanban** — bascule liste/Kanban, glisser-déposer, historique des
   statuts (validée par Christian le 2026-07-08, migration 0003 exécutée).
4. 🔄 **Chiffrage manuel** — saisie poste par poste, sans IA (construite le
   2026-07-08, en test par Christian — nécessite la migration
   `0004_chiffrages.sql`).
5. ⬜ **Workflow de validation** — soumission, validation/refus, versionnage.
6. ⬜ **Chiffrage IA** — API Claude (texte + photos) + recherche web.
7. ⬜ **Vue synthétique direction** — tableau de bord.
8. ⬜ **Notifications + import Excel**.

## Décisions actées en cours de route

- La **direction peut aussi créer des travaux** (en plus du responsable
  travaux et de l'admin) — tranché par Christian le 2026-07-07.
- **Priorités** : basse / normale / haute / urgente.
- Pas de suppression de travaux (clôture par statut « terminé », traçabilité).
- Compte de test : Christian, rôle `direction` (c.vunzasipula@jp-facilities.com).
- 41 sites réels importés depuis `LISTE_DES_SITES_v2.xlsx` (dossier `_KIZEO\_LISTE`
  sur le SharePoint) ; ce fichier contient aussi client et chargé d'affaires
  par site, non exploités pour l'instant.
- **Changement de statut** (étape 3) : via glisser-déposer du Kanban ou le
  sélecteur de la fiche. Les statuts « Validé »/« Refusé » sont réservés à la
  direction (le vrai circuit de validation, avec motif de refus, arrive à
  l'étape 5). Chaque changement est journalisé dans `travaux_historique`
  via la fonction SQL `changer_statut_travail` (atomique, RLS appliquée).
- **Choix de vue** liste/Kanban : paramètre d'URL `?vue=` + cookie
  `vue_travaux` (mémorise le dernier choix).
- **Identité visuelle** (retour de Christian le 2026-07-08 : « pas de couleur,
  pas de logo, tableau pas mis en avant ») : orange JP Facilities **#EC6707**
  (couleur exacte du logo du site jp-facilities.com) comme `--primary`, base
  neutre chaude, logo dans `public/logo-jpf.png` (en-tête + connexion),
  tableau en carte avec zébrures et retards en rouge (`estEnRetard`),
  colonnes Kanban avec bordure haute colorée (`STATUT_ACCENTS`).
  Christian est attentif au rendu visuel — soigner chaque nouvel écran.

- **Chiffrage manuel** (étape 4, décisions actées par Christian le
  2026-07-08) : la **direction peut aussi chiffrer** (en plus du responsable
  d'affaires et de l'admin — pratique : son compte de test est direction) ;
  une ligne (poste) = **libellé + quantité × prix unitaire** (unités : u, h,
  forfait, m², ml — montant calculé ; les heures du chiffrage = somme des
  quantités des lignes en « h »). Format initial « montant + heures » jugé
  pas intuitif par Christian après test → migration `0005_lignes_quantite_pu.sql`.
  Tables `chiffrages` (versionnées, statut `brouillon`/`soumis`/`valide`/
  `refuse` — seule `brouillon` sert à l'étape 4) et `chiffrage_lignes`
  (migration `0004_chiffrages.sql`). Création uniquement via la fonction SQL
  `creer_chiffrage` (security definer : version + passage automatique
  « À chiffrer » → « Chiffrage en cours » journalisé) ; un seul brouillon à
  la fois par travail ; postes enregistrés en bloc via
  `remplacer_lignes_chiffrage` (atomique, RLS : rôles autorisés + brouillon).
  Page : `/travaux/[id]/chiffrages/[chiffrageId]`. La soumission à
  validation arrive à l'étape 5.

## Règles métier (rappel)

- Statuts : À chiffrer → Chiffrage en cours → En attente de validation →
  Validé (ou Refusé) → Planifié → En cours → Terminé.
- Seule la direction valide/refuse un chiffrage ; refus motivé.
- Un chiffrage validé n'est jamais modifié : nouvelle version re-validée.
- L'IA propose, l'humain dispose ; prix web = pistes sourcées, jamais fermes.
- Chaque changement d'état : horodaté et attribué (audit).

## Remarques de Christian en attente (données le 2026-07-08, à traiter plus tard — pas tout de suite)

Sur l'écran de chiffrage / le tableau des postes :

- Afficher la **date de création** (manquante à ses yeux — préciser où exactement le moment venu).
- **Terminologie : on ne dit pas « travail »** — il parle de « demande » (à confirmer : quel terme exact partout dans l'app ?).
- Afficher le **n° de la demande et son id**.
- Un bouton **« Import »** pour ajouter des lignes (postes) en masse.
- Pouvoir **cocher des lignes** (cases à cocher — usage à préciser : suppression multiple ? sélection ?).
- Tableau avec des **bordures visibles gris clair**.

## Points non tranchés (demander à Christian le moment venu)

- Structure précise de l'import Excel initial des travaux.
- Niveau de détail du stockage des coûts réels.
- Indicateurs de succès.
- Volumétrie des photos par travail.
