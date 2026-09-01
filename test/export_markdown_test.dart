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
}
