import 'package:dio/dio.dart';

import '../../domain/entities/auth_tokens.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/role.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._dio);

  final Dio _dio;

  Future<AuthTokens> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/v1/auth/login',
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
      '/v1/auth/register',
      data: {
        'email': email,
        'password': password,
      },
    );
    return _parseTokens(response.data);
  }

  Future<AuthTokens> refresh(String refreshToken) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/v1/auth/refresh',
      data: {'refreshToken': refreshToken},
      options: Options(headers: {'Authorization': 'Bearer $refreshToken'}),
    );
    return _parseTokens(response.data);
  }

  Future<User> fetchProfile() async {
    final response = await _dio.get<Map<String, dynamic>>('/v1/auth/me');
    final data = response.data ?? <String, dynamic>{};
    final roles = data['roles'] ?? data['Roles'] ?? [];
    final roleValue =
        roles is List && roles.isNotEmpty ? roles.first.toString() : (data['role']?.toString() ?? 'CLIENT');
    final email = (data['email'] ?? data['Email'] ?? data['user'] ?? '').toString();
    final userId = (data['user_id'] ?? data['UserID'] ?? data['id'] ?? '').toString();

    return User(
      id: userId.isNotEmpty ? userId : 'unknown',
      email: email,
      role: roleFromApi(roleValue),
    );
  }

  Future<void> logout(String? refreshToken) async {
    await _dio.post<Map<String, dynamic>>(
      '/v1/auth/logout',
      data: {'refreshToken': refreshToken},
    );
  }

  AuthTokens _parseTokens(Map<String, dynamic>? payload) {
    if (payload == null) {
      throw DioException(requestOptions: RequestOptions(path: '/auth'));
    }
    final rawTokens = payload['tokens'] ?? payload['data']?['tokens'] ?? payload['data'] ?? payload;

    if (rawTokens is Map<String, dynamic>) {
      final accessToken =
          rawTokens['accessToken'] ?? rawTokens['AccessToken'] ?? rawTokens['access_token'] ?? rawTokens['token'];
      final refreshToken =
          rawTokens['refreshToken'] ?? rawTokens['RefreshToken'] ?? rawTokens['refresh_token'] ?? rawTokens['refresh'];

      if (accessToken is String) {
        final refresh = refreshToken is String ? refreshToken : '';
        return AuthTokens(accessToken: accessToken, refreshToken: refresh);
      }
    }
    throw DioException(requestOptions: RequestOptions(path: '/auth'));
  }
}
