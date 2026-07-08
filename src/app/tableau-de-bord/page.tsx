import Link from "next/link";
import { createClient } from "@/lib/supabase/server";
import { getProfilConnecte } from "@/lib/auth";
import { AppHeader } from "@/components/app-header";
import { Badge } from "@/components/ui/badge";
import {
  STATUTS_ORDONNES,
  STATUT_LABELS,
  STATUT_STYLES,
  STATUT_ACCENTS,
  PRIORITE_LABELS,
  PRIORITE_STYLES,
  estEnRetard,
  formatDateFr,
  type PrioriteTravail,
  type StatutTravail,
} from "@/lib/travaux";
import { formatEuros } from "@/lib/chiffrages";
import { cn } from "@/lib/utils";

export const dynamic = "force-dynamic";

// Couleur de chaque statut dans la barre de répartition (mêmes teintes
// que les accents du Kanban, en fond plein)
const STATUT_BARRES: Record<StatutTravail, string> = {
  a_chiffrer: "bg-slate-400",
  chiffrage_en_cours: "bg-sky-400",
  en_attente_validation: "bg-amber-400",
  valide: "bg-green-500",
  refuse: "bg-red-400",
  planifie: "bg-indigo-400",
  en_cours: "bg-blue-500",
  termine: "bg-emerald-500",
};

type TravailDash = {
  id: string;
  numero: number;
  titre: string;
  priorite: PrioriteTravail;
  statut: StatutTravail;
  echeance: string | null;
  batiment: { nom: string } | null;
};

type ChiffrageSoumis = {
  id: string;
  travail_id: string;
  version: number;
  soumis_le: string | null;
  soumis_par: { full_name: string } | null;
  travail: { id: string; numero: number; titre: string } | null;
  lignes: { montant: number }[];
};

function sommeMontants(lignes: { montant: number }[]): number {
  return lignes.reduce((s, l) => s + (Number(l.montant) || 0), 0);
}

// Montants « en un coup d'œil » : arrondis à l'euro pour rester lisibles
function eurosEntiers(valeur: number): string {
  return new Intl.NumberFormat("fr-FR", {
    style: "currency",
    currency: "EUR",
    maximumFractionDigits: 0,
  }).format(valeur);
}

