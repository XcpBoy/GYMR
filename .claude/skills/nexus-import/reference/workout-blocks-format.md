# Workout Block (routine) format

Source of truth: `lib/services/export_service.dart` — `exportWorkoutBlocksToXlsx`/`exportWorkoutBlocksToCsv` (writers, share a `_buildWorkoutBlockRows` helper), `importWorkoutBlocksFromCsv`/`importWorkoutBlocksFromExcel` → shared `_parseWorkoutBlockRows`/`_writeImportedWorkoutBlocks` (readers).

**One row per SET, not per exercise.** An exercise with 3 sets in the routine needs 3 rows, all sharing the same exercise-identity columns (WB_NAME/WB_FOLDER/WB_CREATED_AT/EXERCISE_NAME/ORDER_INDEX/UTILITIES/BATCH), differing only in the `SET_*` columns.

**Name-based columns, IF a header row is present.** The importer looks for a cell literally equal to `WB_NAME` (case-insensitive) in row 1. If found, columns are read by name — order doesn't matter as long as the header is accurate. If NOT found, every row (including row 1) is treated as data and columns are read by hardcoded position instead. **Always include the header row exactly as below** — don't rely on positional fallback, it has gaps (see SIDE below).

## Columns (header names — order shown matches the app's own export, but name-based lookup means order isn't strict as long as the header row is accurate)

| Header | DB target | Required | Format |
|---|---|---|---|
| `WB_NAME` | `workout_blocks.name` | **Yes** — empty drops the row | Plain text, shared across every row of the block |
| `WB_FOLDER` | `workout_blocks.folder` | No | Plain text, shared across the block |
| `WB_CREATED_AT` | `workout_blocks.created_at` **and the block's literal database ID** | No | Integer (epoch millis). **Leave blank for a brand-new block** — GYMR mints one. When re-importing an edited export, prefer preserving the exact original value — if it's blank instead, the importer falls back to matching an existing block by `WB_NAME` + `WB_FOLDER` and updates it in place rather than forking a duplicate, but that fallback only works if the name/folder are unchanged. |
| `EXERCISE_NAME` | resolved by exact name match | **Yes** — empty drops the row | Must match an exercise **already in the target GYMR install** exactly. This importer does NOT create missing exercises — pair with an exercises-format import first if needed. |
| `EXERCISE_ID` | optional numeric hint | No | Leave blank; the app resolves by name anyway |
| `ORDER_INDEX` | exercise order within the block | No, defaults 0 | Integer, 0-based |
| `UTILITIES` | `workout_block_kns.utilities` | No | **Semicolon-separated** (`;`), e.g. `PRIMARY;GTG` — do not use commas here, that's a different field's convention |
| `BATCH` | `workout_block_kns.batch_name` | No | Plain text batch/cluster name, shared across sets of the same exercise |
| `SET_NUMBER` | `workout_block_sets.set_number` | No, defaults 1 | Integer, 1-based, increments per set row for the same exercise |
| `SET_MIN_REPS` | `reps_min` | No | Number |
| `SET_MAX_REPS` | `reps_max` | No | Number |
| `SET_PLOAD` | `pload` (planned load) | No | Number |
| `SET_RPE` | `rpe` goal | No | Number |
| `SET_RIR` | `rir` goal | No | Number |
| `SET_INTENTION` | set-level purpose note | No | Plain text |
| `PREFIXES` / `SUFFIXES` / `BODY_POSITIONS` / `IMPLEMENTS` | *(display hint only — not persisted)* | No | These are read but currently discarded on write. Leave blank unless the user specifically wants to keep the columns present for readability; don't rely on them to actually change anything. |
| `SIDE` | `workout_block_sets.side` | No | `RIGHT` or `LEFT` (exact case). **Leave blank for unilateral exercises** — see below. Only has a name-based lookup, no positional fallback, so it silently can't be read at all in a header-less file. |

## Unilateral exercises: one row per set, not two

If the target exercise's `IS_UNILATERAL` flag is true, write **exactly one row per set** with `SIDE` blank. GYMR auto-expands it into a RIGHT+LEFT pair at import time. Do not hand-author separate RIGHT/LEFT rows unless you deliberately want asymmetric reps/RPE/etc. per side (in which case, use two rows with explicit `SIDE` values instead of relying on auto-expansion).

## Grouping / de-dup behavior

Rows are grouped into one exercise-block-entry per unique `[ORDER_INDEX, EXERCISE_NAME (uppercased), UTILITIES, BATCH]` combination — set rows sharing all four become sets under the same entry. Keep these four columns byte-identical across every set row of the same exercise, or you'll accidentally split one exercise into two entries in the imported block.

## Idempotency

Re-importing a file with the same `WB_CREATED_AT` **updates the existing block in place** (all its exercises/sets are replaced with what's in the file). With a blank `WB_CREATED_AT`, the importer looks for an existing block with the same `WB_NAME`+`WB_FOLDER` and updates that instead of creating a duplicate; if none matches, a new block is created. Re-importing with a *different* (non-blank) `WB_CREATED_AT` than any existing block always creates a new block. Still prefer round-tripping the exact ID for "edit and re-import" workflows — the name/folder fallback is a safety net, not the primary mechanism.

## Ready template

`templates/workout_block_template.csv` in this skill has a correctly-formatted 2-exercise example (one bilateral, one unilateral) to copy from.
