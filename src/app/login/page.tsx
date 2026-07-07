"use client";

import Image from "next/image";
import { useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    setLoading(true);

    const supabase = createClient();
    const { error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });

    if (error) {
      setError(
        error.message === "Invalid login credentials"
          ? "E-mail ou mot de passe incorrect."
          : "Connexion impossible pour le moment. Réessayez dans un instant."
      );
      setLoading(false);
      return;
    }

    router.push("/");
    router.refresh();
  }

  return (
    <main className="flex flex-1 items-center justify-center px-6 py-16">
      <div className="flex w-full max-w-sm flex-col gap-6">
        <div className="flex items-center justify-center gap-3">
          <Image
            src="/logo-jpf.png"
            alt="JP Facilities"
            width={266}
            height={158}
            priority
            className="h-10 w-auto"
          />
          <span className="text-left text-sm font-medium uppercase leading-tight tracking-[0.18em] text-muted-foreground">
            JP
            <br />
            Facilities
          </span>
        </div>
        <Card className="w-full border-t-4 border-t-primary shadow-md">
          <CardHeader className="text-center">
            <CardTitle className="text-2xl">Suivi des travaux</CardTitle>
            <CardDescription>
              Connectez-vous avec le compte fourni par votre administrateur.
            </CardDescription>
          </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit} className="flex flex-col gap-5">
            <div className="flex flex-col gap-2">
              <Label htmlFor="email">Adresse e-mail</Label>
              <Input
                id="email"
                type="email"
                autoComplete="email"
                placeholder="prenom.nom@exemple.fr"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
              />
            </div>
            <div className="flex flex-col gap-2">
              <Label htmlFor="password">Mot de passe</Label>
              <Input
                id="password"
                type="password"
                autoComplete="current-password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
              />
            </div>
            {error && (
              <p className="rounded-md border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-700">
                {error}
              </p>
            )}
              <Button type="submit" size="lg" disabled={loading}>
                {loading ? "Connexion…" : "Se connecter"}
              </Button>
            </form>
          </CardContent>
        </Card>
      </div>
    </main>
  );
}
