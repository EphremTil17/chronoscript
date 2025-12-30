import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// Singleton service that captures and stores application logs.
class LogService {
  static final LogService _instance = LogService._internal();
  factory LogService() => _instance;
  LogService._internal();

  static const int _maxLogs = 1000;
  final ValueNotifier<List<LogRecord>> logsNotifier = ValueNotifier([]);

  /// Initializes the log listener. Should be called as early as possible.
  void init() {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      final currentLogs = List<LogRecord>.from(logsNotifier.value);
      currentLogs.add(record);

      if (currentLogs.length > _maxLogs) {
        currentLogs.removeAt(0);
      }

      logsNotifier.value = currentLogs;

      // Also print to debug console
      debugPrint('${record.level.name}: ${record.time}: ${record.message}');
    });
  }

  void clear() {
    logsNotifier.value = [];
  }
}
