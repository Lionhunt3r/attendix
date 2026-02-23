import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web/web.dart' as web;

/// Provider for app update availability state
final appUpdateAvailableProvider = StateProvider<bool>((ref) => false);

/// Provider for AppUpdateService
final appUpdateServiceProvider = Provider<AppUpdateService>((ref) {
  final service = AppUpdateService(ref);
  ref.onDispose(() => service.dispose());
  return service;
});

/// Service to detect and handle app updates (web only)
///
/// This service listens for Service Worker update events from JavaScript
/// and notifies the app when a new version is available.
class AppUpdateService {
  final Ref _ref;
  bool _dialogShown = false;
  JSFunction? _eventListener;

  AppUpdateService(this._ref);

  /// Start listening for updates (call once on app start)
  void startListening() {
    if (!kIsWeb) return;

    // Check if update is already available (set by JavaScript before Dart loaded)
    if (_isUpdateAvailable()) {
      _ref.read(appUpdateAvailableProvider.notifier).state = true;
    }

    // Listen for update events from JavaScript
    _eventListener = _onUpdateAvailable.toJS;
    web.window.addEventListener('flutter-update-available', _eventListener);
  }

  void _onUpdateAvailable(web.Event event) {
    _ref.read(appUpdateAvailableProvider.notifier).state = true;
  }

  /// Check if update is available from JavaScript global
  bool _isUpdateAvailable() {
    return _getAppUpdateAvailable();
  }

  /// Reload the app to apply update
  void applyUpdate() {
    if (kIsWeb) {
      web.window.location.reload();
    }
  }

  /// Mark that dialog has been shown (to prevent showing multiple times)
  void markDialogShown() {
    _dialogShown = true;
  }

  /// Check if dialog was already shown
  bool get wasDialogShown => _dialogShown;

  /// Reset dialog shown state (e.g., when user clicks "Later")
  void resetDialogShown() {
    _dialogShown = false;
  }

  void dispose() {
    if (kIsWeb && _eventListener != null) {
      web.window.removeEventListener('flutter-update-available', _eventListener);
    }
  }
}

/// JS interop to get window.appUpdateAvailable
@JS('window.appUpdateAvailable')
external bool? get _jsAppUpdateAvailable;

bool _getAppUpdateAvailable() {
  try {
    return _jsAppUpdateAvailable ?? false;
  } catch (_) {
    return false;
  }
}
