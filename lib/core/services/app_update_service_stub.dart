import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for app update availability state
final appUpdateAvailableProvider = StateProvider<bool>((ref) => false);

/// Provider for AppUpdateService
final appUpdateServiceProvider = Provider<AppUpdateService>((ref) {
  return AppUpdateService(ref);
});

/// Stub implementation for non-web platforms
class AppUpdateService {
  AppUpdateService(Ref ref);

  void startListening() {}
  void applyUpdate() {}
  void markDialogShown() {}
  bool get wasDialogShown => false;
  void resetDialogShown() {}
  void dispose() {}
}
