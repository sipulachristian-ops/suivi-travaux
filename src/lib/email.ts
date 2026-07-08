// Envoi d'e-mails via le service Resend (https://resend.com), appelé
// directement en HTTP — pas de dépendance supplémentaire.
//
// Fonctionne dès que la clé RESEND_API_KEY existe (.env.local en local,
// variables d'environnement sur Vercel — jamais dans le code). Tant
// qu'elle n'existe pas, l'envoi est simplement ignoré : les
// notifications dans l'application, elles, fonctionnent toujours.

const SITE_URL =
  process.env.NEXT_PUBLIC_SITE_URL ?? "https://suivi-travaux-nu.vercel.app";

// Adresse d'expédition : l'adresse de test de Resend par défaut
// (elle ne peut écrire qu'à l'adresse du compte Resend) ; une fois le
// domaine jp-facilities.com vérifié chez Resend, définir EMAIL_FROM.
const FROM =
  process.env.EMAIL_FROM ?? "Suivi des travaux <onboarding@resend.dev>";

export type EmailNotification = {
  to: string[];
  sujet: string;
  titre: string;
  corps: string;
  lien: string; // chemin dans l'app, ex. /travaux/xxx/chiffrages/yyy
  lienTexte: string;
};

// Envoie l'e-mail et n'échoue JAMAIS : une panne d'e-mail ne doit pas
// bloquer la soumission ou la décision d'un chiffrage.
export async function envoyerEmailNotification(
  email: EmailNotification
): Promise<void> {
  const cle = process.env.RESEND_API_KEY;
  const destinataires = email.to.filter((adresse) => adresse.includes("@"));

  if (!cle || destinataires.length === 0) {
    if (!cle) {
      console.log(
        "E-mail non envoyé (RESEND_API_KEY absente) :",
        email.sujet
      );
    }
    return;
  }

  try {
    const reponse = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${cle}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: FROM,
        to: destinataires,
        subject: email.sujet,
        html: gabaritHtml(email),
      }),
    });

    if (!reponse.ok) {
      console.error(
        "Envoi d'e-mail refusé par Resend :",
        reponse.status,
        await reponse.text()
      );
    }
  } catch (erreur) {
    console.error("Envoi d'e-mail impossible :", erreur);
  }
}

// Gabarit sobre aux couleurs JP Facilities (orange #EC6707)
function gabaritHtml(email: EmailNotification): string {
  const url = `${SITE_URL}${email.lien}`;
  return `<!doctype html>
<html lang="fr">
  <body style="margin:0;padding:24px;background:#f7f6f4;font-family:Arial,Helvetica,sans-serif;color:#1f2937;">
    <div style="max-width:560px;margin:0 auto;background:#ffffff;border:1px solid #e5e7eb;border-radius:12px;overflow:hidden;">
      <div style="height:4px;background:#EC6707;"></div>
      <div style="padding:24px;">
        <p style="margin:0 0 4px;font-size:11px;letter-spacing:2px;text-transform:uppercase;color:#9ca3af;">
          JP Facilities · Suivi des travaux
        </p>
        <h1 style="margin:0 0 16px;font-size:18px;">${echapperHtml(email.titre)}</h1>
        <p style="margin:0 0 24px;font-size:14px;line-height:1.6;">${echapperHtml(email.corps)}</p>
        <a href="${url}"
           style="display:inline-block;background:#EC6707;color:#ffffff;text-decoration:none;font-size:14px;font-weight:bold;padding:10px 20px;border-radius:8px;">
          ${echapperHtml(email.lienTexte)}
        </a>
        <p style="margin:24px 0 0;font-size:12px;color:#9ca3af;">
          Vous recevez cet e-mail car vous êtes concerné par ce chiffrage
          dans l'application Suivi des travaux.
        </p>
      </div>
    </div>
  </body>
</html>`;
}

function echapperHtml(texte: string): string {
  return texte
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}
