import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { getProfilConnecte, peutGererTravaux } from "@/lib/auth";
import { AppHeader } from "@/components/app-header";
import { TravailForm } from "../travail-form";
import { creerTravail } from "../actions";

export default async function NouveauTravailPage() {
  const profil = await getProfilConnecte();
  if (!peutGererTravaux(profil.role)) {
    redirect("/travaux");
  }

  const supabase = await createClient();
  const [{ data: batiments }, { data: responsables }] = await Promise.all([
    supabase.from("batiments").select("id, nom").eq("actif", true).order("nom"),
    supabase.from("profiles").select("id, full_name").order("full_name"),
  ]);

  return (
    <div className="flex flex-1 flex-col">
      <AppHeader fullName={profil.fullName} role={profil.role} />
      <main className="mx-auto flex w-full max-w-2xl flex-1 flex-col gap-6 px-4 py-6 sm:px-6">
        <div>
          <h1 className="text-2xl font-semibold tracking-tight">
            Nouveau travail
          </h1>
          <p className="text-sm text-muted-foreground">
            Le travail sera créé au statut « À chiffrer ».
          </p>
        </div>
        <TravailForm
          action={creerTravail}
          batiments={batiments ?? []}
          responsables={responsables ?? []}
          libelleBouton="Créer le travail"
          lienAnnuler="/travaux"
        />
      </main>
    </div>
  );
}
