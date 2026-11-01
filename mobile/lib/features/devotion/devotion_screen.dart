import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../widgets/common.dart';

/// "5 MINUTES AVEC DIEU": one devotion — verse, what God says, what I
/// understand, what I do.
class DevotionScreen extends StatefulWidget {
  const DevotionScreen({super.key, required this.id, this.initial});

  final String id;

  /// The devotion already on screen in Parole: shown at once (no loading);
  /// only the bookmark state is fetched in the background.
  final Devotion? initial;

  @override
  State<DevotionScreen> createState() => _DevotionScreenState();
}

class _DevotionScreenState extends State<DevotionScreen> {
  late final Future<(Devotion?, bool)> _future = _load();

  Future<(Devotion?, bool)> _load() async {
    final d = await Repo.devotion(widget.id);
    var saved = false;
    if (d != null) {
      try {
        saved = (await Repo.bookmarkedDevotionIds([d.id])).isNotEmpty;
      } catch (_) {
        // Bookmarks are optional.
      }
    }
    return (d, saved);
  }

  @override
  Widget build(BuildContext context) {
    final initial = widget.initial;
    if (initial != null) {
      return Scaffold(
        backgroundColor: AppColors.warmWhite,
        body: DevotionView(devotion: initial, checkSaved: true),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      body: AsyncView<(Devotion?, bool)>(
        future: _future,
        builder: (context, result) {
          final (d, saved) = result;
          if (d == null) {
            return SafeArea(
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: BackButton(color: AppColors.deepPurple),
                  ),
                  Expanded(
                    child: EmptyState(message: context.l10n.devotionNotFound),
                  ),
                ],
              ),
            );
          }
          return DevotionView(devotion: d, initiallySaved: saved);
        },
      ),
    );
  }
}

/// The page itself (public so tests can render it with sample data).
class DevotionView extends StatefulWidget {
  const DevotionView({
    super.key,
    required this.devotion,
    this.initiallySaved = false,
    this.checkSaved = false,
  });

  final Devotion devotion;
  final bool initiallySaved;

  /// Look up in the background whether this devotion is saved.
  final bool checkSaved;

  @override
  State<DevotionView> createState() => _DevotionViewState();
}

class _DevotionViewState extends State<DevotionView> {
  final _player = AudioPlayer();
  late bool _completed = widget.devotion.completed;
  late bool _saved = widget.initiallySaved;
  bool _saving = false;
  String? _loadedAudio;

  Devotion get d => widget.devotion;

  @override
  void initState() {
    super.initState();
    if (widget.checkSaved) _loadSaved();
  }

