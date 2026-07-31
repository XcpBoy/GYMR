# GYMR

A local-first workout tracker for hybrid athletes (calisthenics, bodybuilding, gymnastics,
streetlifting, armwrestling) who want to log training data with more rigor
than a generic fitness app allows, without sending anything to a server.
Built with Flutter + Riverpod + Drift/SQLite — everything lives in an
on-device SQLite database.

**Status:** beta, in daily use — v0.1.6, DB schema 29. This is an
actively-developed personal project (not a polished public release), but it's
used for real training logging day-to-day without major issues. Newer/less
exercised flows may still have rough edges.

**Platform:** Android is the primary, actively-used target. An iOS project
scaffold exists under `ios/` (icons, Info.plist permissions) but has not yet
been built or validated on a Mac.

## What it does

- **CRRNT.WO** — the main live workout-logging screen. Log sets (weight,
  reps, RPE, RIR, technique, failure phase) against a movement library,
  track PRs (including a custom Volume Points metric, not just 1RM), tag
  somatic feedback (anomaly/recovery), and organize sets into batches or
  supersets.
- **WO.BLCKS** — reusable workout templates ("Workout Blocks"): build a
  session structure once (exercises, target reps/load, order) and inject it
  into any day instead of rebuilding it from scratch.
- **KINISI INVENTORY** — the exercise library: create/edit movements with
  muscle group, movement pattern, discipline, and other classification
  metadata used throughout the rest of the app.
- **KNS.HISTORICAL_REPORT** — full logged history for a single exercise
  across every past session, with one-tap re-injection of a past set into
  today's workout.
- **ANTHROPOMETRIC DATA** — body weight and custom body measurements
  (arm, waist, etc.) over time, with duplicate-label normalization and a
  quick-pick selector for repeat labels.
- **SOMATIC_SPECTRUM** — a dedicated view for the anomaly/recovery feedback
  logged during training, organized by folder.
- **TIMELINE_CALENDAR / CHRONO_HISTORY** — calendar and chronological views
  over past training sessions.
- **FULL_DATASET_EXPLORER** — a raw browsable/paginated view over the
  underlying logged data (sets, bodyweight, measurements).
- **NEXUS_DATA_EXCHANGE** — export training data to PDF/CSV/Excel, or share
  it directly from the device.
- **THEME.MDFYR** — full UI theming: every color and wallpaper used across
  the app is DB-backed and user-editable from this screen, not hardcoded.

## Design language

"Technical Brutalism": dark theme only, sharp corners, monospace/geometric
fonts, hairline borders. See `lib/ui/styles.dart` (`LabColors` / `LabStyles`).

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
