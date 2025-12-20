import 'package:logger/logger.dart';
import 'package:riverpod/riverpod.dart';

final appLoggerProvider = Provider<Logger>((_) {
  return Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      lineLength: 120,
      noBoxingByDefault: true,
    ),
    filter: _SafeLogFilter(),
  );
});

String redact(String? value) => value == null || value.isEmpty ? 'null' : '***redacted***';

class _SafeLogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    // Avoid verbose logs in release by default; adjust as needed.
    return true;
  }
}
