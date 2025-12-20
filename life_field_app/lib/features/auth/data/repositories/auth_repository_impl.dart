import 'package:dio/dio.dart';
import 'package:riverpod/riverpod.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/error_mapper.dart';
import '../../domain/entities/auth_tokens.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: AuthRemoteDataSource(ref.watch(dioProvider)),
  );
});

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required this.remoteDataSource});

  final AuthRemoteDataSource remoteDataSource;

  @override
  Future<User> fetchProfile() => _guard(remoteDataSource.fetchProfile);

  @override
  Future<AuthTokens> login({required String email, required String password}) {
    return _guard(() => remoteDataSource.login(email: email, password: password));
  }

  @override
  Future<AuthTokens> refresh(String refreshToken) {
    return _guard(() => remoteDataSource.refresh(refreshToken));
  }

  @override
  Future<AuthTokens> register({required String email, required String password}) {
    return _guard(() => remoteDataSource.register(email: email, password: password));
  }

  @override
  Future<void> logout(String? refreshToken) => _guard(() => remoteDataSource.logout(refreshToken));

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on DioException catch (e) {
      throw mapDioError(e);
    } on AppError {
      rethrow;
    } catch (e) {
      throw AppError(type: AppErrorType.unknown, message: e.toString());
    }
  }
}
