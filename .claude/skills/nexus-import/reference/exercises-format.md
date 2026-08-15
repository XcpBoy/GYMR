# Exercise Inventory (KNS list) format

Source of truth: `lib/services/export_service.dart` — `exportExercisesToCsv` (writer) and `importExercisesFromCsv`/`importExercisesFromExcel` (readers, identical column layout for both). CSV and XLSX use the same 17 columns in the same order — the difference is only file container, not content.

**Positional, not name-based.** The importer skips the header row unconditionally and reads every subsequent row by column *index*. If you reorder columns, the import will silently put data in the wrong DB fields — no error.

## Columns (exact order)

| # | Header | DB field | Required | Format |
|---|---|---|---|---|
| 0 | `NAME` | `name` | **Yes** — empty name drops the whole row | Plain text, will be stored uppercased |
| 1 | `PREFIXES` | `prefixes` | No | Comma-separated text, e.g. `"One Arm,Standing"`. Full `[{"v":"X","s":true}]` JSON also accepted if you need to hide a piece from the assembled name. |
| 2 | `IMPLEMENTS` | `implements` | No | Same rules as PREFIXES |
| 3 | `BODY_POSITIONS` | `bodyPositions` | No | Same rules as PREFIXES |
| 4 | `SUFFIXES` | `suffixes` | No | Same rules as PREFIXES |
| 5 | `PRIMARY_MUSCLE` | `primaryMuscleGroup` | No | Plain text |
| 6 | `SECONDARY_MUSCLE` | `secondaryMuscleGroup` | No | Plain text |
| 7 | `FIELD` | `field` | No | Plain text (discipline, e.g. `CALISTHENICS`, `BODYBUILDING`, `STREET LIFTING`) |
| 8 | `TISSUE_TYPE` | `tissueType` | No | Plain text |
| 9 | `TISSUE_NAME` | `tissueName` | No | Plain text |
| 10 | `NUM_PHASES` | `numPhases` | No | Integer, defaults to `1` if blank/unparseable |
| 11 | `PHASE_DESCRIPTIONS` | `phaseDescriptions` | No | Free text (not JSON-validated by the importer) |
| 12 | `INTENTION` | `intention` | No | Must start with `[NT:<LOAD_TYPE>|ISO:<true|false>]` if you want the load-nature selector to pick it up correctly. `<LOAD_TYPE>` is one of `LASTRE`, `EXT.LOAD`, `JST.BW`, `BANDED`, `UNMOVABLE`. Free text can follow the bracket, e.g. `[NT:JST.BW|ISO:false] Endurance work`. |
| 13 | `PATTERN_TYPE` | `patternType` | No | Plain text, e.g. `Horizontal Push` |
| 14 | `COMPLEX_METADATA` | `complexMetadata` | No | JSON object, see shape below. If malformed JSON, the importer silently discards the whole cell and starts from `{}` — don't half-write JSON here. |
| 15 | `IS_UNILATERAL` | `isUnilateral` | No | `1` or `true` (case-insensitive) = true; anything else = false |
| 16 | `DESCRIPTION` | *(merged into COMPLEX_METADATA["description"])* | No | Plain text. Use this column for descriptions rather than hand-editing the JSON in column 14 — it's simpler and the importer merges it in automatically. |

## COMPLEX_METADATA JSON shape (column 14)

```json
{
  "regressions": ["EXACT EXERCISE NAME", "..."],
  "progressions": ["EXACT EXERCISE NAME", "..."],
  "alters": ["EXACT EXERCISE NAME", "..."],
  "particular_toggles": ["TOGGLE_NAME", "..."],
  "description": ""
}
```

- `regressions`/`progressions`/`alters` reference **other exercises by their exact full display name** (case-sensitive match against the exercise's assembled name). A relational link to a name that doesn't exist in the target GYMR install is silently broken (shows up in KNS.TREE.ALERT after import, but doesn't error during import).
- These lists are ideally **reciprocal**: if A lists B under `progressions`, B should list A under `regressions` (and vice versa), and `alters` should be listed on both sides identically. If you're generating relational data for a starter pack, keep both sides consistent.
- `description` here is redundant with column 16 — prefer column 16 and leave this key out (or empty) unless you're already hand-authoring the full JSON for other reasons.
- Any keys you omit get backfilled with empty-list/empty-string defaults by the app when it's read later, so a minimal `{}` is safe — but a `description` you want to KEEP should go through column 16, not be left implicit.

## Duplicate handling

Exercises are matched **by exact name**. An exercise with the same `NAME` as one already in the target GYMR install is **left untouched** — re-importing does not update/overwrite an existing exercise's data. If you're revising an exercise the user already has, tell them explicitly that they may need to delete the old one first, or that only genuinely new names will take effect.

## Known app quirks to warn the user about, not silently work around

- Excel import only reads the **first sheet** with data in the workbook — if you're handed a multi-sheet `.xlsx`, only sheet 1 will import.
- There is no Excel *export* for exercises (only CSV) — if the user wants a `.xlsx` starting point, generate CSV instead (Excel opens CSV fine) or tell them to convert.
