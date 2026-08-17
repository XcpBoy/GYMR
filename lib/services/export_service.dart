import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../database/database.dart';
import 'package:drift/drift.dart';
import '../logic/calculator.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/sqlite3.dart';
import '../providers/theme_provider.dart';
import '../localization/strings.dart';

class LoadDetails {
  final String type;
  final bool isIsometric;
  LoadDetails({required this.type, required this.isIsometric});
}

class SomaticLogEntry {
  final int id;
  final int setId;
  final String description;
  final int spectrumValue;
  SomaticLogEntry(
      {required this.id,
      required this.setId,
      required this.description,
      required this.spectrumValue});
}

Future<pw.Font> _loadUnicodeFont() async {
  // Try system fonts with Unicode support (Android paths)
  final paths = [
    '/system/fonts/NotoSans-Regular.ttf',
    '/system/fonts/DroidSansFallback.ttf',
  ];
  for (final path in paths) {
    try {
      final file = File(path);
      if (await file.exists()) {
        final data = await file.readAsBytes();
        return pw.Font.ttf(data.buffer.asByteData());
      }
    } catch (_) {}
  }
  return pw.Font.helvetica();
}

Future<pw.Font?> _loadEmojiFont() async {
  final paths = [
    '/system/fonts/NotoColorEmoji.ttf',
    '/system/fonts/NotoSansSymbols2-Regular.ttf',
  ];
  for (final path in paths) {
    try {
      final file = File(path);
      if (await file.exists()) {
        final data = await file.readAsBytes();
        return pw.Font.ttf(data.buffer.asByteData());
      }
    } catch (_) {}
  }
  return null;
}

class ExportService {
  // TODO: Implement consistent priority colors in PDF (currently not reflecting accurately)
  // --- DATABASE MANAGEMENT ---

  static Future<List<File>> listDatabases() async {
    try {
      final dbFolder = await getApplicationDocumentsDirectory();
      final dir = Directory(dbFolder.path);
      if (!await dir.exists()) return [];

      final List<FileSystemEntity> entities = await dir.list().toList();
      return entities.whereType<File>().where((file) {
        final ext = p.extension(file.path).toLowerCase();
        final name = p.basename(file.path).toLowerCase();
        return ext == '.sqlite' || ext == '.db' || name.contains('.sqlite-');
      }).toList();
    } catch (e) {
      debugPrint("Error listing databases: $e");
      return [];
    }
  }

  static Future<bool> backupAllDatabases() async {
    final dbs = await listDatabases();
    if (dbs.isEmpty) return false;

    // Find the main database file
    File? mainDb;
    for (var dbFile in dbs) {
      final name = p.basename(dbFile.path).toLowerCase();
      if (name.endsWith('.sqlite') || name.endsWith('.db')) {
        mainDb = dbFile;
        break;
      }
    }
    mainDb ??= dbs.first;

    final tempDir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final exportFile = File("${tempDir.path}/GYMR_backup_$timestamp.sqlite");
    await mainDb.copy(exportFile.path);

    await SharePlus.instance.share(
        ShareParams(files: [XFile(exportFile.path)],
            text: 'GYMR Database Backup'));
    return true;
  }

  // ── DB BACKUP DIRECTORY PERSISTENCE ──

