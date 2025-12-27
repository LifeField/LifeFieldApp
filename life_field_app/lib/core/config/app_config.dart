import 'package:flutter/foundation.dart';
import 'package:riverpod/riverpod.dart';

final appConfigProvider = Provider<AppConfig>(
  (_) => throw UnimplementedError('appConfigProvider must be overridden'),
);

@immutable
class AppConfig {
  const AppConfig({
    required this.baseUrl,
    required this.flavor,
    this.sentryDsn,
  });

  factory AppConfig.fromEnvironment() {
    const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
    return const AppConfig(
      baseUrl: String.fromEnvironment(
        'BASE_URL',
        //defaultValue: 'https://api.example.com',
        defaultValue: 'http://172.23.7.58:8080'
      ),
      flavor: flavor,
      sentryDsn: String.fromEnvironment('SENTRY_DSN', defaultValue: ''),
    );
  }

  final String baseUrl;
  final String flavor;
  final String? sentryDsn;

  bool get enableSentry => flavor == 'prod' && (sentryDsn?.isNotEmpty ?? false);
}
