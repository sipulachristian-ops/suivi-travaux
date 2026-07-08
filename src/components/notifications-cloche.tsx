"use client";

import { useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { Bell, CalendarClock } from "lucide-react";
import { marquerNotificationsLues } from "@/app/actions-notifications";
import {
  formatRelatifFr,
  type AlerteEcheance,
  type Notification,
} from "@/lib/notifications";
import { formatDateFr } from "@/lib/travaux";
import { cn } from "@/lib/utils";

export function NotificationsCloche({
  notifications,
  nonLues,
  echeances,
  migrationManquante,
}: {
  notifications: Notification[];
  nonLues: number;
  echeances: AlerteEcheance[];
  migrationManquante: boolean;
}) {
  const [ouvert, setOuvert] = useState(false);
  const [, startTransition] = useTransition();
  const router = useRouter();

  // Le compteur réunit tout ce qui demande attention : notifications
  // non lues + échéances proches ou dépassées.
  const compteur = nonLues + echeances.length;
  const retards = echeances.filter((e) => e.enRetard).length;

  function ouvrirNotification(notification: Notification) {
    setOuvert(false);
    startTransition(async () => {
      if (!notification.lue_le) {
        await marquerNotificationsLues([notification.id]);
      }
      if (notification.lien) router.push(notification.lien);
    });
  }

  function toutMarquerLu() {
    startTransition(async () => {
      await marquerNotificationsLues();
    });
  }

  return (
    <div className="relative">
      <button
        type="button"
        onClick={() => setOuvert((v) => !v)}
        aria-label={
          compteur > 0 ? `Notifications (${compteur})` : "Notifications"
        }
        className="relative flex size-9 items-center justify-center rounded-md text-muted-foreground transition-colors hover:bg-accent hover:text-foreground"
      >
        <Bell className="size-[18px]" />
        {compteur > 0 && (
          <span
            className={cn(
              "absolute -right-0.5 -top-0.5 flex h-4 min-w-4 items-center justify-center rounded-full px-1 text-[10px] font-semibold text-white",
              retards > 0 || nonLues > 0 ? "bg-red-500" : "bg-amber-500"
            )}
          >
            {compteur > 9 ? "9+" : compteur}
          </span>
        )}
      </button>

      {ouvert && (
        <>
          {/* Clic hors du panneau : on referme */}
          <div
            className="fixed inset-0 z-20"
            onClick={() => setOuvert(false)}
          />
          <div className="absolute right-0 z-30 mt-2 flex w-[min(92vw,24rem)] flex-col overflow-hidden rounded-xl border bg-card shadow-lg">
            <div className="flex items-center justify-between gap-3 border-b px-4 py-2.5">
              <p className="text-sm font-semibold">Notifications</p>
              {nonLues > 0 && (
                <button
                  type="button"
                  onClick={toutMarquerLu}
                  className="text-xs font-medium text-primary hover:underline"
                >
                  Tout marquer comme lu
                </button>
              )}
            </div>

            <div className="max-h-[70vh] overflow-y-auto">
              {/* Échéances proches ou dépassées (calculées en direct) */}
              {echeances.length > 0 && (
                <div className="border-b">
                  <p className="px-4 pb-1 pt-3 text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">
                    Échéances à surveiller
                  </p>
                  {echeances.map((e) => (
                    <button
                      key={e.id}
                      type="button"
                      onClick={() => {
                        setOuvert(false);
                        router.push(`/travaux/${e.id}`);
                      }}
                      className="flex w-full items-start gap-3 px-4 py-2.5 text-left transition-colors hover:bg-accent/50"
                    >
                      <CalendarClock
                        className={cn(
                          "mt-0.5 size-4 shrink-0",
                          e.enRetard ? "text-red-500" : "text-amber-500"
                        )}
                      />
                      <span className="min-w-0">
                        <span className="block truncate text-sm font-medium">
                          <span className="font-mono text-xs text-primary">
                            T-{e.numero}
                          </span>{" "}
                          {e.titre}
                        </span>
                        <span
                          className={cn(
                            "block text-xs",
                            e.enRetard
                              ? "font-medium text-red-600"
                              : "text-muted-foreground"
                          )}
                        >
                          {e.enRetard
                            ? `En retard — échéance ${formatDateFr(e.echeance)}`
                            : `Échéance ${formatDateFr(e.echeance)}`}
                        </span>
                      </span>
                    </button>
                  ))}
                </div>
              )}

              {/* Notifications (chiffrages soumis, décisions…) */}
              {notifications.length === 0 ? (
                <p className="px-4 py-6 text-sm text-muted-foreground">
                  {migrationManquante
                    ? "Les notifications seront actives une fois la migration 0007 exécutée dans Supabase."
                    : "Aucune notification pour le moment."}
                </p>
              ) : (
                notifications.map((n) => (
                  <button
                    key={n.id}
                    type="button"
                    onClick={() => ouvrirNotification(n)}
                    className={cn(
                      "flex w-full items-start gap-3 px-4 py-3 text-left transition-colors hover:bg-accent/50",
                      !n.lue_le && "bg-primary/5"
                    )}
                  >
                    <span
                      className={cn(
                        "mt-1.5 size-2 shrink-0 rounded-full",
                        n.lue_le ? "bg-transparent" : "bg-primary"
                      )}
                    />
                    <span className="min-w-0">
                      <span
                        className={cn(
                          "block text-sm",
                          n.lue_le ? "font-medium" : "font-semibold"
                        )}
                      >
                        {n.titre}
                      </span>
                      <span className="block text-xs leading-relaxed text-muted-foreground">
                        {n.message}
                      </span>
                      <span className="mt-0.5 block text-[11px] text-muted-foreground/70">
                        {formatRelatifFr(n.created_at)}
                      </span>
                    </span>
                  </button>
                ))
              )}
            </div>
          </div>
        </>
      )}
    </div>
  );
}
