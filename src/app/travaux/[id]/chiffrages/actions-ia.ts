"use server";

import Anthropic from "@anthropic-ai/sdk";
import { createClient } from "@/lib/supabase/server";
import { getProfilConnecte, peutChiffrer } from "@/lib/auth";
import { UNITES, type LigneSaisie, type Unite } from "@/lib/chiffrages";

// Étape 6a : Claude analyse la description du travail et propose des
// postes de chiffrage. L'IA propose, l'humain dispose (règle PRD) : la
// proposition pré-remplit l'éditeur, rien n'est enregistré sans action
// de l'utilisateur, et les prix restent indicatifs.

const SYSTEM_PROMPT = `Tu es économiste de la construction chez JP Facilities, spécialiste de la maintenance multitechnique de bâtiments en France (électricité, plomberie, CVC, serrurerie, second œuvre, espaces verts).

À partir de la demande de travaux fournie, tu proposes les postes d'un chiffrage :
- 3 à 12 postes, du plus important au moins important ;
- la main d'œuvre est exprimée en heures (unité « h ») avec un taux horaire réaliste, séparée des fournitures ;
- les fournitures sont en unités (« u »), les surfaces en « m2 », les longueurs en « ml », les prestations globales en « forfait » ;
- prix hors taxes, réalistes pour le marché français actuel — ce sont des ordres de grandeur indicatifs, jamais des prix fermes ;
- si des informations manquent, fais des hypothèses raisonnables et signale-les dans le commentaire.

Le commentaire fait au maximum 500 caractères, sans mise en forme : hypothèses retenues et points à vérifier.`;

// Schéma imposé à la réponse de Claude (sorties structurées) : la
// réponse est toujours un JSON valide de cette forme, pas de texte libre.
const SCHEMA_PROPOSITION = {
  type: "object",
  properties: {
    postes: {
      type: "array",
      items: {
        type: "object",
        properties: {
          libelle: { type: "string", description: "Intitulé court du poste" },
          quantite: { type: "number" },
          unite: { type: "string", enum: [...UNITES] },
          prix_unitaire: {
            type: "number",
            description: "Prix unitaire HT en euros",
          },
        },
        required: ["libelle", "quantite", "unite", "prix_unitaire"],
        additionalProperties: false,
      },
    },
    commentaire: {
      type: "string",
      description: "Hypothèses retenues et points à vérifier (500 caractères max)",
    },
  },
  required: ["postes", "commentaire"],
  additionalProperties: false,
} as const;

// Garde-fou : on ne fait jamais confiance aveuglément à la sortie du
// modèle — mêmes bornes que la validation d'enregistrement des postes.
function nettoyerPostes(brut: unknown): LigneSaisie[] {
  if (!Array.isArray(brut)) return [];
  const postes: LigneSaisie[] = [];
  for (const p of brut.slice(0, 50) as Array<Record<string, unknown>>) {
    const libelle = String(p?.libelle ?? "")
      .trim()
      .slice(0, 300);
    const quantite = Number(p?.quantite);
    const prixUnitaire = Number(p?.prix_unitaire);
    const unite = (UNITES as readonly string[]).includes(String(p?.unite))
      ? (p.unite as Unite)
      : "u";
    if (!libelle) continue;
    if (!Number.isFinite(quantite) || quantite < 0 || quantite >= 1_000_000)
      continue;
    if (
      !Number.isFinite(prixUnitaire) ||
      prixUnitaire < 0 ||
      prixUnitaire >= 1_000_000_000
    )
      continue;
    postes.push({
      libelle,
      quantite: Math.round(quantite * 1000) / 1000,
      unite,
      prix_unitaire: Math.round(prixUnitaire * 100) / 100,
    });
  }
  return postes;
}

export async function proposerChiffrageIA(travailId: string): Promise<{
  postes?: LigneSaisie[];
  commentaire?: string;
  error?: string;
}> {
  const profil = await getProfilConnecte();
  if (!peutChiffrer(profil.role)) {
    return { error: "Votre rôle ne permet pas de chiffrer." };
  }

  if (!process.env.ANTHROPIC_API_KEY) {
    return {
      error:
        "La clé API Anthropic n'est pas configurée (variable ANTHROPIC_API_KEY). Ajoutez-la dans .env.local en local, et dans les variables d'environnement Vercel en production.",
    };
  }

  const supabase = await createClient();
  const { data: travail } = await supabase
    .from("travaux")
    .select(
      "numero, titre, nature, description, priorite, echeance, batiment:batiments(nom, adresse)"
    )
    .eq("id", travailId)
    .single();

  if (!travail) {
    return { error: "Travail introuvable." };
  }

  const batiment = travail.batiment as unknown as {
    nom: string;
    adresse: string;
  } | null;

  const demande = [
    `Demande T-${travail.numero} : ${travail.titre}`,
    travail.nature ? `Nature : ${travail.nature}` : null,
    batiment ? `Bâtiment : ${batiment.nom} — ${batiment.adresse}` : null,
    `Priorité : ${travail.priorite}`,
    travail.echeance ? `Échéance : ${travail.echeance}` : null,
    "",
    "Description :",
    travail.description?.trim() ||
      "(pas de description — appuie-toi sur le titre et la nature)",
    "",
    "Propose les postes du chiffrage.",
  ]
    .filter((l) => l !== null)
    .join("\n");

  try {
    const anthropic = new Anthropic();
    const reponse = await anthropic.messages.create({
      model: "claude-opus-4-8",
      max_tokens: 16000,
      thinking: { type: "adaptive" },
      system: SYSTEM_PROMPT,
      messages: [{ role: "user", content: demande }],
      output_config: {
        format: { type: "json_schema", schema: SCHEMA_PROPOSITION },
      },
    });

    const bloc = reponse.content.find(
      (b): b is Anthropic.TextBlock => b.type === "text"
    );
    if (!bloc) {
      return { error: "L'IA n'a pas renvoyé de proposition. Réessayez." };
    }

    const proposition = JSON.parse(bloc.text) as {
      postes?: unknown;
      commentaire?: unknown;
    };
    const postes = nettoyerPostes(proposition.postes);
    if (postes.length === 0) {
      return {
        error:
          "L'IA n'a pas pu proposer de postes exploitables. Complétez la description de la demande puis réessayez.",
      };
    }

    return {
      postes,
      commentaire: String(proposition.commentaire ?? "").slice(0, 1000),
    };
  } catch (e) {
    if (e instanceof Anthropic.AuthenticationError) {
      return {
        error:
          "La clé API Anthropic est invalide ou révoquée. Vérifiez la variable ANTHROPIC_API_KEY.",
      };
    }
    if (e instanceof Anthropic.RateLimitError) {
      return {
        error:
          "Le service IA est temporairement saturé. Réessayez dans une minute.",
      };
    }
    if (e instanceof Anthropic.APIConnectionError) {
      return {
        error: "Connexion au service IA impossible. Vérifiez votre réseau puis réessayez.",
      };
    }
    if (e instanceof Anthropic.APIError) {
      console.error("proposerChiffrageIA :", e.status, e.message);
      return {
        error: `Le service IA a renvoyé une erreur (détail technique : ${e.status ?? "?"} — ${e.message}).`,
      };
    }
    console.error("proposerChiffrageIA :", e);
    return { error: "La proposition IA a échoué. Réessayez dans un instant." };
  }
}
