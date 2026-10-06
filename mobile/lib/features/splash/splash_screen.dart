import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth_links.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';
import '../onboarding/onboarding_screen.dart';

/// Animated splash: the ring appears, the gold star shoots into place,
/// then the name and tagline reveal. Afterwards we go to /home (the router
/// sends signed-out users to /welcome).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  // Each step of the animation runs in its own slice of the timeline (0..1).
  late final Animation<double> _ringScale;
  late final Animation<double> _ringFade;
  late final Animation<double> _ringTurn;
  late final Animation<double> _starTravel;
  late final Animation<double> _starFade;
  late final Animation<double> _flash;
  late final Animation<double> _title;
  late final Animation<double> _tagline;
  late final Animation<double> _exit;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    Animation<double> step(
      double from,
      double to, [
      Curve curve = Curves.easeOut,
    ]) => CurvedAnimation(
      parent: _c,
      curve: Interval(from, to, curve: curve),
    );

    _ringScale = Tween(
      begin: 0.55,
      end: 1.0,
    ).animate(step(0.0, 0.30, Curves.easeOutBack));
    _ringFade = step(0.0, 0.18);
    _ringTurn = Tween(
      begin: -0.35,
      end: 0.0,
    ).animate(step(0.0, 0.32, Curves.easeOutCubic));
    _starTravel = step(0.22, 0.46, Curves.easeOutCubic);
    _starFade = step(0.22, 0.30);
    _flash = step(0.44, 0.66);
    _title = step(0.46, 0.68, Curves.easeOutCubic);
    _tagline = step(0.60, 0.78);
    _exit = step(0.90, 1.0, Curves.easeIn);

    _c.addStatusListener((status) {
      if (status == AnimationStatus.completed) _goNext();
    });
  }

  /// First launch → onboarding (for everyone). Otherwise /home; the router
  /// sends signed-out users to /welcome.
  Future<void> _goNext() async {
    // Opened from a password-reset email: go straight to the new password.
    if (AuthFlow.recoveryPending) {
      if (mounted) context.go('/reset-password');
      return;
    }
    final seen = await OnboardingScreen.isDone();
    if (mounted) context.go(seen ? '/home' : '/onboarding');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load the onboarding pictures while the animation plays.
    for (final image in OnboardingScreen.images) {
      precacheImage(AssetImage(image), context);
    }
    if (_c.isAnimating || _c.isCompleted) return;
    // Respect the "reduce motion" accessibility setting.
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.duration = const Duration(milliseconds: 900);
    }
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final markHeight = math.min(size.width * 0.5, 220.0);
    // Mark artwork is 705 x 843.
    final markWidth = markHeight * 705 / 843;

    return Scaffold(
      backgroundColor: AppColors.deepPurple,
      body: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Opacity(
          opacity: 1 - _exit.value,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Soft glow behind the logo.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.15),
                    radius: 0.9,
                    colors: [
                      Color.lerp(
                        AppColors.deepPurple,
                        AppColors.purpleLight,
                        _ringFade.value,
                      )!,
                      AppColors.deepPurple,
                      AppColors.purpleDark,
                    ],
                    stops: const [0, 0.55, 1],
                  ),
                ),
              ),
              CustomPaint(painter: _SparklePainter(_c.value)),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: markWidth,
                      height: markHeight,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _buildRing(markWidth, markHeight),
                          _buildFlash(markWidth, markHeight),
                          _buildStar(markWidth, markHeight),
                        ],
                      ),
                    ),
                    SizedBox(height: markHeight * 0.22),
                    _buildTitle(),
                    const SizedBox(height: 10),
                    _buildTagline(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRing(double w, double h) {
    return Positioned.fill(
      child: Opacity(
        opacity: _ringFade.value,
        child: Transform.rotate(
          angle: _ringTurn.value,
          child: Transform.scale(
            scale: _ringScale.value,
            child: Image.asset(
              'assets/images/logo_ring_white.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStar(double w, double h) {
    // The star flies in along its own diagonal, from bottom-left.
    final t = _starTravel.value;
    final dx = -w * 0.55 * (1 - t);
    final dy = h * 0.65 * (1 - t);
    return Positioned.fill(
      child: Opacity(
        opacity: _starFade.value,
        child: Transform.translate(
          offset: Offset(dx, dy),
          child: Image.asset(
            'assets/images/logo_star.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildFlash(double w, double h) {
    // Gold burst where the star tip lands (top-right of the mark).
    final v = _flash.value;
    if (v == 0 || v == 1) return const SizedBox.shrink();
    final d = w * (0.3 + 0.9 * v);
    return Positioned(
      left: w * 0.80 - d / 2,
      top: h * 0.10 - d / 2,
      width: d,
      height: d,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              AppColors.goldLight.withValues(alpha: 0.85 * (1 - v)),
              AppColors.gold.withValues(alpha: 0.35 * (1 - v)),
              AppColors.gold.withValues(alpha: 0),
            ],
            stops: const [0, 0.35, 1],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    final v = _title.value;
    return Opacity(
      opacity: v,
      child: Transform.translate(
        offset: Offset(0, 18 * (1 - v)),
        child: Text(
          'IMPACT-365',
          style: AppText.display.copyWith(
            color: Colors.white, // Letters start spread out and close up.
            letterSpacing: 2 + 14 * (1 - v),
          ),
        ),
      ),
    );
  }

  Widget _buildTagline(BuildContext context) {
    final v = _tagline.value;
    return Opacity(
      opacity: v,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 28 * v, height: 1.5, color: AppColors.gold),
          const SizedBox(width: 10),
          Text(
            context.l10n.appTagline,
            style: AppText.bodyLarge.copyWith(
              color: AppColors.gold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 10),
          Container(width: 28 * v, height: 1.5, color: AppColors.gold),
        ],
      ),
    );
  }
}

/// A few gold specks that twinkle softly in the background.
class _SparklePainter extends CustomPainter {
  _SparklePainter(this.t);

  final double t;

  // Fixed positions (fractions of the screen) and phase offsets.
  static const _specks = [
    (0.12, 0.18, 0.0, 2.2),
    (0.85, 0.12, 0.3, 1.6),
    (0.78, 0.32, 0.6, 2.6),
    (0.20, 0.42, 0.15, 1.8),
    (0.90, 0.58, 0.45, 2.0),
    (0.08, 0.70, 0.75, 2.4),
    (0.30, 0.86, 0.5, 1.5),
    (0.70, 0.82, 0.9, 2.2),
    (0.55, 0.08, 0.2, 1.4),
    (0.45, 0.94, 0.65, 1.9),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final (x, y, phase, radius) in _specks) {
      final twinkle = (math.sin((t * 3 + phase) * math.pi * 2) + 1) / 2;
      final appear = (t * 4 - phase).clamp(0.0, 1.0);
      paint.color = AppColors.gold.withValues(alpha: 0.55 * twinkle * appear);
      canvas.drawCircle(Offset(x * size.width, y * size.height), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_SparklePainter old) => old.t != t;
}
