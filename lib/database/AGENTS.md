## Purpose

Drift (SQLite) database schema, migrations, and generated code for GYMR.

## Ownership

- Scope: `lib/database/` — 2 files (database.dart schema, database.g.dart generated code).
- Owns: schema definitions (`extends Table` classes), migration logic in `beforeOpen`, all `CREATE TABLE`/`ALTER TABLE` statements.
- The generated `database.g.dart` is owned by Drift's build_runner — do NOT hand-edit.

## Local Contracts

- **Schema** defined via Drift's `extends Table` classes in `database.dart`.
- **Generated code** in `database.g.dart` is never hand-edited. Regenerate with `dart run build_runner build --delete-conflicting-outputs`.
- **New tables**: add `CREATE TABLE IF NOT EXISTS` in `beforeOpen` for legacy DB compatibility. Existing DBs that predate the table won't have it.
- **New columns**: use `ALTER TABLE` with `try/catch` in `beforeOpen` for existing DBs. Add with `NOT NULL DEFAULT <value>` when adding to existing tables.
- **Migrations** are additive only — no destructive schema changes without explicit user direction.
- **Data class naming**: Drift strips trailing 's' from table names for the data class. Table `WorkoutBlockKns` → class `WorkoutBlockKn`. Use the data class name (not the table name) in `StreamBuilder` type parameters.
- **Companion classes** (e.g., `WorkoutSetsCompanion`) come from `database.dart`, NOT from `package:drift/drift.dart`. Only `drift.Value`, `drift.OrderingTerm`, etc. need the `drift.` prefix.
- **`customSelect`** does NOT accept `?` positional parameters — embed values via string interpolation.
- **`beforeOpen` callback** runs every DB open and is the right place for safety-net table creation: `CREATE TABLE IF NOT EXISTS` + `ALTER TABLE` wrapped in `try/catch`.

## Work Guidance

- After schema changes, run: `dart run build_runner build --delete-conflicting-outputs`.
- Verify the generated classes compile before telling the user to hot-restart.
- When adding a Table class mid-project, ALWAYS add the corresponding `CREATE TABLE IF NOT EXISTS` in `beforeOpen`.

## Verification

- Hot restart and verify: StreamProvider using `db.select().watch()` does not throw `SqliteException: no such table`.
- Test CRUD: add exercise, log workout, navigate away and back.

## Child DOX Index

- (no child AGENTS.md files under lib/database/)
