import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/locale_controller.dart';
import 'models.dart';

/// All reads/writes to Supabase go through here so screens stay simple.
/// Security is enforced in the database with Row Level Security.
class Repo {
  Repo._();

  static SupabaseClient get _db => Supabase.instance.client;
  static String get _uid => _db.auth.currentUser!.id;
  static String get _lang => LocaleController.instance.languageCode;

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ---------------------------------------------------------------- Profile

  static Future<Profile> myProfile() async {
    final row = await _db.from('profiles').select().eq('id', _uid).single();
    return Profile.fromJson(row);
  }

  static Future<void> updateProfile({String? fullName, String? phone}) => _db
      .from('profiles')
      .update({'full_name': ?fullName, 'phone': ?phone})
      .eq('id', _uid);

  static Future<void> savePreferredLanguage(String code) =>
      _db.from('profiles').update({'preferred_language': code}).eq('id', _uid);

  static Future<UserStats> myStats() async {
    final res = await _db.rpc('my_stats');
    return UserStats.fromJson(Map<String, dynamic>.from(res as Map));
  }

  // -------------------------------------------------------------- Devotions

  static const _devotionSelect =
      'id, devotion_date, slot, image_url, '
      'devotion_translations(lang, theme, verse_reference, verse_text, god_says, i_understand, i_do, audio_url)';

  static Future<Set<String>> _myCompletedDevotionIds(List<String> ids) async {
    if (ids.isEmpty) return {};
    final rows = await _db
        .from('devotion_completions')
        .select('devotion_id')
        .eq('user_id', _uid)
        .inFilter('devotion_id', ids);
    return rows.map((r) => r['devotion_id'] as String).toSet();
  }

  /// Published devotions for the last [days] days, newest first.
  static Future<List<Devotion>> recentDevotions({int days = 14}) async {
    final from = DateTime.now().subtract(Duration(days: days));
    final rows = await _db
        .from('devotions')
        .select(_devotionSelect)
        .gte('devotion_date', _dateOnly(from))
        .lte('devotion_date', _dateOnly(DateTime.now()))
        .order('devotion_date', ascending: false);
    final done = await _myCompletedDevotionIds(
      rows.map((r) => r['id'] as String).toList(),
    );
    return rows
        .map((r) => Devotion.fromRow(r, _lang, completedIds: done))
        .whereType<Devotion>()
        .toList();
  }

  static Future<List<Devotion>> todayDevotions() async {
    final rows = await _db
        .from('devotions')
        .select(_devotionSelect)
        .eq('devotion_date', _dateOnly(DateTime.now()));
    final done = await _myCompletedDevotionIds(
      rows.map((r) => r['id'] as String).toList(),
    );
    final list =
        rows
            .map((r) => Devotion.fromRow(r, _lang, completedIds: done))
            .whereType<Devotion>()
            .toList()
          ..sort((a, b) => a.slot.index.compareTo(b.slot.index));
    return list;
  }

  static Future<Devotion?> devotion(String id) async {
    final row = await _db
        .from('devotions')
        .select(_devotionSelect)
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;
    final done = await _myCompletedDevotionIds([id]);
    return Devotion.fromRow(row, _lang, completedIds: done);
  }

  static Future<void> completeDevotion(String id) => _db
      .from('devotion_completions')
      .upsert({'user_id': _uid, 'devotion_id': id});

  // ------------------------------------------------------------- Challenges

  static Future<Challenge?> todayChallenge() async {
    final row = await _db
        .from('challenges')
        .select(
          'id, challenge_date, image_url, '
          'challenge_translations(lang, title, description, verse_reference, verse_text)',
        )
        .eq('challenge_date', _dateOnly(DateTime.now()))
        .maybeSingle();
    if (row == null) return null;
    final done = await _db
        .from('challenge_completions')
        .select('challenge_id')
        .eq('user_id', _uid)
        .eq('challenge_id', row['id'] as String)
        .maybeSingle();
    return Challenge.fromRow(row, _lang, completed: done != null);
  }

  static Future<void> completeChallenge(String id, {String? note}) =>
      _db.from('challenge_completions').upsert({
        'user_id': _uid,
        'challenge_id': id,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      });

  // ---------------------------------------------------------------- Journal

  static Future<JournalEntry> journalFor(DateTime day) async {
    final row = await _db
        .from('journal_entries')
        .select()
        .eq('user_id', _uid)
        .eq('entry_date', _dateOnly(day))
        .maybeSingle();
    return row == null ? JournalEntry() : JournalEntry.fromJson(row);
  }

