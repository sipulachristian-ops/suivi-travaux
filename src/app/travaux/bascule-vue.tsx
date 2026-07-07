"use client";

import { useRouter, useSearchParams } from "next/navigation";
import { cn } from "@/lib/utils";

// Bascule Liste / Kanban. Le choix vit dans l'URL (?vue=kanban) pour que
// les filtres soient conservés, et dans un cookie pour être retrouvé
// quand on revient sur la page sans paramètre.
export function BasculeVue({ vue }: { vue: "liste" | "kanban" }) {
  const router = useRouter();
  const searchParams = useSearchParams();

  function choisirVue(nouvelle: "liste" | "kanban") {
    if (nouvelle === vue) return;
    document.cookie = `vue_travaux=${nouvelle}; path=/; max-age=31536000; samesite=lax`;
    const params = new URLSearchParams(searchParams.toString());
    params.set("vue", nouvelle);
    router.replace(`/travaux?${params.toString()}`);
  }

  const boutonClass = (actif: boolean) =>
    cn(
      "rounded-[5px] px-3 py-1 text-sm transition-colors",
      actif
        ? "bg-background font-medium shadow-xs"
        : "text-muted-foreground hover:text-foreground"
    );

  return (
    <div
      className="inline-flex items-center gap-0.5 rounded-md border bg-muted p-0.5"
      role="group"
      aria-label="Choisir la vue"
    >
      <button
        type="button"
        className={boutonClass(vue === "liste")}
        aria-pressed={vue === "liste"}
        onClick={() => choisirVue("liste")}
      >
        Liste
      </button>
      <button
        type="button"
        className={boutonClass(vue === "kanban")}
        aria-pressed={vue === "kanban"}
        onClick={() => choisirVue("kanban")}
      >
        Kanban
      </button>
    </div>
  );
}
