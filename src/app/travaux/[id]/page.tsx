import Link from "next/link";
import { notFound } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { getProfilConnecte, peutChiffrer, peutGererTravaux } from "@/lib/auth";
import { AppHeader } from "@/components/app-header";
import { Badge } from "@/components/ui/badge";
import { TravailForm } from "../travail-form";
import { ChangerStatut } from "../changer-statut";
import { modifierTravail } from "../actions";
import { CreerChiffrageBouton } from "./chiffrages/creer-chiffrage-bouton";
import {
  STATUT_LABELS,
  STATUT_STYLES,
  formatDateFr,
  type StatutTravail,
} from "@/lib/travaux";
import {
  STATUT_CHIFFRAGE_LABELS,
  STATUT_CHIFFRAGE_STYLES,
  formatEuros,
  formatHeures,
  totauxLignes,
  type StatutChiffrage,
} from "@/lib/chiffrages";

export default async function TravailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const profil = await getProfilConnecte();
  const { id } = await params;
  const supabase = await createClient();

  const [
    { data: travail },
    { data: batiments },
    { data: responsables },
    { data: chiffrages, error: erreurChiffrages },
  ] = await Promise.all([
    supabase
      .from("travaux")
      .select(
        "id, numero, titre, nature, description, batiment_id, priorite, statut, echeance, responsable_id, created_at, updated_at, createur:profiles!travaux_cree_par_fkey(full_name)"
      )
      .eq("id", id)
      .single(),
    supabase.from("batiments").select("id, nom").eq("actif", true).order("nom"),
    supabase.from("profiles").select("id, full_name").order("full_name"),
    supabase
      .from("chiffrages")
      .select(
        "id, version, statut, created_at, auteur:profiles!chiffrages_auteur_fkey(full_name), lignes:chiffrage_lignes(montant, heures)"
      )
      .eq("travail_id", id)
      .order("version", { ascending: false }),
  ]);

  if (!travail) {
    notFound();
  }

  const statut = travail.statut as StatutTravail;
  const createur = travail.createur as unknown as { full_name: string } | null;
  const modifiable = peutGererTravaux(profil.role);
  const actionModifier = modifierTravail.bind(null, travail.id);

  // erreurChiffrages : la migration 0004 n'a pas encore été exécutée —
  // la fiche reste utilisable, la section chiffrage l'indique simplement.
  const listeChiffrages = (chiffrages ?? []).map((c) => ({
    id: c.id,
    version: c.version as number,
    statut: c.statut as StatutChiffrage,
    created_at: c.created_at as string,
    auteur: (c.auteur as unknown as { full_name: string } | null)?.full_name,
    nbPostes: (c.lignes ?? []).length,
    totaux: totauxLignes(c.lignes ?? []),
  }));
  const brouillonExiste = listeChiffrages.some((c) => c.statut === "brouillon");
  // Pas de nouveau chiffrage tant qu'une version attend la décision de
  // la direction (même règle que la fonction SQL creer_chiffrage).
  const soumissionEnAttente = listeChiffrages.some(
    (c) => c.statut === "soumis"
  );
  const peutCreerChiffrage =
    peutChiffrer(profil.role) &&
    !brouillonExiste &&
    !soumissionEnAttente &&
    !erreurChiffrages;

  return (
    <div className="flex flex-1 flex-col">
      <AppHeader fullName={profil.fullName} role={profil.role} />
      <main className="mx-auto flex w-full max-w-2xl flex-1 flex-col gap-6 px-4 py-6 sm:px-6">
        <div className="flex flex-col gap-2">
          <Link
            href="/travaux"
            className="text-sm text-muted-foreground hover:underline"
          >
            ← Retour à la liste
          </Link>
          <div className="flex flex-wrap items-center gap-3">
            <h1 className="text-2xl font-semibold tracking-tight">
              T-{travail.numero} · {travail.titre}
            </h1>
            <Badge variant="outline" className={STATUT_STYLES[statut]}>
              {STATUT_LABELS[statut]}
            </Badge>
          </div>
          <p className="text-sm text-muted-foreground">
            Créé par {createur?.full_name || "?"} le{" "}
            {formatDateFr(travail.created_at)} · dernière modification le{" "}
            {formatDateFr(travail.updated_at)}
          </p>
          {modifiable && (
            <div className="mt-1">
              <ChangerStatut
                travailId={travail.id}
                statut={statut}
                estDirection={profil.role === "direction"}
              />
            </div>
          )}
        </div>

        {modifiable ? (
          <TravailForm
            action={actionModifier}
            batiments={batiments ?? []}
            responsables={responsables ?? []}
            valeurs={{
              titre: travail.titre,
              nature: travail.nature,
              description: travail.description,
              batiment_id: travail.batiment_id,
              priorite: travail.priorite,
              echeance: travail.echeance,
              responsable_id: travail.responsable_id,
            }}
            libelleBouton="Enregistrer les modifications"
            lienAnnuler="/travaux"
          />
        ) : (
          <div className="flex flex-col gap-4 rounded-xl border bg-card p-5 shadow-sm">
            <div>
              <p className="text-sm font-medium text-muted-foreground">
                Description
              </p>
              <p className="whitespace-pre-wrap">
                {travail.description || "—"}
              </p>
            </div>
            <div className="grid gap-4 sm:grid-cols-2">
              <div>
                <p className="text-sm font-medium text-muted-foreground">
                  Nature
                </p>
                <p>{travail.nature || "—"}</p>
              </div>
              <div>
                <p className="text-sm font-medium text-muted-foreground">
                  Échéance
                </p>
                <p>{formatDateFr(travail.echeance)}</p>
              </div>
            </div>
          </div>
        )}

        <section className="flex flex-col gap-3 rounded-xl border bg-card p-5 shadow-sm">
          <div className="flex flex-wrap items-center justify-between gap-2">
            <h2 className="text-base font-semibold">Chiffrage</h2>
            {peutCreerChiffrage && (
              <CreerChiffrageBouton
                travailId={travail.id}
                libelle={
                  listeChiffrages.length > 0
                    ? "Nouvelle version"
                    : "Créer un chiffrage"
                }
              />
            )}
          </div>

          {erreurChiffrages ? (
            <p className="text-sm text-muted-foreground">
              Le module de chiffrage sera disponible une fois la migration
              0004 exécutée dans Supabase.
            </p>
          ) : listeChiffrages.length === 0 ? (
            <p className="text-sm text-muted-foreground">
              Aucun chiffrage pour l&apos;instant.
            </p>
          ) : (
            <div className="flex flex-col">
              {listeChiffrages.map((c) => (
                <Link
                  key={c.id}
                  href={`/travaux/${travail.id}/chiffrages/${c.id}`}
                  className="flex flex-wrap items-center gap-x-3 gap-y-1 border-t py-3 first:border-t-0 first:pt-0 last:pb-0 hover:bg-muted/50"
                >
                  <span className="text-sm font-medium">
                    Version {c.version}
                  </span>
                  <Badge
                    variant="outline"
                    className={STATUT_CHIFFRAGE_STYLES[c.statut]}
                  >
                    {STATUT_CHIFFRAGE_LABELS[c.statut]}
                  </Badge>
                  <span className="text-sm text-muted-foreground">
                    {c.nbPostes === 0
                      ? "Aucun poste"
                      : `${c.nbPostes} poste${c.nbPostes > 1 ? "s" : ""} · ${formatEuros(c.totaux.montant)} · ${formatHeures(c.totaux.heures)}`}
                  </span>
                  <span className="ml-auto text-sm text-muted-foreground">
                    par {c.auteur || "?"} le {formatDateFr(c.created_at)} →
                  </span>
                </Link>
              ))}
            </div>
          )}
        </section>
      </main>
    </div>
  );
}
