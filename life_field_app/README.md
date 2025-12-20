# LifeField Mobile

Flutter app for the LifeField fitness/nutrition marketplace with role-based experiences.

## Flavors & env
- Flavors: `dev`, `staging`, `prod` with `--dart-define` (`BASE_URL`, `FLAVOR`, `SENTRY_DSN`).
- Android: productFlavors already configured; example run `flutter run --flavor dev --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://api.dev.example.com --dart-define=SENTRY_DSN=`.
- iOS: shared schemes `dev`, `staging`, `prod` mapped to matching build configurations (`Debug/Release/Profile-<flavor>`). Example run `flutter run --flavor dev --dart-define=FLAVOR=dev ...`.

## Tooling
- Codegen: `dart run build_runner build -d`.
- Quality gates: `flutter analyze` and `flutter test`.

## Notes
- Tokens live in secure storage; refresh handled via Dio interceptors.
- Sentry initializes only when `FLAVOR=prod` and `SENTRY_DSN` is provided.
