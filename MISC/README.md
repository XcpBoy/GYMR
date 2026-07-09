# MISC

Loose files that don't belong in the app's source tree or the project root,
kept here instead of scattered across the repo. Nothing in `lib/` imports
or reads from this folder — it's excluded from the app build.

- `gymr_wbs (10).xlsx` — a leftover sample/exported Workout Blocks file.
  Not read by any code path; the app generates its own `gymr_wbs_<timestamp>.xlsx`
  files at export time (see `lib/services/export_service.dart`).
- `_lab_footer_backup.txt` — a manual backup of a widget that used to live
  in `lib/ui/`, kept here in case old content is ever needed for reference.
- `kindadencenthusk_deprecated_mock_prototype.dart` — an early prototype
  screen built against mock data classes, superseded by the real DB schema.
  Never imported anywhere; kept for reference instead of deleted outright.
