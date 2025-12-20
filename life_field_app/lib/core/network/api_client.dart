import 'package:dio/dio.dart';
import 'package:riverpod/riverpod.dart';

import '../config/app_config.dart';
import '../logging/app_logger.dart';
import '../storage/secure_storage.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/refresh_interceptor.dart';

final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  final logger = ref.watch(appLoggerProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: config.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 25),
      contentType: 'application/json',
    ),
  );

  dio.interceptors.add(ref.read(authInterceptorProvider));
  dio.interceptors.add(ref.read(refreshInterceptorProvider(dio)));
  dio.interceptors.add(
    LogInterceptor(
      requestHeader: false,
      responseHeader: false,
      requestBody: false,
      responseBody: false,
      logPrint: logger.i,
    ),
  );

  return dio;
});

final authInterceptorProvider = Provider<AuthInterceptor>((ref) {
  return AuthInterceptor(ref.watch(tokenStorageProvider));
});

final refreshInterceptorProvider = Provider.family<RefreshInterceptor, Dio>((ref, dio) {
  return RefreshInterceptor(
    dio: dio,
    tokenStorage: ref.watch(tokenStorageProvider),
    read: ref.read,
    logger: ref.watch(appLoggerProvider),
  );
});
