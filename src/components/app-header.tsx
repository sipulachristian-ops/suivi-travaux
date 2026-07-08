import Image from "next/image";
import Link from "next/link";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { Button } from "@/components/ui/button";
import { ROLE_LABELS, type UserRole } from "@/lib/roles";

async function signOut() {
  "use server";
  const supabase = await createClient();
  await supabase.auth.signOut();
  redirect("/login");
}

export function AppHeader({
  fullName,
  role,
}: {
  fullName: string;
  role: UserRole;
}) {
  return (
    <header className="sticky top-0 z-10 border-b bg-card shadow-xs">
      {/* Liseré aux couleurs JP Facilities */}
      <div className="h-0.5 bg-primary" />
      <div className="mx-auto flex w-full max-w-6xl items-center justify-between gap-4 px-4 py-2.5 sm:px-6">
        <div className="flex items-center gap-4 sm:gap-6">
          <Link href="/travaux" className="flex items-center gap-3">
            <Image
              src="/logo-jpf.png"
              alt="JP Facilities"
              width={266}
              height={158}
              priority
              className="h-7 w-auto"
            />
            {/* Sur mobile, le texte cède la place aux liens de navigation */}
            <span className="hidden flex-col leading-tight sm:flex">
              <span className="font-semibold tracking-tight">
                Suivi des travaux
              </span>
              <span className="text-[10px] font-medium uppercase tracking-[0.18em] text-muted-foreground">
                JP Facilities
              </span>
            </span>
          </Link>
          <nav className="flex items-center gap-1 text-sm">
            <Link
              href="/tableau-de-bord"
              className="rounded-md px-2.5 py-1.5 font-medium text-muted-foreground transition-colors hover:bg-accent hover:text-foreground"
            >
              Tableau de bord
            </Link>
            <Link
              href="/travaux"
              className="rounded-md px-2.5 py-1.5 font-medium text-muted-foreground transition-colors hover:bg-accent hover:text-foreground"
            >
              Travaux
            </Link>
          </nav>
        </div>
        <div className="flex items-center gap-3">
          <div className="hidden text-right sm:block">
            <p className="text-sm font-medium leading-tight">{fullName}</p>
            <p className="text-xs text-accent-foreground">{ROLE_LABELS[role]}</p>
          </div>
          <form action={signOut}>
            <Button variant="outline" size="sm" type="submit">
              Se déconnecter
            </Button>
          </form>
        </div>
      </div>
    </header>
  );
}
