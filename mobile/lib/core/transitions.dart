import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

/// How long a page takes to slide in / out. Short, like WhatsApp: the move
/// is visible but feels instant.
const pageInDuration = Duration(milliseconds: 220);
const pageOutDuration = Duration(milliseconds: 180);

/// A page opened on top of another (devotion, inbox, Holy SOS, ...).
///
/// - Android: quick slide from the right with a light fade.
/// - iPhone: the native slide, with the swipe-from-the-edge to go back.
Page<void> appPage(GoRouterState state, Widget child) {
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    return CupertinoPage<void>(key: state.pageKey, child: child);
  }
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: pageInDuration,
    reverseTransitionDuration: pageOutDuration,
    transitionsBuilder: quickSlide,
  );
}

/// Pages that replace each other (splash → welcome, tabs): no animation.
Page<void> instantPage(GoRouterState state, Widget child) =>
    NoTransitionPage<void>(key: state.pageKey, child: child);

/// Quick fade, for the welcome / onboarding / sign-in-in-progress screens.
Page<void> fadePage(GoRouterState state, Widget child) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: pageInDuration,
      reverseTransitionDuration: pageOutDuration,
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    );

/// The incoming page slides in from 25 % on the right and fades in; the
/// page underneath slides slightly to the left (like WhatsApp on Android).
Widget quickSlide(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  final incoming = CurvedAnimation(
    parent: animation,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );
  final outgoing = CurvedAnimation(
    parent: secondaryAnimation,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );
  return SlideTransition(
    position: Tween(
      begin: Offset.zero,
      end: const Offset(-0.08, 0),
    ).animate(outgoing),
    child: SlideTransition(
      position: Tween(
        begin: const Offset(0.25, 0),
        end: Offset.zero,
      ).animate(incoming),
      child: FadeTransition(
        opacity: Tween(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: const Interval(0, 0.7)),
        ),
        child: child,
      ),
    ),
  );
}

/// Same quick slide for any page opened with Navigator.push (MaterialPageRoute)
/// on Android, set in the theme.
class QuickSlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const QuickSlidePageTransitionsBuilder();

  @override
  Duration get transitionDuration => pageInDuration;

  @override
  Duration get reverseTransitionDuration => pageOutDuration;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => quickSlide(context, animation, secondaryAnimation, child);
}
