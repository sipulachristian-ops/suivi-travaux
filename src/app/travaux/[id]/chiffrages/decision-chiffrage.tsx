"use client";

import { useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import { deciderChiffrage } from "./actions";

// Bloc « Décision de la direction » affiché sur un chiffrage soumis :
// valider (avec confirmation) ou refuser (motif obligatoire).
export function DecisionChiffrage({
  chiffrageId,
  travailId,
}: {
  chiffrageId: string;
  travailId: string;
}) {
  const [mode, setMode] = useState<"aucun" | "validation" | "refus">("aucun");
  const [motif, setMotif] = useState("");
  const [erreur, setErreur] = useState<string | null>(null);
  const [enCours, startTransition] = useTransition();
  const router = useRouter();

  function decider(decision: "valide" | "refuse") {
    setErreur(null);
    if (decision === "refuse" && !motif.trim()) {
      setErreur("Indiquez le motif du refus.");
      return;
    }
    startTransition(async () => {
      const resultat = await deciderChiffrage(
        chiffrageId,
        travailId,
        decision,
        motif
      );
      if (resultat.error) {
        setErreur(resultat.error);
        return;
      }
      router.refresh();
    });
  }

  return (
    <div className="flex flex-col gap-3 rounded-xl border border-amber-200 bg-amber-50/60 p-5 shadow-sm">
      <div>
        <h2 className="text-base font-semibold">Décision de la direction</h2>
        <p className="text-sm text-muted-foreground">
          Ce chiffrage est en attente de votre décision. Un chiffrage validé
          ne sera plus jamais modifié ; un refus doit être motivé et permettra
          une nouvelle version.
        </p>
      </div>

      {mode === "aucun" && (
        <div className="flex flex-wrap items-center gap-3">
          <Button type="button" onClick={() => setMode("validation")}>
            Valider le chiffrage
          </Button>
          <Button
            type="button"
            variant="outline"
            className="border-red-200 text-red-700 hover:bg-red-50 hover:text-red-700"
            onClick={() => setMode("refus")}
          >
            Refuser…
          </Button>
        </div>
      )}

      {mode === "validation" && (
        <div className="flex flex-col gap-3 rounded-md border border-green-200 bg-green-50 px-4 py-3">
          <p className="text-sm text-green-900">
            Le chiffrage sera validé définitivement et le travail passera au
            statut « Validé ».
          </p>
          <div className="flex flex-wrap items-center gap-3">
            <Button
              type="button"
              size="sm"
              disabled={enCours}
              onClick={() => decider("valide")}
            >
              {enCours ? "Validation…" : "Confirmer la validation"}
            </Button>
            <Button
              type="button"
              size="sm"
              variant="ghost"
              disabled={enCours}
              onClick={() => setMode("aucun")}
            >
              Annuler
            </Button>
          </div>
        </div>
      )}

      {mode === "refus" && (
        <div className="flex flex-col gap-3 rounded-md border border-red-200 bg-red-50 px-4 py-3">
          <label className="text-sm font-medium text-red-900" htmlFor="motif-refus">
            Motif du refus (obligatoire)
          </label>
          <Textarea
            id="motif-refus"
            placeholder="Ex. : prix de la main d'œuvre à revoir, poste manquant…"
            value={motif}
            onChange={(e) => setMotif(e.target.value)}
            rows={3}
            className="bg-white"
          />
          <div className="flex flex-wrap items-center gap-3">
            <Button
              type="button"
              size="sm"
              variant="destructive"
              disabled={enCours}
              onClick={() => decider("refuse")}
            >
              {enCours ? "Refus…" : "Confirmer le refus"}
            </Button>
            <Button
              type="button"
              size="sm"
              variant="ghost"
              disabled={enCours}
              onClick={() => {
                setMode("aucun");
                setErreur(null);
              }}
            >
              Annuler
            </Button>
          </div>
        </div>
      )}

      {erreur && (
        <p className="rounded-md border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-700">
          {erreur}
        </p>
      )}
    </div>
  );
}
