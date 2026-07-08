"use client";

import { useState, useTransition } from "react";
import { Button } from "@/components/ui/button";
import { creerChiffrage } from "./actions";

// Bouton de la fiche travail : crée le brouillon (première version ou
// nouvelle version pré-remplie) puis redirige vers la saisie des postes.
export function CreerChiffrageBouton({
  travailId,
  libelle = "Créer un chiffrage",
}: {
  travailId: string;
  libelle?: string;
}) {
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
        {enCours ? "Création…" : libelle}
      </Button>
      {erreur && <p className="text-sm text-red-600">{erreur}</p>}
    </div>
  );
}
