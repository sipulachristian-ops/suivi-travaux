"use client";

import { useMemo, useState, useTransition } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  formatEuros,
  formatHeures,
  type LigneChiffrage,
  type LigneSaisie,
} from "@/lib/chiffrages";
import { enregistrerLignes } from "./actions";

// Une ligne en cours de saisie : montant et heures restent du texte
// (virgule française acceptée), la conversion se fait à l'enregistrement.
type LigneEdition = {
  cle: number;
  libelle: string;
  montant: string;
  heures: string;
};

function versTexte(valeur: number): string {
  return valeur === 0 ? "" : String(valeur).replace(".", ",");
}

// "1 250,50" → 1250.5 ; champ vide → 0 ; texte invalide → null
function versNombre(texte: string): number | null {
  const propre = texte.trim().replace(/\s/g, "").replace(",", ".");
  if (propre === "") return 0;
  const nombre = Number(propre);
  return Number.isFinite(nombre) && nombre >= 0 ? nombre : null;
}

const inputNombreClass = "text-right tabular-nums";

export function ChiffrageEditeur({
  chiffrageId,
  travailId,
  lignesInitiales,
}: {
  chiffrageId: string;
  travailId: string;
  lignesInitiales: LigneChiffrage[];
}) {
  const [prochaineCle, setProchaineCle] = useState(lignesInitiales.length + 1);
  const [lignes, setLignes] = useState<LigneEdition[]>(() =>
    lignesInitiales.length > 0
      ? lignesInitiales.map((l, index) => ({
          cle: index,
          libelle: l.libelle,
          montant: versTexte(l.montant),
          heures: versTexte(l.heures),
        }))
      : [{ cle: 0, libelle: "", montant: "", heures: "" }]
  );
  const [erreur, setErreur] = useState<string | null>(null);
  const [enregistre, setEnregistre] = useState(false);
  const [enCours, startTransition] = useTransition();

  function modifier(cle: number, champ: keyof LigneEdition, valeur: string) {
    setEnregistre(false);
    setLignes((courantes) =>
      courantes.map((l) => (l.cle === cle ? { ...l, [champ]: valeur } : l))
    );
  }

  function ajouterLigne() {
    setEnregistre(false);
    setLignes((courantes) => [
      ...courantes,
      { cle: prochaineCle, libelle: "", montant: "", heures: "" },
    ]);
    setProchaineCle((n) => n + 1);
  }

  function supprimerLigne(cle: number) {
    setEnregistre(false);
    setLignes((courantes) => courantes.filter((l) => l.cle !== cle));
  }

  // Totaux affichés en direct pendant la saisie (lignes lisibles seulement)
  const totaux = useMemo(() => {
    return lignes.reduce(
      (acc, l) => ({
        montant: acc.montant + (versNombre(l.montant) ?? 0),
        heures: acc.heures + (versNombre(l.heures) ?? 0),
      }),
      { montant: 0, heures: 0 }
    );
  }, [lignes]);

  function enregistrer() {
    setErreur(null);

    const postes: LigneSaisie[] = [];
    for (const [index, ligne] of lignes.entries()) {
      const libelle = ligne.libelle.trim();
      const montant = versNombre(ligne.montant);
      const heures = versNombre(ligne.heures);
      const vide = !libelle && !ligne.montant.trim() && !ligne.heures.trim();
      if (vide) continue; // ligne laissée vide : on l'ignore

      if (!libelle) {
        setErreur(`Le poste n° ${index + 1} n'a pas de libellé.`);
        return;
      }
      if (montant === null) {
        setErreur(`Montant invalide pour « ${libelle} ».`);
        return;
      }
      if (heures === null) {
        setErreur(`Nombre d'heures invalide pour « ${libelle} ».`);
        return;
      }
      postes.push({ libelle, montant, heures });
    }

    startTransition(async () => {
      const resultat = await enregistrerLignes(chiffrageId, travailId, postes);
      if (resultat.error) {
        setErreur(resultat.error);
      } else {
        setEnregistre(true);
      }
    });
  }

  return (
    <div className="flex flex-col gap-4 rounded-xl border bg-card p-5 shadow-sm">
      {/* En-têtes de colonnes */}
      <div className="grid grid-cols-[minmax(0,1fr)_5.5rem_4rem_2rem] items-center gap-2 text-xs font-medium text-muted-foreground">
        <span>Poste</span>
        <span className="text-right">Montant €</span>
        <span className="text-right">Heures</span>
        <span />
      </div>

      <div className="flex flex-col gap-2">
        {lignes.map((ligne, index) => (
          <div
            key={ligne.cle}
            className="grid grid-cols-[minmax(0,1fr)_5.5rem_4rem_2rem] items-center gap-2"
          >
            <Input
              aria-label={`Libellé du poste ${index + 1}`}
              placeholder="Ex. : Fourniture chaudière"
              value={ligne.libelle}
              onChange={(e) => modifier(ligne.cle, "libelle", e.target.value)}
            />
            <Input
              aria-label={`Montant du poste ${index + 1} en euros`}
              inputMode="decimal"
              placeholder="0,00"
              className={inputNombreClass}
              value={ligne.montant}
              onChange={(e) => modifier(ligne.cle, "montant", e.target.value)}
            />
            <Input
              aria-label={`Heures du poste ${index + 1}`}
              inputMode="decimal"
              placeholder="0"
              className={inputNombreClass}
              value={ligne.heures}
              onChange={(e) => modifier(ligne.cle, "heures", e.target.value)}
            />
            <button
              type="button"
              aria-label={`Supprimer le poste ${index + 1}`}
              className="flex h-8 w-8 items-center justify-center rounded-md text-muted-foreground hover:bg-red-50 hover:text-red-600"
              onClick={() => supprimerLigne(ligne.cle)}
            >
              ✕
            </button>
          </div>
        ))}
      </div>

      <div>
        <Button type="button" variant="outline" size="sm" onClick={ajouterLigne}>
          + Ajouter un poste
        </Button>
      </div>

      <div className="flex flex-wrap items-center justify-between gap-3 border-t pt-4">
        <p className="text-sm font-medium">
          Total :{" "}
          <span className="tabular-nums">{formatEuros(totaux.montant)}</span>
          {" · "}
          <span className="tabular-nums">{formatHeures(totaux.heures)}</span>
        </p>
        <div className="flex items-center gap-3">
          {enregistre && !enCours && (
            <span className="text-sm text-green-700">Enregistré ✓</span>
          )}
          <Button type="button" disabled={enCours} onClick={enregistrer}>
            {enCours ? "Enregistrement…" : "Enregistrer le chiffrage"}
          </Button>
        </div>
      </div>

      {erreur && (
        <p className="rounded-md border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-700">
          {erreur}
        </p>
      )}
    </div>
  );
}
