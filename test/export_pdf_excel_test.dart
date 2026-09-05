// Regression test for the per-exercise memoization added to
// exportWorkoutsToPdf/exportWorkoutsToExcel (see _buildPdfExcelExerciseData):
// fullName/parsedComplexMetadata/phase-labels/toggle-list are now computed
// once per distinct exercise instead of once per set. This pins both
// exporters to still produce correct, non-empty output for a case that
// exercises every piece of derived per-exercise data (LASTRE bodyweight
// load, unilateral side detection, toggles, failure phase, superset - PDF
// only) plus PDF's legacy {"name": ...}-shaped toggle entries, which Excel's
// plain-string-only toggle list does not need to handle.
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:excel/excel.dart';
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
    tempDir = Directory.systemTemp.createTempSync('gymr_pdf_xlsx_test_');
    PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir.path);
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  // allowMapToggles controls whether particular_toggles includes a legacy
  // {"name": ...} entry: PDF tolerates that shape (allowMapToggles: true),
  // but Excel's toggle list is plain-string-only, exactly like the
  // original pre-optimization code - a mixed list there throws and
  // silently degrades to no active toggles, which is the same fixture used
  // to pin that pre-existing behavior for Excel.
  Future<AppDatabase> buildDb({required bool allowMapToggles}) async {
    final db = _testDb();
    final toggles = allowMapToggles
        ? '["DROPSET", {"name": "PAUSE"}]'
        : '["DROPSET", "PAUSE"]';
    final exA = await db.into(db.baseExercises).insert(
          BaseExercisesCompanion.insert(
            name: 'Weighted Muscle Up',
            field: const drift.Value('LASTRE'),
            isUnilateral: const drift.Value(true),
            complexMetadata: drift.Value(
                '{"particular_toggles": $toggles, "classification": "ISOLATION", "description": "KEEP HOLLOW"}'),
            phaseDescriptions: const drift.Value(
                '{"phases": {"1": "lockout"}}'),
          ),
        );
    final exB = await db.into(db.baseExercises).insert(
          BaseExercisesCompanion.insert(name: 'Exercise B'),
        );
    final logId = await db.into(db.workoutLogs).insert(
          WorkoutLogsCompanion.insert(date: DateTime(2025, 6, 1)),
        );
    await db.into(db.workoutSets).insert(
          WorkoutSetsCompanion.insert(
            logId: logId,
            baseExerciseId: exA,
            weight: 20.0,
            reps: 8.0,
            failurePhase: const drift.Value(1),
            supersetGroupId: const drift.Value('1'),
            complexMetadata: const drift.Value(
                '{"side": "LEFT", "DROPSET": true}'),
          ),
        );
    await db.into(db.workoutSets).insert(
          WorkoutSetsCompanion.insert(
            logId: logId,
            baseExerciseId: exB,
            weight: 15.0,
            reps: 10.0,
            supersetGroupId: const drift.Value('1'),
          ),
        );
    await db.customStatement(
      "INSERT INTO anthropometric_logs (label, value, unit, date) VALUES ('WEIGHT', ?, 'KG', ?)",
      [80.0, DateTime(2025, 6, 1).millisecondsSinceEpoch ~/ 1000],
    );
    return db;
  }

  Future<List<drift.TypedResult>> joinRows(AppDatabase db) {
    final query = db.select(db.workoutSets).join([
      drift.innerJoin(db.baseExercises,
          db.baseExercises.id.equalsExp(db.workoutSets.baseExerciseId)),
      drift.innerJoin(
          db.workoutLogs, db.workoutLogs.id.equalsExp(db.workoutSets.logId)),
    ]);
    return query.get();
  }

  test('exportWorkoutsToPdf produces a non-empty file for a set exercising '
      'every per-exercise derived field (LASTRE load, unilateral, toggles '
      'incl. legacy map-shaped entries, failure phase, superset)', () async {
    final db = await buildDb(allowMapToggles: true);
    addTearDown(db.close);

    await ExportService.exportWorkoutsToPdf(
      await joinRows(db),
      db,
      {},
      ThemeController(db),
      fileName: 'gymr_pdf_test',
      share: false,
    );

    final file = File('${tempDir.path}/gymr_pdf_test.pdf');
    expect(await file.exists(), isTrue);
    final bytes = await file.readAsBytes();
    expect(bytes.length, greaterThan(0));
    // %PDF header
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });

  test('exportWorkoutsToExcel produces correct cell values for the same '
      'exercise (bodyweight load, unilateral side, toggle, failure phase)',
      () async {
    final db = await buildDb(allowMapToggles: false);
    addTearDown(db.close);

    await ExportService.exportWorkoutsToExcel(
      await joinRows(db),
      db,
      {},
      ThemeController(db),
      fileName: 'gymr_xlsx_test',
      share: false,
    );

    final file = File('${tempDir.path}/gymr_xlsx_test.xlsx');
    expect(await file.exists(), isTrue);
    final bytes = await file.readAsBytes();
    expect(bytes.length, greaterThan(0));

    final excel = Excel.decodeBytes(bytes);
    final sheet = excel['WORKOUTS'];
    // Row 0: day header, Row 1: column header, Row 2: exA's set.
    final dataRow = sheet.row(2);
    String cell(int i) => dataRow[i]?.value?.toString() ?? '';

    expect(cell(3), contains('WEIGHTED MUSCLE UP'));
    expect(cell(4), 'L'); // side
    expect(cell(6), '20'); // raw set weight, not the LASTRE total load
    expect(cell(8), '126.67'); // EORM off LASTRE total (bodyweight 80 + 20 @ 8 reps), Excel keeps 2 decimals
    expect(cell(13), 'LOCKOUT'); // failure phase label
    expect(cell(14), 'DROPSET'); // active toggle
  });
}
