## Purpose

All application source code for GYMR (BeyondPerformance) — Flutter workout tracker.

## Ownership

- Scope: entire `lib/` tree — Dart source, providers, database, services, logic.
- Owns the application layer: widget tree, state management, business logic, database schema, and services.
- No code outside `lib/` is application logic (platform scaffolds, build config, assets live at project root).

## Local Contracts

- All source lives under `lib/`. Imports use `package:beyond_performance/...` for intra-project references.
- Business logic (`lib/logic/`) must be pure Dart (no Flutter dependency) where possible.
- UI code lives in `lib/ui/`. No Flutter widgets outside this subtree.
- Riverpod providers live in `lib/providers/`. Screens read from providers — providers never import screens.
- Drift schema lives in `lib/database/`. Generated code (`database.g.dart`) is not hand-edited.
- Services (`lib/services/`) are stateless — no Riverpod dependency, no Flutter widget imports.

## Work Guidance

- Follow the DOX chain before editing: read root AGENTS.md → lib/AGENTS.md → the child AGENTS.md for the specific subtree you're touching.
- After every meaningful change, run a DOX pass: update nearest owning docs, refresh affected Child DOX Indexes, remove stale/contradictory text.
- Fast iteration loop: implement → user hot restarts on device → verify → repeat. No formal test suite.

## Verification

- No formal testing framework exists. Verification is by hot restart + visual inspection on Redmi Note 8 Pro.
- Catch compile errors (unescaped `$`, runSelect args, provider types) before telling the user to hot-restart.

## Child DOX Index

- `lib/ui/AGENTS.md` — UI layer (screens, widgets, scaffold, styles)
- `lib/providers/AGENTS.md` — Riverpod providers (state management)
- `lib/logic/AGENTS.md` — Business logic (calculators, chart models, progression)
- `lib/database/AGENTS.md` — Drift database schema, migrations, generated code
- `lib/services/AGENTS.md` — Export/import and service layer
