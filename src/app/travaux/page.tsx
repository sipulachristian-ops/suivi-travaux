import Link from "next/link";
import { cookies } from "next/headers";
import { createClient } from "@/lib/supabase/server";
import { getProfilConnecte, peutGererTravaux } from "@/lib/auth";
import { AppHeader } from "@/components/app-header";
import { FiltresTravaux } from "./filtres";
import { BasculeVue } from "./bascule-vue";
import { KanbanTravaux } from "./kanban";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  STATUT_LABELS,
  STATUT_STYLES,
  PRIORITE_LABELS,
  PRIORITE_STYLES,
  formatDateFr,
  estEnRetard,
  type TravailListe,
} from "@/lib/travaux";
import { cn } from "@/lib/utils";

export const dynamic = "force-dynamic";

type SearchParams = Promise<{
  q?: string;
  statut?: string;
  batiment?: string;
  priorite?: string;
  responsable?: string;
  vue?: string;
}>;

export default async function TravauxPage({
  searchParams,
}: {
  searchParams: SearchParams;
}) {
  const profil = await getProfilConnecte();
  const params = await searchParams;
  const supabase = await createClient();

  // Vue choisie : paramètre d'URL d'abord, sinon dernier choix (cookie)
  const cookieVue = (await cookies()).get("vue_travaux")?.value;
  const vue = (params.vue ?? cookieVue) === "kanban" ? "kanban" : "liste";

  let query = supabase
    .from("travaux")
    .select(
      "id, numero, titre, nature, priorite, statut, echeance, batiment:batiments(nom), responsable:profiles!travaux_responsable_id_fkey(full_name)"
    )
    .order("created_at", { ascending: false });

  if (params.statut) query = query.eq("statut", params.statut);
  if (params.batiment) query = query.eq("batiment_id", params.batiment);
  if (params.priorite) query = query.eq("priorite", params.priorite);
  if (params.responsable) query = query.eq("responsable_id", params.responsable);
  if (params.q) {
    const q = params.q.replace(/[%,()]/g, " ").trim();
    if (q) query = query.or(`titre.ilike.%${q}%,nature.ilike.%${q}%`);
  }

  const [{ data: travauxData }, { data: batiments }, { data: responsables }] =
    await Promise.all([
      query,
      supabase.from("batiments").select("id, nom").eq("actif", true).order("nom"),
      supabase.from("profiles").select("id, full_name").order("full_name"),
    ]);

  const travaux = (travauxData ?? []) as unknown as TravailListe[];
  const filtresActifs = Boolean(
    params.q || params.statut || params.batiment || params.priorite || params.responsable
  );

  return (
    <div className="flex flex-1 flex-col">
      <AppHeader fullName={profil.fullName} role={profil.role} />
      <main className="mx-auto flex w-full max-w-6xl flex-1 flex-col gap-4 px-4 py-5 sm:px-6">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div className="flex items-baseline gap-2.5">
            <h1 className="text-2xl font-semibold tracking-tight">Travaux</h1>
            <span className="rounded-full bg-accent px-2.5 py-0.5 text-sm font-medium text-accent-foreground">
              {travaux.length}
            </span>
            {filtresActifs && (
              <span className="text-sm text-muted-foreground">
                filtres actifs
              </span>
            )}
          </div>
          <div className="flex items-center gap-2">
            <BasculeVue vue={vue} />
            {peutGererTravaux(profil.role) && (
              <Button render={<Link href="/travaux/nouveau" />}>
                + Nouveau travail
              </Button>
            )}
          </div>
        </div>

        <FiltresTravaux
          batiments={batiments ?? []}
          responsables={responsables ?? []}
        />

        {travaux.length === 0 ? (
          <div className="flex flex-col items-center gap-3 rounded-xl border border-dashed bg-card px-6 py-16 text-center">
            <p className="font-medium">
              {filtresActifs
                ? "Aucun travail ne correspond à ces filtres."
                : "Aucun travail pour l'instant."}
            </p>
            <p className="text-sm text-muted-foreground">
              {filtresActifs
                ? "Essayez d'élargir ou d'effacer les filtres."
                : "Créez le premier travail pour démarrer le suivi."}
            </p>
          </div>
        ) : vue === "kanban" ? (
          <KanbanTravaux
            travaux={travaux}
            peutDeplacer={peutGererTravaux(profil.role)}
            estDirection={profil.role === "direction"}
          />
        ) : (
          <>
            {/* Tableau (écran large) */}
            <div className="hidden overflow-hidden rounded-xl border bg-card shadow-sm md:block">
              <Table>
                <TableHeader>
                  <TableRow className="bg-muted/60 hover:bg-muted/60">
                    <TableHead className="w-16 text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">
                      N°
                    </TableHead>
                    <TableHead className="text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">
                      Intitulé
                    </TableHead>
                    <TableHead className="text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">
                      Bâtiment
                    </TableHead>
                    <TableHead className="text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">
                      Priorité
                    </TableHead>
                    <TableHead className="text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">
                      Statut
                    </TableHead>
                    <TableHead className="text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">
                      Échéance
                    </TableHead>
                    <TableHead className="text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">
                      Responsable
                    </TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {travaux.map((t) => (
                    <TableRow
                      key={t.id}
                      className="odd:bg-muted/25 hover:bg-accent/60"
                    >
                      <TableCell className="font-mono text-xs font-medium text-primary">
                        T-{t.numero}
                      </TableCell>
                      <TableCell>
                        <Link
                          href={`/travaux/${t.id}`}
                          className="font-medium hover:text-primary hover:underline"
                        >
                          {t.titre}
                        </Link>
                        {t.nature && (
                          <p className="text-xs text-muted-foreground">
                            {t.nature}
                          </p>
                        )}
                      </TableCell>
                      <TableCell>{t.batiment?.nom ?? "—"}</TableCell>
                      <TableCell>
                        <Badge
                          variant="outline"
                          className={PRIORITE_STYLES[t.priorite]}
                        >
                          {PRIORITE_LABELS[t.priorite]}
                        </Badge>
                      </TableCell>
                      <TableCell>
                        <Badge
                          variant="outline"
                          className={STATUT_STYLES[t.statut]}
                        >
                          {STATUT_LABELS[t.statut]}
                        </Badge>
                      </TableCell>
                      <TableCell
                        className={cn(
                          estEnRetard(t.echeance, t.statut) &&
                            "font-medium text-red-600"
                        )}
                      >
                        {formatDateFr(t.echeance)}
                        {estEnRetard(t.echeance, t.statut) && (
                          <span className="block text-[11px]">en retard</span>
                        )}
                      </TableCell>
                      <TableCell>{t.responsable?.full_name ?? "—"}</TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </div>

            {/* Cartes (mobile) */}
            <div className="flex flex-col gap-3 md:hidden">
              {travaux.map((t) => (
                <Link
                  key={t.id}
                  href={`/travaux/${t.id}`}
                  className="rounded-xl border bg-card p-4 shadow-xs active:bg-muted"
                >
                  <div className="flex items-start justify-between gap-2">
                    <p className="font-medium">{t.titre}</p>
                    <span className="text-xs text-muted-foreground">
                      T-{t.numero}
                    </span>
                  </div>
                  <p className="mt-1 text-sm text-muted-foreground">
                    {t.batiment?.nom ?? "—"}
                    {t.echeance ? ` · échéance ${formatDateFr(t.echeance)}` : ""}
                  </p>
                  <div className="mt-3 flex flex-wrap gap-2">
                    <Badge variant="outline" className={STATUT_STYLES[t.statut]}>
                      {STATUT_LABELS[t.statut]}
                    </Badge>
                    <Badge
                      variant="outline"
                      className={PRIORITE_STYLES[t.priorite]}
                    >
                      {PRIORITE_LABELS[t.priorite]}
                    </Badge>
                  </div>
                </Link>
              ))}
            </div>
          </>
        )}
      </main>
    </div>
  );
}
