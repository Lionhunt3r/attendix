import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Helper class for showing toast messages (SnackBars)
///
/// Based on Ionic Utils.ts showToast method
class ToastHelper {
  /// Shows a success toast with green background
  static void showSuccess(BuildContext context, String message) {
    _showToast(
      context,
      message,
      backgroundColor: Colors.green,
      icon: Icons.check_circle,
    );
  }

  /// Shows an error toast with red background
  static void showError(BuildContext context, String message) {
    _showToast(
      context,
      message,
      backgroundColor: Colors.red,
      icon: Icons.error,
    );
  }

  /// Shows an info toast with default background
  static void showInfo(BuildContext context, String message) {
    _showToast(
      context,
      message,
      icon: Icons.info,
    );
  }

  /// Shows a warning toast with orange background
  static void showWarning(BuildContext context, String message) {
    _showToast(
      context,
      message,
      backgroundColor: Colors.orange,
      icon: Icons.warning,
    );
  }

  /// Shows a persistent update available snackbar (does not auto-dismiss)
  static void showUpdateAvailable(
    BuildContext context, {
    required VoidCallback onUpdate,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.system_update, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Neue Version verfügbar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(days: 365), // Persistent - won't auto-dismiss
        action: SnackBarAction(
          label: 'Aktualisieren',
          textColor: Colors.white,
          onPressed: onUpdate,
        ),
      ),
    );
  }

  static void _showToast(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    IconData? icon,
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}
