"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { getProfilConnecte, peutGererTravaux } from "@/lib/auth";
import {
  STATUTS_ORDONNES,
  STATUTS_RESERVES_DIRECTION,
  STATUT_LABELS,
  type StatutTravail,
} from "@/lib/travaux";

export type ActionResult = { error: string } | undefined;

function lireChamps(formData: FormData) {
  const titre = String(formData.get("titre") ?? "").trim();
  const batimentId = String(formData.get("batiment_id") ?? "");
  const nature = String(formData.get("nature") ?? "").trim();
  const description = String(formData.get("description") ?? "").trim();
  const priorite = String(formData.get("priorite") ?? "normale");
  const echeance = String(formData.get("echeance") ?? "");
  const responsableId = String(formData.get("responsable_id") ?? "");

  return {
    titre,
    batiment_id: batimentId,
    nature,
    description,
    priorite,
    echeance: echeance || null,
    responsable_id: responsableId || null,
  };
}

export async function creerTravail(
  _prev: ActionResult,
  formData: FormData
): Promise<ActionResult> {
  const profil = await getProfilConnecte();
  if (!peutGererTravaux(profil.role)) {
    return { error: "Votre rôle ne permet pas de créer un travail." };
  }

  const champs = lireChamps(formData);
  if (!champs.titre) return { error: "L'intitulé est obligatoire." };
  if (!champs.batiment_id) return { error: "Le bâtiment est obligatoire." };

  const supabase = await createClient();
  const { data, error } = await supabase
    .from("travaux")
    .insert({ ...champs, cree_par: profil.id })
    .select("id")
    .single();

  if (error) {
    return { error: "Enregistrement impossible. Réessayez dans un instant." };
  }

  revalidatePath("/travaux");
  redirect(`/travaux/${data.id}`);
}

export async function modifierTravail(
  travailId: string,
  _prev: ActionResult,
  formData: FormData
): Promise<ActionResult> {
  const profil = await getProfilConnecte();
  if (!peutGererTravaux(profil.role)) {
    return { error: "Votre rôle ne permet pas de modifier un travail." };
  }

  const champs = lireChamps(formData);
  if (!champs.titre) return { error: "L'intitulé est obligatoire." };
  if (!champs.batiment_id) return { error: "Le bâtiment est obligatoire." };

  const supabase = await createClient();
  const { error } = await supabase
    .from("travaux")
    .update(champs)
    .eq("id", travailId);

  if (error) {
    return { error: "Modification impossible. Réessayez dans un instant." };
  }

  revalidatePath("/travaux");
  revalidatePath(`/travaux/${travailId}`);
  redirect(`/travaux/${travailId}`);
}

// Change le statut d'un travail (Kanban ou fiche) et journalise le
// changement dans travaux_historique — via la fonction SQL
// changer_statut_travail (les deux écritures passent ensemble).
export async function changerStatutTravail(
  travailId: string,
  nouveauStatut: StatutTravail
): Promise<{ error?: string }> {
  const profil = await getProfilConnecte();
  if (!peutGererTravaux(profil.role)) {
    return { error: "Votre rôle ne permet pas de changer le statut." };
  }
  if (!STATUTS_ORDONNES.includes(nouveauStatut)) {
    return { error: "Statut inconnu." };
  }
  if (
    STATUTS_RESERVES_DIRECTION.includes(nouveauStatut) &&
    profil.role !== "direction"
  ) {
    return {
      error: `Seule la direction peut passer un travail en « ${STATUT_LABELS[nouveauStatut]} ».`,
    };
  }

  const supabase = await createClient();
  const { error } = await supabase.rpc("changer_statut_travail", {
    p_travail_id: travailId,
    p_nouveau_statut: nouveauStatut,
  });

  if (error) {
    return { error: "Changement de statut impossible. Réessayez dans un instant." };
  }

  revalidatePath("/travaux");
  revalidatePath(`/travaux/${travailId}`);
  return {};
}
