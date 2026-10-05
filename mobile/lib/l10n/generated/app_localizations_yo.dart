// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Yoruba (`yo`).
class AppLocalizationsYo extends AppLocalizations {
  AppLocalizationsYo([String locale = 'yo']) : super(locale);

  @override
  String get appTagline => 'Ọjọ́ kan, ipa kan';

  @override
  String get navHome => 'Ilé';

  @override
  String get navWord => 'Ọ̀rọ̀';

  @override
  String get navPrayer => 'Àdúrà';

  @override
  String get navImpact => 'Ipa';

  @override
  String get navProfile => 'Profáìlì';

  @override
  String get authWelcome => 'Ẹ kú àbọ̀ sí Impact-365';

  @override
  String get authSubtitle => 'Ọjọ́ tuntun. Ìpàdé tuntun pẹ̀lú Ọlọ́run.';

  @override
  String get authEmail => 'Ímeèlì';

  @override
  String get authPassword => 'Ọ̀rọ̀ aṣínà';

  @override
  String get authFullName => 'Orúkọ kíkún';

  @override
  String get authSignIn => 'Wọlé';

  @override
  String get authSignUp => 'Ṣẹ̀dá àkáǹtì mi';

  @override
  String get authNoAccount => 'O kò ní àkáǹtì? Forúkọsílẹ̀';

  @override
  String get authHaveAccount => 'O ti ní àkáǹtì? Wọlé';

  @override
  String get authCheckEmail => 'Ṣàyẹ̀wò ímeèlì rẹ láti jẹ́rìí àkáǹtì rẹ.';

  @override
  String get authInvalid => 'Kún gbogbo àyè (ọ̀rọ̀ aṣínà: ó kéré tán lẹ́tà 6).';

  @override
  String homeGreeting(String name) {
    return 'Ẹ kú ọjọ́, $name.';
  }

  @override
  String get homeGreetingDefault => 'Olùfipa';

  @override
  String get homeSubtitle => 'Ọjọ́ tuntun.\nÌpàdé tuntun pẹ̀lú Ọlọ́run.';

  @override
  String homeDayCounter(int day) {
    return 'Ọjọ́ $day / 365';
  }

