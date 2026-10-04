"use client";

import { createContext, useContext, useSyncExternalStore } from "react";

/** Admin website language (French / English). */
export type AdminLang = "fr" | "en";

const fr = {
  appName: "Impact-365 Admin",
  tagline: "1 jour 1 impact",
  nav: {
    dashboard: "Tableau de bord",
    devotions: "Dévotions",
    challenges: "Défis du jour",
    concerns: "Messages privés",
    sos: "Holy SOS",
    prayers: "Prières partagées",
    announcements: "Annonces",
    members: "Membres",
  },
  login: {
    title: "Espace responsables",
    subtitle: "Connecte-toi avec ton compte administrateur, pasteur ou responsable.",
    email: "E-mail",
    password: "Mot de passe",
    submit: "Se connecter",
    error: "E-mail ou mot de passe incorrect.",
  },
  denied: {
    title: "Accès réservé",
    text: "Ce compte n'a pas les droits d'accès à l'espace admin. Demande à un administrateur de t'attribuer le rôle « responsable », « pasteur » ou « admin ».",
  },
  common: {
    save: "Enregistrer",
    saving: "Enregistrement…",
    saved: "Enregistré ✓",
    cancel: "Annuler",
    delete: "Supprimer",
    confirmDelete: "Supprimer définitivement ?",
    edit: "Modifier",
    new: "Nouveau",
    back: "Retour",
    loading: "Chargement…",
    empty: "Rien pour le moment.",
    error: "Une erreur est survenue.",
    published: "Publié",
    draft: "Brouillon",
    anonymous: "Anonyme",
    signOut: "Se déconnecter",
    all: "Tous",
    upload: "Téléverser",
    remove: "Retirer",
    date: "Date",
    language: "Langue",
  },
  dashboard: {
    welcome: "Bienvenue",
    members: "Membres",
    openConversations: "Conversations ouvertes",
    openHelp: "Demandes SOS en cours",
    prayersWeek: "Prières (7 jours)",
    devotionsScheduled: "Dévotions programmées",
    completionsToday: "Dévotions lues aujourd'hui",
    quick: "Actions rapides",
    addDevotion: "Ajouter une dévotion",
    addChallenge: "Ajouter un défi",
    answerMessages: "Répondre aux messages",
  },
  slots: { morning: "Matin", afternoon: "Après-midi", night: "Soir" },
  langs: { fr: "Français", en: "English", yo: "Yorùbá" },
  devotions: {
    title: "Dévotions",
    subtitle: "3 dévotions par jour : matin, après-midi et soir. Elles apparaissent dans l'application à la date choisie.",
    newDevotion: "Nouvelle dévotion",
    editDevotion: "Modifier la dévotion",
    slot: "Moment",
    image: "Image de fond (facultatif)",
    publish: "Publier (visible dans l'app à la date choisie)",
    translations: "Contenu par langue",
    translationHint: "Remplis au moins une langue. Si une langue manque, l'app affiche le français, puis l'anglais.",
    theme: "Thème du jour",
    verseReference: "Référence biblique",
    verseReferencePh: "ex. Matthieu 6:33",
    verseText: "Texte du verset",
    godSays: "Ce que Dieu dit",
    iUnderstand: "Ce que je comprends",
    iDo: "Ce que je fais",
    audio: "Audio (facultatif)",
    missing: "Manquant",
    filled: "Rempli",
    incomplete: "Langue {lang} incomplète : référence, verset et les 3 sections sont requis.",
    needOne: "Remplis au moins une langue.",
    duplicate: "Une dévotion existe déjà pour cette date et ce moment.",
    from: "Du",
    to: "au",
  },
  challenges: {
    title: "Défis du jour",
    subtitle: "Un défi concret par jour, affiché dans l'onglet « Impact ».",
    newChallenge: "Nouveau défi",
    editChallenge: "Modifier le défi",
    challengeTitle: "Défi",
    description: "Description (facultatif)",
    verseReference: "Référence du verset (facultatif)",
    verseText: "Texte du verset (facultatif)",
    completions: "relevés",
    duplicate: "Un défi existe déjà pour cette date.",
  },
  concerns: {
    title: "Messages privés",
    subtitle: "Les membres partagent ce qu'ils ont sur le cœur. Seuls les responsables voient ces échanges.",
    open: "Ouvertes",
    closed: "Fermées",
    select: "Choisis une conversation.",
    reply: "Écris ta réponse…",
    send: "Envoyer",
    close: "Clôturer",
    reopen: "Rouvrir",
    assignMe: "M'assigner",
    assignedTo: "Assignée à",
    unassigned: "Non assignée",
    member: "Membre",
    leader: "Responsable",
  },
  sos: {
    title: "Holy SOS",
    subtitle: "Demandes d'aide des membres. Les demandes anonymes ne montrent le nom qu'aux responsables.",
    status: { open: "Ouvert", in_progress: "En cours", resolved: "Résolu" },
    categories: {
      prayer: "Prière",
      financial: "Financier",
      health: "Santé",
      emotional: "Émotionnel",
      studies_work: "Études / Travail",
      other: "Autre",
    },
    leadersOnly: "Responsables uniquement",
    anonymousToCommunity: "Anonyme pour la communauté",
    note: "Note visible par le membre",
    notePh: "Un mot d'encouragement ou la suite donnée…",
    offers: "Propositions d'aide",
    noOffers: "Aucune proposition pour l'instant.",
  },
  prayers: {
    title: "Prières partagées",
    subtitle: "Sujets de prière que les membres ont choisi de partager avec la communauté.",
    intercessions: "personnes ont prié",
    answered: "Exaucée",
    testimony: "Témoignage",
  },
  announcements: {
    title: "Annonces",
    subtitle: "Messages envoyés à tous les membres (onglet « Notifications » de l'app).",
    newAnnouncement: "Nouvelle annonce",
    titleField: "Titre",
    body: "Message",
    audience: "Langue des destinataires",
    everyone: "Tout le monde",
    publish: "Publier",
  },
  members: {
    title: "Membres",
    subtitle: "Seuls les administrateurs peuvent changer les rôles.",
    search: "Rechercher un nom…",
    name: "Nom",
    role: "Rôle",
    language: "Langue",
    joined: "Inscrit le",
    roles: { member: "Membre", leader: "Responsable", pastor: "Pasteur", admin: "Admin" },
  },
};

