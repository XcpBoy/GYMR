// Smoke tests for the Workout Blocks persistence path: create/rename/
// folder/delete, injection, export, and the "injected today" lookup that
// WB Projections relies on. Each of these had a real, silent bug found
// during the wb_store -> workout_blocks migration (folder never
// persisting, WB Projections' date filter never matching). These tests
// exist so a future change to this area fails loudly instead of only
// showing up by hand on a phone.
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;

import 'package:beyond_performance/database/database.dart';
import 'package:beyond_performance/providers/database_provider.dart';
import 'package:beyond_performance/ui/WO.Blocks.manager.dart';
import 'package:beyond_performance/services/ovarch_plan_injection_service.dart';
import 'package:beyond_performance/services/export_service.dart';

AppDatabase _testDb() => AppDatabase.forTesting(NativeDatabase.memory());

Future<int> _insertExercise(AppDatabase db, {bool isUnilateral = false}) {
  return db.into(db.baseExercises).insert(
        BaseExercisesCompanion.insert(
          name: 'Test Exercise',
          isUnilateral: drift.Value(isUnilateral),
        ),
      );
}

/// Inserts a workout_blocks row via raw SQL. `folder`/`deleted_at` are not
/// part of the compile-time WorkoutBlocks Drift table (they're added at
/// runtime by beforeOpen's ALTER TABLE safety net), so there's no generated
/// Companion field for them — this mirrors how production code writes
/// these two columns (WO.Blocks.manager.dart, export_service.dart).
Future<void> _insertBlock(AppDatabase db, int id, String name,
    {String? folder}) {
  return db.customStatement(
    'INSERT INTO workout_blocks (id, name, folder, created_at, deleted_at) VALUES (?, ?, ?, ?, 0)',
    [id, name, folder, DateTime.now().millisecondsSinceEpoch],
  );
}

void main() {
  group('WorkoutBlockListNotifier (WO.Blocks.manager)', () {
    test('add, rename, setFolder, remove persist to workout_blocks', () async {
      final db = _testDb();
      addTearDown(db.close);
      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(workoutBlockListProvider.notifier);
      await notifier.add('Push Day', folder: 'UPPER');

      var state = container.read(workoutBlockListProvider);
      expect(state, hasLength(1));
      expect(state.first.name, 'PUSH DAY');
      expect(state.first.folder, 'UPPER',
          reason:
              'folder must persist to workout_blocks, not just in-memory state');

      final id = state.first.id;
      final blockId = int.parse(id.replaceAll('wb_', ''));
      await notifier.rename(id, 'Push Day V2');
      await notifier.setFolder(id, 'CHANGED');
      state = container.read(workoutBlockListProvider);
      expect(state.first.name, 'PUSH DAY V2');
      expect(state.first.folder, 'CHANGED');

      // Re-read straight from the table (not from in-memory state) to catch
      // a write that updates `state` but never reaches the DB — exactly the
      // bug setFolder() had before the fix.
      final row = await db.customSelect(
        'SELECT name, folder FROM workout_blocks WHERE id = ?',
        variables: [drift.Variable(blockId)],
      ).getSingle();
      expect(row.data['name'], 'PUSH DAY V2');
      expect(row.data['folder'], 'CHANGED');

      await notifier.remove(id);
      state = container.read(workoutBlockListProvider);
      expect(state, isEmpty);
    });
  });

  group('OvarchPlanInjectionService', () {
    test('activeWorkoutBlocks + workoutBlockById see a created block',
        () async {
      final db = _testDb();
      addTearDown(db.close);

      await _insertBlock(db, 1, 'LEG DAY', folder: 'LOWER');

      final active = await OvarchPlanInjectionService.activeWorkoutBlocks(db);
      expect(active, hasLength(1));
      expect(active.first['name'], 'LEG DAY');

      final byId = await OvarchPlanInjectionService.workoutBlockById(db, 1);
      expect(byId, isNotNull);
      expect(byId!['name'], 'LEG DAY');
    });

    test(
        'injectWorkoutBlock writes sets tagged with injectedFromBlock, '
        'findable by the same date-range query WB Projections uses',
        () async {
      final db = _testDb();
      addTearDown(db.close);

      final exerciseId = await _insertExercise(db);
      const blockId = 42;
      await _insertBlock(db, blockId, 'PULL DAY');
      final knsId = await db.into(db.workoutBlockKns).insert(
            WorkoutBlockKnsCompanion.insert(
              blockId: blockId,
              baseExerciseId: exerciseId,
            ),
          );
      await db.into(db.workoutBlockSets).insert(
            WorkoutBlockSetsCompanion.insert(
              knsId: knsId,
              setNumber: 1,
              repsMax: const drift.Value(8),
              pload: const drift.Value(40),
            ),
          );

      final today = DateTime.now();
      await OvarchPlanInjectionService.injectWorkoutBlock(
        db,
        today,
        {'id': blockId, 'name': 'PULL DAY', 'intention': null},
      );

      final sets = await db.select(db.workoutSets).get();
      expect(sets, isNotEmpty,
          reason: 'injection should create at least one workout_sets row');
      expect(
          sets.first.complexMetadata, contains('"injectedFromBlock":$blockId'));

      // Same lookup pattern used by "VIEW WB PROJECTIONS" after the fix:
      // resolve today's logs via Drift's typed DateTime comparison, then
      // pull injectedFromBlock out of complex_metadata for those logs.
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayEnd =
          DateTime(today.year, today.month, today.day, 23, 59, 59);
      final logsToday = await (db.select(db.workoutLogs)
            ..where((t) => t.date.isBetweenValues(todayStart, todayEnd)))
          .get();
      expect(logsToday, isNotEmpty,
          reason:
              'the injected log must fall inside "today" per Drift\'s typed date comparison');

      final logIds = logsToday.map((l) => l.id).join(',');
      final injectedRows = await db
          .customSelect(
              "SELECT DISTINCT json_extract(ws.complex_metadata, '\$.injectedFromBlock') as block_id "
              "FROM workout_sets ws "
              "WHERE ws.log_id IN ($logIds) "
              "AND ws.complex_metadata LIKE '%injectedFromBlock%'")
          .get();
      final injectedBlockIds =
          injectedRows.map((r) => r.data['block_id'] as int).toSet();
      expect(injectedBlockIds, contains(blockId));
    });
  });

  group('ExportService', () {
    test('loadWorkoutBlocksCombinedData round-trips block, folder, and sets',
        () async {
      final db = _testDb();
      addTearDown(db.close);

      final exerciseId = await _insertExercise(db);
      const blockId = 7;
      await _insertBlock(db, blockId, 'CORE DAY', folder: 'CONDITIONING');
      final knsId = await db.into(db.workoutBlockKns).insert(
            WorkoutBlockKnsCompanion.insert(
              blockId: blockId,
              baseExerciseId: exerciseId,
            ),
          );
      await db.into(db.workoutBlockSets).insert(
            WorkoutBlockSetsCompanion.insert(
              knsId: knsId,
              setNumber: 1,
              repsMax: const drift.Value(12),
            ),
          );

      final combined = await ExportService.loadWorkoutBlocksCombinedData(db);
      expect(combined, hasLength(1));
      final wb = combined.first['wb'] as Map<String, dynamic>;
      expect(wb['name'], 'CORE DAY');
      expect(wb['folder'], 'CONDITIONING');
      final kns = combined.first['kns'] as List;
      expect(kns, hasLength(1));
    });
  });
}
