import 'package:dio/dio.dart';

import '../errors/app_error.dart';

AppError mapDioError(DioException error) {
  final statusCode = error.response?.statusCode;
  final message = _extractMessage(error);

  switch (statusCode) {
    case 401:
      return AppError(type: AppErrorType.unauthorized, message: message, statusCode: statusCode);
    case 403:
      return AppError(type: AppErrorType.forbidden, message: message, statusCode: statusCode);
    case 400:
    case 422:
      return AppError(
        type: AppErrorType.validation,
        message: message,
        statusCode: statusCode,
        details: _asMap(error.response?.data),
      );
    default:
      break;
  }

  if (error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.receiveTimeout ||
      error.type == DioExceptionType.sendTimeout) {
    return AppError(type: AppErrorType.network, message: 'Network timeout');
  }

  return AppError(type: AppErrorType.unknown, message: message, statusCode: statusCode);
}

String _extractMessage(DioException error) {
  final data = error.response?.data;
  if (data is Map<String, dynamic> && data['message'] is String) {
    return data['message'] as String;
  }
  if (data is Map<String, dynamic> && data['error'] is String) {
    return data['error'] as String;
  }
  if (data is String && data.isNotEmpty) {
    return data;
  }
  if (error.response?.statusMessage != null && error.response!.statusMessage!.isNotEmpty) {
    return error.response!.statusMessage!;
  }
  if (error.message != null) {
    return error.message!;
  }
  return 'Unexpected error';
}

Map<String, dynamic>? _asMap(dynamic data) {
  if (data is Map<String, dynamic>) {
    return data;
  }
  return null;
}
