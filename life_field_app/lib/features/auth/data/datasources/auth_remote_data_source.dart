import 'package:dio/dio.dart';

import '../../domain/entities/auth_tokens.dart';
import '../../domain/entities/user.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._dio);

  final Dio _dio;

  Future<AuthTokens> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );
    return _parseTokens(response.data);
  }

  Future<AuthTokens> register({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/register',
      data: {
        'email': email,
        'password': password,
      },
    );
    return _parseTokens(response.data);
  }

  Future<AuthTokens> refresh(String refreshToken) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
      options: Options(headers: {'Authorization': 'Bearer $refreshToken'}),
    );
    return _parseTokens(response.data);
  }

  Future<User> fetchProfile() async {
    final response = await _dio.get<Map<String, dynamic>>('/me');
    return User.fromJson(response.data ?? <String, dynamic>{});
  }

  Future<void> logout(String? refreshToken) async {
    await _dio.post<Map<String, dynamic>>(
      '/auth/logout',
      data: {'refreshToken': refreshToken},
    );
  }

  AuthTokens _parseTokens(Map<String, dynamic>? payload) {
    if (payload == null) {
      throw DioException(requestOptions: RequestOptions(path: '/auth'));
    }
    final data = payload['tokens'] ?? payload;
    if (data is Map<String, dynamic>) {
      return AuthTokens.fromJson(data);
    }
    throw DioException(requestOptions: RequestOptions(path: '/auth'));
  }
}
