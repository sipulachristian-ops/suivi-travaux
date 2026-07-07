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
};
