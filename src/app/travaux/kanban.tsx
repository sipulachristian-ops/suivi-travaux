"use client";

import Link from "next/link";
import { useEffect, useOptimistic, useRef, useState, useTransition } from "react";
import { Badge } from "@/components/ui/badge";
import { cn } from "@/lib/utils";
import {
  STATUTS_ORDONNES,
  STATUTS_RESERVES_DIRECTION,
  STATUT_ACCENTS,
  STATUT_LABELS,
  STATUT_STYLES,
  PRIORITE_LABELS,
  PRIORITE_STYLES,
  formatDateFr,
  estEnRetard,
  type StatutTravail,
  type TravailListe,
} from "@/lib/travaux";
import { changerStatutTravail } from "./actions";

export function KanbanTravaux({
  travaux,
  peutDeplacer,
  estDirection,
}: {
  travaux: TravailListe[];
  peutDeplacer: boolean;
  estDirection: boolean;
}) {
  // Déplacement optimiste : la carte change de colonne tout de suite ;
  // si le serveur refuse, React revient automatiquement aux données réelles.
  const [items, deplacerCarte] = useOptimistic(
    travaux,
    (courant, { id, statut }: { id: string; statut: StatutTravail }) =>
      courant.map((t) => (t.id === id ? { ...t, statut } : t))
  );
  const [colonneSurvolee, setColonneSurvolee] = useState<StatutTravail | null>(
    null
  );
  const [message, setMessage] = useState<string | null>(null);
  const [, startTransition] = useTransition();
  const timerMessage = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => {
    return () => {
      if (timerMessage.current) clearTimeout(timerMessage.current);
    };
  }, []);

  function afficherMessage(texte: string) {
    setMessage(texte);
    if (timerMessage.current) clearTimeout(timerMessage.current);
    timerMessage.current = setTimeout(() => setMessage(null), 5000);
  }

  function deposer(travailId: string, nouveauStatut: StatutTravail) {
    const travail = items.find((t) => t.id === travailId);
    if (!travail || travail.statut === nouveauStatut) return;

    if (
      STATUTS_RESERVES_DIRECTION.includes(nouveauStatut) &&
      !estDirection
    ) {
      afficherMessage(
        `Seule la direction peut passer un travail en « ${STATUT_LABELS[nouveauStatut]} ».`
      );
      return;
    }

    startTransition(async () => {
      deplacerCarte({ id: travailId, statut: nouveauStatut });
      const resultat = await changerStatutTravail(travailId, nouveauStatut);
      if (resultat.error) {
        afficherMessage(resultat.error);
      }
    });
  }

  return (
    <div className="flex flex-col gap-3">
      {message && (
        <div
          role="alert"
          className="rounded-md border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-700"
        >
          {message}
        </div>
      )}
      {peutDeplacer && (
        <p className="hidden text-xs text-muted-foreground md:block">
          Glissez une carte vers une autre colonne pour changer son statut.
          Sur mobile, le statut se change depuis la fiche du travail.
        </p>
      )}

      <div className="-mx-4 overflow-x-auto px-4 pb-2 sm:-mx-6 sm:px-6">
        <div className="flex gap-3">
          {STATUTS_ORDONNES.map((statut) => {
            const cartes = items.filter((t) => t.statut === statut);
            return (
              <div
                key={statut}
                className={cn(
                  "flex w-64 shrink-0 flex-col rounded-xl border border-t-[3px] bg-muted/50 shadow-xs",
                  STATUT_ACCENTS[statut],
                  colonneSurvolee === statut && "border-ring bg-accent/70"
                )}
                onDragOver={(e) => {
                  if (!peutDeplacer) return;
                  e.preventDefault();
                  setColonneSurvolee(statut);
                }}
                onDragLeave={() => setColonneSurvolee(null)}
                onDrop={(e) => {
                  if (!peutDeplacer) return;
                  e.preventDefault();
                  setColonneSurvolee(null);
                  const id = e.dataTransfer.getData("text/plain");
                  if (id) deposer(id, statut);
                }}
              >
                <div className="flex items-center justify-between gap-2 px-3 py-2">
                  <Badge variant="outline" className={STATUT_STYLES[statut]}>
                    {STATUT_LABELS[statut]}
                  </Badge>
                  <span className="rounded-full bg-background px-2 py-0.5 text-xs font-medium text-muted-foreground shadow-xs">
                    {cartes.length}
                  </span>
                </div>

                <div className="flex min-h-24 flex-col gap-2 px-2 pb-2">
                  {cartes.map((t) => (
                    <div
                      key={t.id}
                      draggable={peutDeplacer}
                      onDragStart={(e) => {
                        e.dataTransfer.setData("text/plain", t.id);
                        e.dataTransfer.effectAllowed = "move";
                      }}
                      className={cn(
                        "rounded-lg border bg-card p-3 shadow-xs transition-shadow hover:shadow-md",
                        peutDeplacer && "cursor-grab active:cursor-grabbing"
                      )}
                    >
                      <div className="flex items-start justify-between gap-2">
                        <Link
                          href={`/travaux/${t.id}`}
                          className="text-sm font-medium hover:text-primary hover:underline"
                          draggable={false}
                        >
                          {t.titre}
                        </Link>
                        <span className="shrink-0 font-mono text-xs font-medium text-primary">
                          T-{t.numero}
                        </span>
                      </div>
                      <p
                        className={cn(
                          "mt-1 text-xs text-muted-foreground",
                          estEnRetard(t.echeance, t.statut) &&
                            "font-medium text-red-600"
                        )}
                      >
                        {t.batiment?.nom ?? "—"}
                        {t.echeance
                          ? ` · échéance ${formatDateFr(t.echeance)}${
                              estEnRetard(t.echeance, t.statut)
                                ? " (en retard)"
                                : ""
                            }`
                          : ""}
                      </p>
                      <div className="mt-2 flex flex-wrap items-center gap-1.5">
                        <Badge
                          variant="outline"
                          className={cn("text-xs", PRIORITE_STYLES[t.priorite])}
                        >
                          {PRIORITE_LABELS[t.priorite]}
                        </Badge>
                        {t.responsable?.full_name && (
                          <span className="text-xs text-muted-foreground">
                            {t.responsable.full_name}
                          </span>
                        )}
                      </div>
                    </div>
                  ))}
                  {cartes.length === 0 && (
                    <p className="px-1 py-2 text-center text-xs text-muted-foreground">
                      Aucun travail
                    </p>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}
