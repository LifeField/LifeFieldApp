# Agent Rules

- Respect Clean Architecture, feature-first folders under `lib/` (`app/`, `core/`, `features/…`). Use Riverpod + go_router, Dio with auth/refresh interceptors, and secure storage for tokens.
- Flavors: dev/staging/prod. Pass env via `--dart-define` (`BASE_URL`, `FLAVOR`, `SENTRY_DSN`). Android uses productFlavors; iOS uses schemes/configs. Do not break flavor support.
- Privacy/GDPR: avoid logging PII or tokens (redact), use TLS-only URLs, store secrets in secure storage, and keep consents separate (TERMS, PRIVACY, HEALTH_DATA_PROCESSING, MARKETING).
- Roles: ADMIN, CLIENT, PT_COACH, NUTRIZIONISTA, DIETISTA, BIOLOGO, MEDICO. Mobile must route to role-specific homes (client/pro/admin) and load data respecting PERSONAL vs RELATIONSHIP separation.
- Avoid destructive git commands; keep logical commits and clean status. Edit files via `apply_patch`.
- After code changes, run `flutter analyze` and `flutter test` when tooling is available. If tooling is missing, note it explicitly to the user.
