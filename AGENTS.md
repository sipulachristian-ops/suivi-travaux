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
  ⚠️ Leçon du 2026-07-08 : **ne jamais modifier une migration déjà
  exécutée** (la 0002 avait été enrichie des 41 sites réels APRÈS son
  exécution → la production est restée avec les bâtiments d'exemple
  A/B/C jusqu'à la migration de rattrapage 0009). Toujours créer une
  nouvelle migration, et vérifier l'état réel de la base via l'API REST
  plutôt que de se fier aux fichiers.
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
4. ✅ **Chiffrage manuel** — saisie poste par poste, sans IA (validée par
   Christian le 2026-07-08 — « passons à l'étape 5 » ; migrations 0004 et
   0005 ; ses remarques d'ergonomie sont consignées plus bas, à traiter).
5. ✅ **Workflow de validation** — soumission, validation/refus motivé,
   versionnage (validée par Christian le 2026-07-08, migration 0006
   exécutée).
6. ✅ **Vue synthétique direction** — tableau de bord (validée par
   Christian le 2026-07-08 — « étape 7 »).
7. 🔶 **Notifications + import Excel** — notifications construites le
   2026-07-08 (cloche + e-mails, migration 0007 **à exécuter par
   Christian**, en test) ; import Excel en cours : fichier
   `CMT SUIVI P5.xlsx` analysé, décisions actées (voir plus bas),
   colonnes de suivi commercial ajoutées (migration 0008 **à exécuter**),
   **en attente du tri des sites par Christian**
   (`TRI_SITES_IMPORT.xlsx`) avant de générer la migration d'import.
8. 🔶 **Chiffrage IA** — API Claude (texte + photos) + recherche web.
   **Reportée en fin de feuille de route par Christian le 2026-07-08**
   (pas encore de clé API Anthropic). Découpée en trois sous-étapes :
   6a ✅ construite (proposition à partir du texte — le bouton affiche un
   message clair tant que ANTHROPIC_API_KEY n'existe pas), photos ⬜ et
   recherche web de prix ⬜ à faire.

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

- **Workflow de validation** (étape 5, construit le 2026-07-08, migration
  `0006_workflow_validation.sql`) : soumission depuis l'éditeur de chiffrage
  (bouton « Soumettre à la direction » : enregistre les postes puis fige le
  chiffrage, avec confirmation) via la fonction SQL `soumettre_chiffrage`
  (security definer : ≥ 1 poste requis, une seule soumission en attente par
  travail, travail → « En attente de validation » journalisé). Décision via
  `decider_chiffrage` (direction uniquement, refus motivé obligatoire,
  travail → Validé/Refusé journalisé) — bloc « Décision de la direction »
  sur la page du chiffrage (statut `soumis`). Traçabilité sur `chiffrages` :
  `soumis_le/par`, `decide_le/par`, `motif_refus` (affiché en rouge sur la
  version refusée). `creer_chiffrage` mise à jour : bloquée tant qu'une
  version est `soumis`, nouvelle version **pré-remplie avec les postes de la
  précédente**, travail `refuse` → « Chiffrage en cours » journalisé. Le
  sélecteur manuel de statut de la fiche reste inchangé (la direction peut
  toujours passer Validé/Refusé à la main — à restreindre plus tard si
  Christian le souhaite).

- **Chiffrage IA — 6a** (construite le 2026-07-08) : bouton « Proposer avec
  l'IA » dans l'éditeur de chiffrage (brouillon uniquement). Action serveur
  `proposerChiffrageIA` dans `actions-ia.ts` : SDK `@anthropic-ai/sdk`,
  modèle `claude-opus-4-8`, thinking adaptatif, **sorties structurées**
  (schéma JSON : postes {libellé, quantité, unité, prix_unitaire} +
  commentaire ≤ 500 car.). Garde-fous : mêmes bornes de validation que
  l'enregistrement, la proposition ne fait que pré-remplir l'éditeur
  (l'IA propose, l'humain dispose), confirmation avant d'écraser des
  postes déjà saisis, commentaire affiché avec la mention « prix
  indicatifs ». Clé dans `ANTHROPIC_API_KEY` (.env.local + Vercel — jamais
  dans le code) ; `maxDuration = 120` sur la page chiffrage (l'appel peut
  durer plus d'une minute). Messages d'erreur en clair (clé absente ou
  invalide, saturation, réseau).

- **Tableau de bord** (étape 6, construite le 2026-07-08) : page
  `/tableau-de-bord`, **accessible à tous les rôles** (tranché par
  Christian le 2026-07-08 — pas de cloisonnement), lien dans l'en-tête
  (sur mobile, le texte du logo s'efface au profit des liens de
  navigation). Contenu (PRD §5.4) : 4 chiffres clés (chiffrages à valider
  + montant, budget engagé, retards, priorités haute/urgente), barre et
  grille de répartition par statut (cliquable → liste filtrée
  `?statut=`), liste des chiffrages soumis (lien direct vers la page de
  décision), liste des travaux en retard ou prioritaires (8 max).
  **Budget engagé** = somme de la dernière version validée de chaque
  travail (les anciennes versions validées ne comptent pas deux fois).
  Aucune migration : uniquement des lectures.

- **Notifications** (étape 7, construites le 2026-07-08, migration
  `0007_notifications.sql`) : Christian a choisi **dans l'app + e-mail**.
  Table `notifications` (RLS : chacun ne lit que les siennes ; écrites
  uniquement par les fonctions SQL), `soumettre_chiffrage` notifie
  chaque membre de la direction, `decider_chiffrage` notifie la personne
  qui a soumis (motif inclus en cas de refus). Marquage lu via la
  fonction `marquer_notifications_lues` (toutes ou une liste). La
  migration ajoute aussi **`email` dans `profiles`** (copié depuis le
  compte de connexion, trigger mis à jour) — servira aussi à la future
  liste des utilisateurs. UI : **cloche dans l'en-tête**
  (`notifications-cloche.tsx`, données via `lib/notifications-server.ts`)
  avec compteur, marquage lu au clic, et section « Échéances à
  surveiller » **calculée en direct** (échéance dépassée ou sous 7
  jours, rôles gestion travaux : direction, responsable travaux, admin
  — pas de stockage, pas de cron). Tolérant si la migration 0007
  manque. **E-mails via Resend** (appel HTTP direct, pas de dépendance,
  `lib/email.ts`) : envoyés après soumission (à la direction) et après
  décision (au soumetteur), jamais bloquants ; actifs dès que
  `RESEND_API_KEY` existe (.env.local + Vercel), expéditeur
  `EMAIL_FROM` (défaut : adresse de test onboarding@resend.dev, qui ne
  peut écrire qu'à l'adresse du compte Resend — domaine
  jp-facilities.com à vérifier chez Resend pour un usage réel),
  base des liens `NEXT_PUBLIC_SITE_URL` (défaut : l'URL Vercel).

- **Import Excel** (étape 7, décisions actées par Christian le
  2026-07-08) : source = `CMT SUIVI P5.xlsx` (même dossier SharePoint
  que les documents de référence) — 107 lignes, 1 ligne = 1 devis
  (n° DE0000xxxx, site, prestation, montant HT ; colonnes éparses :
  OS, sous-traitance, rapport, CAT, facturation ; « Intervenants JPF »
  vide, dates inexploitables). Décisions :
  1. **Montant HT → chiffrage validé** à 1 poste forfait par demande
     importée (alimente le budget engagé du tableau de bord).
  2. **Statuts — règle automatique** : « Réalisé » → Terminé,
     « En cours de programmation » → Planifié, sinon → Validé.
  3. **Colonnes dédiées** (choix de Christian, PAS la description) :
     migration `0008_suivi_commercial.sql` ajoute sur `travaux` :
     `reference_devis`, `numero_os`, `montant_os`, `sous_traitance`
     (bool, null = non renseigné), `nom_sous_traitant`,
     `commande_sous_traitance`, `commande_materiel`,
     `rapport_intervention`, `cat`, `facturation`. Affichées sur la
     fiche dans une carte « Suivi commercial » (visible seulement si
     renseignées ; requête séparée, tolérante si la 0008 manque).
     Pas encore modifiables dans le formulaire — à voir avec Christian.
     Depuis le retour de Christian post-import (2026-07-08) : le
     **tableau de la liste** affiche aussi le suivi commercial
     (N° devis, OS + montant, sous-traitance, rapport, CAT,
     facturation), page élargie à `max-w-[100rem]`, cellules
     `whitespace-nowrap` + défilement horizontal du composant Table.
     Après essais : **seule la ligne d'en-tête est figée** (sticky) —
     Christian a testé les colonnes N°/Intitulé figées façon Excel et
     les a refusées (« fige uniquement la ligne supérieure »). Le
     tableau a sa propre hauteur (`max-h-[calc(100dvh-14rem)]`).
     ⚠️ Le select de `/travaux` inclut désormais ces colonnes : la
     page liste REQUIERT la migration 0008.
  4. **Sites : Christian trie lui-même** — la colonne « Site » du
     fichier est plutôt le client (49 valeurs, 0 correspondance exacte
     avec les 41 bâtiments, 35 inconnues, 2 lignes internes
     consommables/outillage à écarter). Fichier de tri généré :
     `TRI_SITES_IMPORT.xlsx` (même dossier SharePoint) — 1 ligne par
     site, listes déroulantes Créer / Rapprocher / Écarter +
     rapprochements pré-remplis. Tri rendu le 2026-07-08, arbitrages :
     un bâtiment indiqué vaut rapprochement même si la liste déroulante
     dit « Créer » (8 lignes concernées, dont les 4 LNA SANTE) ;
     Théâtre de la Pépinière et Ville de Puteaux → nouveaux bâtiments.
     Migration `0010_import_devis.sql` **générée** (script Python à
     partir de CMT SUIVI P5.xlsx + le tri) : 36 nouveaux bâtiments,
     105 demandes (2 lignes internes écartées), 104 chiffrages validés
     à 1 poste forfait (3 589 768,96 € HT ; 1 devis sans montant),
     import porté par le compte direction, garde-fou anti-double-import
     (refuse si un `reference_devis` existe déjà). **À exécuter par
     Christian après la 0009.** NB : le devis DE00001369 « ANNULE —
     NOUVEAU DEVIS 1446 » est importé tel quel (statut Validé) — à
     clôturer dans l'app si besoin.
  5. **Rattrapage sites** : la production n'avait jamais reçu les 41
     sites réels (voir la leçon plus haut) — migration
     `0009_rattrapage_sites_reels.sql` (insertion sans doublon +
     désactivation des bâtiments d'exemple A/B/C), **à exécuter avant
     l'import**.

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

Sur la navigation générale (remarque du 2026-07-08 également) :

- Une **navigation latérale** (sur le côté), séparée du tableau/contenu
  principal, avec au moins : lien **Tableau de bord** et **Liste des
  utilisateurs** (une table des utilisateurs).

## Points non tranchés (demander à Christian le moment venu)

- Structure précise de l'import Excel initial des travaux.
- Niveau de détail du stockage des coûts réels.
- Indicateurs de succès.
- Volumétrie des photos par travail.
