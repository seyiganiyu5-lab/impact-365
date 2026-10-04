import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../widgets/common.dart';
import 'add_prayer_sheet.dart';

/// "Ma Prayer Room" tab.
class PrayerRoomScreen extends StatefulWidget {
  const PrayerRoomScreen({super.key});

  @override
  State<PrayerRoomScreen> createState() => _PrayerRoomScreenState();
}

class _PrayerRoomScreenState extends State<PrayerRoomScreen> {
  late Future<UserStats> _stats = Repo.myStats();

  void _refresh() => setState(() => _stats = Repo.myStats());

  Future<void> _open(String path) async {
    await context.push(path);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.purple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded, color: AppColors.gold),
        label: Text(l.prayerAdd),
        onPressed: () async {
          if (await showAddPrayerSheet(context)) _refresh();
        },
      ),
      body: SafeArea(
        child: FutureBuilder<UserStats>(
          future: _stats,
          builder: (context, snap) {
            final s = snap.data;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              children: [
                Row(
                  children: [
                    const SizedBox(width: 48),
                    Expanded(
                      child: ScreenTitle(
                        title: l.prayerRoomTitle,
                        subtitle: l.prayerRoomSubtitle,
                      ),
                    ),
                    IconButton(
                      onPressed: () => context.push('/inbox'),
                      icon: const Icon(Icons.notifications_none_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                VerseBanner(
                  text: l.prayerRoomVerse,
                  reference: l.prayerRoomVerseRef,
                ),
                MenuTile(
                  icon: Icons.menu_book_outlined,
                  title: l.prayerMyTopics,
                  subtitle: l.prayerMyTopicsSub,
                  count: s?.prayersOpen,
                  onTap: () => _open('/prayers/mine'),
                ),
                MenuTile(
                  icon: Icons.volunteer_activism_outlined,
                  title: l.prayerAnswered,
                  subtitle: l.prayerAnsweredSub,
                  count: s?.prayersAnswered,
                  onTap: () => _open('/prayers/answered'),
                ),
                MenuTile(
                  icon: Icons.people_outline_rounded,
                  title: l.prayerForSomeone,
                  subtitle: l.prayerForSomeoneSub,
                  onTap: () => _open('/prayers/community'),
                ),
                MenuTile(
                  icon: Icons.edit_note_rounded,
                  title: l.prayerJournal,
                  subtitle: l.prayerJournalSub,
                  onTap: () => _open('/journal'),
                ),
                MenuTile(
                  icon: Icons.shield_outlined,
                  title: l.sosTitle,
                  subtitle: l.profileSosSub,
                  onTap: () => _open('/sos'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
