import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Single Logger instance for the whole app. Verbose in debug builds;
/// release builds only print warnings and above, so a shipped app doesn't
/// spam the console with request/response dumps.
final Logger _logger = Logger(
  level: kReleaseMode ? Level.warning : Level.debug,
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 5,
    lineLength: 100,
    colors: true,
    printEmojis: false,
    dateTimeFormat: DateTimeFormat.none,
  ),
);

/// General-purpose entry point — picks warning level when an [error] is
/// attached (every current call site logs an already-recovered failure),
/// info otherwise. Reach for [logDebug]/[logWarning]/[logError] directly
/// when a call site needs an explicit level.
void log(String message, {Object? error, StackTrace? stackTrace}) {
  if (error != null) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  } else {
    _logger.i(message);
  }
}

void logDebug(String message) => _logger.d(message);

void logInfo(String message) => _logger.i(message);

void logWarning(String message, {Object? error, StackTrace? stackTrace}) =>
    _logger.w(message, error: error, stackTrace: stackTrace);

void logError(String message, {Object? error, StackTrace? stackTrace}) =>
    _logger.e(message, error: error, stackTrace: stackTrace);
