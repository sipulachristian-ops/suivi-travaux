"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import {
  getProfilConnecte,
  peutChiffrer,
  peutValiderChiffrage,
} from "@/lib/auth";
import { UNITES, type LigneSaisie } from "@/lib/chiffrages";
import { envoyerEmailNotification } from "@/lib/email";

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

// Traduit les erreurs des fonctions SQL du workflow en message clair.
function messageErreurWorkflow(
  error: { code?: string; message: string } | null,
  action: string
): string {
  // P0001 : message levé par la fonction SQL elle-même (déjà en clair)
  if (error?.code === "P0001") {
    return error.message;
  }
  // PGRST2xx : l'API Supabase ne connaît pas (encore) la fonction —
  // migration 0006 pas exécutée, ou cache pas encore rafraîchi.
  if (error?.code?.startsWith("PGRST")) {
    return "La base de données n'est pas encore prête (migration 0006). Si vous venez de l'exécuter, attendez quelques secondes puis réessayez.";
  }
  console.error(`${action} :`, error);
  return `${action} impossible (détail technique : ${
    error ? `${error.code ?? "?"} — ${error.message}` : "réponse vide"
  }).`;
}

// Soumet un chiffrage à la direction via la fonction SQL
// soumettre_chiffrage : le chiffrage est figé (plus modifiable) et le
// travail passe « En attente de validation », le tout journalisé.
export async function soumettreChiffrage(
  chiffrageId: string,
  travailId: string
): Promise<{ error?: string }> {
  const profil = await getProfilConnecte();
  if (!peutChiffrer(profil.role)) {
    return { error: "Votre rôle ne permet pas de soumettre un chiffrage." };
  }

  const supabase = await createClient();
  const { error } = await supabase.rpc("soumettre_chiffrage", {
    p_chiffrage_id: chiffrageId,
  });

  if (error) {
    return { error: messageErreurWorkflow(error, "Soumission") };
  }

  // E-mail à la direction (en plus de la notification dans l'app).
  // Toute erreur ici est ignorée : l'e-mail ne bloque jamais le workflow.
  try {
    const [travailRes, directionRes] = await Promise.all([
      supabase
        .from("travaux")
        .select("numero, titre")
        .eq("id", travailId)
        .single(),
      supabase
        .from("profiles")
        .select("email")
        .eq("role", "direction")
        .neq("id", profil.id)
        .neq("email", ""),
    ]);

    const travail = travailRes.data;
    const emails = (directionRes.data ?? []).map((p) => p.email);
    if (travail && emails.length > 0) {
      await envoyerEmailNotification({
        to: emails,
        sujet: `Chiffrage à valider — T-${travail.numero} ${travail.titre}`,
        titre: "Un chiffrage attend votre validation",
        corps: `${profil.fullName} a soumis un chiffrage pour la demande T-${travail.numero} — ${travail.titre}.`,
        lien: `/travaux/${travailId}/chiffrages/${chiffrageId}`,
        lienTexte: "Voir le chiffrage",
      });
    }
  } catch (erreur) {
    console.error("E-mail de soumission non envoyé :", erreur);
  }

  revalidatePath("/travaux");
  revalidatePath(`/travaux/${travailId}`);
  revalidatePath(`/travaux/${travailId}/chiffrages/${chiffrageId}`);
  return {};
}

// Valide ou refuse un chiffrage soumis, via la fonction SQL
// decider_chiffrage. Règle métier : seule la direction décide, et un
// refus est toujours motivé. Le statut du travail suit la décision.
export async function deciderChiffrage(
  chiffrageId: string,
  travailId: string,
  decision: "valide" | "refuse",
  motif: string
): Promise<{ error?: string }> {
  const profil = await getProfilConnecte();
  if (!peutValiderChiffrage(profil.role)) {
    return { error: "Seule la direction peut valider ou refuser un chiffrage." };
  }

  const motifPropre = String(motif ?? "").trim();
  if (decision === "refuse" && !motifPropre) {
    return { error: "Indiquez le motif du refus." };
  }
  if (motifPropre.length > 2000) {
    return { error: "Le motif est trop long (2000 caractères maximum)." };
  }

  const supabase = await createClient();
  const { error } = await supabase.rpc("decider_chiffrage", {
    p_chiffrage_id: chiffrageId,
    p_decision: decision,
    p_motif: motifPropre,
  });

  if (error) {
    return { error: messageErreurWorkflow(error, "Décision") };
  }

  // E-mail à la personne qui a soumis (en plus de la notification).
  // Toute erreur ici est ignorée : l'e-mail ne bloque jamais le workflow.
  try {
    const [travailRes, chiffrageRes] = await Promise.all([
      supabase
        .from("travaux")
        .select("numero, titre")
        .eq("id", travailId)
        .single(),
      supabase
        .from("chiffrages")
        .select("soumis_par, auteur_soumission:profiles!chiffrages_soumis_par_fkey(email)")
        .eq("id", chiffrageId)
        .single(),
    ]);

    const travail = travailRes.data;
    const soumisPar = chiffrageRes.data?.soumis_par as string | null;
    const email = (
      chiffrageRes.data?.auteur_soumission as { email?: string } | null
    )?.email;

    if (travail && email && soumisPar && soumisPar !== profil.id) {
      const validee = decision === "valide";
      await envoyerEmailNotification({
        to: [email],
        sujet: `Chiffrage ${validee ? "validé" : "refusé"} — T-${travail.numero} ${travail.titre}`,
        titre: validee
          ? "Votre chiffrage a été validé"
          : "Votre chiffrage a été refusé",
        corps: validee
          ? `La direction a validé votre chiffrage pour la demande T-${travail.numero} — ${travail.titre}.`
          : `La direction a refusé votre chiffrage pour la demande T-${travail.numero} — ${travail.titre}. Motif : ${motifPropre}`,
        lien: `/travaux/${travailId}/chiffrages/${chiffrageId}`,
        lienTexte: "Voir la décision",
      });
    }
  } catch (erreur) {
    console.error("E-mail de décision non envoyé :", erreur);
  }

  revalidatePath("/travaux");
  revalidatePath(`/travaux/${travailId}`);
  revalidatePath(`/travaux/${travailId}/chiffrages/${chiffrageId}`);
  return {};
}
