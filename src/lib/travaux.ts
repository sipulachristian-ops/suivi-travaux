export type StatutTravail =
  | "a_chiffrer"
  | "chiffrage_en_cours"
  | "en_attente_validation"
  | "valide"
  | "refuse"
  | "planifie"
  | "en_cours"
  | "termine";

export type PrioriteTravail = "basse" | "normale" | "haute" | "urgente";

// Ordre métier des statuts : c'est aussi l'ordre des colonnes du Kanban.
export const STATUTS_ORDONNES: StatutTravail[] = [
  "a_chiffrer",
  "chiffrage_en_cours",
  "en_attente_validation",
  "valide",
  "refuse",
  "planifie",
  "en_cours",
  "termine",
];

// Statuts réservés à la direction (règle métier : seule la direction
// valide ou refuse un chiffrage).
export const STATUTS_RESERVES_DIRECTION: StatutTravail[] = [
  "valide",
  "refuse",
];

export const STATUT_LABELS: Record<StatutTravail, string> = {
  a_chiffrer: "À chiffrer",
  chiffrage_en_cours: "Chiffrage en cours",
  en_attente_validation: "En attente de validation",
  valide: "Validé",
  refuse: "Refusé",
  planifie: "Planifié",
  en_cours: "En cours",
  termine: "Terminé",
};

// Couleurs des badges de statut (fond clair + texte foncé, lisible)
export const STATUT_STYLES: Record<StatutTravail, string> = {
  a_chiffrer: "border-slate-200 bg-slate-100 text-slate-700",
  chiffrage_en_cours: "border-sky-200 bg-sky-50 text-sky-700",
  en_attente_validation: "border-amber-200 bg-amber-50 text-amber-700",
  valide: "border-green-200 bg-green-50 text-green-700",
  refuse: "border-red-200 bg-red-50 text-red-700",
  planifie: "border-indigo-200 bg-indigo-50 text-indigo-700",
  en_cours: "border-blue-200 bg-blue-50 text-blue-700",
  termine: "border-emerald-200 bg-emerald-50 text-emerald-700",
};

export const PRIORITE_LABELS: Record<PrioriteTravail, string> = {
  basse: "Basse",
  normale: "Normale",
  haute: "Haute",
  urgente: "Urgente",
};

export const PRIORITE_STYLES: Record<PrioriteTravail, string> = {
  basse: "border-slate-200 bg-slate-50 text-slate-600",
  normale: "border-slate-200 bg-white text-slate-700",
  haute: "border-orange-200 bg-orange-50 text-orange-700",
  urgente: "border-red-200 bg-red-50 text-red-700",
};

// Couleur d'accent de chaque colonne du Kanban (bordure haute)
export const STATUT_ACCENTS: Record<StatutTravail, string> = {
  a_chiffrer: "border-t-slate-400",
  chiffrage_en_cours: "border-t-sky-400",
  en_attente_validation: "border-t-amber-400",
  valide: "border-t-green-500",
  refuse: "border-t-red-400",
  planifie: "border-t-indigo-400",
  en_cours: "border-t-blue-500",
  termine: "border-t-emerald-500",
};

// Un travail est en retard si son échéance est passée et qu'il n'est pas clos
export function estEnRetard(
  echeance: string | null,
  statut: StatutTravail
): boolean {
  if (!echeance || statut === "termine" || statut === "refuse") return false;
  return new Date(echeance) < new Date(new Date().toDateString());
}

export function formatDateFr(value: string | null): string {
  if (!value) return "—";
  return new Intl.DateTimeFormat("fr-FR", { dateStyle: "medium" }).format(
    new Date(value)
  );
}

// Un travail tel que renvoyé par la requête liste (avec jointures)
export type TravailListe = {
  id: string;
  numero: number;
  titre: string;
  nature: string;
  priorite: PrioriteTravail;
  statut: StatutTravail;
  echeance: string | null;
  batiment: { nom: string } | null;
  responsable: { full_name: string } | null;
  // Suivi commercial (migration 0008, rempli par l'import Excel)
  reference_devis: string;
  numero_os: string;
  montant_os: number | null;
  sous_traitance: boolean | null;
  nom_sous_traitant: string;
  rapport_intervention: string;
  cat: string;
  facturation: string;
};
