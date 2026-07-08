import { createClient } from "@/lib/supabase/server";
import { estEnRetard, type StatutTravail } from "@/lib/travaux";
import { peutGererTravaux } from "@/lib/auth";
import type { UserRole } from "@/lib/roles";
import type { Alertes, AlerteEcheance, Notification } from "@/lib/notifications";

const JOURS_ECHEANCE_PROCHE = 7;

// Rassemble tout ce que la cloche affiche pour l'utilisateur connecté.
export async function getAlertes(role: UserRole): Promise<Alertes> {
  const supabase = await createClient();

  const dansSeptJours = new Date();
  dansSeptJours.setDate(dansSeptJours.getDate() + JOURS_ECHEANCE_PROCHE);
  const borne = dansSeptJours.toISOString().slice(0, 10);

  const [notifsRes, nonLuesRes, echeancesRes] = await Promise.all([
    supabase
      .from("notifications")
      .select("id, titre, message, lien, lue_le, created_at")
      .order("created_at", { ascending: false })
      .limit(15),
    supabase
      .from("notifications")
      .select("id", { count: "exact", head: true })
      .is("lue_le", null),
    // Échéances : pour les rôles qui gèrent les travaux (PRD §5.5)
    peutGererTravaux(role)
      ? supabase
          .from("travaux")
          .select("id, numero, titre, statut, echeance")
          .not("echeance", "is", null)
          .lte("echeance", borne)
          .not("statut", "in", "(termine,refuse)")
          .order("echeance", { ascending: true })
          .limit(10)
      : Promise.resolve({ data: [] as never[], error: null }),
  ]);

  const echeances: AlerteEcheance[] = (echeancesRes.data ?? [])
    .map(
      (t: {
        id: string;
        numero: number;
        titre: string;
        statut: StatutTravail;
        echeance: string | null;
      }) => ({
        id: t.id,
        numero: t.numero,
        titre: t.titre,
        echeance: t.echeance ?? "",
        enRetard: estEnRetard(t.echeance, t.statut),
      })
    )
    .filter((t) => t.echeance !== "");

  // Table absente (migration 0007 pas encore exécutée) : la cloche
  // fonctionne quand même, avec les seules échéances.
  if (notifsRes.error) {
    return {
      notifications: [],
      nonLues: 0,
      echeances,
      migrationManquante: true,
    };
  }

  return {
    notifications: (notifsRes.data ?? []) as Notification[],
    nonLues: nonLuesRes.count ?? 0,
    echeances,
    migrationManquante: false,
  };
}
