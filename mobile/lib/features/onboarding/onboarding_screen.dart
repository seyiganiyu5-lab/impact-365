import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/locale_controller.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';

/// Shown once, the first time the app is opened.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  /// SharedPreferences key set once onboarding has been completed or skipped.
  static const doneKey = 'onboarding_done';

  static const images = [
    'assets/images/onboarding_1.jpg',
    'assets/images/onboarding_2.jpg',
    'assets/images/onboarding_3.jpg',
  ];

  static Future<bool> isDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(doneKey) ?? false;
  }

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _pages = PageController();
  late final AnimationController _zoom;
  int _index = 0;

  // The pictures are landscape; these keep the person / sun in frame on a
  // portrait phone.
  static const _focus = [
    Alignment(0.05, 0),
    Alignment(0.08, 0),
    Alignment(0, 0),
  ];

  @override
  void initState() {
    super.initState();
    _zoom = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pages.dispose();
    _zoom.dispose();
    super.dispose();
  }

  bool get _isLast => _index == OnboardingScreen.images.length - 1;

  void _next() {
    if (_isLast) {
      _finish();
    } else {
      _pages.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(OnboardingScreen.doneKey, true);
    // /home for signed-in users; the router sends everyone else to /welcome.
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final texts = [
      (l.onb1Title, l.onb1Text),
      (l.onb2Title, l.onb2Text),
      (l.onb3Title, l.onb3Text),
    ];

    return Scaffold(
      backgroundColor: AppColors.purpleDark,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Pictures (swipeable).
          PageView.builder(
            controller: _pages,
            itemCount: OnboardingScreen.images.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) => AnimatedBuilder(
              animation: _zoom,
              builder: (context, child) => Transform.scale(
                // Slow "Ken Burns" zoom on the visible picture only.
                scale: i == _index
                    ? 1.0 + 0.08 * Curves.easeInOut.transform(_zoom.value)
                    : 1.0,
                child: child,
              ),
              child: Image.asset(
                OnboardingScreen.images[i],
                fit: BoxFit.cover,
                alignment: _focus[i],
              ),
            ),
          ),

          // Gradients so the text and buttons stay readable.
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x80000000),
                    Color(0x00000000),
                    Color(0x0026124F),
                    Color(0xCC26124F),
                    AppColors.purpleDark,
                  ],
                  stops: [0, 0.18, 0.42, 0.68, 1],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar: language + skip.
                  Row(
                    children: [
                      const _LanguageButton(),
                      const Spacer(),
                      AnimatedOpacity(
                        opacity: _isLast ? 0 : 1,
                        duration: const Duration(milliseconds: 200),
                        child: TextButton(
                          onPressed: _isLast ? null : _finish,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                          ),
                          child: Text(l.onbSkip, style: AppText.labelLarge),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),

                  // Title + explanation, animated on page change.
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 380),
                    switchInCurve: Curves.easeOutCubic,
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween(
                          begin: const Offset(0, 0.12),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    ),
                    layoutBuilder: (current, previous) => Stack(
                      alignment: Alignment.bottomLeft,
                      children: [...previous, ?current],
                    ),
                    child: Column(
                      key: ValueKey(_index),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '0${_index + 1} / 0${texts.length}',
                          style: AppText.labelMedium.copyWith(
                            color: AppColors.gold,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          texts[_index].$1,
                          style: AppText.headline.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          texts[_index].$2,
                          style: AppText.bodyLarge.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Dots + Next / Get started.
                  Row(
                    children: [
                      for (var i = 0; i < texts.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(right: 8),
                          width: i == _index ? 28 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _index
                                ? AppColors.gold
                                : Colors.white.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      const Spacer(),
                      _NextButton(
                        isLast: _isLast,
                        label: _isLast ? l.onbStart : l.onbNext,
                        onPressed: _next,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Gold button: "Next →" that widens into "Get started →" on the last page.
class _NextButton extends StatelessWidget {
  const _NextButton({
    required this.isLast,
    required this.label,
    required this.onPressed,
  });

  final bool isLast;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(30),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          height: 56,
          padding: EdgeInsets.symmetric(horizontal: isLast ? 28 : 22),
          decoration: BoxDecoration(
            gradient: AppColors.goldGradient,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppText.titleSmall.copyWith(color: Colors.white),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small "🌐 FR" button to pick the app language before signing in.
class _LanguageButton extends StatelessWidget {
  const _LanguageButton();

  @override
  Widget build(BuildContext context) {
    final controller = LocaleController.instance;
    return PopupMenuButton<Locale>(
      onSelected: controller.setLocale,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      itemBuilder: (context) => [
        for (final loc in LocaleController.supported)
          PopupMenuItem(
            value: loc,
            child: Row(
              children: [
                Expanded(
                  child: Text(LocaleController.displayName(loc.languageCode)),
                ),
                if (loc.languageCode == controller.languageCode)
                  const Icon(Icons.check, color: AppColors.gold, size: 18),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(
              controller.languageCode.toUpperCase(),
              style: AppText.labelMedium.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
