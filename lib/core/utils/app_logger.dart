import 'package:flutter/foundation.dart';

class AppLogger {
  const AppLogger._();

  static void success(String event, [Map<String, Object?> details = const {}]) {
    _write('success', event, details);
  }

  static void error(
    String event,
    Object error, [
    Map<String, Object?> details = const {},
  ]) {
    _write('error', event, {...details, 'error': error});
  }

  static void info(String event, [Map<String, Object?> details = const {}]) {
    _write('info', event, details);
  }

  static void _write(String level, String event, Map<String, Object?> details) {
    if (!kDebugMode) {
      return;
    }
    final suffix = details.isEmpty
        ? ''
        : ' ${details.entries.map((entry) => '${entry.key}=${entry.value}').join(' ')}';
    debugPrint('[CirclePulse][$level] $event$suffix');
  }
}
