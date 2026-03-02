import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/pwa_service.dart';

/// Key for storing PWA hint dismissed state
const _kPwaHintDismissedKey = 'pwa_hint_dismissed';

/// Provider for PWA service
final pwaServiceProvider = Provider<PwaService>((ref) {
  return PwaService();
});

/// Provider for whether to show PWA install hint
final showPwaInstallHintProvider = FutureProvider<bool>((ref) async {
  final pwaService = ref.watch(pwaServiceProvider);

  // Check if PWA install hint should be shown based on platform
  if (!pwaService.shouldShowInstallHint()) {
    return false;
  }

  // Check if user has dismissed the hint
  final prefs = await SharedPreferences.getInstance();
  final dismissed = prefs.getBool(_kPwaHintDismissedKey) ?? false;

  return !dismissed;
});

/// Provider for PWA platform detection
final pwaPlatformProvider = Provider<PwaPlatform>((ref) {
  final pwaService = ref.watch(pwaServiceProvider);
  return pwaService.getPlatform();
});

/// Notifier for dismissing PWA install hint
class PwaHintNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Dismiss the PWA install hint permanently
  Future<void> dismissHint() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPwaHintDismissedKey, true);
    ref.invalidate(showPwaInstallHintProvider);
  }
}

final pwaHintNotifierProvider =
    AsyncNotifierProvider<PwaHintNotifier, void>(PwaHintNotifier.new);