type Dict = typeof fr;

const en: Dict = {
  appName: "Impact-365 Admin",
  tagline: "1 day 1 impact",
  nav: {
    dashboard: "Dashboard",
    devotions: "Devotions",
    challenges: "Daily challenges",
    concerns: "Private messages",
    sos: "Holy SOS",
    prayers: "Shared prayers",
    announcements: "Announcements",
    members: "Members",
  },
  login: {
    title: "Leaders area",
    subtitle: "Sign in with your admin, pastor or leader account.",
    email: "Email",
    password: "Password",
    submit: "Sign in",
    error: "Wrong email or password.",
  },
  denied: {
    title: "Restricted access",
    text: "This account cannot access the admin area. Ask an administrator to give you the “leader”, “pastor” or “admin” role.",
  },
  common: {
    save: "Save",
    saving: "Saving…",
    saved: "Saved ✓",
    cancel: "Cancel",
    delete: "Delete",
    confirmDelete: "Delete permanently?",
    edit: "Edit",
    new: "New",
    back: "Back",
    loading: "Loading…",
    empty: "Nothing yet.",
    error: "Something went wrong.",
    published: "Published",
    draft: "Draft",
    anonymous: "Anonymous",
    signOut: "Sign out",
    all: "All",
    upload: "Upload",
    remove: "Remove",
    date: "Date",
    language: "Language",
  },
  dashboard: {
    welcome: "Welcome",
    members: "Members",
    openConversations: "Open conversations",
    openHelp: "Open SOS requests",
    prayersWeek: "Prayers (7 days)",
    devotionsScheduled: "Scheduled devotions",
    completionsToday: "Devotions read today",
    quick: "Quick actions",
    addDevotion: "Add a devotion",
    addChallenge: "Add a challenge",
    answerMessages: "Answer messages",
  },
  slots: { morning: "Morning", afternoon: "Afternoon", night: "Night" },
  langs: { fr: "Français", en: "English", yo: "Yorùbá" },
  devotions: {
    title: "Devotions",
    subtitle: "3 devotions per day: morning, afternoon and night. They appear in the app on the chosen date.",
    newDevotion: "New devotion",
    editDevotion: "Edit devotion",
    slot: "Time of day",
    image: "Background image (optional)",
    publish: "Publish (visible in the app on the chosen date)",
    translations: "Content per language",
    translationHint: "Fill in at least one language. If a language is missing, the app shows French, then English.",
    theme: "Theme of the day",
    verseReference: "Bible reference",
    verseReferencePh: "e.g. Matthew 6:33",
    verseText: "Verse text",
    godSays: "What God says",
    iUnderstand: "What I understand",
    iDo: "What I do",
    audio: "Audio (optional)",
    missing: "Missing",
    filled: "Filled",
    incomplete: "{lang} is incomplete: reference, verse and the 3 sections are required.",
    needOne: "Fill in at least one language.",
    duplicate: "A devotion already exists for this date and time of day.",
    from: "From",
    to: "to",
  },
  challenges: {
    title: "Daily challenges",
    subtitle: "One concrete challenge per day, shown in the “Impact” tab.",
    newChallenge: "New challenge",
    editChallenge: "Edit challenge",
    challengeTitle: "Challenge",
    description: "Description (optional)",
    verseReference: "Verse reference (optional)",
    verseText: "Verse text (optional)",
    completions: "completed",
    duplicate: "A challenge already exists for this date.",
  },
  concerns: {
    title: "Private messages",
    subtitle: "Members share what is on their heart. Only leaders can see these conversations.",
    open: "Open",
    closed: "Closed",
    select: "Select a conversation.",
    reply: "Write your reply…",
    send: "Send",
    close: "Close",
    reopen: "Reopen",
    assignMe: "Assign to me",
    assignedTo: "Assigned to",
    unassigned: "Unassigned",
    member: "Member",
    leader: "Leader",
  },
  sos: {
    title: "Holy SOS",
    subtitle: "Help requests from members. Anonymous requests only show the name to leaders.",
    status: { open: "Open", in_progress: "In progress", resolved: "Resolved" },
    categories: {
      prayer: "Prayer",
      financial: "Financial",
      health: "Health",
      emotional: "Emotional",
      studies_work: "Studies / Work",
      other: "Other",
    },
    leadersOnly: "Leaders only",
    anonymousToCommunity: "Anonymous to the community",
    note: "Note visible to the member",
    notePh: "A word of encouragement or the follow-up given…",
    offers: "Offers of help",
    noOffers: "No offers yet.",
  },
  prayers: {
    title: "Shared prayers",
    subtitle: "Prayer points members chose to share with the community.",
    intercessions: "people prayed",
    answered: "Answered",
    testimony: "Testimony",
  },
  announcements: {
    title: "Announcements",
    subtitle: "Messages sent to every member (“Notifications” tab in the app).",
    newAnnouncement: "New announcement",
    titleField: "Title",
    body: "Message",
    audience: "Recipients' language",
    everyone: "Everyone",
    publish: "Publish",
  },
  members: {
    title: "Members",
    subtitle: "Only administrators can change roles.",
    search: "Search a name…",
    name: "Name",
    role: "Role",
    language: "Language",
    joined: "Joined",
    roles: { member: "Member", leader: "Leader", pastor: "Pastor", admin: "Admin" },
  },
};

