"use client";

import { useRouter, useSearchParams } from "next/navigation";
import { useEffect, useState } from "react";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { STATUT_LABELS, PRIORITE_LABELS } from "@/lib/travaux";

const selectClass =
  "h-9 rounded-md border border-input bg-transparent px-3 text-sm shadow-xs outline-none focus-visible:border-ring focus-visible:ring-ring/50 focus-visible:ring-[3px]";

export function FiltresTravaux({
  batiments,
  responsables,
}: {
  batiments: { id: string; nom: string }[];
  responsables: { id: string; full_name: string }[];
}) {
  const router = useRouter();
  const searchParams = useSearchParams();
  const [recherche, setRecherche] = useState(searchParams.get("q") ?? "");

  function setParam(cle: string, valeur: string) {
    const params = new URLSearchParams(searchParams.toString());
    if (valeur) {
      params.set(cle, valeur);
    } else {
      params.delete(cle);
    }
    router.replace(`/travaux?${params.toString()}`);
  }

  // Recherche : on attend une demi-seconde après la dernière frappe
  useEffect(() => {
    const actuel = searchParams.get("q") ?? "";
    if (recherche === actuel) return;
    const timer = setTimeout(() => setParam("q", recherche), 500);
    return () => clearTimeout(timer);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [recherche]);

  const filtresActifs =
    searchParams.get("q") ||
    searchParams.get("statut") ||
    searchParams.get("batiment") ||
    searchParams.get("priorite") ||
    searchParams.get("responsable");

  return (
    <div className="flex flex-wrap items-center gap-2 rounded-xl border bg-card p-2.5 shadow-xs">
      <Input
        placeholder="Rechercher un travail…"
        value={recherche}
        onChange={(e) => setRecherche(e.target.value)}
        className="w-full sm:w-56"
      />
      <select
        className={selectClass}
        value={searchParams.get("statut") ?? ""}
        onChange={(e) => setParam("statut", e.target.value)}
        aria-label="Filtrer par statut"
      >
        <option value="">Tous les statuts</option>
        {Object.entries(STATUT_LABELS).map(([valeur, label]) => (
          <option key={valeur} value={valeur}>
            {label}
          </option>
        ))}
      </select>
      <select
        className={selectClass}
        value={searchParams.get("batiment") ?? ""}
        onChange={(e) => setParam("batiment", e.target.value)}
        aria-label="Filtrer par bâtiment"
      >
        <option value="">Tous les bâtiments</option>
        {batiments.map((b) => (
          <option key={b.id} value={b.id}>
            {b.nom}
          </option>
        ))}
      </select>
      <select
        className={selectClass}
        value={searchParams.get("priorite") ?? ""}
        onChange={(e) => setParam("priorite", e.target.value)}
        aria-label="Filtrer par priorité"
      >
        <option value="">Toutes les priorités</option>
        {Object.entries(PRIORITE_LABELS).map(([valeur, label]) => (
          <option key={valeur} value={valeur}>
            {label}
          </option>
        ))}
      </select>
      <select
        className={selectClass}
        value={searchParams.get("responsable") ?? ""}
        onChange={(e) => setParam("responsable", e.target.value)}
        aria-label="Filtrer par responsable"
      >
        <option value="">Tous les responsables</option>
        {responsables.map((r) => (
          <option key={r.id} value={r.id}>
            {r.full_name || "(sans nom)"}
          </option>
        ))}
      </select>
      {filtresActifs && (
        <Button
          variant="ghost"
          size="sm"
          onClick={() => {
            setRecherche("");
            // On efface les filtres mais on garde la vue (liste/Kanban)
            const vue = searchParams.get("vue");
            router.replace(vue ? `/travaux?vue=${vue}` : "/travaux");
          }}
        >
          Effacer les filtres
        </Button>
      )}
    </div>
  );
}
