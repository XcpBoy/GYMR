---
name: gymr
description: "GYMR (BeyondPerformance) — Flutter workout tracker for hybrid athletes. Technical Brutalism design, Riverpod + Drift stack."
tags: [flutter, riverpod, drift, sqlite, gymr, calisthenics, workout-tracker]
platforms: [linux, macos, windows]
---

# GYMR // BEYOND_PERFORMANCE // PROJECT_CONTEXT

## DOX CHAIN // GYMR PROJECT CONTEXT

GYMR uses an in-repo DOX hierarchy through `AGENTS.md` files. Before meaningful edits in the current build, read the root `AGENTS.md`, then the relevant child docs under `lib/AGENTS.md` and the nearest subtree doc such as `lib/ui/AGENTS.md`.

The current repo root `AGENTS.md` also contains durable GYMR operating knowledge recorded on 2026-06-13, including WB persistence rules, NEXUS WB import/export rules, THEME.MDFYR changes, SOMATIC_LOGS font-size changes, release ZIP packaging rules, and user workflow preferences. Treat that section as active project context when working in this repo.

See `references/dox-hierarchy.md` for the general DOX framework.

## 4.5 PNDEV Tracker Status

- `01` — `WO.BLCKS / workout blocks` overhaul, previously `WORKOUT DAYS`, is marked finished (moved to history as #99).
- `02` — `OVARCH.PLN` overhaul is marked finished (moved to history as #100).
- `03`, `14`, and `26` were removed from the active PNDEV list:
  - `03` Session Blueprint Filtering
  - `14` Nexus Timeline Export
  - `26` Batch headers in `.md` and `.xlsx` exports + download fix
- `05` (Physique Tracking), `06` (Custom Icon Set), and `17` (Granular Supersets) were moved to backburner.
- `09` — **Volume Points (VP) System**: Formula `VP = tonnage × (1 + m × ln(i+1))` implemented and live. VP displayed in C.WO set expanded row, VP PR (V!) detected and shown in PR box, VP MULTIPLIER field in exercise editor, Performance Overview card live. 10s debounce, value caching, merged VP PR loop. See `references/volume-points-system.md`.
- `13` (KNS Order Standardization), and `15` (Blueprint Expected Input) were removed.
- `29` — WB Editor Set Values Persistence on Add Set: prevent registered set values from being lost when adding a new set inside a KNS card.
- `30` — WB Editor UI & Element Distribution: move "Delete All Sets" to a more discreet position, reposition KNS purpose text field, general layout improvements.
- `31` — WB PROJECTIONS Fix: correct WB projections so they properly reflect goals and progress.
- `32` — WB Editor Apply to All: "Apply Batch to All" and "Apply Util to All" options for bulk assignment across all sets in a KNS card.
- `33` — Banded as Load Nature: add "BAND" as a load nature below "EXT LOAD" with its own inputs and tonnage calculation logic.
- `34` — Assistance Support: add assisted/assistance tracking to exercise sets with toggle and numeric input.
- `35` — WB Editor Real-Time KNS Card Sync: KNS cards update in real time as changes are made without manual reload.
- `36` — WB Editor Auto-Save: every field change auto-persists to DB without requiring a save button press.
- `37` — WB Editor Specific Set Deleter with Complex Set Mods: per-set delete button that correctly handles cleanup of all associated complex set mods.
- `38` — WB Editor Apply RIR/RPE/MIN-MAX to KNS Card Complex Mods: apply RIR, RPE, MIN REPS/SECS, MAX REPS/SECS directly from the KNS card complex mods panel without editing each set individually.

## 5. SIMPLE TASK EXECUTION DISCIPLINE

For straightforward mechanical tasks, avoid over-planning and over-verification. Do not create a todo list, run broad searches, or add heavy checks unless the task genuinely has multiple dependent steps or real risk. Prefer the shortest reliable path: inspect only the relevant file/section, apply the targeted change, then run a minimal verification such as a focused analyzer call or a direct integrity probe.

When the user is actively reporting a runtime UI/layout crash after a change, stop planning and fix the concrete crash path. Analyzer/format checks are not a substitute for the user's device report.

Do not run `git status` automatically at the start of a session or before every task. The user rarely uses Git for day-to-day backups; the main backup workflow is release-style `.zip` snapshots in the GYMR `.zip safety vault`.

This is especially important for release packaging and small UI edits. The user has explicitly corrected excessive verification when a task is simple.

### Canonical build path and duplicate-folder recovery

The canonical GYMR current build path on this host is:

```text
/mnt/c/Users/Ginna/Desktop/Juan Jose Marroquin/Code/GYMR PROYECT DIRECTORY/GYMR CURRENT BUILD
```

Do not treat this sibling path as the active repo unless the user confirms it:

```text
/mnt/c/Users/Ginna/Desktop/Juan Jose Marroquin/Code/Agents/GYMR PROYECT DIRECTORY/GYMR CURRENT BUILD
```

The `Code\Agents\...` folder can be stale or empty and may contain only generated artifacts such as `build/`. When the user says files or `.zip` snapshots disappeared, first confirm the canonical path and look for repo markers (`.git`, `pubspec.yaml`, `lib/`, `android/`, `assets/`, `AGENTS.md`, `VERSION.md`). If the canonical repo is present, do not restore from Git; explain that the active build is in the canonical path and the `Agents` folder is likely a duplicate/stale folder.

Recovery order for apparent disappearance:

1. Confirm the active/canonical path.
2. Check the GYMR `.zip safety vault`.
3. Check Git history in the canonical repo.
4. Ask before copying, moving, deleting, or symlinking between duplicate folders.

Do not run `git status` automatically just because files appear missing. Git is a fallback after path and ZIP-vault checks. See `references/build-path-recovery.md`.

### Visual templates need a functional download/share button

When the user asks for a template (especially in NEXUS EXPECTED INPUTS), do NOT stop at rendering formatted text in the UI. Add a **DOWNLOAD** or **SHARE** button that generates a real downloadable file (`.xlsx` via the `excel` package, `.csv` via `_encodeCsv`). The visual reference text is supplementary — the download button is the deliverable.

**CRITICAL: XLSX must be a single flat sheet**, matching the gymr_wbs.xlsx format — 20 columns, one row per set, sheet named `WO.BLOCKS`. Do NOT split into multiple sheets (WORKOUT_BLOCK / WORKOUT_BLOCK_KNS / WORKOUT_BLOCK_SETS). The user will reject multi-sheet formats. See `references/nexus-expected-inputs-wb-template.md` for the exact column layout and generation pattern.

Pattern:
1. Add the static method in `ExportService.dart` (e.g. `generateEmptyWbTemplate()`) that creates the file
2. Wire a `LabButton(label: "DOWNLOAD_..._XLSX", onPressed: _method, ...)` in the nexus_screen
3. In `_method`, call `ExportService.method()`, then `Share.shareXFiles([XFile(filePath)], text: '...')`
4. Show a snackbar on success/failure

### PNDEV is NOT a substitute for implementation

When the user says "hazlo" about a code change (remove a button, fix a bug, add a feature), **implement the code change directly**. Do not first add it to `GYMRpndev.txt` as a PNDEV item. PNDEV is for backlog/planning of future work, not a waypoint between instruction and action. The sequence is:

```
User instruction → inspect → edit code → verify compile → done
```

Not:

```text
User instruction → add to PNDEV → ✗ stop
```

If you find yourself writing a PNDEV entry while the user is actively asking you to do something, you are planning instead of doing. Stop and make the code change.

### WO.BLCKS rename + WB/C.WO copy-day injection fixes

When adding or fixing WB rename, WB editor copy-day, or C.WO copy-day flows, trace the provider path first:

- `lib/ui/WO.Blocks.manager.dart` owns `workoutBlockListProvider` and WB cards.
- `lib/ui/WB.editor.dart` owns `wbEditorProvider` and `knsVersionProvider`.
- `lib/ui/workout_manager.dart` owns C.WO injection UI.
- `lib/services/export_service.dart` owns export file generation and share behavior.

For WO.BLCKS rename, add the edit action on each WB card and save through the notifier. Preserve existing fields (`folder`, `createdAt`) and uppercase the saved WB name if that matches the current naming convention.

For WB editor `COPY FROM SPECIFIC DAY`, do not only show `SESSION_CLONED_SUCCESSFULLY`; the copied KNS must be appended to `wbEditorProvider` state, `_save()` must persist it, and `knsVersionProvider` must be incremented so provider consumers reload. If the user says the success message appears but nothing shows in the editor, inspect whether the notifier path writes the copied `WbEditorKns`/`WbEditorSet` data and whether the version counter is bumped.

For C.WO `COPY FROM SPECIFIC DAY`, avoid popping the C.WO screen after date selection or after success. The user should remain on the active day so the injected sets are visible.

For markdown exports/download flows, separate “write file” from “share file”: download callers should pass `share: false` and route through the save-file picker, while explicit share callers should pass `share: true`.

See `references/wo-blocks-rename-wb-editor-copy-day.md` for the exact files, verification command, and future-session checklist.

## 6. CRITICAL LEARNINGS // WB EDITOR PERSISTENCE

### Two-Tier Persistence Architecture

The WB Editor uses a **dual-path** model that was hardened across many iterations. Never deviate from it:

```
User keystroke → _onChanged()
  ├── notifier.updateSet()  → StateNotifier (UI reactivity, values often stale)
  └── db.update(workoutBlockSets) → SQLite (THE source of truth for field values)

_reload() / navigate back → _load()
  └── Reads workout_block_kns + workout_block_sets from SQLite
      → Provider builds TypedResult from DB (for field values)
```

**Key rule:** Field values (`pload`, `repsMin`, `repsMax`, `rpe`, `rir`, `setIntention`) are written SOLELY by `_onChanged()` → `db.update()`. `_save()` NEVER writes field values — only structure (`id`, `kns_id`, `set_number`, `side`).

### `INSERT OR REPLACE` + `ON DELETE CASCADE` = Silent Data Loss

When a parent table has `ON DELETE CASCADE` on its children, `INSERT OR REPLACE` on the parent **deletes the old row** (triggering cascade) then inserts a new one. Any field values the child rows had are lost.

**WRONG:**
```dart
INSERT OR REPLACE INTO workout_block_kns (...)  // DELETES → CASCADE wipes sets
INSERT OR IGNORE INTO workout_block_sets (...)   // creates NEW rows with NULL values
```

**CORRECT:**
```dart
INSERT OR IGNORE INTO workout_block_kns (id, block_id, base_exercise_id, order_index) VALUES (...)
UPDATE workout_block_kns SET utilities = ?, batch_name = ? WHERE id = ?
INSERT OR IGNORE INTO workout_block_sets (id, kns_id, set_number, side) VALUES (...)
```

### `didUpdateWidget` Overwrites TextField Controllers

`_WorkoutSetInstanceState.didUpdateWidget` runs on EVERY provider rebuild and overwrites all TextField controllers. **Do NOT increment `knsVersionProvider` from `_onChanged()`** — this creates an infinite loop that destroys user input.

### Provider Must Read From DB, Not StateNotifier

The `workoutSetsProvider` must read directly from `workout_block_kns` + `workout_block_sets` tables, NOT from the StateNotifier. Use `Stream.fromFuture(Future(() async { ... }))` with `ref.watch(knsVersionProvider)` for reactivity.

Inject `knsId` into `complexMetadata['knsId']` in the provider so child widgets can extract it without touching the buggy StateNotifier:
```dart
final int knsId = () {
  try { final cm = jsonDecode(s.complexMetadata ?? '{}'); return (cm['knsId'] as num?)?.toInt() ?? 0; } catch (_) { return 0; }
}();
```

### NEXUS WB XLSX import/export — real tables only (updated 2026-07-09)

**Superseded:** this used to describe a dual-write with legacy `wb_store`/`wb_kns_store` JSON tables. Those tables were fully retired on 2026-07-09 — see `AGENTS.md`'s "NEXUS WB import/export and WB editor" section. `workout_blocks` (+ `workout_block_kns` + `workout_block_sets`) is now the **sole** source of truth for both the WB editor and WB injection paths. Import XLSX/CSV directly into the real tables inside a transaction; there is no legacy mirror to maintain anymore. See `references/nexus-wb-xlsx-real-table-sync.md` for historical context on why the dual-write existed in the first place.

### WB PROJECTIONS source of truth and injected-WB filter (query fixed 2026-07-09)

`WB PROJECTIONS` must discover WBs from the active OVARCH block source, but the C.WO projection view must display only WBs injected into the active C.WO date.

Use:

```dart
final wbList = await OvarchPlanInjectionService.activeWorkoutBlocks(db);
```

Then detect injected blocks for `widget.date` by resolving that day's `workout_logs` rows through **Drift's typed `DateTime` comparison** — not a raw `millisecondsSinceEpoch` literal compared against `wl.date`. Drift stores `DateTimeColumn` as unix **seconds**, so a raw-millisecond comparison silently matches nothing; this was a real, previously undetected bug (found and fixed 2026-07-09, see `lib/ui/workout_manager.dart`'s `_showWbProjections`):

```dart
final selectedDate = widget.date;
final todayStart = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
final todayEnd = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 23, 59, 59);

final logsToday = await (db.select(db.workoutLogs)
      ..where((t) => t.date.isBetweenValues(todayStart, todayEnd)))
    .get();

final injectedBlockIds = <int>{};
if (logsToday.isNotEmpty) {
  final logIds = logsToday.map((l) => l.id).join(',');
  final injectedSets = await db.customSelect(
    "SELECT DISTINCT json_extract(ws.complex_metadata, '\$.injectedFromBlock') as block_id "
    "FROM workout_sets ws "
    "WHERE ws.log_id IN ($logIds) "
    "AND ws.complex_metadata LIKE '%injectedFromBlock%'",
  ).get();
  // ...collect into injectedBlockIds
}
```

Filter `wbList` to `injectedBlockIds` before rendering. If none are found, show `NO_INJECTED_WBS`.

Important:
- `wb_store` no longer exists (retired 2026-07-09) — `activeWorkoutBlocks` reads `workout_blocks` directly, no legacy merge needed.
- Do not show every active WB when the user asked for the C.WO-injected projection view.
- Plan Day injection must call `injectWorkoutBlock(..., trackSourceBlock: true)` so all WBs inserted from a day carry `injectedFromBlock`.
- If existing sets were injected before this fix and lack consistent metadata/timestamp/log alignment, re-inject them once after the fix.
- A smoke test now covers this exact path: `test/wb_smoke_test.dart`.

See `references/cwo-injection-detection.md` and `references/wb-projections-data-path.md` for the original (now partly superseded) investigation.

### `_WbInjectConfigDialog` as StatefulWidget

The inject config dialog was moved from an inline `showDialog` with `StatefulBuilder` to a standalone `StatefulWidget` class (`_WbInjectConfigDialog`). This eliminates the `_dependents.isEmpty` crash that `StatefulBuilder` causes in modals.

### Context Invalidation After `Navigator.pop`

Using the parent `context` to show a dialog after `Navigator.pop(c)` can crash with `This BuildContext is no longer valid`. Prefer `this.context` from the `State` after the modal closes, and guard with `mounted`:

```dart
// BROKEN:
Navigator.pop(c);
_showInjectConfig(context, ref, date, wbData);

// FIXED:
Navigator.pop(c);
Future.microtask(() {
  if (!mounted) return;
  _showInjectConfig(this.context, ref, date, wbData);
});
```

For C.WO injection pickers that use `QualitySearchPicker`, also avoid its default parent-route pop by passing `closeOnSelect: false` and doing the explicit `Navigator.pop(c, value)` yourself. Otherwise `QualitySearchPicker` can close the modal and then pop the parent C.WO route, sending the user to the dashboard.

### Constructor Race Condition

Never call async methods from a StateNotifier constructor. The `Future` runs without `await` and completes after the widget mounts, racing with `initState` → `reload()`.

**WRONG:**
```dart
WbEditorNotifier(this._db, this._blockId) : super(WbEditorState(knsEntries: [])) {
    _initTable();  // async — fires and forgets
}
```

**CORRECT:**
```dart
WbEditorNotifier(this._db, this._blockId) : super(WbEditorState(knsEntries: []));
// No async calls in constructor
```

### Column Safety for Hot Restart and Existing-DB Migration

`beforeOpen` runs only on DB open (full app restart). New columns added mid-session need `ALTER TABLE` in `ensureTable()` and in import/export table-guarantee helpers. Do not assume `CREATE TABLE IF NOT EXISTS` matches the real table shape in an already-migrated DB.

For NEXUS WB import/export, ensure `workout_blocks` has `description` before inserting it:

```dart
try { await _db.customStatement('ALTER TABLE workout_blocks ADD COLUMN intention TEXT'); } catch (_) {}
try { await _db.customStatement('ALTER TABLE workout_blocks ADD COLUMN description TEXT'); } catch (_) {}
```

Apply the same safety net in `beforeOpen`, `WB.editor.ensureTable()`, and `ExportService._ensureWorkoutBlockTables()`.

### NEXUS WB Set IDs Must Be Independent of `set_number`

Do not derive `workout_block_sets.id` from `kns_id + set_number` or any other formula that uses `set_number`. Exported XLSX files can contain duplicate set numbers inside the same KNS (for example two `Pronation Twist set 2` rows), which causes `UNIQUE constraint failed: workout_block_sets.id` during import.

Use an independent monotonically increasing seed per parse/import pass while preserving `set_number` as data:

```dart
var setIdSeed = DateTime.now().microsecondsSinceEpoch + 1000000000;
final setEntry = <String, dynamic>{
  'id': setIdSeed++,
  'setNumber': setNum,
};
```

For fallback paths where parsed rows lack `id`, use a separate seed instead of recomputing from `kns_id`:

```dart
var fallbackSetIdSeed = DateTime.now().microsecondsSinceEpoch + 2000000000;
final setId = _toInt(set['id']) ?? fallbackSetIdSeed++;
```

See `references/nexus-wb-import-migration-pitfalls.md` for the error transcript, migration rule, and verification notes from the GYMR NEXUS WB import fix.

### OVARCH.PLN active WB picker and soft-delete rule (simplified 2026-07-09)

OVARCH.PLN pickers must not read only `workout_blocks WHERE deleted_at IS NULL`; that hides active rows stored as `deleted_at = 0` and can show stale deleted rows stored as `deleted_at IS NULL`. Use `COALESCE(deleted_at, 0) = 0`.

**Superseded:** the legacy `wb_store` merge/reconciliation logic described here previously (skip real-only orphans, merge legacy snapshot, etc.) no longer applies — `wb_store` was retired 2026-07-09. `OvarchPlanInjectionService.activeWorkoutBlocks` now reads `workout_blocks` directly with just the `deleted_at` filter above; there is nothing to merge or reconcile.

When wiring Plan Day / DayBlock block pickers through `QualitySearchPicker`, include the numeric block ID in the visible label and map that exact visible string back to the block ID because `QualitySearchPicker` returns the displayed string, not a hidden value. Validate the selected ID is still active before inserting into `plan_day_blocks`.

### OVARCH.PLN legacy `plan_day_blocks` schema repair

Older local DBs may already contain `plan_day_blocks` with alias columns such as `plan_day_id` / `workout_block_id` instead of Drift's current `day_id` / `block_id`. `beforeOpen` must create the table if missing, add `day_id` / `plan_day_id` / `block_id` / `workout_block_id` / `order_index` / `notes` safety columns, then backfill both directions (`plan_day_id -> day_id`, `day_id -> plan_day_id`, `workout_block_id -> block_id`, and `block_id -> workout_block_id`) before any Drift DAO query touches `db.planDayBlocks`. Until the schema is fully normalized, direct inserts into `plan_day_blocks` must populate both `day_id` + legacy `plan_day_id` and both `block_id` + legacy `workout_block_id`.

### OVARCH.PLN DayBlock architecture

GYMR planning is moving to a WB-backed model: `TrainingPlans -> PlanWeeks -> PlanDays -> PlanDayBlocks -> WorkoutBlocks`. `PlanDayBlocks` is a live reference to a WB, not a snapshot. DayBlock notes are allowed, but do not build a full modifier/snapshot layer on top of the WB. C.WO keeps both `Workout Block` and `Plan Day` injection buttons; Plan Day injection expands all DayBlock WBs in order and appends below existing sets. Mark those inserted sets with `injectedFromBlock` by calling `injectWorkoutBlock(..., trackSourceBlock: true)` so C.WO can recognize and project the WBs that came from the day. See `references/ovarch-dayblock-architecture.md` for the schema, UX, injection, and legacy-blueprint rules.

### OVARCH.PLN Plan Day picker context safety

- When wiring the C.WO `Plan Day` picker in `lib/ui/workout_manager.dart`, keep the picker UI and the persistence path context-safe:
  - `QualitySearchPicker` calls `widget.onSelected(...)` before it decides whether to pop. If your `onSelected` already does `Navigator.pop(c, value)`, pass `closeOnSelect: false`; otherwise the widget will pop the modal and then continue to pop the parent route. This is the common cause of being unexpectedly sent from C.WO to the dashboard after selecting a Plan Day or WB.
  - Use `this.context` from the `State` after closing the picker, not the picker builder's stale `BuildContext`, when opening the next options dialog or showing a snackbar.
  - Check `mounted` immediately after every `await` that can outlive a modal or route pop.
- Build the exact visible picker label and map that exact string to `dayId` before showing `QualitySearchPicker`. Do not use hidden keys like `GYMR_DAY_ID:$dayId` because `QualitySearchPicker` returns the displayed string, not the hidden value.
- Treat invalid selections as a user-visible failure with `INVALID_PLAN_DAY_SELECTION`, not as a silent return.
- For Plan Day injection, let the service continue past deleted/missing/empty WBs and return `{injected, skipped}` so the UI can show `PLAN_DAY_INJECTED: N WB / SKIPPED: M` instead of pretending a partial failure was a full success.
- When Plan Day injection looks silent, instrument every handoff with process logs (`CWO_INJECTION`, `CWO_PLAN_DAY`, `PLAN_DAY_PICKER`, `OVARCH_PLAN_DAY_INJECT`, `OVARCH_INJECT`, and `PLAN_SCREEN_INJECT`) before assuming the service is the only failing point.
- C.WO injection type button colors should come from THEME.MDFYR keys: `INJECTION_INDIVIDUAL_MOVEMENT`, `INJECTION_WORKOUT_BLOCK`, `INJECTION_PLAN_DAY`, and `INJECTION_COPY_FROM_SPECIFIC_DAY`; `COPY_FROM_SPECIFIC_DAY` should default to a non-green/non-orange/non-cyan color such as `LabColors.secondary`.
- After successful `OvarchPlanInjectionService.injectPlanDay(...)`, show a snackbar and let the existing C.WO stream refresh. Do not push a duplicate `WorkoutManagerScreen`; it creates stacked navigation and is unnecessary for the current-day data path.
- Plan Day injection must pass `trackSourceBlock: true` to `injectWorkoutBlock(...)` so the inserted sets carry `injectedFromBlock` and `WB projections` can identify exactly which DayBlock WBs were injected into the active C.WO date.
- C.WO WB injection should show a compact options popup before insertion so the user can choose `P.LOAD -> LOAD`, `MAX REPS -> REPS`, `MIN REPS -> REPS`, `RPE -> RPE`, `INJECT ALL SETS`, and `APPLY TO ALL KNS/SETS`. When global apply is off, allow per-KNS overrides; sets inside a KNS inherit that KNS option set.
- Plan Day injection must pass the selected injection options into `OvarchPlanInjectionService.injectPlanDay(..., options: options.toServiceOptions())`. The service should resolve options per KNS and insert `workout_sets.rpe` when RPE is enabled.
- Plan Day block resolution must tolerate legacy/alias IDs: prefer `plan_day_blocks.workout_block_id`, fall back to `plan_day_blocks.block_id`, then resolve through current `workout_blocks`. (The `wb_store` snapshot fallback mentioned in older notes no longer applies — that table was retired 2026-07-09.) If the plan day points to a stale ID and there is exactly one active WB, use that single active WB as a last-resort fallback and log `ACTIVE_SINGLE_FALLBACK`; if there are multiple active WBs and no match, log `NO_FALLBACK` instead of guessing.
- If Plan Day options checkboxes are visually non-responsive, replace `Icon`/`InkWell`-only checkbox rows with a real `Checkbox` inside an `InkWell` row; this keeps both the square and label tappable. See `references/cwo-injection-progress-plan-checkboxes.md`.
- C.WO WB and Plan Day injection should show a visible green progress card near the top of the C.WO day body while injection runs. Use a continuous `LinearProgressIndicator` with a percentage above it, start it before injection, update it per KNS for WB injection, finish it in both success and error paths, and cancel the progress timer in `dispose()`. See `references/cwo-injection-progress-plan-checkboxes.md`.

This pattern prevents stale-context crashes, visible-label mapping bugs, silent partial Plan Day injection failures, and WB injection that silently drops MIN REPS or RPE. See `references/ovarch-plan-day-injection-pitfalls.md` and `references/cwo-wb-injection-options.md`.

### C.WO injection progress must be driven by service callbacks

When fixing `WO INJECTION` or `PLAN DAY INJECTION` progress, do **not** duplicate the full KNS/set insertion loop in `lib/ui/workout_manager.dart` just to update a progress bar. The UI should own presentation only (`_startInjectionProgress`, `_setInjectionProgress`, `_finishInjectionProgress`) and pass callbacks into the service:

- `OvarchPlanInjectionService.injectWorkoutBlock(..., onKnsProgress: ...)`
- `OvarchPlanInjectionService.injectPlanDay(..., onProgress: ...)`

`injectWorkoutBlock` should compute `totalKns` after reading `workout_block_kns`, throw `WB_HAS_NO_KNS` when there are no KNS rows, and call `onKnsProgress(processedKns, totalKns, ...)` after each KNS is inserted. `injectPlanDay` should count total KNS across resolved DayBlock WBs before injection, then increment progress through the same per-KNS callback path. Start progress before the options dialog, update it from callbacks, and finish it in success, cancel, and error paths.

Validate that a selected WB has real `workout_block_kns` rows before opening WB injection options; if none exist, show `WB_HAS_NO_KNS` and return. See `references/cwo-injection-progress-service-callbacks.md`.

### WO.BLOCKS Sort Bar Buttons — Backburner Removal

The following buttons were removed from the WO.Blocks.manager.dart sort bar (Row in build method, around line 278):
- NEWEST, A-Z, FOLDER (sort chips via `_sortChip`)
- DELETE ALL BLOCKS, DEL PAST (GestureDetector with red/orange borders)

When removing them, the Row should be kept with just `const Spacer()` + the `'${blocks.length} WB'` counter text. No code needs to stay for these buttons — entire blocks can be deleted cleanly.

### WB Editor Set Field Initialization: JST.BW and ISO Handling

The WB editor renders workout_block_sets as `WorkoutSet` objects through `_WorkoutSetInstance`. Understanding the data mapping is critical to avoid the JST.BW bodyweight trap and to correctly handle ISO labels.

**Data mapping in `workoutSetsProvider`** (lines 846-871 of `WB.editor.dart`):

| DB column | WorkoutSet field | TextEditingController | UI label |
|---|---|---|---|
| `reps_min` | `technique` | `_lC` | MIN REPS / MIN SEC |
| `reps_max` | `reps` | `_rC` | MAX REPS / MAX SEC |
| `pload` | `weight` | `_ploadC` | P.LOAD |

The `_lC` controller is bound to MIN REPS (or MIN SEC for isometric), **not** to load/weight. `_ploadC` is the load controller.

**JST.BW: NEVER force bodyweight into minReps.** The `_initControllers` method must NOT set `_lC.text = widget.bodyWeight.toString()` for JST.BW exercises. This was a recurring bug where:
- `_initControllers` overwrote the DB-loaded `reps_min` value with bodyweight
- User edits were lost on re-entering the WB editor

The fix: remove the bodyweight override entirely. The minReps value loads naturally from `workout_block_sets.reps_min` → `WorkoutSet.technique` → `_lC.text`. Tonnage calculations still use `widget.bodyWeight` directly via `final w = isJst ? widget.bodyWeight : (double.tryParse(_lC.text) ?? 0)` in the build method — no data loss.

**ISO exercises: conditional MIN SEC / MAX SEC labels.** `_WorkoutSetInstanceState` already detects isometric state via `_isIso` in `_initControllers`:

```dart
_isIso = (metaMatch?.group(2) == 'true') ||
    intentionText.startsWith('[ISO]') ||
    widget.exercise.parsedComplexMetadata['isIsometric'] == true;
```

The MIN REPS / MAX REPS labels in `build()` must use this flag:

```dart
_buildGridInput(_isIso ? 'MIN SEC' : 'MIN REPS', _lC, flex: 25),
_buildGridInput(_isIso ? 'MAX SEC' : 'MAX REPS', _rC, flex: 25),
```

This keeps the field semantics correct without changing the underlying DB schema or persistence.

### C.WO set input reactivity pattern

C.WO set cards should feel immediate even though persistence is debounced. In `lib/ui/workout_manager.dart`, `_onChanged()` is the right place to split UI reactivity from DB persistence:

```dart
void _onChanged() {
  _db?.cancel();

  _db = Timer(const Duration(milliseconds: 100), () async {
    if (!mounted) return;
    // heavy DB / PR / history work stays here
  });
}
```

Rules:
- Do **not** call `setState(() {})` on every LOAD / REPS / SECS keystroke by default. On low-end Android devices, rebuilding the whole `_WorkoutSetInstance` card while the keyboard is composing text can feel slower than the original DB debounce.
- Let `TextField` update its visible text natively during typing. Keep the persistence path debounced so SQLite is not flooded while the user types.
- If controller-derived values such as TONNAGE/eORM must update immediately, prefer a targeted local rebuild/listenable around only the derived summary widgets after testing. Avoid a full-card `setState()` until the user confirms the reaction is still instant.
- Keep DB writes debounced to avoid flooding SQLite while the user types; a short debounce such as `100ms` is reasonable, but the visible typing path should not be blocked by the debounced work.
- The completion checkbox should update SQLite and call `setState(() {})` immediately; do not rely on the parent stream refresh for the green rectangle to appear.
- Heavy PR/history recalculation should be split from the fast current-set save when typing still feels delayed. Use a short debounce for raw field persistence (about 100 ms) and a longer idle debounce for PR/eORM recalculation (for example 1.2 s after the last keystroke):
```dart
Timer? _db;
Timer? _prDb;

void _onChanged() {
  _db?.cancel();
  _prDb?.cancel();

  _db = Timer(const Duration(milliseconds: 100), () async {
    await _saveCurrentSetRaw();
  });

  _prDb = Timer(const Duration(milliseconds: 1200), () async {
    await _recalculatePrsAndEorm();
  });
}
```
This keeps LOAD/REPS/SECS responsive during composition while PR/eORM updates after the user pauses.
- The completed-set checkbox should feel instantaneous: update local UI with `setState(() {})` before the SQLite write, and persist only `isCompleted` with an unawaited targeted `db.update(...).write(...)`. Avoid `replace(widget.set.copyWith(...))` for this toggle because it writes the whole row and adds avoidable latency.
- If the user asks for a larger checkbox hitbox but says the visual frame must stay the same, do not enlarge the painted 36 px frame. Use a wider GestureDetector/SizedBox hit target (for example `46.8 px` = `36 * 1.15`) and center the 36 px visual frame inside it. This keeps the visual frame unchanged while expanding the touch target.
- If the user reports that lag is much worse with many KNS cards or many sets per KNS, treat it as a rendering-scale problem, not just a TextField problem: use lazy builders, cache grouped set slots, and parse exercise metadata once per KNS/exercise instead of once per set. See `references/cwo-large-session-rendering.md`.
- Pitfall: if the user says typing LOAD/REPS/SECS feels delayed, inspect `_onChanged()` for full-card `setState()` on every keystroke before adding more DB work. See `references/cwo-input-reactivity.md` for the iteration log and verification notes.

### C.WO input + large-session scroll performance pass

When the user reports that C.WO typing feels delayed (for example, letters appear several seconds after typing) or that scrolling with 50+ KNS sets is choppy, treat it as a combined input-reactivity and render-scale problem.

- Keep the visible `TextField` composition path native and fast. Do not call full-card `setState()` on every keystroke unless the user explicitly asks for instant derived-value refresh.
- Split persistence from expensive work:
  - Raw set fields: debounce the DB write around 100 ms.
  - Set notes: debounce around 300 ms and pass `includePr: false` so typing notes does not trigger PR/eORM recalculation.
  - PR/eORM recalculation: run on a longer idle timer, around 1.2 s after the last raw-field edit.
- For general/session notes, debounce each note independently (around 700 ms), cancel the previous timer for that note, and persist after the pause. Do not write to SQLite on every character.
- For large C.WO sessions, migrate the main page from `SingleChildScrollView + Column` to `CustomScrollView + slivers` so the list can be built incrementally instead of laying out one huge column at once.
- When migrating to slivers, validate the render-object contract before calling it done:
  - Every entry in `CustomScrollView.slivers` must produce a `RenderSliver`.
  - If a normal box widget such as `Padding`, `Column`, `SizedBox`, or a session-notes widget is needed, wrap it with `SliverToBoxAdapter(...)`.
  - Never place a box widget directly in `slivers`; Flutter will throw `A RenderViewport expected a child of type RenderSliver but received a child of type RenderPadding`.
  - Never wrap a `SliverToBoxAdapter` inside another `SliverToBoxAdapter`; Flutter will throw `A RenderSliverToBoxAdapter expected a child of type RenderBox but received a child of type RenderSliverToBoxAdapter`.
  - If a conditional helper returns either a sliver or a box, normalize the branch to a box first, then wrap once. Example: `currentLogForNotes == null ? const SizedBox.shrink() : Padding(...)`, then `SliverToBoxAdapter(child: generalNotesWidget)`.
  - After a sliver refactor, ask the user to do a full hot restart, not only hot reload; stale sliver elements can keep a broken render tree alive.
- Do not treat `dart analyze` as sufficient proof for sliver/render-object refactors. It can miss runtime parent/child `RenderObject` mismatches. Pair analyzer with a targeted runtime check from the user/device and, when a stack trace appears, fix the render-object contract directly.
- Avoid unnecessary nested sliver wrappers. If using `SliverList`, use the current Flutter constructor shape:
  ```dart
  SliverList(
    delegate: SliverChildListDelegate([...]),
  )
  ```
  not `list: [...]`.
- Remove expensive animations/curves from expanded note/detail sections during scroll-heavy work. A simple `Column(mainAxisSize: MainAxisSize.min)` is often enough and avoids layout work while scrolling.
- Move repeated work out of `build()` where possible: parse intention/metadata once upstream, precompute group counts, precompute superset flags/names/colors, and read the current `WorkoutLog` for notes once instead of repeatedly from provider rows.
- Verify the code path with `dart format`, `dart analyze --no-fatal-warnings lib/ui/workout_manager.dart`, and `git diff --check -- lib/ui/workout_manager.dart`. These checks catch syntax/type issues, not every runtime sliver-layout failure.
- If the change touches `CustomScrollView`, slivers, `SliverToBoxAdapter`, or nested scrollables, run a hot restart on device/emulator when possible. Hot reload can preserve a broken element tree; hot restart is the safer probe.
- If no device/emulator is available, state explicitly: "Compile checks pass; manual device hot restart is still pending." Do not imply manual testing was done.
- See `references/cwo-sliver-layout-pitfalls.md` for the exact sliver child rules and the two common C.WO crashes from this class of change.
- Manual device testing is still needed for real composition latency and scroll smoothness.

See `references/cwo-input-scroll-performance.md` for the session-specific implementation notes and verification output.

### C.WO Workout Opts popup placement and KNS expansion state

When the user asks for a control "in WORKOUT OPTS", put it inside the `WORKOUT OPTS` bottom sheet (`_WorkoutOptsSheet`) unless they explicitly ask for a separate trigger. Do not enlarge or repurpose the existing `WORKOUT OPTS` trigger button to host the new control. Add the control as a `_WorkoutOptsSlice` and pass any session-level state/toggle callback from `_WorkoutDayPageState` into `_WorkoutOptsSheet`.

For C.WO KNS cards, use parent-owned expansion state when a session-level mode can affect multiple cards. Keep explicit expanded keys and collapsed keys separately so `maintain extended` can expand everything by default while still allowing the user to collapse individual KNS cards until they re-expand them. This preserves typing performance because expansion state changes only on KNS taps/toggles, not on set-field keystrokes.

See `references/cwo-workout-opts-and-kns-expansion.md` for the exact state shape, popup placement pattern, horizontal-margin/spacer fixes, and verification caveats.

### Pixel Overflow Fix Pattern for Nested Bottom Sheets

Deeply nested `showModalBottomSheet(builder: ... => Container(height: ..., child: Column(children: [...]))` popups with multiple buttons easily overflow on smaller screens. The fix pattern:

1. **Wrap the Column in `SingleChildScrollView`** — adds scrollability so content doesn't clip.
2. **Increase the height fraction slightly** — e.g. from `0.4` to `0.45` — for breathing room.
3. **Account for the extra `)`** — adding `SingleChildScrollView(` increases the nesting depth by 1. The closing `])));` becomes `]))));` (one more `)`). Run `dart analyze` on the single file to catch mismatch before hot restart.

See `references/dart-edit-pitfalls.md#nested-modal-parenthesization` for the full parenthesis counting rule.

### Build Runner

Sessions run either from WSL or natively on Windows depending on the environment — check which shell is active first (see `AGENTS.md`). The command is the same either way:
```bash
dart run build_runner build --delete-conflicting-outputs
```
From WSL specifically, the full Dart SDK path used in past sessions was:
```bash
/mnt/c/Users/Ginna/develop/flutter_windows_3.41.5-stable/flutter/bin/cache/dart-sdk/bin/dart.exe run build_runner build --delete-conflicting-outputs
```

## 6.4 C.WO SET CARD UI CONVENTIONS

The set card in `workout_manager.dart` (C.WO active workout screen) has specific behavioral and layout rules that must be preserved:

### Set number area = expand/collapse trigger

The leftmost column displays the intra-exercise set number (`01`, `02`, etc.). **Tapping the set number MUST toggle `_exp`** to expand/collapse the set's detail cards (RPE/RIR/TECH row, somatic, notes, failure phase, toggles, complex mods). Do not replace this tap target with a checkbox — the expand/collapse behavior is a core UX affordance.

### Completed-set checkbox = separate fixed-width frame on the far right

The `isCompleted` toggle is a **separate fixed-width widget** placed on the far RIGHT of the C.WO top row, after `PR`, not merged into the set number. Current layout:

```text
[SET# flex:15] [LOAD flex:27] [REPS/SECS flex:30] [PR flex:25] [CHECK 32px visual frame + expanded hitbox]
```

Current layout:

```text
[SET# flex:15] [LOAD flex:27] [REPS/SECS flex:30] [PR flex:25] [CHECK 32px visual frame + expanded hitbox]
```

The checkbox widget (`_buildCompletedCheck`) uses a full-height frame with an expanded hitbox. The `GestureDetector` must wrap the full-width frame with `HitTestBehavior.opaque`; do not nest the detector only around the tiny check icon.

```dart
Widget _buildCompletedCheck(Color completedColor) {
  final done = widget.set.isCompleted;
  return Padding(
    padding: const EdgeInsets.all(4.8),
    child: SizedBox(
      width: 32,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _setCompleted(!done),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: done
                ? completedColor.withValues(alpha: 0.18)
                : Colors.transparent,
            border: Border(
                left: BorderSide(color: Colors.grey[800]!, width: 0.5)),
          ),
          child: done
              ? Icon(Icons.check, size: 18, color: completedColor)
              : const SizedBox.shrink(),
        ),
      ),
    ),
  );
}

void _setCompleted(bool completed) {
  if (!mounted) return;
  setState(() {});

  final db = ref.read(databaseProvider);
  unawaited((db.update(db.workoutSets)
        ..where((t) => t.id.equals(widget.set.id)))
      .write(WorkoutSetsCompanion(
          isCompleted: drift.Value(completed))));
}
```

The visual checkbox frame is intentionally compact (`32 px`), while the surrounding padding is the expanded hitbox. If the user says the frame got too large, shrink the inner visual frame and keep the outer hitbox separate. If the user wants more horizontal room for `PR`, increase `_buildPRBox(flex: ...)` and reduce the checkbox visual frame rather than changing the checkbox's painted size only.

### Clean integer defaults for C.WO set input controllers

Do not initialize numeric set-field controllers with `value.toString()` when the value is an integer double. That produces default UI text like `5.0` for `LOAD`, `REPS/SECS`, and rest-second fields. Use a small formatter so integer doubles render as `5`, while real decimals remain visible:

```dart
String _formatInputValue(double value) {
  if (value.isFinite && value == value.truncateToDouble()) {
    return value.truncate().toString();
  }
  return value.toString();
}
```

Apply it to `_lC`, `_rC`, `_rsC`, `_fC`, and JST.BW bodyweight initialization:

```dart
_lC = TextEditingController(text: _formatInputValue(widget.set.weight));
_rC = TextEditingController(text: _formatInputValue(widget.set.reps));
_rsC = TextEditingController(
    text: _formatInputValue(widget.set.restTimeSeconds?.toDouble() ?? 0));
_fC = TextEditingController(
    text: widget.set.restTimeSeconds != null
        ? _formatInputValue(widget.set.restTimeSeconds! / 10)
        : '');
if (isJst) {
  _lC.text = _formatInputValue(widget.bodyWeight);
}
```

### C.WO Optimization Pattern (10s Debounce + Value Caching)

After the first VP implementation, C.WO became unacceptably laggy on the user's Redmi Note 8 Pro during typing. Applied three-tier debounce + value caching.

**Root cause:** Heavy work in short debounce paths — `complexMetadata` write in `_saveCurrentSetRaw()` (100ms) and `setState(() {})` in `_recalculatePrsAndEorm()` (1.2s).

**Fix:**

```dart
void _onChanged({bool includePr = true, int rawDelayMs = 100}) {
  _db?.cancel();
  _prDb?.cancel();
  _vpTimer?.cancel();

  _db = Timer(Duration(milliseconds: rawDelayMs), () async {
    await _saveCurrentSetRaw();   // RAW FIELDS ONLY — no VP, no complexMetadata
    if (!includePr || !mounted) return;
    _prDb = Timer(const Duration(milliseconds: 1200), () async {
      await _recalculatePrsAndEorm();  // VP PR merged, NO setState
    });
  });

  _vpTimer = Timer(const Duration(seconds: 10), () async {
    if (!mounted) return;
    _vpValue = _computeVp();
    // persist VP to complexMetadata + ONE setState
  });
}
```

**Value caching (avoid JSON parse in build()):**

```dart
// State — set once, read many times
double _vpValue = 0;
double _vpMultiplier = 1.0;

// initState:
_vpMultiplier = (widget.exercise.parsedComplexMetadata["vpMultiplier"] as num?)?.toDouble() ?? 1.0;
// Load from complexMetadata or compute
if (widget.set.complexMetadata != null && ...) {
  final meta = jsonDecode(widget.set.complexMetadata!);
  _vpValue = (meta['vp'] as num?)?.toDouble() ?? 0;
}
if (_vpValue == 0) _vpValue = _computeVp();
```

**Rules:**
- `_saveCurrentSetRaw()` NEVER writes `complexMetadata` — only raw columns.
- VP PR detection NEVER calls `setState` — update `_hasVpPr` silently; provider stream refresh handles rebuild.
- Display reads cached `_vpValue` — no `_computeVp()` call in `build()`.
- Dispose `_vpTimer` alongside `_db` and `_prDb`.
- Parsed-once multiplier vs `widget.exercise.parsedComplexMetadata` on every build.

**"DEFAULT: 1.0" label removed** from exercise editor VP MULTIPLIER field — user found it visually noisy.

### Performance Overview Card (async, live compute)

Added as `SliverToBoxAdapter` below `generalNotesSliver` — wrapped in `FutureBuilder<Widget>`:

```dart
SliverToBoxAdapter(child: generalNotesSliver),
SliverToBoxAdapter(
    child: FutureBuilder<Widget>(
        future: _buildVpOverview(context, ref, workoutAsync.value),
        builder: (ctx, snap) =>
            snap.connectionState == ConnectionState.done
                ? (snap.data ?? const SizedBox.shrink())
                : const SizedBox.shrink())),
```

`_buildVpOverview` returns `Future<Widget>` and:
1. Groups C.WO sets by `baseExerciseId`
2. For each group, orders sets by timestamp to assign ordinals
3. Computes VP live from `workout_set.weight` + `workout_set.reps` + ordinal + `vpMultiplier` — **not** from stored `complex_metadata['vp']`
4. Uses `bodyWeightAtDateProvider` for body weight in JST.BW/LASTRE calculations
5. Resolves exercise names via async DB query — uses `ex.fullName` for full KNS display
6. Renders bordered card: header (PERFORMANCE OVERVIEW + total VP), per-KNS rows (full name + VP), SESIÓN TOTAL footer
7. Returns `SizedBox.shrink()` when no VP data exists

**Why async:** Two DB queries — exercise list (for names + multipliers) and body weight provider — make pure-sync impractical. FutureBuilder handles the loading state cleanly.

**Key constraint:** Shows full KNS names via `ex.fullName` per the KNS Full Name Display Rule.

### Theme key for completed color

When `completedColor` appears in the C.WO set card, derive it from the theme system:

```dart
final completedColor =
    tC.getColor(settings, 'UI_TAG_SET_COMPLETED', defaultColor: Colors.greenAccent);
```

This lets the user customize the check fill from THEME.MDFYR under key `UI_TAG_SET_COMPLETED`.

### COMPLEX_SET_MODS moved below failure phase

The 3-dot trigger (`_buildModsTrigger` / `Icons.more_vert`) that opened the complex set mods modal has been replaced. Instead of a right-aligned 3-dot button in the top row, there is a dedicated `_buildComplexSetModsButton()` placed immediately after `_buildFailurePhaseCard()` in the expanded detail section. This button uses `Icons.tune` with a center-aligned `COMPLEX_SET_MODS` label.

Remove the dead `_buildModsTrigger` method when refactoring — it is no longer called from the widget tree.

### C.WO batch rendering and assignment pitfalls

C.WO batch sections must stay anchored at their first visible position. If a KNS assigned to an existing batch appears later in `orderIndex`, append it to the existing batch section instead of creating a duplicate bottom header for the same batch. The batch order should reflect the first occurrence unless the user voluntarily moves the batch with its drag handle.

When assigning a C.WO KNS to a batch, expand the target batch after persistence so the assigned KNS does not appear to disappear inside a collapsed batch. A practical pattern is to add `expandBatch(String batchName)` on `_WorkoutDayPageState` and call it from `_ExerciseModuleState` via `context.findAncestorStateOfType<_WorkoutDayPageState>()?.expandBatch(batchName)`.

In `WB.editor.dart`, `setBatch(int knsId, String batchName)` must preserve the KNS child sets when rebuilding `WbEditorKns`: pass `sets: k.sets`. Dropping `sets` makes `_save()` persist a KNS without its set rows and can make the card disappear or render empty after reload.

For C.WO's nested `ReorderableListView` layout, use `padding: EdgeInsets.zero` on both the outer list and the inner batch list, and avoid duplicate spacers after `WORKOUT OPTS`. A single compact spacer is enough; extra day-specific spacer branches create the initial-gap feel that often disappears after the first scroll.

### InkWell inside ReorderableDragStartListener: wrap with Material

When a KNS card in a `ReorderableListView` contains an `InkWell` (e.g. the exercise name area for expand/collapse), dragging the card via `ReorderableDragStartListener` crashes with:

```
No Material widget found.
_InkResponseStateWidget widgets require a Material widget ancestor within the closest LookupBoundary.
```

**Why:** Flutter renders the dragged widget in a temporary overlay tree that lacks the `Material` ancestor present in the normal widget tree. `InkWell` (which is `_InkResponseStateWidget`) requires `Material` to render ink splashes.

**Fix:** Wrap the `InkWell` with `Material(color: Colors.transparent)`:

```dart
Material(
  color: Colors.transparent,
  child: InkWell(
    onTap: () => widget.onToggleExpanded(!widget.expanded),
    onLongPress: () => _showComplexModsModal(context),
    child: Column(/* exercise name + tags */),
  ),
)
```

The `Colors.transparent` preserves the original visual appearance — no background, no ink splash visible — while providing the required `Material` ancestor for the drag overlay.

**Verification:** `dart analyze` must pass with 0 errors. The bracket chain must be correct: every `Material(` needs its own closing `),` at the same indent level as the opening.

**Pitfall (multi-pass patches):** Applying incremental patches that wrap already-wrapped code creates double nesting. If the area was already patched once, read the current file and replace the entire block, not just the opening line, to guarantee balanced brackets.

### KNS Full Name Display Rule

**Always show the full constructed KNS name** (`BaseExercise.fullName`) in any UI that displays exercises, unless explicitly overridden. The full name is built from:

```
[body positions] [implements] [prefixes] BASE_NAME [suffixes]
```

Concrete examples:
- `SUPINE RING FL ROW` (body position + implement + base name)
- `WEIGHTED PARALLEL PRONATION TWIST SUPINATED` (implements + prefix + base name + suffix)
- `ARCHED BACK PULL UP TUT` (body position + base name + suffix)

The `BaseExercise.fullName` getter (in `lib/database/database.dart` line 824) already constructs this correctly — use `ex.fullName` instead of `ex.name` wherever a human-readable exercise label is needed. This applies to the Performance Overview, charts, exports, and any summary display.

The only exception is **inline editing contexts** where the base name alone is sufficient because prefixes/suffixes are visible through other UI elements (e.g. the exercise name header inside a KNS card that already shows tags separately).

### KINISI INVENTORY filter chips are not the C.WO inject picker

`KINISI INVENTORY` is `lib/ui/ledger_screen.dart`. The C.WO movement injection picker is `lib/ui/workout_manager.dart` and must not be changed when the user asks to remove KINISI INVENTORY chips.

If asked to remove chips such as `NAME`, `MUSCLEGROUP`, `PATTERNTYPE`, `PURPOSE`, `TISSUETYPE`, and `FIELD` from KINISI INVENTORY:

1. Edit `ledger_screen.dart` only.
2. Remove `FilterType`, `_selectedFilterType`, the `GridView.count` chip bar, `_buildFilterButton()`, and the old per-filter `switch`.
3. Keep `SEARCH_INVENTORY` as a global search across relevant exercise fields.
4. Do not remove `BASE` / `MUSCLE` filters from the C.WO `INJECT_MOVEMENT` picker unless explicitly asked.
5. If the C.WO picker was changed by mistake, restore its original `BASE` and `MUSCLE` text-input filters and related state.

See `references/kinisi-inventory-filter-chips.md`.

## 6.5 THEME.MDFYR DASHBOARD COLOR KEYS

Dashboard/home module cards for `WO.BLCKS` must read the THEME.MDFYR dashboard keys `DASHBOARD_CARD_WO.BLKCS` and `DASHBOARD_CARD_WO.BLKCS_BG`. The visible label remains `WO.BLCKS`, but the theme key is the corrected `WO.BLKCS` spelling.

`ThemeController.getColor(...)` supports `aliases` for backward compatibility. Use aliases when wiring cards so existing saved colors are not broken:

- `DASHBOARD_CARD_WO.BLKCS` with aliases `DASHBOARD_CARD_WO.BLCKS`, `DASHBOARD_CARD_SESSION.BP`
- `DASHBOARD_CARD_WO.BLKCS_BG` with aliases `DASHBOARD_CARD_WO.BLCKS_BG`, `DASHBOARD_CARD_SESSION.BP_BG`

## 6.6 NEXUS EXCHANGE UI PATTERNS

NEXUS exchange cards should use `_buildExportCard(..., onDownload: ...)` for download buttons and `_buildImportCard(...)` for import cards. KNS library CSV export should return the generated file path and accept `{bool share = true}` so share actions call `share: true` while download actions call `share: false` and save with `FilePicker.platform.saveFile(...)`.

Use theme-aware exchange colors through `NEXUS_WO_BLOCKS`, `NEXUS_KNS_LIBRARY`, and `NEXUS_ROUTINE`, with defaults of yellow, orange, and green. Add the same keys to THEME.MDFYR under `NEXUS_EXCHANGE_COLORS` so the user can override them. Always pass `defaultColor` when resolving these keys; otherwise `ThemeController.getColor(...)` falls back to a deterministic hash.

Do not declare local variables inside Dart collection spread literals. Move variables such as exchange color defaults before `return Container(...)` or before the collection literal.

See `references/nexus-exchange-ui.md` for the full pattern and pitfalls.

## 6.7 DB Inspector Category Replace Pattern

Use exact category replacement for DB inspector typo cleanup tools. Load columns via PRAGMA, load `SELECT DISTINCT` values for the selected column, present scrollable selectors for column / TO REPLACE / REPLACE WITH, snapshot affected rows into `_UndoSnapshot(isBulkReplace: true)`, then run an exact `UPDATE`. Handle `NULL` with `IS NULL` / `SET column = NULL`. Use a dedicated `StatefulWidget` dialog for the modal instead of `StatefulBuilder`.

Drift parameter pitfall:
- `customSelect(..., variables: ...)` expects `Variable(value)` wrappers.
- `customStatement(sql, params)` expects raw Dart values, not `Variable(...)`.
- Passing `Variable<Object>` to `customStatement` causes: `Invalid argument (params[1]): Allowed parameters must either be null or bool, int, num, String or List<int>.: Instance of 'Variable<Object>'`.
- Correct pattern:
```dart
final selectVariables = <dynamic>[];
if (fromRaw != null) selectVariables.add(fromRaw);
final matchingRows = await db.customSelect(
  'SELECT * FROM $table WHERE $whereSql',
  variables: selectVariables.map((v) => Variable(v)).toList(),
).get();

final updateVariables = <dynamic>[];
if (toRaw != null) updateVariables.add(toRaw);
if (fromRaw != null) updateVariables.add(fromRaw);
await db.customStatement(
  'UPDATE $table SET $setSql WHERE $whereSql',
  updateVariables,
);
```

UI expectation for DB inspector modals:
- The user wants dense, dark, technical UI with sharp corners (`BorderRadius.zero`), not soft rounded cards.
- Category replace popup should be taller vertically and use fixed-height, clipped scrollable lists.
- Avoid nested `SingleChildScrollView` around bounded `ListView`s; use fixed heights + `ClipRect` so the highlighted row stays inside its list and does not overlap the rest of the dialog while scrolling.

See `references/db-inspector-architecture.md` for the full category replace dialog architecture and pitfall notes.

## 6.8 GIT SNAPSHOTTING FOR UNSTABLE BUILDS

When the user asks to create a Git repo and push the current GYMR build, treat it as a **release snapshot**, not as a casual local experiment. Prefer a private GitHub repo, initialize locally first, add a Flutter/Dart `.gitignore`, exclude local-only files such as `android/local.properties`, and add a short `README.md` caveat if the user says the version is unstable or unverified. Commit with language like `Initial unstable GYMR snapshot`.

Do not fake a push if GitHub auth is missing. `gh` may be absent, `GITHUB_TOKEN` may be unset, and SSH credentials may not exist; report the exact auth blocker and ask for a token, `gh` login, or an existing remote URL.

See `references/git-snapshotting-unstable-builds.md` for the snapshot workflow, ignore rules, and auth pitfalls.

## 7. RELEASE ZIP PACKAGING

When packaging a GYMR build snapshot as a release ZIP, create it under the GYMR project directory's `.zip safety vault` folder as `.zip safety vault/GYMR_vX.Y.Z__<short_descriptive_change_summary>.zip`, not inside the current build root. The filename must describe what this version added, removed, changed, fixed, or polished. Include source/config/platform/assets plus existing project guidance files, but exclude generated or local-only artifacts (`.dart_tool/`, `build/`, `.flutter-plugins-dependencies`, `GYMRpndev.txt`, the destination `.zip safety vault/`, and compiled app artifacts). As of 2026-07-09, stray/archived files (including the old sample `gymr_wbs*.xlsx`) live under `MISC/` at the repo root — exclude `MISC/` from release ZIPs as well, since none of it is part of the shipped app.

For normal release packaging, verify the archive with a real ZIP integrity check and a manifest probe for required entries such as `pubspec.yaml`, `pubspec.lock`, `lib/main.dart`, `android/app/build.gradle.kts`, `assets/db.sqlite`, `AGENTS.md`, and `VERSION.md`. When the user explicitly asks for a simple ZIP with no unnecessary verification, use the fast path: create the ZIP at the correct path and report the path only; do not run testzip/manifest checks unless the user asks or there is a real risk.

See `references/release-packaging.md`.

## 8. REFERENCES

Key reference files in the gymr skill:
- `references/real-db-hybrid-persistence.md` — Full architecture of the dual-path persistence model
- `references/immutable-update-set-pattern.md` — The updateSet fix and constructor race condition analysis
- `references/insert-or-ignore-cascade-pitfall.md` — Why INSERT OR REPLACE + ON DELETE CASCADE silently deletes child field values
- `references/injection-context-crash-fix.md` — BuildContext invalidation fix for showDialog after Navigator.pop
- `references/wb-editor-state-persistence.md` — Original mock persistence documentation
- `references/wb-editor-mock-limitations.md` — Why the mock system was abandoned (with detailed failure analysis)
- `references/inject-wb-config-popup.md` — The inject config dialog + unilateral injection
- `references/auto-merge-regex-pattern.md` — Case-insensitive + regex-normalized merge
- `references/db-inspector-architecture.md` — Configurable columns, page size, category replace, and raw data export.
- `references/cwo-input-reactivity.md` — C.WO text-field reactivity lesson: avoid full-card `setState()` on every keystroke; keep completion check immediate; split fast current-set save from PR/eORM recalculation.
- `references/cwo-input-scroll-performance.md` — C.WO input debounce plus large-session scroll performance pass for set notes, session notes, and 50+ KNS sessions.
- `references/cwo-workout-opts-and-kns-expansion.md` — C.WO Workout Opts popup placement, maintain-extended toggle, parent-owned KNS expansion state, and compact spacer/margin fixes.
- `references/cwo-sliver-renderobject-pitfalls.md` — C.WO `CustomScrollView` sliver migration rules and render-object runtime pitfalls.
- `references/cwo-completed-check-reactivity.md` — Completed-set checkbox fast local UI update and expanded-hitbox-without-enlarged-frame pattern.
- `references/kinisi-inventory-filter-chips.md` — KINISI INVENTORY chip-removal scope: edit `ledger_screen.dart`, not the C.WO inject picker.
- `references/cwo-injection-detection.md` — C.WO WB injection recognition fix: logs can show KNS/sets inserted while `NO_INJECTED_WBS` still appears if detection uses the wrong date/timestamp path.
- `references/cwo-injection-progress-plan-checkboxes.md` — Visible green C.WO injection progress bar, per-KNS WB progress updates, Plan Day continuous progress, and responsive Plan Day checkbox row pattern.
- `references/cwo-injection-progress-service-callbacks.md` — Service-driven progress callbacks for C.WO WB and Plan Day injection.
- `references/cwo-sliver-layout-pitfalls.md` — C.WO sliver layout rules: valid sliver children, direct-box and nested-sliver crash patterns, hot restart verification, and parent-owned expansion state.
- `references/cwo-wb-injection-options.md` — C.WO Workout Block injection options popup, per-KNS overrides, RPE/MIN REPS injection, and Plan Day legacy block resolution.
- `references/cwo-large-session-rendering.md` — C.WO large-session rendering lesson: lazy builders, grouped slot caching, and parse exercise metadata once per KNS/exercise.
- `references/nexus-wb-import-migration-pitfalls.md` — NEXUS WB XLSX import migration safety and unique set-ID rule.
- `references/nexus-wb-xlsx-real-table-sync.md` — NEXUS WB XLSX real-table import/export sync
- `references/wo-blocks-rename-wb-editor-copy-day.md` — WO.BLCKS rename, WB editor copy-day persistence, C.WO copy-day context safety, and markdown export share=false pattern
- `references/git-snapshotting-unstable-builds.md` — Git repo snapshot workflow for unstable GYMR build folders, ignore rules, README caveat, and GitHub auth pitfalls
- `references/nexus-expected-inputs-wb-template.md` — WB empty template for NEXUS EXPECTED INPUTS (XLSX generation + data reference)
- `references/ovarch-dayblock-architecture.md` — OVARCH.PLN DayBlock schema, UX, injection, and legacy-blueprint rules.
- `references/ovarch-plan-day-injection-pitfalls.md` — C.WO Plan Day picker visible-label mapping, partial injection handling, and injection button theme keys.
- `references/ovarch-wb-picker-pitfalls.md` — Active WB picker filtering, `QualitySearchPicker` visible-value mapping, debug logs, and `DEL PAST` cleanup notes.
- `references/nexus-exchange-ui.md` — NEXUS export/download button pattern, KNS CSV path-returning export, and exchange color theme keys.
- `references/theme-dashboard-color-keys.md` — THEME.MDFYR dashboard key aliases for WO.BLCKS cards.
- `references/release-packaging.md` — GYMR release ZIP packaging convention and verification checklist.
- `references/build-path-recovery.md` — canonical GYMR build path, duplicate-folder recovery order, and when to use Git vs ZIP backups.
- `references/volume-points-system.md` — Volume Points (VP) system: finalized formula `tonnage × (1 + m·ln(i+1))`, ordinal-based, implementation details (C.WO display, VP PR detection, multiplier field), files touched.
