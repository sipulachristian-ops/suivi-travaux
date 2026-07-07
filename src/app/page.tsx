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

export default async function Home() {
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

  const displayName = profile?.full_name || user.email;
  const roleLabel = profile
    ? ROLE_LABELS[profile.role as UserRole]
    : "Rôle non défini";

  return (
    <div className="flex flex-1 flex-col">
      <header className="flex items-center justify-between border-b px-6 py-4">
        <span className="font-semibold">Suivi des travaux</span>
        <form action={signOut}>
          <Button variant="outline" size="sm" type="submit">
            Se déconnecter
          </Button>
        </form>
      </header>
      <main className="flex flex-1 flex-col items-center justify-center gap-4 px-6 py-16 text-center">
        <span className="rounded-full border px-3 py-1 text-xs font-medium uppercase tracking-wide text-muted-foreground">
          {roleLabel}
        </span>
        <h1 className="text-3xl font-semibold tracking-tight sm:text-4xl">
          Bonjour {displayName}
        </h1>
        <p className="max-w-md text-muted-foreground">
          Vous êtes connecté. La gestion des travaux arrive à l&apos;étape 2 de
          la feuille de route.
        </p>
      </main>
    </div>
  );
}
