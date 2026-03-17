import 'dart:developer' as developer;

class AppLogger {
  static void info(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: 'APP_LOG',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
