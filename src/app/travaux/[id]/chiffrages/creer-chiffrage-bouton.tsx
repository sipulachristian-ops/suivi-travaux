"use client";

import { useState, useTransition } from "react";
import { Button } from "@/components/ui/button";
import { creerChiffrage } from "./actions";

// Bouton « Créer un chiffrage » de la fiche travail : crée le brouillon
// puis redirige vers la page de saisie des postes.
export function CreerChiffrageBouton({ travailId }: { travailId: string }) {
  const [erreur, setErreur] = useState<string | null>(null);
  const [enCours, startTransition] = useTransition();

  return (
    <div className="flex flex-col items-end gap-1">
      <Button
        size="sm"
        disabled={enCours}
        onClick={() =>
          startTransition(async () => {
            setErreur(null);
            const resultat = await creerChiffrage(travailId);
            if (resultat?.error) setErreur(resultat.error);
          })
        }
      >
        {enCours ? "Création…" : "Créer un chiffrage"}
      </Button>
      {erreur && <p className="text-sm text-red-600">{erreur}</p>}
    </div>
  );
}
