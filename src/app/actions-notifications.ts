"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import { getProfilConnecte } from "@/lib/auth";

// Marque comme lues les notifications de l'utilisateur connecté :
// toutes (sans argument) ou une liste précise. La fonction SQL ne
// touche que les notifications dont il est le destinataire.
export async function marquerNotificationsLues(
  ids?: string[]
): Promise<{ error?: string }> {
  await getProfilConnecte();

  if (ids && (!Array.isArray(ids) || ids.length > 100)) {
    return { error: "Liste de notifications invalide." };
  }

  const supabase = await createClient();
  const { error } = await supabase.rpc("marquer_notifications_lues", {
    p_ids: ids ?? null,
  });

  if (error) {
    // Migration 0007 pas encore exécutée : rien à marquer, pas d'alarme.
    if (error.code?.startsWith("PGRST")) return {};
    console.error("marquer_notifications_lues :", error);
    return { error: "Impossible de marquer les notifications comme lues." };
  }

  revalidatePath("/", "layout");
  return {};
}
