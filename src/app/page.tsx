import { redirect } from "next/navigation";

// L'écran principal de l'application est la liste des travaux.
export default function Home() {
  redirect("/travaux");
}
