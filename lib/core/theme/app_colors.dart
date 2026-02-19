import 'package:flutter/material.dart';

/// App color palette
class AppColors {
  AppColors._();

  // Primary colors (based on Ionic's default blue)
  static const Color primary = Color(0xFF3880FF);
  static const Color primaryLight = Color(0xFF5A9AFF);
  static const Color primaryDark = Color(0xFF1A5CCC);

  // Secondary colors
  static const Color secondary = Color(0xFF3DC2FF);
  static const Color secondaryLight = Color(0xFF6FD4FF);
  static const Color secondaryDark = Color(0xFF0A9ACC);

  // Tertiary/Accent
  static const Color tertiary = Color(0xFF5260FF);
  static const Color tertiaryLight = Color(0xFF7A85FF);
  static const Color tertiaryDark = Color(0xFF2A3ACC);

  // Success
  static const Color success = Color(0xFF2DD36F);
  static const Color successLight = Color(0xFF5AE08F);
  static const Color successDark = Color(0xFF1AA055);

  // Warning
  static const Color warning = Color(0xFFFFC409);
  static const Color warningLight = Color(0xFFFFD339);
  static const Color warningDark = Color(0xFFCC9A00);

  // Danger/Error
  static const Color danger = Color(0xFFEB445A);
  static const Color dangerLight = Color(0xFFEF6B7A);
  static const Color dangerDark = Color(0xFFBB2A3E);

  // Info (cyan blue)
  static const Color info = Color(0xFF3DC2FF);
  static const Color infoLight = Color(0xFF6FD4FF);
  static const Color infoDark = Color(0xFF0A9ACC);

  // Neutral colors
  static const Color dark = Color(0xFF222428);
  static const Color medium = Color(0xFF92949C);
  static const Color light = Color(0xFFF4F5F8);

  // Background colors
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF1E1E1E);
  static const Color surfaceLight = Color(0xFFF4F5F8);
  static const Color surfaceDark = Color(0xFF2D2D2D);

  // Text colors
  static const Color textPrimaryLight = Color(0xFF222428);
  static const Color textSecondaryLight = Color(0xFF5F6368);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);

  // Attendance status colors
  static const Color statusPresent = success;
  static const Color statusAbsent = danger;
  static const Color statusExcused = warning;
  static const Color statusLate = Color(0xFFFF9500);
  static const Color statusNeutral = medium;
  static const Color statusLateExcused = Color(0xFFFFB347);

  // Divider
  static const Color dividerLight = Color(0xFFE0E0E0);
  static const Color dividerDark = Color(0xFF3D3D3D);

  // Shadow
  static const Color shadowLight = Color(0x1A000000);
  static const Color shadowDark = Color(0x40000000);

  /// Get color for attendance status
  static Color getStatusColor(int statusValue) {
    switch (statusValue) {
      case 0:
        return statusNeutral;
      case 1:
        return statusPresent;
      case 2:
        return statusExcused;
      case 3:
        return statusLate;
      case 4:
        return statusAbsent;
      case 5:
        return statusLateExcused;
      default:
        return statusNeutral;
    }
  }

  /// Get contrast color (black or white) for a given background
  static Color getContrastColor(Color background) {
    final luminance = background.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}