  Future<void> _loadSaved() async {
    try {
      final ids = await Repo.bookmarkedDevotionIds([d.id]);
      if (mounted) setState(() => _saved = ids.isNotEmpty);
    } catch (_) {
      // Bookmarks are optional.
    }
  }

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
    } catch (e) {
      if (mounted) context.toast(context.errorText(e));
    }
  }

  Future<void> _complete() async {
    setState(() => _saving = true);
    try {
      await Repo.completeDevotion(d.id);
      if (mounted) setState(() => _completed = true);
    } catch (e) {
      if (mounted) context.toast(context.errorText(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _toggleSaved() async {
    final next = !_saved;
    setState(() => _saved = next);
    try {
      await Repo.setDevotionBookmark(d.id, next);
      if (mounted) {
        context.toast(
          next
              ? context.l10n.homeBookmarkAdded
              : context.l10n.homeBookmarkRemoved,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saved = !next);
        context.toast(context.errorText(e));
      }
    }
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/word');
    }
  }

  /// Height of the photo header below the status bar.
  static const _headerHeight = 250.0;

  /// How far the sheet rises over the photo.
  static const _overlap = 28.0;

  String _slotLabel(BuildContext context) {
    final l = context.l10n;
    return switch (d.slot) {
      DevotionSlot.morning => '🌅  ${l.slotMorning}',
      DevotionSlot.afternoon => '☀️  ${l.slotAfternoon}',
      DevotionSlot.night => '🌙  ${l.slotNight}',
    };
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final media = MediaQuery.of(context);
    final top = media.padding.top;
    final headerBottom = top + _headerHeight;
    final theme = (d.theme ?? '').trim();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: SingleChildScrollView(
        child: Stack(
          children: [
            // Photo header: theme of the day, reference, date.
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: headerBottom,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (d.imageUrl != null)
                    FadeInImage(
                      placeholder: const AssetImage(
                        'assets/images/home_hero.jpg',
                      ),
                      image: NetworkImage(d.imageUrl!),
                      fit: BoxFit.cover,
                      imageErrorBuilder: (_, _, _) => Image.asset(
                        'assets/images/home_hero.jpg',
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Image.asset(
                      'assets/images/home_hero.jpg',
                      fit: BoxFit.cover,
                    ),
                  // Light at the top (title bar), deep purple at the bottom
                  // (white text stays readable on any photo).
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xF2F9F9F6),
                          Color(0x00F9F9F6),
                          Color(0x261A0B3D),
                          Color(0xD91A0B3D),
                        ],
                        stops: [0, 0.3, 0.5, 1],
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: top),
                      _TopBar(
                        title: l.devotionTitle,
                        onBack: _back,
                        menu: _menu(context),
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          20,
                          0,
                          20,
                          _overlap + 18,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _GlassChip(label: _slotLabel(context)),
                                  const SizedBox(height: 10),
                                  Text(
                                    theme.isNotEmpty ? theme : d.verseReference,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppText.headline.copyWith(
                                      color: Colors.white,
                                      fontSize: 26,
                                      height: 1.15,
                                      shadows: _textShadow,
                                    ),
                                  ),
                                  if (theme.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      d.verseReference,
                                      style: AppText.scriptureRef.copyWith(
                                        color: AppColors.gold,
                                        fontSize: 15,
                                        shadows: _textShadow,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            _DateBadge(date: d.date),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // The sheet: verse, the three steps, actions.
            Padding(
              padding: EdgeInsets.only(top: headerBottom - _overlap),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: media.size.height - headerBottom + _overlap,
                ),
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: AppColors.warmWhite,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      18,
                      22,
                      18,
                      media.padding.bottom + 28,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _VerseCard(
                          text: d.verseText,
                          reference: d.verseReference,
                        ),
                        const SizedBox(height: 18),
                        _Step(
                          number: 1,
                          icon: Icons.menu_book_rounded,
                          title: l.devotionGodSays,
                          body: d.godSays,
                        ),
                        _Step(
                          number: 2,
                          icon: Icons.lightbulb_outline_rounded,
                          title: l.devotionIUnderstand,
                          body: d.iUnderstand,
                        ),
                        _Step(
                          number: 3,
                          icon: Icons.directions_walk_rounded,
                          title: l.devotionIDo,
                          body: d.iDo,
                          highlight: true,
                          last: true,
                        ),
                        const SizedBox(height: 22),
                        _UnderstoodButton(
                          label: _completed
                              ? l.devotionCompleted.toUpperCase()
                              : l.devotionDone,
                          done: _completed,
                          busy: _saving,
                          onPressed: _completed || _saving ? null : _complete,
                        ),
                        if (d.audioUrl != null) ...[
                          const SizedBox(height: 12),
                          StreamBuilder<bool>(
                            stream: _player.playingStream,
                            builder: (context, snap) {
                              final playing = snap.data ?? false;
                              return _AudioButton(
                                label: playing
                                    ? l.devotionPause
                                    : l.devotionListen,
                                icon: playing
                                    ? Icons.pause_rounded
                                    : Icons.headphones_rounded,
                                onPressed: () => _toggleAudio(d.audioUrl!),
                              );
                            },
                          ),
                        ],
                        const SizedBox(height: 22),
                        _QuestionCard(
                          onAsk: () => context.push(
                            Uri(
                              path: '/inbox/new',
                              queryParameters: {'subject': d.verseReference},
                            ).toString(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _textShadow = [
    Shadow(color: Color(0x66000000), blurRadius: 12, offset: Offset(0, 1)),
  ];

  Widget _menu(BuildContext context) {
    final l = context.l10n;
    return PopupMenuButton<String>(
      tooltip: l.devotionMore,
      icon: const Icon(
        Icons.more_vert_rounded,
        color: AppColors.deepPurple,
        size: 28,
      ),
      color: AppColors.warmWhite,
      onSelected: (value) {
        switch (value) {
          case 'save':
            _toggleSaved();
          case 'copy':
            Clipboard.setData(
              ClipboardData(text: '${d.verseText}\n— ${d.verseReference}'),
            );
            context.toast(l.devotionCopied);
          case 'ask':
            context.push(
              Uri(
                path: '/inbox/new',
                queryParameters: {'subject': d.verseReference},
              ).toString(),
            );
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'save',
          child: _MenuRow(
            icon: _saved
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            label: _saved ? l.devotionMenuUnsave : l.devotionMenuSave,
          ),
        ),
        PopupMenuItem(
          value: 'copy',
          child: _MenuRow(icon: Icons.copy_rounded, label: l.devotionMenuCopy),
        ),
        PopupMenuItem(
          value: 'ask',
          child: _MenuRow(
            icon: Icons.chat_bubble_outline_rounded,
            label: l.devotionMenuAsk,
          ),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.onBack,
    required this.menu,
  });

  final String title;
  final VoidCallback onBack;
  final Widget menu;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          const SizedBox(width: 4),
          IconButton(
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.deepPurple,
              size: 28,
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.titleMedium.copyWith(
                color: AppColors.deepPurple,
                letterSpacing: 0.3,
              ),
            ),
          ),
          menu,
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.deepPurple, size: 20),
        const SizedBox(width: 12),
        Flexible(child: Text(label, style: AppText.bodyMedium)),
      ],
    );
  }
}

class _DateBadge extends StatelessWidget {
  const _DateBadge({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final day = l.weekdaysLong.split(',')[date.weekday - 1];
    final month = l.monthsShort.split(',')[date.month - 1].replaceAll('.', '');
    final small = AppText.labelSmall.copyWith(
      color: AppColors.gold,
      fontSize: 11,
      letterSpacing: 0.6,
    );
    return Container(
      width: 74,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.deepPurple,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gold, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(day.toUpperCase(), maxLines: 1, style: small),
          ),
          Text(
            date.day.toString().padLeft(2, '0'),
            style: AppText.display.copyWith(
              color: AppColors.gold,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          Text(month.toUpperCase(), style: small),
        ],
      ),
    );
  }
}

/// Small translucent label on the photo ("🌅 Matin").
class _GlassChip extends StatelessWidget {
  const _GlassChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppText.labelSmall.copyWith(
          color: Colors.white,
          fontSize: 11.5,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

/// The Bible verse, in the scripture font, like a quote.
class _VerseCard extends StatelessWidget {
  const _VerseCard({required this.text, required this.reference});

  final String text;
  final String reference;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      decoration: BoxDecoration(
        color: AppColors.beige,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '“',
            style: AppText.scriptureLarge.copyWith(
              color: AppColors.gold,
              fontSize: 48,
              height: 0.9,
            ),
          ),
          Text(
            text,
            style: AppText.scriptureLarge.copyWith(
              color: AppColors.ink,
              fontSize: 19,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(width: 22, height: 2, color: AppColors.gold),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  reference,
                  style: AppText.scriptureRef.copyWith(
                    color: AppColors.goldDark,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One of the three steps, joined by a thin line like a path.
class _Step extends StatelessWidget {
  const _Step({
    required this.number,
    required this.icon,
    required this.title,
    required this.body,
    this.highlight = false,
    this.last = false,
  });

  final int number;
  final IconData icon;
  final String title;
  final String body;

  /// "Ce que je fais": the step to live today, in gold.
  final bool highlight;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 44,
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: highlight ? AppColors.gold : AppColors.deepPurple,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      color: AppColors.lavender,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 18),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                decoration: BoxDecoration(
                  color: highlight
                      ? AppColors.gold.withValues(alpha: 0.12)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: highlight
                        ? AppColors.gold.withValues(alpha: 0.5)
                        : AppColors.border,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$number · $title',
                      style: AppText.labelSmall.copyWith(
                        color: highlight
                            ? AppColors.goldDark
                            : AppColors.deepPurple,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      body,
                      style: AppText.bodyLarge.copyWith(
                        color: AppColors.ink,
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Une question ?" → private message to a leader.
class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.onAsk});

  final VoidCallback onAsk;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color: AppColors.lavender,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Text('💬', style: TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.devotionQuestionTitle,
                  style: AppText.titleSmall.copyWith(
                    color: AppColors.deepPurple,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l.devotionQuestionText,
                  style: AppText.bodySmall.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onAsk,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.deepPurple,
              backgroundColor: Colors.white,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            child: Text(
              l.devotionAskQuestion,
              style: AppText.labelSmall.copyWith(fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnderstoodButton extends StatelessWidget {
  const _UnderstoodButton({
    required this.label,
    required this.done,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final bool done;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.deepPurple,
          // Once done, stays purple (not greyed) with the gold check.
          disabledBackgroundColor: AppColors.deepPurple.withValues(
            alpha: done ? 0.85 : 0.6,
          ),
          disabledForegroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 28),
            Expanded(
              child: busy
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : Text(
                      label,
                      textAlign: TextAlign.center,
                      style: AppText.labelLarge.copyWith(color: Colors.white),
                    ),
            ),
            Icon(
              done ? Icons.check_circle_rounded : Icons.check_rounded,
              color: AppColors.gold,
              size: 26,
            ),
          ],
        ),
      ),
    );
  }
}

class _AudioButton extends StatelessWidget {
  const _AudioButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.deepPurple,
          disabledForegroundColor: AppColors.deepPurple.withValues(alpha: 0.45),
          side: BorderSide(
            color: AppColors.deepPurple.withValues(
              alpha: onPressed == null ? 0.35 : 1,
            ),
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.labelLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
