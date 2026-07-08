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

// Unités possibles pour un poste. « h » a un rôle particulier : les
// heures du chiffrage sont la somme des quantités des lignes en « h ».
export const UNITES = ["u", "h", "forfait", "m2", "ml"] as const;
export type Unite = (typeof UNITES)[number];

export const UNITE_LABELS: Record<Unite, string> = {
  u: "u",
  h: "h",
  forfait: "forfait",
  m2: "m²",
  ml: "ml",
};

// Un poste tel que stocké en base (montant et heures calculés en SQL :
// montant = quantité × prix unitaire ; heures = quantité si unité « h »)
export type LigneChiffrage = {
  id: string;
  position: number;
  libelle: string;
  quantite: number;
  unite: string;
  prix_unitaire: number;
  montant: number;
  heures: number;
};

// Un poste tel qu'envoyé à l'enregistrement (les postes sont remplacés
// en bloc à chaque enregistrement ; montant et heures calculés en SQL)
export type LigneSaisie = {
  libelle: string;
  quantite: number;
  unite: Unite;
  prix_unitaire: number;
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

export function formatQuantite(valeur: number, unite: string): string {
  const nombre = new Intl.NumberFormat("fr-FR", {
    maximumFractionDigits: 3,
  }).format(valeur);
  return `${nombre} ${UNITE_LABELS[unite as Unite] ?? unite}`;
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
