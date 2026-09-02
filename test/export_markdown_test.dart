// Regression test for the "GYMR no responde" ANR reported exporting
// SYNTHESIS > EXPORT_MARKDOWN_REPORT across a multi-year date range
// (Jan'24-Aug'26). exportWorkoutsToMarkdown now hands its formatting pass
// to a background isolate via compute(); the single most valuable thing
// this test proves is that the plain data bundle it sends across that
// isolate boundary (WorkoutSet/BaseExercise/WorkoutLog/SomaticLogEntry) is
// actually isolate-sendable - if any of that reasoning was wrong, this
// test fails with an isolate serialization error instead of a phone
// hanging mid-workout. It also exercises the two-pointer bodyweight
// lookup rewrite (_batchFetchBodyweights) across many logged dates to
// confirm it still produces correct values.
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:beyond_performance/database/database.dart';
import 'package:beyond_performance/providers/theme_provider.dart';
import 'package:beyond_performance/services/export_service.dart';

AppDatabase _testDb() => AppDatabase.forTesting(NativeDatabase.memory());

class _FakePathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final String tempPath;
  _FakePathProviderPlatform(this.tempPath);

  @override
  Future<String?> getTemporaryPath() async => tempPath;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('gymr_export_test_');
    PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir.path);
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test(
      'exportWorkoutsToMarkdown handles a multi-year, many-set history '
      'without throwing (isolate transfer) and applies bodyweight correctly',
      () async {
    final db = _testDb();
    addTearDown(db.close);

    // somatic_logs is created inside a schema-version-gated migration step
    // (database.dart), not unconditionally in beforeOpen - a fresh
    // forTesting() database already sitting at the latest schema version
    // never runs that migration, so the table doesn't exist unless created
    // here. Mirrors the exact CREATE TABLE from database.dart.
    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS somatic_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        set_id INTEGER REFERENCES workout_sets(id) ON DELETE CASCADE,
        description TEXT NOT NULL,
        spectrum_value INTEGER NOT NULL DEFAULT 0,
        tags TEXT,
        created_at INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // A LASTRE exercise so totalLoad = bodyweight + added weight, which
    // exercises the bodyweight lookup path end to end.
    final exerciseId = await db.into(db.baseExercises).insert(
          BaseExercisesCompanion.insert(
            name: 'Weighted Muscle Up',
            field: const drift.Value('LASTRE'),
          ),
        );

    // Spread ~250 logged sessions across ~2.5 years (Jan'24-Aug'26), one
    // set each - big enough to be a meaningful stress case without making
    // the test itself slow.
    final start = DateTime(2024, 1, 1);
    for (int i = 0; i < 250; i++) {
      final date = start.add(Duration(days: i * 4));
      final logId = await db.into(db.workoutLogs).insert(
            WorkoutLogsCompanion.insert(date: date),
          );
      await db.into(db.workoutSets).insert(
            WorkoutSetsCompanion.insert(
              logId: logId,
              baseExerciseId: exerciseId,
              weight: 20.0,
              reps: 8.0,
              timestamp: drift.Value(date),
            ),
          );
      // Bodyweight logged every ~12 days (fixed value, so the expected
      // EORM below is deterministic) so _batchFetchBodyweights has to
      // carry the last-known value forward across gaps, not just match
      // same-day entries.
      if (i % 3 == 0) {
        await db.customStatement(
          "INSERT INTO anthropometric_logs (label, value, unit, date) VALUES ('WEIGHT', ?, 'KG', ?)",
          [80.0, date.millisecondsSinceEpoch ~/ 1000],
        );
      }
    }

    final query = db.select(db.workoutSets).join([
      drift.innerJoin(db.baseExercises,
          db.baseExercises.id.equalsExp(db.workoutSets.baseExerciseId)),
      drift.innerJoin(
          db.workoutLogs, db.workoutLogs.id.equalsExp(db.workoutSets.logId)),
    ]);
    final rows = await query.get();
    expect(rows, hasLength(250));

    await ExportService.exportWorkoutsToMarkdown(
      rows,
      db,
      {},
      ThemeController(db),
      fileName: 'gymr_export_test',
      share: false,
    );

    final file = File('${tempDir.path}/gymr_export_test.md');
    expect(await file.exists(), isTrue);
    final content = await file.readAsString();

    expect(content, contains('WEIGHTED MUSCLE UP'));
    expect(content, contains('20.0KG'));
    // LASTRE totalLoad = bodyweight(80) + weight(20) = 100, Epley EORM at
    // 8 reps = 100 * (1 + 8/30) = 126.67 -> "126.7". If the bodyweight
    // lookup silently failed (e.g. an off-by-one in the two-pointer
    // rewrite) this would instead show 20 * 1.2667 = "25.3" (weight only).
    expect(content, contains('126.7'),
        reason:
            'bodyweight should be carried forward and added to LASTRE load');
    expect(content, isNot(contains('25.3')),
        reason: 'would indicate the bodyweight lookup silently found nothing');
  });

  test(
      'rows sort by real timestamp across exercises, not grouped by '
      'orderIndex (circuit-training / alternating-exercise sessions), and '
      'the TIME column reflects when each set was actually created',
      () async {
    final db = _testDb();
    addTearDown(db.close);

    final exA = await db.into(db.baseExercises).insert(
          BaseExercisesCompanion.insert(name: 'Exercise A'),
        );
    final exB = await db.into(db.baseExercises).insert(
          BaseExercisesCompanion.insert(name: 'Exercise B'),
        );
    final logId = await db.into(db.workoutLogs).insert(
          WorkoutLogsCompanion.insert(date: DateTime(2025, 3, 1)),
        );

    // A was added to the workout first (orderIndex 0), B second
    // (orderIndex 1) - but in real life the sets were done alternating
    // (circuit-style): A 10:00, B 10:05, A 10:10, B 10:15. Sorting by
    // orderIndex first (the old behavior) would wrongly group both of A's
    // sets before either of B's.
    Future<void> insertSet(int exerciseId, int orderIndex, int hour, int minute) {
      return db.into(db.workoutSets).insert(
            WorkoutSetsCompanion.insert(
              logId: logId,
              baseExerciseId: exerciseId,
              weight: 10.0,
              reps: 5.0,
              orderIndex: drift.Value(orderIndex),
              timestamp: drift.Value(DateTime(2025, 3, 1, hour, minute)),
            ),
          );
    }

    await insertSet(exA, 0, 10, 0);
    await insertSet(exB, 1, 10, 5);
    await insertSet(exA, 0, 10, 10);
    await insertSet(exB, 1, 10, 15);

    // Same orderBy as nexus_screen.dart's _generateWorkoutFile/
    // _downloadWorkoutFile after the fix: timestamp primary, orderIndex
    // only as a tiebreaker.
    final query = db.select(db.workoutSets).join([
      drift.innerJoin(db.baseExercises,
          db.baseExercises.id.equalsExp(db.workoutSets.baseExerciseId)),
      drift.innerJoin(
          db.workoutLogs, db.workoutLogs.id.equalsExp(db.workoutSets.logId)),
    ])
      ..orderBy([
        drift.OrderingTerm.asc(db.workoutLogs.date),
        drift.OrderingTerm.asc(db.workoutSets.timestamp),
        drift.OrderingTerm.asc(db.workoutSets.orderIndex),
      ]);
    final rows = await query.get();

    await ExportService.exportWorkoutsToMarkdown(
      rows,
      db,
      {},
      ThemeController(db),
      fileName: 'gymr_chrono_order_test',
      share: false,
    );

    final file = File('${tempDir.path}/gymr_chrono_order_test.md');
    final content = await file.readAsString();

    // Each row starts with "| <setNumber> | <HH:mm> | <EXERCISE NAME>" -
    // matching on the full prefix ties the position check to the actual
    // set number and time together, not just exercise name order.
    final posA1 = content.indexOf('| 1 | 10:00 | EXERCISE A');
    final posB1 = content.indexOf('| 2 | 10:05 | EXERCISE B');
    final posA2 = content.indexOf('| 3 | 10:10 | EXERCISE A');
    final posB2 = content.indexOf('| 4 | 10:15 | EXERCISE B');

    expect(posA1, greaterThanOrEqualTo(0), reason: 'first A row not found as expected');
    expect(posB1, greaterThanOrEqualTo(0), reason: 'first B row not found as expected');
    expect(posA2, greaterThanOrEqualTo(0), reason: 'second A row not found as expected');
    expect(posB2, greaterThanOrEqualTo(0), reason: 'second B row not found as expected');

    expect(posA1, lessThan(posB1),
        reason: 'rows must be in real chronological order, not grouped by exercise/orderIndex');
    expect(posB1, lessThan(posA2));
    expect(posA2, lessThan(posB2));
  });

  test(
      'exportWorkoutsToMarkdown tolerates a malformed particular_toggles '
      '(list of maps instead of strings) instead of crashing the whole export',
      () async {
    // Regression test: splitting set.complexMetadata's jsonDecode into its
    // own try/catch (for the perf fix above) initially left the
    // particular_toggles List<String>.from() cast unguarded, so a single
    // exercise with malformed toggle data crashed the ENTIRE export with
    // "type '_Map<String, dynamic>' is not a subtype of type 'String'" -
    // exactly what a real user hit exporting ~14 months of real data.
    final db = _testDb();
    addTearDown(db.close);

    final exerciseId = await db.into(db.baseExercises).insert(
          BaseExercisesCompanion.insert(
            name: 'Bad Toggles Exercise',
            // Malformed on purpose: a list of maps, not plain strings -
            // the shape every OTHER nomenclature piece uses
            // ({"v":...,"s":...}), which particular_toggles never should.
            complexMetadata: const drift.Value(
                '{"particular_toggles": [{"v": "DROPSET", "s": true}]}'),
          ),
        );
    final logId = await db.into(db.workoutLogs).insert(
          WorkoutLogsCompanion.insert(date: DateTime(2025, 1, 1)),
        );
    await db.into(db.workoutSets).insert(
          WorkoutSetsCompanion.insert(
            logId: logId,
            baseExerciseId: exerciseId,
            weight: 10.0,
            reps: 5.0,
            complexMetadata: const drift.Value('{"DROPSET": true}'),
          ),
        );

    final query = db.select(db.workoutSets).join([
      drift.innerJoin(db.baseExercises,
          db.baseExercises.id.equalsExp(db.workoutSets.baseExerciseId)),
      drift.innerJoin(
          db.workoutLogs, db.workoutLogs.id.equalsExp(db.workoutSets.logId)),
    ]);
    final rows = await query.get();

    // Must not throw.
    await ExportService.exportWorkoutsToMarkdown(
      rows,
      db,
      {},
      ThemeController(db),
      fileName: 'gymr_bad_toggles_test',
      share: false,
    );

    final file = File('${tempDir.path}/gymr_bad_toggles_test.md');
    expect(await file.exists(), isTrue);
    final content = await file.readAsString();
    expect(content, contains('BAD TOGGLES EXERCISE'));
  });
}
