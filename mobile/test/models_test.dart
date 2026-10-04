import 'package:flutter_test/flutter_test.dart';
import 'package:impact365/data/models.dart';

Map<String, dynamic> _devotionRow(List<String> langs) => {
  'id': 'd1',
  'devotion_date': '2026-05-12',
  'slot': 'morning',
  'image_url': null,
  'devotion_translations': [
    for (final l in langs)
      {
        'lang': l,
        'theme': 'theme-$l',
        'verse_reference': 'ref-$l',
        'verse_text': 'text-$l',
        'god_says': 'says-$l',
        'i_understand': 'understand-$l',
        'i_do': 'do-$l',
        'audio_url': null,
      },
  ],
};

void main() {
  group('DevotionSlot.current', () {
    test('morning before noon', () {
      expect(
        DevotionSlot.current(DateTime(2026, 1, 1, 6)),
        DevotionSlot.morning,
      );
    });
    test('afternoon from noon to 6pm', () {
      expect(
        DevotionSlot.current(DateTime(2026, 1, 1, 12)),
        DevotionSlot.afternoon,
      );
      expect(
        DevotionSlot.current(DateTime(2026, 1, 1, 17, 59)),
        DevotionSlot.afternoon,
      );
    });
    test('night from 6pm', () {
      expect(
        DevotionSlot.current(DateTime(2026, 1, 1, 18)),
        DevotionSlot.night,
      );
    });
  });

  group('Devotion.fromRow language fallback', () {
    test('uses the requested language when present', () {
      final d = Devotion.fromRow(_devotionRow(['fr', 'en', 'yo']), 'yo')!;
      expect(d.verseText, 'text-yo');
    });
    test('falls back to French when Yoruba is missing', () {
      final d = Devotion.fromRow(_devotionRow(['en', 'fr']), 'yo')!;
      expect(d.verseText, 'text-fr');
    });
    test('falls back to English when only English exists', () {
      final d = Devotion.fromRow(_devotionRow(['en']), 'fr')!;
      expect(d.verseText, 'text-en');
    });
    test('returns null when no translation exists', () {
      expect(Devotion.fromRow(_devotionRow([]), 'fr'), isNull);
    });
    test('marks completion', () {
      final d = Devotion.fromRow(
        _devotionRow(['fr']),
        'fr',
        completedIds: {'d1'},
      )!;
      expect(d.completed, isTrue);
    });
  });

  test('HelpCategory maps studies_work both ways', () {
    expect(HelpCategory.studiesWork.dbValue, 'studies_work');
    expect(HelpCategory.fromDb('studies_work'), HelpCategory.studiesWork);
  });

  test('UserStats parses my_stats() json', () {
    final s = UserStats.fromJson({
      'streak': 42,
      'devotions_completed': 128,
      'challenges_completed': 87,
      'prayers_answered': 12,
      'prayers_open': 8,
      'days_since_join': 42,
      'week_challenges': [1, 2],
    });
    expect(s.streak, 42);
    expect(s.weekChallengeDays, {1, 2});
  });
}
