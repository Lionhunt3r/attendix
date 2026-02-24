import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Centralized color parsing utility.
///
/// This class provides a single source of truth for parsing named colors
/// used throughout the app, especially for AttendanceType colors.
///
/// Available named colors:
/// - primary, secondary, tertiary (from AppColors)
/// - success, warning, danger (semantic colors)
/// - rosa, mint, orange (custom colors)
class ColorUtils {
  ColorUtils._(); // Private constructor - utility class

  /// Custom colors not defined in AppColors
  static const Color rosa = Color(0xFFE91E63); // Material Pink 500
  static const Color mint = Color(0xFF009688); // Material Teal 500
  static const Color orange = Color(0xFFFF9800); // Material Orange 500

  /// Parse a color string to a Color object.
  ///
  /// Supports:
  /// - Named colors: 'primary', 'secondary', 'tertiary', 'success', 'warning',
  ///   'danger', 'rosa', 'mint', 'orange'
  /// - Hex colors: '#FF5733', '#3880FF'
  ///
  /// Returns [AppColors.primary] if the color string is null, empty,
  /// or cannot be parsed.
  ///
  /// Example:
  /// ```dart
  /// final color = ColorUtils.parseNamedColor('rosa'); // Returns pink
  /// final hex = ColorUtils.parseNamedColor('#FF5733'); // Returns orange-red
  /// final fallback = ColorUtils.parseNamedColor('unknown'); // Returns primary
  /// ```
  static Color parseNamedColor(String? colorStr) {
    if (colorStr == null || colorStr.isEmpty) {
      return AppColors.primary;
    }

    // Handle hex colors
    if (colorStr.startsWith('#')) {
      try {
        return Color(int.parse('FF${colorStr.substring(1)}', radix: 16));
      } catch (_) {
        return AppColors.primary;
      }
    }

    // Handle named colors (case-insensitive)
    switch (colorStr.toLowerCase()) {
      case 'primary':
        return AppColors.primary;
      case 'secondary':
        return AppColors.secondary;
      case 'tertiary':
        return AppColors.tertiary;
      case 'success':
        return AppColors.success;
      case 'warning':
        return AppColors.warning;
      case 'danger':
        return AppColors.danger;
      case 'rosa':
        return rosa;
      case 'mint':
        return mint;
      case 'orange':
        return orange;
      default:
        return AppColors.primary;
    }
  }

  /// List of all available named colors for AttendanceType configuration.
  ///
  /// This should be the single source of truth for which colors
  /// can be selected in the AttendanceType edit page.
  static const List<String> availableColors = [
    'primary',
    'secondary',
    'tertiary',
    'success',
    'warning',
    'danger',
    'rosa',
    'mint',
    'orange',
  ];

  /// Get a Color from a color name (for UI display in color pickers).
  ///
  /// Unlike [parseNamedColor], this returns [Colors.purple] for tertiary
  /// to maintain visual consistency in color picker UIs where a more
  /// distinct purple is preferred.
  ///
  /// For actual color rendering in the app, use [parseNamedColor] instead.
  static Color getColorForPicker(String? colorName) {
    switch (colorName) {
      case 'primary':
        return AppColors.primary;
      case 'secondary':
        return AppColors.secondary;
      case 'tertiary':
        return Colors.purple; // More visually distinct in picker
      case 'success':
        return AppColors.success;
      case 'warning':
        return AppColors.warning;
      case 'danger':
        return AppColors.danger;
      case 'rosa':
        return Colors.pink;
      case 'mint':
        return Colors.teal;
      case 'orange':
        return Colors.orange;
      default:
        return AppColors.primary;
    }
  }
}
