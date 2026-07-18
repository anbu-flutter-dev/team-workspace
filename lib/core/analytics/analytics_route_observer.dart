import 'package:flutter/widgets.dart';
import 'package:team_workspace/core/analytics/analytics_service.dart';

/// Logs a screen_view event whenever go_router pushes/replaces a named
/// route. Routes without a `name` (there shouldn't be any) are skipped
/// rather than logged as null.
class AnalyticsRouteObserver extends NavigatorObserver {
  AnalyticsRouteObserver(this._analytics);

  final AnalyticsService _analytics;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _logScreenView(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _logScreenView(newRoute);
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  void _logScreenView(Route<dynamic>? route) {
    final name = route?.settings.name;
    if (name != null) _analytics.logScreenView(name);
  }
}
