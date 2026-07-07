"use client";

import { useOptimistic, useState, useTransition } from "react";
import {
  STATUTS_ORDONNES,
  STATUTS_RESERVES_DIRECTION,
  STATUT_LABELS,
  type StatutTravail,
} from "@/lib/travaux";
import { changerStatutTravail } from "./actions";

// Changement de statut depuis la fiche — utile notamment sur mobile,
// où le glisser-déposer du Kanban n'existe pas.
export function ChangerStatut({
  travailId,
  statut,
  estDirection,
}: {
  travailId: string;
  statut: StatutTravail;
  estDirection: boolean;
}) {
  const [erreur, setErreur] = useState<string | null>(null);
  const [enCours, startTransition] = useTransition();
  // Valeur affichée tout de suite ; si le serveur refuse, React revient
  // automatiquement au statut réel.
  const [valeur, choisirValeur] = useOptimistic(
    statut,
    (_courant, nouveau: StatutTravail) => nouveau
  );

  function changer(nouveauStatut: StatutTravail) {
    if (nouveauStatut === valeur) return;
    setErreur(null);
    startTransition(async () => {
      choisirValeur(nouveauStatut);
      const resultat = await changerStatutTravail(travailId, nouveauStatut);
      if (resultat.error) setErreur(resultat.error);
    });
  }

  return (
    <div className="flex flex-col gap-1">
      <div className="flex items-center gap-2">
        <label
          htmlFor="changer-statut"
          className="text-sm text-muted-foreground"
        >
          Statut :
        </label>
        <select
          id="changer-statut"
          className="h-9 rounded-md border border-input bg-transparent px-3 text-sm shadow-xs outline-none focus-visible:border-ring focus-visible:ring-ring/50 focus-visible:ring-[3px]"
          value={valeur}
          disabled={enCours}
          onChange={(e) => changer(e.target.value as StatutTravail)}
        >
          {STATUTS_ORDONNES.map((s) => (
            <option
              key={s}
              value={s}
              disabled={STATUTS_RESERVES_DIRECTION.includes(s) && !estDirection}
            >
              {STATUT_LABELS[s]}
              {STATUTS_RESERVES_DIRECTION.includes(s) && !estDirection
                ? " (direction)"
                : ""}
            </option>
          ))}
        </select>
        {enCours && (
          <span className="text-xs text-muted-foreground">
            Enregistrement…
          </span>
        )}
      </div>
      {erreur && <p className="text-sm text-red-600">{erreur}</p>}
    </div>
  );
}
