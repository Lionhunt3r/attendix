import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_constants.dart';

/// Custom page transitions for GoRouter
class AppPageTransitions {
  AppPageTransitions._();

  /// Slide up transition with fade - ideal for detail pages
  static CustomTransitionPage<T> slideUp<T>({
    required Widget child,
    required GoRouterState state,
    Duration? duration,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: duration ?? AppDurations.pageTransition,
      reverseTransitionDuration: duration ?? AppDurations.pageTransition,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slideTween = Tween(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        );
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return SlideTransition(
          position: slideTween.animate(curvedAnimation),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  /// Slide from right transition - for push navigation
  static CustomTransitionPage<T> slideRight<T>({
    required Widget child,
    required GoRouterState state,
    Duration? duration,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: duration ?? AppDurations.pageTransition,
      reverseTransitionDuration: duration ?? AppDurations.pageTransition,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slideTween = Tween(
          begin: const Offset(1.0, 0),
          end: Offset.zero,
        );
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return SlideTransition(
          position: slideTween.animate(curvedAnimation),
          child: child,
        );
      },
    );
  }

  /// Simple fade transition - for tab switches
  static CustomTransitionPage<T> fade<T>({
    required Widget child,
    required GoRouterState state,
    Duration? duration,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: duration ?? AppDurations.fast,
      reverseTransitionDuration: duration ?? AppDurations.fast,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }

  /// Scale transition with fade - for modals/dialogs
  static CustomTransitionPage<T> scale<T>({
    required Widget child,
    required GoRouterState state,
    Duration? duration,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: duration ?? AppDurations.normal,
      reverseTransitionDuration: duration ?? AppDurations.fast,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final scaleTween = Tween(
          begin: 0.95,
          end: 1.0,
        );
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return ScaleTransition(
          scale: scaleTween.animate(curvedAnimation),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  /// No transition - instant switch
  static CustomTransitionPage<T> none<T>({
    required Widget child,
    required GoRouterState state,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return child;
      },
    );
  }

  /// Shared axis transition (horizontal) - Material motion
  static CustomTransitionPage<T> sharedAxisHorizontal<T>({
    required Widget child,
    required GoRouterState state,
    Duration? duration,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: duration ?? AppDurations.normal,
      reverseTransitionDuration: duration ?? AppDurations.normal,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final offsetTween = Tween(
          begin: const Offset(0.2, 0),
          end: Offset.zero,
        );
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );

        return SlideTransition(
          position: offsetTween.animate(curvedAnimation),
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 0.5),
            ),
            child: child,
          ),
        );
      },
    );
  }
}
