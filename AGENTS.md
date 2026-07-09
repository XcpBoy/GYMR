\# DOX framework



\- DOX is highly performant AGENTS.md hierarchy installed here

\- Agent must follow DOX instructions across any edits

## Purpose

GYMR (BeyondPerformance) — Flutter workout tracker for hybrid athletes. Technical Brutalism design, Riverpod + Drift stack. Local-first SQLite persistence, mobile-first Android target (Redmi Note 8 Pro).

## Ownership

- Scope: entire GYMR project tree — Dart source, Flutter config, platform scaffolds, assets, build artifacts.
- This root AGENTS.md is the DOX rail: project-wide instructions, global preferences, durable workflow rules, and the top-level child index.
- Every meaningful edit requires reading the DOX chain from root to target, and a DOX pass on closeout.

\## Core Contract



\- AGENTS.md files are binding work contracts for their subtrees

\- Work products, source materials, instructions, records, assets, and durable docs must stay understandable from the nearest applicable AGENTS.md plus every parent AGENTS.md above it



\## Read Before Editing



1\. Read the root AGENTS.md

2\. Identify every file or folder you expect to touch

3\. Walk from the repository root to each target path

4\. Read every AGENTS.md found along each route

5\. If a parent AGENTS.md lists a child AGENTS.md whose scope contains the path, read that child and continue from there

6\. Use the nearest AGENTS.md as the local contract and parent docs for repo-wide rules

7\. If docs conflict, the closer doc controls local work details, but no child doc may weaken DOX



Do not rely on memory. Re-read the applicable DOX chain in the current session before editing.



\## Update After Editing



Every meaningful change requires a DOX pass before the task is done.



Update the closest owning AGENTS.md when a change affects:



\- purpose, scope, ownership, or responsibilities

\- durable structure, contracts, workflows, or operating rules

\- required inputs, outputs, permissions, constraints, side effects, or artifacts

\- user preferences about behavior, communication, process, organization, or quality

\- AGENTS.md creation, deletion, move, rename, or index contents



Update parent docs when parent-level structure, ownership, workflow, or child index changes. Update child docs when parent changes alter local rules. Remove stale or contradictory text immediately. Small edits that do not change behavior or contracts may leave docs unchanged, but the DOX pass still must happen.



\## Hierarchy



\- Root AGENTS.md is the DOX rail: project-wide instructions, global preferences, durable workflow rules, and the top-level Child DOX Index

\- Child AGENTS.md files own domain-specific instructions and their own Child DOX Index

\- Each parent explains what its direct children cover and what stays owned by the parent

\- The closer a doc is to the work, the more specific and practical it must be



\## Child Doc Shape



\- Create a child AGENTS.md when a folder becomes a durable boundary with its own purpose, rules, responsibilities, workflow, materials, or quality standards

\- Work Guidance must reflect the current standards of the project or user instructions; if there are no specific standards or instructions yet, leave it empty

\- Verification must reflect an existing check; if no verification framework exists yet, leave it empty and update it when one exists



Default section order:

\- Purpose

\- Ownership

\- Local Contracts

\- Work Guidance

\- Verification

\- Child DOX Index



\## Style



\- Keep docs concise, current, and operational

\- Document stable contracts, not diary entries

\- Put broad rules in parent docs and concrete details in child docs

\- Prefer direct bullets with explicit names

\- Do not duplicate rules across many files unless each scope needs a local version

\- Delete stale notes instead of explaining history

\- Trim obvious statements, repeated rules, misplaced detail, and warnings for risks that no longer exist



\## Closeout



1\. Re-check changed paths against the DOX chain

2\. Update nearest owning docs and any affected parents or children

3\. Refresh every affected Child DOX Index

4\. Remove stale or contradictory text

5\. Run existing verification when relevant

6\. Report any docs intentionally left unchanged and why



\## User Preferences



When the user requests a durable behavior change, record it here or in the relevant child AGENTS.md



## GYMR Operating Knowledge // Recorded 2026-06-13

This section captures durable GYMR knowledge discovered across prior sessions so future work does not need to relearn the same project rules.

### Project identity and environment

- Project: `GYMR / BeyondPerformance`, a local-first Flutter workout tracker for hybrid athletes.
- Stack: Flutter + Riverpod + Drift + SQLite.
- Primary target: Android, especially Redmi Note 8 Pro.
- Sessions run either from WSL or natively on Windows (PowerShell/Bash), depending on the environment — check which shell is actually active rather than assuming WSL. When on Windows, the Dart SDK executable used in past sessions has been:
  - `C:\Users\Ginna\develop\flutter_windows_3.41.5-stable\flutter\bin\cache\dart-sdk\bin\dart.exe`
  - The equivalent WSL path is `/mnt/c/Users/Ginna/develop/flutter_windows_3.41.5-stable/flutter/bin/cache/dart-sdk/bin/dart.exe`.
