import 'dart:io';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

// --- Modular Exercise Schema ---

class BaseExercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get prefixes => text().nullable()();
  TextColumn get implements => text().nullable()();
  TextColumn get bodyPositions => text().nullable()();
  TextColumn get suffixes => text().nullable()();
  TextColumn get primaryMuscleGroup => text().nullable()();
  TextColumn get secondaryMuscleGroup => text().nullable()();
  TextColumn get field => text().nullable()();
  TextColumn get tissueType => text().nullable()();
  TextColumn get tissueName => text().nullable()();
  IntColumn get numPhases =>
      integer().withDefault(const Constant(1)).nullable()();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();
  TextColumn get phaseDescriptions => text().nullable()();

  TextColumn get intention => text().nullable()();
  TextColumn get patternType => text().nullable()();
  TextColumn get complexMetadata => text().nullable()();
  BoolColumn get isUnilateral => boolean().withDefault(const Constant(false))();

  @override
  List<String> get customConstraints =>
      ['UNIQUE(name, prefixes, implements, body_positions, suffixes)'];
}

class Prefixes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
}

class Suffixes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
}

class ExerciseVariants extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get baseId => integer().references(BaseExercises, #id)();
  IntColumn get prefixId => integer().nullable().references(Prefixes, #id)();
  IntColumn get suffixId => integer().nullable().references(Suffixes, #id)();

  @override
  List<String> get customConstraints =>
      ['UNIQUE(base_id, prefix_id, suffix_id)'];
}

// --- Progression Graph ---

enum ProgressionType { predecessor, successor, equal, weaknessSupport }

class ProgressionEdges extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get fromVariantId => integer().references(ExerciseVariants, #id)();
  IntColumn get toVariantId => integer().references(ExerciseVariants, #id)();
  IntColumn get type => intEnum<ProgressionType>()();
}

// --- Workout Logging ---

class WorkoutLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  IntColumn get durationMinutes => integer().nullable()();
  DateTimeColumn get workoutStartTime => dateTime().nullable()();
  IntColumn get accumulatedSeconds =>
      integer().withDefault(const Constant(0))();
  TextColumn get notes => text().nullable()();
}

class WorkoutSets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get logId => integer().references(WorkoutLogs, #id)();
  IntColumn get baseExerciseId => integer().references(BaseExercises, #id)();

  RealColumn get weight => real()();
  RealColumn get reps => real()();
  RealColumn get rpe => real().nullable()();
  RealColumn get rir => real().nullable()();
  IntColumn get technique => integer().nullable()();
  IntColumn get failurePhase => integer().nullable()();
  IntColumn get restTimeSeconds => integer().nullable()();

  TextColumn get notes => text().nullable()();
  TextColumn get trackName => text().nullable()();
  IntColumn get hypeLevel => integer().nullable()();
  BoolColumn get isPrSong => boolean().withDefault(const Constant(false))();
  BoolColumn get isPr => boolean().withDefault(const Constant(false))();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
  TextColumn get complexMetadata => text().nullable()();
  TextColumn get priority => text().nullable()();
  TextColumn get supersetGroupId => text().nullable()();
  TextColumn get supersetName => text().nullable()();
}

// --- Somatic Feedback ---

class DiscomfortTags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
}

class DiscomfortLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get setId =>
      integer().references(WorkoutSets, #id, onDelete: KeyAction.cascade)();
  TextColumn get description => text()();
  IntColumn get intensity => integer().nullable()();
}

class DiscomfortLogTags extends Table {
  IntColumn get logId =>
      integer().references(DiscomfortLogs, #id, onDelete: KeyAction.cascade)();
  IntColumn get tagId =>
      integer().references(DiscomfortTags, #id, onDelete: KeyAction.cascade)();

  @override
  List<String> get customConstraints => ['PRIMARY KEY (log_id, tag_id)'];
}

// --- Blueprints ---

class Blueprints extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get intention => text()();
  DateTimeColumn get createdAt =>
      dateTime().nullable().withDefault(currentDateAndTime)();
}

class BlueprintExercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get blueprintId => integer().references(Blueprints, #id)();
  IntColumn get baseExerciseId => integer().references(BaseExercises, #id)();
  TextColumn get targetSetsReps => text().nullable()();
  IntColumn get orderIndex => integer()();
  TextColumn get priority => text().nullable()();
  TextColumn get supersetGroupId => text().nullable()();
  TextColumn get supersetName => text().nullable()();
}

// --- Overarching Planning (OVARCH.PLN) ---

class TrainingPlans extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class PlanWeeks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get planId =>
      integer().references(TrainingPlans, #id, onDelete: KeyAction.cascade)();
  IntColumn get weekNumber => integer()();
  TextColumn get purpose => text().nullable()();
}

class PlanDays extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get weekId =>
      integer().references(PlanWeeks, #id, onDelete: KeyAction.cascade)();
  IntColumn get dayNumber => integer()();
  IntColumn get blueprintId =>
      integer().nullable().references(Blueprints, #id)();
  TextColumn get label => text().nullable()(); // e.g., "Push A"
}

class PlanDayBlocks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get dayId =>
      integer().references(PlanDays, #id, onDelete: KeyAction.cascade)();
  IntColumn get blockId =>
      integer().references(WorkoutBlocks, #id, onDelete: KeyAction.cascade)();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();
  TextColumn get notes => text().nullable()();
}

// --- Anthropometric Data ---

class AnthropometricLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  TextColumn get label => text()();
  RealColumn get value => real()();
  TextColumn get unit => text()();
  BoolColumn get isFlexed => boolean().withDefault(const Constant(false))();
  BoolColumn get isPumped => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// --- NEW: Theme Personalization ---

class ThemeSettings extends Table {
  TextColumn get key => text()();
  TextColumn get colorHex => text().nullable()();
  TextColumn get value => text().nullable()();

  @override
  Set<Column> get primaryKey => {key};
}

// --- Global Batch Definitions ---

class BatchDefinitions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// --- Workout Blocks (replaces mock WB editor) ---

class WorkoutBlocks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get intention => text().nullable()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class WorkoutBlockKns extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get blockId =>
      integer().references(WorkoutBlocks, #id, onDelete: KeyAction.cascade)();
  IntColumn get baseExerciseId => integer().references(BaseExercises, #id)();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();
  TextColumn get utilities => text().nullable()(); // JSON array
  TextColumn get batchName => text().nullable()();
  TextColumn get metadata => text().nullable()(); // JSON for extra fields
}

class WorkoutBlockSets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get knsId =>
      integer().references(WorkoutBlockKns, #id, onDelete: KeyAction.cascade)();
  IntColumn get setNumber => integer()();
  RealColumn get repsMin => real().nullable()();
  RealColumn get repsMax => real().nullable()();
  RealColumn get pload => real().nullable()();
  RealColumn get rpe => real().nullable()();
  RealColumn get rir => real().nullable()();
  TextColumn get setIntention => text().nullable()();
  TextColumn get side => text().nullable()(); // "RIGHT"/"LEFT" for unilateral
  TextColumn get tags => text().nullable()(); // JSON array
  TextColumn get metadata => text().nullable()(); // JSON for extra fields
}

// --- Database Access ---

@DriftDatabase(tables: [
  BaseExercises,
  Prefixes,
  Suffixes,
  ExerciseVariants,
  ProgressionEdges,
  WorkoutLogs,
  WorkoutSets,
  DiscomfortTags,
  DiscomfortLogs,
  DiscomfortLogTags,
  Blueprints,
  BlueprintExercises,
  TrainingPlans,
  PlanWeeks,
  PlanDays,
  PlanDayBlocks,
  AnthropometricLogs,
  ThemeSettings,
  WorkoutBlocks,
  WorkoutBlockKns,
  WorkoutBlockSets,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // For tests only: pass an in-memory NativeDatabase instead of the real
  // on-disk file, so smoke tests never touch a user's actual data.
  AppDatabase.forTesting(QueryExecutor executor) : super(executor);

  @override
  int get schemaVersion => 29;

  // --- Bidirectional Relational Integrity ---

  Future<void> syncBidirectionalRelations(
      int exerciseId, Map<String, dynamic> newMeta) async {
    final exercise = await (select(baseExercises)
          ..where((t) => t.id.equals(exerciseId)))
        .getSingle();
    final String currentName = exercise.fullName;
    final allEx = await select(baseExercises).get();

    final categories = {
      "progressions": "regressions",
      "regressions": "progressions",
      "alters": "alters"
    };

    await transaction(() async {
      for (var entry in categories.entries) {
        final category = entry.key;
        final opposite = entry.value;
        final targets = List<String>.from(newMeta[category] ?? []);

        for (var ex in allEx) {
          if (ex.id == exerciseId) continue;
          final targetMeta = ex.parsedComplexMetadata;
          final List<String> relationList =
              List<String>.from(targetMeta[opposite] ?? []);

          final String targetFullName = ex.fullName;
          bool isTarget = targets.contains(targetFullName);
          bool hasRelation = relationList.contains(currentName);

          if (isTarget && !hasRelation) {
            relationList.add(currentName);
            targetMeta[opposite] = relationList;
            await (update(baseExercises)..where((t) => t.id.equals(ex.id)))
                .write(BaseExercisesCompanion(
                    complexMetadata: Value(jsonEncode(targetMeta))));
          } else if (!isTarget && hasRelation) {
            relationList.remove(currentName);
            targetMeta[opposite] = relationList;
            await (update(baseExercises)..where((t) => t.id.equals(ex.id)))
                .write(BaseExercisesCompanion(
                    complexMetadata: Value(jsonEncode(targetMeta))));
          }
        }
      }
    });
  }

  // Workout Blocks / plan_day_blocks are not version-gated in onUpgrade:
  // they're created and column-patched here in beforeOpen instead, so a DB
  // file restored from an older backup (not just a normal version upgrade)
  // still self-heals. That means their real schema history lives in this
  // method, not in the onUpgrade "from < X" ladder above.
  //
  // beforeOpen runs on every app launch, so naively re-running ALTER TABLE
  // ADD COLUMN forever and swallowing the resulting "duplicate column"
  // error hides genuine failures. Check first instead.
  Future<void> _addColumnIfMissing(
      String table, String column, String columnDef) async {
    final cols = await customSelect('PRAGMA table_info($table)').get();
    final exists = cols.any((row) => row.data['name'] == column);
    if (!exists) {
      await customStatement('ALTER TABLE $table ADD COLUMN $column $columnDef');
    }
  }

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
      },
      onUpgrade: (m, from, to) async {
        // En instalaciones de cero, onCreate crea todo al esquema 19.
        // Estas migraciones solo sirven para usuarios que actualizan versiones viejas.
        if (from < 7) await m.createTable(anthropometricLogs);
        if (from < 8) await m.createTable(themeSettings);
        if (from < 16) {
          try {
            await customStatement(
                'ALTER TABLE workout_sets ADD COLUMN is_completed BOOLEAN NOT NULL DEFAULT 0');
          } catch (_) {}
          try {
            await customStatement(
                'ALTER TABLE workout_sets ADD COLUMN order_index INTEGER NOT NULL DEFAULT 0');
          } catch (_) {}
        }
        if (from < 17) {
          try {
            await customStatement(
                'ALTER TABLE base_exercises ADD COLUMN order_index INTEGER NOT NULL DEFAULT 0');
          } catch (_) {}
        }

        // MIGRATION_SAFETY: El alterTable(workoutSets) se movió al final de onUpgrade (v18 -> v22+)
        // para asegurar que todas las columnas nuevas existan antes de intentar recrear la tabla.

        if (from < 19) {
          try {
            await customStatement(
                'ALTER TABLE workout_sets ADD COLUMN complex_metadata TEXT');
          } catch (_) {}
          try {
            await customStatement(
                'ALTER TABLE base_exercises ADD COLUMN complex_metadata TEXT');
          } catch (_) {}
        }
        if (from < 20) {
          try {
            await customStatement(
                'ALTER TABLE base_exercises ADD COLUMN is_unilateral BOOLEAN NOT NULL DEFAULT 0');
          } catch (_) {}
        }
        if (from < 21) {
          try {
            await customStatement(
                'ALTER TABLE workout_sets ADD COLUMN priority TEXT');
          } catch (_) {}
          try {
            await customStatement(
                'ALTER TABLE blueprint_exercises ADD COLUMN priority TEXT');
          } catch (_) {}
        }
        if (from < 22) {
          try {
            await customStatement(
                'ALTER TABLE workout_sets ADD COLUMN superset_group_id TEXT');
          } catch (_) {}
          try {
            await customStatement(
                'ALTER TABLE workout_sets ADD COLUMN superset_name TEXT');
          } catch (_) {}
          try {
            await customStatement(
                'ALTER TABLE blueprint_exercises ADD COLUMN superset_group_id TEXT');
          } catch (_) {}
          try {
            await customStatement(
                'ALTER TABLE blueprint_exercises ADD COLUMN superset_name TEXT');
          } catch (_) {}
        }

        if (from < 28) {
          // PNDEV 43 v2: Fix NULL order_index / is_unilateral in base_exercises
          // caused by Companion.insert() without orderIndex field
          await customStatement(
              'UPDATE base_exercises SET order_index = 0 WHERE order_index IS NULL');
          await customStatement(
              'UPDATE base_exercises SET is_unilateral = 0 WHERE is_unilateral IS NULL');
        }

        if (from < 23) {
          try {
            await customStatement(
                'ALTER TABLE workout_logs ADD COLUMN duration_minutes INTEGER');
          } catch (_) {}
          try {
            await customStatement(
                'ALTER TABLE workout_logs ADD COLUMN workout_start_time INTEGER');
          } catch (_) {}
          try {
            await customStatement(
                'ALTER TABLE workout_logs ADD COLUMN accumulated_seconds INTEGER NOT NULL DEFAULT 0');
          } catch (_) {}
        }

        if (from < 24) {
          try {
            await customStatement(
                'ALTER TABLE workout_sets ADD COLUMN rir REAL');
          } catch (_) {}
        }

        if (from < 25) {
          await m.createTable(trainingPlans);
          await m.createTable(planWeeks);
          await m.createTable(planDays);
        }

        if (from < 26) {
          try {
            await customStatement(
                'ALTER TABLE training_plans ADD COLUMN is_pinned BOOLEAN NOT NULL DEFAULT 0');
          } catch (_) {}
        }

        if (from < 27) {
          // SOMATIC OVERHAUL v27: merge discomfort_logs + discomfort_tags + discomfort_log_tags into somatic_logs
          // + new folder tables

          // Create new denormalized somatic_logs table (tags stored as comma-separated TEXT)
          await customStatement('''
            CREATE TABLE IF NOT EXISTS somatic_logs (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              set_id INTEGER REFERENCES workout_sets(id) ON DELETE CASCADE,
              description TEXT NOT NULL,
              spectrum_value INTEGER NOT NULL DEFAULT 0,
              tags TEXT,
              created_at INTEGER NOT NULL DEFAULT 0
            )
          ''');

          // Create somatic_folders table
          await customStatement('''
            CREATE TABLE IF NOT EXISTS somatic_folders (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              created_at INTEGER NOT NULL DEFAULT 0
            )
          ''');

          // Create somatic_folder_logs (many-to-many)
          await customStatement('''
            CREATE TABLE IF NOT EXISTS somatic_folder_logs (
              folder_id INTEGER NOT NULL REFERENCES somatic_folders(id) ON DELETE CASCADE,
              log_id INTEGER NOT NULL REFERENCES somatic_logs(id) ON DELETE CASCADE,
              PRIMARY KEY (folder_id, log_id)
            )
          ''');

          // Create spectrum_references table (user-editable descriptions per value)
          await customStatement('''
            CREATE TABLE IF NOT EXISTS spectrum_references (
              value INTEGER PRIMARY KEY,
              label TEXT NOT NULL,
              description TEXT NOT NULL DEFAULT ""
            )
          ''');

          // Insert default spectrum references (-10 to +10)
          await customStatement('''
            INSERT OR IGNORE INTO spectrum_references (value, label, description) VALUES
            (-10, 'EXCRUCIATING', 'Unbearable pain. Cannot perform any movement.'),
            (-9, 'SEVERE', 'Debilitating pain. Movement severely restricted.'),
            (-8, 'INTENSE', 'Very strong pain. Focus completely disrupted.'),
            (-7, 'STRONG', 'Significant pain. Movement noticeably affected.'),
            (-6, 'HIGH', 'Considerable pain. Can push through with effort.'),
            (-5, 'MODERATE', 'Clear discomfort. Performance starts to suffer.'),
            (-4, 'NOTICEABLE', 'Pain is present but manageable.'),
            (-3, 'MILD', 'Slight ache. Barely affects performance.'),
            (-2, 'TRACE', 'Very slight sensation. Almost imperceptible.'),
            (-1, 'MINIMAL', 'Faint awareness of the area. No pain.'),
            (0, 'NEUTRAL', 'Baseline. No sensation either way.'),
            (1, 'EASY', 'Slight positive sensation. Area feels loose.'),
            (2, 'GOOD', 'Noticeable positive feedback. Feels healthy.'),
            (3, 'FRESH', 'Area feels springy and responsive.'),
            (4, 'BOUNCY', 'Tissue feels resilient and elastic.'),
            (5, 'RECOVERED', 'Full recovery sensation. Ready for load.'),
            (6, 'STRONG', 'Area feels robust and capable.'),
            (7, 'ENERGIZED', 'Positive energy flowing through the area.'),
            (8, 'POWERFUL', 'Feeling of strength and readiness.'),
            (9, 'EXCELLENT', 'Peak recovery state. Best condition.'),
            (10, 'PERFECT', 'Absolute ideal state. Could not feel better.')
          '''
              .replaceAll('\n', ' ')
              .replaceAll('\t', ' '));

          // Migrate existing discomfort_logs: intensity → negative spectrum_value
          await customStatement('''
            INSERT INTO somatic_logs (set_id, description, spectrum_value, tags, created_at)
            SELECT dl.set_id, dl.description, COALESCE(-(dl.intensity), -5), '', CAST(strftime('%s', 'now') * 1000 AS INTEGER)
            FROM discomfort_logs dl
          ''');

          // Drop old tables
          await customStatement('DROP TABLE IF EXISTS discomfort_log_tags');
          await customStatement('DROP TABLE IF EXISTS discomfort_tags');
          await customStatement('DROP TABLE IF EXISTS discomfort_logs');
        }

        // Ejecutar alterTable al final si venimos de una versión donde se necesitaba (v18)
        if (from < 18) {
          try {
            await m.alterTable(TableMigration(workoutSets));
          } catch (e) {
            debugPrint("Warning during workoutSets alterTable: $e");
          }
        }
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
        // Safety net: create blueprint_exercises if missing (legacy DBs that predate the table)
        await customStatement('''
          CREATE TABLE IF NOT EXISTS blueprint_exercises (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            blueprint_id INTEGER NOT NULL REFERENCES blueprints(id),
            base_exercise_id INTEGER NOT NULL REFERENCES base_exercises(id),
            target_sets_reps TEXT,
            order_index INTEGER NOT NULL,
            priority TEXT,
            superset_group_id TEXT,
            superset_name TEXT
          )
        ''');
        // Safety net for blueprints table (legacy DBs that predate v25)
        await customStatement('''
          CREATE TABLE IF NOT EXISTS blueprints (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            intention TEXT,
            created_at INTEGER NOT NULL DEFAULT 0
          )
        ''');

        // Auxiliary raw-SQL table: batch_definitions (no Drift DAO)
        await customStatement('''
          CREATE TABLE IF NOT EXISTS batch_definitions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            created_at INTEGER NOT NULL DEFAULT 0
          )
        ''');
        // Seed from existing workout_sets complex_metadata — this scans
        // every row's JSON metadata, so only run it on a fresh install or
        // version upgrade (details.versionBefore != versionNow), not on
        // every normal app launch. INSERT OR IGNORE means existing users
        // already have this seeded; re-running it on every open was pure
        // wasted full-table-scan cost with schema-versions growing.
        if (details.versionBefore != details.versionNow) {
          await customStatement('''
            INSERT OR IGNORE INTO batch_definitions (name, created_at)
            SELECT DISTINCT
              json_extract(complex_metadata, '\$.batch'),
              CAST(strftime('%s', 'now') * 1000 AS INTEGER)
            FROM workout_sets
            WHERE complex_metadata IS NOT NULL
              AND json_extract(complex_metadata, '\$.batch') IS NOT NULL
              AND json_extract(complex_metadata, '\$.batch') != ''
          ''');
        }

        // Workout Blocks tables (safety net for legacy DBs)
        await customStatement('''
          CREATE TABLE IF NOT EXISTS workout_blocks (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            intention TEXT,
            description TEXT,
            created_at INTEGER NOT NULL DEFAULT 0,
            deleted_at INTEGER
          )
        ''');
        await customStatement('''
          CREATE TABLE IF NOT EXISTS workout_block_kns (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            block_id INTEGER NOT NULL REFERENCES workout_blocks(id) ON DELETE CASCADE,
            base_exercise_id INTEGER NOT NULL REFERENCES base_exercises(id),
            order_index INTEGER NOT NULL DEFAULT 0,
            utilities TEXT,
            batch_name TEXT,
            metadata TEXT
          )
        ''');
        await customStatement('''
          CREATE TABLE IF NOT EXISTS workout_block_sets (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            kns_id INTEGER NOT NULL REFERENCES workout_block_kns(id) ON DELETE CASCADE,
            set_number INTEGER NOT NULL,
            reps_min REAL,
            reps_max REAL,
            pload REAL,
            rpe REAL,
            rir REAL,
            set_intention TEXT,
            side TEXT,
            tags TEXT,
            metadata TEXT
          )
        ''');
        await customStatement('''
          CREATE TABLE IF NOT EXISTS plan_day_blocks (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            day_id INTEGER NOT NULL REFERENCES plan_days(id) ON DELETE CASCADE,
            block_id INTEGER NOT NULL REFERENCES workout_blocks(id) ON DELETE CASCADE,
            order_index INTEGER NOT NULL DEFAULT 0,
            notes TEXT
          )
        ''');
        // Repair legacy plan_day_blocks schemas that used day/block aliases before
        // the Drift table was standardized to day_id / block_id.
        await _addColumnIfMissing(
            'plan_day_blocks', 'day_id', 'INTEGER NOT NULL DEFAULT 0');
        await _addColumnIfMissing(
            'plan_day_blocks', 'plan_day_id', 'INTEGER NOT NULL DEFAULT 0');
        await _addColumnIfMissing(
            'plan_day_blocks', 'block_id', 'INTEGER NOT NULL DEFAULT 0');
        await _addColumnIfMissing(
            'plan_day_blocks', 'workout_block_id', 'INTEGER NOT NULL DEFAULT 0');
        await _addColumnIfMissing(
            'plan_day_blocks', 'order_index', 'INTEGER NOT NULL DEFAULT 0');
        await _addColumnIfMissing('plan_day_blocks', 'notes', 'TEXT');
        for (final alias in const ['plan_day_id', 'plan_days_id', 'plan_day']) {
          try {
            await customStatement('''
              UPDATE plan_day_blocks
              SET day_id = $alias
              WHERE (day_id IS NULL OR day_id = 0) AND $alias IS NOT NULL
            ''');
          } catch (_) {}
        }
        try {
          await customStatement('''
            UPDATE plan_day_blocks
            SET plan_day_id = day_id
            WHERE (plan_day_id IS NULL OR plan_day_id = 0) AND day_id IS NOT NULL
          ''');
        } catch (_) {}
        for (final alias in const [
          'workout_block_id',
          'workout_blocks_id',
          'block'
        ]) {
          try {
            await customStatement('''
              UPDATE plan_day_blocks
              SET block_id = $alias
              WHERE (block_id IS NULL OR block_id = 0) AND $alias IS NOT NULL
            ''');
          } catch (_) {}
        }
        try {
          await customStatement('''
            UPDATE plan_day_blocks
            SET workout_block_id = block_id
            WHERE (workout_block_id IS NULL OR workout_block_id = 0) AND block_id IS NOT NULL
          ''');
        } catch (_) {}
        // Add missing columns (safe for hot restart where beforeOpen doesn't re-run)
        await _addColumnIfMissing('workout_blocks', 'intention', 'TEXT');
        await _addColumnIfMissing('workout_blocks', 'description', 'TEXT');
        await _addColumnIfMissing('workout_blocks', 'deleted_at', 'INTEGER');
        await _addColumnIfMissing('workout_blocks', 'folder', 'TEXT');
        await _addColumnIfMissing('workout_block_kns', 'utilities', 'TEXT');
        await _addColumnIfMissing('workout_block_kns', 'batch_name', 'TEXT');
        await _addColumnIfMissing('workout_block_kns', 'metadata', 'TEXT');
        await _addColumnIfMissing('workout_block_sets', 'reps_min', 'REAL');
        await _addColumnIfMissing('workout_block_sets', 'reps_max', 'REAL');
        await _addColumnIfMissing('workout_block_sets', 'pload', 'REAL');
        await _addColumnIfMissing('workout_block_sets', 'rpe', 'REAL');
        await _addColumnIfMissing('workout_block_sets', 'rir', 'REAL');
        await _addColumnIfMissing(
            'workout_block_sets', 'set_intention', 'TEXT');
        await _addColumnIfMissing('workout_block_sets', 'side', 'TEXT');
        await _addColumnIfMissing('workout_block_sets', 'tags', 'TEXT');
        await _addColumnIfMissing('workout_block_sets', 'metadata', 'TEXT');
        await _backfillFolderFromLegacyWbStore();
      },
    );
  }

  // One-time bridge for the migration off the legacy wb_store/wb_kns_store
  // JSON blobs. workout_blocks is now the sole source of truth for the WB
  // list (including `folder`, which used to live only in the wb_store
  // blob). Two things to backfill for any install that still has old
  // wb_store data:
  //   1. A block that only ever existed in wb_store (very old install that
  //      predates the real table) — insert it.
  //   2. `folder` on a block that already exists in workout_blocks but
  //      never got its folder copied over.
  // Once that's done, the legacy tables have nothing left depending on
  // them, so drop them. Safe to run on every launch: the backfill loop is
  // a no-op the moment wb_store no longer exists, and DROP TABLE IF EXISTS
  // is a no-op once already dropped.
  Future<void> _backfillFolderFromLegacyWbStore() async {
    try {
      final rows =
          await customSelect('SELECT data FROM wb_store WHERE id = 1').get();
      if (rows.isNotEmpty) {
        final raw = rows.first.data['data'] as String?;
        if (raw != null && raw.isNotEmpty) {
          final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
          for (final entry in list) {
            final rawId = entry['id']?.toString().replaceAll('wb_', '');
            final blockId = int.tryParse(rawId ?? '');
            if (blockId == null) continue;
            final name = entry['name']?.toString();
            if (name == null || name.isEmpty) continue;
            final folder = entry['folder']?.toString();
            final createdAt = entry['createdAt'] is int
                ? entry['createdAt'] as int
                : int.tryParse(entry['createdAt']?.toString() ?? '') ??
                    blockId;

            await customStatement(
              'INSERT OR IGNORE INTO workout_blocks (id, name, folder, created_at, deleted_at) VALUES (?, ?, ?, ?, 0)',
              [blockId, name, folder, createdAt],
            );
            if (folder != null && folder.isNotEmpty) {
              await customStatement(
                "UPDATE workout_blocks SET folder = ? WHERE id = ? AND (folder IS NULL OR folder = '')",
                [folder, blockId],
              );
            }
          }
        }
      }
    } catch (_) {
      // wb_store may not exist — nothing to backfill.
    }
    try {
      await customStatement('DROP TABLE IF EXISTS wb_store');
    } catch (_) {}
    try {
      await customStatement('DROP TABLE IF EXISTS wb_kns_store');
    } catch (_) {}
  }
}

final Map<String, dynamic> _defaultComplexMetadata = {
  "regressions": [],
  "progressions": [],
  "alters": [],
  "particular_toggles": [],
  "description": ""
};

// jsonDecode is synchronous and complexMetadata is read on every rebuild
// (search/filter loops over the full exercise list call this per item, per
// keystroke). Cache by raw JSON string so repeated reads of the same value
// don't reparse. Safe to share the returned map across callers: nothing in
// the codebase mutates the result, it's read-only lookups everywhere.
final Map<String, Map<String, dynamic>> _complexMetadataCache = {};

extension BaseExerciseExtension on BaseExercise {
  Map<String, dynamic> get parsedComplexMetadata {
    final raw = complexMetadata;
    if (raw == null || raw.isEmpty) {
      return _defaultComplexMetadata;
    }
    final cached = _complexMetadataCache[raw];
    if (cached != null) return cached;
    Map<String, dynamic> result;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      // Ensure all keys exist with correct types
      _defaultComplexMetadata.forEach((key, value) {
        decoded.putIfAbsent(key, () => value);
      });
      result = decoded;
    } catch (_) {
      result = _defaultComplexMetadata;
    }
    _complexMetadataCache[raw] = result;
    return result;
  }

  List<Map<String, dynamic>> get _parsedBodyPositions {
    if (bodyPositions == null || bodyPositions!.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(bodyPositions!);
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return bodyPositions!
          .split(',')
          .where((s) => s.isNotEmpty)
          .map((e) => {"v": e, "s": true})
          .toList();
    }
  }

  List<String> get bodyPositionTags {
    return _parsedBodyPositions
        .where((p) => p["s"] == false)
        .map((p) => p["v"] as String)
        .toList();
  }

  String get fullName {
    final List<String> parts = [];
    final activePositions = _parsedBodyPositions
        .where((p) => p["s"] == true)
        .map((p) => p["v"] as String);
    if (activePositions.isNotEmpty) parts.add(activePositions.join(' '));
    if (implements != null && implements!.isNotEmpty)
      parts.add(implements!.replaceAll(',', ' '));
    if (prefixes != null && prefixes!.isNotEmpty)
      parts.add(prefixes!.replaceAll(',', ' '));
    parts.add(name);
    if (suffixes != null && suffixes!.isNotEmpty)
      parts.add(suffixes!.replaceAll(',', ' '));
    return parts.join(' ').trim().toUpperCase();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));

    // INFALIBLE: Drift crea el archivo si no existe.
    // Al ser una instalación nueva, onCreate() generará todas las tablas.
    return NativeDatabase(file);
  });
}
