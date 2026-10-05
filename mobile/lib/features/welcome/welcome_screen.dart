import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../widgets/common.dart';

/// "Bienvenue sur IMPACT-365" — choose to sign in or create an account.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..forward();

  Animation<double> _step(double from, double to) => CurvedAnimation(
    parent: _c,
    curve: Interval(from, to, curve: Curves.easeOutCubic),
  );

  late final _logo = _step(0.0, 0.45);
  late final _title = _step(0.12, 0.55);
  late final _subtitle = _step(0.22, 0.65);
  late final _panel = _step(0.25, 0.80);
  late final _buttons = _step(0.55, 1.0);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      body: Stack(
        children: [
          // Soft decorative circles (top-right and left), as in the design.
          Positioned(
            top: -size.width * 0.18,
            right: -size.width * 0.16,
            child: _Circle(diameter: size.width * 0.62),
          ),
          Positioned(
            top: size.height * 0.16,
            left: -size.width * 0.36,
            child: _Circle(diameter: size.width * 0.62),
          ),
          Column(
            children: [
              Expanded(
                flex: 45,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _Appear(
                          animation: _logo,
                          scaleFrom: 0.8,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.deepPurple.withValues(
                                    alpha: 0.18,
                                  ),
                                  blurRadius: 22,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/images/logo_full.png',
                              width: 104,
                              height: 104,
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        _Appear(
                          animation: _title,
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(text: '${l.welcomeTitle}\nIMPACT-'),
                                const TextSpan(
                                  text: '365',
                                  style: TextStyle(color: AppColors.gold),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                            style: AppText.display.copyWith(
                              color: AppColors.deepPurple,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        _Appear(
                          animation: _subtitle,
                          child: Text(
                            l.welcomeSubtitle,
                            textAlign: TextAlign.center,
                            style: AppText.bodyMedium.copyWith(
                              color: AppColors.deepPurple,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 55,
                child: AnimatedBuilder(
                  animation: _panel,
                  builder: (context, child) => FractionalTranslation(
                    translation: Offset(0, 1 - _panel.value),
                    child: child,
                  ),
                  child: _BottomPanel(buttons: _buttons),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BottomPanel extends StatelessWidget {
  const _BottomPanel({required this.buttons});

  final Animation<double> buttons;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.deepPurple,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
        // The soft, glowing edge from the design.
        boxShadow: [
          BoxShadow(
            color: AppColors.deepPurple.withValues(alpha: 0.35),
            blurRadius: 40,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 36, 32, 28),
          child: FadeTransition(
            opacity: buttons,
            child: Column(
              children: [
                const Icon(
                  Icons.format_quote_rounded,
                  color: AppColors.gold,
                  size: 34,
                ),
                const SizedBox(height: 6),
                Text(
                  l.welcomeVerse,
                  textAlign: TextAlign.center,
                  style: AppText.scripture.copyWith(
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l.welcomeVerseRef,
                  style: AppText.scriptureRef.copyWith(color: AppColors.gold),
                ),
                const Spacer(),
                _WelcomeButton(
                  label: l.welcomeSignIn,
                  background: Colors.white,
                  foreground: AppColors.deepPurple,
                  onPressed: () => context.push('/auth?mode=signin'),
                ),
                const SizedBox(height: 16),
                _WelcomeButton(
                  label: l.welcomeSignUp,
                  background: AppColors.gold,
                  foreground: Colors.white,
                  onPressed: () => context.push('/auth?mode=signup'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeButton extends StatelessWidget {
  const _WelcomeButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onPressed,
  });

  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        // Style on the Text so it keeps the app font from the theme.
        child: Text(label, style: AppText.labelLarge.copyWith(fontSize: 17)),
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle({required this.diameter});

  final double diameter;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFF3F1EB),
      ),
    );
  }
}

/// Fades a child in while sliding it up slightly (optionally scaling).
class _Appear extends StatelessWidget {
  const _Appear({
    required this.animation,
    required this.child,
    this.scaleFrom = 1,
  });

  final Animation<double> animation;
  final Widget child;
  final double scaleFrom;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final v = animation.value;
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - v)),
            child: Transform.scale(
              scale: scaleFrom + (1 - scaleFrom) * v,
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }
}
