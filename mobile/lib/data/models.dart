/// Plain data classes mapped from Supabase rows.
library;

enum DevotionSlot {
  morning,
  afternoon,
  night;

  static DevotionSlot fromName(String name) =>
      DevotionSlot.values.firstWhere((s) => s.name == name);

  /// Morning before noon, afternoon until 6pm, night after.
  static DevotionSlot current([DateTime? now]) {
    final h = (now ?? DateTime.now()).hour;
    if (h < 12) return DevotionSlot.morning;
    if (h < 18) return DevotionSlot.afternoon;
    return DevotionSlot.night;
  }
}

class Devotion {
  Devotion({
    required this.id,
    required this.date,
    required this.slot,
    required this.verseReference,
    required this.verseText,
    required this.godSays,
    required this.iUnderstand,
    required this.iDo,
    this.theme,
    this.imageUrl,
    this.audioUrl,
    this.completed = false,
  });

  final String id;
  final DateTime date;
  final DevotionSlot slot;
  final String? theme;
  final String verseReference;
  final String verseText;
  final String godSays;
  final String iUnderstand;
  final String iDo;
  final String? imageUrl;
  final String? audioUrl;
  final bool completed;

  /// [row] is a `devotions` row with its `devotion_translations` embedded.
  /// Picks the translation for [lang], falling back to fr, then en, then any.
  static Devotion? fromRow(
    Map<String, dynamic> row,
    String lang, {
    Set<String> completedIds = const {},
  }) {
    final translations = (row['devotion_translations'] as List)
        .cast<Map<String, dynamic>>();
    if (translations.isEmpty) return null;
    Map<String, dynamic>? pick(String l) =>
        translations.where((t) => t['lang'] == l).firstOrNull;
    final t = pick(lang) ?? pick('fr') ?? pick('en') ?? translations.first;
    return Devotion(
      id: row['id'] as String,
      date: DateTime.parse(row['devotion_date'] as String),
      slot: DevotionSlot.fromName(row['slot'] as String),
      imageUrl: row['image_url'] as String?,
      theme: t['theme'] as String?,
      verseReference: t['verse_reference'] as String,
      verseText: t['verse_text'] as String,
      godSays: t['god_says'] as String,
      iUnderstand: t['i_understand'] as String,
      iDo: t['i_do'] as String,
      audioUrl: t['audio_url'] as String?,
      completed: completedIds.contains(row['id']),
    );
  }
}

class Challenge {
  Challenge({
    required this.id,
    required this.date,
    required this.title,
    this.description,
    this.verseReference,
    this.verseText,
    this.imageUrl,
    this.completed = false,
  });

  final String id;
  final DateTime date;
  final String title;
  final String? description;
  final String? verseReference;
  final String? verseText;
  final String? imageUrl;
  final bool completed;

  static Challenge? fromRow(
    Map<String, dynamic> row,
    String lang, {
    bool completed = false,
  }) {
    final translations = (row['challenge_translations'] as List)
        .cast<Map<String, dynamic>>();
    if (translations.isEmpty) return null;
    Map<String, dynamic>? pick(String l) =>
        translations.where((t) => t['lang'] == l).firstOrNull;
    final t = pick(lang) ?? pick('fr') ?? pick('en') ?? translations.first;
    return Challenge(
      id: row['id'] as String,
      date: DateTime.parse(row['challenge_date'] as String),
      imageUrl: row['image_url'] as String?,
      title: t['title'] as String,
      description: t['description'] as String?,
      verseReference: t['verse_reference'] as String?,
      verseText: t['verse_text'] as String?,
      completed: completed,
    );
  }
}

class UserStats {
  UserStats({
    this.streak = 0,
    this.devotionsCompleted = 0,
    this.challengesCompleted = 0,
    this.prayersAnswered = 0,
    this.prayersOpen = 0,
    this.daysSinceJoin = 1,
    this.weekChallengeDays = const {},
  });

  final int streak;
  final int devotionsCompleted;
  final int challengesCompleted;
  final int prayersAnswered;
  final int prayersOpen;
  final int daysSinceJoin;

  /// ISO weekdays (1 = Monday) on which a challenge was completed this week.
  final Set<int> weekChallengeDays;

  factory UserStats.fromJson(Map<String, dynamic> j) => UserStats(
    streak: j['streak'] as int? ?? 0,
    devotionsCompleted: j['devotions_completed'] as int? ?? 0,
    challengesCompleted: j['challenges_completed'] as int? ?? 0,
    prayersAnswered: j['prayers_answered'] as int? ?? 0,
    prayersOpen: j['prayers_open'] as int? ?? 0,
    daysSinceJoin: j['days_since_join'] as int? ?? 1,
    weekChallengeDays: ((j['week_challenges'] as List?) ?? [])
        .cast<int>()
        .toSet(),
  );
}

class Profile {
  Profile({
    required this.id,
    this.fullName,
    this.phone,
    this.avatarUrl,
    this.role = 'member',
    this.preferredLanguage = 'fr',
  });

  final String id;
  final String? fullName;
  final String? phone;
  final String? avatarUrl;
  final String role;
  final String preferredLanguage;

  String get firstName => (fullName ?? '').trim().split(' ').first;

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
    id: j['id'] as String,
    fullName: j['full_name'] as String?,
    phone: j['phone'] as String?,
    avatarUrl: j['avatar_url'] as String?,
    role: j['role'] as String? ?? 'member',
    preferredLanguage: j['preferred_language'] as String? ?? 'fr',
  );
}

