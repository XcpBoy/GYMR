---
name: nexus-import
description: Generate GYMR-NEXUS-ready CSV/XLSX files (exercise inventories, workout block routines) for the user to import via C.WO's NEXUS screen. Use when the user asks to fill in / add data to an exported NEXUS file (e.g. "add descriptions to all these KNS"), build a starter-pack of exercises or routines for someone else, or otherwise wants a file they can import back into GYMR instead of typing data by hand in the app.
---

# NEXUS Import Designer

GYMR's NEXUS screen (`lib/ui/nexus_screen.dart`, backed by `lib/services/export_service.dart`) is the app's import/export hub. This skill lets you **generate the file**, not the user — they import it themselves inside the app afterward.

## When to use this

- User pastes/attaches an exported NEXUS CSV/XLSX and asks you to fill in missing data (descriptions, muscle groups, progressions/regressions, etc.) so they can re-import instead of typing in-app.
- User asks for a "starter pack" of exercises or a routine (workout block) for themselves or someone else.
- User asks you to bulk-generate/edit KNS (exercise) data or a workout block from scratch.

## The two formats you'll actually use

Read the matching reference doc **before** generating either file — the two formats have genuinely different rules (positional vs name-based columns, different delimiters, different idempotency semantics). Do not assume one format's rules apply to the other.

1. **Exercise inventory (KNS list)** → `reference/exercises-format.md`. Round-trips cleanly: what NEXUS exports as CSV is exactly what it re-imports.
2. **Workout block (routine)** → `reference/workout-blocks-format.md`. One row per **set** (not per exercise) — an exercise with 3 sets is 3 rows sharing the same exercise identity columns.

Ready-to-copy starter templates for both live in `templates/`. Prefer editing a copy of these over building a file from a blank sheet — they already encode the trickier conventions correctly (unilateral single-row sets, empty-vs-omitted-column handling).

## Critical rules — get these wrong and the import silently misbehaves

- **Exercises CSV/XLSX is positional.** The header row is *read but ignored by the code* — only column *position* matters. Never reorder columns, even if you think a different order reads better. 17 columns, exact order in `reference/exercises-format.md`.
- **Workout Blocks CSV/XLSX is name-based** *if and only if* a header row is present with a cell literally reading `WB_NAME`. Always include the header row exactly as documented — do not rely on positional order for this format.
- **`WB_CREATED_AT` is the block's real database ID, not a timestamp label.** If you're editing an *existing* exported workout block and want the re-import to update it in place, preserve its `WB_CREATED_AT` value exactly. If you're building a brand-new block from scratch, leave the column blank — GYMR will mint an ID on import. Never invent an arbitrary number for this column.
- **`UTILITIES` in workout blocks uses `;` as its separator.** Every other multi-value field in GYMR uses `,`. Don't mix these up.
- **Unilateral exercises need only ONE row per set**, with `SIDE` left blank. GYMR auto-duplicates it into RIGHT+LEFT at import time if the exercise's own `IS_UNILATERAL` flag is true. Do not hand-author RIGHT/LEFT row pairs.
- **`COMPLEX_METADATA` (exercises, column 15) is a JSON object.** If you're only adding a description, the safest edit is to parse the existing JSON in that cell (if present) and set/overwrite its `"description"` key — or just fill the separate `DESCRIPTION` column (col 17), which NEXUS merges into `COMPLEX_METADATA["description"]` on import even if column 15 is empty. Prefer the plain `DESCRIPTION` column for simple text; only touch raw `COMPLEX_METADATA` JSON when the user is asking for progressions/regressions/alters/toggles.
- **`BODY_POSITIONS`/`PREFIXES`/`SUFFIXES`/`IMPLEMENTS` (exercises) accept plain comma-separated text** (`"Ring,Weighted"`) — you don't need the full `[{"v":"...","s":true}]` JSON shape unless the user specifically wants some pieces hidden from the assembled exercise name (`"s":false`).
- **No exercise auto-creation in the Workout Blocks importer.** If a routine references an exercise name that doesn't already exist in the user's GYMR inventory, the row will not create it. If you're building a routine from scratch for someone else, pair it with an exercises-import file (or tell the user which exercise names must already exist / be imported first).
- **Never blank a required column to "skip" a row.** `NAME` (exercises) and `WB_NAME`/`EXERCISE_NAME` (workout blocks) being empty causes the whole row to be silently dropped, with no error shown to the user.

## Known app bugs worth telling the user about (don't work around them silently)

- The **"IMPORT ROUTINE" button in NEXUS currently parses FitNotes-app CSVs, not GYMR blueprint/routine CSVs** — a wiring bug in `nexus_screen.dart`'s dispatch logic. If a user says a routine/blueprint CSV "didn't import right", this is almost certainly why. Tell them, don't just quietly generate a workaround.
- There is **no Excel export for exercises** and **no CSV export for workout blocks** in the app — only the pairs documented above exist. If the user wants to "start from their current export" in the other format, generate it from the format that *does* export, translating columns per the reference docs.

## Workflow

1. Identify which format the user's request needs (exercises vs workout block — or both, for a "starter pack" that includes ready-to-use routines).
2. Read the matching `reference/*.md` file. If editing an existing exported file the user provided, read it in full before changing anything — preserve every column and every row you're not asked to touch.
3. Generate the output as a `.csv` (preferred — both formats accept CSV, and it's easier for you to write correctly than binary `.xlsx`) using the Write tool. Keep the exact header row from the reference doc.
4. Tell the user the file is ready and exactly which NEXUS button imports it (`IMPORT KNS_INVENTORY` / `.csv` for exercises, or the workout-blocks CSV import — confirm current button labels in `nexus_screen.dart` if unsure, since labels can drift from this doc over time).
5. If you generated new exercises AND a routine that references them in the same request, tell the user to import the exercises file first, then the workout block file — the block importer doesn't create missing exercises for them.