  static Future<void> saveJournal(DateTime day, JournalEntry e) =>
      _db.from('journal_entries').upsert({
        'user_id': _uid,
        'entry_date': _dateOnly(day),
        'god_shows': e.godShows,
        'must_change': e.mustChange,
        'pray_for': e.prayFor,
        'gratitude': e.gratitude,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'user_id,entry_date');

  // ---------------------------------------------------------------- Prayers

  static Future<List<PrayerRequest>> myPrayers({required bool answered}) async {
    final rows = await _db
        .from('prayer_requests')
        .select()
        .eq('user_id', _uid)
        .eq('is_answered', answered)
        .order(answered ? 'answered_at' : 'created_at', ascending: false);
    return rows.map(PrayerRequest.fromJson).toList();
  }

  static Future<void> addPrayer({
    required String title,
    String? details,
    bool shared = false,
    bool anonymous = false,
  }) => _db.from('prayer_requests').insert({
    'user_id': _uid,
    'title': title,
    'details': details,
    'is_shared': shared,
    'is_anonymous': anonymous,
  });

  static Future<void> markPrayerAnswered(String id, {String? testimony}) => _db
      .from('prayer_requests')
      .update({
        'is_answered': true,
        'answered_at': DateTime.now().toUtc().toIso8601String(),
        'testimony': testimony,
      })
      .eq('id', id);

  static Future<void> deletePrayer(String id) =>
      _db.from('prayer_requests').delete().eq('id', id);

  static Future<List<CommunityPrayer>> communityPrayers() async {
    final rows = await _db
        .from('community_prayers')
        .select()
        .eq('is_answered', false)
        .order('created_at', ascending: false)
        .limit(100);
    return rows.map(CommunityPrayer.fromJson).toList();
  }

  static Future<void> setIPrayed(String prayerId, bool prayed) => prayed
      ? _db.from('prayer_intercessions').upsert({
          'prayer_id': prayerId,
          'user_id': _uid,
        })
      : _db
            .from('prayer_intercessions')
            .delete()
            .eq('prayer_id', prayerId)
            .eq('user_id', _uid);

  // --------------------------------------------------------------- Holy SOS

  static Future<void> submitHelpRequest({
    required HelpCategory category,
    required String description,
    required bool anonymous,
    required bool leadersOnly,
  }) => _db.from('help_requests').insert({
    'user_id': _uid,
    'category': category.dbValue,
    'description': description,
    'is_anonymous': anonymous,
    'leaders_only': leadersOnly,
  });

  static Future<List<HelpNeed>> communityNeeds() async {
    final rows = await _db
        .from('community_needs')
        .select()
        .eq('is_mine', false)
        .order('created_at', ascending: false)
        .limit(100);
    return rows.map(HelpNeed.fromJson).toList();
  }

  static Future<void> offerHelp(String requestId, String message) => _db
      .from('help_offers')
      .insert({'request_id': requestId, 'helper_id': _uid, 'message': message});

  static Future<List<MyHelpRequest>> myHelpRequests() async {
    final rows = await _db
        .from('help_requests')
        .select(
          'id, category, description, status, staff_note, created_at, '
          'help_offers(id, message, created_at, helper:profiles(full_name))',
        )
        .eq('user_id', _uid)
        .order('created_at', ascending: false);
    return rows.map((r) {
      final offers = (r['help_offers'] as List).map((o) {
        final helper = o['helper'] as Map<String, dynamic>?;
        return HelpOffer(
          id: o['id'] as String,
          message: o['message'] as String,
          helperName: helper?['full_name'] as String?,
          createdAt: DateTime.parse(o['created_at'] as String),
        );
      }).toList();
      return MyHelpRequest(
        id: r['id'] as String,
        category: HelpCategory.fromDb(r['category'] as String),
        description: r['description'] as String,
        status: r['status'] as String,
        staffNote: r['staff_note'] as String?,
        createdAt: DateTime.parse(r['created_at'] as String),
        offers: offers,
      );
    }).toList();
  }

  // ------------------------------------------- Conversations with leaders

  static Future<List<Conversation>> myConversations() async {
    final rows = await _db
        .from('conversations')
        .select(
          'id, subject, status, last_message_at, '
          'messages(body, created_at, is_from_staff, read_at)',
        )
        .eq('user_id', _uid)
        .order('last_message_at', ascending: false);
    return rows.map((r) {
      final msgs = (r['messages'] as List).cast<Map<String, dynamic>>()
        ..sort(
          (a, b) =>
              (a['created_at'] as String).compareTo(b['created_at'] as String),
        );
      return Conversation(
        id: r['id'] as String,
        subject: r['subject'] as String,
        status: r['status'] as String,
        lastMessageAt: DateTime.parse(r['last_message_at'] as String),
        lastMessage: msgs.isEmpty ? null : msgs.last['body'] as String,
        unread: msgs
            .where((m) => m['is_from_staff'] == true && m['read_at'] == null)
            .length,
      );
    }).toList();
  }

  static Future<Conversation> conversation(String id) async {
    final r = await _db
        .from('conversations')
        .select('id, subject, status, last_message_at')
        .eq('id', id)
        .single();
    return Conversation(
      id: r['id'] as String,
      subject: r['subject'] as String,
      status: r['status'] as String,
      lastMessageAt: DateTime.parse(r['last_message_at'] as String),
    );
  }

  /// Creates the conversation and its first message; returns the new id.
  static Future<String> startConversation(String subject, String body) async {
    final row = await _db
        .from('conversations')
        .insert({'user_id': _uid, 'subject': subject})
        .select('id')
        .single();
    final id = row['id'] as String;
    await sendMessage(id, body);
    return id;
  }

  static Future<void> sendMessage(String conversationId, String body) =>
      _db.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': _uid,
        'body': body,
      });

  /// Live stream of the messages in a conversation (Supabase Realtime).
  static Stream<List<ChatMessage>> messagesStream(String conversationId) => _db
      .from('messages')
      .stream(primaryKey: ['id'])
      .eq('conversation_id', conversationId)
      .order('created_at')
      .map((rows) => rows.map(ChatMessage.fromJson).toList());

  static Future<void> markStaffMessagesRead(String conversationId) => _db
      .from('messages')
      .update({'read_at': DateTime.now().toUtc().toIso8601String()})
      .eq('conversation_id', conversationId)
      .eq('is_from_staff', true)
      .isFilter('read_at', null);

  static String get currentUserId => _uid;

  // ---------------------------------------------------------- Announcements

  static Future<List<Announcement>> announcements() async {
    final rows = await _db
        .from('announcements')
        .select()
        .or('lang.is.null,lang.eq.$_lang')
        .order('created_at', ascending: false)
        .limit(50);
    return rows.map(Announcement.fromJson).toList();
  }
}
