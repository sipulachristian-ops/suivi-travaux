// Types et petits utilitaires des notifications, partagés entre le
// serveur (requêtes dans notifications-server.ts) et la cloche (client).

export type Notification = {
  id: string;
  titre: string;
  message: string;
  lien: string;
  lue_le: string | null;
  created_at: string;
};

// Alerte d'échéance calculée en direct (pas stockée) : travaux dont
// l'échéance est dépassée ou tombe dans les 7 prochains jours.
export type AlerteEcheance = {
  id: string;
  numero: number;
  titre: string;
  echeance: string;
  enRetard: boolean;
};

export type Alertes = {
  notifications: Notification[];
  nonLues: number;
  echeances: AlerteEcheance[];
  // true si la table notifications n'existe pas encore (migration 0007)
  migrationManquante: boolean;
};

// « il y a 5 min », « il y a 3 h », « hier », « le 12 juin »
export function formatRelatifFr(iso: string): string {
  const date = new Date(iso);
  const ecartMs = Date.now() - date.getTime();
  const minutes = Math.floor(ecartMs / 60_000);
  if (minutes < 1) return "à l'instant";
  if (minutes < 60) return `il y a ${minutes} min`;
  const heures = Math.floor(minutes / 60);
  if (heures < 24) return `il y a ${heures} h`;
  const jours = Math.floor(heures / 24);
  if (jours === 1) return "hier";
  if (jours < 7) return `il y a ${jours} jours`;
  return new Intl.DateTimeFormat("fr-FR", { dateStyle: "medium" }).format(date);
}
