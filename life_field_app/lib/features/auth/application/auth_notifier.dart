import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/storage/secure_storage.dart';
import '../domain/entities/auth_tokens.dart';
import '../domain/repositories/auth_repository.dart';
import '../data/repositories/auth_repository_impl.dart';
import 'auth_state.dart';

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    repository: ref.watch(authRepositoryProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  )..bootstrap();
});

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier({
    required this.repository,
    required this.tokenStorage,
  }) : super(const AuthState());

  final AuthRepository repository;
  final TokenStorage tokenStorage;

  Future<void> bootstrap() async {
    if (state.initialized) return;
    final stored = await tokenStorage.read();
    if (stored == null) {
      state = state.copyWith(initialized: true);
      return;
    }
    state = state.copyWith(isLoading: true, tokens: stored, error: null);
    try {
      final user = await repository.fetchProfile();
      state = state.copyWith(
        user: user,
        tokens: stored,
        isLoading: false,
        initialized: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        initialized: true,
        error: _mapError(error),
        tokens: null,
        user: null,
      );
      await tokenStorage.clear();
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final tokens = await repository.login(email: email, password: password);
      await _persistSession(tokens);
      final user = await repository.fetchProfile();
      state = state.copyWith(
        isLoading: false,
        user: user,
        tokens: tokens,
        initialized: true,
        error: null,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, error: _mapError(error));
      await tokenStorage.clear();
    }
  }

  Future<void> register({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final tokens = await repository.register(email: email, password: password);
      await _persistSession(tokens);
      final user = await repository.fetchProfile();
      state = state.copyWith(
        isLoading: false,
        user: user,
        tokens: tokens,
        initialized: true,
        error: null,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, error: _mapError(error));
      await tokenStorage.clear();
    }
  }

  Future<void> logout() async {
    try {
      await repository.logout(state.tokens?.refreshToken);
    } catch (_) {
      debugPrint('Logout failed, continuing to clear session');
    } finally {
      await tokenStorage.clear();
      state = state.copyWith(
        user: null,
        tokens: null,
        isLoading: false,
        error: null,
        initialized: true,
      );
    }
  }

  Future<void> forceLogout() async {
    await tokenStorage.clear();
    state = state.copyWith(
      user: null,
      tokens: null,
      isLoading: false,
      error: null,
    );
  }

  Future<void> updateTokens(AuthTokens tokens) async {
    await tokenStorage.saveTokens(tokens);
    state = state.copyWith(tokens: tokens);
  }

  AppError? _mapError(Object error) {
    if (error is AppError) {
      return error;
    }
    return AppError(type: AppErrorType.unknown, message: error.toString());
  }

  Future<void> _persistSession(AuthTokens tokens) async {
    await tokenStorage.saveTokens(tokens);
  }
}
