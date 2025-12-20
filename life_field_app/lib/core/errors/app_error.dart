enum AppErrorType {
  network,
  unauthorized,
  forbidden,
  validation,
  unknown,
}

class AppError implements Exception {
  AppError({
    required this.type,
    required this.message,
    this.statusCode,
    this.details,
  });

  final AppErrorType type;
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? details;

  @override
  String toString() => 'AppError(type: $type, code: $statusCode, message: $message)';
}
