import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_yo.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
    Locale('yo'),
  ];

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'1 day 1 impact'**
  String get appTagline;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navWord.
  ///
  /// In en, this message translates to:
  /// **'Word'**
  String get navWord;

  /// No description provided for @navPrayer.
  ///
  /// In en, this message translates to:
  /// **'Prayer'**
  String get navPrayer;

  /// No description provided for @navImpact.
  ///
  /// In en, this message translates to:
  /// **'Impact'**
  String get navImpact;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @authWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Impact-365'**
  String get authWelcome;

  /// No description provided for @authSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A new day. A new encounter with God.'**
  String get authSubtitle;

  /// No description provided for @authEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmail;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authFullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get authFullName;

  /// No description provided for @authSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignIn;

  /// No description provided for @authSignUp.
  ///
  /// In en, this message translates to:
  /// **'Create my account'**
  String get authSignUp;

  /// No description provided for @authNoAccount.
  ///
  /// In en, this message translates to:
  /// **'No account yet? Sign up'**
  String get authNoAccount;

  /// No description provided for @authHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get authHaveAccount;

  /// No description provided for @authCheckEmail.
  ///
  /// In en, this message translates to:
  /// **'Check your email to confirm your account.'**
  String get authCheckEmail;

  /// No description provided for @authInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields (password: 6 characters minimum).'**
  String get authInvalid;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Good day, {name}.'**
  String homeGreeting(String name);

  /// No description provided for @homeGreetingDefault.
  ///
  /// In en, this message translates to:
  /// **'Impacter'**
  String get homeGreetingDefault;

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A new day.\nA new encounter with God.'**
  String get homeSubtitle;

  /// No description provided for @homeDayCounter.
  ///
  /// In en, this message translates to:
  /// **'Day {day} / 365'**
  String homeDayCounter(int day);

  /// No description provided for @homeCurrentStreak.
  ///
  /// In en, this message translates to:
  /// **'Current streak'**
  String get homeCurrentStreak;

  /// No description provided for @daysCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 days} =1{1 day} other{{count} days}}'**
  String daysCount(int count);

  /// No description provided for @homeVerseOfDay.
  ///
  /// In en, this message translates to:
  /// **'Verse of the day'**
  String get homeVerseOfDay;

  /// No description provided for @homeStartDevotion.
  ///
  /// In en, this message translates to:
  /// **'START MY DEVOTION'**
  String get homeStartDevotion;

  /// No description provided for @homeThemeOfDay.
  ///
  /// In en, this message translates to:
  /// **'Theme of the day'**
  String get homeThemeOfDay;

  /// No description provided for @homeToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get homeToday;

  /// No description provided for @homeYourWord.
  ///
  /// In en, this message translates to:
  /// **'Your Word'**
  String get homeYourWord;

  /// No description provided for @homeYourPrayer.
  ///
  /// In en, this message translates to:
  /// **'Your prayer'**
  String get homeYourPrayer;

  /// No description provided for @homeYourImpact.
  ///
  /// In en, this message translates to:
  /// **'Your impact'**
  String get homeYourImpact;

  /// No description provided for @homeDiscover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get homeDiscover;

  /// No description provided for @homePray.
  ///
  /// In en, this message translates to:
  /// **'Pray'**
  String get homePray;

  /// No description provided for @homeAct.
  ///
  /// In en, this message translates to:
  /// **'Act'**
  String get homeAct;

  /// No description provided for @homeFaithJourney.
  ///
  /// In en, this message translates to:
  /// **'Faith journey'**
  String get homeFaithJourney;

  /// No description provided for @homeFaithJourneyText.
  ///
  /// In en, this message translates to:
  /// **'Your consistency shapes your eternal impact.'**
  String get homeFaithJourneyText;

  /// No description provided for @homeNoDevotion.
  ///
  /// In en, this message translates to:
  /// **'No devotion published yet for today. Come back soon!'**
  String get homeNoDevotion;

  /// No description provided for @slotMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get slotMorning;

  /// No description provided for @slotAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get slotAfternoon;

  /// No description provided for @slotNight.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get slotNight;

  /// No description provided for @devotionTitle.
  ///
  /// In en, this message translates to:
  /// **'5 MINUTES WITH GOD'**
  String get devotionTitle;

  /// No description provided for @devotionGodSays.
  ///
  /// In en, this message translates to:
  /// **'WHAT GOD SAYS'**
  String get devotionGodSays;

  /// No description provided for @devotionIUnderstand.
  ///
  /// In en, this message translates to:
  /// **'WHAT I UNDERSTAND'**
  String get devotionIUnderstand;

  /// No description provided for @devotionIDo.
  ///
  /// In en, this message translates to:
  /// **'WHAT I DO'**
  String get devotionIDo;

  /// No description provided for @devotionDone.
  ///
  /// In en, this message translates to:
  /// **'I UNDERSTOOD'**
  String get devotionDone;

  /// No description provided for @devotionCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get devotionCompleted;

  /// No description provided for @devotionListen.
  ///
  /// In en, this message translates to:
  /// **'LISTEN TO AUDIO'**
  String get devotionListen;

  /// No description provided for @devotionPause.
  ///
  /// In en, this message translates to:
  /// **'PAUSE AUDIO'**
  String get devotionPause;

  /// No description provided for @devotionQuestionTitle.
  ///
  /// In en, this message translates to:
  /// **'A question?'**
  String get devotionQuestionTitle;

  /// No description provided for @devotionQuestionText.
  ///
  /// In en, this message translates to:
  /// **'Write it, a leader will gladly help you.'**
  String get devotionQuestionText;

  /// No description provided for @devotionAskQuestion.
  ///
  /// In en, this message translates to:
  /// **'Ask my question'**
  String get devotionAskQuestion;

  /// No description provided for @wordTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s devotions'**
  String get wordTodayTitle;

  /// No description provided for @wordHistory.
  ///
  /// In en, this message translates to:
  /// **'Previous days'**
  String get wordHistory;

  /// No description provided for @wordNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not yet available'**
  String get wordNotAvailable;

  /// No description provided for @journalTitle.
  ///
  /// In en, this message translates to:
  /// **'My Journal'**
  String get journalTitle;

  /// No description provided for @journalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Take a moment to write.'**
  String get journalSubtitle;

  /// No description provided for @journalQ1.
  ///
  /// In en, this message translates to:
  /// **'1. What is God showing me today?'**
  String get journalQ1;

  /// No description provided for @journalQ1Hint.
  ///
  /// In en, this message translates to:
  /// **'Write what God puts in your heart through His Word, a situation, a thought or a verse.'**
  String get journalQ1Hint;

  /// No description provided for @journalQ2.
  ///
  /// In en, this message translates to:
  /// **'2. What must I change?'**
  String get journalQ2;

  /// No description provided for @journalQ2Hint.
  ///
  /// In en, this message translates to:
  /// **'What habits, thoughts or attitudes is God calling you to leave behind?'**
  String get journalQ2Hint;

  /// No description provided for @journalQ3.
  ///
  /// In en, this message translates to:
  /// **'3. Who should I pray for?'**
  String get journalQ3;

  /// No description provided for @journalQ3Hint.
  ///
  /// In en, this message translates to:
  /// **'Note the names of people or situations you want to present to God.'**
  String get journalQ3Hint;

  /// No description provided for @journalGratitude.
  ///
  /// In en, this message translates to:
  /// **'Gratitude journal'**
  String get journalGratitude;

  /// No description provided for @journalGratitudeHint.
  ///
  /// In en, this message translates to:
  /// **'Thank God for 3 things today.'**
  String get journalGratitudeHint;

  /// No description provided for @journalWriteHere.
  ///
  /// In en, this message translates to:
  /// **'Write here...'**
  String get journalWriteHere;

  /// No description provided for @journalSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get journalSave;

  /// No description provided for @journalSaved.
  ///
  /// In en, this message translates to:
  /// **'Journal saved'**
  String get journalSaved;

  /// No description provided for @prayerRoomTitle.
  ///
  /// In en, this message translates to:
  /// **'My Prayer Room'**
  String get prayerRoomTitle;

  /// No description provided for @prayerRoomSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Talk to God. Lay it down. Wait. Receive.'**
  String get prayerRoomSubtitle;

  /// No description provided for @prayerMyTopics.
  ///
  /// In en, this message translates to:
  /// **'My prayer points'**
  String get prayerMyTopics;

  /// No description provided for @prayerMyTopicsSub.
  ///
  /// In en, this message translates to:
  /// **'Your intentions, your needs.'**
  String get prayerMyTopicsSub;

  /// No description provided for @prayerAnswered.
  ///
  /// In en, this message translates to:
  /// **'My answered prayers'**
  String get prayerAnswered;

  /// No description provided for @prayerAnsweredSub.
  ///
  /// In en, this message translates to:
  /// **'God has already acted. Keep track.'**
  String get prayerAnsweredSub;

  /// No description provided for @prayerForSomeone.
  ///
  /// In en, this message translates to:
  /// **'Pray for someone'**
  String get prayerForSomeone;

  /// No description provided for @prayerForSomeoneSub.
  ///
  /// In en, this message translates to:
  /// **'Intercede. Carry. Love.'**
  String get prayerForSomeoneSub;

  /// No description provided for @prayerJournal.
  ///
  /// In en, this message translates to:
  /// **'Keep a heart of prayer'**
  String get prayerJournal;

  /// No description provided for @prayerJournalSub.
  ///
  /// In en, this message translates to:
  /// **'Open my journal.'**
  String get prayerJournalSub;

  /// No description provided for @prayerVerse.
  ///
  /// In en, this message translates to:
  /// **'Prayer verse'**
  String get prayerVerse;

  /// No description provided for @prayerAdd.
  ///
  /// In en, this message translates to:
  /// **'New prayer point'**
  String get prayerAdd;

  /// No description provided for @prayerTitleField.
  ///
  /// In en, this message translates to:
  /// **'Prayer point'**
  String get prayerTitleField;

  /// No description provided for @prayerDetailsField.
  ///
  /// In en, this message translates to:
  /// **'Details (optional)'**
  String get prayerDetailsField;

  /// No description provided for @prayerShare.
  ///
  /// In en, this message translates to:
  /// **'Share with the community so they can pray'**
  String get prayerShare;

  /// No description provided for @prayerAnonymous.
  ///
  /// In en, this message translates to:
  /// **'Stay anonymous'**
  String get prayerAnonymous;

  /// No description provided for @prayerMarkAnswered.
  ///
  /// In en, this message translates to:
  /// **'God answered!'**
  String get prayerMarkAnswered;

  /// No description provided for @prayerTestimony.
  ///
  /// In en, this message translates to:
  /// **'Your testimony (optional)'**
  String get prayerTestimony;

  /// No description provided for @prayerEmpty.
  ///
  /// In en, this message translates to:
  /// **'No prayer points yet. Add your first one.'**
  String get prayerEmpty;

  /// No description provided for @prayerAnsweredEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your answered prayers will appear here.'**
  String get prayerAnsweredEmpty;

  /// No description provided for @prayerCommunityEmpty.
  ///
  /// In en, this message translates to:
  /// **'No shared prayer requests right now.'**
  String get prayerCommunityEmpty;

  /// No description provided for @prayerIPrayed.
  ///
  /// In en, this message translates to:
  /// **'I prayed'**
  String get prayerIPrayed;

  /// No description provided for @prayerPrayedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Be the first to pray} =1{1 person prayed} other{{count} people prayed}}'**
  String prayerPrayedCount(int count);

  /// No description provided for @anonymous.
  ///
  /// In en, this message translates to:
  /// **'Anonymous'**
  String get anonymous;

  /// No description provided for @impactTitle.
  ///
  /// In en, this message translates to:
  /// **'Your impact of the day'**
  String get impactTitle;

  /// No description provided for @impactSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A small gesture. A great impact.'**
  String get impactSubtitle;

  /// No description provided for @impactChallenge.
  ///
  /// In en, this message translates to:
  /// **'Challenge of the day'**
  String get impactChallenge;

  /// No description provided for @impactAccept.
  ///
  /// In en, this message translates to:
  /// **'I TAKE THE CHALLENGE'**
  String get impactAccept;

  /// No description provided for @impactDone.
  ///
  /// In en, this message translates to:
  /// **'CHALLENGE COMPLETED'**
  String get impactDone;

  /// No description provided for @impactWeek.
  ///
  /// In en, this message translates to:
  /// **'My progress this week'**
  String get impactWeek;

  /// No description provided for @impactStreak.
  ///
  /// In en, this message translates to:
  /// **'Impact Streak'**
  String get impactStreak;

  /// No description provided for @impactTotal.
  ///
  /// In en, this message translates to:
  /// **'Total impacts'**
  String get impactTotal;

  /// No description provided for @impactTotalSub.
  ///
  /// In en, this message translates to:
  /// **'Small gestures. Great changes.'**
  String get impactTotalSub;

  /// No description provided for @impactNoChallenge.
  ///
  /// In en, this message translates to:
  /// **'No challenge published for today yet.'**
  String get impactNoChallenge;

  /// No description provided for @impactNotePrompt.
  ///
  /// In en, this message translates to:
  /// **'How did it go? (optional)'**
  String get impactNotePrompt;

  /// No description provided for @weekdaysShort.
  ///
  /// In en, this message translates to:
  /// **'Mon,Tue,Wed,Thu,Fri,Sat,Sun'**
  String get weekdaysShort;

  /// No description provided for @monthsShort.
  ///
  /// In en, this message translates to:
  /// **'Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec'**
  String get monthsShort;

  /// No description provided for @sosTitle.
  ///
  /// In en, this message translates to:
  /// **'Holy SOS'**
  String get sosTitle;

  /// No description provided for @sosSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You are not alone. Share your need, we pray and act with you.'**
  String get sosSubtitle;

  /// No description provided for @sosBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'God sees. The family acts.'**
  String get sosBannerTitle;

  /// No description provided for @sosBannerText.
  ///
  /// In en, this message translates to:
  /// **'Share your need in full confidentiality. Our community prays for you and brings real support.'**
  String get sosBannerText;

  /// No description provided for @sosBannerTags.
  ///
  /// In en, this message translates to:
  /// **'Confidential. Caring. Brotherly.'**
  String get sosBannerTags;

  /// No description provided for @sosNeedHelp.
  ///
  /// In en, this message translates to:
  /// **'I need help'**
  String get sosNeedHelp;

  /// No description provided for @sosNeedHelpSub.
  ///
  /// In en, this message translates to:
  /// **'Submit a request'**
  String get sosNeedHelpSub;

  /// No description provided for @sosWantHelp.
  ///
  /// In en, this message translates to:
  /// **'I want to help'**
  String get sosWantHelp;

  /// No description provided for @sosWantHelpSub.
  ///
  /// In en, this message translates to:
  /// **'Support a brother or sister'**
  String get sosWantHelpSub;

  /// No description provided for @sosMyRequests.
  ///
  /// In en, this message translates to:
  /// **'My requests'**
  String get sosMyRequests;

  /// No description provided for @sosMyRequestsSub.
  ///
  /// In en, this message translates to:
  /// **'Follow your requests and responses'**
  String get sosMyRequestsSub;

  /// No description provided for @sosQ1.
  ///
  /// In en, this message translates to:
  /// **'1. What kind of need do you want to share?'**
  String get sosQ1;

  /// No description provided for @sosQ2.
  ///
  /// In en, this message translates to:
  /// **'2. Describe your need'**
  String get sosQ2;

  /// No description provided for @sosQ2Hint.
  ///
  /// In en, this message translates to:
  /// **'Write your need here. Feel free to be as precise as you wish...'**
  String get sosQ2Hint;

  /// No description provided for @sosQ3.
  ///
  /// In en, this message translates to:
  /// **'3. Do you want to stay anonymous?'**
  String get sosQ3;

  /// No description provided for @sosQ3Sub.
  ///
  /// In en, this message translates to:
  /// **'Your identity will remain confidential.'**
  String get sosQ3Sub;

  /// No description provided for @sosLeadersOnly.
  ///
  /// In en, this message translates to:
  /// **'Only the leaders can see this request'**
  String get sosLeadersOnly;

  /// No description provided for @sosSend.
  ///
  /// In en, this message translates to:
  /// **'Send my request'**
  String get sosSend;

  /// No description provided for @sosSent.
  ///
  /// In en, this message translates to:
  /// **'Your request has been sent. We are praying for you.'**
  String get sosSent;

  /// No description provided for @sosOffer.
  ///
  /// In en, this message translates to:
  /// **'Offer help'**
  String get sosOffer;

  /// No description provided for @sosOfferHint.
  ///
  /// In en, this message translates to:
  /// **'Write an encouraging message or explain how you can help...'**
  String get sosOfferHint;

  /// No description provided for @sosOfferSent.
  ///
  /// In en, this message translates to:
  /// **'Thank you! Your offer has been sent.'**
  String get sosOfferSent;

  /// No description provided for @sosOffers.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No offers yet} =1{1 offer of help} other{{count} offers of help}}'**
  String sosOffers(int count);

  /// No description provided for @sosEmpty.
  ///
  /// In en, this message translates to:
  /// **'No needs shared right now. Praise God!'**
  String get sosEmpty;

  /// No description provided for @sosConfidential.
  ///
  /// In en, this message translates to:
  /// **'Guaranteed confidentiality'**
  String get sosConfidential;

  /// No description provided for @sosConfidentialText.
  ///
  /// In en, this message translates to:
  /// **'Every request is treated with dignity, discretion and love by the leaders.'**
  String get sosConfidentialText;

  /// No description provided for @catPrayer.
  ///
  /// In en, this message translates to:
  /// **'Prayer'**
  String get catPrayer;

  /// No description provided for @catFinancial.
  ///
  /// In en, this message translates to:
  /// **'Financial'**
  String get catFinancial;

  /// No description provided for @catHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get catHealth;

  /// No description provided for @catEmotional.
  ///
  /// In en, this message translates to:
  /// **'Emotional'**
  String get catEmotional;

  /// No description provided for @catStudiesWork.
  ///
  /// In en, this message translates to:
  /// **'Studies / Work'**
  String get catStudiesWork;

  /// No description provided for @catOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get catOther;

  /// No description provided for @statusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get statusOpen;

  /// No description provided for @statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get statusInProgress;

  /// No description provided for @statusResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get statusResolved;

  /// No description provided for @statusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get statusClosed;

  /// No description provided for @inboxTitle.
  ///
  /// In en, this message translates to:
  /// **'Messages & Notifications'**
  String get inboxTitle;

  /// No description provided for @inboxSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stay connected. Don\'t miss anything important.'**
  String get inboxSubtitle;

  /// No description provided for @inboxMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get inboxMessages;

  /// No description provided for @inboxNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get inboxNotifications;

  /// No description provided for @inboxNewConversation.
  ///
  /// In en, this message translates to:
  /// **'Talk to a leader'**
  String get inboxNewConversation;

  /// No description provided for @inboxEmpty.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet. Your leaders are here to listen.'**
  String get inboxEmpty;

  /// No description provided for @notificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet.'**
  String get notificationsEmpty;

  /// No description provided for @chatSubject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get chatSubject;

  /// No description provided for @chatSubjectHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. I need advice, I am going through a hard time...'**
  String get chatSubjectHint;

  /// No description provided for @chatFirstMessage.
  ///
  /// In en, this message translates to:
  /// **'Your message'**
  String get chatFirstMessage;

  /// No description provided for @chatFirstMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Pour out your heart. Only the pastors and leaders will read this.'**
  String get chatFirstMessageHint;

  /// No description provided for @chatTypeMessage.
  ///
  /// In en, this message translates to:
  /// **'Write a message...'**
  String get chatTypeMessage;

  /// No description provided for @chatStart.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get chatStart;

  /// No description provided for @chatPrivateNotice.
  ///
  /// In en, this message translates to:
  /// **'Private conversation with the church leaders.'**
  String get chatPrivateNotice;

  /// No description provided for @chatLeader.
  ///
  /// In en, this message translates to:
  /// **'Leader'**
  String get chatLeader;

  /// No description provided for @chatClosed.
  ///
  /// In en, this message translates to:
  /// **'This conversation has been closed by the leaders.'**
  String get chatClosed;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get profileTitle;

  /// No description provided for @profileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'God knows you. Walk with Him.'**
  String get profileSubtitle;

  /// No description provided for @profileStreak.
  ///
  /// In en, this message translates to:
  /// **'Days in a row'**
  String get profileStreak;

  /// No description provided for @profileImpacts.
  ///
  /// In en, this message translates to:
  /// **'Impacts made'**
  String get profileImpacts;

  /// No description provided for @profileDevotions.
  ///
  /// In en, this message translates to:
  /// **'Devotions completed'**
  String get profileDevotions;

  /// No description provided for @profileAnswered.
  ///
  /// In en, this message translates to:
  /// **'Answered prayers'**
  String get profileAnswered;

  /// No description provided for @profilePersonalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal information'**
  String get profilePersonalInfo;

  /// No description provided for @profilePersonalInfoSub.
  ///
  /// In en, this message translates to:
  /// **'Manage your profile and preferences.'**
  String get profilePersonalInfoSub;

  /// No description provided for @profileLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profileLanguage;

  /// No description provided for @profileLanguageSub.
  ///
  /// In en, this message translates to:
  /// **'Français, English, Yorùbá'**
  String get profileLanguageSub;

  /// No description provided for @profileSos.
  ///
  /// In en, this message translates to:
  /// **'Needs & Requests (Holy SOS)'**
  String get profileSos;

  /// No description provided for @profileSosSub.
  ///
  /// In en, this message translates to:
  /// **'Share a need. Receive support.'**
  String get profileSosSub;

  /// No description provided for @profileMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages & Notifications'**
  String get profileMessages;

  /// No description provided for @profileMessagesSub.
  ///
  /// In en, this message translates to:
  /// **'Talk to your leaders.'**
  String get profileMessagesSub;

  /// No description provided for @profileAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get profileAbout;

  /// No description provided for @profileAboutSub.
  ///
  /// In en, this message translates to:
  /// **'Learn more about Impact-365.'**
  String get profileAboutSub;

  /// No description provided for @profileAboutText.
  ///
  /// In en, this message translates to:
  /// **'Impact-365 helps you meet God every day through His Word, prayer and concrete acts of love.'**
  String get profileAboutText;

  /// No description provided for @profileSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get profileSignOut;

  /// No description provided for @profileSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get profileSave;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileSaved;

  /// No description provided for @profileImpacterSince.
  ///
  /// In en, this message translates to:
  /// **'Impacter for {days} days'**
  String profileImpacterSince(int days);

  /// No description provided for @newBadge.
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get newBadge;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get commonSubmit;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get commonError;

  /// No description provided for @commonSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get commonSeeAll;

  /// No description provided for @commonToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get commonToday;

  /// No description provided for @commonYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get commonYesterday;

  /// No description provided for @profileVerse.
  ///
  /// In en, this message translates to:
  /// **'I can do all things through Christ who strengthens me.'**
  String get profileVerse;

  /// No description provided for @profileVerseRef.
  ///
  /// In en, this message translates to:
  /// **'Philippians 4:13'**
  String get profileVerseRef;

  /// No description provided for @journalVerse.
  ///
  /// In en, this message translates to:
  /// **'Meditate on it day and night, so that you may be careful to do everything written in it.'**
  String get journalVerse;

  /// No description provided for @journalVerseRef.
  ///
  /// In en, this message translates to:
  /// **'Joshua 1:8'**
  String get journalVerseRef;

  /// No description provided for @prayerRoomVerse.
  ///
  /// In en, this message translates to:
  /// **'Do not be anxious about anything, but in every situation, by prayer and petition, with thanksgiving, present your requests to God.'**
  String get prayerRoomVerse;

  /// No description provided for @prayerRoomVerseRef.
  ///
  /// In en, this message translates to:
  /// **'Philippians 4:6'**
  String get prayerRoomVerseRef;

  /// No description provided for @sosVerse.
  ///
  /// In en, this message translates to:
  /// **'« Your Father knows what you need. »'**
  String get sosVerse;

  /// No description provided for @sosVerseRef.
  ///
  /// In en, this message translates to:
  /// **'Matthew 6:8'**
  String get sosVerseRef;

  /// No description provided for @sosMyEmpty.
  ///
  /// In en, this message translates to:
  /// **'You have not submitted any request yet.'**
  String get sosMyEmpty;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneLabel;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr', 'yo'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
    case 'yo':
      return AppLocalizationsYo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
