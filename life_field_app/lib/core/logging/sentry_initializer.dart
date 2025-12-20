import 'dart:async';

import 'package:sentry_flutter/sentry_flutter.dart';

import '../config/app_config.dart';

Future<void> initSentry({
  required AppConfig config,
  required FutureOr<void> Function() appRunner,
}) async {
  if (config.enableSentry && (config.sentryDsn?.isNotEmpty ?? false)) {
    await SentryFlutter.init(
      (options) {
        options.dsn = config.sentryDsn;
        options.environment = config.flavor;
        options.tracesSampleRate = 0.2;
      },
      appRunner: appRunner,
    );
    return;
  }

  await appRunner();
}
