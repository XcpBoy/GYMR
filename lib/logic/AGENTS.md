## Purpose

Pure business logic, calculation models, and data transformations for GYMR.

## Ownership

- Scope: `lib/logic/` — 3 Dart files (calculator, chart_models, progression_graph).
- Owns: PR calculations, volume computations, 1RM estimates, chart data models, strength curve progression graphs.
- Does NOT own UI rendering, state management, or database queries.

## Local Contracts

- **Pure Dart only** — no Flutter/UI dependency where possible. If logic needs Flutter imports, pull Flutter-free types down into this layer instead.
- Functions must be testable in isolation (pure input → deterministic output). No side effects.
- Chart models (`chart_models.dart`) define the data shape used by `fl_chart` widgets.
- Progression graph logic (`progression_graph.dart`) computes strength curves from workout history.
- Calculator (`calculator.dart`) handles PR calcs, volume, 1RM estimates, and related math.

## Work Guidance

- New business logic goes in a new file under `lib/logic/`.
- If the logic needs shared state beyond its parameters, it doesn't belong here — move to a provider instead.
- Prefer extension methods on existing types over new utility classes for domain-specific transformations.

## Verification

- (no formal testing framework exists. Verify by checking the UI that consumes this logic on hot restart.)

## Child DOX Index

- (no child AGENTS.md files under lib/logic/)