class JournalEntry {
  JournalEntry({
    this.godShows = '',
    this.mustChange = '',
    this.prayFor = '',
    this.gratitude = '',
  });

  final String godShows;
  final String mustChange;
  final String prayFor;
  final String gratitude;

  factory JournalEntry.fromJson(Map<String, dynamic> j) => JournalEntry(
    godShows: j['god_shows'] as String? ?? '',
    mustChange: j['must_change'] as String? ?? '',
    prayFor: j['pray_for'] as String? ?? '',
    gratitude: j['gratitude'] as String? ?? '',
  );
}

class PrayerRequest {
  PrayerRequest({
    required this.id,
    required this.title,
    required this.createdAt,
    this.details,
    this.isShared = false,
    this.isAnonymous = false,
    this.isAnswered = false,
    this.testimony,
  });

  final String id;
  final String title;
  final String? details;
  final bool isShared;
  final bool isAnonymous;
  final bool isAnswered;
  final String? testimony;
  final DateTime createdAt;

  factory PrayerRequest.fromJson(Map<String, dynamic> j) => PrayerRequest(
    id: j['id'] as String,
    title: j['title'] as String,
    details: j['details'] as String?,
    isShared: j['is_shared'] as bool? ?? false,
    isAnonymous: j['is_anonymous'] as bool? ?? false,
    isAnswered: j['is_answered'] as bool? ?? false,
    testimony: j['testimony'] as String?,
    createdAt: DateTime.parse(j['created_at'] as String),
  );
}

class CommunityPrayer {
  CommunityPrayer({
    required this.id,
    required this.title,
    required this.createdAt,
    this.details,
    this.authorName,
    this.intercessionCount = 0,
    this.iPrayed = false,
  });

  final String id;
  final String title;
  final String? details;
  final String? authorName;
  final int intercessionCount;
  final bool iPrayed;
  final DateTime createdAt;

  factory CommunityPrayer.fromJson(Map<String, dynamic> j) => CommunityPrayer(
    id: j['id'] as String,
    title: j['title'] as String,
    details: j['details'] as String?,
    authorName: j['author_name'] as String?,
    intercessionCount: j['intercession_count'] as int? ?? 0,
    iPrayed: j['i_prayed'] as bool? ?? false,
    createdAt: DateTime.parse(j['created_at'] as String),
  );
}

enum HelpCategory {
  prayer,
  financial,
  health,
  emotional,
  studiesWork,
  other;

  String get dbValue => this == studiesWork ? 'studies_work' : name;

  static HelpCategory fromDb(String v) =>
      HelpCategory.values.firstWhere((c) => c.dbValue == v);
}

class HelpNeed {
  HelpNeed({
    required this.id,
    required this.category,
    required this.description,
    required this.status,
    required this.createdAt,
    this.authorName,
    this.isMine = false,
    this.offerCount = 0,
  });

  final String id;
  final HelpCategory category;
  final String description;
  final String status;
  final DateTime createdAt;
  final String? authorName;
  final bool isMine;
  final int offerCount;

  factory HelpNeed.fromJson(Map<String, dynamic> j) => HelpNeed(
    id: j['id'] as String,
    category: HelpCategory.fromDb(j['category'] as String),
    description: j['description'] as String,
    status: j['status'] as String,
    createdAt: DateTime.parse(j['created_at'] as String),
    authorName: j['author_name'] as String?,
    isMine: j['is_mine'] as bool? ?? false,
    offerCount: j['offer_count'] as int? ?? 0,
  );
}

class HelpOffer {
  HelpOffer({
    required this.id,
    required this.message,
    required this.createdAt,
    this.helperName,
  });

  final String id;
  final String message;
  final String? helperName;
  final DateTime createdAt;
}

class MyHelpRequest {
  MyHelpRequest({
    required this.id,
    required this.category,
    required this.description,
    required this.status,
    required this.createdAt,
    this.staffNote,
    this.offers = const [],
  });

  final String id;
  final HelpCategory category;
  final String description;
  final String status;
  final String? staffNote;
  final DateTime createdAt;
  final List<HelpOffer> offers;
}

class Conversation {
  Conversation({
    required this.id,
    required this.subject,
    required this.status,
    required this.lastMessageAt,
    this.lastMessage,
    this.unread = 0,
  });

  final String id;
  final String subject;
  final String status;
  final DateTime lastMessageAt;
  final String? lastMessage;
  final int unread;

  bool get isOpen => status == 'open';
}

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.body,
    required this.senderId,
    required this.isFromStaff,
    required this.createdAt,
    this.readAt,
  });

  final String id;
  final String body;
  final String senderId;
  final bool isFromStaff;
  final DateTime createdAt;
  final DateTime? readAt;

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
    id: j['id'] as String,
    body: j['body'] as String,
    senderId: j['sender_id'] as String,
    isFromStaff: j['is_from_staff'] as bool? ?? false,
    createdAt: DateTime.parse(j['created_at'] as String),
    readAt: j['read_at'] == null
        ? null
        : DateTime.parse(j['read_at'] as String),
  );
}

class Announcement {
  Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;

  factory Announcement.fromJson(Map<String, dynamic> j) => Announcement(
    id: j['id'] as String,
    title: j['title'] as String,
    body: j['body'] as String,
    createdAt: DateTime.parse(j['created_at'] as String),
  );
}
