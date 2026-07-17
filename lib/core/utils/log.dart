import 'dart:developer' as developer;

void log(
  String message, {
  String name = 'team_workspace',
  Object? error,
  StackTrace? stackTrace,
}) {
  developer.log(message, name: name, error: error, stackTrace: stackTrace);
}
