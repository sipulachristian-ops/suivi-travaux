"use client";

import { useMemo, useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { Sparkles } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  UNITES,
  UNITE_LABELS,
  formatEuros,
  formatHeures,
  type LigneChiffrage,
  type LigneSaisie,
  type Unite,
} from "@/lib/chiffrages";
import { enregistrerLignes, soumettreChiffrage } from "./actions";
import { proposerChiffrageIA } from "./actions-ia";

// Une ligne en cours de saisie : quantité et prix unitaire restent du
// texte (virgule française acceptée), la conversion se fait à
// l'enregistrement. Le montant (quantité × PU) est calculé à l'affichage.
type LigneEdition = {
  cle: number;
  libelle: string;
  quantite: string;
  unite: string;
  prixUnitaire: string;
};

function versTexte(valeur: number): string {
  return valeur === 0 ? "" : String(valeur).replace(".", ",");
}

// "1 250,50" → 1250.5 ; champ vide → null ; texte invalide → NaN
function versNombre(texte: string): number | null {
  const propre = texte.trim().replace(/\s/g, "").replace(",", ".");
  if (propre === "") return null;
  const nombre = Number(propre);
  return Number.isFinite(nombre) && nombre >= 0 ? nombre : Number.NaN;
}

function montantLigne(ligne: LigneEdition): number | null {
  const quantite = versNombre(ligne.quantite) ?? 1;
  const prixUnitaire = versNombre(ligne.prixUnitaire) ?? 0;
  if (Number.isNaN(quantite) || Number.isNaN(prixUnitaire)) return null;
  return Math.round(quantite * prixUnitaire * 100) / 100;
}

const inputNombreClass = "text-right tabular-nums";
const selectClass =
  "h-9 w-full rounded-md border border-input bg-transparent px-2 text-sm shadow-xs outline-none focus-visible:border-ring focus-visible:ring-ring/50 focus-visible:ring-[3px]";
const grilleClass =
  "sm:grid sm:grid-cols-[minmax(0,1fr)_4.5rem_4.75rem_6rem_6.5rem_2rem] sm:items-center sm:gap-2";

