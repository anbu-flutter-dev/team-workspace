/// Contract for event/screen tracking — components never call a specific
/// analytics SDK directly, same abstraction-layer rule as the rest of the
/// data layer (services wrap providers).
abstract interface class AnalyticsService {
  void logEvent(String name, {Map<String, Object?> parameters});

  void logScreenView(String screenName);
}
