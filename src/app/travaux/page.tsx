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
import { formatEuros } from "@/lib/chiffrages";
import { cn } from "@/lib/utils";

export const dynamic = "force-dynamic";

// Volets figés « comme Excel » : les cellules collantes (en-tête et
// colonnes N° / Intitulé) doivent être OPAQUES pour que le contenu ne
// transparaisse pas en défilant. Les couleurs translucides du tableau
// (zébrures, survol) sont recomposées ici en couleurs pleines.
const FOND_ENTETE =
  "bg-[color-mix(in_oklab,var(--muted)_60%,var(--card))]";
const FOND_ZEBRE =
  "group-odd:bg-[color-mix(in_oklab,var(--muted)_25%,var(--card))]";
const FOND_SURVOL =
  "group-hover:bg-[color-mix(in_oklab,var(--accent)_60%,var(--card))]";

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
      "id, numero, titre, nature, priorite, statut, echeance, batiment:batiments(nom), responsable:profiles!travaux_responsable_id_fkey(full_name), reference_devis, numero_os, montant_os, sous_traitance, nom_sous_traitant, rapport_intervention, cat, facturation"
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
      {/* Plus large que les autres pages : le tableau porte aussi le
          suivi commercial (demande de Christian) */}
      <main className="mx-auto flex w-full max-w-[100rem] flex-1 flex-col gap-4 px-4 py-5 sm:px-6">
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
            {/* Tableau (écran large) — volets figés comme Excel :
                en-tête collé en haut, N° + Intitulé collés à gauche,
                défilement vertical et horizontal à la molette */}
            <div className="hidden overflow-hidden rounded-xl border bg-card shadow-sm md:block [&_[data-slot=table-container]]:max-h-[calc(100dvh-14rem)] [&_[data-slot=table-container]]:overflow-y-auto">
              <Table>
                <TableHeader className="sticky top-0 z-20">
                  <TableRow className={cn("hover:bg-transparent", FOND_ENTETE)}>
                    <TableHead
                      className={cn(
                        "sticky left-0 z-10 w-16 text-[11px] font-semibold uppercase tracking-wider text-muted-foreground",
                        FOND_ENTETE
                      )}
                    >
                      N°
                    </TableHead>
                    <TableHead
                      className={cn(
                        "sticky left-16 z-10 border-r text-[11px] font-semibold uppercase tracking-wider text-muted-foreground",
                        FOND_ENTETE
                      )}
                    >
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
                    <TableHead className="text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">
                      N° devis
                    </TableHead>
                    <TableHead className="text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">
                      OS
                    </TableHead>
                    <TableHead className="text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">
                      Sous-traitance
                    </TableHead>
                    <TableHead className="text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">
                      Rapport
                    </TableHead>
                    <TableHead className="text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">
                      CAT
                    </TableHead>
                    <TableHead className="text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">
                      Facturation
                    </TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {travaux.map((t) => (
                    <TableRow
                      key={t.id}
                      className="group odd:bg-muted/25 hover:bg-accent/60"
                    >
                      <TableCell
                        className={cn(
                          "sticky left-0 z-[5] w-16 bg-card font-mono text-xs font-medium text-primary",
                          FOND_ZEBRE,
                          FOND_SURVOL
                        )}
                      >
                        T-{t.numero}
                      </TableCell>
                      {/* whitespace-normal : les intitulés longs
                          s'enroulent dans la colonne figée au lieu de
                          déborder sur les colonnes qui défilent */}
                      <TableCell
                        className={cn(
                          "sticky left-16 z-[5] min-w-72 max-w-96 whitespace-normal break-words border-r bg-card",
                          FOND_ZEBRE,
                          FOND_SURVOL
                        )}
                      >
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
                      <TableCell className="min-w-44">
                        {t.batiment?.nom ?? "—"}
                      </TableCell>
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
                          "whitespace-nowrap",
                          estEnRetard(t.echeance, t.statut) &&
                            "font-medium text-red-600"
                        )}
                      >
                        {formatDateFr(t.echeance)}
                        {estEnRetard(t.echeance, t.statut) && (
                          <span className="block text-[11px]">en retard</span>
                        )}
                      </TableCell>
                      <TableCell className="whitespace-nowrap">
                        {t.responsable?.full_name ?? "—"}
                      </TableCell>
                      <TableCell className="whitespace-nowrap font-mono text-xs">
                        {t.reference_devis || "—"}
                      </TableCell>
                      <TableCell className="whitespace-nowrap">
                        {t.numero_os ? (
                          <>
                            <span className="font-mono text-xs">
                              {t.numero_os}
                            </span>
                            {t.montant_os !== null && (
                              <span className="block text-xs text-muted-foreground">
                                {formatEuros(Number(t.montant_os))}
                              </span>
                            )}
                          </>
                        ) : (
                          "—"
                        )}
                      </TableCell>
                      <TableCell className="whitespace-nowrap">
                        {t.nom_sous_traitant ||
                          (t.sous_traitance === null
                            ? "—"
                            : t.sous_traitance
                              ? "Oui"
                              : "Non")}
                      </TableCell>
                      <TableCell className="whitespace-nowrap">
                        {t.rapport_intervention || "—"}
                      </TableCell>
                      <TableCell className="whitespace-nowrap">
                        {t.cat || "—"}
                      </TableCell>
                      <TableCell className="whitespace-nowrap">
                        {t.facturation || "—"}
                      </TableCell>
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
                    {t.reference_devis ? ` · devis ${t.reference_devis}` : ""}
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
