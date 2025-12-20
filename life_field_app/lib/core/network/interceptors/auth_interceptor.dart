import 'package:dio/dio.dart';

import '../../storage/secure_storage.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokenStorage);

  final TokenStorage _tokenStorage;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final tokens = await _tokenStorage.read();
    final existingAuth = options.headers['Authorization']?.toString() ?? '';
    if (tokens != null && !existingAuth.startsWith('Bearer')) {
      options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
    }
    super.onRequest(options, handler);
  }
}
