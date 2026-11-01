/**
 * Texts of the public legal pages (privacy policy, account deletion).
 * Kept in one place so French and English stay in step.
 *
 * Every statement here must stay true for the app and the admin website:
 * update this file whenever data, providers or access rules change.
 */

export const LEGAL = {
  publisher: "IMPACT-365",
  email: "contact@impact365jours.com",
  country: { fr: "Côte d'Ivoire", en: "Côte d'Ivoire" },
  updated: { fr: "1er novembre 2026", en: "1 November 2026" },
  minAge: 13,
  authority: {
    name: "ARTCI",
    fullFr: "Autorité de Régulation des Télécommunications/TIC de Côte d'Ivoire",
    fullEn: "Telecommunications/ICT Regulatory Authority of Côte d'Ivoire",
    url: "https://www.artci.ci",
  },
} as const;

export type LegalLang = "fr" | "en";

/** A paragraph, or a bullet list. `**bold**` is supported. */
export type Block = string | { list: string[] };

export type Section = { id: string; title: string; blocks: Block[] };

export type LegalDoc = {
  title: string;
  intro: string;
  updatedLabel: string;
  sections: Section[];
};

const e = LEGAL.email;
const age = LEGAL.minAge;

// ---------------------------------------------------------------- Privacy

export const privacy: Record<LegalLang, LegalDoc> = {
  fr: {
    title: "Politique de confidentialité",
    updatedLabel: `Dernière mise à jour : ${LEGAL.updated.fr}`,
    intro:
      "IMPACT-365 t'aide à rencontrer Dieu chaque jour : dévotions, prière, défis, entraide (Holy SOS) et échanges privés avec les responsables de ton église. Cette page explique, simplement, quelles données nous utilisons, pourquoi, qui peut les voir et comment tu gardes le contrôle.",
    sections: [
      {
        id: "responsable",
        title: "1. Qui est responsable de tes données ?",
        blocks: [
          `**${LEGAL.publisher}**, éditeur de l'application mobile IMPACT-365 et de l'espace responsables (admin.impact365jours.com), basé en ${LEGAL.country.fr}.`,
          `Pour toute question sur tes données : **${e}**.`,
        ],
      },
      {
        id: "donnees",
        title: "2. Les données que nous utilisons",
        blocks: [
          "**Ton compte**",
          {
            list: [
              "Ton adresse e-mail et ton nom.",
              "Ton mot de passe, si tu crées un compte par e-mail. Il est stocké chiffré (haché) : personne ne peut le lire, pas même nous.",
              "Si tu te connectes avec Google : ton nom, ton adresse e-mail et ta photo de profil Google.",
            ],
          },
          "**Ton profil** (facultatif, tu le modifies quand tu veux)",
          {
            list: [
              "Ton numéro de téléphone.",
              "Ta photo de profil.",
              "Ta langue (français, anglais ou yoruba).",
            ],
          },
          "**Ce que tu écris ou fais dans l'application**",
          {
            list: [
              "**Ton journal** : il est strictement privé. Seul toi peux le lire, ni les autres membres ni les responsables de l'église.",
              "**Tes sujets de prière** : privés par défaut. Si tu choisis de les partager, les autres membres peuvent les voir et prier pour toi, avec ton nom ou de façon anonyme, selon ton choix. Ton témoignage, si tu l'écris quand Dieu exauce, est enregistré avec la prière.",
              "**« J'ai prié »** quand tu pries pour la demande d'un autre membre.",
              "**Holy SOS** : tes demandes d'aide (type de besoin et description), avec les options « anonyme » et « seulement les responsables », et les propositions d'aide que tu fais à d'autres.",
              "**Tes messages privés** avec les pasteurs et responsables.",
              "**Ton parcours** : dévotions lues et mises en favori, défis accomplis, séries de jours.",
            ],
          },
          "**Données techniques**",
          {
            list: [
              "Sur ton téléphone : ta session de connexion (gardée dans le stockage sécurisé du téléphone) et tes préférences (comme la langue).",
              "Sur nos serveurs : des journaux techniques (date, adresse IP, type d'appareil) gardés par nos hébergeurs pour la sécurité et le bon fonctionnement, et des compteurs qui limitent les abus (nombre d'essais, d'envois).",
            ],
          },
          "**Ce que nous ne faisons pas** : pas de publicité, pas de pistage, pas d'outil de mesure d'audience, pas de localisation, pas d'accès à tes contacts. **Nous ne vendons ni ne louons jamais tes données.**",
        ],
      },
      {
        id: "pourquoi",
        title: "3. Pourquoi nous les utilisons",
        blocks: [
          {
            list: [
              "Créer et sécuriser ton compte (codes de vérification par e-mail, protection contre les abus).",
              "Te proposer le contenu du jour dans ta langue et suivre ton parcours.",
              "Permettre la prière et l'entraide entre membres, selon ce que tu choisis de partager.",
              "Permettre aux responsables de te répondre et de t'accompagner.",
              "Publier les annonces de l'église.",
            ],
          },
          "Certaines données peuvent révéler tes convictions religieuses ; ce sont des données sensibles. Nous ne les utilisons qu'avec ton consentement, que tu donnes en créant ton compte et en choisissant ce que tu partages. Tu peux le retirer à tout moment en modifiant tes choix ou en supprimant ton compte.",
        ],
      },
      {
        id: "acces",
        title: "4. Qui peut voir tes données ?",
        blocks: [
          {
            list: [
              "**Toi** : tout ce qui te concerne.",
              "**Les autres membres** : uniquement ce que tu partages (prières partagées, demandes Holy SOS visibles par la communauté), avec ton nom seulement si tu n'as pas choisi l'anonymat.",
              "**Les responsables, pasteurs et administrateurs de l'église** : ton profil (nom, téléphone, photo, langue), tes messages privés avec eux, tes demandes Holy SOS (même anonymes ou réservées aux responsables) et les prières partagées. **Jamais ton journal, ni tes prières privées.**",
              "**Nos prestataires techniques**, uniquement pour faire fonctionner le service (voir ci-dessous).",
            ],
          },
          "Ces règles d'accès sont appliquées directement par notre base de données, pas seulement par l'application.",
        ],
      },
      {
        id: "prestataires",
        title: "5. Nos prestataires et l'hébergement",
        blocks: [
          {
            list: [
              "**Supabase** : base de données, comptes et stockage des photos.",
              "**Vercel** : hébergement du site web (espace responsables et cette page).",
              "**Resend** : envoi des e-mails (codes de vérification).",
              "**Google** : connexion avec Google, si tu la choisis.",
              "**Cloudflare** : gestion du nom de domaine impact365jours.com.",
            ],
          },
          `Ces services peuvent stocker ou traiter des données sur des serveurs situés hors de ${LEGAL.country.fr}. Nous choisissons des prestataires reconnus qui protègent les données (chiffrement, contrats de protection des données) et nous ne leur transmettons que ce qui est nécessaire.`,
        ],
      },
      {
        id: "conservation",
        title: "6. Combien de temps nous les gardons",
        blocks: [
          "Tes données sont gardées tant que ton compte existe. Quand tu supprimes ton compte, tout ce qui t'appartient est effacé immédiatement : profil, photo, journal, prières, demandes et propositions Holy SOS, messages et parcours.",
          "Des copies peuvent subsister quelques temps dans les sauvegardes techniques de nos hébergeurs, puis sont écrasées. Les journaux techniques sont gardés pour une durée limitée par nos prestataires.",
        ],
      },
      {
        id: "securite",
        title: "7. Comment nous les protégeons",
        blocks: [
          {
            list: [
              "Connexions toujours chiffrées (HTTPS).",
              "Règles d'accès appliquées par la base de données pour chaque information.",
              "Mots de passe hachés ; codes de vérification valables 10 minutes ; nombre d'essais limité.",
              "Session de connexion gardée dans le stockage sécurisé de ton téléphone.",
            ],
          },
        ],
      },
      {
        id: "droits",
        title: "8. Tes droits",
        blocks: [
          "Tu peux à tout moment :",
          {
            list: [
              "**Consulter et corriger** tes informations : Profil → Informations personnelles.",
              "**Supprimer ton compte** et toutes tes données : Profil → Supprimer mon compte (voir la page « Supprimer mon compte »).",
              "**Retirer ton consentement** : arrêter de partager une prière, choisir l'anonymat, retirer ta photo.",
              `**Demander une copie** de tes données, t'opposer à un usage ou poser une question : écris à **${e}** depuis l'adresse de ton compte. Nous répondons dans un délai d'un mois.`,
            ],
          },
          `Si tu estimes que tes droits ne sont pas respectés, tu peux saisir l'autorité de protection des données de ${LEGAL.country.fr} : l'**${LEGAL.authority.name}** (${LEGAL.authority.fullFr}), ${LEGAL.authority.url}.`,
          `Cette politique respecte la loi ivoirienne n° 2013-450 du 19 juin 2013 relative à la protection des données à caractère personnel.`,
        ],
      },
      {
        id: "enfants",
        title: "9. Enfants",
        blocks: [
          `L'application est destinée aux personnes de **${age} ans et plus**. Un enfant de moins de ${age} ans ne peut l'utiliser qu'avec l'accord et l'accompagnement d'un parent. Si nous apprenons qu'un compte appartient à un enfant de moins de ${age} ans sans accord parental, nous le supprimons. Un parent peut nous écrire à ${e}.`,
        ],
      },
      {
        id: "changements",
        title: "10. Modifications",
        blocks: [
          "Si cette politique change, nous mettons à jour la date en haut de la page. En cas de changement important, nous te prévenons dans l'application.",
        ],
      },
      {
        id: "contact",
        title: "11. Nous contacter",
        blocks: [`**${LEGAL.publisher}** — ${LEGAL.country.fr} — **${e}**`],
      },
    ],
  },

  en: {
    title: "Privacy Policy",
    updatedLabel: `Last updated: ${LEGAL.updated.en}`,
    intro:
      "IMPACT-365 helps you meet God every day: devotions, prayer, challenges, mutual help (Holy SOS) and private conversations with your church leaders. This page explains, simply, which data we use, why, who can see it and how you stay in control.",
    sections: [
      {
        id: "controller",
        title: "1. Who is responsible for your data?",
        blocks: [
          `**${LEGAL.publisher}**, publisher of the IMPACT-365 mobile app and of the leaders' website (admin.impact365jours.com), based in ${LEGAL.country.en}.`,
          `For any question about your data: **${e}**.`,
        ],
      },
      {
        id: "data",
        title: "2. The data we use",
        blocks: [
          "**Your account**",
          {
            list: [
              "Your email address and your name.",
              "Your password, if you sign up with email. It is stored encrypted (hashed): nobody can read it, not even us.",
              "If you sign in with Google: your Google name, email address and profile photo.",
            ],
          },
          "**Your profile** (optional, change it any time)",
          {
            list: ["Your phone number.", "Your profile photo.", "Your language (French, English or Yoruba)."],
          },
          "**What you write or do in the app**",
          {
            list: [
              "**Your journal**: strictly private. Only you can read it, not other members and not church leaders.",
              "**Your prayer requests**: private by default. If you choose to share one, other members can see it and pray for you, with your name or anonymously, as you choose. Your testimony, if you write one when God answers, is saved with the prayer.",
              "**\"I prayed\"** when you pray for another member's request.",
              "**Holy SOS**: your requests for help (type of need and description), with the \"anonymous\" and \"leaders only\" options, and the offers of help you make to others.",
              "**Your private messages** with pastors and leaders.",
              "**Your journey**: devotions read and saved, challenges completed, day streaks.",
            ],
          },
          "**Technical data**",
          {
            list: [
              "On your phone: your sign-in session (kept in the phone's secure storage) and your preferences (such as language).",
              "On our servers: technical logs (date, IP address, device type) kept by our hosting providers for security and reliability, and counters that limit abuse (number of attempts and posts).",
            ],
          },
          "**What we don't do**: no advertising, no tracking, no audience-measurement tools, no location, no access to your contacts. **We never sell or rent your data.**",
        ],
      },
      {
        id: "why",
        title: "3. Why we use it",
        blocks: [
          {
            list: [
              "To create and secure your account (email verification codes, protection against abuse).",
              "To show you each day's content in your language and keep track of your journey.",
              "To let members pray for and help each other, according to what you choose to share.",
              "To let leaders answer and support you.",
              "To publish church announcements.",
            ],
          },
          "Some of this data can reveal your religious beliefs, which is sensitive data. We only use it with your consent, which you give by creating your account and by choosing what you share. You can withdraw it at any time by changing your choices or deleting your account.",
        ],
      },
      {
        id: "access",
        title: "4. Who can see your data?",
        blocks: [
          {
            list: [
              "**You**: everything about you.",
              "**Other members**: only what you share (shared prayers, Holy SOS requests visible to the community), with your name only if you didn't choose to stay anonymous.",
              "**Church leaders, pastors and administrators**: your profile (name, phone, photo, language), your private messages with them, your Holy SOS requests (even anonymous or leaders-only ones) and shared prayers. **Never your journal or your private prayers.**",
              "**Our technical providers**, only to run the service (see below).",
            ],
          },
          "These access rules are enforced by our database itself, not only by the app.",
        ],
      },
      {
        id: "providers",
        title: "5. Our providers and hosting",
        blocks: [
          {
            list: [
              "**Supabase**: database, accounts and photo storage.",
              "**Vercel**: hosting of the website (leaders' area and this page).",
              "**Resend**: sending emails (verification codes).",
              "**Google**: Sign in with Google, if you choose it.",
              "**Cloudflare**: management of the impact365jours.com domain name.",
            ],
          },
          `These services may store or process data on servers located outside ${LEGAL.country.en}. We choose recognised providers that protect data (encryption, data-protection agreements) and only share what is necessary.`,
        ],
      },
      {
        id: "retention",
        title: "6. How long we keep it",
        blocks: [
          "Your data is kept as long as your account exists. When you delete your account, everything that belongs to you is erased immediately: profile, photo, journal, prayers, Holy SOS requests and offers, messages and journey.",
          "Copies may remain for a short time in our providers' technical backups before being overwritten. Technical logs are kept for a limited period by our providers.",
        ],
      },
      {
        id: "security",
        title: "7. How we protect it",
        blocks: [
          {
            list: [
              "Connections always encrypted (HTTPS).",
              "Access rules enforced by the database for every piece of information.",
              "Hashed passwords; verification codes valid for 10 minutes; limited number of attempts.",
              "Sign-in session kept in your phone's secure storage.",
            ],
          },
        ],
      },
      {
        id: "rights",
        title: "8. Your rights",
        blocks: [
          "At any time you can:",
          {
            list: [
              "**See and correct** your information: Profile → Personal information.",
              "**Delete your account** and all your data: Profile → Delete my account (see the \"Delete my account\" page).",
              "**Withdraw your consent**: stop sharing a prayer, choose anonymity, remove your photo.",
              `**Ask for a copy** of your data, object to a use, or ask a question: write to **${e}** from your account's email address. We answer within one month.`,
            ],
          },
          `If you believe your rights are not respected, you can contact the data-protection authority of ${LEGAL.country.en}: **${LEGAL.authority.name}** (${LEGAL.authority.fullEn}), ${LEGAL.authority.url}.`,
          "This policy follows Ivorian Law No. 2013-450 of 19 June 2013 on the protection of personal data.",
        ],
      },
      {
        id: "children",
        title: "9. Children",
        blocks: [
          `The app is meant for people aged **${age} and over**. A child under ${age} may only use it with a parent's permission and guidance. If we learn that an account belongs to a child under ${age} without parental permission, we delete it. A parent can write to us at ${e}.`,
        ],
      },
      {
        id: "changes",
        title: "10. Changes",
        blocks: [
          "If this policy changes, we update the date at the top of the page. For important changes, we let you know in the app.",
        ],
      },
      {
        id: "contact",
        title: "11. Contact us",
        blocks: [`**${LEGAL.publisher}** — ${LEGAL.country.en} — **${e}**`],
      },
    ],
  },
};

