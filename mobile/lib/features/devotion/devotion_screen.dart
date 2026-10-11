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
  const DevotionScreen({super.key, required this.id});

  final String id;

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
  });

  final Devotion devotion;
  final bool initiallySaved;

  @override
  State<DevotionView> createState() => _DevotionViewState();
}

class _DevotionViewState extends State<DevotionView> {
  final _player = AudioPlayer();
  late bool _completed = widget.devotion.completed;
  late bool _saved = widget.initiallySaved;
  bool _saving = false;
  String? _loadedAudio;

  /// Height of the photo behind the title and verse (below the status bar).
  static const _photoHeight = 240.0;

  /// How far the white sheet rises over the photo.
  static const _sheetOverlap = 40.0;

  Devotion get d => widget.devotion;

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

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final top = MediaQuery.paddingOf(context).top;
    final photoBottom = top + _photoHeight;
    final sheetTop = photoBottom - _sheetOverlap;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.paddingOf(context).bottom + 24,
        ),
        child: Stack(
          children: [
            // Photo with a light fade at the top (title stays readable) and
            // a darker one at the bottom left (white verse stays readable).
            SizedBox(
              height: photoBottom,
              width: double.infinity,
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
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xF2F9F9F6),
                          Color(0x00F9F9F6),
                          Color(0x00000000),
                          Color(0x8C1A0B3D),
                        ],
                        stops: [0, 0.32, 0.5, 1],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Cream frame with a golden glow behind the sheet (full width).
            Positioned(
              left: 0,
              right: 0,
              top: sheetTop + 36,
              bottom: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFF3EBD3), Color(0xFFF9F7F0)],
                    stops: [0, 0.35],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(48),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.25),
                      blurRadius: 24,
                    ),
                  ],
                ),
              ),
            ),

            // Page content: header text, then the white sheet.
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: top),
                _TopBar(
                  title: l.devotionTitle,
                  onBack: _back,
                  menu: _menu(context),
                ),
                SizedBox(
                  height: sheetTop - top - 56,
                  child: Padding(
                    // Right padding leaves room for the date badge.
                    padding: const EdgeInsets.fromLTRB(20, 4, 112, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d.verseReference,
                          style: AppText.headline.copyWith(
                            color: Colors.white,
                            fontSize: 24,
                            shadows: _textShadow,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Flexible(
                          child: Text(
                            d.verseText,
                            maxLines: 5,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.bodySmall.copyWith(
                              color: Colors.white,
                              fontStyle: FontStyle.italic,
                              height: 1.35,
                              shadows: _textShadow,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _Sheet(
                  children: [
                    _Section(
                      icon: const _BibleIcon(),
                      title: l.devotionGodSays,
                      body: d.godSays,
                    ),
                    const _SectionDivider(),
                    _Section(
                      icon: const Icon(
                        Icons.psychology_outlined,
                        size: 52,
                        color: AppColors.ink,
                      ),
                      title: l.devotionIUnderstand,
                      body: d.iUnderstand,
                    ),
                    const _SectionDivider(),
                    _Section(
                      icon: const _HandCheckIcon(),
                      title: l.devotionIDo,
                      body: d.iDo,
                    ),
                    const SizedBox(height: 12),
                    _UnderstoodButton(
                      label: _completed
                          ? l.devotionCompleted.toUpperCase()
                          : l.devotionDone,
                      done: _completed,
                      busy: _saving,
                      onPressed: _completed || _saving ? null : _complete,
                    ),
                    const SizedBox(height: 12),
                    if (d.audioUrl != null)
                      StreamBuilder<bool>(
                        stream: _player.playingStream,
                        builder: (context, snap) {
                          final playing = snap.data ?? false;
                          return _AudioButton(
                            label: playing ? l.devotionPause : l.devotionListen,
                            icon: playing
                                ? Icons.pause_rounded
                                : Icons.headphones_outlined,
                            onPressed: () => _toggleAudio(d.audioUrl!),
                          );
                        },
                      )
                    else
                      _AudioButton(
                        label: l.devotionAudioSoon,
                        icon: Icons.headphones_outlined,
                        onPressed: null,
                      ),
                  ],
                ),
              ],
            ),

            // Date badge, overlapping the photo and the sheet.
            Positioned(
              right: 20,
              top: sheetTop - 90,
              child: _DateBadge(date: d.date),
            ),
          ],
        ),
      ),
    );
  }

  static const _textShadow = [
    Shadow(color: Color(0x80000000), blurRadius: 10, offset: Offset(0, 1)),
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
    final gold = AppText.bodyMedium.copyWith(color: AppColors.gold);
    return Container(
      width: 88,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.deepPurple,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gold, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(day.toUpperCase(), maxLines: 1, style: gold),
          ),
          Text(
            date.day.toString().padLeft(2, '0'),
            style: AppText.display.copyWith(
              color: AppColors.gold,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          Text(month.toUpperCase(), style: gold),
        ],
      ),
    );
  }
}

/// White sheet with rounded top corners and a soft golden glow.
class _Sheet extends StatelessWidget {
  const _Sheet({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.fromLTRB(16, 26, 16, 20),
      decoration: BoxDecoration(
        color: AppColors.warmWhite,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(40),
          bottom: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.28),
            blurRadius: 28,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.icon, required this.title, required this.body});

  final Widget icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 60, child: Center(child: icon)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppText.titleSmall.copyWith(
                    color: AppColors.deepPurple,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: AppText.bodyMedium.copyWith(
                    color: AppColors.deepPurple,
                    height: 1.45,
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

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) => const Divider(
    height: 8,
    indent: 20,
    endIndent: 20,
    color: Color(0xFFB9B4C7),
  );
}

/// Open Bible with a cross above it (line style, like the design).
class _BibleIcon extends StatelessWidget {
  const _BibleIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Icon(Icons.menu_book_outlined, size: 50, color: AppColors.ink),
          Positioned(
            top: 0,
            child: Icon(Icons.add, size: 20, color: AppColors.ink),
          ),
        ],
      ),
    );
  }
}

/// Raised hand with a check mark: "what I do".
class _HandCheckIcon extends StatelessWidget {
  const _HandCheckIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: Icon(
              Icons.back_hand_outlined,
              size: 44,
              color: AppColors.ink,
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Icon(
              Icons.check_circle_outline_rounded,
              size: 22,
              color: AppColors.ink,
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