- A minimal automated test suite exists as of 2026-07-09: `flutter test` runs `test/wb_smoke_test.dart`, smoke tests for the Workout Blocks persistence path (create/rename/folder/delete, injection, export, WB Projections lookup) against an in-memory DB via `AppDatabase.forTesting()`. `test/widget_test.dart` is unmodified Flutter boilerplate and currently fails in this harness (pre-existing, unrelated gap). Verification for non-trivial changes should include `dart analyze` + `flutter test`, plus hot restart + visual inspection on device for UI-facing changes.
- Avoid excessive verification for simple mechanical tasks. Use direct execution and only minimal checks unless the task genuinely needs deeper validation.
- Archived/dead files that aren't part of the app build live in `MISC/` at the repo root (see `MISC/README.md`), not scattered through `lib/`. Standalone one-time scripts live in `tools/`, run manually via `dart run`. Both are excluded from `dart analyze` via `analysis_options.yaml`.

### DOX workflow

- Before editing, follow the DOX chain: root `AGENTS.md` → relevant child docs such as `lib/AGENTS.md` → subtree docs such as `lib/ui/AGENTS.md`.
- After meaningful edits, re-check the affected DOX chain and update docs if durable contracts, workflows, or project knowledge changed.
- Generated Drift code such as `database.g.dart` is not hand-edited.

### Persistence rules

- Data persistence is priority #1. Prefer real DB tables and durable flows over mocks.
- For WB editor fields, field values are written by `_onChanged()` → `db.update()`. `_save()` only syncs structure (`id`, `kns_id`, `set_number`, `side`).
- Providers should read field values from DB, not only from StateNotifier state.
- Avoid `INSERT OR REPLACE` on parent rows when children have `ON DELETE CASCADE`; it deletes the parent, cascades child deletion, and silently loses data. Use `INSERT OR IGNORE` + targeted `UPDATE` for structure.
- Use soft-delete/restoration patterns when deleted WBs still need to remain exportable or restorable.
- If a DB column may be missing in an existing DB, protect with `ALTER TABLE ... ADD COLUMN` in `beforeOpen`, import/export helpers, and editor ensure-table paths.

### NEXUS WB import/export and WB editor

- As of 2026-07-09, `workout_blocks` (+ `workout_block_kns` + `workout_block_sets`) is the **sole** source of truth for Workout Blocks. The legacy `wb_store` / `wb_kns_store` JSON-blob tables that used to shadow-write alongside the real tables have been retired: `database.dart`'s `_backfillFolderFromLegacyWbStore()` backfills anything that only existed in those blobs (including `folder`, which used to live only there) on startup, then drops both tables. Do not reintroduce a dual-write path — write/read `workout_blocks` directly.
- Soft-delete WBs with `workout_blocks.deleted_at`; do not permanently delete WBs if they must remain exportable/restorable.
- OVARCH.PLN active WB pickers (`OvarchPlanInjectionService.activeWorkoutBlocks`) read directly from `workout_blocks` filtered on `COALESCE(deleted_at, 0) = 0` — no legacy merge/reconciliation needed anymore.
- `plan_day_blocks` can exist in older local DBs with legacy alias columns. `beforeOpen` must add `day_id` / `plan_day_id` / `block_id` / `workout_block_id` safety columns and backfill from aliases such as `plan_day_id` / `workout_block_id` before any Drift DAO query. Direct inserts into `plan_day_blocks` must populate both `day_id` + legacy `plan_day_id` and both `block_id` + legacy `workout_block_id` until the schema is fully normalized.
- NEXUS WB set IDs must be independent of `set_number`. Exported XLSX can contain duplicate `set_number` values in the same KNS, so deriving IDs from `kns_id + set_number` causes unique constraint failures.
- Unilateral exercises can have two side rows. Export/import should preserve side rows and map `RIGHT` / `LEFT` correctly.
- Injected WB sets track source block ID via `complex_metadata['injectedFromBlock']` so WB Projections can filter to WBs actually injected today. WB Projections' "today" lookup must resolve log ids via Drift's typed `DateTime` comparison (`t.date.isBetweenValues(...)`), never a raw `millisecondsSinceEpoch` literal compared against a `DateTimeColumn` — Drift stores those as unix **seconds**, so a raw-millisecond comparison silently never matches (this broke WB Projections once already).
- Protect `workout_blocks` with `intention`, `description`, and `folder` columns when needed, via the `_addColumnIfMissing` helper in `database.dart` rather than a bare `try { ALTER TABLE ... } catch (_) {}`.
- Widgets shared between `workout_manager.dart` (live logging) and `WB.editor.dart` (block template editor) live in `lib/ui/wb_shared/`. Both files were originally a copy-paste fork; the identical/near-identical pieces (search pickers, set instance widgets, session timer, general notes, quick action button, unilateral pair frame, opts slice) were extracted there in 2026-07. The remaining large pieces that still differ per-screen on purpose (`_WorkoutDayPage`, `_ExerciseModule`, `_WorkoutSetInstance`, `_WorkoutOptsSheet`) were deliberately left separate — they encode real per-screen behavior differences (live PR/VP tracking vs. set tags, a smaller opts sheet in the block editor), not accidental duplication. Don't force these together without checking whether the divergence is a bug or intentional first.
- Build runner:
  - `dart run build_runner build --delete-conflicting-outputs`

