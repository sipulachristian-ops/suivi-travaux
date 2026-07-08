import Link from "next/link";
import { notFound } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { getProfilConnecte, peutChiffrer } from "@/lib/auth";
import { AppHeader } from "@/components/app-header";
import { Badge } from "@/components/ui/badge";
import { ChiffrageEditeur } from "../chiffrage-editeur";
import { formatDateFr } from "@/lib/travaux";
import {
  STATUT_CHIFFRAGE_LABELS,
  STATUT_CHIFFRAGE_STYLES,
  formatEuros,
  formatHeures,
  formatQuantite,
  totauxLignes,
  type LigneChiffrage,
  type StatutChiffrage,
} from "@/lib/chiffrages";

export default async function ChiffragePage({
  params,
}: {
  params: Promise<{ id: string; chiffrageId: string }>;
}) {
  const profil = await getProfilConnecte();
  const { id: travailId, chiffrageId } = await params;
  const supabase = await createClient();

  const { data: chiffrage } = await supabase
    .from("chiffrages")
    .select(
      "id, travail_id, version, statut, created_at, auteur:profiles!chiffrages_auteur_fkey(full_name), lignes:chiffrage_lignes(id, position, libelle, quantite, unite, prix_unitaire, montant, heures), travail:travaux(id, numero, titre)"
    )
    .eq("id", chiffrageId)
    .order("position", { referencedTable: "chiffrage_lignes" })
    .single();

  if (!chiffrage || chiffrage.travail_id !== travailId) {
    notFound();
  }

  const statut = chiffrage.statut as StatutChiffrage;
  const auteur = chiffrage.auteur as unknown as { full_name: string } | null;
  const travail = chiffrage.travail as unknown as {
    id: string;
    numero: number;
    titre: string;
  };
  const lignes = (chiffrage.lignes ?? []) as LigneChiffrage[];
  const totaux = totauxLignes(lignes);
  const modifiable = peutChiffrer(profil.role) && statut === "brouillon";

  return (
    <div className="flex flex-1 flex-col">
      <AppHeader fullName={profil.fullName} role={profil.role} />
      <main className="mx-auto flex w-full max-w-2xl flex-1 flex-col gap-6 px-4 py-6 sm:px-6">
        <div className="flex flex-col gap-2">
          <Link
            href={`/travaux/${travail.id}`}
            className="text-sm text-muted-foreground hover:underline"
          >
            ← Retour au travail T-{travail.numero}
          </Link>
          <div className="flex flex-wrap items-center gap-3">
            <h1 className="text-2xl font-semibold tracking-tight">
              Chiffrage · {travail.titre}
            </h1>
            <Badge variant="outline" className={STATUT_CHIFFRAGE_STYLES[statut]}>
              {STATUT_CHIFFRAGE_LABELS[statut]}
            </Badge>
          </div>
          <p className="text-sm text-muted-foreground">
            Version {chiffrage.version} · créé par {auteur?.full_name || "?"} le{" "}
            {formatDateFr(chiffrage.created_at)}
          </p>
          {modifiable && (
            <p className="text-sm text-muted-foreground">
              Saisissez les postes un par un, puis enregistrez. La soumission à
              la direction arrivera avec le workflow de validation.
            </p>
          )}
        </div>

        {modifiable ? (
          <ChiffrageEditeur
            chiffrageId={chiffrage.id}
            travailId={travail.id}
            lignesInitiales={lignes}
          />
        ) : (
          <div className="flex flex-col gap-3 rounded-xl border bg-card p-5 shadow-sm">
            {lignes.length === 0 ? (
              <p className="text-sm text-muted-foreground">
                Aucun poste saisi pour l&apos;instant.
              </p>
            ) : (
              <>
                <div className="grid grid-cols-[minmax(0,1fr)_4.5rem_6rem_6.5rem] gap-2 text-xs font-medium text-muted-foreground">
                  <span>Poste</span>
                  <span className="text-right">Qté</span>
                  <span className="text-right">P.U.</span>
                  <span className="text-right">Montant</span>
                </div>
                {lignes.map((ligne) => (
                  <div
                    key={ligne.id}
                    className="grid grid-cols-[minmax(0,1fr)_4.5rem_6rem_6.5rem] gap-2 border-t pt-2 text-sm first-of-type:border-t-0"
                  >
                    <span>{ligne.libelle}</span>
                    <span className="text-right tabular-nums">
                      {formatQuantite(ligne.quantite, ligne.unite)}
                    </span>
                    <span className="text-right tabular-nums">
                      {formatEuros(ligne.prix_unitaire)}
                    </span>
                    <span className="text-right tabular-nums">
                      {formatEuros(ligne.montant)}
                    </span>
                  </div>
                ))}
                <p className="border-t pt-3 text-sm font-medium">
                  Total :{" "}
                  <span className="tabular-nums">
                    {formatEuros(totaux.montant)}
                  </span>
                  {" · "}
                  <span className="tabular-nums">
                    {formatHeures(totaux.heures)}
                  </span>
                </p>
              </>
            )}
          </div>
        )}
      </main>
    </div>
  );
}
