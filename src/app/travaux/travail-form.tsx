"use client";

import { useActionState } from "react";
import Link from "next/link";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { PRIORITE_LABELS } from "@/lib/travaux";
import type { ActionResult } from "./actions";

const selectClass =
  "h-9 w-full rounded-md border border-input bg-transparent px-3 text-sm shadow-xs outline-none focus-visible:border-ring focus-visible:ring-ring/50 focus-visible:ring-[3px]";

export type TravailFormValues = {
  titre?: string;
  nature?: string;
  description?: string;
  batiment_id?: string;
  priorite?: string;
  echeance?: string | null;
  responsable_id?: string | null;
};

export function TravailForm({
  action,
  batiments,
  responsables,
  valeurs = {},
  libelleBouton,
  lienAnnuler,
}: {
  action: (prev: ActionResult, formData: FormData) => Promise<ActionResult>;
  batiments: { id: string; nom: string }[];
  responsables: { id: string; full_name: string }[];
  valeurs?: TravailFormValues;
  libelleBouton: string;
  lienAnnuler: string;
}) {
  const [state, formAction, pending] = useActionState(action, undefined);

  return (
    <form
      action={formAction}
      className="flex flex-col gap-5 rounded-xl border bg-card p-5 shadow-sm"
    >
      <div className="flex flex-col gap-2">
        <Label htmlFor="titre">Intitulé *</Label>
        <Input
          id="titre"
          name="titre"
          placeholder="Ex. : Remplacement de la chaudière"
          defaultValue={valeurs.titre ?? ""}
          required
        />
      </div>

      <div className="grid gap-5 sm:grid-cols-2">
        <div className="flex flex-col gap-2">
          <Label htmlFor="batiment_id">Bâtiment *</Label>
          <select
            id="batiment_id"
            name="batiment_id"
            className={selectClass}
            defaultValue={valeurs.batiment_id ?? ""}
            required
          >
            <option value="" disabled>
              Choisir un bâtiment…
            </option>
            {batiments.map((b) => (
              <option key={b.id} value={b.id}>
                {b.nom}
              </option>
            ))}
          </select>
        </div>
        <div className="flex flex-col gap-2">
          <Label htmlFor="nature">Nature du travail</Label>
          <Input
            id="nature"
            name="nature"
            placeholder="Ex. : Plomberie, Électricité…"
            defaultValue={valeurs.nature ?? ""}
          />
        </div>
      </div>

      <div className="flex flex-col gap-2">
        <Label htmlFor="description">Description</Label>
        <Textarea
          id="description"
          name="description"
          rows={4}
          placeholder="Décrivez le besoin : localisation précise, symptômes, contraintes…"
          defaultValue={valeurs.description ?? ""}
        />
      </div>

      <div className="grid gap-5 sm:grid-cols-3">
        <div className="flex flex-col gap-2">
          <Label htmlFor="priorite">Priorité</Label>
          <select
            id="priorite"
            name="priorite"
            className={selectClass}
            defaultValue={valeurs.priorite ?? "normale"}
          >
            {Object.entries(PRIORITE_LABELS).map(([valeur, label]) => (
              <option key={valeur} value={valeur}>
                {label}
              </option>
            ))}
          </select>
        </div>
        <div className="flex flex-col gap-2">
          <Label htmlFor="echeance">Échéance souhaitée</Label>
          <Input
            id="echeance"
            name="echeance"
            type="date"
            defaultValue={valeurs.echeance ?? ""}
          />
        </div>
        <div className="flex flex-col gap-2">
          <Label htmlFor="responsable_id">Responsable</Label>
          <select
            id="responsable_id"
            name="responsable_id"
            className={selectClass}
            defaultValue={valeurs.responsable_id ?? ""}
          >
            <option value="">Non attribué</option>
            {responsables.map((r) => (
              <option key={r.id} value={r.id}>
                {r.full_name || "(sans nom)"}
              </option>
            ))}
          </select>
        </div>
      </div>

      {state?.error && (
        <p className="rounded-md border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-700">
          {state.error}
        </p>
      )}

      <div className="flex items-center gap-3">
        <Button type="submit" disabled={pending}>
          {pending ? "Enregistrement…" : libelleBouton}
        </Button>
        <Button variant="ghost" render={<Link href={lienAnnuler} />}>
          Annuler
        </Button>
      </div>
    </form>
  );
}