### WB editor modal pitfalls

- Do not call async methods from a StateNotifier constructor.
- `didUpdateWidget` can overwrite TextField controllers on provider rebuilds.
- Do not increment `knsVersionProvider` from `_onChanged()`; it can create an infinite loop that destroys user input.
- Do not use parent `context` after `Navigator.pop()` to show another dialog. Use `Future.microtask(() { if (context.mounted) ... })`.
- Avoid `StatefulBuilder` for complex WB inject modals if it causes `_dependents.isEmpty` crashes; use a standalone `StatefulWidget` dialog class when needed.

### Theme / UI conventions

- UI labels are English only.
- Colors must come from `themeControllerProvider.getColor()` except allowed exceptions: `LabColors.primary` for primary accents and `Colors.grey[800]` for structural borders.
- No raw JSON editors in metadata forms; use structured form fields.
- `LabButton.onPressed` must not be null; use `() {}` for no-op.
- Mobile-first touch UI; avoid precision-dependent drag/drop, keyboard shortcuts, and hover states.
- THEME.MDFYR/MDYFR is the main theme surface. Dashboard card keys are configured there.
- As of 2026-06-13:
  - `WO.BLKCS` and `WO.BLKCS_BG` were added to THEME.MDFYR dashboard items.
  - `SESSION.BP` and `SESSION.BP_BG` were removed.
  - `Session Blueprint` was removed from the WB editor injection type modal.
  - Dashboard/home module cards for `WO.BLCKS` read `DASHBOARD_CARD_WO.BLKCS` and `DASHBOARD_CARD_WO.BLKCS_BG`, with legacy aliases for `SESSION.BP` / `SESSION.BP_BG` and `WO.BLCKS` / `WO.BLCKS_BG`.
  - C.WO injection type buttons are theme-wired through `INJECTION_INDIVIDUAL_MOVEMENT`, `INJECTION_WORKOUT_BLOCK`, `INJECTION_PLAN_DAY`, and `INJECTION_COPY_FROM_SPECIFIC_DAY`; `COPY_FROM_SPECIFIC_DAY` defaults to `LabColors.secondary` rather than green/orange/cyan.

### Somatic logs

- Somatic logs live in `somatic_logs`.
- Negative `spectrum_value` = anomaly/discomfort.
- Positive `spectrum_value` = recovery.
- Tags are stored as comma-separated text in `somatic_logs.tags`.
- Optional folder association uses `somatic_folders` + `somatic_folder_logs`.
- As of 2026-06-13, explicit text sizes in the SOMATIC_LOGS card/overlay/reference flow were increased by 20%.
- Relevant file: `lib/ui/workout_manager.dart`.

### Release ZIP packaging

- GYMR release/source ZIPs must be created under:
  - `<GYMR project directory>/.zip safety vault/GYMR_vX.Y.Z.zip`
- Do not create release ZIPs in the current build root `dist/` unless explicitly requested.
- Include source/config/platform/assets plus existing project guidance files.
- Exclude generated/local-only artifacts:
  - `.dart_tool/`
  - `build/`
  - `.flutter-plugins-dependencies`
  - sample `gymr_wbs*.xlsx`
  - `GYMRpndev.txt`
  - destination `.zip safety vault/`
  - compiled artifacts such as `.apk`, `.aab`, `.ipa`, `.xcarchive`
- Verify ZIP existence, non-zero plausible file count, `testzip()` integrity, and required entries such as `pubspec.yaml`, `pubspec.lock`, `lib/main.dart`, `android/app/build.gradle.kts`, `assets/db.sqlite`, `AGENTS.md`, and `VERSION.md`.

### User workflow preferences for this project

- User prefers action over discussion once direction is clear.
- User values detailed debug logging and hates silent failures.
- User prefers copy-paste-then-modify workflows for UI changes.
- User prefers compact UI and structured forms, not JSON editors.
- User wants data persistence done properly once, with real DB behavior.
- C.WO batch sections stay anchored at their first visible position. If a KNS assigned to an existing batch appears later in `orderIndex`, render it under the existing batch header instead of creating a duplicate bottom header.
- Assigning a C.WO KNS to a batch should expand the target batch so the assigned KNS does not appear to disappear inside a collapsed batch.



\## Child DOX Index



- `lib/AGENTS.md` — All application source code (ui, providers, logic, database, services)
  - `lib/ui/AGENTS.md` — UI layer (screens, widgets, scaffold, styles)
  - `lib/providers/AGENTS.md` — Riverpod providers (state management)
  - `lib/logic/AGENTS.md` — Business logic (calculators, chart models, progression)
  - `lib/database/AGENTS.md` — Drift database schema, migrations, generated code
  - `lib/services/AGENTS.md` — Export/import and service layer

