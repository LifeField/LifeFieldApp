import 'package:flutter/material.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [
    Locale('en'),
    Locale('it'),
  ];

  static const _localizedValues = <String, Map<String, String>>{
    'en': {
      'app_title': 'LifeField',
      'login': 'Login',
      'email': 'Email',
      'password': 'Password',
      'client_home': 'Client Home',
      'pro_home': 'Pro Home',
      'admin_home': 'Admin Home',
      'logout': 'Logout',
    },
    'it': {
      'app_title': 'LifeField',
      'login': 'Accedi',
      'email': 'Email',
      'password': 'Password',
      'client_home': 'Home Cliente',
      'pro_home': 'Home Pro',
      'admin_home': 'Home Admin',
      'logout': 'Esci',
    },
  };

  String _text(String key) => _localizedValues[locale.languageCode]?[key] ?? _localizedValues['en']![key]!;

  String get appTitle => _text('app_title');
  String get login => _text('login');
  String get email => _text('email');
  String get password => _text('password');
  String get clientHome => _text('client_home');
  String get proHome => _text('pro_home');
  String get adminHome => _text('admin_home');
  String get logout => _text('logout');

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'it'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}
