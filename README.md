# GYMR

A high-performance, local-first workout tracker for hybrid athletes. Flutter +
Riverpod + Drift/SQLite, all data stored on-device. Primary target: Android
(tested on a Redmi Note 8 Pro). iOS scaffold is present under `ios/` but has
not yet been built/validated on a Mac.

**Status:** unstable — v0.1.6, DB schema 29. Not fully validated end-to-end
on device; some flows may still need manual testing.

## Project layout

```
lib/
  ui/            screens, widgets, scaffold, styles
    wb_shared/   widgets shared between the live-logging and WB-template
                 editor screens (kept in sync deliberately)
  providers/     Riverpod providers (state management)
  logic/         business logic (calculators, chart models, progression)
  database/      Drift schema, migrations, generated code
  services/      export/import and other service-layer code
test/            automated tests (flutter test)
tools/           standalone one-time scripts, run manually via `dart run`
                 (not part of the app build)
```

## Running it

```
flutter pub get
flutter run
```

Rebuilding Drift's generated code after a schema change:

```
dart run build_runner build --delete-conflicting-outputs
```

## Testing

```
flutter test
```

`test/wb_smoke_test.dart` covers the Workout Blocks persistence path (create/
rename/folder/delete, injection, export, and the WB Projections lookup)
against an in-memory database. `test/widget_test.dart` is the default Flutter
boilerplate and currently fails in this harness (unrelated pre-existing gap,
not covered by CI).

## Related

- **GYMR LITE** — a minimal standalone web version (session + measurement
  logging, CSV/JSON export, no backend) built for an applied-statistics class
  project. Lives in its own public repo:
  [XcpBoy/gymr-lite](https://github.com/XcpBoy/gymr-lite), deployed at
  https://xcpboy.github.io/gymr-lite/.
