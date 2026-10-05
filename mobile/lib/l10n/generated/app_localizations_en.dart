// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTagline => '1 day 1 impact';

  @override
  String get navHome => 'Home';

  @override
  String get navWord => 'Word';

  @override
  String get navPrayer => 'Prayer';

  @override
  String get navImpact => 'Impact';

  @override
  String get navProfile => 'Profile';

  @override
  String get authWelcome => 'Welcome to Impact-365';

  @override
  String get authSubtitle => 'A new day. A new encounter with God.';

  @override
  String get authEmail => 'Email';

  @override
  String get authPassword => 'Password';

  @override
  String get authFullName => 'Full name';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authSignUp => 'Create my account';

  @override
  String get authNoAccount => 'No account yet? Sign up';

  @override
  String get authHaveAccount => 'Already have an account? Sign in';

  @override
  String get authCheckEmail => 'Check your email to confirm your account.';

  @override
  String get authInvalid =>
      'Please fill in all fields (password: 6 characters minimum).';

  @override
  String homeGreeting(String name) {
    return 'Good day, $name.';
  }

  @override
  String get homeGreetingDefault => 'Impacter';

  @override
  String get homeSubtitle => 'A new day.\nA new encounter with God.';

  @override
  String homeDayCounter(int day) {
    return 'Day $day / 365';
  }

  @override
  String get homeCurrentStreak => 'Current streak';

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
      zero: '0 days',
    );
    return '$_temp0';
  }

  @override
  String get homeVerseOfDay => 'Verse of the day';

  @override
  String get homeStartDevotion => 'START MY DEVOTION';

  @override
  String get homeThemeOfDay => 'Theme of the day';

  @override
  String get homeToday => 'Today';

  @override
  String get homeYourWord => 'Your Word';

  @override
  String get homeYourPrayer => 'Your prayer';

  @override
  String get homeYourImpact => 'Your impact';

  @override
  String get homeDiscover => 'Discover';

  @override
  String get homePray => 'Pray';

  @override
  String get homeAct => 'Act';

  @override
  String get homeFaithJourney => 'Faith journey';

  @override
  String get homeFaithJourneyText =>
      'Your consistency shapes your eternal impact.';

  @override
  String get homeNoDevotion =>
      'No devotion published yet for today. Come back soon!';

  @override
  String get slotMorning => 'Morning';

  @override
  String get slotAfternoon => 'Afternoon';

  @override
  String get slotNight => 'Night';

  @override
  String get devotionTitle => '5 MINUTES WITH GOD';

  @override
  String get devotionGodSays => 'WHAT GOD SAYS';

  @override
  String get devotionIUnderstand => 'WHAT I UNDERSTAND';

  @override
  String get devotionIDo => 'WHAT I DO';

  @override
  String get devotionDone => 'I UNDERSTOOD';

  @override
  String get devotionCompleted => 'Completed';

  @override
  String get devotionListen => 'LISTEN TO AUDIO';

  @override
  String get devotionPause => 'PAUSE AUDIO';

  @override
  String get devotionQuestionTitle => 'A question?';

  @override
  String get devotionQuestionText => 'Write it, a leader will gladly help you.';

  @override
  String get devotionAskQuestion => 'Ask my question';

  @override
  String get wordTodayTitle => 'Today\'s devotions';

  @override
  String get wordHistory => 'Previous days';

  @override
  String get wordNotAvailable => 'Not yet available';

  @override
  String get journalTitle => 'My Journal';

  @override
  String get journalSubtitle => 'Take a moment to write.';

  @override
  String get journalQ1 => '1. What is God showing me today?';

  @override
  String get journalQ1Hint =>
      'Write what God puts in your heart through His Word, a situation, a thought or a verse.';

  @override
  String get journalQ2 => '2. What must I change?';

  @override
  String get journalQ2Hint =>
      'What habits, thoughts or attitudes is God calling you to leave behind?';

  @override
  String get journalQ3 => '3. Who should I pray for?';

  @override
  String get journalQ3Hint =>
      'Note the names of people or situations you want to present to God.';

  @override
  String get journalGratitude => 'Gratitude journal';

  @override
  String get journalGratitudeHint => 'Thank God for 3 things today.';

  @override
  String get journalWriteHere => 'Write here...';

  @override
  String get journalSave => 'Save';

  @override
  String get journalSaved => 'Journal saved';

  @override
  String get prayerRoomTitle => 'My Prayer Room';

  @override
  String get prayerRoomSubtitle => 'Talk to God. Lay it down. Wait. Receive.';

  @override
  String get prayerMyTopics => 'My prayer points';

  @override
  String get prayerMyTopicsSub => 'Your intentions, your needs.';

  @override
  String get prayerAnswered => 'My answered prayers';

  @override
  String get prayerAnsweredSub => 'God has already acted. Keep track.';

  @override
  String get prayerForSomeone => 'Pray for someone';

  @override
  String get prayerForSomeoneSub => 'Intercede. Carry. Love.';

  @override
  String get prayerJournal => 'Keep a heart of prayer';

  @override
  String get prayerJournalSub => 'Open my journal.';

  @override
  String get prayerVerse => 'Prayer verse';

  @override
  String get prayerAdd => 'New prayer point';

  @override
  String get prayerTitleField => 'Prayer point';

  @override
  String get prayerDetailsField => 'Details (optional)';

  @override
  String get prayerShare => 'Share with the community so they can pray';

  @override
  String get prayerAnonymous => 'Stay anonymous';

  @override
  String get prayerMarkAnswered => 'God answered!';

  @override
  String get prayerTestimony => 'Your testimony (optional)';

  @override
  String get prayerEmpty => 'No prayer points yet. Add your first one.';

  @override
  String get prayerAnsweredEmpty => 'Your answered prayers will appear here.';

  @override
  String get prayerCommunityEmpty => 'No shared prayer requests right now.';

  @override
  String get prayerIPrayed => 'I prayed';

  @override
  String prayerPrayedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people prayed',
      one: '1 person prayed',
      zero: 'Be the first to pray',
    );
    return '$_temp0';
  }

  @override
  String get anonymous => 'Anonymous';

  @override
  String get impactTitle => 'Your impact of the day';

  @override
  String get impactSubtitle => 'A small gesture. A great impact.';

  @override
  String get impactChallenge => 'Challenge of the day';

  @override
  String get impactAccept => 'I TAKE THE CHALLENGE';

  @override
  String get impactDone => 'CHALLENGE COMPLETED';

  @override
  String get impactWeek => 'My progress this week';

  @override
  String get impactStreak => 'Impact Streak';

  @override
  String get impactTotal => 'Total impacts';

  @override
  String get impactTotalSub => 'Small gestures. Great changes.';

  @override
  String get impactNoChallenge => 'No challenge published for today yet.';

  @override
  String get impactNotePrompt => 'How did it go? (optional)';

  @override
  String get weekdaysShort => 'Mon,Tue,Wed,Thu,Fri,Sat,Sun';

  @override
  String get monthsShort => 'Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec';

  @override
  String get sosTitle => 'Holy SOS';

  @override
  String get sosSubtitle =>
      'You are not alone. Share your need, we pray and act with you.';

  @override
  String get sosBannerTitle => 'God sees. The family acts.';

  @override
  String get sosBannerText =>
      'Share your need in full confidentiality. Our community prays for you and brings real support.';

  @override
  String get sosBannerTags => 'Confidential. Caring. Brotherly.';

  @override
  String get sosNeedHelp => 'I need help';

  @override
  String get sosNeedHelpSub => 'Submit a request';

  @override
  String get sosWantHelp => 'I want to help';

  @override
  String get sosWantHelpSub => 'Support a brother or sister';

  @override
  String get sosMyRequests => 'My requests';

  @override
  String get sosMyRequestsSub => 'Follow your requests and responses';

  @override
  String get sosQ1 => '1. What kind of need do you want to share?';

  @override
  String get sosQ2 => '2. Describe your need';

  @override
  String get sosQ2Hint =>
      'Write your need here. Feel free to be as precise as you wish...';

  @override
  String get sosQ3 => '3. Do you want to stay anonymous?';

  @override
  String get sosQ3Sub => 'Your identity will remain confidential.';

  @override
  String get sosLeadersOnly => 'Only the leaders can see this request';

  @override
  String get sosSend => 'Send my request';

  @override
  String get sosSent => 'Your request has been sent. We are praying for you.';

  @override
  String get sosOffer => 'Offer help';

  @override
  String get sosOfferHint =>
      'Write an encouraging message or explain how you can help...';

  @override
  String get sosOfferSent => 'Thank you! Your offer has been sent.';

  @override
  String sosOffers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count offers of help',
      one: '1 offer of help',
      zero: 'No offers yet',
    );
    return '$_temp0';
  }

  @override
  String get sosEmpty => 'No needs shared right now. Praise God!';

  @override
  String get sosConfidential => 'Guaranteed confidentiality';

  @override
  String get sosConfidentialText =>
      'Every request is treated with dignity, discretion and love by the leaders.';

  @override
  String get catPrayer => 'Prayer';

  @override
  String get catFinancial => 'Financial';

  @override
  String get catHealth => 'Health';

  @override
  String get catEmotional => 'Emotional';

  @override
  String get catStudiesWork => 'Studies / Work';

  @override
  String get catOther => 'Other';

  @override
  String get statusOpen => 'Open';

  @override
  String get statusInProgress => 'In progress';

  @override
  String get statusResolved => 'Resolved';

  @override
  String get statusClosed => 'Closed';

  @override
  String get inboxTitle => 'Messages & Notifications';

  @override
  String get inboxSubtitle => 'Stay connected. Don\'t miss anything important.';

  @override
  String get inboxMessages => 'Messages';

  @override
  String get inboxNotifications => 'Notifications';

  @override
  String get inboxNewConversation => 'Talk to a leader';

  @override
  String get inboxEmpty =>
      'No conversations yet. Your leaders are here to listen.';

  @override
  String get notificationsEmpty => 'No notifications yet.';

  @override
  String get chatSubject => 'Subject';

  @override
  String get chatSubjectHint =>
      'e.g. I need advice, I am going through a hard time...';

  @override
  String get chatFirstMessage => 'Your message';

  @override
  String get chatFirstMessageHint =>
      'Pour out your heart. Only the pastors and leaders will read this.';

  @override
  String get chatTypeMessage => 'Write a message...';

  @override
  String get chatStart => 'Send';

  @override
  String get chatPrivateNotice =>
      'Private conversation with the church leaders.';

  @override
  String get chatLeader => 'Leader';

  @override
  String get chatClosed => 'This conversation has been closed by the leaders.';

  @override
  String get profileTitle => 'My Profile';

  @override
  String get profileSubtitle => 'God knows you. Walk with Him.';

  @override
  String get profileStreak => 'Days in a row';

  @override
  String get profileImpacts => 'Impacts made';

  @override
  String get profileDevotions => 'Devotions completed';

  @override
  String get profileAnswered => 'Answered prayers';

  @override
  String get profilePersonalInfo => 'Personal information';

  @override
  String get profilePersonalInfoSub => 'Manage your profile and preferences.';

  @override
  String get profileLanguage => 'Language';

  @override
  String get profileLanguageSub => 'Français, English, Yorùbá';

  @override
  String get profileSos => 'Needs & Requests (Holy SOS)';

  @override
  String get profileSosSub => 'Share a need. Receive support.';

  @override
  String get profileMessages => 'Messages & Notifications';

  @override
  String get profileMessagesSub => 'Talk to your leaders.';

  @override
  String get profileAbout => 'About';

  @override
  String get profileAboutSub => 'Learn more about Impact-365.';

  @override
  String get profileAboutText =>
      'Impact-365 helps you meet God every day through His Word, prayer and concrete acts of love.';

  @override
  String get profileSignOut => 'Sign out';

  @override
  String get profileSave => 'Save';

  @override
  String get profileSaved => 'Profile updated';

  @override
  String profileImpacterSince(int days) {
    return 'Impacter for $days days';
  }

  @override
  String get newBadge => 'NEW';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSubmit => 'Submit';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonError => 'Something went wrong. Please try again.';

  @override
  String get commonSeeAll => 'See all';

  @override
  String get commonToday => 'Today';

  @override
  String get commonYesterday => 'Yesterday';

  @override
  String get profileVerse =>
      'I can do all things through Christ who strengthens me.';

  @override
  String get profileVerseRef => 'Philippians 4:13';

  @override
  String get journalVerse =>
      'Meditate on it day and night, so that you may be careful to do everything written in it.';

  @override
  String get journalVerseRef => 'Joshua 1:8';

  @override
  String get prayerRoomVerse =>
      'Do not be anxious about anything, but in every situation, by prayer and petition, with thanksgiving, present your requests to God.';

  @override
  String get prayerRoomVerseRef => 'Philippians 4:6';

  @override
  String get sosVerse => '« Your Father knows what you need. »';

  @override
  String get sosVerseRef => 'Matthew 6:8';

  @override
  String get sosMyEmpty => 'You have not submitted any request yet.';

  @override
  String get phoneLabel => 'Phone';

  @override
  String get onbSkip => 'Skip';

  @override
  String get onbNext => 'Next';

  @override
  String get onbStart => 'Get started';

  @override
  String get onb1Title => 'Meet God every day';

  @override
  String get onb1Text =>
      'Morning, afternoon and night, receive a short and deep devotion: the Word, what it means, and how to live it today.';

  @override
  String get onb2Title => 'Pray, and never walk alone';

  @override
  String get onb2Text =>
      'Lay down your prayer points, celebrate answered prayers and carry others in prayer. Need help? Your church family is here, in full confidentiality.';

  @override
  String get onb3Title => 'One day, one impact';

  @override
  String get onb3Text =>
      'Take up a small challenge each day, keep your journal and grow step by step: 365 days to leave an eternal mark.';

  @override
  String get onbReplay => 'Replay the introduction';

  @override
  String get welcomeTitle => 'Welcome to';

  @override
  String get welcomeSubtitle =>
      'Begin your spiritual journey one day at a time';

  @override
  String get welcomeSignIn => 'Sign in';

  @override
  String get welcomeSignUp => 'Create an account';

  @override
  String get welcomeVerse =>
      'The steadfast love of the Lord never ceases; his mercies are new every morning.';

  @override
  String get welcomeVerseRef => 'Lamentations 3:22-23';
}
