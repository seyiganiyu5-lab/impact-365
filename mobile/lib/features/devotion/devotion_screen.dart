import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../widgets/common.dart';
import 'word_screen.dart';

/// "5 MINUTES AVEC DIEU" — read, understand, apply.
class DevotionScreen extends StatefulWidget {
  const DevotionScreen({super.key, required this.id});

  final String id;

  @override
  State<DevotionScreen> createState() => _DevotionScreenState();
}

class _DevotionScreenState extends State<DevotionScreen> {
  late final Future<Devotion?> _future = Repo.devotion(widget.id);
  final _player = AudioPlayer();
  bool _completed = false;
  bool _saving = false;
  String? _loadedAudio;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggleAudio(String url) async {
    try {
      if (_player.playing) {
        await _player.pause();
        return;
      }
      if (_loadedAudio != url) {
        await _player.setUrl(url);
        _loadedAudio = url;
      }
      await _player.play();
    } catch (_) {
      if (mounted) context.toast(context.l10n.commonError);
    }
  }

  Future<void> _complete(Devotion d) async {
    setState(() => _saving = true);
    try {
      await Repo.completeDevotion(d.id);
      if (mounted) setState(() => _completed = true);
    } catch (_) {
      if (mounted) context.toast(context.l10n.commonError);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      body: AsyncView<Devotion?>(
        future: _future,
        builder: (context, d) {
          if (d == null) {
            return SafeArea(child: EmptyState(message: l.homeNoDevotion));
          }
          final done = _completed || d.completed;
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 280,
                backgroundColor: AppColors.purple,
                foregroundColor: Colors.white,
                title: Text(
                  l.devotionTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: _Header(devotion: d),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                sliver: SliverList.list(
                  children: [
                    AppCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Column(
                        children: [
                          _Section(
                            icon: Icons.auto_stories_rounded,
                            title: l.devotionGodSays,
                            body: d.godSays,
                          ),
                          const Divider(color: AppColors.border),
                          _Section(
                            icon: Icons.psychology_rounded,
                            title: l.devotionIUnderstand,
                            body: d.iUnderstand,
                          ),
                          const Divider(color: AppColors.border),
                          _Section(
                            icon: Icons.volunteer_activism_rounded,
                            title: l.devotionIDo,
                            body: d.iDo,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    FilledButton(
                      onPressed: done || _saving ? null : () => _complete(d),
                      style: FilledButton.styleFrom(
                        disabledBackgroundColor: AppColors.purpleLight,
                        disabledForegroundColor: Colors.white,
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 24),
                          Expanded(
                            child: Text(
                              done ? l.devotionCompleted : l.devotionDone,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const Icon(
                            Icons.check_rounded,
                            color: AppColors.gold,
                          ),
                        ],
                      ),
                    ),
                    if (d.audioUrl != null) ...[
                      const SizedBox(height: 12),
                      StreamBuilder<bool>(
                        stream: _player.playingStream,
                        builder: (context, snap) {
                          final playing = snap.data ?? false;
                          return OutlinedButton.icon(
                            onPressed: () => _toggleAudio(d.audioUrl!),
                            icon: Icon(
                              playing
                                  ? Icons.pause_rounded
                                  : Icons.headphones_rounded,
                            ),
                            label: Text(
                              playing ? l.devotionPause : l.devotionListen,
                            ),
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                    AppCard(
                      color: AppColors.lavender,
                      child: Row(
                        children: [
                          const IconBubble(icon: Icons.help_outline_rounded),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l.devotionQuestionTitle,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  l.devotionQuestionText,
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => context.push(
                        Uri(
                          path: '/inbox/new',
                          queryParameters: {'subject': d.verseReference},
                        ).toString(),
                      ),
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: Text(l.devotionAskQuestion),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.devotion});

  final Devotion devotion;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final dayName = l.weekdaysShort.split(',')[devotion.date.weekday - 1];
    final month = l.monthsShort.split(',')[devotion.date.month - 1];
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.sunsetGradient,
        image: devotion.imageUrl == null
            ? null
            : DecorationImage(
                image: NetworkImage(devotion.imageUrl!),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withValues(alpha: 0.35),
                  BlendMode.darken,
                ),
              ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 100, 20, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Icon(
                      slotIcon(devotion.slot),
                      color: AppColors.goldLight,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      slotLabel(context, devotion.slot),
                      style: const TextStyle(color: AppColors.goldLight),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  devotion.verseReference,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  devotion.verseText,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.purple.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.6)),
            ),
            child: Column(
              children: [
                Text(
                  dayName.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.goldLight,
                    fontSize: 11,
                  ),
                ),
                Text(
                  '${devotion.date.day}',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  month.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.goldLight,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBubble(icon: icon, size: 56),
          const SizedBox(width: 14),
          Container(width: 2, height: 56, color: AppColors.goldLight),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.purple,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(body, style: const TextStyle(height: 1.45, fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