  static Future<String?> loadBackupDirectory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('backup_directory');
  }

  static Future<void> saveBackupDirectory(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('backup_directory', path);
  }

  static Future<DateTime?> loadLastBackupDate() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt('last_backup_date_ms');
    return ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  }

  static Future<void> saveLastBackupDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
        'last_backup_date_ms', date.millisecondsSinceEpoch);
  }

  /// Returns the reliable backup directory (app's external storage).
  /// Creates it if it doesn't exist.
  static Future<String> getBackupDirectory() async {
    final extDir = await getExternalStorageDirectory();
    final dirPath = p.join(extDir!.path, 'GYMR_backups');
    final dir = Directory(dirPath);
    if (!await dir.exists()) await dir.create(recursive: true);
    return dirPath;
  }

  /// Copy the main database file with a timestamp to the app's external
  /// storage (always writable on Android). Returns the path of the backup.
  static Future<String> backupDatabaseToDirectory([String? _]) async {
    final dbs = await listDatabases();
    if (dbs.isEmpty) throw Exception('NO_DATABASE_FILES_FOUND');

    File? mainDb;
    for (var dbFile in dbs) {
      final name = p.basename(dbFile.path).toLowerCase();
      if (name.endsWith('.sqlite') || name.endsWith('.db')) {
        mainDb = dbFile;
        break;
      }
    }
    mainDb ??= dbs.first;

    final actualDir = await getBackupDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final backupFile =
        File(p.join(actualDir, 'GYMR_db_$timestamp.sqlite'));
    await mainDb.copy(backupFile.path);

    await saveBackupDirectory(actualDir);
    await saveLastBackupDate(DateTime.now());
    return backupFile.path;
  }

  /// Auto-backup: runs once per day.
  /// Returns true if a backup was performed, false otherwise.
  static Future<bool> tryAutoBackup() async {
    try {
      final lastBackup = await loadLastBackupDate();
      final today = DateTime.now();
      if (lastBackup != null &&
          lastBackup.year == today.year &&
          lastBackup.month == today.month &&
          lastBackup.day == today.day) {
        return false;
      }

      await backupDatabaseToDirectory();
      return true;
    } catch (e) {
      debugPrint('Auto-backup failed: $e');
      return false;
    }
  }

  // Tables that must exist for a .sqlite file to plausibly be a GYMR
  // database - catches "opens fine as *some* SQLite file but isn't ours"
  // (e.g. a random app's export, or a backup from a wildly older schema
  // version) before it silently overwrites the user's real database.
  static const _kGymrCoreTables = ['base_exercises', 'workout_sets'];

  static Future<void> importDatabase(
      File sourceFile, String targetFileName) async {
    try {
      final tempDb = sqlite3.open(sourceFile.path);
      try {
        final tableNames = tempDb
            .select(
                "SELECT name FROM sqlite_master WHERE type = 'table'")
            .map((row) => row['name'] as String)
            .toSet();
        final missing =
            _kGymrCoreTables.where((t) => !tableNames.contains(t)).toList();
        if (missing.isNotEmpty) {
          throw Exception(
              "Selected file does not look like a GYMR database (missing table(s): ${missing.join(', ')}).");
        }
      } finally {
        tempDb.dispose();
      }
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception(
          "Selected file is not a valid SQLite database or is corrupted.");
    }

    final dbFolder = await getApplicationDocumentsDirectory();
    final targetPath = p.join(dbFolder.path, targetFileName);
    final targetFile = File(targetPath);
    if (await targetFile.exists()) {
      await targetFile.delete();
    }
    await sourceFile.copy(targetPath);
  }

  // --- HELPERS ---

  /// Generates a WOLOG filename from a list of dates.
  static String wologFileName(List<DateTime> dates, String extension) {
    if (dates.isEmpty) return "WOLOG_empty.$extension";
    final sorted = List<DateTime>.from(dates)..sort();
    final a = DateFormat('ddMMyy').format(sorted.first);
    final b = DateFormat('ddMMyy').format(sorted.last);
    if (a == b) return "WOLOG_$a.$extension";
    return "WOLOG_${a}_$b.$extension";
  }

  static Future<Map<String, double>> _batchFetchBodyweights(
      AppDatabase db, List<DateTime> dates) async {
    if (dates.isEmpty) return {};
    final sortedDates = List<DateTime>.from(dates)..sort();
    final lastDate = sortedDates.last;

    // Raw + null-coalesced instead of the typed select: a row with an
    // unexpectedly-null column (schema drift on older installs) throws
    // "Null check operator used on a null value" in Drift's typed decoder
    // and would take out the whole export. Only date/value are needed.
    final cutoffSeconds = lastDate.millisecondsSinceEpoch ~/ 1000;
    final rawRows = await db.customSelect(
      "SELECT date, value FROM anthropometric_logs WHERE label = 'WEIGHT' AND date <= ? "
      'ORDER BY date ASC',
      variables: [Variable(cutoffSeconds)],
      readsFrom: {db.anthropometricLogs},
    ).get();
    final logs = rawRows
        .map((row) => (
              date: DateTime.fromMillisecondsSinceEpoch(
                  (row.data['date'] as int) * 1000),
              value: (row.data['value'] as num?)?.toDouble() ?? 0.0,
            ))
        .toList();

    final Map<String, double> dateToWeight = {};
    for (var date in dates) {
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      double? best;
      for (var log in logs) {
        if (log.date.isBefore(date) || log.date.isAtSameMomentAs(date)) {
          best = log.value;
        } else {
          break;
        }
      }
      if (best != null) dateToWeight[dateKey] = best;
    }
    return dateToWeight;
  }

  static Future<Map<int, List<SomaticLogEntry>>> _batchFetchSomatics(
      AppDatabase db, List<int> setIds) async {
    if (setIds.isEmpty) return {};

    // Chunking to avoid SQLite parameter limit (usually 999 or 32766, but safety first)
    const int chunkSize = 500;
    final List<SomaticLogEntry> allLogs = [];

    for (var i = 0; i < setIds.length; i += chunkSize) {
      final chunk = setIds.sublist(
          i, i + chunkSize > setIds.length ? setIds.length : i + chunkSize);
      final placeholders = chunk.map((_) => '?').join(',');
      final rows = await db.executor.runSelect(
        'SELECT id, set_id, description, spectrum_value FROM somatic_logs WHERE set_id IN ($placeholders)',
        chunk,
      );
      for (var row in rows) {
        allLogs.add(SomaticLogEntry(
          id: row['id'] as int,
          setId: row['set_id'] as int,
          description: row['description'] as String,
          spectrumValue: row['spectrum_value'] as int,
        ));
      }
    }

    final Map<int, List<SomaticLogEntry>> map = {};
    for (var log in allLogs) {
      map.putIfAbsent(log.setId, () => []).add(log);
    }
    return map;
  }

  static LoadDetails _detectLoadDetails(BaseExercise ex) {
    final intentionText = ex.intention ?? '';
    final metaMatch =
        RegExp(r'\[NT:(.*)\|ISO:(.*)\]').firstMatch(intentionText);

    if (metaMatch != null) {
      return LoadDetails(
        type: metaMatch.group(1) ?? 'EXT.LOAD',
        isIsometric: metaMatch.group(2) == 'true',
      );
    }

    String type = 'EXT.LOAD';
    if (['LASTRE', 'EXT.LOAD', 'JST.BW'].contains(ex.tissueName)) {
      type = ex.tissueName!;
    } else if (['LASTRE', 'EXT.LOAD', 'JST.BW'].contains(ex.field)) {
      type = ex.field!;
    }

    return LoadDetails(
      type: type,
      isIsometric: intentionText.startsWith('[ISO]'),
    );
  }

  static String _encodeCsv(List<List<dynamic>> rows) {
    return rows.map((row) {
      return row.map((cell) {
        String str = cell?.toString() ?? "";
        if (str.contains(',') || str.contains('"') || str.contains('\n')) {
          return '"${str.replaceAll('"', '""')}"';
        }
        return str;
      }).join(',');
    }).join('\n');
  }

  static List<List<String>> _decodeCsv(String csv) {
    List<List<String>> result = [];
    List<String> currentLabels = [];
    StringBuffer currentField = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < csv.length; i++) {
      String char = csv[i];
      if (inQuotes) {
        if (char == '"') {
          if (i + 1 < csv.length && csv[i + 1] == '"') {
            currentField.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          currentField.write(char);
        }
      } else {
        if (char == '"') {
          inQuotes = true;
        } else if (char == ',') {
          currentLabels.add(currentField.toString());
          currentField.clear();
        } else if (char == '\n' || char == '\r') {
          currentLabels.add(currentField.toString());
          if (currentLabels.isNotEmpty &&
              currentLabels.any((s) => s.isNotEmpty)) {
            result.add(List.from(currentLabels));
          }
          currentLabels.clear();
          currentField.clear();
          if (char == '\r' && i + 1 < csv.length && csv[i + 1] == '\n') i++;
        } else {
          currentField.write(char);
        }
      }
    }
    if (currentLabels.isNotEmpty || currentField.isNotEmpty) {
      currentLabels.add(currentField.toString());
      result.add(currentLabels);
    }
    return result;
  }

  // --- EXPORT LOGIC ---

  // Ordered keys for the main workout-report PDF table's columns, matching
  // the fixed index order tableData rows are built in below. Used by
  // NEXUS_CONFIG > PDF_COLUMNS (app_config_screen.dart) to let the user
  // toggle which columns get rendered, persisted as APPCFG_PDF_COL_<key>
  // bools (default true - nothing changes for existing users).
  static const List<String> kPdfColumnKeys = [
    'SET', 'EXERCISE', 'UTIL', 'LR', 'NAT', 'LOAD', 'REPS', 'EORM', 'PR',
    'RPE', 'RIR', 'TECH', 'FAIL', 'TOGGLES', 'NOTES'
  ];
  static const Map<String, String> kPdfColumnLabels = {
    'SET': 'SET', 'EXERCISE': 'EXERCISE', 'UTIL': 'UTIL.', 'LR': 'L/R',
    'NAT': 'NAT.', 'LOAD': 'LOAD', 'REPS': 'REPS/SECS', 'EORM': 'EORM',
    'PR': 'PR', 'RPE': 'RPE', 'RIR': 'RIR', 'TECH': 'TECH', 'FAIL': 'FAIL',
    'TOGGLES': 'TOGGLES', 'NOTES': 'NOTES'
  };

  static Future<void> exportWorkoutsToPdf(List<TypedResult> rows,
      AppDatabase db, Map<String, ThemeSetting> settings, ThemeController tC,
      {String? fileName, bool share = true, String lang = 'en'}) async {
    final pdf = pw.Document();
    final unicodeFont = await _loadUnicodeFont();
    final emojiFont = await _loadEmojiFont();
    final fallbackFonts = emojiFont != null ? [emojiFont] : null;

    final visibleCols = <int>[
      for (int i = 0; i < kPdfColumnKeys.length; i++)
        if (tC.getBool(settings, 'APPCFG_PDF_COL_${kPdfColumnKeys[i]}',
            defaultValue: true))
          i
    ];

    // 1. PRE-FETCH DATA (BATCH)
    final allDates =
        rows.map((r) => r.readTable(db.workoutLogs).date).toSet().toList();
    final allSetIds = rows.map((r) => r.readTable(db.workoutSets).id).toList();

    final bwMap = await _batchFetchBodyweights(db, allDates);
    final somaticMap = await _batchFetchSomatics(db, allSetIds);

    // Grouping by Month/Year and then by Day
    final Map<String, Map<String, List<TypedResult>>> groupedData = {};
    for (var r in rows) {
      final log = r.readTable(db.workoutLogs);
      final monthKey = DateFormat('MMMM yyyy').format(log.date);
      final dayKey = DateFormat('yyyy-MM-dd').format(log.date);

      groupedData.putIfAbsent(monthKey, () => {});
      groupedData[monthKey]!.putIfAbsent(dayKey, () => []).add(r);
    }

    final sortedMonths = groupedData.keys.toList()
      ..sort((a, b) {
        final dateA = DateFormat('MMMM yyyy').parse(a);
        final dateB = DateFormat('MMMM yyyy').parse(b);
        return dateA.compareTo(dateB);
      });

    List<Map<String, dynamic>> somaticAnomalies = [];
    List<Map<String, dynamic>> somaticRecoveries = [];
    final List<Map<String, String>> exerciseDescriptions = [];
    final Set<int> processedExerciseIds = {};
    final Map<String, List<Map<String, dynamic>>> supersetGroups = {};

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        theme: pw.ThemeData.withFont(
            base: unicodeFont, fontFallback: fallbackFonts),
        header: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(bottom: 10),
          child: pw.Text(
              "GYMR // TECHNICAL_WORKOUT_REPORT // PAGE ${context.pageNumber}",
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
        ),
        build: (pw.Context context) {
          final List<pw.Widget> content = [];
          content.add(pw.Header(
              level: 0,
              child: pw.Text("GYMR // TECHNICAL_WORKOUT_REPORT",
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 16))));
          content.add(pw.SizedBox(height: 10));

          for (var monthKey in sortedMonths) {
            content.add(pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 10),
              child: pw.Text(monthKey.toUpperCase(),
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 14,
                      color: PdfColors.blueGrey900)),
            ));

            final monthDays = groupedData[monthKey]!;
            final sortedDays = monthDays.keys.toList()..sort();

            for (var dayKey in sortedDays) {
              final dayRows = monthDays[dayKey]!;
              final displayDate = DateFormat('EEEE, MMM d, yyyy')
                  .format(DateTime.parse(dayKey))
                  .toUpperCase();

              content.add(pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                margin: const pw.EdgeInsets.only(top: 10, bottom: 5),
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                child: pw.Text(displayDate,
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 10)),
              ));

              List<List<dynamic>> tableData = [];
              List<bool> isUnilateralRow = [];
              List<PdfColor?> rowPriorityColors = [];

              // Tracker for absolute set numbering per exercise within this day
              int daySetCounter = 0;
              String? lastBatch;

              for (var r in dayRows) {
                final set = r.readTable(db.workoutSets);
                final ex = r.readTable(db.baseExercises);
                final log = r.readTable(db.workoutLogs);

                final dateKey = DateFormat('yyyy-MM-dd').format(log.date);
                final bw = bwMap[dateKey];
                final details = _detectLoadDetails(ex);

                double? totalLoad;
                if (details.type == 'LASTRE') {
                  totalLoad = (bw ?? 0) + set.weight;
                } else if (details.type == 'EXT.LOAD') {
                  totalLoad = set.weight;
                } else if (details.type == 'JST.BW') {
                  totalLoad = bw ?? 0;
                } else if (details.type == 'UNMOVABLE') {
                  totalLoad = (bw ?? 0) + set.weight;
                }

                final fullName = ex.fullName;
                final classification =
                    ex.parsedComplexMetadata["classification"] ?? "C";
                final classShort =
                    classification.toString().startsWith('I') ? 'I' : 'C';
                final loadNature =
                    "[$classShort] ${details.isIsometric ? 'ISO+' : ''}${details.type}";

                final eorm = WorkoutCalculator.calculateEpley1RM(
                    totalLoad ?? set.weight, set.reps);

                // Increment absolute set counter for the day
                daySetCounter++;
                final setNumber = daySetCounter;

                // 1. Technique
                final techText = set.technique?.toString() ?? "-";

                // 2. Failure Phase
                String failureText = "-";
                if (set.failurePhase != null) {
                  Map<String, dynamic> phs = {};
                  if (ex.phaseDescriptions != null) {
                    try {
                      final Map<String, dynamic> meta =
                          jsonDecode(ex.phaseDescriptions!);
                      phs = meta["phases"] as Map<String, dynamic>? ?? {};
                    } catch (_) {}
                  }
                  failureText = (phs[set.failurePhase.toString()] ??
                          "PHASE ${set.failurePhase}")
                      .toString()
                      .toUpperCase();
                }

                // 3. Particular Toggles
                String togglesText = "-";
                if (set.complexMetadata != null) {
                  try {
                    final Map<String, dynamic> setMeta =
                        jsonDecode(set.complexMetadata!);
                    final Map<String, dynamic> exMeta =
                        ex.parsedComplexMetadata;
                    final List<dynamic> rawToggles =
                        exMeta["particular_toggles"] ?? [];
                    final List<String> availableToggles = rawToggles
                        .map((t) =>
                            (t is Map) ? (t["name"] as String) : (t as String))
                        .toList();

                    final activeToggles = availableToggles
                        .where((t) => setMeta[t] == true)
                        .toList();
                    if (activeToggles.isNotEmpty) {
                      togglesText = activeToggles.join(", ");
                    }
                  } catch (_) {}
                }

                // 4. Somatic Discomfort (Batch)
                final somatics = somaticMap[set.id] ?? [];
                if (somatics.isNotEmpty) {
                  for (final s in somatics) {
                    if (s.spectrumValue < 0) {
                      somaticAnomalies.add({
                        'date': DateFormat('dd/MM/yy').format(log.date),
                        'exercise': fullName,
                        'logs': "${s.description} (Spectrum:${s.spectrumValue})"
                      });
                    } else if (s.spectrumValue > 0) {
                      somaticRecoveries.add({
                        'date': DateFormat('dd/MM/yy').format(log.date),
                        'exercise': fullName,
                        'logs': "${s.description} (Spectrum:${s.spectrumValue})"
                      });
                    }
                  }
                }

                // 5. Unilateral side detection
                String sideText = "-";
                bool isUnilateral = false;
                if (ex.isUnilateral && set.complexMetadata != null) {
                  try {
                    final Map<String, dynamic> meta =
                        jsonDecode(set.complexMetadata!);
                    if (meta["side"] == "RIGHT") {
                      sideText = "R";
                      isUnilateral = true;
                    } else if (meta["side"] == "LEFT") {
                      sideText = "L";
                      isUnilateral = true;
                    }
                  } catch (_) {}
                }
                isUnilateralRow.add(isUnilateral);

                // 6. Priority Color
                PdfColor? pColor;
                if (set.priority != null && set.priority!.isNotEmpty) {
                  final fColor = tC.getColor(
                      settings, "PRIORITY_${set.priority}",
                      nameSeed: set.priority);
                  pColor = PdfColor.fromInt(fColor.value & 0xFFFFFF);
                }
                rowPriorityColors.add(pColor);

                // 7. Batch detection for export headers
                String? currentBatch;
                if (set.complexMetadata != null) {
                  try {
                    final Map<String, dynamic> cm =
                        jsonDecode(set.complexMetadata!);
                    if (cm['batch'] != null &&
                        cm['batch'].toString().isNotEmpty) {
                      currentBatch = cm['batch'].toString();
                    }
                  } catch (_) {}
                }
                // Track batch changes across rows (uses a static-like pattern via closure)
                // Compare with previous row's batch via the lastBatch variable
                if (currentBatch != null && currentBatch != lastBatch) {
                  lastBatch = currentBatch;
                  tableData.add([
                    currentBatch.toUpperCase(),
                    '',
                    '',
                    '',
                    '',
                    '',
                    '',
                    '',
                    '',
                    '',
                    '',
                    '',
                    '',
                    '',
                    ''
                  ]);
                } else if (currentBatch == null && lastBatch != null) {
                  lastBatch = null;
                }

                tableData.add([
                  setNumber.toString(),
                  "$fullName${isUnilateral ? ' (UNI)' : ''}",
                  set.priority?.toUpperCase() ?? "-",
                  sideText,
                  loadNature,
                  "${set.weight}KG",
                  "${set.reps.toString().replaceAll(RegExp(r'\.0$'), '')}${details.isIsometric ? 's' : ''}",
                  eorm.toStringAsFixed(1),
                  set.isPr ? "YES" : "",
                  set.rpe?.toString() ?? "-",
                  set.rir?.toString() ?? "-",
                  techText,
                  failureText,
                  togglesText,
                  set.notes ?? "-",
                ]);

                // Global Collections
                if (!processedExerciseIds.contains(ex.id)) {
                  final desc =
                      ex.parsedComplexMetadata["description"]?.toString() ?? "";
                  if (desc.isNotEmpty) {
                    exerciseDescriptions
                        .add({'name': ex.fullName, 'desc': desc});
                  }
                  processedExerciseIds.add(ex.id);
                }

                if (set.supersetGroupId != null) {
                  final dateKeySup = DateFormat('dd/MM/yy').format(log.date);
                  final groupKey = "${dateKeySup}_${set.supersetGroupId}";
                  supersetGroups.putIfAbsent(groupKey, () => []);
                  if (!supersetGroups[groupKey]!
                      .any((e) => e['name'] == ex.fullName)) {
                    supersetGroups[groupKey]!.add({
                      'name': ex.fullName,
                      'supersetName': set.supersetName ?? 'SUPERSET',
                      'date': dateKeySup
                    });
                  }
                }
              }

              // Render data split by batch headers
              List<List<dynamic>> currentSegment = [];
              int segmentStartRow = 0;
              void flushSegment() {
                if (currentSegment.isEmpty) return;
                final allHeaders = [
                  tr(lang, 'SET'),
                  tr(lang, 'EXERCISE'),
                  'UTIL.',
                  'L/R',
                  'NAT.',
                  tr(lang, 'LOAD'),
                  'REPS/SECS',
                  'EORM',
                  'PR',
                  'RPE',
                  'RIR',
                  'TECH',
                  'FAIL',
                  tr(lang, 'TOGGLES'),
                  tr(lang, 'NOTES')
                ];
                final allColumnWidths = <int, pw.TableColumnWidth>{
                  0: const pw.FixedColumnWidth(20),
                  1: const pw.FlexColumnWidth(1.0),
                  2: const pw.FlexColumnWidth(0.35),
                  3: const pw.FixedColumnWidth(22),
                  4: const pw.FixedColumnWidth(55),
                  5: const pw.FixedColumnWidth(45),
                  6: const pw.FixedColumnWidth(30),
                  7: const pw.FixedColumnWidth(35),
                  8: const pw.FixedColumnWidth(20),
                  9: const pw.FixedColumnWidth(25),
                  10: const pw.FixedColumnWidth(20),
                  11: const pw.FixedColumnWidth(25),
                  12: const pw.FixedColumnWidth(35),
                  13: const pw.FlexColumnWidth(0.4),
                  14: const pw.FlexColumnWidth(0.8),
                };
                content.add(pw.TableHelper.fromTextArray(
                  headers: segmentStartRow == 0
                      ? [for (final i in visibleCols) allHeaders[i]]
                      : null,
                  data: currentSegment
                      .map((row) => [for (final i in visibleCols) row[i]])
                      .toList(),
                  columnWidths: {
                    for (int newIdx = 0; newIdx < visibleCols.length; newIdx++)
                      newIdx: allColumnWidths[visibleCols[newIdx]]!,
                  },
                  headerStyle:
                      pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 5),
                  cellStyle: const pw.TextStyle(fontSize: 4.5),
                  cellAlignment: pw.Alignment.centerLeft,
                  headerDecoration:
                      const pw.BoxDecoration(color: PdfColors.grey300),
                  rowDecoration: const pw.BoxDecoration(
                    border: pw.Border(
                        bottom: pw.BorderSide(
                            color: PdfColors.grey200, width: 0.3)),
                  ),
                  cellDecoration: (index, data, rowNum) {
                    if (rowNum > 0 && rowNum <= rowPriorityColors.length) {
                      final pColor = rowPriorityColors[rowNum - 1];
                      if (pColor != null) {
                        return pw.BoxDecoration(color: pColor.flatten());
                      }
                      if (isUnilateralRow[rowNum - 1]) {
                        return const pw.BoxDecoration(color: PdfColors.cyan50);
                      }
                    }
                    return const pw.BoxDecoration();
                  },
                ));
                currentSegment = [];
              }

              for (var rowIdx = 0; rowIdx < tableData.length; rowIdx++) {
                final row = tableData[rowIdx];
                // Check if this is a batch header row (non-empty first col, rest empty)
                final isBatchHeader = row[0].toString().isNotEmpty &&
                    row.sublist(1).every((c) => c.toString().isEmpty);
                if (isBatchHeader) {
                  flushSegment();
                  content.add(pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.symmetric(
                        vertical: 4, horizontal: 8),
                    margin: const pw.EdgeInsets.only(top: 6, bottom: 2),
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.blueGrey100),
                    child: pw.Text(row[0].toString(),
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 7,
                            color: PdfColors.blueGrey900)),
                  ));
                  segmentStartRow = rowIdx + 1;
                } else {
                  currentSegment.add(row);
                }
              }
              flushSegment();

              final dayLog = dayRows.first.readTable(db.workoutLogs);
              final rawNotes = dayLog.notes ?? "";
              final cleanNotes =
                  rawNotes.replaceAll(RegExp(r'\[S:[\d.]+\]'), '').trim();
              final noteBlocks = cleanNotes
                  .split('||NOTE||')
                  .map((n) => n.trim())
                  .where((n) => n.isNotEmpty)
                  .toList();
              if (noteBlocks.isNotEmpty) {
                content.add(pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 6, bottom: 2),
                  child: pw.Text(
                    "SESSION_GENERAL_NOTES:",
                    style: pw.TextStyle(
                        fontSize: 6,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blueGrey800),
                  ),
                ));
                for (var ni = 0; ni < noteBlocks.length; ni++) {
                  content.add(pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 8, bottom: 2),
                    child: pw.Text(
                      "[${ni + 1}] ${noteBlocks[ni].toUpperCase()}",
                      style: pw.TextStyle(
                          fontSize: 5.5,
                          fontStyle: pw.FontStyle.italic,
                          color: PdfColors.blueGrey800),
                    ),
                  ));
                }
              }

              content.add(pw.SizedBox(height: 10));
            }
          }

          if (somaticAnomalies.isNotEmpty) {
            content.add(pw.Header(level: 1, text: "SOMATIC_ANOMALIES_LOG"));
            content.add(pw.TableHelper.fromTextArray(
              headers: [tr(lang, 'DATE'), tr(lang, 'EXERCISE'), 'ANOMALY_DETAILS'],
              data: somaticAnomalies
                  .map((a) => [a['date'], a['exercise'], a['logs']])
                  .toList(),
              headerStyle:
                  pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 6),
              cellStyle: const pw.TextStyle(fontSize: 5),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.red50),
              columnWidths: {
                0: const pw.FixedColumnWidth(40),
                1: const pw.FixedColumnWidth(100),
                2: const pw.FlexColumnWidth(1)
              },
            ));
          }

          if (somaticRecoveries.isNotEmpty) {
            content.add(pw.SizedBox(height: 10));
            content.add(pw.Header(level: 1, text: "SOMATIC_RECOVERY_LOG"));
            content.add(pw.TableHelper.fromTextArray(
              headers: [tr(lang, 'DATE'), tr(lang, 'EXERCISE'), 'RECOVERY_DETAILS'],
              data: somaticRecoveries
                  .map((r) => [r['date'], r['exercise'], r['logs']])
                  .toList(),
              headerStyle:
                  pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 6),
              cellStyle: const pw.TextStyle(fontSize: 5),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.green50),
              columnWidths: {
                0: const pw.FixedColumnWidth(40),
                1: const pw.FixedColumnWidth(100),
                2: const pw.FlexColumnWidth(1)
              },
            ));
          }

          if (exerciseDescriptions.isNotEmpty) {
            content.add(pw.SizedBox(height: 20));
            content.add(
                pw.Header(level: 1, text: "EXERCISE_TECHNICAL_DESCRIPTIONS"));
            content.add(pw.TableHelper.fromTextArray(
              headers: [tr(lang, 'EXERCISE'), 'TECHNICAL_DESCRIPTION'],
              data: exerciseDescriptions
                  .map((e) => [e['name'], e['desc']])
                  .toList(),
              headerStyle:
                  pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 6),
              cellStyle: const pw.TextStyle(fontSize: 5),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue50),
              columnWidths: {
                0: const pw.FixedColumnWidth(120),
                1: const pw.FlexColumnWidth(1)
              },
            ));
          }

          if (supersetGroups.isNotEmpty) {
            content.add(pw.SizedBox(height: 20));
            content.add(pw.Header(level: 1, text: "SUPERSET_BLOCKS_STRUCTURE"));
            content.add(pw.TableHelper.fromTextArray(
              headers: [tr(lang, 'DATE'), 'SUPERSET_NAME', tr(lang, 'COMPONENTS')],
              data: supersetGroups.values
                  .map((group) => [
                        group.first['date'],
                        group.first['supersetName'].toString().toUpperCase(),
                        group.map((e) => e['name']).join(" <-> ")
                      ])
                  .toList(),
              headerStyle:
                  pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 6),
              cellStyle: const pw.TextStyle(fontSize: 5),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.orange50),
              columnWidths: {
                0: const pw.FixedColumnWidth(40),
                1: const pw.FixedColumnWidth(80),
                2: const pw.FlexColumnWidth(1)
              },
            ));
          }

          return content;
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final file = File("${output.path}/${fileName ?? 'gymr_report_$ts'}.pdf");
    await file.writeAsBytes(await pdf.save());
    if (share) {
      await SharePlus.instance.share(
          ShareParams(files: [XFile(file.path)],
              text: 'GYMR Report PDF'));
    }
  }

  static Future<void> exportWorkoutsToExcel(List<TypedResult> rows,
      AppDatabase db, Map<String, ThemeSetting> settings, ThemeController tC,
      {String? fileName, bool share = true, String lang = 'en'}) async {
    var excel = Excel.createExcel();
    Sheet sheet = excel['WORKOUTS'];

    sheet.setColumnWidth(0, 8); // SET #
    sheet.setColumnWidth(1, 12); // DATE
    sheet.setColumnWidth(2, 20); // EXERCISE
    sheet.setColumnWidth(3, 8); // PRIO
    sheet.setColumnWidth(4, 6); // L/R
    sheet.setColumnWidth(5, 20); // NATURE
    sheet.setColumnWidth(6, 10); // LOAD
    sheet.setColumnWidth(7, 12); // REPS/SECS
    sheet.setColumnWidth(8, 10); // EORM
    sheet.setColumnWidth(9, 6); // IS_PR
    sheet.setColumnWidth(10, 6); // RPE
    sheet.setColumnWidth(11, 6); // RIR
    sheet.setColumnWidth(12, 6); // TECH
    sheet.setColumnWidth(13, 15); // FAILURE_PHASE
    sheet.setColumnWidth(14, 15); // TOGGLES
    sheet.setColumnWidth(15, 25); // NOTES
    sheet.setColumnWidth(16, 25); // SOMATIC

    // 1. PRE-FETCH DATA (BATCH)
    final allDates =
        rows.map((r) => r.readTable(db.workoutLogs).date).toSet().toList();
    final allSetIds = rows.map((r) => r.readTable(db.workoutSets).id).toList();

    final bwMap = await _batchFetchBodyweights(db, allDates);
    final somaticMap = await _batchFetchSomatics(db, allSetIds);

    // Grouping by Day
    final Map<String, List<TypedResult>> groupedByDay = {};
    for (var r in rows) {
      final log = r.readTable(db.workoutLogs);
      final key = DateFormat('yyyy-MM-dd').format(log.date);
      groupedByDay.putIfAbsent(key, () => []).add(r);
    }

    final sortedDays = groupedByDay.keys.toList()..sort();

    for (var dayKey in sortedDays) {
      final dayRows = groupedByDay[dayKey]!;
      final displayDate = DateFormat('EEEE, MMM d, yyyy')
          .format(DateTime.parse(dayKey))
          .toUpperCase();

      // Day Segment Header
      sheet.appendRow([
        TextCellValue('---'),
        TextCellValue(displayDate),
        TextCellValue(tr(lang, '--- DAY SEGMENT ---')),
      ]);

      sheet.appendRow([
        TextCellValue(tr(lang, 'SET #')),
        TextCellValue(tr(lang, 'DATE')),
        TextCellValue(tr(lang, 'EXERCISE')),
        TextCellValue('L/R'),
        TextCellValue(tr(lang, 'NATURE')),
        TextCellValue(tr(lang, 'LOAD')),
        TextCellValue('REPS/SECS'),
        TextCellValue('EORM'),
        TextCellValue('IS_PR'),
        TextCellValue('RPE'),
        TextCellValue('RIR'),
        TextCellValue('TECH'),
        TextCellValue('FAILURE_PHASE'),
        TextCellValue(tr(lang, 'TOGGLES')),
        TextCellValue(tr(lang, 'NOTES')),
        TextCellValue(tr(lang, 'SOMATIC'))
      ]);

      int daySetCounter = 0;

      for (var r in dayRows) {
        final set = r.readTable(db.workoutSets);
        final ex = r.readTable(db.baseExercises);
        final log = r.readTable(db.workoutLogs);

        final dateKey = DateFormat('yyyy-MM-dd').format(log.date);
        final bw = bwMap[dateKey];
        final details = _detectLoadDetails(ex);

        double? totalLoad;
        if (details.type == 'LASTRE') {
          totalLoad = (bw ?? 0) + set.weight;
        } else if (details.type == 'EXT.LOAD') {
          totalLoad = set.weight;
        } else if (details.type == 'JST.BW') {
          totalLoad = bw ?? 0;
        } else if (details.type == 'UNMOVABLE') {
          totalLoad = (bw ?? 0) + set.weight;
        }

        final fullName = ex.fullName;
        final classification =
            ex.parsedComplexMetadata["classification"] ?? "C";
        final classShort =
            classification.toString().startsWith('I') ? 'I' : 'C';
        final loadNature =
            "[$classShort] ${details.isIsometric ? 'ISO+' : ''}${details.type}";

        final eorm = WorkoutCalculator.calculateEpley1RM(
            totalLoad ?? set.weight, set.reps);

        daySetCounter++;
        final setNumber = daySetCounter;

        String failureText = "";
        if (set.failurePhase != null) {
          Map<String, dynamic> phs = {};
          if (ex.phaseDescriptions != null) {
            try {
              final Map<String, dynamic> meta =
                  jsonDecode(ex.phaseDescriptions!);
              phs = meta["phases"] as Map<String, dynamic>? ?? {};
            } catch (_) {}
          }
          failureText =
              (phs[set.failurePhase.toString()] ?? "PHASE ${set.failurePhase}")
                  .toString()
                  .toUpperCase();
        }

        String togglesText = "";
        if (set.complexMetadata != null) {
          try {
            final Map<String, dynamic> setMeta =
                jsonDecode(set.complexMetadata!);
            final Map<String, dynamic> exMeta = ex.parsedComplexMetadata;
            final List<String> availableToggles =
                List<String>.from(exMeta["particular_toggles"] ?? []);
            final activeToggles =
                availableToggles.where((t) => setMeta[t] == true).toList();
            if (activeToggles.isNotEmpty)
              togglesText = activeToggles.join(", ");
          } catch (_) {}
        }

        final somatics = somaticMap[set.id] ?? [];
        String somaticText = somatics
            .map((s) => "${s.description} (Spectrum:${s.spectrumValue})")
            .join(" | ");

        String sideText = "-";
        if (ex.isUnilateral && set.complexMetadata != null) {
          try {
            final Map<String, dynamic> meta = jsonDecode(set.complexMetadata!);
            if (meta["side"] == "RIGHT") {
              sideText = "R";
            } else if (meta["side"] == "LEFT") {
              sideText = "L";
            }
          } catch (_) {}
        }

        String? priority = set.priority;
        CellStyle? priorityStyle;
        if (priority != null && priority.isNotEmpty) {
          final color =
              tC.getColor(settings, "PRIORITY_$priority", nameSeed: priority);
          final hexColor =
              '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
          priorityStyle =
              CellStyle(backgroundColorHex: ExcelColor.fromHexString(hexColor));
        }

        sheet.appendRow([
          IntCellValue(setNumber),
          TextCellValue(DateFormat('yyyy-MM-dd').format(log.date)),
          TextCellValue(fullName),
          TextCellValue(sideText),
          TextCellValue(loadNature),
          DoubleCellValue(set.weight),
          TextCellValue(
              "${set.reps.toString().replaceAll(RegExp(r'\.0$'), '')}${details.isIsometric ? 's' : ''}"),
          DoubleCellValue(double.parse(eorm.toStringAsFixed(2))),
          TextCellValue(set.isPr ? "YES" : ""),
          TextCellValue(set.rpe?.toString() ?? ""),
          TextCellValue(set.rir?.toString() ?? ""),
          IntCellValue(set.technique ?? 0),
          TextCellValue(failureText),
          TextCellValue(togglesText),
          TextCellValue(set.notes ?? ""),
          TextCellValue(somaticText)
        ]);

        if (priorityStyle != null) {
          final rowIdx = sheet.maxRows - 1;
          for (var colIdx = 0; colIdx < 17; colIdx++) {
            sheet
                .cell(CellIndex.indexByColumnRow(
                    columnIndex: colIdx, rowIndex: rowIdx))
                .cellStyle = priorityStyle;
          }
        }
      }

      // Append session general notes if present
      final dayLog = dayRows.first.readTable(db.workoutLogs);
      final rawNotes = dayLog.notes ?? "";
      final cleanNotes =
          rawNotes.replaceAll(RegExp(r'\[S:[\d.]+\]'), '').trim();
      final noteBlocks = cleanNotes
          .split('||NOTE||')
          .map((n) => n.trim())
          .where((n) => n.isNotEmpty)
          .toList();
      if (noteBlocks.isNotEmpty) {
        for (var ni = 0; ni < noteBlocks.length; ni++) {
          sheet.appendRow([
            TextCellValue('NOTE_${ni + 1}:'),
            TextCellValue(noteBlocks[ni].toUpperCase())
          ]);
        }
      }

      // Empty row between days
      sheet.appendRow([]);
    }

    final fileBytes = excel.save();
    if (fileBytes != null) {
      final output = await getTemporaryDirectory();
      final ts = DateTime.now().millisecondsSinceEpoch;
      final file =
          File("${output.path}/${fileName ?? 'gymr_workouts_$ts'}.xlsx");
      await file.writeAsBytes(fileBytes);
      if (share) {
        await SharePlus.instance.share(
            ShareParams(files: [XFile(file.path)],
                text: 'Workout Data Excel'));
      }
    }
  }

  static Future<void> exportWorkoutsToCsv(
      List<TypedResult> rows, AppDatabase db,
      {String? fileName, bool share = true, String lang = 'en'}) async {
    List<List<dynamic>> csvData = [];

    // 1. PRE-FETCH DATA (BATCH)
    final allDates =
        rows.map((r) => r.readTable(db.workoutLogs).date).toSet().toList();
    final allSetIds = rows.map((r) => r.readTable(db.workoutSets).id).toList();

    final bwMap = await _batchFetchBodyweights(db, allDates);
    final somaticMap = await _batchFetchSomatics(db, allSetIds);

    // Grouping by Day
    final Map<String, List<TypedResult>> groupedByDay = {};
    for (var r in rows) {
      final log = r.readTable(db.workoutLogs);
      final key = DateFormat('yyyy-MM-dd').format(log.date);
      groupedByDay.putIfAbsent(key, () => []).add(r);
    }

    final sortedDays = groupedByDay.keys.toList()..sort();

    for (var dayKey in sortedDays) {
      final dayRows = groupedByDay[dayKey]!;
      final displayDate = DateFormat('EEEE, MMM d, yyyy')
          .format(DateTime.parse(dayKey))
          .toUpperCase();

      // Day Segment Separator
      csvData.add(["---", "DAY_SEGMENT: $displayDate", "---"]);
      csvData.add([
        tr(lang, "SET #"),
        tr(lang, "DATE"),
        tr(lang, "EXERCISE"),
        "UTIL",
        "L/R",
        tr(lang, "NATURE"),
        tr(lang, "LOAD"),
        "REPS/SECS",
        "EORM",
        "PR",
        "RPE",
        "RIR",
        "TECH",
        tr(lang, "FAILURE"),
        tr(lang, "TOGGLES"),
        tr(lang, "NOTES"),
        tr(lang, "SOMATIC")
      ]);

      int daySetCounter = 0;

      for (var r in dayRows) {
        final set = r.readTable(db.workoutSets);
        final ex = r.readTable(db.baseExercises);
        final log = r.readTable(db.workoutLogs);

        final dateKey = DateFormat('yyyy-MM-dd').format(log.date);
        final bw = bwMap[dateKey];
        final details = _detectLoadDetails(ex);

        double? totalLoad;
        if (details.type == 'LASTRE') {
          totalLoad = (bw ?? 0) + set.weight;
        } else if (details.type == 'EXT.LOAD') {
          totalLoad = set.weight;
        } else if (details.type == 'JST.BW') {
          totalLoad = bw ?? 0;
        } else if (details.type == 'UNMOVABLE') {
          totalLoad = (bw ?? 0) + set.weight;
        }

        final fullName = ex.fullName;
        final classification =
            ex.parsedComplexMetadata["classification"] ?? "C";
        final classShort =
            classification.toString().startsWith('I') ? 'I' : 'C';
        final loadNature =
            "[$classShort] ${details.isIsometric ? 'ISO+' : ''}${details.type}";

        final eorm = WorkoutCalculator.calculateEpley1RM(
            totalLoad ?? set.weight, set.reps);

        daySetCounter++;
        final setNumber = daySetCounter;

        String failureText = "";
        if (set.failurePhase != null) {
          Map<String, dynamic> phs = {};
          if (ex.phaseDescriptions != null) {
            try {
              final Map<String, dynamic> meta =
                  jsonDecode(ex.phaseDescriptions!);
              phs = meta["phases"] as Map<String, dynamic>? ?? {};
            } catch (_) {}
          }
          failureText =
              (phs[set.failurePhase.toString()] ?? "PHASE ${set.failurePhase}")
                  .toString()
                  .toUpperCase();
        }

        String togglesText = "";
        if (set.complexMetadata != null) {
          try {
            final Map<String, dynamic> setMeta =
                jsonDecode(set.complexMetadata!);
            final Map<String, dynamic> exMeta = ex.parsedComplexMetadata;
            final List<String> availableToggles =
                List<String>.from(exMeta["particular_toggles"] ?? []);
            final activeToggles =
                availableToggles.where((t) => setMeta[t] == true).toList();
            if (activeToggles.isNotEmpty)
              togglesText = activeToggles.join(", ");
          } catch (_) {}
        }

        final somatics = somaticMap[set.id] ?? [];
        String somaticText = somatics
            .map((s) => "${s.description} (Spectrum:${s.spectrumValue})")
            .join(" | ");

        String sideText = "-";
        if (ex.isUnilateral && set.complexMetadata != null) {
          try {
            final Map<String, dynamic> meta = jsonDecode(set.complexMetadata!);
            if (meta["side"] == "RIGHT") {
              sideText = "R";
            } else if (meta["side"] == "LEFT") {
              sideText = "L";
            }
          } catch (_) {}
        }

        csvData.add([
          setNumber,
          DateFormat('yyyy-MM-dd').format(log.date),
          fullName,
          set.priority?.toUpperCase() ?? "-",
          sideText,
          loadNature,
          set.weight,
          "${set.reps.toString().replaceAll(RegExp(r'\.0$'), '')}${details.isIsometric ? 's' : ''}",
          eorm.toStringAsFixed(2),
          set.isPr ? "YES" : "",
          set.rpe ?? "",
          set.rir ?? "",
          set.technique ?? "",
          failureText,
          togglesText,
          set.notes ?? "",
          somaticText
        ]);
      }

      final dayLog = dayRows.first.readTable(db.workoutLogs);
      final rawNotes = dayLog.notes ?? "";
      final cleanNotes =
          rawNotes.replaceAll(RegExp(r'\[S:[\d.]+\]'), '').trim();
      final noteBlocks = cleanNotes
          .split('||NOTE||')
          .map((n) => n.trim())
          .where((n) => n.isNotEmpty)
          .toList();
      for (var ni = 0; ni < noteBlocks.length; ni++) {
        csvData.add(["NOTE_${ni + 1}:", noteBlocks[ni].toUpperCase()]);
      }

      csvData.add([]); // Blank row between days
    }

    final output = await getTemporaryDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final file = File("${output.path}/${fileName ?? 'gymr_workouts_$ts'}.csv");
    await file.writeAsString(_encodeCsv(csvData));
    await Share.shareXFiles([XFile(file.path)], text: 'Workouts CSV');
  }

  static Future<void> exportWorkoutsToMarkdown(List<TypedResult> rows,
      AppDatabase db, Map<String, ThemeSetting> settings, ThemeController tC,
      {String? fileName, bool share = true, String lang = 'en'}) async {
    final buffer = StringBuffer();

    // 1. PRE-FETCH DATA (BATCH)
    final allDates =
        rows.map((r) => r.readTable(db.workoutLogs).date).toSet().toList();
    final allSetIds = rows.map((r) => r.readTable(db.workoutSets).id).toList();

    final bwMap = await _batchFetchBodyweights(db, allDates);
    final somaticMap = await _batchFetchSomatics(db, allSetIds);

    // Grouping by Month/Year and then by Day
    final Map<String, Map<String, List<TypedResult>>> groupedData = {};
    for (var r in rows) {
      final log = r.readTable(db.workoutLogs);
      final monthKey = DateFormat('MMMM yyyy').format(log.date);
      final dayKey = DateFormat('yyyy-MM-dd').format(log.date);

      groupedData.putIfAbsent(monthKey, () => {});
      groupedData[monthKey]!.putIfAbsent(dayKey, () => []).add(r);
    }

    final sortedMonths = groupedData.keys.toList()
      ..sort((a, b) {
        final dateA = DateFormat('MMMM yyyy').parse(a);
        final dateB = DateFormat('MMMM yyyy').parse(b);
        return dateA.compareTo(dateB);
      });

    List<Map<String, dynamic>> somaticAnomalies = [];
    List<Map<String, dynamic>> somaticRecoveries = [];
    final List<Map<String, String>> exerciseDescriptions = [];
    final Set<int> processedExerciseIds = {};
    final Map<String, List<Map<String, dynamic>>> supersetGroups = {};

    buffer.writeln("# GYMR // TECHNICAL_WORKOUT_REPORT");
    buffer.writeln(
        "${tr(lang, 'Generated on:')} ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}");
    buffer.writeln();

    for (var monthKey in sortedMonths) {
      buffer.writeln("## ${monthKey.toUpperCase()}");
      buffer.writeln();

      final monthDays = groupedData[monthKey]!;
      final sortedDays = monthDays.keys.toList()..sort();

      for (var dayKey in sortedDays) {
        final dayRows = monthDays[dayKey]!;
        final displayDate = DateFormat('EEEE, MMM d, yyyy')
            .format(DateTime.parse(dayKey))
            .toUpperCase();

        buffer.writeln("### $displayDate");
        buffer.writeln();
        buffer.writeln(
            "| ${tr(lang, 'SET')} | ${tr(lang, 'EXERCISE')} | UTIL. | L/R | NAT. | ${tr(lang, 'LOAD')} | REPS/SECS | EORM | PR | RPE | RIR | TECH | FAIL | ${tr(lang, 'TOGGLES')} | ${tr(lang, 'NOTES')} |");
        buffer.writeln(
            "|:---|:---|:---:|:---:|:---|:---|:---:|:---:|:---:|:---:|:---:|:---:|:---|:---|:---|");

        int daySetCounter = 0;

        for (var r in dayRows) {
          final set = r.readTable(db.workoutSets);
          final ex = r.readTable(db.baseExercises);
          final log = r.readTable(db.workoutLogs);

          final dateKey = DateFormat('yyyy-MM-dd').format(log.date);
          final bw = bwMap[dateKey];
          final details = _detectLoadDetails(ex);

          double? totalLoad;
          if (details.type == 'LASTRE') {
            totalLoad = (bw ?? 0) + set.weight;
          } else if (details.type == 'EXT.LOAD') {
            totalLoad = set.weight;
          } else if (details.type == 'JST.BW') {
            totalLoad = bw ?? 0;
          } else if (details.type == 'UNMOVABLE') {
            totalLoad = (bw ?? 0) + set.weight;
          }

          final fullName = ex.fullName;
          final classification =
              ex.parsedComplexMetadata["classification"] ?? "C";
          final classShort =
              classification.toString().startsWith('I') ? 'I' : 'C';
          final loadNature =
              "[$classShort] ${details.isIsometric ? 'ISO+' : ''}${details.type}";

          final eorm = WorkoutCalculator.calculateEpley1RM(
              totalLoad ?? set.weight, set.reps);

          daySetCounter++;
          final setNumber = daySetCounter;

          // 1. Technique
          final techText = set.technique?.toString() ?? "-";

          // 2. Failure Phase
          String failureText = "-";
          if (set.failurePhase != null) {
            Map<String, dynamic> phs = {};
            if (ex.phaseDescriptions != null) {
              try {
                final Map<String, dynamic> meta =
                    jsonDecode(ex.phaseDescriptions!);
                phs = meta["phases"] as Map<String, dynamic>? ?? {};
              } catch (_) {}
            }
            failureText = (phs[set.failurePhase.toString()] ??
                    "PHASE ${set.failurePhase}")
                .toString()
                .toUpperCase();
          }

          // 3. Particular Toggles
          String togglesText = "-";
          if (set.complexMetadata != null) {
            try {
              final Map<String, dynamic> setMeta =
                  jsonDecode(set.complexMetadata!);
              final Map<String, dynamic> exMeta = ex.parsedComplexMetadata;
              final List<String> availableToggles =
                  List<String>.from(exMeta["particular_toggles"] ?? []);
              final activeToggles =
                  availableToggles.where((t) => setMeta[t] == true).toList();
              if (activeToggles.isNotEmpty)
                togglesText = activeToggles.join(", ");
            } catch (_) {}
          }

          // 4. Somatic Discomfort (Batch)
          final somatics = somaticMap[set.id] ?? [];
          if (somatics.isNotEmpty) {
            for (final s in somatics) {
              if (s.spectrumValue < 0) {
                somaticAnomalies.add({
                  'date': DateFormat('dd/MM/yy').format(log.date),
                  'exercise': fullName,
                  'logs': "${s.description} (Spectrum:${s.spectrumValue})"
                });
              } else if (s.spectrumValue > 0) {
                somaticRecoveries.add({
                  'date': DateFormat('dd/MM/yy').format(log.date),
                  'exercise': fullName,
                  'logs': "${s.description} (Spectrum:${s.spectrumValue})"
                });
              }
            }
          }

          // 5. Unilateral side detection
          String sideText = "-";
          bool isUnilateral = false;
          if (ex.isUnilateral && set.complexMetadata != null) {
            try {
              final Map<String, dynamic> meta =
                  jsonDecode(set.complexMetadata!);
              if (meta["side"] == "RIGHT") {
                sideText = "R";
                isUnilateral = true;
              } else if (meta["side"] == "LEFT") {
                sideText = "L";
                isUnilateral = true;
              }
            } catch (_) {}
          }

          buffer.writeln(
              "| $setNumber | $fullName${isUnilateral ? ' (UNI)' : ''} | ${set.priority?.toUpperCase() ?? "-"} | $sideText | $loadNature | ${set.weight}KG | ${set.reps.toString().replaceAll(RegExp(r'\.0$'), '')}${details.isIsometric ? 's' : ''} | ${eorm.toStringAsFixed(1)} | ${set.isPr ? "**YES**" : ""} | ${set.rpe?.toString() ?? "-"} | ${set.rir?.toString() ?? "-"} | $techText | $failureText | $togglesText | ${set.notes?.replaceAll('\n', ' ') ?? "-"} |");

          // Global Collections
          if (!processedExerciseIds.contains(ex.id)) {
            final desc =
                ex.parsedComplexMetadata["description"]?.toString() ?? "";
            if (desc.isNotEmpty)
              exerciseDescriptions.add({'name': ex.fullName, 'desc': desc});
            processedExerciseIds.add(ex.id);
          }

          if (set.supersetGroupId != null) {
            final dateKeySup = DateFormat('dd/MM/yy').format(log.date);
            final groupKey = "${dateKeySup}_${set.supersetGroupId}";
            supersetGroups.putIfAbsent(groupKey, () => []);
            if (!supersetGroups[groupKey]!
                .any((e) => e['name'] == ex.fullName)) {
              supersetGroups[groupKey]!.add({
                'name': ex.fullName,
                'supersetName': set.supersetName ?? 'SUPERSET',
                'date': dateKeySup
              });
            }
          }
        }

        final dayLog = dayRows.first.readTable(db.workoutLogs);
        final rawNotes = dayLog.notes ?? "";
        final cleanNotes =
            rawNotes.replaceAll(RegExp(r'\[S:[\d.]+\]'), '').trim();
        final noteBlocks = cleanNotes
            .split('||NOTE||')
            .map((n) => n.trim())
            .where((n) => n.isNotEmpty)
            .toList();
        if (noteBlocks.isNotEmpty) {
          buffer.writeln("**SESSION_GENERAL_NOTES:**");
          for (var ni = 0; ni < noteBlocks.length; ni++) {
            buffer.writeln("- **[${ni + 1}]** ${noteBlocks[ni].toUpperCase()}");
          }
          buffer.writeln();
        }

        buffer.writeln();
      }
    }

    if (somaticAnomalies.isNotEmpty) {
      buffer.writeln("## SOMATIC_ANOMALIES_LOG");
      buffer.writeln();
      buffer.writeln("| ${tr(lang, 'DATE')} | ${tr(lang, 'EXERCISE')} | ANOMALY_DETAILS |");
      buffer.writeln("|:---|:---|:---|");
      for (var a in somaticAnomalies) {
        buffer.writeln("| ${a['date']} | ${a['exercise']} | ${a['logs']} |");
      }
      buffer.writeln();
    }

    if (somaticRecoveries.isNotEmpty) {
      buffer.writeln("## SOMATIC_RECOVERY_LOG");
      buffer.writeln();
      buffer.writeln("| ${tr(lang, 'DATE')} | ${tr(lang, 'EXERCISE')} | RECOVERY_DETAILS |");
      buffer.writeln("|:---|:---|:---|");
      for (var r in somaticRecoveries) {
        buffer.writeln("| ${r['date']} | ${r['exercise']} | ${r['logs']} |");
      }
      buffer.writeln();
    }

    if (exerciseDescriptions.isNotEmpty) {
      buffer.writeln("## EXERCISE_TECHNICAL_DESCRIPTIONS");
      buffer.writeln();
      buffer.writeln("| ${tr(lang, 'EXERCISE')} | TECHNICAL_DESCRIPTION |");
      buffer.writeln("|:---|:---|");
      for (var e in exerciseDescriptions) {
        buffer
            .writeln("| ${e['name']} | ${e['desc']?.replaceAll('\n', ' ')} |");
      }
      buffer.writeln();
    }

    if (supersetGroups.isNotEmpty) {
      buffer.writeln("## SUPERSET_BLOCKS_STRUCTURE");
      buffer.writeln();
      buffer.writeln("| ${tr(lang, 'DATE')} | SUPERSET_NAME | ${tr(lang, 'COMPONENTS')} |");
      buffer.writeln("|:---|:---|:---|");
      for (var group in supersetGroups.values) {
        buffer.writeln(
            "| ${group.first['date']} | ${group.first['supersetName'].toString().toUpperCase()} | ${group.map((e) => e['name']).join(" <-> ")} |");
      }
      buffer.writeln();
    }

    final output = await getTemporaryDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final file = File("${output.path}/${fileName ?? 'gymr_report_$ts'}.md");
    await file.writeAsString(buffer.toString());
    if (share) {
      await SharePlus.instance.share(
          ShareParams(files: [XFile(file.path)],
              text: 'GYMR Markdown Report'));
    }
  }

  // Shared with kns_tree_manager_screen.dart (KNST.FIXER/KNST.ALERT), so
  // both the in-app screens and this exporter agree on exactly what counts
  // as a
  // relational issue: progressions/regressions/alters pointing at a name
  // that doesn't exist in the exercise inventory, or missing the
  // reciprocal entry on the other side. Each issue keeps the offending
  // BaseExercise object (not just its name) so the screen can still
  // navigate to it on tap.
  static const Map<String, String> kKnsReciprocal = {
    "progressions": "regressions",
    "regressions": "progressions",
    "alters": "alters",
  };

  static List<Map<String, dynamic>> findKnsTreeIssues(
      List<BaseExercise> exercises) {
    final byName = {for (final e in exercises) e.fullName: e};
    final issues = <Map<String, dynamic>>[];

    for (final e in exercises) {
      final meta = e.parsedComplexMetadata;
      for (final category in kKnsReciprocal.keys) {
        final targets = List<String>.from(meta[category] ?? []);
        for (final targetName in targets) {
          final target = byName[targetName];
          if (target == null) {
            issues.add({
              'exercise': e,
              'label': 'BROKEN_LINK ($category -> "$targetName" NOT_FOUND)',
            });
            continue;
          }
          final oppositeCategory = kKnsReciprocal[category]!;
          final targetMeta = target.parsedComplexMetadata;
          final reciprocalList =
              List<String>.from(targetMeta[oppositeCategory] ?? []);
          if (!reciprocalList.contains(e.fullName)) {
            issues.add({
              'exercise': e,
              'label':
                  'ONE_SIDED_LINK ($category -> "${target.fullName}" missing reciprocal $oppositeCategory)',
            });
          }
        }
      }
    }

    issues.sort((a, b) => (a['exercise'] as BaseExercise)
        .fullName
        .compareTo((b['exercise'] as BaseExercise).fullName));
    return issues;
  }

  static Future<String> exportKnsTreeAlertToMarkdown(
      List<BaseExercise> exercises,
      {bool share = true}) async {
    final issues = findKnsTreeIssues(exercises);
    final buffer = StringBuffer();
    buffer.writeln("# GYMR // KNS.TREE.ALERT");
    buffer.writeln();
    buffer.writeln("Generated: ${DateTime.now().toIso8601String()}");
    buffer.writeln();

    if (issues.isEmpty) {
      buffer.writeln("No relational issues found.");
    } else {
      final flaggedCount =
          issues.map((i) => (i['exercise'] as BaseExercise).id).toSet().length;
      buffer.writeln(
          "${issues.length} broken links across $flaggedCount movements.");
      buffer.writeln();
      buffer.writeln("| EXERCISE | ISSUE |");
      buffer.writeln("|:---|:---|");
      for (final issue in issues) {
        final exName = (issue['exercise'] as BaseExercise).fullName;
        buffer.writeln("| $exName | ${issue['label']} |");
      }
    }
    buffer.writeln();

    final output = await getTemporaryDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final file = File("${output.path}/gymr_kns_tree_alert_$ts.md");
    await file.writeAsString(buffer.toString());
    if (share) {
      await SharePlus.instance.share(ShareParams(
          files: [XFile(file.path)], text: 'GYMR KNS.TREE.ALERT Report'));
    }
    return file.path;
  }

  static Future<void> exportBlueprintsToCsv(
      List<Map<String, dynamic>> combinedData, AppDatabase db,
      {String lang = 'en'}) async {
    List<List<dynamic>> csvData = [
      ["BP_NAME", "BP_INTENTION", "EX_NAME", "TARGET_SETS_REPS", "ORDER"]
    ];

    for (var item in combinedData) {
      final bp = item['blueprint'] as Blueprint;
      final exercises = item['exercises'] as List<TypedResult>;

      for (var exRow in exercises) {
        final ex = exRow.readTable(db.baseExercises);
        final bpEx = exRow.readTable(db.blueprintExercises);
        csvData.add([
          bp.name,
          bp.intention,
          ex.name,
          bpEx.targetSetsReps ?? "",
          bpEx.orderIndex
        ]);
      }
    }

    final output = await getTemporaryDirectory();
    final file = File(
        "${output.path}/blueprints_full_${DateTime.now().millisecondsSinceEpoch}.csv");
    await file.writeAsString(_encodeCsv(csvData));
    await Share.shareXFiles([XFile(file.path)], text: 'Blueprints Full CSV');
  }

  static Future<Map<String, int>> importBlueprintsFromCsv(
      String csvContent, AppDatabase db) async {
    final rows = _decodeCsv(csvContent);
    if (rows.isEmpty) return {"blueprints": 0, "exercises": 0};

    int blueprintsCount = 0;
    int exercisesCount = 0;
    Map<String, int> bpCache = {};

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < 3) continue;

      final bpName = row[0];
      final bpIntention = row[1];
      final exName = row[2];
      final targetSetsReps = row.length > 3 ? row[3] : "";
      final orderIndex = row.length > 4 ? int.tryParse(row[4]) ?? 0 : 0;

      if (bpName.isEmpty) continue;

      int bpId;
      if (bpCache.containsKey(bpName)) {
        bpId = bpCache[bpName]!;
      } else {
        bpId = await db.into(db.blueprints).insert(
              BlueprintsCompanion.insert(
                name: bpName,
                intention: bpIntention,
              ),
              mode: InsertMode.insertOrIgnore,
            );
        if (bpId <= 0) {
          final existing = await (db.select(db.blueprints)
                ..where((t) => t.name.equals(bpName)))
              .getSingleOrNull();
          bpId = existing?.id ?? 0;
        } else {
          blueprintsCount++;
        }
        bpCache[bpName] = bpId;
      }

      final existingEx = await (db.select(db.baseExercises)
            ..where((t) => t.name.equals(exName)))
          .getSingleOrNull();
      int exId;
      if (existingEx != null) {
        exId = existingEx.id;
      } else {
        exId = await db.into(db.baseExercises).insert(
              BaseExercisesCompanion.insert(name: exName),
            );
      }

      await db.into(db.blueprintExercises).insert(
            BlueprintExercisesCompanion.insert(
              blueprintId: bpId,
              baseExerciseId: exId,
              targetSetsReps: Value(targetSetsReps),
              orderIndex: orderIndex,
            ),
          );
      exercisesCount++;
    }

    return {"blueprints": blueprintsCount, "exercises": exercisesCount};
  }

  static Future<Map<String, int>> importFromFitNotes(
      String csvContent, AppDatabase db) async {
    final rows = _decodeCsv(csvContent);
    if (rows.isEmpty) return {"logs": 0, "sets": 0, "exercises": 0};

    int logsCount = 0;
    int setsCount = 0;
    int exercisesCount = 0;

    Map<String, int> logCache = {};
    Map<String, int> exerciseCache = {};

    await db.transaction(() async {
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.length < 6) continue;

        final dateStr = row[0].trim();
        final exName = row[1].trim();
        final category = row[2].trim();
        final weight = double.tryParse(row[3].trim()) ?? 0.0;
        final reps = double.tryParse(row[5].trim()) ?? 0.0;
        final comment = row.length > 9 ? row[9].trim() : null;

        if (dateStr.isEmpty || exName.isEmpty) continue;

        int logId;
        DateTime date;
        try {
          date = DateTime.parse(dateStr);
        } catch (e) {
          continue;
        }

        final dateOnly = DateTime(date.year, date.month, date.day);
        final dateKey = DateFormat('yyyy-MM-dd').format(dateOnly);

        if (logCache.containsKey(dateKey)) {
          logId = logCache[dateKey]!;
        } else {
          final existingLog = await (db.select(db.workoutLogs)
                ..where((t) => t.date.equals(dateOnly)))
              .getSingleOrNull();
          if (existingLog != null) {
            logId = existingLog.id;
          } else {
            logId = await db.into(db.workoutLogs).insert(
                  WorkoutLogsCompanion.insert(
                      date: dateOnly,
                      notes: Value(comment != null && comment.isNotEmpty
                          ? comment
                          : null)),
                );
            logsCount++;
          }
          logCache[dateKey] = logId;
        }

        int exId;
        final exerciseKey = exName.toUpperCase();
        if (exerciseCache.containsKey(exerciseKey)) {
          exId = exerciseCache[exerciseKey]!;
        } else {
          final existingEx = await (db.select(db.baseExercises)
                ..where((t) => t.name.equals(exName)))
              .getSingleOrNull();
          if (existingEx != null) {
            exId = existingEx.id;
          } else {
            exId = await db.into(db.baseExercises).insert(
                  BaseExercisesCompanion.insert(
                    name: exName,
                    primaryMuscleGroup:
                        Value(category.isNotEmpty ? category : null),
                    intention: const Value('[NT:EXT.LOAD|ISO:false]'),
                  ),
                );
            exercisesCount++;
          }
          exerciseCache[exerciseKey] = exId;
        }

        final timestamp =
            dateOnly.add(Duration(minutes: (setsCount % 600) + 480));

        await db.into(db.workoutSets).insert(
              WorkoutSetsCompanion.insert(
                logId: logId,
                baseExerciseId: exId,
                weight: weight,
                reps: reps,
                timestamp: Value(timestamp),
              ),
            );
        setsCount++;
      }
    });

    return {"logs": logsCount, "sets": setsCount, "exercises": exercisesCount};
  }

  static Future<String> exportExercisesToCsv(List<BaseExercise> exercises,
      {bool share = true, String lang = 'en'}) async {
    List<List<dynamic>> csvData = [
      [
        "NAME",
        "PREFIXES",
        "IMPLEMENTS",
        "BODY_POSITIONS",
        "SUFFIXES",
        "PRIMARY_MUSCLE",
        "SECONDARY_MUSCLE",
        "FIELD",
        "TISSUE_TYPE",
        "TISSUE_NAME",
        "NUM_PHASES",
        "PHASE_DESCRIPTIONS",
        "INTENTION",
        "PATTERN_TYPE",
        "COMPLEX_METADATA",
        "IS_UNILATERAL",
        "DESCRIPTION"
      ]
    ];

    for (var ex in exercises) {
      final desc = ex.parsedComplexMetadata["description"]?.toString() ?? "";
      csvData.add([
        ex.name,
        ex.prefixes ?? "",
        ex.implements ?? "",
        ex.bodyPositions ?? "",
        ex.suffixes ?? "",
        ex.primaryMuscleGroup ?? "",
        ex.secondaryMuscleGroup ?? "",
        ex.field ?? "",
        ex.tissueType ?? "",
        ex.tissueName ?? "",
        ex.numPhases ?? 1,
        ex.phaseDescriptions ?? "",
        ex.intention ?? "",
        ex.patternType ?? "",
        ex.complexMetadata ?? "",
        ex.isUnilateral ? 1 : 0,
        desc
      ]);
    }

    final output = await getTemporaryDirectory();
    final file = File(
        "${output.path}/gymr_exercises_${DateTime.now().millisecondsSinceEpoch}.csv");
    await file.writeAsString(_encodeCsv(csvData));
    await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)],
            text: 'GYMR Exercises CSV Export'));
    return file.path;
  }

  static Future<String> exportExercisesToExcel(
      List<BaseExercise> exercises) async {
    var excel = Excel.createExcel();
    excel.rename('Sheet1', 'EXERCISES');
    Sheet sheet = excel.sheets.entries.first.value;

    final headerStyle = CellStyle(
        bold: true, fontColorHex: ExcelColor.fromHexString('#00FFFF'));
    sheet.appendRow([
      TextCellValue("NAME"),
      TextCellValue("PREFIXES"),
      TextCellValue("IMPLEMENTS"),
      TextCellValue("BODY_POSITIONS"),
      TextCellValue("SUFFIXES"),
      TextCellValue("PRIMARY_MUSCLE"),
      TextCellValue("SECONDARY_MUSCLE"),
      TextCellValue("FIELD"),
      TextCellValue("TISSUE_TYPE"),
      TextCellValue("TISSUE_NAME"),
      TextCellValue("NUM_PHASES"),
      TextCellValue("PHASE_DESCRIPTIONS"),
      TextCellValue("INTENTION"),
      TextCellValue("PATTERN_TYPE"),
      TextCellValue("COMPLEX_METADATA"),
      TextCellValue("IS_UNILATERAL"),
      TextCellValue("DESCRIPTION"),
    ]);
    for (int ci = 0; ci < 17; ci++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: ci, rowIndex: 0))
          .cellStyle = headerStyle;
    }

    for (var ex in exercises) {
      final desc = ex.parsedComplexMetadata["description"]?.toString() ?? "";
      sheet.appendRow([
        TextCellValue(ex.name),
        TextCellValue(ex.prefixes ?? ""),
        TextCellValue(ex.implements ?? ""),
        TextCellValue(ex.bodyPositions ?? ""),
        TextCellValue(ex.suffixes ?? ""),
        TextCellValue(ex.primaryMuscleGroup ?? ""),
        TextCellValue(ex.secondaryMuscleGroup ?? ""),
        TextCellValue(ex.field ?? ""),
        TextCellValue(ex.tissueType ?? ""),
        TextCellValue(ex.tissueName ?? ""),
        IntCellValue(ex.numPhases ?? 1),
        TextCellValue(ex.phaseDescriptions ?? ""),
        TextCellValue(ex.intention ?? ""),
        TextCellValue(ex.patternType ?? ""),
        TextCellValue(ex.complexMetadata ?? ""),
        IntCellValue(ex.isUnilateral ? 1 : 0),
        TextCellValue(desc),
      ]);
    }

    final output = await getTemporaryDirectory();
    final filePath =
        "${output.path}/gymr_exercises_${DateTime.now().millisecondsSinceEpoch}.xlsx";
    await File(filePath).writeAsBytes(excel.encode()!);
    return filePath;
  }

  // Shared by importExercisesFromCsv/Excel: [cells] is the row already
  // normalized to plain strings (17 positions, matching exportExercisesToCsv's
  // header order), so both formats funnel through one upsert path instead of
  // duplicating the same ~50 lines of field mapping twice.
  //
  // Upserts by exact NAME match: an existing exercise is UPDATED with the
  // row's values (not left untouched) so "export, edit in NEXUS skill,
  // re-import" actually applies the edits instead of silently no-op'ing.
  static Future<bool> _upsertExerciseRow(
      AppDatabase db, List<String?> cells) async {
    String? cell(int i) =>
        (i < cells.length && (cells[i]?.isNotEmpty ?? false)) ? cells[i] : null;

    final name = cell(0)?.trim();
    if (name == null || name.isEmpty) return false;

    String? complexMeta = cell(14);
    final description = cell(16);
    if (description != null) {
      Map<String, dynamic> meta = {};
      if (complexMeta != null) {
        try {
          meta = jsonDecode(complexMeta);
        } catch (_) {}
      }
      meta["description"] = description;
      complexMeta = jsonEncode(meta);
    }

    final numPhases = int.tryParse(cell(10) ?? '') ?? 1;
    final isUnilateralRaw = cell(15);
    final isUnilateral = isUnilateralRaw == "1" ||
        (isUnilateralRaw?.toLowerCase() == "true");

    try {
      final existing = await (db.select(db.baseExercises)
            ..where((t) => t.name.equals(name)))
          .getSingleOrNull();

      final companion = BaseExercisesCompanion(
        name: Value(name),
        prefixes: Value(cell(1)),
        implements: Value(cell(2)),
        bodyPositions: Value(cell(3)),
        suffixes: Value(cell(4)),
        primaryMuscleGroup: Value(cell(5)),
        secondaryMuscleGroup: Value(cell(6)),
        field: Value(cell(7)),
        tissueType: Value(cell(8)),
        tissueName: Value(cell(9)),
        numPhases: Value(numPhases),
        phaseDescriptions: Value(cell(11)),
        intention: Value(cell(12)),
        patternType: Value(cell(13)),
        complexMetadata: Value(complexMeta),
        isUnilateral: Value(isUnilateral),
      );

      if (existing != null) {
        await (db.update(db.baseExercises)
              ..where((t) => t.id.equals(existing.id)))
            .write(companion);
      } else {
        await db.into(db.baseExercises).insert(companion);
      }
      return true;
    } catch (e) {
      debugPrint("Error importing exercise $name: $e");
      return false;
    }
  }

  static Future<int> importExercisesFromCsv(
      String csvContent, AppDatabase db) async {
    final rows = _decodeCsv(csvContent);
    if (rows.isEmpty) return 0;

    int count = 0;
    await db.transaction(() async {
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty) continue;
        if (await _upsertExerciseRow(db, row)) count++;
      }
    });

    return count;
  }

  static Future<int> importExercisesFromExcel(
      List<int> bytes, AppDatabase db) async {
    var excel = Excel.decodeBytes(bytes);
    int count = 0;

    // Every sheet with data is imported (not just the first) - a workbook
    // split across multiple sheets no longer silently loses data.
    for (var table in excel.tables.keys) {
      final sheet = excel.tables[table];
      if (sheet == null || sheet.maxRows <= 1) continue;

      await db.transaction(() async {
        for (int i = 1; i < sheet.maxRows; i++) {
          final row = sheet.rows[i];
          if (row.isEmpty || row[0] == null) continue;
          final cells = row.map((c) => c?.value?.toString()).toList();
          if (await _upsertExerciseRow(db, cells)) count++;
        }
      });
    }

    return count;
  }

  static Future<void> generateEmptyExerciseTemplate() async {
    List<List<dynamic>> csvData = [
      [
        "NAME",
        "PREFIXES",
        "IMPLEMENTS",
        "BODY_POSITIONS",
        "SUFFIXES",
        "PRIMARY_MUSCLE",
        "SECONDARY_MUSCLE",
        "FIELD",
        "TISSUE_TYPE",
        "TISSUE_NAME",
        "NUM_PHASES",
        "PHASE_DESCRIPTIONS",
        "INTENTION",
        "PATTERN_TYPE",
        "COMPLEX_METADATA",
        "IS_UNILATERAL",
        "DESCRIPTION"
      ],
      [
        "PULL UP",
        "",
        "WEIGHT VEST",
        "DEAD_HANG",
        "",
        "BACK",
        "BICEPS",
        "STRENGTH",
        "MUSCLE",
        "LATS",
        "1",
        "",
        "[NT:LASTRE|ISO:false]",
        "VERTICAL_PULL",
        "",
        "0",
        "Weighted pull up focused on latissimus dorsi development."
      ]
    ];

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/kinisi_template.csv");
    await file.writeAsString(_encodeCsv(csvData));
    await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)],
            text: 'GYMR Empty KNS Template'));
  }

  // --- RAW TABLE EXPORT ---
  /// Exports a single DB table as CSV. Used by NEXUS raw data section.
  static Future<void> exportTableToCsv(AppDatabase db, String tableName,
      {String lang = 'en'}) async {
    // Query all rows
    final result = await db.customSelect('SELECT * FROM $tableName').get();
    if (result.isEmpty) {
      throw Exception("Table '$tableName' is empty or does not exist.");
    }

    // Build CSV
    final headers = result.first.data.keys.toList();
    final rows = <List<dynamic>>[headers];
    for (final row in result) {
      final csvRow = <String>[];
      for (final key in headers) {
        final val = row.data[key];
        if (val == null) {
          csvRow.add('');
        } else if (val is String) {
          csvRow.add(val);
        } else {
          csvRow.add(val.toString());
        }
      }
      rows.add(csvRow);
    }

    final csvContent = _encodeCsv(rows);
    final output = await getTemporaryDirectory();
    final safeName = tableName.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    final file = File("${output.path}/GYMR_${safeName}_export.csv");
    await file.writeAsString(csvContent);
    await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)],
            text: 'GYMR Database Backup'));
  }

  /// Lists all user tables in the database (excludes sqlite_* and android_* system tables)
  static Future<List<String>> listAllTables(AppDatabase db) async {
    final result = await db
        .customSelect(
            "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'android_%' ORDER BY name")
        .get();
    return result.map((r) => r.data['name'] as String).toList();
  }

  // ─── WORKOUT BLOCK EXPORT/IMPORT ────────────────────────────

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static String _cell(
      List<String> row, Map<String, int> header, String name, int fallback) {
    final index = header[name.toUpperCase()] ?? fallback;
    if (index < 0) return '';
    if (row.length <= index) return '';
    return row[index].trim();
  }

  static Future<Map<String, dynamic>> _resolveExerciseFields(
      AppDatabase db, int? baseExerciseId, String exerciseName) async {
    int resolvedId = _toInt(baseExerciseId) ?? 0;
    if (resolvedId == 0 && exerciseName.trim().isNotEmpty) {
      final existingEx = await (db.select(db.baseExercises)
            ..where((t) => t.name.equals(exerciseName.trim())))
          .getSingleOrNull();
      if (existingEx != null) resolvedId = existingEx.id;
    }

    if (resolvedId != 0) {
      final ex = await (db.select(db.baseExercises)
            ..where((t) => t.id.equals(resolvedId)))
          .getSingleOrNull();
      if (ex != null) {
        return {
          'baseExerciseId': resolvedId,
          'exerciseName': ex.name,
          'field': ex.field,
          'primaryMuscleGroup': ex.primaryMuscleGroup,
          'prefixes': ex.prefixes,
          'suffixes': ex.suffixes,
          'bodyPositions': ex.bodyPositions,
          'implements': ex.implements,
          'isUnilateral': ex.isUnilateral,
        };
      }
    }

    return {
      'baseExerciseId': resolvedId,
      'exerciseName': exerciseName,
      'field': null,
      'primaryMuscleGroup': null,
      'prefixes': null,
      'suffixes': null,
      'bodyPositions': null,
      'implements': null,
      'isUnilateral': false,
    };
  }

  static Future<Map<String, dynamic>> _buildWorkoutBlockCombined(
    AppDatabase db,
    int blockId,
    Map<String, dynamic> wb,
    List<QueryRow> knsRows,
  ) async {
    final List<Map<String, dynamic>> knsList = [];
    for (final knsRow in knsRows) {
      final knsId = knsRow.data['id'] as int;
      final baseExId = knsRow.data['base_exercise_id'] as int;
      final resolved = await _resolveExerciseFields(db, baseExId, '');
      final utilitiesRaw = knsRow.data['utilities'] as String?;
      final List<String> utilities =
          utilitiesRaw != null && utilitiesRaw.isNotEmpty
              ? (() {
                  try {
                    return (jsonDecode(utilitiesRaw) as List).cast<String>();
                  } catch (_) {
                    return <String>[];
                  }
                })()
              : <String>[];
      final metaRaw = knsRow.data['metadata'] as String?;
      String? intention;
      if (metaRaw != null && metaRaw.isNotEmpty) {
        try {
          final meta = jsonDecode(metaRaw) as Map<String, dynamic>;
          intention = meta['intention'] as String?;
        } catch (_) {}
      }

      final setRows = await db
          .customSelect(
              'SELECT id, set_number, reps_min, reps_max, pload, rpe, rir, set_intention, side FROM workout_block_sets WHERE kns_id = $knsId ORDER BY set_number ASC, id ASC')
          .get();

      knsList.add({
        'id': knsId,
        'baseExerciseId': baseExId,
        'exerciseName': resolved['exerciseName'] ?? '',
        'orderIndex': _toInt(knsRow.data['order_index']) ?? 0,
        'utilities': utilities,
        'batchName': knsRow.data['batch_name'] as String?,
        'intention': intention,
        'isUnilateral': resolved['isUnilateral'] == true,
        'field': resolved['field'],
        'primaryMuscleGroup': resolved['primaryMuscleGroup'],
        'prefixes': resolved['prefixes'],
        'suffixes': resolved['suffixes'],
        'bodyPositions': resolved['bodyPositions'],
        'implements': resolved['implements'],
        'sets': setRows
            .map((sRow) => {
                  'id': sRow.data['id'] as int,
                  'setNumber': _toInt(sRow.data['set_number']) ?? 1,
                  'minReps': _toDouble(sRow.data['reps_min']),
                  'maxReps': _toDouble(sRow.data['reps_max']),
                  'pload': _toDouble(sRow.data['pload']),
                  'rpe': _toDouble(sRow.data['rpe']),
                  'rir': _toDouble(sRow.data['rir']),
                  'intention': sRow.data['set_intention'] as String?,
                  'side': sRow.data['side'] as String?,
                })
            .toList(),
      });
    }

    return {
      'wb': {
        'id': wb['id'] ?? 'wb_$blockId',
        'name': wb['name'] ?? 'WB $blockId',
        'folder': wb['folder'],
        'intention': wb['intention'],
        'description': wb['description'],
        'createdAt': _toInt(wb['createdAt']) ?? 0,
      },
      'kns': knsList,
      'description': wb['description'],
    };
  }

  // workout_blocks (+ workout_block_kns/workout_block_sets) is the sole
  // source of truth for the WB list. The legacy wb_store/wb_kns_store JSON
  // blobs are gone — see database.dart's _backfillFolderFromLegacyWbStore,
  // which backfilled anything that only existed in them and dropped the
  // tables.
  static Future<List<Map<String, dynamic>>> loadWorkoutBlocksCombinedData(
      AppDatabase db) async {
    await _ensureWorkoutBlockTables(db);
    final combined = <Map<String, dynamic>>[];
    final realRows = await db
        .customSelect(
            'SELECT id, name, folder, intention, description, created_at FROM workout_blocks WHERE COALESCE(deleted_at, 0) = 0 ORDER BY id ASC')
        .get();

    for (final wbRow in realRows) {
      final blockId = wbRow.data['id'] as int;
      final wb = {
        'id': 'wb_$blockId',
        'name': wbRow.data['name'] as String,
        'folder': wbRow.data['folder'] as String?,
        'intention': wbRow.data['intention'] as String?,
        'description': wbRow.data['description'] as String?,
        'createdAt': _toInt(wbRow.data['created_at']) ?? 0,
      };

      final knsRows = await db
          .customSelect(
              'SELECT id, base_exercise_id, order_index, utilities, batch_name, metadata FROM workout_block_kns WHERE block_id = $blockId ORDER BY order_index ASC')
          .get();

      combined.add(await _buildWorkoutBlockCombined(
        db,
        blockId,
        wb,
        knsRows,
      ));
    }

    return combined;
  }

  static List<Map<String, dynamic>> _parseWorkoutBlockRows(
      List<List<String>> rows) {
    final cleanRows = rows
        .where((row) => row.any((cell) => cell.trim().isNotEmpty))
        .map((row) => row.map((cell) => cell.trim()).toList())
        .toList();
    if (cleanRows.isEmpty) return [];

    final header = <String, int>{};
    final first = cleanRows.first;
    final hasHeader = first.any((cell) => cell.toUpperCase() == 'WB_NAME');
    final dataRows = hasHeader ? cleanRows.skip(1).toList() : cleanRows;
    if (hasHeader) {
      for (var i = 0; i < first.length; i++) {
        header[first[i].toUpperCase()] = i;
      }
    }

    final groups = <String, List<List<String>>>{};
    for (final row in dataRows) {
      final wbName = _cell(row, header, 'WB_NAME', 0);
      if (wbName.isEmpty) continue;
      final wbFolder = _cell(row, header, 'WB_FOLDER', 1);
      final wbCreatedAt = _cell(row, header, 'WB_CREATED_AT', 2);
      final key = [wbName, wbFolder, wbCreatedAt].join('\u001F');
      groups.putIfAbsent(key, () => []).add(row);
    }

    final parsed = <Map<String, dynamic>>[];
    var setIdSeed = DateTime.now().microsecondsSinceEpoch + 1000000000;
    for (final groupRows in groups.values) {
      final firstRow = groupRows.first;
      final wbName = _cell(firstRow, header, 'WB_NAME', 0);
      final wbFolder = _cell(firstRow, header, 'WB_FOLDER', 1);
      final wbCreatedAtRaw = _cell(firstRow, header, 'WB_CREATED_AT', 2);
      final createdAtWasBlank = wbCreatedAtRaw.isEmpty;
      final createdAt =
          _toInt(wbCreatedAtRaw) ?? DateTime.now().millisecondsSinceEpoch;
      final blockId = createdAt;
      final wb = {
        'id': 'wb_$blockId',
        'name': wbName,
        'folder': wbFolder.isNotEmpty ? wbFolder : null,
        'createdAt': createdAt,
        'createdAtWasBlank': createdAtWasBlank,
      };

      final knsByKey = <String, Map<String, dynamic>>{};
      for (final row in groupRows) {
        final exName = _cell(row, header, 'EXERCISE_NAME', 3);
        if (exName.isEmpty) continue;

        final orderIdx = _toInt(_cell(row, header, 'ORDER_INDEX', 5)) ?? 0;
        final utilitiesStr = _cell(row, header, 'UTILITIES', 6);
        final utilities = utilitiesStr.isNotEmpty
            ? utilitiesStr
                .split(';')
                .where((u) => u.trim().isNotEmpty)
                .map((u) => u.trim())
                .toList()
            : <String>[];
        final batch = _cell(row, header, 'BATCH', 7);
        // Read for display only - _writeImportedWorkoutBlocks never persists
        // these (workout_block_kns has no columns for them), so they're
        // deliberately excluded from knsKey below: including free-text
        // fields in the dedup key used to split one exercise's sets into
        // multiple KNS entries whenever the text was inconsistent row to row.
        final prefixes = _cell(row, header, 'PREFIXES', 15);
        final suffixes = _cell(row, header, 'SUFFIXES', 16);
        final bodyPositions = _cell(row, header, 'BODY_POSITIONS', 17);
        final implements = _cell(row, header, 'IMPLEMENTS', 18);
        final knsKey = [
          orderIdx,
          exName.toUpperCase(),
          utilities.join('|'),
          batch,
        ].join('\u001F');

        var kns = knsByKey[knsKey];
        if (kns == null) {
          final exId = _toInt(_cell(row, header, 'EXERCISE_ID', 4)) ?? 0;
          kns = {
            'id': DateTime.now().microsecondsSinceEpoch +
                parsed.length * 1000000 +
                knsByKey.length * 1000,
            'baseExerciseId': exId,
            'exerciseName': exName,
            'orderIndex': orderIdx,
            'utilities': utilities,
            'batchName': batch.isNotEmpty ? batch : null,
            'intention': null,
            'isUnilateral': false,
            'field': null,
            'primaryMuscleGroup': null,
            'prefixes': prefixes.isNotEmpty ? prefixes : null,
            'suffixes': suffixes.isNotEmpty ? suffixes : null,
            'bodyPositions': bodyPositions.isNotEmpty ? bodyPositions : null,
            'implements': implements.isNotEmpty ? implements : null,
            'sets': <Map<String, dynamic>>[],
          };
          knsByKey[knsKey] = kns;
        }

        final setNum = _toInt(_cell(row, header, 'SET_NUMBER', 8)) ?? 1;
        final setEntry = <String, dynamic>{
          'id': setIdSeed++,
          'setNumber': setNum,
        };
        final minReps = _toDouble(_cell(row, header, 'SET_MIN_REPS', 9));
        final maxReps = _toDouble(_cell(row, header, 'SET_MAX_REPS', 10));
        final pload = _toDouble(_cell(row, header, 'SET_PLOAD', 11));
        final rpe = _toDouble(_cell(row, header, 'SET_RPE', 12));
        final rir = _toDouble(_cell(row, header, 'SET_RIR', 13));
        final setIntention = _cell(row, header, 'SET_INTENTION', 14);
        final side = _cell(row, header, 'SIDE', -1);
        if (minReps != null) setEntry['minReps'] = minReps;
        if (maxReps != null) setEntry['maxReps'] = maxReps;
        if (pload != null) setEntry['pload'] = pload;
        if (rpe != null) setEntry['rpe'] = rpe;
        if (rir != null) setEntry['rir'] = rir;
        if (setIntention.isNotEmpty) setEntry['intention'] = setIntention;
        if (side.isNotEmpty) setEntry['side'] = side;
        setEntry['tags'] = <String>[];
        (kns['sets'] as List<Map<String, dynamic>>).add(setEntry);
      }

      parsed.add(
          {'wb': wb, 'kns': knsByKey.values.toList(), 'description': null});
    }
    return parsed;
  }

  static Future<void> _ensureWorkoutBlockTables(AppDatabase db) async {
    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS workout_blocks (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        intention TEXT,
        description TEXT,
        created_at INTEGER NOT NULL DEFAULT 0,
        deleted_at INTEGER
      )
    ''');
    await db.customStatement('''
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
    await db.customStatement('''
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
    try {
      await db.customStatement(
          'ALTER TABLE workout_blocks ADD COLUMN intention TEXT');
    } catch (_) {}
    try {
      await db.customStatement(
          'ALTER TABLE workout_blocks ADD COLUMN description TEXT');
    } catch (_) {}
    try {
      await db.customStatement(
          'ALTER TABLE workout_blocks ADD COLUMN deleted_at INTEGER');
    } catch (_) {}
    try {
      await db.customStatement(
          'ALTER TABLE workout_block_kns ADD COLUMN utilities TEXT');
    } catch (_) {}
    try {
      await db.customStatement(
          'ALTER TABLE workout_block_kns ADD COLUMN batch_name TEXT');
    } catch (_) {}
    try {
      await db.customStatement(
          'ALTER TABLE workout_block_kns ADD COLUMN metadata TEXT');
    } catch (_) {}
    try {
      await db.customStatement(
          'ALTER TABLE workout_block_sets ADD COLUMN reps_min REAL');
    } catch (_) {}
    try {
      await db.customStatement(
          'ALTER TABLE workout_block_sets ADD COLUMN reps_max REAL');
    } catch (_) {}
    try {
      await db.customStatement(
          'ALTER TABLE workout_block_sets ADD COLUMN pload REAL');
    } catch (_) {}
    try {
      await db.customStatement(
          'ALTER TABLE workout_block_sets ADD COLUMN rpe REAL');
    } catch (_) {}
    try {
      await db.customStatement(
          'ALTER TABLE workout_block_sets ADD COLUMN rir REAL');
    } catch (_) {}
    try {
      await db.customStatement(
          'ALTER TABLE workout_block_sets ADD COLUMN set_intention TEXT');
    } catch (_) {}
    try {
      await db.customStatement(
          'ALTER TABLE workout_block_sets ADD COLUMN side TEXT');
    } catch (_) {}
    try {
      await db.customStatement(
          'ALTER TABLE workout_block_sets ADD COLUMN tags TEXT');
    } catch (_) {}
    try {
      await db.customStatement(
          'ALTER TABLE workout_block_sets ADD COLUMN metadata TEXT');
    } catch (_) {}
  }

  static Future<Map<String, int>> _writeImportedWorkoutBlocks(
      List<Map<String, dynamic>> parsedBlocks, AppDatabase db) async {
    await _ensureWorkoutBlockTables(db);
    int blocksCount = 0;
    int knsCount = 0;

    await db.transaction(() async {
      for (final item in parsedBlocks) {
        final wb = item['wb'] as Map<String, dynamic>;
        final wbName = wb['name']?.toString() ?? '';
        if (wbName.isEmpty) continue;
        var createdAt =
            _toInt(wb['createdAt']) ?? DateTime.now().millisecondsSinceEpoch;
        var blockId =
            _toInt(wb['id']?.toString().replaceAll('wb_', '')) ?? createdAt;
        final folder = wb['folder']?.toString();
        final resolvedFolder = folder?.isNotEmpty == true ? folder : null;

        // WB_CREATED_AT was blank in the source file (a from-scratch import,
        // or an edited export where the column got accidentally cleared).
        // Rather than always minting a fresh ID - which would fork a
        // duplicate block on a "re-import an edited export" workflow -
        // reuse an existing block with the same name+folder if one exists.
        if (wb['createdAtWasBlank'] == true) {
          final existing = await db.customSelect(
            'SELECT id, created_at FROM workout_blocks WHERE name = ? AND '
            '(folder = ? OR (folder IS NULL AND ? IS NULL)) AND deleted_at = 0 '
            'LIMIT 1',
            variables: [
              Variable.withString(wbName),
              resolvedFolder == null
                  ? const Variable(null)
                  : Variable.withString(resolvedFolder),
              resolvedFolder == null
                  ? const Variable(null)
                  : Variable.withString(resolvedFolder),
            ],
          ).getSingleOrNull();
          if (existing != null) {
            blockId = existing.data['id'] as int;
            createdAt = existing.data['created_at'] as int;
          }
        }
        final intention = wb['intention']?.toString();
        final description =
            item['description']?.toString() ?? wb['description']?.toString();

        blocksCount++;

        await db.customStatement(
          'INSERT OR IGNORE INTO workout_blocks (id, name, folder, intention, description, created_at, deleted_at) VALUES (?, ?, ?, ?, ?, ?, 0)',
          [blockId, wbName, resolvedFolder, intention, description, createdAt],
        );
        await db.customStatement(
            'UPDATE workout_blocks SET name = ?, folder = ?, intention = ?, description = ?, created_at = ?, deleted_at = 0 WHERE id = ?',
            [wbName, resolvedFolder, intention, description, createdAt, blockId]);
        await db.customStatement(
            'DELETE FROM workout_block_kns WHERE block_id = ?', [blockId]);

        final knsList =
            (item['kns'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        var localKnsIndex = 0;
        var fallbackSetIdSeed =
            DateTime.now().microsecondsSinceEpoch + 2000000000;
        for (final kns in knsList) {
          final exName = kns['exerciseName']?.toString() ?? '';
          if (exName.isEmpty) continue;
          var baseExerciseId = _toInt(kns['baseExerciseId']) ?? 0;
          if (baseExerciseId == 0) {
            final resolved = await _resolveExerciseFields(db, 0, exName);
            baseExerciseId = _toInt(resolved['baseExerciseId']) ?? 0;
          }
          final knsId = _toInt(kns['id']) ??
              (DateTime.now().microsecondsSinceEpoch +
                  blockId * 1000 +
                  localKnsIndex);
          final orderIndex = _toInt(kns['orderIndex']) ?? localKnsIndex;
          final utilities = (kns['utilities'] as List?)?.cast<String>() ?? [];
          final batchName = kns['batchName']?.toString();
          var sets = (kns['sets'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          var hasSideRows = sets.any((s) =>
              (s['side']?.toString() ?? '').toUpperCase() == 'RIGHT' ||
              (s['side']?.toString() ?? '').toUpperCase() == 'LEFT');
          final meta = <String, dynamic>{};
          if (kns['intention'] != null &&
              kns['intention'].toString().isNotEmpty)
            meta['intention'] = kns['intention'].toString();
          if ((kns['isUnilateral'] as bool?) == true || hasSideRows)
            meta['isUnilateral'] = true;

          await db.customStatement(
            'INSERT INTO workout_block_kns (id, block_id, base_exercise_id, order_index, utilities, batch_name, metadata) VALUES (?, ?, ?, ?, ?, ?, ?)',
            [
              knsId,
              blockId,
              baseExerciseId,
              orderIndex,
              utilities.isNotEmpty ? jsonEncode(utilities) : null,
              batchName?.isNotEmpty == true ? batchName : null,
              meta.isNotEmpty ? jsonEncode(meta) : null,
            ],
          );

          if (sets.length == 1 &&
              !hasSideRows &&
              baseExerciseId != 0 &&
              (sets.first['side']?.toString() ?? '').isEmpty) {
            final ex = await (db.select(db.baseExercises)
                  ..where((t) => t.id.equals(baseExerciseId)))
                .getSingleOrNull();
            if (ex?.isUnilateral == true) {
              final first = Map<String, dynamic>.from(sets.first);
              final rightId = _toInt(first['id']) ?? fallbackSetIdSeed++;
              final leftId = fallbackSetIdSeed++;
              sets = [
                {...first, 'id': rightId, 'side': 'RIGHT'},
                {
                  ...Map<String, dynamic>.from(first),
                  'id': leftId,
                  'side': 'LEFT'
                },
              ];
            }
          } else if (!hasSideRows &&
              sets.any((s) => (s['side']?.toString() ?? '').isEmpty)) {
            final sideSet = sets
                .where((s) => (s['side']?.toString() ?? '').isEmpty)
                .toList();
            if (sideSet.length >= 2) {
              sideSet.first['side'] = 'RIGHT';
              sideSet[1]['side'] = 'LEFT';
              hasSideRows = true;
            }
          }
          for (final set in sets) {
            final setNumber = _toInt(set['setNumber']) ?? 1;
            final setId = _toInt(set['id']) ?? fallbackSetIdSeed++;
            await db.customStatement(
              'INSERT INTO workout_block_sets (id, kns_id, set_number, reps_min, reps_max, pload, rpe, rir, set_intention, side, tags, metadata) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
              [
                setId,
                knsId,
                setNumber,
                _toDouble(set['minReps']),
                _toDouble(set['maxReps']),
                _toDouble(set['pload']),
                _toDouble(set['rpe']),
                _toDouble(set['rir']),
                set['intention']?.toString(),
                set['side']?.toString(),
                jsonEncode(
                    (set['tags'] as List?)?.cast<String>() ?? <String>[]),
                jsonEncode((set['metadata'] as Map<String, dynamic>?) ??
                    <String, dynamic>{}),
              ],
            );
          }

          localKnsIndex++;
          knsCount++;
        }
      }
    });

    return {'blocks': blocksCount, 'kns': knsCount};
  }

  static const _kWbHeader = [
    'WB_NAME',
    'WB_FOLDER',
    'WB_CREATED_AT',
    'EXERCISE_NAME',
    'EXERCISE_ID',
    'ORDER_INDEX',
    'UTILITIES',
    'BATCH',
    'SET_NUMBER',
    'SET_MIN_REPS',
    'SET_MAX_REPS',
    'SET_PLOAD',
    'SET_RPE',
    'SET_RIR',
    'SET_INTENTION',
    'PREFIXES',
    'SUFFIXES',
    'BODY_POSITIONS',
    'IMPLEMENTS',
    'SIDE',
  ];

  // Shared by exportWorkoutBlocksToXlsx/Csv: builds the flat row list (one
  // row per set, matching _kWbHeader's column order) so both file formats
  // stay in sync from a single place instead of duplicating this ~100-line
  // empty-row/unilateral-expansion/normal-set branching logic per format.
  static List<List<String>> _buildWorkoutBlockRows(
      List<Map<String, dynamic>> combinedData) {
    final rows = <List<String>>[];
    for (var item in combinedData) {
      final wb = item['wb'] as Map<String, dynamic>;
      final knsList = item['kns'] as List<Map<String, dynamic>>;
      final wbName = wb['name'] ?? '';
      final wbFolder = wb['folder'] ?? '';
      final wbCreated = wb['createdAt'] ?? '';

      if (knsList.isEmpty) {
        rows.add(
            [wbName.toString(), wbFolder.toString(), wbCreated.toString()]);
      }
      for (final kns in knsList) {
        final exName = kns['exerciseName'] ?? '';
        final exId = kns['baseExerciseId']?.toString() ?? '';
        final orderIdx = kns['orderIndex'] ?? 0;
        final utilities = (kns['utilities'] as List?)?.join(';') ?? '';
        final batch = kns['batchName'] ?? '';
        final intention = kns['intention'] ?? '';
        final prefixes = kns['prefixes'] ?? '';
        final suffixes = kns['suffixes'] ?? '';
        final bodyPositions = kns['bodyPositions'] ?? '';
        final implements = kns['implements'] ?? '';
        final sets = kns['sets'] as List? ?? [];
        final isUnilateral = kns['isUnilateral'] == true;
        if (sets.isEmpty) {
          rows.add([
            wbName.toString(),
            wbFolder.toString(),
            wbCreated.toString(),
            exName.toString(),
            exId,
            orderIdx.toString(),
            utilities,
            batch,
            '1',
            '',
            '',
            '',
            '',
            '',
            intention.toString(),
            prefixes.toString(),
            suffixes.toString(),
            bodyPositions.toString(),
            implements.toString(),
            '',
          ]);
        } else if (isUnilateral &&
            sets.length == 1 &&
            ((sets.first as Map<String, dynamic>)['side']?.toString() ?? '')
                .isEmpty) {
          final s = sets.first as Map<String, dynamic>;
          for (int sideIndex = 0; sideIndex < 2; sideIndex++) {
            rows.add([
              wbName.toString(),
              wbFolder.toString(),
              wbCreated.toString(),
              exName.toString(),
              exId,
              orderIdx.toString(),
              utilities,
              batch,
              (s['setNumber'] ?? 1).toString(),
              s['minReps']?.toString() ?? '',
              s['maxReps']?.toString() ?? '',
              s['pload']?.toString() ?? '',
              s['rpe']?.toString() ?? '',
              s['rir']?.toString() ?? '',
              s['intention']?.toString() ?? '',
              prefixes.toString(),
              suffixes.toString(),
              bodyPositions.toString(),
              implements.toString(),
              sideIndex == 0 ? 'RIGHT' : 'LEFT',
            ]);
          }
        } else {
          for (int i = 0; i < sets.length; i++) {
            final s = sets[i] as Map<String, dynamic>;
            rows.add([
              wbName.toString(),
              wbFolder.toString(),
              wbCreated.toString(),
              exName.toString(),
              exId,
              orderIdx.toString(),
              utilities,
              batch,
              (s['setNumber'] ?? (i + 1)).toString(),
              s['minReps']?.toString() ?? '',
              s['maxReps']?.toString() ?? '',
              s['pload']?.toString() ?? '',
              s['rpe']?.toString() ?? '',
              s['rir']?.toString() ?? '',
              s['intention']?.toString() ?? '',
              prefixes.toString(),
              suffixes.toString(),
              bodyPositions.toString(),
              implements.toString(),
              s['side']?.toString() ?? '',
            ]);
          }
        }
      }
    }
    return rows;
  }

  static Future<String> exportWorkoutBlocksToXlsx(
      List<Map<String, dynamic>> combinedData, AppDatabase db,
      {String lang = 'en'}) async {
    var excel = Excel.createExcel();
    // Rename the default sheet instead of creating a new one
    excel.rename('Sheet1', 'WO.BLOCKS');
    Sheet sheet = excel.sheets.entries.first.value;

    sheet.setColumnWidth(0, 15);
    sheet.setColumnWidth(1, 15);
    sheet.setColumnWidth(2, 12);
    sheet.setColumnWidth(3, 25);
    sheet.setColumnWidth(4, 12);
    sheet.setColumnWidth(5, 10);
    sheet.setColumnWidth(6, 20);
    sheet.setColumnWidth(7, 15);
    sheet.setColumnWidth(8, 10);
    sheet.setColumnWidth(9, 10);
    sheet.setColumnWidth(10, 10);
    sheet.setColumnWidth(11, 10);
    sheet.setColumnWidth(12, 10);
    sheet.setColumnWidth(13, 10);
    sheet.setColumnWidth(14, 15);
    sheet.setColumnWidth(15, 20);
    sheet.setColumnWidth(16, 20);
    sheet.setColumnWidth(17, 20);
    sheet.setColumnWidth(18, 20);
    sheet.setColumnWidth(19, 10);

    final headerStyle = CellStyle(
        bold: true, fontColorHex: ExcelColor.fromHexString('#00FFFF'));
    sheet.appendRow(_kWbHeader.map((h) => TextCellValue(h)).toList());
    // Style header cells by position
    for (int ci = 0; ci < _kWbHeader.length; ci++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: ci, rowIndex: 0))
          .cellStyle = headerStyle;
    }

    for (final row in _buildWorkoutBlockRows(combinedData)) {
      sheet.appendRow(row.map((v) => TextCellValue(v)).toList());
    }

    final output = await getTemporaryDirectory();
    final filePath =
        "${output.path}/gymr_wbs_${DateTime.now().millisecondsSinceEpoch}.xlsx";
    await File(filePath).writeAsBytes(excel.encode()!);
    return filePath;
  }

  static Future<String> exportWorkoutBlocksToCsv(
      List<Map<String, dynamic>> combinedData, AppDatabase db) async {
    final csvData = <List<dynamic>>[_kWbHeader];
    csvData.addAll(_buildWorkoutBlockRows(combinedData));

    final output = await getTemporaryDirectory();
    final file = File(
        "${output.path}/gymr_wbs_${DateTime.now().millisecondsSinceEpoch}.csv");
    await file.writeAsString(_encodeCsv(csvData));
    return file.path;
  }

  /// Generates an empty WB template .xlsx for NEXUS EXPECTED INPUTS.
  /// Matches the gymr_wbs.xlsx format — single flat sheet, one row per set.
  static Future<String> generateEmptyWbTemplate() async {
    var excel = Excel.createExcel();
    excel.rename('Sheet1', 'WO.BLOCKS');
    Sheet sheet = excel.sheets.entries.first.value;

    sheet.setColumnWidth(0, 18);
    sheet.setColumnWidth(1, 12);
    sheet.setColumnWidth(2, 14);
    sheet.setColumnWidth(3, 22);
    sheet.setColumnWidth(4, 10);
    sheet.setColumnWidth(5, 10);
    sheet.setColumnWidth(6, 12);
    sheet.setColumnWidth(7, 12);
    sheet.setColumnWidth(8, 10);
    sheet.setColumnWidth(9, 12);
    sheet.setColumnWidth(10, 12);
    sheet.setColumnWidth(11, 10);
    sheet.setColumnWidth(12, 8);
    sheet.setColumnWidth(13, 8);
    sheet.setColumnWidth(14, 18);
    sheet.setColumnWidth(15, 12);
    sheet.setColumnWidth(16, 12);
    sheet.setColumnWidth(17, 14);
    sheet.setColumnWidth(18, 14);
    sheet.setColumnWidth(19, 10);

    final headerStyle = CellStyle(
        bold: true, fontColorHex: ExcelColor.fromHexString('#00FFFF'));
    sheet.appendRow([
      TextCellValue('WB_NAME'),
      TextCellValue('WB_FOLDER'),
      TextCellValue('WB_CREATED_AT'),
      TextCellValue('EXERCISE_NAME'),
      TextCellValue('EXERCISE_ID'),
      TextCellValue('ORDER_INDEX'),
      TextCellValue('UTILITIES'),
      TextCellValue('BATCH'),
      TextCellValue('SET_NUMBER'),
      TextCellValue('SET_MIN_REPS'),
      TextCellValue('SET_MAX_REPS'),
      TextCellValue('SET_PLOAD'),
      TextCellValue('SET_RPE'),
      TextCellValue('SET_RIR'),
      TextCellValue('SET_INTENTION'),
      TextCellValue('PREFIXES'),
      TextCellValue('SUFFIXES'),
      TextCellValue('BODY_POSITIONS'),
      TextCellValue('IMPLEMENTS'),
      TextCellValue('SIDE'),
    ]);
    for (int ci = 0; ci < 20; ci++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: ci, rowIndex: 0))
          .cellStyle = headerStyle;
    }

    // ── PULL DAY TEMPLATE rows (one per set) ──
    // Weighted Pull Up — 3 sets
    sheet.appendRow([
      TextCellValue('PULL DAY TEMPLATE'),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue('WEIGHTED PULL UP'),
      TextCellValue(''),
      TextCellValue('0'),
      TextCellValue('PULL'),
      TextCellValue('PULLING'),
      TextCellValue('1'),
      TextCellValue(''),
      TextCellValue('8'),
      TextCellValue('10'),
      TextCellValue('6'),
      TextCellValue('2'),
      TextCellValue('WARMUP'),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue('DEAD_HANG'),
      TextCellValue('WEIGHT VEST'),
      TextCellValue(''),
    ]);
    sheet.appendRow([
      TextCellValue('PULL DAY TEMPLATE'),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue('WEIGHTED PULL UP'),
      TextCellValue(''),
      TextCellValue('0'),
      TextCellValue('PULL'),
      TextCellValue('PULLING'),
      TextCellValue('2'),
      TextCellValue('6'),
      TextCellValue('8'),
      TextCellValue('20'),
      TextCellValue('8'),
      TextCellValue('1'),
      TextCellValue('WORKING'),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue('DEAD_HANG'),
      TextCellValue('WEIGHT VEST'),
      TextCellValue(''),
    ]);
    sheet.appendRow([
      TextCellValue('PULL DAY TEMPLATE'),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue('WEIGHTED PULL UP'),
      TextCellValue(''),
      TextCellValue('0'),
      TextCellValue('PULL'),
      TextCellValue('PULLING'),
      TextCellValue('3'),
      TextCellValue('5'),
      TextCellValue('6'),
      TextCellValue('25'),
      TextCellValue('9'),
      TextCellValue('1'),
      TextCellValue('HEAVY'),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue('DEAD_HANG'),
      TextCellValue('WEIGHT VEST'),
      TextCellValue(''),
    ]);
    // Devon Lift ISO — 2 sets
    sheet.appendRow([
      TextCellValue('PULL DAY TEMPLATE'),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue('DEVON LIFT ISO'),
      TextCellValue(''),
      TextCellValue('1'),
      TextCellValue('ISO'),
      TextCellValue('ISO_HOLD'),
      TextCellValue('1'),
      TextCellValue('15'),
      TextCellValue('20'),
      TextCellValue('5'),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue('ISO HOLD'),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
    ]);
    sheet.appendRow([
      TextCellValue('PULL DAY TEMPLATE'),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue('DEVON LIFT ISO'),
      TextCellValue(''),
      TextCellValue('1'),
      TextCellValue('ISO'),
      TextCellValue('ISO_HOLD'),
      TextCellValue('2'),
      TextCellValue('20'),
      TextCellValue('30'),
      TextCellValue('10'),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue('MAX HOLD'),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue('RIGHT'),
    ]);
    // Murcielagos — 3 sets
    sheet.appendRow([
      TextCellValue('PULL DAY TEMPLATE'),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue('MURCIELAGOS'),
      TextCellValue(''),
      TextCellValue('2'),
      TextCellValue('PULL,CORE'),
      TextCellValue('CORE'),
      TextCellValue('1'),
      TextCellValue(''),
      TextCellValue('12'),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
    ]);
    sheet.appendRow([
      TextCellValue('PULL DAY TEMPLATE'),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue('MURCIELAGOS'),
      TextCellValue(''),
      TextCellValue('2'),
      TextCellValue('PULL,CORE'),
      TextCellValue('CORE'),
      TextCellValue('2'),
      TextCellValue('8'),
      TextCellValue('12'),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
    ]);
    sheet.appendRow([
      TextCellValue('PULL DAY TEMPLATE'),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue('MURCIELAGOS'),
      TextCellValue(''),
      TextCellValue('2'),
      TextCellValue('PULL,CORE'),
      TextCellValue('CORE'),
      TextCellValue('3'),
      TextCellValue('6'),
      TextCellValue('10'),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue('UNILATERAL FOCUS'),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue('RIGHT'),
    ]);

    final output = await getTemporaryDirectory();
    final filePath = "${output.path}/gymr_wb_empty_template.xlsx";
    await File(filePath).writeAsBytes(excel.encode()!);
    return filePath;
  }

  static Future<Map<String, int>> importWorkoutBlocksFromCsv(
      String csvContent, AppDatabase db) async {
    final rows = _decodeCsv(csvContent);
    final parsedBlocks = _parseWorkoutBlockRows(rows);
    if (parsedBlocks.isEmpty) return {"blocks": 0, "kns": 0};
    return _writeImportedWorkoutBlocks(parsedBlocks, db);
  }

  static Future<Map<String, int>> importWorkoutBlocksFromExcel(
      List<int> bytes, AppDatabase db) async {
    var excel = Excel.decodeBytes(bytes);
    if (excel.sheets.isEmpty) return {"blocks": 0, "kns": 0};
    final sheet = excel.sheets.values.first;
    final allRows = <List<String>>[];
    for (int ri = 0; ri < sheet.rows.length; ri++) {
      final row = sheet.rows[ri];
      final strRow = row.map((c) {
        if (c == null) return '';
        return c.value.toString().trim();
      }).toList();
      if (strRow.isNotEmpty) {
        allRows.add(strRow);
      }
    }

    final parsedBlocks = _parseWorkoutBlockRows(allRows);
    if (parsedBlocks.isEmpty) return {"blocks": 0, "kns": 0};
    return _writeImportedWorkoutBlocks(parsedBlocks, db);
  }
}