// ---------------------------------------------------------- Delete account

export const deletion: Record<LegalLang, LegalDoc> = {
  fr: {
    title: "Supprimer mon compte IMPACT-365",
    updatedLabel: `Dernière mise à jour : ${LEGAL.updated.fr}`,
    intro:
      "Tu peux supprimer ton compte IMPACT-365 et toutes tes données à tout moment, gratuitement.",
    sections: [
      {
        id: "app",
        title: "Depuis l'application (le plus rapide)",
        blocks: [
          {
            list: [
              "Ouvre l'application IMPACT-365 et connecte-toi.",
              "Va dans **Profil**.",
              "Touche **Supprimer mon compte**.",
              "Confirme en tapant le mot **SUPPRIMER**.",
            ],
          },
          "La suppression est immédiate et définitive.",
        ],
      },
      {
        id: "email",
        title: "Sans l'application",
        blocks: [
          `Écris à **${e}** depuis l'adresse e-mail de ton compte, avec pour objet « Supprimer mon compte ». Nous supprimons ton compte sous 30 jours au plus tard et te le confirmons par e-mail.`,
        ],
      },
      {
        id: "what",
        title: "Ce qui est supprimé",
        blocks: [
          {
            list: [
              "Ton compte et ton profil (nom, e-mail, téléphone, photo).",
              "Ton journal.",
              "Tes sujets de prière (privés et partagés) et tes « J'ai prié ».",
              "Tes demandes et propositions d'aide Holy SOS.",
              "Tes conversations et messages avec les responsables.",
              "Ton parcours (dévotions, défis, favoris, séries).",
            ],
          },
          "Rien n'est conservé, à l'exception de copies temporaires dans les sauvegardes techniques de nos hébergeurs, écrasées après un court délai.",
          "Note : le dernier administrateur de l'église ne peut pas supprimer son compte tant qu'il n'a pas nommé un autre administrateur.",
        ],
      },
    ],
  },
  en: {
    title: "Delete my IMPACT-365 account",
    updatedLabel: `Last updated: ${LEGAL.updated.en}`,
    intro: "You can delete your IMPACT-365 account and all your data at any time, free of charge.",
    sections: [
      {
        id: "app",
        title: "From the app (quickest)",
        blocks: [
          {
            list: [
              "Open the IMPACT-365 app and sign in.",
              "Go to **Profile**.",
              "Tap **Delete my account**.",
              "Confirm by typing the word **DELETE**.",
            ],
          },
          "Deletion is immediate and permanent.",
        ],
      },
      {
        id: "email",
        title: "Without the app",
        blocks: [
          `Write to **${e}** from your account's email address, with the subject "Delete my account". We delete your account within 30 days at the latest and confirm it by email.`,
        ],
      },
      {
        id: "what",
        title: "What is deleted",
        blocks: [
          {
            list: [
              "Your account and profile (name, email, phone, photo).",
              "Your journal.",
              "Your prayer requests (private and shared) and your \"I prayed\".",
              "Your Holy SOS requests and offers of help.",
              "Your conversations and messages with leaders.",
              "Your journey (devotions, challenges, saved items, streaks).",
            ],
          },
          "Nothing is kept, except temporary copies in our providers' technical backups, overwritten after a short time.",
          "Note: the church's last administrator cannot delete their account until they have named another administrator.",
        ],
      },
    ],
  },
};
