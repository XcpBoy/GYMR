// Regression test for NEXUS > ONLY_OUTPUT > EXPORT ANTRPMTRC.DT
// (CSV/PDF/XLSX), added on request. Exercises the raw-query path
// (_fetchAnthropometricRows) - the same defensive read
// anthropometric_data_screen.dart's _watchLogs already uses, in case a
// truly legacy pre-migration row (predating the is_flexed/is_pumped
// columns entirely, so no NOT NULL constraint applied at insert time)
// still has a NULL there.
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:excel/excel.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:beyond_performance/database/database.dart';
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
    tempDir = Directory.systemTemp.createTempSync('gymr_antrpmtrc_test_');
    PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir.path);
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Future<AppDatabase> buildDb() async {
    final db = _testDb();
    await db.customStatement(
      "INSERT INTO anthropometric_logs (date, label, value, unit, is_flexed, is_pumped) "
      "VALUES (?, 'WEIGHT', 82.5, 'KG', 0, 0)",
      [DateTime(2025, 1, 1).millisecondsSinceEpoch ~/ 1000],
    );
    await db.customStatement(
      "INSERT INTO anthropometric_logs (date, label, value, unit, is_flexed, is_pumped) "
      "VALUES (?, 'ARM', 38.2, 'CM', 0, 0)",
      [DateTime(2025, 2, 1).millisecondsSinceEpoch ~/ 1000],
    );
    await db.customStatement(
      "INSERT INTO anthropometric_logs (date, label, value, unit, is_flexed, is_pumped) "
      "VALUES (?, 'ARM', 39.0, 'CM', 1, 1)",
      [DateTime(2025, 2, 15).millisecondsSinceEpoch ~/ 1000],
    );
    return db;
  }

  test('exportAnthropometricToCsv produces a CSV with header + all rows',
      () async {
    final db = await buildDb();
    addTearDown(db.close);

    final path =
        await ExportService.exportAnthropometricToCsv(db, share: false);
    final content = await File(path).readAsString();
    final lines = content.trim().split('\n');

    expect(lines.first, 'DATE,LABEL,VALUE,UNIT,FLEXED,PUMPED');
    expect(lines.length, 4); // header + 3 rows
    expect(content, contains('2025-01-01,WEIGHT,82.5,KG,,'));
    expect(content, contains('2025-02-01,ARM,38.2,CM,,'));
    expect(content, contains('2025-02-15,ARM,39.0,CM,YES,YES'));
  });

  test('exportAnthropometricToExcel writes the correct cell values',
      () async {
    final db = await buildDb();
    addTearDown(db.close);

    final path =
        await ExportService.exportAnthropometricToExcel(db, share: false);
    final bytes = await File(path).readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel['ANTHROPOMETRIC'];

    String cell(int row, int col) =>
        sheet.row(row)[col]?.value?.toString() ?? '';

    expect(cell(0, 0), 'DATE');
    expect(cell(1, 1), 'WEIGHT');
    expect(cell(2, 4), ''); // FLEXED blank for a false row
    expect(cell(3, 4), 'YES');
    expect(cell(3, 5), 'YES');
  });

  test('exportAnthropometricToPdf produces a valid non-empty PDF', () async {
    final db = await buildDb();
    addTearDown(db.close);

    final path =
        await ExportService.exportAnthropometricToPdf(db, share: false);
    final bytes = await File(path).readAsBytes();
    expect(bytes.length, greaterThan(0));
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });

  test('exports on an empty table produce a header-only file without '
      'throwing', () async {
    final db = _testDb();
    addTearDown(db.close);

    final csvPath =
        await ExportService.exportAnthropometricToCsv(db, share: false);
    final content = await File(csvPath).readAsString();
    expect(content.trim(), 'DATE,LABEL,VALUE,UNIT,FLEXED,PUMPED');
  });
}
