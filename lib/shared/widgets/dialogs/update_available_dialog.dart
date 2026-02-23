import 'package:flutter/material.dart';

/// Dialog shown when a new version of the app is available
class UpdateAvailableDialog extends StatelessWidget {
  final VoidCallback onUpdate;
  final VoidCallback onLater;

  const UpdateAvailableDialog({
    super.key,
    required this.onUpdate,
    required this.onLater,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(
        Icons.system_update,
        size: 48,
        color: Colors.blue,
      ),
      title: const Text('Update verfügbar'),
      content: const Text(
        'Eine neue Version der App ist verfügbar. '
        'Jetzt aktualisieren für die beste Erfahrung.',
      ),
      actions: [
        TextButton(
          onPressed: onLater,
          child: const Text('Später'),
        ),
        FilledButton(
          onPressed: onUpdate,
          child: const Text('Aktualisieren'),
        ),
      ],
    );
  }

  /// Show the update dialog
  static Future<void> show(
    BuildContext context, {
    required VoidCallback onUpdate,
    required VoidCallback onLater,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => UpdateAvailableDialog(
        onUpdate: onUpdate,
        onLater: onLater,
      ),
    );
  }
}
