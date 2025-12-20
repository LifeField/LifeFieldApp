import '../entities/auth_tokens.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<AuthTokens> login({
    required String email,
    required String password,
  });

  Future<AuthTokens> register({
    required String email,
    required String password,
  });

  Future<AuthTokens> refresh(String refreshToken);

  Future<User> fetchProfile();

  Future<void> logout(String? refreshToken);
}