export default async function TableauDeBordPage() {
  const profil = await getProfilConnecte();
  const supabase = await createClient();

  const [travauxRes, soumisRes, validesRes] = await Promise.all([
    supabase
      .from("travaux")
      .select("id, numero, titre, priorite, statut, echeance, batiment:batiments(nom)"),
    supabase
      .from("chiffrages")
      .select(
        "id, travail_id, version, soumis_le, soumis_par:profiles!chiffrages_soumis_par_fkey(full_name), travail:travaux(id, numero, titre), lignes:chiffrage_lignes(montant)"
      )
      .eq("statut", "soumis")
      .order("soumis_le", { ascending: true }),
    supabase
      .from("chiffrages")
      .select("travail_id, decide_le, lignes:chiffrage_lignes(montant)")
      .eq("statut", "valide"),
  ]);

  const travaux = (travauxRes.data ?? []) as unknown as TravailDash[];
  const chiffragesSoumis = (soumisRes.data ?? []) as unknown as ChiffrageSoumis[];
  const chiffragesValides = (validesRes.data ?? []) as unknown as {
    travail_id: string;
    decide_le: string | null;
    lignes: { montant: number }[];
  }[];

  // Répartition par statut
  const parStatut = Object.fromEntries(
    STATUTS_ORDONNES.map((s) => [s, 0])
  ) as Record<StatutTravail, number>;
  for (const t of travaux) {
    if (t.statut in parStatut) parStatut[t.statut] += 1;
  }

  // Travaux à surveiller : en retard, ou priorité haute/urgente encore ouverte
  const retards = travaux.filter((t) => estEnRetard(t.echeance, t.statut));
  const prioritaires = travaux.filter(
    (t) =>
      (t.priorite === "haute" || t.priorite === "urgente") &&
      t.statut !== "termine" &&
      t.statut !== "refuse"
  );
  const aSurveiller = [...retards, ...prioritaires]
    .filter((t, index, tous) => tous.findIndex((x) => x.id === t.id) === index)
    .sort((a, b) => (a.echeance ?? "9999").localeCompare(b.echeance ?? "9999"));

  // Montant des chiffrages en attente de validation
  const montantSoumis = chiffragesSoumis.reduce(
    (s, c) => s + sommeMontants(c.lignes),
    0
  );

  // Budget engagé : dernière version validée de chaque travail
  const derniereValidation = new Map<string, { decide_le: string; montant: number }>();
  for (const c of chiffragesValides) {
    const decideLe = c.decide_le ?? "";
    const existante = derniereValidation.get(c.travail_id);
    if (!existante || decideLe > existante.decide_le) {
      derniereValidation.set(c.travail_id, {
        decide_le: decideLe,
        montant: sommeMontants(c.lignes),
      });
    }
  }
  const budgetEngage = [...derniereValidation.values()].reduce(
    (s, v) => s + v.montant,
    0
  );
  const nbUrgentes = prioritaires.filter((t) => t.priorite === "urgente").length;

  const indicateurs = [
    {
      libelle: "Chiffrages à valider",
      valeur: String(chiffragesSoumis.length),
      detail:
        chiffragesSoumis.length > 0
          ? `${eurosEntiers(montantSoumis)} en attente`
          : "rien en attente",
      accent: "border-t-amber-400",
    },
    {
      libelle: "Budget engagé",
      valeur: eurosEntiers(budgetEngage),
      detail: `${derniereValidation.size} demande${derniereValidation.size > 1 ? "s" : ""} validée${derniereValidation.size > 1 ? "s" : ""}`,
      accent: "border-t-green-500",
    },
    {
      libelle: "Travaux en retard",
      valeur: String(retards.length),
      detail: "échéance dépassée",
      accent: "border-t-red-400",
    },
    {
      libelle: "Priorités haute / urgente",
      valeur: String(prioritaires.length),
      detail: nbUrgentes > 0 ? `dont ${nbUrgentes} urgente${nbUrgentes > 1 ? "s" : ""}` : "en cours de traitement",
      accent: "border-t-primary",
    },
  ];

  return (
    <div className="flex flex-1 flex-col">
      <AppHeader fullName={profil.fullName} role={profil.role} />
      <main className="mx-auto flex w-full max-w-6xl flex-1 flex-col gap-6 px-4 py-5 sm:px-6">
        <div className="flex flex-wrap items-baseline justify-between gap-2">
          <h1 className="text-2xl font-semibold tracking-tight">
            Tableau de bord
          </h1>
          <p className="text-sm text-muted-foreground">
            Vue d&apos;ensemble au{" "}
            {new Intl.DateTimeFormat("fr-FR", { dateStyle: "long" }).format(
              new Date()
            )}
          </p>
        </div>

        {/* Chiffres clés */}
        <div className="grid grid-cols-2 gap-3 lg:grid-cols-4">
          {indicateurs.map((i) => (
            <div
              key={i.libelle}
              className={cn(
                "rounded-xl border border-t-2 bg-card p-4 shadow-sm",
                i.accent
              )}
            >
              <p className="text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">
                {i.libelle}
              </p>
              <p className="mt-1.5 text-2xl font-semibold tabular-nums">
                {i.valeur}
              </p>
              <p className="text-xs text-muted-foreground">{i.detail}</p>
            </div>
          ))}
        </div>

        {/* Répartition par statut */}
        <section className="flex flex-col gap-3">
          <h2 className="text-sm font-semibold uppercase tracking-wider text-muted-foreground">
            Répartition des {travaux.length} travaux par statut
          </h2>
          {travaux.length > 0 && (
            <div className="flex h-2 overflow-hidden rounded-full border bg-muted">
              {STATUTS_ORDONNES.filter((s) => parStatut[s] > 0).map((s) => (
                <div
                  key={s}
                  title={`${STATUT_LABELS[s]} : ${parStatut[s]}`}
                  className={STATUT_BARRES[s]}
                  style={{ width: `${(parStatut[s] / travaux.length) * 100}%` }}
                />
              ))}
            </div>
          )}
          <div className="grid grid-cols-2 gap-2 sm:grid-cols-4">
            {STATUTS_ORDONNES.map((s) => (
              <Link
                key={s}
                href={`/travaux?statut=${s}`}
                className={cn(
                  "rounded-lg border border-t-2 bg-card px-3 py-2.5 shadow-xs transition-colors hover:border-primary/50 hover:bg-accent/50",
                  STATUT_ACCENTS[s]
                )}
              >
                <p className="text-xl font-semibold tabular-nums">
                  {parStatut[s]}
                </p>
                <p className="text-xs text-muted-foreground">
                  {STATUT_LABELS[s]}
                </p>
              </Link>
            ))}
          </div>
        </section>

        {/* Chiffrages en attente de validation */}
        <section className="flex flex-col gap-3">
          <h2 className="text-sm font-semibold uppercase tracking-wider text-muted-foreground">
            Chiffrages en attente de validation
          </h2>
          <div className="rounded-xl border bg-card shadow-sm">
            {chiffragesSoumis.length === 0 ? (
              <p className="px-5 py-6 text-sm text-muted-foreground">
                Aucun chiffrage en attente — tout est à jour.
              </p>
            ) : (
              <div className="flex flex-col divide-y">
                {chiffragesSoumis.map((c) => (
                  <Link
                    key={c.id}
                    href={`/travaux/${c.travail?.id}/chiffrages/${c.id}`}
                    className="flex flex-wrap items-center justify-between gap-x-4 gap-y-1 px-5 py-3.5 transition-colors hover:bg-accent/50"
                  >
                    <div className="min-w-0">
                      <p className="font-medium">
                        <span className="font-mono text-xs text-primary">
                          T-{c.travail?.numero}
                        </span>{" "}
                        {c.travail?.titre}
                      </p>
                      <p className="text-xs text-muted-foreground">
                        Version {c.version} · soumis par{" "}
                        {c.soumis_par?.full_name || "?"} le{" "}
                        {formatDateFr(c.soumis_le)}
                      </p>
                    </div>
                    <p className="text-sm font-semibold tabular-nums">
                      {formatEuros(sommeMontants(c.lignes))}
                    </p>
                  </Link>
                ))}
              </div>
            )}
          </div>
        </section>

        {/* Travaux en retard ou prioritaires */}
        <section className="flex flex-col gap-3">
          <div className="flex items-baseline justify-between gap-3">
            <h2 className="text-sm font-semibold uppercase tracking-wider text-muted-foreground">
              Travaux en retard ou prioritaires
            </h2>
            <Link
              href="/travaux"
              className="text-sm text-primary hover:underline"
            >
              Voir tous les travaux →
            </Link>
          </div>
          <div className="rounded-xl border bg-card shadow-sm">
            {aSurveiller.length === 0 ? (
              <p className="px-5 py-6 text-sm text-muted-foreground">
                Aucun travail en retard ni priorité haute en cours.
              </p>
            ) : (
              <div className="flex flex-col divide-y">
                {aSurveiller.slice(0, 8).map((t) => {
                  const retard = estEnRetard(t.echeance, t.statut);
                  return (
                    <Link
                      key={t.id}
                      href={`/travaux/${t.id}`}
                      className="flex flex-wrap items-center justify-between gap-x-4 gap-y-2 px-5 py-3.5 transition-colors hover:bg-accent/50"
                    >
                      <div className="min-w-0">
                        <p className="font-medium">
                          <span className="font-mono text-xs text-primary">
                            T-{t.numero}
                          </span>{" "}
                          {t.titre}
                        </p>
                        <p className="text-xs text-muted-foreground">
                          {t.batiment?.nom ?? "—"}
                          {t.echeance && (
                            <>
                              {" · échéance "}
                              <span
                                className={cn(retard && "font-medium text-red-600")}
                              >
                                {formatDateFr(t.echeance)}
                                {retard && " (en retard)"}
                              </span>
                            </>
                          )}
                        </p>
                      </div>
                      <div className="flex flex-wrap gap-2">
                        <Badge
                          variant="outline"
                          className={PRIORITE_STYLES[t.priorite]}
                        >
                          {PRIORITE_LABELS[t.priorite]}
                        </Badge>
                        <Badge variant="outline" className={STATUT_STYLES[t.statut]}>
                          {STATUT_LABELS[t.statut]}
                        </Badge>
                      </div>
                    </Link>
                  );
                })}
                {aSurveiller.length > 8 && (
                  <p className="px-5 py-3 text-xs text-muted-foreground">
                    … et {aSurveiller.length - 8} autre
                    {aSurveiller.length - 8 > 1 ? "s" : ""} — voir la liste
                    complète.
                  </p>
                )}
              </div>
            )}
          </div>
        </section>
      </main>
    </div>
  );
}
