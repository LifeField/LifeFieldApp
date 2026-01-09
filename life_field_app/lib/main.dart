import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dart:convert';

import 'package:go_router/go_router.dart';

import 'app/app.dart';
import 'app/router/route_paths.dart';
import 'core/navigation/app_navigator.dart';
import 'core/notifications/notification_service.dart';
import 'core/config/app_config.dart';
import 'core/logging/sentry_initializer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.initialize();
  NotificationService.instance.setOnNotificationResponse((response) async {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map) return;
      final workoutId = int.tryParse('${decoded['workoutId'] ?? ''}');
      if (workoutId == null) return;
      final workoutName = (decoded['workoutName'] ?? 'Allenamento').toString();
      final context = appNavigatorKey.currentContext;
      if (context == null) return;
      final router = GoRouter.of(context);
      router.goNamed(
        RoutePaths.workoutExecutionName,
        pathParameters: {'workoutId': '$workoutId'},
        extra: workoutName,
      );
    } catch (_) {
      // ignore invalid payload
    }
  });
  final config = AppConfig.fromEnvironment();
  await initSentry(
    config: config,
    appRunner: () => runApp(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(config),
        ],
        child: const App(),
      ),
    ),
  );
}