export function ChiffrageEditeur({
  chiffrageId,
  travailId,
  lignesInitiales,
}: {
  chiffrageId: string;
  travailId: string;
  lignesInitiales: LigneChiffrage[];
}) {
  const [prochaineCle, setProchaineCle] = useState(lignesInitiales.length + 1);
  const [lignes, setLignes] = useState<LigneEdition[]>(() =>
    lignesInitiales.length > 0
      ? lignesInitiales.map((l, index) => ({
          cle: index,
          libelle: l.libelle,
          quantite: versTexte(l.quantite),
          unite: l.unite,
          prixUnitaire: versTexte(l.prix_unitaire),
        }))
      : [{ cle: 0, libelle: "", quantite: "1", unite: "u", prixUnitaire: "" }]
  );
  const [erreur, setErreur] = useState<string | null>(null);
  const [enregistre, setEnregistre] = useState(false);
  const [confirmeSoumission, setConfirmeSoumission] = useState(false);
  const [confirmeIA, setConfirmeIA] = useState(false);
  const [iaEnCours, setIaEnCours] = useState(false);
  const [commentaireIA, setCommentaireIA] = useState<string | null>(null);
  const [enCours, startTransition] = useTransition();
  const router = useRouter();

  function modifier(cle: number, champ: keyof LigneEdition, valeur: string) {
    setEnregistre(false);
    setLignes((courantes) =>
      courantes.map((l) => (l.cle === cle ? { ...l, [champ]: valeur } : l))
    );
  }

  function ajouterLigne() {
    setEnregistre(false);
    setLignes((courantes) => [
      ...courantes,
      { cle: prochaineCle, libelle: "", quantite: "1", unite: "u", prixUnitaire: "" },
    ]);
    setProchaineCle((n) => n + 1);
  }

  function supprimerLigne(cle: number) {
    setEnregistre(false);
    setLignes((courantes) => courantes.filter((l) => l.cle !== cle));
  }

  // Totaux affichés en direct : montant = somme des quantité × PU ;
  // heures = somme des quantités des lignes en « h »
  const totaux = useMemo(() => {
    return lignes.reduce(
      (acc, l) => {
        const montant = montantLigne(l);
        const quantite = versNombre(l.quantite) ?? 1;
        return {
          montant: acc.montant + (montant ?? 0),
          heures:
            acc.heures +
            (l.unite === "h" && !Number.isNaN(quantite) ? quantite : 0),
        };
      },
      { montant: 0, heures: 0 }
    );
  }, [lignes]);

  // Transforme la saisie en postes prêts à envoyer ; en cas d'erreur,
  // l'affiche et renvoie null (les lignes laissées vides sont ignorées).
  function construirePostes(): LigneSaisie[] | null {
    const postes: LigneSaisie[] = [];
    for (const [index, ligne] of lignes.entries()) {
      const libelle = ligne.libelle.trim();
      const vide =
        !libelle && !ligne.prixUnitaire.trim() && ligne.quantite.trim() === "1";
      if (!libelle && vide) continue; // ligne laissée vide : on l'ignore

      if (!libelle) {
        setErreur(`Le poste n° ${index + 1} n'a pas de libellé.`);
        return null;
      }
      const quantite = versNombre(ligne.quantite) ?? 1;
      if (Number.isNaN(quantite)) {
        setErreur(`Quantité invalide pour « ${libelle} ».`);
        return null;
      }
      const prixUnitaire = versNombre(ligne.prixUnitaire) ?? 0;
      if (Number.isNaN(prixUnitaire)) {
        setErreur(`Prix unitaire invalide pour « ${libelle} ».`);
        return null;
      }
      postes.push({
        libelle,
        quantite,
        unite: (UNITES as readonly string[]).includes(ligne.unite)
          ? (ligne.unite as Unite)
          : "u",
        prix_unitaire: prixUnitaire,
      });
    }
    return postes;
  }

  // La proposition IA remplace les postes affichés : si des postes sont
  // déjà saisis, on demande confirmation avant d'écraser.
  function saisieCommencee(): boolean {
    return lignes.some((l) => l.libelle.trim() || l.prixUnitaire.trim());
  }

  function demanderPropositionIA() {
    setErreur(null);
    if (saisieCommencee()) {
      setConfirmeIA(true);
      return;
    }
    lancerPropositionIA();
  }

  function lancerPropositionIA() {
    setConfirmeIA(false);
    setIaEnCours(true);
    startTransition(async () => {
      try {
        const resultat = await proposerChiffrageIA(travailId);
        if (resultat.error || !resultat.postes) {
          setErreur(resultat.error ?? "La proposition IA a échoué. Réessayez.");
          return;
        }
        setLignes(
          resultat.postes.map((p, index) => ({
            cle: index,
            libelle: p.libelle,
            quantite: versTexte(p.quantite) || "0",
            unite: p.unite,
            prixUnitaire: versTexte(p.prix_unitaire) || "0",
          }))
        );
        setProchaineCle(resultat.postes.length);
        setCommentaireIA(resultat.commentaire || null);
        setEnregistre(false);
      } finally {
        setIaEnCours(false);
      }
    });
  }

  function enregistrer() {
    setErreur(null);
    const postes = construirePostes();
    if (!postes) return;

    startTransition(async () => {
      const resultat = await enregistrerLignes(chiffrageId, travailId, postes);
      if (resultat.error) {
        setErreur(resultat.error);
      } else {
        setEnregistre(true);
      }
    });
  }

  // Soumission : enregistre les postes puis fige le chiffrage (le
  // travail passe « En attente de validation »). Confirmée en deux temps.
  function soumettre() {
    setErreur(null);
    const postes = construirePostes();
    if (!postes) return;
    if (postes.length === 0) {
      setErreur("Ajoutez au moins un poste avant de soumettre.");
      return;
    }

    startTransition(async () => {
      const sauvegarde = await enregistrerLignes(chiffrageId, travailId, postes);
      if (sauvegarde.error) {
        setErreur(sauvegarde.error);
        return;
      }
      const resultat = await soumettreChiffrage(chiffrageId, travailId);
      if (resultat.error) {
        setErreur(resultat.error);
        return;
      }
      setConfirmeSoumission(false);
      router.refresh(); // la page passe en lecture seule (chiffrage soumis)
    });
  }

  return (
    <div className="flex flex-col gap-4 rounded-xl border bg-card p-5 shadow-sm">
      {/* En-têtes de colonnes (masqués sur mobile : chaque champ y est empilé) */}
      <div
        className={`hidden text-xs font-medium text-muted-foreground ${grilleClass}`}
      >
        <span>Poste</span>
        <span className="text-right">Qté</span>
        <span>Unité</span>
        <span className="text-right">P.U. €</span>
        <span className="text-right">Montant</span>
        <span />
      </div>

      <div className="flex flex-col gap-4 sm:gap-2">
        {lignes.map((ligne, index) => {
          const montant = montantLigne(ligne);
          return (
            <div
              key={ligne.cle}
              className={`flex flex-col gap-2 rounded-lg border p-3 sm:rounded-none sm:border-0 sm:p-0 ${grilleClass}`}
            >
              <Input
                aria-label={`Libellé du poste ${index + 1}`}
                placeholder="Ex. : Main d'œuvre raccordement"
                value={ligne.libelle}
                onChange={(e) => modifier(ligne.cle, "libelle", e.target.value)}
              />
              <div className="flex items-center gap-2 sm:contents">
                <Input
                  aria-label={`Quantité du poste ${index + 1}`}
                  inputMode="decimal"
                  placeholder="1"
                  className={`w-16 sm:w-full ${inputNombreClass}`}
                  value={ligne.quantite}
                  onChange={(e) => modifier(ligne.cle, "quantite", e.target.value)}
                />
                <select
                  aria-label={`Unité du poste ${index + 1}`}
                  className={`w-20 sm:w-full ${selectClass}`}
                  value={ligne.unite}
                  onChange={(e) => modifier(ligne.cle, "unite", e.target.value)}
                >
                  {UNITES.map((u) => (
                    <option key={u} value={u}>
                      {UNITE_LABELS[u]}
                    </option>
                  ))}
                </select>
                <Input
                  aria-label={`Prix unitaire du poste ${index + 1} en euros`}
                  inputMode="decimal"
                  placeholder="0,00"
                  className={`w-24 sm:w-full ${inputNombreClass}`}
                  value={ligne.prixUnitaire}
                  onChange={(e) =>
                    modifier(ligne.cle, "prixUnitaire", e.target.value)
                  }
                />
                <span className="flex-1 text-right text-sm font-medium tabular-nums sm:flex-none">
                  {montant === null ? "—" : formatEuros(montant)}
                </span>
                <button
                  type="button"
                  aria-label={`Supprimer le poste ${index + 1}`}
                  className="flex h-8 w-8 items-center justify-center rounded-md text-muted-foreground hover:bg-red-50 hover:text-red-600"
                  onClick={() => supprimerLigne(ligne.cle)}
                >
                  ✕
                </button>
              </div>
            </div>
          );
        })}
      </div>

      <div className="flex flex-wrap items-center justify-between gap-3">
        <Button type="button" variant="outline" size="sm" onClick={ajouterLigne}>
          + Ajouter un poste
        </Button>
        <Button
          type="button"
          variant="outline"
          size="sm"
          className="border-primary/40 text-primary hover:bg-primary/5 hover:text-primary"
          disabled={enCours || confirmeSoumission || confirmeIA}
          onClick={demanderPropositionIA}
        >
          <Sparkles aria-hidden className="size-3.5" />
          {iaEnCours ? "Analyse en cours…" : "Proposer avec l'IA"}
        </Button>
      </div>

      {confirmeIA && (
        <div className="flex flex-col gap-3 rounded-md border border-primary/30 bg-primary/5 px-4 py-3">
          <p className="text-sm">
            L&apos;IA va analyser la description de la demande et proposer des
            postes. <strong>Les postes actuellement saisis seront remplacés.</strong>
          </p>
          <div className="flex flex-wrap items-center gap-3">
            <Button
              type="button"
              size="sm"
              disabled={enCours}
              onClick={lancerPropositionIA}
            >
              Remplacer par la proposition IA
            </Button>
            <Button
              type="button"
              size="sm"
              variant="ghost"
              disabled={enCours}
              onClick={() => setConfirmeIA(false)}
            >
              Annuler
            </Button>
          </div>
        </div>
      )}

      {commentaireIA && (
        <div className="rounded-md border border-sky-200 bg-sky-50 px-4 py-3">
          <p className="text-sm font-medium text-sky-900">
            Proposition de l&apos;IA — prix indicatifs, à vérifier avant
            d&apos;enregistrer
          </p>
          <p className="mt-1 whitespace-pre-wrap text-sm text-sky-800">
            {commentaireIA}
          </p>
        </div>
      )}

      <div className="flex flex-wrap items-center justify-between gap-3 border-t pt-4">
        <p className="text-sm font-medium">
          Total :{" "}
          <span className="tabular-nums">{formatEuros(totaux.montant)}</span>
          {" · "}
          <span className="tabular-nums">{formatHeures(totaux.heures)}</span>
        </p>
        <div className="flex flex-wrap items-center gap-3">
          {enregistre && !enCours && (
            <span className="text-sm text-green-700">Enregistré ✓</span>
          )}
          <Button
            type="button"
            variant="outline"
            disabled={enCours || confirmeSoumission}
            onClick={() => {
              setErreur(null);
              setConfirmeSoumission(true);
            }}
          >
            Soumettre à la direction
          </Button>
          <Button
            type="button"
            disabled={enCours || confirmeSoumission}
            onClick={enregistrer}
          >
            {enCours ? "Enregistrement…" : "Enregistrer le chiffrage"}
          </Button>
        </div>
      </div>

      {confirmeSoumission && (
        <div className="flex flex-col gap-3 rounded-md border border-amber-200 bg-amber-50 px-4 py-3">
          <p className="text-sm text-amber-900">
            Une fois soumis, le chiffrage ne sera plus modifiable et la
            direction sera invitée à le valider ou le refuser. Les postes
            saisis seront enregistrés avant l&apos;envoi.
          </p>
          <div className="flex flex-wrap items-center gap-3">
            <Button type="button" size="sm" disabled={enCours} onClick={soumettre}>
              {enCours ? "Soumission…" : "Confirmer la soumission"}
            </Button>
            <Button
              type="button"
              size="sm"
              variant="ghost"
              disabled={enCours}
              onClick={() => setConfirmeSoumission(false)}
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
