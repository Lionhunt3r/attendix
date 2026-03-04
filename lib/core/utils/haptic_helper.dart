import 'package:flutter/services.dart';

/// PWA-safe haptic feedback helpers
class HapticHelper {
  HapticHelper._();

  /// Light haptic for status changes
  static void light() {
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}
  }

  /// Medium haptic for destructive actions (delete, archive)
  static void medium() {
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}
  }
}
