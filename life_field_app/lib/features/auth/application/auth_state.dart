import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/errors/app_error.dart';
import '../domain/entities/auth_tokens.dart';
import '../domain/entities/user.dart';

part 'auth_state.freezed.dart';

@freezed
class AuthState with _$AuthState {
  const factory AuthState({
    @Default(false) bool isLoading,
    @Default(false) bool initialized,
    User? user,
    AuthTokens? tokens,
    AppError? error,
  }) = _AuthState;

  const AuthState._();

  bool get isAuthenticated => user != null && tokens != null;
}
