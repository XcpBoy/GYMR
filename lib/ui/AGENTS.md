## Purpose

All user interface screens, widgets, scaffold, navigation, and visual styles for GYMR.

## Ownership

- Scope: `lib/ui/` — 30 Dart files including screens, main scaffold, styles, widget modules, and charts subdirectory.
- Owns every visual component: user-facing screens, the main scaffold, navigation, theming UI, and all reusable widgets.
- Charts subdirectory (`lib/ui/charts/`) is included here — no separate AGENTS.md for it.

## Local Contracts

- Every screen is a `StatefulWidget` in its own file under `lib/ui/`.
- All screens use `ref` (Riverpod) for state access. `setState` is allowed ONLY for ephemeral UI state that doesn't need persistence.
- **Colors MUST come from `themeControllerProvider.getColor()`. Never hardcode `Colors.cyanAccent`, `Colors.amber`, etc.** Exceptions: `LabColors.primary` for primary accents, `Colors.grey[800]` for structural borders. Every new color-driven widget needs a `UI_TAG_*` key the user can configure in THEME.MDFYR.
- UI labels in English only — no Spanish strings in UI.
- No drag-and-drop requiring pointer precision. No keyboard shortcuts. No hover states. Mobile-first (touch input only).
- No raw JSON editors in metadata forms — always structured form fields (TextFields, dropdowns, chips).
- NEXUS export cards use `_buildExportCard` (SHARE + DOWNLOAD). Import cards use `_buildImportCard` (single IMPORT). Both use card style with left color border.

## Work Guidance

- **Copy C.WO → Modify**: new screens that share layout with existing ones start by copy-pasting the existing widget's BUILD METHOD, then making targeted changes. Pixel-identical widget trees — same `IntrinsicHeight > Row > Expanded` pattern, same `_buildGridInput` cell structure, same spacing and flex ratios.
- **Husk pattern**: for complex screen copies, copy the full source file, read line-by-line manually stripping business logic while keeping widget tree intact. No regex gutting.
- **Standard layout pattern**: `IntrinsicHeight > Row > Expanded` for grid inputs. Sets collapsible by default (tap name to expand/collapse; start expanded).
- **Block name ONLY in AppBar** — never duplicate in body.
- **After 3+ failed patches**: use `write_file` with full corrected content. Patches on corrupted bracket structures compound problems.
- **Before committing changes**: verify bracket balance by reading 10 lines before and after each edit.

## Verification

- Hot restart + visual inspection on Redmi Note 8 Pro.
- Check for: `_dependents.isEmpty` crash in modals (no `StatefulBuilder` in `showDialog`/`showModalBottomSheet`), `GestureDetector` inside `InkWell`, `ReorderableListView` children missing keys.
- No `Expanded` directly inside `MainScaffold.body` (needs a Column wrapper).
- `LabButton.onPressed` does NOT accept null — use `() {}` as no-op.

## Child DOX Index

- (no child AGENTS.md files under lib/ui/)
