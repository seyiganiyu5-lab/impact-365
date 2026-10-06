// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTagline => '1 jour 1 impact';

  @override
  String get navHome => 'Accueil';

  @override
  String get navWord => 'Parole';

  @override
  String get navPrayer => 'Prière';

  @override
  String get navImpact => 'Impact';

  @override
  String get navProfile => 'Profil';

  @override
  String get authWelcome => 'Bienvenue sur Impact-365';

  @override
  String get authSubtitle =>
      'Un nouveau jour. Une nouvelle rencontre avec Dieu.';

  @override
  String get authEmail => 'E-mail';

  @override
  String get authPassword => 'Mot de passe';

  @override
  String get authFullName => 'Nom complet';

  @override
  String get authSignIn => 'Se connecter';

  @override
  String get authSignUp => 'Créer mon compte';

  @override
  String get authNoAccount => 'Pas encore de compte ? Inscris-toi';

  @override
  String get authHaveAccount => 'Déjà un compte ? Connecte-toi';

  @override
  String get authCheckEmail =>
      'Vérifie ta boîte mail pour confirmer ton compte.';

  @override
  String get authInvalid =>
      'Remplis tous les champs (mot de passe : 6 caractères minimum).';

  @override
  String homeGreeting(String name) {
    return 'Bonjour, $name.';
  }

  @override
  String get homeGreetingDefault => 'Impacteur';

  @override
  String get homeSubtitle =>
      'Un nouveau jour.\nUne nouvelle rencontre avec Dieu.';

  @override
  String homeDayCounter(int day) {
    return 'Jour $day / 365';
  }

  @override
  String get homeCurrentStreak => 'Série actuelle';

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours',
      one: '1 jour',
      zero: '0 jour',
    );
    return '$_temp0';
  }

  @override
  String get homeVerseOfDay => 'Verset du jour';

  @override
  String get homeStartDevotion => 'COMMENCER MA DÉVOTION';

  @override
  String get homeThemeOfDay => 'Thème du jour';

  @override
  String get homeToday => 'Aujourd\'hui';

  @override
  String get homeYourWord => 'Ta Parole';

  @override
  String get homeYourPrayer => 'Ta prière';

  @override
  String get homeYourImpact => 'Ton impact';

  @override
  String get homeDiscover => 'Découvrir';

  @override
  String get homePray => 'Prier';

  @override
  String get homeAct => 'Agir';

  @override
  String get homeFaithJourney => 'Parcours de foi';

  @override
  String get homeFaithJourneyText => 'Ta constance façonne ton impact éternel.';

  @override
  String get homeNoDevotion =>
      'Aucune dévotion publiée pour aujourd\'hui. Reviens bientôt !';

  @override
  String get slotMorning => 'Matin';

  @override
  String get slotAfternoon => 'Après-midi';

  @override
  String get slotNight => 'Soir';

  @override
  String get devotionTitle => '5 MINUTES AVEC DIEU';

  @override
  String get devotionGodSays => 'CE QUE DIEU DIT';

  @override
  String get devotionIUnderstand => 'CE QUE JE COMPRENDS';

  @override
  String get devotionIDo => 'CE QUE JE FAIS';

  @override
  String get devotionDone => 'J\'AI COMPRIS';

  @override
  String get devotionCompleted => 'Terminé';

  @override
  String get devotionListen => 'ÉCOUTER EN AUDIO';

  @override
  String get devotionPause => 'METTRE EN PAUSE';

  @override
  String get devotionQuestionTitle => 'Une question ?';

  @override
  String get devotionQuestionText =>
      'Écris-la, un responsable t\'aidera avec joie.';

  @override
  String get devotionAskQuestion => 'Poser ma question';

  @override
  String get wordTodayTitle => 'Dévotions du jour';

  @override
  String get wordHistory => 'Jours précédents';

  @override
  String get wordNotAvailable => 'Pas encore disponible';

  @override
  String get journalTitle => 'Mon Journal';

  @override
  String get journalSubtitle => 'Prends un moment pour écrire.';

  @override
  String get journalQ1 => '1. Qu\'est-ce que Dieu me montre aujourd\'hui ?';

  @override
  String get journalQ1Hint =>
      'Écris ici ce que Dieu met dans ton cœur à travers sa Parole, une situation, une pensée ou un verset.';

  @override
  String get journalQ2 => '2. Qu\'est-ce que je dois changer ?';

  @override
  String get journalQ2Hint =>
      'Quelles habitudes, pensées ou attitudes Dieu t\'appelle à laisser derrière toi ?';

  @override
  String get journalQ3 => '3. Pour qui dois-je prier ?';

  @override
  String get journalQ3Hint =>
      'Note les noms des personnes ou situations que tu veux présenter à Dieu.';

  @override
  String get journalGratitude => 'Journal de gratitude';

  @override
  String get journalGratitudeHint =>
      'Remercie Dieu pour 3 choses aujourd\'hui.';

  @override
  String get journalWriteHere => 'Écris ici...';

  @override
  String get journalSave => 'Enregistrer';

  @override
  String get journalSaved => 'Journal enregistré';

  @override
  String get prayerRoomTitle => 'Ma Prayer Room';

  @override
  String get prayerRoomSubtitle => 'Parle à Dieu. Dépose. Attends. Reçois.';

  @override
  String get prayerMyTopics => 'Mes sujets de prière';

  @override
  String get prayerMyTopicsSub => 'Tes intentions, tes besoins.';

  @override
  String get prayerAnswered => 'Mes prières exaucées';

  @override
  String get prayerAnsweredSub => 'Dieu a déjà agi. Garde trace.';

  @override
  String get prayerForSomeone => 'Prier pour quelqu\'un';

  @override
  String get prayerForSomeoneSub => 'Intercède. Porte. Aime.';

  @override
  String get prayerJournal => 'Garde un cœur de prière';

  @override
  String get prayerJournalSub => 'Ouvrir mon journal.';

  @override
  String get prayerVerse => 'Verset de prière';

  @override
  String get prayerAdd => 'Nouveau sujet de prière';

  @override
  String get prayerTitleField => 'Sujet de prière';

  @override
  String get prayerDetailsField => 'Détails (facultatif)';

  @override
  String get prayerShare => 'Partager avec la communauté pour qu\'elle prie';

  @override
  String get prayerAnonymous => 'Rester anonyme';

  @override
  String get prayerMarkAnswered => 'Dieu a exaucé !';

  @override
  String get prayerTestimony => 'Ton témoignage (facultatif)';

  @override
  String get prayerEmpty => 'Aucun sujet de prière. Ajoute ton premier.';

  @override
  String get prayerAnsweredEmpty => 'Tes prières exaucées apparaîtront ici.';

  @override
  String get prayerCommunityEmpty =>
      'Aucune demande de prière partagée pour le moment.';

  @override
  String get prayerIPrayed => 'J\'ai prié';

  @override
  String prayerPrayedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personnes ont prié',
      one: '1 personne a prié',
      zero: 'Sois le premier à prier',
    );
    return '$_temp0';
  }

  @override
  String get anonymous => 'Anonyme';

  @override
  String get impactTitle => 'Ton impact du jour';

  @override
  String get impactSubtitle => 'Un petit geste. Un grand impact.';

  @override
  String get impactChallenge => 'Défi du jour';

  @override
  String get impactAccept => 'JE RELÈVE LE DÉFI';

  @override
  String get impactDone => 'DÉFI RELEVÉ';

  @override
  String get impactWeek => 'Ma progression cette semaine';

  @override
  String get impactStreak => 'Impact Streak';

  @override
  String get impactTotal => 'Total des impacts';

  @override
  String get impactTotalSub => 'Petits gestes. Grands changements.';

  @override
  String get impactNoChallenge => 'Aucun défi publié pour aujourd\'hui.';

  @override
  String get impactNotePrompt => 'Comment ça s\'est passé ? (facultatif)';

  @override
  String get weekdaysShort => 'Lun,Mar,Mer,Jeu,Ven,Sam,Dim';

  @override
  String get monthsShort =>
      'janv.,févr.,mars,avr.,mai,juin,juil.,août,sept.,oct.,nov.,déc.';

  @override
  String get sosTitle => 'Holy SOS';

  @override
  String get sosSubtitle =>
      'Tu n\'es pas seul. Partage ton besoin, nous prions et agissons avec toi.';

  @override
  String get sosBannerTitle => 'Dieu voit. La famille agit.';

  @override
  String get sosBannerText =>
      'Confie ton besoin en toute confidentialité. Notre communauté prie pour toi et t\'apporte un soutien réel.';

  @override
  String get sosBannerTags => 'Confidentiel. Bienveillant. Fraternel.';

  @override
  String get sosNeedHelp => 'J\'ai besoin d\'aide';

  @override
  String get sosNeedHelpSub => 'Déposer ma demande';

  @override
  String get sosWantHelp => 'Je veux aider';

  @override
  String get sosWantHelpSub => 'Soutenir un frère / une sœur';

  @override
  String get sosMyRequests => 'Mes demandes';

  @override
  String get sosMyRequestsSub => 'Suivre tes demandes et réponses';

  @override
  String get sosQ1 => '1. Quel type de besoin veux-tu partager ?';

  @override
  String get sosQ2 => '2. Décris ton besoin';

  @override
  String get sosQ2Hint =>
      'Écris ici ton besoin. Sois libre et précis si tu le souhaites...';

  @override
  String get sosQ3 => '3. Veux-tu rester anonyme ?';

  @override
  String get sosQ3Sub => 'Ton identité restera confidentielle.';

  @override
  String get sosLeadersOnly =>
      'Seuls les responsables peuvent voir cette demande';

  @override
  String get sosSend => 'Envoyer ma demande';

  @override
  String get sosSent => 'Ta demande a été envoyée. Nous prions pour toi.';

  @override
  String get sosOffer => 'Proposer mon aide';

  @override
  String get sosOfferHint =>
      'Écris un message d\'encouragement ou explique comment tu peux aider...';

  @override
  String get sosOfferSent => 'Merci ! Ta proposition a été envoyée.';

  @override
  String sosOffers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count propositions d\'aide',
      one: '1 proposition d\'aide',
      zero: 'Aucune proposition',
    );
    return '$_temp0';
  }

  @override
  String get sosEmpty => 'Aucun besoin partagé pour le moment. Gloire à Dieu !';

  @override
  String get sosConfidential => 'Confidentialité garantie';

  @override
  String get sosConfidentialText =>
      'Chaque demande est traitée avec dignité, discrétion et amour par les responsables.';

  @override
  String get catPrayer => 'Prière';

  @override
  String get catFinancial => 'Financier';

  @override
  String get catHealth => 'Santé';

  @override
  String get catEmotional => 'Émotionnel';

  @override
  String get catStudiesWork => 'Études / Travail';

  @override
  String get catOther => 'Autre';

  @override
  String get statusOpen => 'Ouvert';

  @override
  String get statusInProgress => 'En cours';

  @override
  String get statusResolved => 'Résolu';

  @override
  String get statusClosed => 'Fermé';

  @override
  String get inboxTitle => 'Messages & Notifications';

  @override
  String get inboxSubtitle => 'Reste connecté. Ne manque rien d\'important.';

  @override
  String get inboxMessages => 'Messages';

  @override
  String get inboxNotifications => 'Notifications';

  @override
  String get inboxNewConversation => 'Parler à un responsable';

  @override
  String get inboxEmpty =>
      'Aucune conversation. Tes responsables sont là pour t\'écouter.';

  @override
  String get notificationsEmpty => 'Aucune notification pour le moment.';

  @override
  String get chatSubject => 'Sujet';

  @override
  String get chatSubjectHint =>
      'ex. J\'ai besoin d\'un conseil, je traverse une période difficile...';

  @override
  String get chatFirstMessage => 'Ton message';

  @override
  String get chatFirstMessageHint =>
      'Ouvre ton cœur. Seuls les pasteurs et responsables liront ceci.';

  @override
  String get chatTypeMessage => 'Écris un message...';

  @override
  String get chatStart => 'Envoyer';

  @override
  String get chatPrivateNotice =>
      'Conversation privée avec les responsables de l\'église.';

  @override
  String get chatLeader => 'Responsable';

  @override
  String get chatClosed =>
      'Cette conversation a été clôturée par les responsables.';

  @override
  String get profileTitle => 'Mon Profil';

  @override
  String get profileSubtitle => 'Dieu te connaît. Marche avec Lui.';

  @override
  String get profileStreak => 'Jours consécutifs';

  @override
  String get profileImpacts => 'Impacts réalisés';

  @override
  String get profileDevotions => 'Dévotions complétées';

  @override
  String get profileAnswered => 'Prières exaucées';

  @override
  String get profilePersonalInfo => 'Informations personnelles';

  @override
  String get profilePersonalInfoSub => 'Gère ton profil et tes préférences.';

  @override
  String get profileLanguage => 'Langue';

  @override
  String get profileLanguageSub => 'Français, English, Yorùbá';

  @override
  String get profileSos => 'Besoins & Requests (Holy SOS)';

  @override
  String get profileSosSub => 'Partage un besoin. Reçois du soutien.';

  @override
  String get profileMessages => 'Messages & Notifications';

  @override
  String get profileMessagesSub => 'Parle à tes responsables.';

  @override
  String get profileAbout => 'À propos';

  @override
  String get profileAboutSub => 'En savoir plus sur Impact-365.';

  @override
  String get profileAboutText =>
      'Impact-365 t\'aide à rencontrer Dieu chaque jour à travers sa Parole, la prière et des gestes d\'amour concrets.';

  @override
  String get profileSignOut => 'Se déconnecter';

  @override
  String get profileSave => 'Enregistrer';

  @override
  String get profileSaved => 'Profil mis à jour';

  @override
  String profileImpacterSince(int days) {
    return 'Impacteur depuis $days jours';
  }

  @override
  String get newBadge => 'NOUVEAU';

  @override
  String get commonCancel => 'Annuler';

  @override
  String get commonSubmit => 'Valider';

  @override
  String get commonRetry => 'Réessayer';

  @override
  String get commonError => 'Une erreur est survenue. Réessaie.';

  @override
  String get commonSeeAll => 'Tout voir';

  @override
  String get commonToday => 'Aujourd\'hui';

  @override
  String get commonYesterday => 'Hier';

  @override
  String get profileVerse => 'Je puis tout par Celui qui me fortifie.';

  @override
  String get profileVerseRef => 'Philippiens 4:13';

  @override
  String get journalVerse =>
      'Médite jour et nuit sur cette Parole, afin de mettre en pratique tout ce qui y est écrit.';

  @override
  String get journalVerseRef => 'Josué 1:8';

  @override
  String get prayerRoomVerse =>
      'Ne vous inquiétez de rien ; mais en toute chose faites connaître vos besoins à Dieu par des prières et des supplications, avec des actions de grâces.';

  @override
  String get prayerRoomVerseRef => 'Philippiens 4:6';

  @override
  String get sosVerse => '« Votre Père sait de quoi vous avez besoin. »';

  @override
  String get sosVerseRef => 'Matthieu 6:8';

  @override
  String get sosMyEmpty => 'Tu n\'as encore déposé aucune demande.';

  @override
  String get phoneLabel => 'Téléphone';

  @override
  String get onbSkip => 'Passer';

  @override
  String get onbNext => 'Suivant';

  @override
  String get onbStart => 'Commencer';

  @override
  String get onb1Title => 'Rencontre Dieu chaque jour';

  @override
  String get onb1Text =>
      'Matin, après-midi et soir, reçois une dévotion courte et profonde : la Parole, ce qu\'elle veut dire, et comment la vivre aujourd\'hui.';

  @override
  String get onb2Title => 'Prie, et ne marche jamais seul';

  @override
  String get onb2Text =>
      'Dépose tes sujets de prière, célèbre les exaucements et porte les autres dans la prière. Besoin d\'aide ? Ta famille d\'église est là, en toute confidentialité.';

  @override
  String get onb3Title => 'Un jour, un impact';

  @override
  String get onb3Text =>
      'Relève chaque jour un petit défi, tiens ton journal et grandis pas à pas : 365 jours pour laisser une empreinte éternelle.';

  @override
  String get onbReplay => 'Revoir l\'introduction';

  @override
  String get welcomeTitle => 'Bienvenue sur';

  @override
  String get welcomeSubtitle =>
      'Commence ton parcours spirituel un jour à la fois';

  @override
  String get welcomeSignIn => 'Se connecter';

  @override
  String get welcomeSignUp => 'Créer un compte';

  @override
  String get welcomeVerse =>
      'Les bontés de l\'Éternel ne sont pas épuisées ; elles se renouvellent chaque matin.';

  @override
  String get welcomeVerseRef => 'Lamentations 3:22-23';

  @override
  String get signInTitle => 'Content de te revoir';

  @override
  String get signInSubtitle =>
      'Connecte-toi pour continuer ton parcours avec Dieu.';

  @override
  String get signUpTitle => 'Crée ton compte';

  @override
  String get signUpSubtitle =>
      'Rejoins la famille Impact-365 et commence dès aujourd\'hui.';

  @override
  String get authEmailHint => 'ton@email.com';

  @override
  String get authPasswordHint =>
      'Au moins 8 caractères, avec lettres et chiffres';

  @override
  String get authFullNameHint => 'Prénom et nom';

  @override
  String get authConfirmPassword => 'Confirmer le mot de passe';

  @override
  String get authConfirmPasswordHint => 'Retape ton mot de passe';

  @override
  String get authForgot => 'Mot de passe oublié ?';

  @override
  String get authNoAccountQ => 'Pas encore de compte ?';

  @override
  String get authHaveAccountQ => 'Déjà un compte ?';

  @override
  String get authErrRequired => 'Ce champ est obligatoire';

  @override
  String get authErrEmail => 'Entre une adresse e-mail valide';

  @override
  String get authErrPasswordShort => 'Au moins 8 caractères';

  @override
  String get authErrPasswordMatch => 'Les mots de passe ne correspondent pas';

  @override
  String get authErrInvalidCredentials => 'E-mail ou mot de passe incorrect.';

  @override
  String get authErrEmailTaken => 'Un compte existe déjà avec cet e-mail.';

  @override
  String get authErrNotConfirmed =>
      'Confirme d\'abord ton e-mail — vérifie ta boîte mail.';

  @override
  String get authErrNetwork => 'Pas de connexion internet. Réessaie.';

  @override
  String get authTerms =>
      'En créant un compte, tu acceptes nos conditions d\'utilisation et notre politique de confidentialité.';

  @override
  String get authCheckEmailTitle => 'Vérifie ta boîte mail';

  @override
  String authCheckEmailText(String email) {
    return 'Nous avons envoyé un code à 6 chiffres à $email. Entre-le ci-dessous pour activer ton compte.';
  }

  @override
  String get authBackToSignIn => 'Retour à la connexion';

  @override
  String get authResetTitle => 'Réinitialiser le mot de passe';

  @override
  String get authResetText =>
      'Entre ton e-mail, nous t\'enverrons un code à 6 chiffres pour choisir un nouveau mot de passe.';

  @override
  String get authResetSend => 'Envoyer le code';

  @override
  String get authResetSent => 'Code envoyé ! Vérifie ta boîte mail.';

  @override
  String get authResend => 'Renvoyer le code';

  @override
  String authResendIn(int seconds) {
    return 'Renvoyer dans $seconds s';
  }

  @override
  String get authResent => 'Nouveau code envoyé !';

  @override
  String get authCheckSpam =>
      'Introuvable ? Regarde dans tes spams ou l\'onglet Promotions.';

  @override
  String get newPasswordTitle => 'Nouveau mot de passe';

  @override
  String get newPasswordSubtitle =>
      'Choisis un nouveau mot de passe pour ton compte.';

  @override
  String get newPasswordLabel => 'Nouveau mot de passe';

  @override
  String get newPasswordSave => 'Enregistrer mon mot de passe';

  @override
  String get newPasswordDone =>
      'Mot de passe mis à jour. Content de te revoir !';

  @override
  String get authErrSamePassword =>
      'Le nouveau mot de passe doit être différent de l\'ancien.';

  @override
  String get authErrRateLimit =>
      'Trop de tentatives. Patiente un instant puis réessaie.';

  @override
  String get authErrLinkExpired =>
      'Ce lien a expiré ou a déjà été utilisé. Demandes-en un nouveau.';

  @override
  String get authErrTimeout =>
      'Le serveur met trop de temps à répondre. Vérifie ta connexion et réessaie.';

  @override
  String get authErrEmailSend =>
      'Impossible d\'envoyer l\'e-mail pour le moment. Réessaie plus tard.';

  @override
  String get authCodeResetTitle => 'Entre le code';

  @override
  String authCodeResetText(String email) {
    return 'Nous avons envoyé un code à 6 chiffres à $email. Entre-le pour choisir un nouveau mot de passe.';
  }

  @override
  String get authCodeVerify => 'Vérifier';

  @override
  String get authErrCodeInvalid =>
      'Ce code est incorrect ou a expiré. Vérifie-le ou demandes-en un nouveau.';

  @override
  String get authPasswordSignInHint => 'Ton mot de passe';

  @override
  String get authErrPasswordWeak =>
      'Utilise des lettres et au moins un chiffre';

  @override
  String get errRateLimit =>
      'Tu le fais trop souvent. Patiente un peu puis réessaie.';

  @override
  String get authErrTooManyCodes =>
      'Trop de codes incorrects. Pour ta sécurité, demande un nouveau code.';

  @override
  String authSignInLocked(int seconds) {
    return 'Trop de tentatives échouées. Réessaie dans $seconds s.';
  }
}
