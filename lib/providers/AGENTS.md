## Purpose

Riverpod providers for GYMR state management.

## Ownership

- Scope: `lib/providers/` — 3 Dart files (theme_provider, database_provider, charts_provider).
- Owns all global and feature-specific Riverpod providers.
- Does NOT own mock providers used by WB Editor (those live inside the UI files themselves).

## Local Contracts

- **Database-dependent providers** use `StreamProvider` for reactive DB queries (auto-refresh on data change).
- **Mutable state** uses `StateNotifierProvider`.
- **Computed/derived state** uses `Provider`.
- **Providers are NEVER shared between C.WO and WB Editor.** They read from different data sources (real DB vs mock notifier). Both maintain their own `workoutSetsProvider` in separate files — this is correct.
- Mock data persistence uses Drift custom tables (raw SQLite via `customStatement`/`customSelect`), NOT SharedPreferences — SharedPreferences fails silently on Android hot restart.
- Providers never import UI widgets or screens.

## Work Guidance

- New providers follow the existing patterns in `theme_provider.dart`, `database_provider.dart`, `charts_provider.dart`.
- If a provider needs to load async data on construction, use `Future.microtask` in the consumer's `initState` — not in the provider constructor.
- Every mutation method on a `StateNotifier` that persists data must call `_save()` at the end.

## Verification

- Hot restart on device and verify the feature works (data loads, reactions fire, writes persist).

## Child DOX Index

- (no child AGENTS.md files under lib/providers/)
