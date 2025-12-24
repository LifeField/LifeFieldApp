import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:life_field_app/app/localization/app_localizations.dart';
import 'package:life_field_app/features/auth/application/auth_notifier.dart';
import 'package:life_field_app/features/auth/domain/entities/auth_tokens.dart';
import 'package:life_field_app/features/auth/domain/entities/role.dart';
import 'package:life_field_app/features/auth/domain/entities/user.dart';
import 'package:life_field_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:life_field_app/features/auth/presentation/login/login_screen.dart';
import 'package:life_field_app/core/storage/secure_storage.dart';

void main() {
  testWidgets('renders login fields and triggers login', (tester) async {
    final fakeRepository = _FakeAuthRepository();
    final memoryStorage = _MemoryTokenStorage();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(
            (ref) => AuthNotifier(
              repository: fakeRepository,
              tokenStorage: memoryStorage,
            ),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: LoginScreen(),
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('login_email')), 'user@example.com');
    await tester.enterText(find.byKey(const Key('login_password')), 'supersecret');
    await tester.tap(find.byKey(const Key('login_button')));
    await tester.pump();

    expect(fakeRepository.loginCalls, hasLength(1));
    expect(fakeRepository.loginCalls.single.$1, 'user@example.com');
    expect(fakeRepository.loginCalls.single.$2, 'supersecret');
    expect(memoryStorage.lastSaved?.accessToken, 'token');
  });

  testWidgets('opens registration dialog and registers user', (tester) async {
    final fakeRepository = _FakeAuthRepository();
    final memoryStorage = _MemoryTokenStorage();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(
            (ref) => AuthNotifier(
              repository: fakeRepository,
              tokenStorage: memoryStorage,
            ),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: LoginScreen(),
        ),
      ),
    );

    await tester.tap(find.text('Non hai un account? Clicca qui e iscriviti'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('register_email')), 'new@example.com');
    await tester.enterText(find.byKey(const Key('register_password')), 'password123');
    await tester.enterText(find.byKey(const Key('register_confirm_password')), 'password123');
    await tester.tap(find.byKey(const Key('register_submit')));
    await tester.pumpAndSettle();

    expect(fakeRepository.registerCalls, hasLength(1));
    expect(fakeRepository.registerCalls.single.$1, 'new@example.com');
    expect(fakeRepository.registerCalls.single.$2, 'password123');
    expect(memoryStorage.lastSaved?.accessToken, 'token');
  });
}

class _FakeAuthRepository implements AuthRepository {
  final List<(String, String)> loginCalls = [];
  final List<(String, String)> registerCalls = [];

  @override
  Future<AuthTokens> login({required String email, required String password}) async {
    loginCalls.add((email, password));
    return const AuthTokens(accessToken: 'token', refreshToken: 'refresh');
  }

  @override
  Future<AuthTokens> refresh(String refreshToken) async {
    return const AuthTokens(accessToken: 'token', refreshToken: 'refresh');
  }

  @override
  Future<AuthTokens> register({required String email, required String password}) async {
    registerCalls.add((email, password));
    return const AuthTokens(accessToken: 'token', refreshToken: 'refresh');
  }

  @override
  Future<User> fetchProfile() async {
    return const User(id: '1', email: 'user@example.com', role: Role.client);
  }

  @override
  Future<void> logout(String? refreshToken) async {}
}

class _MemoryTokenStorage extends TokenStorage {
  _MemoryTokenStorage() : super(const FlutterSecureStorage());

  AuthTokens? lastSaved;

  @override
  Future<void> saveTokens(AuthTokens tokens) async {
    lastSaved = tokens;
  }

  @override
  Future<AuthTokens?> read() async {
    return lastSaved;
  }

  @override
  Future<void> clear() async {
    lastSaved = null;
  }
}
