import 'package:team_workspace/core/analytics/analytics_service.dart';
import 'package:team_workspace/core/utils/log.dart';

/// Logs events to the console instead of a real analytics SDK — no backend
/// analytics provider (Firebase Analytics, Mixpanel, ...) is wired into this
/// project. Swapping one in later means implementing [AnalyticsService]
/// again with that SDK; none of the call sites that log events change.
class ConsoleAnalyticsService implements AnalyticsService {
  @override
  void logEvent(String name, {Map<String, Object?> parameters = const {}}) {
    final paramsText = parameters.isEmpty ? '' : ' $parameters';
    logInfo('Analytics event: $name$paramsText');
  }

  @override
  void logScreenView(String screenName) {
    logInfo('Analytics screen_view: $screenName');
  }
}
