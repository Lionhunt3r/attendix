import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:attendix/core/services/tracking/tracking_event.dart';
import 'package:attendix/core/services/tracking/tracking_service.dart';

/// `NavigatorObserver` that fires a `page_view` event on every route push or
/// replace. Routes whose names start with `/login` or `/legal` are skipped,
/// matching Ionic v4.0.5 (`app.component.ts:184-187`).
class TrackingObserver extends NavigatorObserver {
  TrackingObserver(this._container);

  final ProviderContainer _container;

  static const _skipPrefixes = ['/login', '/legal'];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _track(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) _track(newRoute);
  }

  void _track(Route<dynamic> route) {
    final name = route.settings.name;
    if (name == null) return;
    for (final prefix in _skipPrefixes) {
      if (name.startsWith(prefix)) return;
    }
    _container.read(trackingServiceProvider).track(
          TrackingEvent.pageView,
          properties: {'route': name},
        );
  }
}
