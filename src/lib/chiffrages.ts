export type StatutChiffrage = "brouillon" | "soumis" | "valide" | "refuse";

export const STATUT_CHIFFRAGE_LABELS: Record<StatutChiffrage, string> = {
  brouillon: "Brouillon",
  soumis: "En attente de validation",
  valide: "Validé",
  refuse: "Refusé",
};

export const STATUT_CHIFFRAGE_STYLES: Record<StatutChiffrage, string> = {
  brouillon: "border-slate-200 bg-slate-100 text-slate-700",
  soumis: "border-amber-200 bg-amber-50 text-amber-700",
  valide: "border-green-200 bg-green-50 text-green-700",
  refuse: "border-red-200 bg-red-50 text-red-700",
};

// Un poste tel que stocké en base
export type LigneChiffrage = {
  id: string;
  position: number;
  libelle: string;
  montant: number;
  heures: number;
};

// Un poste tel qu'envoyé à l'enregistrement (sans id : les postes
// sont remplacés en bloc à chaque enregistrement)
export type LigneSaisie = {
  libelle: string;
  montant: number;
  heures: number;
};

export function formatEuros(valeur: number): string {
  return new Intl.NumberFormat("fr-FR", {
    style: "currency",
    currency: "EUR",
  }).format(valeur);
}

export function formatHeures(valeur: number): string {
  return `${new Intl.NumberFormat("fr-FR", {
    maximumFractionDigits: 1,
  }).format(valeur)} h`;
}

export function totauxLignes(lignes: { montant: number; heures: number }[]) {
  return lignes.reduce(
    (acc, l) => ({
      montant: acc.montant + (Number(l.montant) || 0),
      heures: acc.heures + (Number(l.heures) || 0),
    }),
    { montant: 0, heures: 0 }
  );
}
