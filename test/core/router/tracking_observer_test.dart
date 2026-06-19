import 'package:attendix/core/router/tracking_observer.dart';
import 'package:attendix/core/services/tracking/tracking_event.dart';
import 'package:attendix/core/services/tracking/tracking_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockTrackingService extends Mock implements TrackingService {}

void main() {
  setUpAll(() {
    registerFallbackValue(TrackingEvent.pageView);
  });

  group('TrackingObserver', () {
    late _MockTrackingService tracking;
    late TrackingObserver observer;

    setUp(() {
      tracking = _MockTrackingService();
      final container = ProviderContainer(
        overrides: [
          trackingServiceProvider.overrideWithValue(tracking),
        ],
      );
      addTearDown(container.dispose);
      observer = TrackingObserver(container);
    });

    PageRoute<void> route(String? name) {
      return PageRouteBuilder<void>(
        settings: RouteSettings(name: name),
        pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      );
    }

    test('fires page_view on didPush with the route name', () {
      observer.didPush(route('/people'), null);

      verify(() => tracking.track(
            TrackingEvent.pageView,
            properties: {'route': '/people'},
          )).called(1);
    });

    test('fires page_view on didReplace with the new route name', () {
      observer.didReplace(
        newRoute: route('/attendance/42'),
        oldRoute: route('/attendance'),
      );

      verify(() => tracking.track(
            TrackingEvent.pageView,
            properties: {'route': '/attendance/42'},
          )).called(1);
    });

    test('skips routes starting with /login', () {
      observer.didPush(route('/login'), null);
      verifyNever(() => tracking.track(any(), properties: any(named: 'properties')));
    });

    test('skips routes starting with /legal', () {
      observer.didPush(route('/legal'), null);
      observer.didPush(route('/legal/datenschutz'), null);
      verifyNever(() => tracking.track(any(), properties: any(named: 'properties')));
    });

    test('does not fire when route name is null', () {
      observer.didPush(route(null), null);
      verifyNever(() => tracking.track(any(), properties: any(named: 'properties')));
    });
  });
}
