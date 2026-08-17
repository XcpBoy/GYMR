# KNS.TREE structure format (.md)

Source of truth: `lib/services/export_service.dart` — `exportKnsTreeStructureToMarkdown` (writer), `importKnsTreeStructureFromMarkdown` (reader, `_parseKnsTreeTable`). Reached from NEXUS > EXCHANGES > KNS.TREE. Distinct from the exercises CSV/XLSX format (that's field data — name, muscle group, etc.) and from KNS.TREE.ALERT's export (that's a report of *broken* relations, not the structure itself).

**This is not meant to be human-prose.** It's a markdown table, chosen for parsing reliability over readability — don't hand-author it as natural sentences ("X progresses to Y"), the importer only understands the table shape below.

## Shape

```
| EXERCISE | PROGRESSIONS | REGRESSIONS | ALTERS |
|---|---|---|---|
| PULL UP | WEIGHTED PULL UP;WEIGHTED CHIN UP | BAND ASSISTED PULL UP | CHIN UP |
| WEIGHTED PULL UP |  | PULL UP |  |
```

- One row per exercise that has at least one relation. Exercises with no progressions/regressions/alters are omitted entirely on export.
- Every name is the exercise's **exact assembled full name** (uppercase) — the same string `BaseExercise.fullName` produces, not just the base `NAME` field. If the exercise has prefixes/suffixes/body positions, they must be part of the string here too.
- Multiple names in one cell are **`;`-separated** (not `,` — matches the `UTILITIES` convention elsewhere in NEXUS, since exercise names can themselves contain commas in rare cases).
- A blank cell means "no relations in that category" — leave it empty, don't write `NONE` or similar.
- The header row and the `|---|---|---|---|` separator row are both required for the file to be recognized, but only the column *count* (4) matters for parsing — header cell text is ignored beyond checking for the literal word `EXERCISE` to skip it.

## Import behavior

Two import modes, exposed as two separate NEXUS buttons — pick the one the user actually wants, they are NOT interchangeable:

- **ADD ONLY**: every resolved relation in the file is appended to that exercise's existing list (via the same safe primitive KNST.FIXER's auto-fix uses). Never removes anything already on the exercise. Safe default for "I'm adding new relations to my existing tree."
- **OVERRIDE**: for every exercise mentioned in the file, its progressions/regressions/alters are replaced outright with exactly what the row says (a blank cell clears that category). Use only when the file is meant to be the authoritative full state for those exercises — this **will delete** relations that exist in the app but aren't in the file.

In both modes: a row whose `EXERCISE` name doesn't resolve to a real exercise in the target install is skipped entirely (not created). Within a resolved row, an individual target name that doesn't resolve is skipped for just that one entry. The import result reports counts of both kinds of skips — tell the user if anything was skipped, don't silently swallow it.

## Generating this file

If asked to build/edit a KNS tree structure file:
1. Get the exact `fullName` for every exercise involved (ask the user for an exported exercises CSV, or an export of this same KNS.TREE structure format, if you don't already know the exact assembled names).
2. Keep relations **reciprocal** where it makes sense: if PULL UP lists WEIGHTED PULL UP under progressions, WEIGHTED PULL UP should list PULL UP under regressions (and `alters` should match on both sides). KNST.FIXER's AUTO-FIX ONESIDED in-app can also clean up one-sided gaps after import — you don't have to get every reciprocal perfect by hand.
3. Prefer ADD ONLY as the recommended import mode when generating incremental additions; only suggest OVERRIDE if the user explicitly wants the file to replace what's there.
