export type UserRole =
  | "direction"
  | "responsable_travaux"
  | "responsable_affaires"
  | "admin";

export const ROLE_LABELS: Record<UserRole, string> = {
  direction: "Direction",
  responsable_travaux: "Responsable travaux",
  responsable_affaires: "Responsable d'affaires",
  admin: "Administrateur",
};
