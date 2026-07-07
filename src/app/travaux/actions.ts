"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { getProfilConnecte, peutGererTravaux } from "@/lib/auth";

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
