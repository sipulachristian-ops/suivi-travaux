import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import type { UserRole } from "@/lib/roles";

export type ProfilConnecte = {
  id: string;
  email: string;
  fullName: string;
  role: UserRole;
};

// Récupère l'utilisateur connecté et son profil ; redirige vers /login sinon.
export async function getProfilConnecte(): Promise<ProfilConnecte> {
  const supabase = await createClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    redirect("/login");
  }

  const { data: profile } = await supabase
    .from("profiles")
    .select("full_name, role")
    .eq("id", user.id)
    .single();

  return {
    id: user.id,
    email: user.email ?? "",
    fullName: profile?.full_name || user.email || "",
    role: (profile?.role as UserRole) ?? "responsable_travaux",
  };
}

// Rôles autorisés à créer et modifier des travaux (décision actée).
export const ROLES_GESTION_TRAVAUX: UserRole[] = [
  "direction",
  "responsable_travaux",
  "admin",
];

export function peutGererTravaux(role: UserRole): boolean {
  return ROLES_GESTION_TRAVAUX.includes(role);
}

// Rôles autorisés à créer et modifier un chiffrage (décision actée le
// 2026-07-08 : la direction chiffre aussi, en plus du responsable
// d'affaires et de l'admin).
export const ROLES_CHIFFRAGE: UserRole[] = [
  "direction",
  "responsable_affaires",
  "admin",
];

export function peutChiffrer(role: UserRole): boolean {
  return ROLES_CHIFFRAGE.includes(role);
}
