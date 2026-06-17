## Purpose

Application services — export/import, file I/O, and cross-cutting utilities for GYMR.

## Ownership

- Scope: `lib/services/` — currently 1 file (export_service.dart).
- Owns: XLSX export/import, CSV export/import, file sharing, file picking, and any future service modules.

## Local Contracts

- **Stateless classes or top-level functions** — no Riverpod dependency, no Flutter widget imports.
- File I/O services return absolute paths as `String` when creating files. Let the UI layer handle display.
- **XLSX export**: rename "Sheet1" to target name — do NOT create new sheets (creates an extra empty sheet).
- **XLSX import**: skip header row (index 0), filter empty rows.
- **Excel package**: use `import 'package:excel/excel.dart' hide Border;` when importing alongside Flutter widgets (conflicting `Border` class).
- Sharing via `share_plus` package. File picking via `file_picker` package.

## Work Guidance

- New service features follow the existing `export_service.dart` pattern: static method, returns `String?` (file path) or `Future<String?>`.
- Keep services decoupled from UI — return paths/data, let the UI handle display and user interaction.
- If a service needs state beyond its parameters, it doesn't belong here.

## Verification

- Hot restart + test: import a file from NEXUS, export data, verify the output file can be opened.
- Check that XLSX single-sheet rule is respected (no duplicate empty sheets).

## Child DOX Index

- (no child AGENTS.md files under lib/services/)
