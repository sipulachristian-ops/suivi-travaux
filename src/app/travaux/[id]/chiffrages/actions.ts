"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { getProfilConnecte, peutChiffrer } from "@/lib/auth";
import type { LigneSaisie } from "@/lib/chiffrages";

// Crée un chiffrage (version suivante) pour un travail, via la fonction
// SQL creer_chiffrage : numéro de version + passage éventuel du travail
// en « Chiffrage en cours », le tout en une seule opération.
export async function creerChiffrage(
  travailId: string
): Promise<{ error?: string }> {
  const profil = await getProfilConnecte();
  if (!peutChiffrer(profil.role)) {
    return { error: "Votre rôle ne permet pas de chiffrer." };
  }

  const supabase = await createClient();
  const { data, error } = await supabase.rpc("creer_chiffrage", {
    p_travail_id: travailId,
  });

  if (error || !data) {
    return {
      error:
        "Création du chiffrage impossible. Vérifiez qu'aucun brouillon n'existe déjà, puis réessayez.",
    };
  }

  revalidatePath("/travaux");
  revalidatePath(`/travaux/${travailId}`);
  redirect(`/travaux/${travailId}/chiffrages/${data}`);
}

// Enregistre les postes d'un chiffrage : les lignes sont remplacées en
// bloc par la fonction SQL remplacer_lignes_chiffrage (atomique, RLS
// appliquée — rôles autorisés et chiffrage en brouillon uniquement).
export async function enregistrerLignes(
  chiffrageId: string,
  travailId: string,
  lignes: LigneSaisie[]
): Promise<{ error?: string }> {
  const profil = await getProfilConnecte();
  if (!peutChiffrer(profil.role)) {
    return { error: "Votre rôle ne permet pas de chiffrer." };
  }

  if (!Array.isArray(lignes) || lignes.length > 200) {
    return { error: "Liste de postes invalide." };
  }
  for (const ligne of lignes) {
    const libelle = String(ligne.libelle ?? "").trim();
    if (!libelle || libelle.length > 300) {
      return { error: "Chaque poste doit avoir un libellé." };
    }
    if (
      !Number.isFinite(ligne.montant) ||
      ligne.montant < 0 ||
      ligne.montant >= 1_000_000_000
    ) {
      return { error: `Montant invalide pour « ${libelle} ».` };
    }
    if (!Number.isFinite(ligne.heures) || ligne.heures < 0 || ligne.heures >= 100_000) {
      return { error: `Nombre d'heures invalide pour « ${libelle} ».` };
    }
  }

  const supabase = await createClient();

  // Un chiffrage validé ne se modifie jamais (règle PRD) — la RLS le
  // garantit déjà, on renvoie simplement un message clair.
  const { data: chiffrage } = await supabase
    .from("chiffrages")
    .select("statut")
    .eq("id", chiffrageId)
    .single();

  if (!chiffrage) {
    return { error: "Chiffrage introuvable." };
  }
  if (chiffrage.statut !== "brouillon") {
    return { error: "Ce chiffrage n'est plus en brouillon : il ne peut plus être modifié." };
  }

  const { error } = await supabase.rpc("remplacer_lignes_chiffrage", {
    p_chiffrage_id: chiffrageId,
    p_lignes: lignes.map((l) => ({
      libelle: String(l.libelle).trim(),
      montant: l.montant,
      heures: l.heures,
    })),
  });

  if (error) {
    return { error: "Enregistrement impossible. Réessayez dans un instant." };
  }

  revalidatePath(`/travaux/${travailId}`);
  revalidatePath(`/travaux/${travailId}/chiffrages/${chiffrageId}`);
  return {};
}
