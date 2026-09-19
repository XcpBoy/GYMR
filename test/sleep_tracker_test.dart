// Regression test for SLPTRCKR (schema v35) - the tap-on/tap-off +
// pause/resume mechanic ported from JRNLR's sleep tracker, plus its NEXUS >
// ONLY_OUTPUT export (CSV/PDF/XLSX).
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:excel/excel.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:beyond_performance/database/database.dart';
import 'package:beyond_performance/logic/sleep_stats.dart';
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
    tempDir = Directory.systemTemp.createTempSync('gymr_sleep_test_');
    PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir.path);
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('start -> pause -> resume -> finish folds paused time out of the '
      'counted duration', () async {
    final db = _testDb();
    addTearDown(db.close);

    expect(await db.openSleepSession(), isNull);
    final id = await db.startSleepSession();
    final open = await db.openSleepSession();
    expect(open, isNotNull);
    expect(open!.id, id);
    expect(open.wakeAt, isNull);
    expect(open.pausedAt, isNull);

    // Backdate bedAt (and later pausedAt) directly so the test doesn't
    // depend on real wall-clock sleeps: 8 real hours, with a 30-minute
    // stretch paused (e.g. woke up briefly) that should NOT count toward
    // hoursInBed.
    final bedAt = DateTime(2025, 6, 1, 23, 0);
    await db.updateSleepLog(id, bedAt: bedAt);

    await db.pauseSleepSession(id);
    // Simulate the pause having lasted 30 minutes by writing pausedAt
    // directly in the past, then resuming - resumeSleepSession folds
    // `now - pausedAt` into pausedSeconds.
    await db.customStatement(
      'UPDATE sleep_logs SET paused_at = ? WHERE id = ?',
      [
        DateTime.now()
                .subtract(const Duration(minutes: 30))
                .millisecondsSinceEpoch ~/
            1000,
        id
      ],
    );
    await db.resumeSleepSession(id);
    final afterResume = await db.openSleepSession();
    expect(afterResume!.pausedAt, isNull);
    expect(afterResume.pausedSeconds, greaterThanOrEqualTo(1799));
    expect(afterResume.pausedSeconds, lessThanOrEqualTo(1801));

    await db.finishSleepSession(id, qualityFeel: 6);
    final logs = await db.watchAllSleepLogs().first;
    expect(logs, hasLength(1));
    final finished = logs.first;
    expect(finished.wakeAt, isNotNull);
    expect(finished.qualityFeel, 6);
    expect(await db.openSleepSession(), isNull);

    // wakeAt is real "now", bedAt was pinned to 2025-06-01 23:00 - hoursInBed
    // should be huge here since this is just checking the paused-time
    // subtraction is wired correctly, not a realistic duration. Rebuild
    // with a controlled wakeAt via updateSleepLog instead for a clean
    // assertion.
    final controlledWake = bedAt.add(const Duration(hours: 8, minutes: 30));
    await db.updateSleepLog(id,
        bedAt: bedAt, wakeAt: controlledWake, qualityFeel: 6);
    final controlled = (await db.watchAllSleepLogs().first).first;
    // 8h30m raw minus ~30m paused = ~8h.
    final hours = hoursInBed(controlled)!;
    expect(hours, closeTo(8.0, 0.02));
  });

  test('deleteSleepLog removes the row', () async {
    final db = _testDb();
    addTearDown(db.close);
    final id = await db.startSleepSession();
    await db.deleteSleepLog(id);
    expect(await db.watchAllSleepLogs().first, isEmpty);
  });

  Future<AppDatabase> buildExportDb() async {
    final db = _testDb();
    final id1 = await db.startSleepSession();
    await db.updateSleepLog(id1,
        bedAt: DateTime(2025, 1, 1, 23, 0),
        wakeAt: DateTime(2025, 1, 2, 7, 0),
        qualityFeel: 5);
    final id2 = await db.startSleepSession();
    await db.updateSleepLog(id2, bedAt: DateTime(2025, 1, 3, 23, 30));
    return db;
  }

  test('exportSleepToCsv includes completed and in-progress sessions',
      () async {
    final db = await buildExportDb();
    addTearDown(db.close);

    final path = await ExportService.exportSleepToCsv(db, share: false);
    final content = await File(path).readAsString();
    final lines = content.trim().split('\n');

    expect(lines.first, 'BED_AT,WAKE_AT,HOURS,QUALITY_FEEL,PAUSED_MIN');
    expect(lines.length, 3);
    expect(content, contains('2025-01-01 23:00,2025-01-02 07:00,8.00,5,0'));
    expect(content, contains('2025-01-03 23:30,IN_PROGRESS,,,0'));
  });

  test('exportSleepToExcel writes the correct cell values', () async {
    final db = await buildExportDb();
    addTearDown(db.close);

    final path = await ExportService.exportSleepToExcel(db, share: false);
    final bytes = await File(path).readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel['SLEEP'];
    String cell(int row, int col) =>
        sheet.row(row)[col]?.value?.toString() ?? '';

    expect(cell(0, 0), 'BED_AT');
    expect(cell(1, 2), '8.00');
    expect(cell(1, 3), '5');
    expect(cell(2, 1), 'IN_PROGRESS');
  });

  test('exportSleepToPdf produces a valid non-empty PDF', () async {
    final db = await buildExportDb();
    addTearDown(db.close);

    final path = await ExportService.exportSleepToPdf(db, share: false);
    final bytes = await File(path).readAsBytes();
    expect(bytes.length, greaterThan(0));
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });
}