const dictionaries: Record<AdminLang, Dict> = { fr, en };

const I18nContext = createContext<{
  lang: AdminLang;
  t: Dict;
  setLang: (l: AdminLang) => void;
}>({ lang: "fr", t: fr, setLang: () => {} });

// The chosen language lives in localStorage; useSyncExternalStore reads it
// safely on the client and falls back to French during server rendering.
const listeners = new Set<() => void>();

function readLang(): AdminLang {
  try {
    return localStorage.getItem("admin_lang") === "en" ? "en" : "fr";
  } catch {
    return "fr";
  }
}

function subscribe(cb: () => void) {
  listeners.add(cb);
  return () => listeners.delete(cb);
}

export function I18nProvider({ children }: { children: React.ReactNode }) {
  const lang = useSyncExternalStore(subscribe, readLang, () => "fr" as AdminLang);

  const setLang = (l: AdminLang) => {
    try {
      localStorage.setItem("admin_lang", l);
    } catch {}
    listeners.forEach((cb) => cb());
  };

  return (
    <I18nContext.Provider value={{ lang, t: dictionaries[lang], setLang }}>
      {children}
    </I18nContext.Provider>
  );
}

export const useI18n = () => useContext(I18nContext);

/** Content languages available for devotions / challenges. */
export const CONTENT_LANGS = ["fr", "en", "yo"] as const;
export type ContentLang = (typeof CONTENT_LANGS)[number];

export const SLOTS = ["morning", "afternoon", "night"] as const;
export type Slot = (typeof SLOTS)[number];
