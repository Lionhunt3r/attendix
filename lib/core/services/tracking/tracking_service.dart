import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/tenant_providers.dart';
import '../../../data/models/usage_event.dart';
import '../../../data/repositories/usage_events_repository.dart';
import 'tracking_event.dart';

/// Resolves the current device platform once per process.
///
/// Override in tests with `trackingDeviceTypeProvider.overrideWithValue('web')`
/// so suites are deterministic on any host.
final trackingDeviceTypeProvider = Provider<String>((ref) {
  if (kIsWeb) return 'web';
  if (Platform.isIOS) return 'ios';
  if (Platform.isAndroid) return 'android';
  return 'web';
});

/// Cross-cutting analytics service. Fire-and-forget — never throws.
///
/// Mirrors Ionic's `TrackingService` (`tracking.service.ts:49-90`):
/// inserts a row into `usage_events` for every `track()` call, derives
/// `tenant_id` lazily so a service-construction-before-login sequence still
/// works, and swallows all errors because tracking must not disrupt UX.
class TrackingService {
  TrackingService(this._ref);

  final Ref _ref;

  void track(
    TrackingEvent event, {
    Map<String, dynamic> properties = const {},
  }) {
    unawaited(_fire(event, properties));
  }

  Future<void> _fire(
    TrackingEvent event,
    Map<String, dynamic> properties,
  ) async {
    try {
      final tenant = _ref.read(currentTenantProvider);
      final repo = _ref.read(usageEventsRepositoryProvider);
      await repo.insert(UsageEvent(
        eventName: event.wireName,
        tenantId: tenant?.id,
        deviceType: _ref.read(trackingDeviceTypeProvider),
        properties: properties,
      ));
    } catch (_) {
      // Swallow — tracking must never disrupt UX.
    }
  }
}

final trackingServiceProvider = Provider<TrackingService>(
  TrackingService.new,
);
