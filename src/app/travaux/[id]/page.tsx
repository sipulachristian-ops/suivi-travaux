import Link from "next/link";
import { notFound } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { getProfilConnecte, peutGererTravaux } from "@/lib/auth";
import { AppHeader } from "@/components/app-header";
import { Badge } from "@/components/ui/badge";
import { TravailForm } from "../travail-form";
import { modifierTravail } from "../actions";
import {
  STATUT_LABELS,
  STATUT_STYLES,
  formatDateFr,
  type StatutTravail,
} from "@/lib/travaux";

export default async function TravailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const profil = await getProfilConnecte();
  const { id } = await params;
  const supabase = await createClient();

  const [{ data: travail }, { data: batiments }, { data: responsables }] =
    await Promise.all([
      supabase
        .from("travaux")
        .select(
          "id, numero, titre, nature, description, batiment_id, priorite, statut, echeance, responsable_id, created_at, updated_at, createur:profiles!travaux_cree_par_fkey(full_name)"
        )
        .eq("id", id)
        .single(),
      supabase.from("batiments").select("id, nom").eq("actif", true).order("nom"),
      supabase.from("profiles").select("id, full_name").order("full_name"),
    ]);

  if (!travail) {
    notFound();
  }

  const statut = travail.statut as StatutTravail;
  const createur = travail.createur as unknown as { full_name: string } | null;
  const modifiable = peutGererTravaux(profil.role);
  const actionModifier = modifierTravail.bind(null, travail.id);

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
          <p className="text-xs text-muted-foreground">
            Le statut évoluera via le Kanban (étape 3) et le circuit de
            validation (étape 5).
          </p>
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
          <div className="flex flex-col gap-4 rounded-lg border p-4">
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
      </main>
    </div>
  );
}
