import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:riverpod/riverpod.dart';

import '../../../features/auth/application/auth_notifier.dart';
import '../../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../logging/app_logger.dart';
import '../../storage/secure_storage.dart';

typedef Reader = T Function<T>(ProviderListenable<T> provider);

class RefreshInterceptor extends Interceptor {
  RefreshInterceptor({
    required Dio dio,
    required this.tokenStorage,
    required Reader read,
    required Logger logger,
  })  : _dio = dio,
        _read = read,
        _logger = logger;

  final Dio _dio;
  final TokenStorage tokenStorage;
  final Reader _read;
  final Logger _logger;

  bool _isRefreshing = false;

  bool _isRefreshCall(RequestOptions request) {
    return request.path.contains('/auth/refresh');
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final refreshToken = (await tokenStorage.read())?.refreshToken;
    if (err.response?.statusCode == 401 &&
        !_isRefreshing &&
        !_isRefreshCall(err.requestOptions) &&
        refreshToken != null) {
      _isRefreshing = true;
      final authNotifier = _read(authNotifierProvider.notifier);
      try {
        final tokens = await _read(authRepositoryProvider).refresh(refreshToken);
        await authNotifier.updateTokens(tokens);
        final clonedRequest = await _retry(err.requestOptions, tokens.accessToken);
        return handler.resolve(clonedRequest);
      } catch (e) {
        _logger.w('Refresh token failed: ${redact(refreshToken)}');
        await authNotifier.forceLogout();
        return handler.reject(err);
      } finally {
        _isRefreshing = false;
      }
    }
    return super.onError(err, handler);
  }

  Future<Response<dynamic>> _retry(RequestOptions requestOptions, String accessToken) {
    final options = Options(
      method: requestOptions.method,
      headers: Map<String, dynamic>.from(requestOptions.headers)
        ..['Authorization'] = 'Bearer $accessToken',
    );
    return _dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }
}