  @override
  String get homeCurrentStreak => 'Ìtẹ̀léra lọ́wọ́lọ́wọ́';

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ọjọ́ $count',
      one: 'Ọjọ́ 1',
      zero: 'Ọjọ́ 0',
    );
    return '$_temp0';
  }

  @override
  String get homeVerseOfDay => 'Ẹsẹ ọjọ́ òní';

  @override
  String get homeStartDevotion => 'BẸ̀RẸ̀ ÌFỌKÀNSÌN MI';

  @override
  String get homeThemeOfDay => 'Àkòrí ọjọ́ òní';

  @override
  String get homeToday => 'Òní';

  @override
  String get homeYourWord => 'Ọ̀rọ̀ rẹ';

  @override
  String get homeYourPrayer => 'Àdúrà rẹ';

  @override
  String get homeYourImpact => 'Ipa rẹ';

  @override
  String get homeDiscover => 'Ṣàwárí';

  @override
  String get homePray => 'Gbàdúrà';

  @override
  String get homeAct => 'Ṣe é';

  @override
  String get homeFaithJourney => 'Ìrìn àjò ìgbàgbọ́';

  @override
  String get homeFaithJourneyText =>
      'Ìdúróṣinṣin rẹ ń ṣe àgbékalẹ̀ ipa ayérayé rẹ.';

  @override
  String get homeNoDevotion => 'Kò sí ìfọkànsìn fún òní síbẹ̀. Padà wá láìpẹ́!';

  @override
  String get slotMorning => 'Òwúrọ̀';

  @override
  String get slotAfternoon => 'Ọ̀sán';

  @override
  String get slotNight => 'Alẹ́';

  @override
  String get devotionTitle => 'ÌṢẸ́JÚ 5 PẸ̀LÚ ỌLỌ́RUN';

  @override
  String get devotionGodSays => 'OHUN TÍ ỌLỌ́RUN SỌ';

  @override
  String get devotionIUnderstand => 'OHUN TÍ MO LÓYE';

  @override
  String get devotionIDo => 'OHUN TÍ MO MÁA ṢE';

  @override
  String get devotionDone => 'MO TI LÓYE';

  @override
  String get devotionCompleted => 'Ó ti parí';

  @override
  String get devotionListen => 'GBỌ́ OHÙN';

  @override
  String get devotionPause => 'DÁ OHÙN DÚRÓ';

  @override
  String get devotionQuestionTitle => 'Ṣé o ní ìbéèrè?';

  @override
  String get devotionQuestionText =>
      'Kọ ọ́, olórí kan yóò fi ayọ̀ ràn ọ́ lọ́wọ́.';

  @override
  String get devotionAskQuestion => 'Béèrè ìbéèrè mi';

  @override
  String get wordTodayTitle => 'Àwọn ìfọkànsìn òní';

  @override
  String get wordHistory => 'Àwọn ọjọ́ tó kọjá';

  @override
  String get wordNotAvailable => 'Kò tíì sí';

  @override
  String get journalTitle => 'Ìwé Àkọsílẹ̀ Mi';

  @override
  String get journalSubtitle => 'Mú àkókò díẹ̀ láti kọ̀wé.';

  @override
  String get journalQ1 => '1. Kí ni Ọlọ́run ń fi hàn mí lónìí?';

  @override
  String get journalQ1Hint =>
      'Kọ ohun tí Ọlọ́run fi sí ọkàn rẹ nípasẹ̀ Ọ̀rọ̀ Rẹ̀, ipò kan, èrò kan tàbí ẹsẹ kan.';

  @override
  String get journalQ2 => '2. Kí ni mo gbọ́dọ̀ yí padà?';

  @override
  String get journalQ2Hint =>
      'Àwọn àṣà, èrò tàbí ìwà wo ni Ọlọ́run ń pè ọ́ láti fi sílẹ̀?';

  @override
  String get journalQ3 => '3. Ta ni mo gbọ́dọ̀ gbàdúrà fún?';

  @override
  String get journalQ3Hint =>
      'Kọ orúkọ àwọn ènìyàn tàbí ipò tí o fẹ́ gbé wá síwájú Ọlọ́run.';

  @override
  String get journalGratitude => 'Ìwé ìdúpẹ́';

  @override
  String get journalGratitudeHint =>
      'Dúpẹ́ lọ́wọ́ Ọlọ́run fún nǹkan mẹ́ta lónìí.';

  @override
  String get journalWriteHere => 'Kọ síbí...';

  @override
  String get journalSave => 'Fipamọ́';

  @override
  String get journalSaved => 'A ti fi àkọsílẹ̀ pamọ́';

  @override
  String get prayerRoomTitle => 'Yàrá Àdúrà Mi';

  @override
  String get prayerRoomSubtitle =>
      'Bá Ọlọ́run sọ̀rọ̀. Gbé e kalẹ̀. Dúró. Gbà á.';

  @override
  String get prayerMyTopics => 'Àwọn kókó àdúrà mi';

  @override
  String get prayerMyTopicsSub => 'Àwọn èrò rẹ, àwọn àìní rẹ.';

  @override
  String get prayerAnswered => 'Àwọn àdúrà mi tí a ti dáhùn';

  @override
  String get prayerAnsweredSub => 'Ọlọ́run ti ṣe é. Ṣe àkọsílẹ̀.';

  @override
  String get prayerForSomeone => 'Gbàdúrà fún ẹnìkan';

  @override
  String get prayerForSomeoneSub => 'Bẹ̀bẹ̀. Rù ú. Nífẹ̀ẹ́.';

  @override
  String get prayerJournal => 'Pa ọkàn àdúrà mọ́';

  @override
  String get prayerJournalSub => 'Ṣí ìwé àkọsílẹ̀ mi.';

  @override
  String get prayerVerse => 'Ẹsẹ àdúrà';

  @override
  String get prayerAdd => 'Kókó àdúrà tuntun';

  @override
  String get prayerTitleField => 'Kókó àdúrà';

  @override
  String get prayerDetailsField => 'Àlàyé (kò pọndandan)';

  @override
  String get prayerShare => 'Pín pẹ̀lú ìjọ kí wọ́n lè gbàdúrà';

  @override
  String get prayerAnonymous => 'Má ṣe fi orúkọ hàn';

  @override
  String get prayerMarkAnswered => 'Ọlọ́run ti dáhùn!';

  @override
  String get prayerTestimony => 'Ẹ̀rí rẹ (kò pọndandan)';

  @override
  String get prayerEmpty => 'Kò sí kókó àdúrà síbẹ̀. Fi àkọ́kọ́ rẹ kún un.';

  @override
  String get prayerAnsweredEmpty => 'Àwọn àdúrà rẹ tí a dáhùn yóò hàn níbí.';

  @override
  String get prayerCommunityEmpty =>
      'Kò sí ìbéèrè àdúrà tí a pín lọ́wọ́lọ́wọ́.';

  @override
  String get prayerIPrayed => 'Mo ti gbàdúrà';

  @override
  String prayerPrayedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ènìyàn $count ti gbàdúrà',
      one: 'Ènìyàn 1 ti gbàdúrà',
      zero: 'Jẹ́ ẹni àkọ́kọ́ láti gbàdúrà',
    );
    return '$_temp0';
  }

  @override
  String get anonymous => 'Àìlórúkọ';

  @override
  String get impactTitle => 'Ipa rẹ lónìí';

  @override
  String get impactSubtitle => 'Ìṣe kékeré. Ipa ńlá.';

  @override
  String get impactChallenge => 'Ìpèníjà ọjọ́ òní';

  @override
  String get impactAccept => 'MO GBA ÌPÈNÍJÀ NÁÀ';

  @override
  String get impactDone => 'MO TI ṢE ÌPÈNÍJÀ NÁÀ';

  @override
  String get impactWeek => 'Ìtẹ̀síwájú mi ní ọ̀sẹ̀ yìí';

  @override
  String get impactStreak => 'Ìtẹ̀léra Ipa';

  @override
  String get impactTotal => 'Àpapọ̀ ipa';

  @override
  String get impactTotalSub => 'Ìṣe kékeré. Àyípadà ńlá.';

  @override
  String get impactNoChallenge => 'Kò sí ìpèníjà fún òní síbẹ̀.';

  @override
  String get impactNotePrompt => 'Báwo ló ṣe lọ? (kò pọndandan)';

  @override
  String get weekdaysShort => 'Ajé,Ìsẹ́,Rú,Bọ̀,Ẹtì,Àbá,Àìkú';

  @override
  String get monthsShort =>
      'Ṣẹ́rẹ́,Èrèlé,Ẹrẹ̀nà,Ìgbé,Ẹ̀bibi,Òkúdu,Agẹmọ,Ògún,Owewe,Ọ̀wàrà,Bélú,Ọ̀pẹ̀';

  @override
  String get sosTitle => 'Holy SOS';

  @override
  String get sosSubtitle =>
      'O kò dá wà. Pín àìní rẹ, a ń gbàdúrà a sì ń ṣiṣẹ́ pẹ̀lú rẹ.';

  @override
  String get sosBannerTitle => 'Ọlọ́run rí i. Ìdílé ń ṣiṣẹ́.';

  @override
  String get sosBannerText =>
      'Fi àìní rẹ lé wa lọ́wọ́ ní àṣírí. Ìjọ wa ń gbàdúrà fún ọ, ó sì ń ràn ọ́ lọ́wọ́ ní tòótọ́.';

  @override
  String get sosBannerTags => 'Àṣírí. Ìfẹ́. Ẹgbẹ́ ará.';

  @override
  String get sosNeedHelp => 'Mo nílò ìrànlọ́wọ́';

  @override
  String get sosNeedHelpSub => 'Fi ìbéèrè sílẹ̀';

  @override
  String get sosWantHelp => 'Mo fẹ́ ṣèrànwọ́';

  @override
  String get sosWantHelpSub => 'Ran arákùnrin tàbí arábìnrin lọ́wọ́';

  @override
  String get sosMyRequests => 'Àwọn ìbéèrè mi';

  @override
  String get sosMyRequestsSub => 'Tẹ̀lé àwọn ìbéèrè àti ìdáhùn rẹ';

  @override
  String get sosQ1 => '1. Irú àìní wo ni o fẹ́ pín?';

  @override
  String get sosQ2 => '2. Ṣàpèjúwe àìní rẹ';

  @override
  String get sosQ2Hint =>
      'Kọ àìní rẹ síbí. Ní òmìnira láti ṣàlàyé bí o ṣe fẹ́...';

  @override
  String get sosQ3 => '3. Ṣé o fẹ́ fi orúkọ rẹ pamọ́?';

  @override
  String get sosQ3Sub => 'Ìdánimọ̀ rẹ yóò wà ní àṣírí.';

  @override
  String get sosLeadersOnly => 'Àwọn olórí nìkan ni yóò rí ìbéèrè yìí';

  @override
  String get sosSend => 'Fi ìbéèrè mi ránṣẹ́';

  @override
  String get sosSent => 'A ti fi ìbéèrè rẹ ránṣẹ́. A ń gbàdúrà fún ọ.';

  @override
  String get sosOffer => 'Fún ní ìrànlọ́wọ́';

  @override
  String get sosOfferHint =>
      'Kọ ọ̀rọ̀ ìyànjú tàbí ṣàlàyé bí o ṣe lè ṣèrànwọ́...';

  @override
  String get sosOfferSent => 'O ṣé o! A ti fi ìrànlọ́wọ́ rẹ ránṣẹ́.';

  @override
  String sosOffers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ìrànlọ́wọ́ $count',
      one: 'Ìrànlọ́wọ́ 1',
      zero: 'Kò sí ìrànlọ́wọ́ síbẹ̀',
    );
    return '$_temp0';
  }

  @override
  String get sosEmpty =>
      'Kò sí àìní tí a pín lọ́wọ́lọ́wọ́. Ògo ni fún Ọlọ́run!';

  @override
  String get sosConfidential => 'Àṣírí tí a ṣèlérí';

  @override
  String get sosConfidentialText =>
      'Àwọn olórí ń bójútó gbogbo ìbéèrè pẹ̀lú ọ̀wọ̀, àṣírí àti ìfẹ́.';

  @override
  String get catPrayer => 'Àdúrà';

  @override
  String get catFinancial => 'Owó';

  @override
  String get catHealth => 'Ìlera';

  @override
  String get catEmotional => 'Ìmọ̀lára';

  @override
  String get catStudiesWork => 'Ẹ̀kọ́ / Iṣẹ́';

  @override
  String get catOther => 'Òmíràn';

  @override
  String get statusOpen => 'Ṣí sílẹ̀';

  @override
  String get statusInProgress => 'Ń lọ lọ́wọ́';

  @override
  String get statusResolved => 'Ó ti yanjú';

  @override
  String get statusClosed => 'Ó ti tì';

  @override
  String get inboxTitle => 'Ìfiránṣẹ́ & Ìkéde';

  @override
  String get inboxSubtitle => 'Dúró ní àsopọ̀. Má ṣe pàdánù ohun pàtàkì.';

  @override
  String get inboxMessages => 'Ìfiránṣẹ́';

  @override
  String get inboxNotifications => 'Ìkéde';

  @override
  String get inboxNewConversation => 'Bá olórí sọ̀rọ̀';

  @override
  String get inboxEmpty => 'Kò sí ìjíròrò síbẹ̀. Àwọn olórí rẹ wà láti gbọ́ ọ.';

  @override
  String get notificationsEmpty => 'Kò sí ìkéde síbẹ̀.';

  @override
  String get chatSubject => 'Àkòrí';

  @override
  String get chatSubjectHint =>
      'àpẹẹrẹ: Mo nílò ìmọ̀ràn, mo ń la àkókò líle kọjá...';

  @override
  String get chatFirstMessage => 'Ọ̀rọ̀ rẹ';

  @override
  String get chatFirstMessageHint =>
      'Tú ọkàn rẹ jáde. Àwọn olùṣọ́-àgùntàn àti olórí nìkan ni yóò kà á.';

  @override
  String get chatTypeMessage => 'Kọ ọ̀rọ̀ kan...';

  @override
  String get chatStart => 'Firánṣẹ́';

  @override
  String get chatPrivateNotice => 'Ìjíròrò àṣírí pẹ̀lú àwọn olórí ìjọ.';

  @override
  String get chatLeader => 'Olórí';

  @override
  String get chatClosed => 'Àwọn olórí ti ti ìjíròrò yìí.';

  @override
  String get profileTitle => 'Profáìlì Mi';

  @override
  String get profileSubtitle => 'Ọlọ́run mọ̀ ọ́. Bá A rìn.';

  @override
  String get profileStreak => 'Ọjọ́ ní ìtẹ̀léra';

  @override
  String get profileImpacts => 'Ipa tí a ṣe';

  @override
  String get profileDevotions => 'Ìfọkànsìn tí a parí';

  @override
  String get profileAnswered => 'Àdúrà tí a dáhùn';

  @override
  String get profilePersonalInfo => 'Ìwífún ti ara ẹni';

  @override
  String get profilePersonalInfoSub => 'Ṣàkóso profáìlì àti àṣàyàn rẹ.';

  @override
  String get profileLanguage => 'Èdè';

  @override
  String get profileLanguageSub => 'Français, English, Yorùbá';

  @override
  String get profileSos => 'Àìní & Ìbéèrè (Holy SOS)';

  @override
  String get profileSosSub => 'Pín àìní kan. Gba ìrànlọ́wọ́.';

  @override
  String get profileMessages => 'Ìfiránṣẹ́ & Ìkéde';

  @override
  String get profileMessagesSub => 'Bá àwọn olórí rẹ sọ̀rọ̀.';

  @override
  String get profileAbout => 'Nípa wa';

  @override
  String get profileAboutSub => 'Mọ̀ síi nípa Impact-365.';

  @override
  String get profileAboutText =>
      'Impact-365 ń ràn ọ́ lọ́wọ́ láti pàdé Ọlọ́run lójoojúmọ́ nípasẹ̀ Ọ̀rọ̀ Rẹ̀, àdúrà àti ìṣe ìfẹ́.';

  @override
  String get profileSignOut => 'Jáde';

  @override
  String get profileSave => 'Fipamọ́';

  @override
  String get profileSaved => 'A ti ṣe àtúnṣe profáìlì';

  @override
  String profileImpacterSince(int days) {
    return 'Olùfipa fún ọjọ́ $days';
  }

  @override
  String get newBadge => 'TUNTUN';

  @override
  String get commonCancel => 'Fagilé';

  @override
  String get commonSubmit => 'Fi ránṣẹ́';

  @override
  String get commonRetry => 'Gbìyànjú lẹ́ẹ̀kan síi';

  @override
  String get commonError => 'Àṣìṣe kan ṣẹlẹ̀. Jọ̀wọ́ gbìyànjú lẹ́ẹ̀kan síi.';

  @override
  String get commonSeeAll => 'Wo gbogbo rẹ̀';

  @override
  String get commonToday => 'Òní';

  @override
  String get commonYesterday => 'Àná';

  @override
  String get profileVerse =>
      'Mo lè ṣe ohun gbogbo nípasẹ̀ Kírísítì tí ń fún mi ní agbára.';

  @override
  String get profileVerseRef => 'Fílípì 4:13';

  @override
  String get journalVerse =>
      'Máa ṣe àṣàrò nínú rẹ̀ lọ́sàn-án àti lóru, kí o lè kíyèsí láti ṣe gẹ́gẹ́ bí gbogbo ohun tí a kọ sínú rẹ̀.';

  @override
  String get journalVerseRef => 'Jóṣúà 1:8';

  @override
  String get prayerRoomVerse =>
      'Ẹ má ṣe ṣàníyàn nípa ohunkóhun; ṣùgbọ́n nínú ohun gbogbo, nípa àdúrà àti ẹ̀bẹ̀ pẹ̀lú ọpẹ́, ẹ jẹ́ kí ìbéèrè yín di mímọ̀ fún Ọlọ́run.';

  @override
  String get prayerRoomVerseRef => 'Fílípì 4:6';

  @override
  String get sosVerse => '« Baba yín mọ ohun tí ẹ ṣe aláìní. »';

  @override
  String get sosVerseRef => 'Mátíù 6:8';

  @override
  String get sosMyEmpty => 'O kò tíì fi ìbéèrè kankan sílẹ̀.';

  @override
  String get phoneLabel => 'Fóònù';

  @override
  String get onbSkip => 'Fò ó';

  @override
  String get onbNext => 'Tókàn';

  @override
  String get onbStart => 'Bẹ̀rẹ̀';

  @override
  String get onb1Title => 'Pàdé Ọlọ́run lójoojúmọ́';

  @override
  String get onb1Text =>
      'Ní òwúrọ̀, ọ̀sán àti alẹ́, gba ìfọkànsìn kúkúrú tó jinlẹ̀: Ọ̀rọ̀ náà, ìtumọ̀ rẹ̀, àti bí o ṣe lè gbé e lónìí.';

  @override
  String get onb2Title => 'Gbàdúrà, má ṣe rìn nìkan';

  @override
  String get onb2Text =>
      'Gbé àwọn kókó àdúrà rẹ kalẹ̀, ṣe ayẹyẹ àdúrà tí a dáhùn, kí o sì gbé àwọn ẹlòmíràn ró nínú àdúrà. Ṣé o nílò ìrànlọ́wọ́? Ìdílé ìjọ rẹ wà níbí, ní àṣírí pátápátá.';

  @override
  String get onb3Title => 'Ọjọ́ kan, ipa kan';

  @override
  String get onb3Text =>
      'Gba ìpèníjà kékeré kan lójoojúmọ́, kọ ìwé àkọsílẹ̀ rẹ, kí o sì dàgbà díẹ̀díẹ̀: ọjọ́ 365 láti fi àmì ayérayé sílẹ̀.';

  @override
  String get onbReplay => 'Wo ìfihàn náà lẹ́ẹ̀kan síi';

  @override
  String get welcomeTitle => 'Ẹ kú àbọ̀ sí';

  @override
  String get welcomeSubtitle => 'Bẹ̀rẹ̀ ìrìn àjò ẹ̀mí rẹ ní ọjọ́ kan lẹ́ẹ̀kan';

  @override
  String get welcomeSignIn => 'Wọlé';

  @override
  String get welcomeSignUp => 'Ṣẹ̀dá àkáǹtì';

  @override
  String get welcomeVerse =>
      'Àánú Olúwa kò tán, ìyọ́nú rẹ̀ kò yẹ̀; wọ́n ń di ọ̀tun ní òròòwúrọ̀.';

  @override
  String get welcomeVerseRef => 'Ẹkún Jeremáyà 3:22-23';

  @override
  String get signInTitle => 'Ẹ kú àbọ̀ padà';

  @override
  String get signInSubtitle =>
      'Wọlé láti tẹ̀síwájú nínú ìrìn àjò rẹ pẹ̀lú Ọlọ́run.';

  @override
  String get signUpTitle => 'Ṣẹ̀dá àkáǹtì rẹ';

  @override
  String get signUpSubtitle =>
      'Darapọ̀ mọ́ ìdílé Impact-365 kí o sì bẹ̀rẹ̀ lónìí.';

  @override
  String get authEmailHint => 'iwo@email.com';

  @override
  String get authPasswordHint => 'Ó kéré tán lẹ́tà 6';

  @override
  String get authFullNameHint => 'Orúkọ àti orúkọ ìdílé';

  @override
  String get authConfirmPassword => 'Jẹ́rìí ọ̀rọ̀ aṣínà';

  @override
  String get authConfirmPasswordHint => 'Tún ọ̀rọ̀ aṣínà rẹ tẹ̀';

  @override
  String get authForgot => 'O gbàgbé ọ̀rọ̀ aṣínà?';

  @override
  String get authNoAccountQ => 'O kò ní àkáǹtì?';

  @override
  String get authHaveAccountQ => 'O ti ní àkáǹtì?';

  @override
  String get authErrRequired => 'Àyè yìí pọndandan';

  @override
  String get authErrEmail => 'Tẹ àdírẹ́sì ímeèlì tó tọ́';

  @override
  String get authErrPasswordShort => 'Ó kéré tán lẹ́tà 6';

  @override
  String get authErrPasswordMatch => 'Àwọn ọ̀rọ̀ aṣínà kò bára mu';

  @override
  String get authErrInvalidCredentials => 'Ímeèlì tàbí ọ̀rọ̀ aṣínà kò tọ́.';

  @override
  String get authErrEmailTaken => 'Àkáǹtì ti wà pẹ̀lú ímeèlì yìí.';

  @override
  String get authErrNotConfirmed =>
      'Jọ̀wọ́ kọ́kọ́ jẹ́rìí ímeèlì rẹ — ṣàyẹ̀wò àpótí ímeèlì rẹ.';

  @override
  String get authErrNetwork =>
      'Kò sí ìsopọ̀ íntánẹ́ẹ̀tì. Gbìyànjú lẹ́ẹ̀kan síi.';

  @override
  String get authTerms =>
      'Nípa ṣíṣẹ̀dá àkáǹtì, o gbà sí àwọn òfin ìlò àti ìlànà àṣírí wa.';

  @override
  String get authCheckEmailTitle => 'Ṣàyẹ̀wò àpótí ímeèlì rẹ';

  @override
  String authCheckEmailText(String email) {
    return 'A ti fi ìjápọ̀ ìjẹ́rìí ránṣẹ́ sí $email. Ṣí i láti mú àkáǹtì rẹ ṣiṣẹ́, lẹ́yìn náà wọlé.';
  }

  @override
  String get authBackToSignIn => 'Padà sí ìwọlé';

  @override
  String get authResetTitle => 'Tún ọ̀rọ̀ aṣínà rẹ ṣe';

  @override
  String get authResetText =>
      'Tẹ ímeèlì rẹ, a ó fi ìjápọ̀ ránṣẹ́ sí ọ láti yan ọ̀rọ̀ aṣínà tuntun.';

  @override
  String get authResetSend => 'Fi ìjápọ̀ ránṣẹ́';

  @override
  String get authResetSent => 'A ti fi ìjápọ̀ ránṣẹ́! Ṣàyẹ̀wò àpótí ímeèlì rẹ.';
}
