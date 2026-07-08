"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { getProfilConnecte, peutChiffrer } from "@/lib/auth";
import { UNITES, type LigneSaisie } from "@/lib/chiffrages";

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
    // P0001 : message levé par la fonction SQL elle-même (déjà en clair,
    // ex. « Un chiffrage en brouillon existe déjà pour ce travail. »)
    if (error?.code === "P0001") {
      return { error: error.message };
    }
    // PGRST2xx : l'API Supabase ne connaît pas (encore) la fonction —
    // migration 0004 pas exécutée, ou cache pas encore rafraîchi.
    if (error?.code?.startsWith("PGRST")) {
      return {
        error:
          "La base de données n'est pas encore prête (migration 0004). Si vous venez de l'exécuter, attendez quelques secondes puis réessayez.",
      };
    }
    console.error("creer_chiffrage :", error);
    return {
      error: `Création du chiffrage impossible (détail technique : ${
        error ? `${error.code ?? "?"} — ${error.message}` : "réponse vide"
      }).`,
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
      !Number.isFinite(ligne.quantite) ||
      ligne.quantite < 0 ||
      ligne.quantite >= 1_000_000
    ) {
      return { error: `Quantité invalide pour « ${libelle} ».` };
    }
    if (!UNITES.includes(ligne.unite)) {
      return { error: `Unité invalide pour « ${libelle} ».` };
    }
    if (
      !Number.isFinite(ligne.prix_unitaire) ||
      ligne.prix_unitaire < 0 ||
      ligne.prix_unitaire >= 1_000_000_000
    ) {
      return { error: `Prix unitaire invalide pour « ${libelle} ».` };
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
      quantite: l.quantite,
      unite: l.unite,
      prix_unitaire: l.prix_unitaire,
    })),
  });

  if (error) {
    return { error: "Enregistrement impossible. Réessayez dans un instant." };
  }

  revalidatePath(`/travaux/${travailId}`);
  revalidatePath(`/travaux/${travailId}/chiffrages/${chiffrageId}`);
  return {};
}
