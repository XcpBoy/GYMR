import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/database_provider.dart';
import '../services/export_service.dart';
import '../providers/theme_provider.dart';
import 'WO.Blocks.manager.dart';
import 'styles.dart';
import 'lab_widgets.dart';
import 'main_scaffold.dart';

class NexusScreen extends ConsumerStatefulWidget {
  const NexusScreen({super.key});

  @override
  ConsumerState<NexusScreen> createState() => _NexusScreenState();
}

class _NexusScreenState extends ConsumerState<NexusScreen> {
  bool _isProcessing = false;
  List<String> _dbTables = [];
  String? _exportingTable;
  String? _backupFolder;

  // Collapsible states
  bool _isExchangesExpanded = false;
  bool _isSynthesisExpanded = true;
  bool _isRawDataExpanded = false;
  bool _isExpectedInputsExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadBackupFolder();
  }

  Future<void> _loadBackupFolder() async {
    final dir = await ExportService.loadBackupDirectory();
    if (mounted) setState(() => _backupFolder = dir);
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'NEXUS_DATA_EXCHANGE',
      screenKey: 'NEXUS',
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildMainGridLayout(context),
                const SizedBox(height: 100),
              ],
            ),
          ),
          if (_isProcessing)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.8),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: LabColors.primary),
                      SizedBox(height: 16),
                      Text("PROCESSING_DATA...",
                          style: TextStyle(
                              color: LabColors.primary,
                              fontSize: 10,
                              fontFamily: 'JetBrains Mono')),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: const LabFooter(),
    );
  }

  Widget _buildMainGridLayout(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: LabColors.primary.withValues(alpha: 0.05),
        border: Border.all(
            color: LabColors.cyanBorder.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Column(
        children: [
          _buildSynthesisSection(context),
          const Divider(height: 1, color: LabColors.cyanBorder, thickness: 0.2),
          _buildExchangeSection(context),
          const Divider(height: 1, color: LabColors.cyanBorder, thickness: 0.2),
          _buildRawDataSection(context),
          const Divider(height: 1, color: LabColors.cyanBorder, thickness: 0.2),
          _buildExpectedInputsSection(context),
        ],
      ),
    );
  }

  Widget _buildExpectedInputsSection(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            "EXPECTED_INPUTS",
            "Template_Reference",
            LabColors.primary,
            isExpanded: _isExpectedInputsExpanded,
            onToggle: () => setState(
                () => _isExpectedInputsExpanded = !_isExpectedInputsExpanded),
          ),
          if (_isExpectedInputsExpanded) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: LabColors.surfaceContainerLow,
                border: Border.all(
                    color: LabColors.primary.withValues(alpha: 0.2),
                    width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("KINISI_LIBRARY_CSV_STRUCTURE:",
                      style: LabStyles.mono(context,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: LabColors.primary)),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.black,
                      child: Text(
                        "NAME,PREFIXES,IMPLEMENTS,BODY_POSITIONS,SUFFIXES,PRIMARY_MUSCLE,SECONDARY_MUSCLE,FIELD,TISSUE_TYPE,TISSUE_NAME,NUM_PHASES,PHASE_DESCRIPTIONS,INTENTION,PATTERN_TYPE,COMPLEX_METADATA,IS_UNILATERAL,DESCRIPTION",
                        style: LabStyles.mono(context,
                            fontSize: 8, color: Colors.grey[400]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text("SAMPLE_ROW:",
                      style: LabStyles.mono(context,
                          fontSize: 8, color: Colors.grey)),
                  const SizedBox(height: 4),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.black,
                      child: Text(
                        "PULL UP,,WEIGHT VEST,DEAD_HANG,,BACK,BICEPS,STRENGTH,MUSCLE,LATS,1,,[NT:LASTRE|ISO:false],VERTICAL_PULL,,0,Weighted pull up focused on latissimus dorsi development.",
                        style: LabStyles.mono(context,
                            fontSize: 8, color: Colors.grey[600]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  LabButton(
                    label: "GENERATE_EMPTY_TEMPLATE",
                    onPressed: _generateTemplateCsv,
                    color: LabColors.primary,
                    isOutlined: true,
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // ── WB EMPTY TEMPLATE ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: LabColors.surfaceContainerLow,
                border: Border.all(
                    color: LabColors.accent.withValues(alpha: 0.2),
                    width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("WB_EMPTY_TEMPLATE:",
                      style: LabStyles.mono(context,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: LabColors.accent)),
                  const SizedBox(height: 12),
                  Text("WORKOUT_BLOCK:",
                      style: LabStyles.mono(context,
                          fontSize: 8, color: Colors.grey)),
                  const SizedBox(height: 4),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.black,
                      child: Text(
                        "NAME,DESCRIPTION\n\"PULL DAY TEMPLATE\",\"Pull strength + iso core + BW metcon\"",
                        style: LabStyles.mono(context,
                            fontSize: 8, color: Colors.grey[400]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text("WORKOUT_BLOCK_KNS:",
                      style: LabStyles.mono(context,
                          fontSize: 8, color: Colors.grey)),
                  const SizedBox(height: 4),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.black,
                      child: Text(
                        "ORDER,BASE_EXERCISE_ID,UTILITIES,BATCH_NAME,INTENTION\n"
                        "0,\"WEIGHTED PULL UP\",\"PULL\",\"PULLING\",\"[NT:LASTRE|ISO:false] Main lat work\"\n"
                        "1,\"DEVON LIFT ISO\",\"ISO\",\"ISO_HOLD\",\"[NT:EXT.LOAD|ISO:true] Isometric side hold\"\n"
                        "2,\"MURCIELAGOS\",\"PULL,CORE\",\"CORE\",\"[NT:JST.BW|ISO:false] BW knee raise\"",
                        style: LabStyles.mono(context,
                            fontSize: 8, color: Colors.grey[400]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text("WORKOUT_BLOCK_SETS:",
                      style: LabStyles.mono(context,
                          fontSize: 8, color: Colors.grey)),
                  const SizedBox(height: 4),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.black,
                      child: Text(
                        "KNS,SET,MIN_REPS/SEC,P.LOAD,MAX_REPS/SEC,RPE,RIR,SIDE,INTENTION\n"
                        "\"WEIGHTED PULL UP\",1,,10,8,6,2,,WARMUP\n"
                        "\"WEIGHTED PULL UP\",2,6,20,8,8,1,,WORKING\n"
                        "\"WEIGHTED PULL UP\",3,5,25,6,9,1,,HEAVY\n"
                        "\"DEVON LIFT ISO\",1,15,5,20,,,,ISO HOLD\n"
                        "\"DEVON LIFT ISO\",2,20,10,30,,,RIGHT,MAX HOLD\n"
                        "\"MURCIELAGOS\",1,,,12,,,,\n"
                        "\"MURCIELAGOS\",2,8,,12,,,,\n"
                        "\"MURCIELAGOS\",3,6,,10,,,RIGHT,UNILATERAL FOCUS",
                        style: LabStyles.mono(context,
                            fontSize: 8, color: Colors.grey[400]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text("BATCH_REFERENCES:",
                      style: LabStyles.mono(context,
                          fontSize: 8,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.black,
                      child: Text(
                        "BATCH_NAME,EXERCISES\n"
                        "\"PULLING\",\"WEIGHTED PULL UP\"\n"
                        "\"ISO_HOLD\",\"DEVON LIFT ISO\"\n"
                        "\"CORE\",\"MURCIELAGOS\"",
                        style: LabStyles.mono(context,
                            fontSize: 8, color: Colors.grey[400]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  LabButton(
                    label: "DOWNLOAD_WB_TEMPLATE_XLSX",
                    onPressed: _generateEmptyWbXlsx,
                    color: LabColors.accent,
                    isOutlined: true,
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _generateTemplateCsv() async {
    setState(() => _isProcessing = true);
    try {
      await ExportService.generateEmptyExerciseTemplate();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("TEMPLATE_GENERATED_AND_SHARED")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("GENERATION_FAILED: $e"),
            backgroundColor: Colors.redAccent));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _generateEmptyWbXlsx() async {
    setState(() => _isProcessing = true);
    try {
      final filePath = await ExportService.generateEmptyWbTemplate();
      if (mounted) {
        await SharePlus.instance.share(
            ShareParams(files: [XFile(filePath)],
                text: 'GYMR WB Empty Template'));
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("WB_TEMPLATE_GENERATED")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("GENERATION_FAILED: $e"),
            backgroundColor: Colors.redAccent));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _loadTables() async {
    try {
      final db = ref.read(databaseProvider);
      final tables = await ExportService.listAllTables(db);
      if (mounted) setState(() => _dbTables = tables);
    } catch (_) {}
  }

  Future<void> _exportTable(String tableName) async {
    setState(() => _exportingTable = tableName);
    try {
      final db = ref.read(databaseProvider);
      await ExportService.exportTableToCsv(db, tableName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("EXPORTED: $tableName.csv",
                  style: LabStyles.mono(context))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text("EXPORT_FAILED: $e", style: LabStyles.mono(context)),
              backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _exportingTable = null);
    }
  }

  Widget _buildRawDataSection(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            "RAW_DATA\nMANAGEMENT",
            "Type: SQLite_Core",
            LabColors.tertiary,
            titleFontSize: 13,
            isExpanded: _isRawDataExpanded,
            onToggle: () => setState(() {
              _isRawDataExpanded = !_isRawDataExpanded;
              if (_isRawDataExpanded && _dbTables.isEmpty) _loadTables();
            }),
          ),
          if (_isRawDataExpanded) ...[
            const SizedBox(height: 24),
            _buildActionButton(
              icon: Icons.archive,
              label: "BACKUP_ALL_DATABASES",
              subLabel: "EXPORT_SINGLE_DB",
              color: LabColors.tertiary,
              onTap: _backupAllDatabases,
              fontSize: 10.8,
            ),
            const SizedBox(height: 12),
            // ── Backup Folder ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: LabColors.surfaceContainerLow,
                  border: Border.all(
                      color: LabColors.tertiary.withValues(alpha: 0.2),
                      width: 0.5)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("BACKUP_LOCATION:",
                      style: LabStyles.mono(context,
                          fontSize: 8,
                          color: LabColors.tertiary,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    _backupFolder ?? "LOADING...",
                    style: LabStyles.mono(context,
                        fontSize: 7, color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: LabButton(
                          label: "BACKUP_NOW",
                          onPressed: _backupToFolder,
                          color: LabColors.tertiary,
                          isOutlined: false,
                          padding: const EdgeInsets.symmetric(
                              vertical: 6, horizontal: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // ── Per-table export ──
            Text("EXPORT_INDIVIDUAL_TABLES:",
                style: LabStyles.mono(context,
                    fontSize: 8,
                    color: LabColors.tertiary,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildTableList(context),
            const SizedBox(height: 24),
            const Divider(color: LabColors.cyanBorder, thickness: 0.3),
            const SizedBox(height: 24),
            Text("DETECTED_DATABASE_FILES:",
                style:
                    LabStyles.mono(context, fontSize: 8, color: Colors.grey)),
            const SizedBox(height: 12),
            FutureBuilder<List<File>>(
              future: ExportService.listDatabases(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: LabColors.tertiary),
                  ));
                }
                final files = snapshot.data ?? [];
                if (files.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        border:
                            Border.all(color: Colors.grey[900]!, width: 0.5)),
                    child: Text("NO_SQLITE_FILES_DETECTED_IN_APP_DIR",
                        style: LabStyles.mono(context,
                            fontSize: 8, color: Colors.grey[600])),
                  );
                }
                return Column(
                  children: files.map((f) => _buildDbFileRow(f)).toList(),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDbFileRow(File file) {
    final fileName = p.basename(file.path);
    int size = 0;
    try {
      // Refresh file stats to get actual size
      size = file.lengthSync();
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: LabColors.surfaceContainerLow,
        border: Border.all(
            color: LabColors.tertiary.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fileName.toUpperCase(),
                    style: LabStyles.mono(context,
                        fontSize: 10, color: Colors.white)),
                Text("${(size / 1024).toStringAsFixed(1)} KB",
                    style: LabStyles.mono(context,
                        fontSize: 7, color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: LabButton(
              label: "OVERRIDE",
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              onPressed: () => _importDatabaseOverride(fileName),
              color: LabColors.tertiary,
              isOutlined: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableExportRow(String tableName) {
    final isExporting = _exportingTable == tableName;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: LabColors.surfaceContainerLow,
        border: Border.all(
            color: LabColors.tertiary.withValues(alpha: 0.15), width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(tableName.toUpperCase(),
                style:
                    LabStyles.mono(context, fontSize: 9, color: Colors.white)),
          ),
          isExporting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 1.5, color: LabColors.tertiary))
              : SizedBox(
                  width: 80,
                  child: LabButton(
                    label: "EXPORT_CSV",
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    onPressed: () => _exportTable(tableName),
                    color: LabColors.tertiary,
                    isOutlined: true,
                    fontSize: 8,
                  ),
                ),
        ],
      ),
    );
  }

  Future<void> _backupAllDatabases() async {
    setState(() => _isProcessing = true);
    try {
      final success = await ExportService.backupAllDatabases();
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("BACKUP_FAILED: NO_FILES_FOUND"),
            backgroundColor: Colors.orangeAccent));
      } 
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("BACKUP_FAILED: $e"),
            backgroundColor: Colors.redAccent));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _backupToFolder() async {
    setState(() => _isProcessing = true);
    try {
      final path = await ExportService.backupDatabaseToDirectory();
      _backupFolder = await ExportService.loadBackupDirectory();
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("BACKUP_SAVED: ${p.basename(path)}"),
            backgroundColor: LabColors.tertiary));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("BACKUP_FAILED: $e"),
            backgroundColor: Colors.redAccent));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Widget _buildTableList(BuildContext context) {
    if (_dbTables.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[900]!, width: 0.5)),
        child: Text("NO_TABLES_DETECTED",
            style:
                LabStyles.mono(context, fontSize: 8, color: Colors.grey[600])),
      );
    }

    return Column(
      children: _dbTables.map((tbl) => _buildTableExportRow(tbl)).toList(),
    );
  }

  Future<void> _importDatabaseOverride(String targetFileName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: LabColors.background,
        title: Text("CRITICAL_OVERWRITE",
            style: LabStyles.mono(context, color: Colors.redAccent)),
        content: Text(
            "THIS WILL OVERWRITE '$targetFileName' AND REQUIRE AN IMMEDIATE APP RESTART. PROCEED?",
            style: LabStyles.mono(context, fontSize: 10)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text("ABORT", style: LabStyles.mono(context))),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text("PROCEED",
                  style: LabStyles.mono(context, color: Colors.redAccent))),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await FilePicker.platform.pickFiles(type: FileType.any);

    if (result != null && result.files.single.path != null) {
      setState(() => _isProcessing = true);
      try {
        await ExportService.importDatabase(
            File(result.files.single.path!), targetFileName);
        if (mounted) {
          setState(() {}); // Refresh list
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (c) => AlertDialog(
              backgroundColor: LabColors.background,
              title: Text("IMPORT_COMPLETE",
                  style: LabStyles.mono(context, color: LabColors.primary)),
              content: Text(
                  "DATABASE '$targetFileName' HAS BEEN REPLACED SUCCESSFULLY. PLEASE RESTART THE APP MANUALLY NOW TO LOAD NEW DATA.",
                  style: LabStyles.mono(context, fontSize: 10)),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(c),
                    child: Text("UNDERSTOOD", style: LabStyles.mono(context))),
              ],
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          String errorMsg = e.toString().replaceFirst("Exception: ", "");
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("IMPORT_FAILED: $errorMsg"),
              backgroundColor: Colors.redAccent));
        }
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  Widget _buildExchangeSection(BuildContext context) {
    final nexusExchangeDefaults = <String, Color>{
      'WO_BLOCKS': LabColors.biometricYellow,
      'KNS_LIBRARY': LabColors.inventoryOrange,
      'ROUTINE': LabColors.visualsNeon,
    };
    final woBlocksColor =
        _nexusExchangeColor('WO_BLOCKS', nexusExchangeDefaults);
    final knsLibraryColor =
        _nexusExchangeColor('KNS_LIBRARY', nexusExchangeDefaults);
    final routineColor = _nexusExchangeColor('ROUTINE', nexusExchangeDefaults);

    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            "EXCHANGES",
            "Type: Bidirectional",
            LabColors.primary,
            isExpanded: _isExchangesExpanded,
            onToggle: () =>
                setState(() => _isExchangesExpanded = !_isExchangesExpanded),
          ),
          if (_isExchangesExpanded) ...[
            const SizedBox(height: 24),
            _buildExportCard(
              title: "EXPORT KINISI LIBRARY",
              icon: Icons.auto_awesome_motion,
              color: knsLibraryColor,
              format: "CSV",
              onShare: () async {
                await _exportExercisesPath(share: true);
              },
              onDownload: () async {
                final filePath = await _exportExercisesPath(share: false);
                if (filePath != null) {
                  await _downloadExportedFile(filePath, 'gymr_exercises.csv');
                }
              },
            ),
            _buildImportCard(
              title: "IMPORT KINISI LIBRARY",
              icon: Icons.input,
              color: knsLibraryColor,
              format: "CSV/XLSX",
              onTap: _importExercises,
            ),
            const SizedBox(height: 12),
            _buildExportCard(
              title: "EXPORT WO.BLOCKS",
              icon: Icons.file_download,
              color: woBlocksColor,
              format: "XLSX",
              onShare: () async {
                final filePath = await _exportWorkoutBlocksPath();
                if (filePath != null) {
                  await SharePlus.instance.share(
                      ShareParams(files: [XFile(filePath)],
                          text: 'GYMR Workout Blocks XLSX'));
                }
              },
              onDownload: () async {
                final filePath = await _exportWorkoutBlocksPath();
                if (filePath != null) {
                  await _downloadExportedFile(filePath, 'gymr_wbs.xlsx');
                }
              },
            ),
            _buildImportCard(
              title: "IMPORT WO.BLOCKS",
              icon: Icons.file_upload,
              color: woBlocksColor,
              format: "XLSX",
              onTap: _importWorkoutBlocks,
            ),
            const SizedBox(height: 12),
            _buildExportCard(
              title: "EXPORT ROUTINE",
              icon: Icons.description,
              color: routineColor,
              format: "XLSX",
              onShare: () => _exportWorkouts('xlsx'),
              onDownload: () => _downloadWorkoutFile('xlsx'),
            ),
            _buildImportCard(
              title: "IMPORT ROUTINE",
              icon: Icons.upload_file,
              color: routineColor,
              format: "CSV",
              onTap: () => _importData('workouts'),
            ),
            // _buildActionButton(icon: Icons.history, label: "FITNOTES.IMPORT", subLabel: "LEGACY_DATA_RECOVERY", color: Colors.blueAccent, onTap: _importFitNotes, format: "CSV"),
          ],
        ],
      ),
    );
  }

  Widget _buildSynthesisSection(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            "SYNTHESIS",
            "Static Output",
            LabColors.accent,
            isExpanded: _isSynthesisExpanded,
            onToggle: () =>
                setState(() => _isSynthesisExpanded = !_isSynthesisExpanded),
          ),
          if (_isSynthesisExpanded) ...[
            const SizedBox(height: 24),
            _buildSynthesisCard(
                title: "RENDER_WORKOUT_PDF",
                description:
                    "Compiles training blocks into a technical diagnostic document.",
                icon: Icons.picture_as_pdf,
                color: LabColors.accent,
                onShare: () => _exportWorkouts('pdf'),
                onDownload: () => _downloadWorkoutFile('pdf'),
                format: "PDF"),
            const SizedBox(height: 16),
            _buildSynthesisCard(
                title: "EXPORT_MARKDOWN_REPORT",
                description:
                    "Generates a structured .md file replicating the PDF table architecture.",
                icon: Icons.description,
                color: Colors.orangeAccent,
                onShare: () => _exportWorkouts('md'),
                onDownload: () => _downloadWorkoutFile('md'),
                format: "MD"),
            const SizedBox(height: 16),
            _buildSynthesisCard(
                title: "EXPORT_EXCEL_WORKBOOK",
                description:
                    "Generates a complete spreadsheet for deep data analysis.",
                icon: Icons.table_chart,
                color: Colors.greenAccent,
                onShare: () => _exportWorkouts('xlsx'),
                onDownload: () => _downloadWorkoutFile('xlsx'),
                format: "XLSX"),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String type, Color color,
      {required bool isExpanded,
      required VoidCallback onToggle,
      double titleFontSize = 18}) {
    return InkWell(
      onTap: onToggle,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
              child: Row(children: [
            Container(width: 4, height: 24, color: color),
            const SizedBox(width: 12),
            Flexible(
                child: Text(title,
                    style: LabStyles.headline(context).copyWith(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1),
                    overflow: TextOverflow.visible))
          ])),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(type.toUpperCase(),
                  style:
                      LabStyles.mono(context, fontSize: 8, color: Colors.grey)),
              Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: color,
                  size: 16),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      {required IconData icon,
      required String label,
      required String subLabel,
      required Color color,
      required VoidCallback onTap,
      double fontSize = 12,
      String? format}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 1),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(
                    color: LabColors.cyanBorder.withValues(alpha: 0.1),
                    width: 0.5))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (format != null)
              Container(
                margin: const EdgeInsets.only(bottom: 4, left: 36),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  border: Border.all(
                      color: color.withValues(alpha: 0.5), width: 0.5),
                ),
                child: Text(format,
                    style: LabStyles.mono(context,
                        fontSize: 6,
                        fontWeight: FontWeight.bold,
                        color: color)),
              ),
            Row(children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 16),
              Expanded(
                  child: Text(label,
                      style: LabStyles.mono(context,
                          fontSize: fontSize, fontWeight: FontWeight.bold))),
              Text(subLabel,
                  style: LabStyles.mono(context, fontSize: 8, color: color))
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSynthesisCard(
      {required String title,
      required String description,
      required IconData icon,
      required Color color,
      required VoidCallback onShare,
      VoidCallback? onDownload,
      String? format}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: LabColors.surfaceContainerLow,
          border: Border(left: BorderSide(color: color, width: 2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (format != null)
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              border:
                  Border.all(color: color.withValues(alpha: 0.5), width: 0.5),
            ),
            child: Text(format,
                style: LabStyles.mono(context,
                    fontSize: 6, fontWeight: FontWeight.bold, color: color)),
          ),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(title,
              style: LabStyles.mono(context,
                  fontSize: 10, fontWeight: FontWeight.bold, color: color)),
          Icon(icon, color: color, size: 18)
        ]),
        const SizedBox(height: 8),
        Text(description,
            style: LabStyles.mono(context, fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: InkWell(
                onTap: onShare,
                child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        border: Border.all(color: color, width: 0.5)),
                    alignment: Alignment.center,
                    child: Text('SHARE',
                        style: LabStyles.mono(context,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: color)))),
          ),
          if (onDownload != null) ...[
            const SizedBox(width: 8),
            Expanded(
              child: InkWell(
                  onTap: onDownload,
                  child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                          color: Colors.black,
                          border: Border.all(
                              color: color.withValues(alpha: 0.5), width: 0.5)),
                      alignment: Alignment.center,
                      child: Text('DOWNLOAD',
                          style: LabStyles.mono(context,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: color)))),
            ),
          ],
        ]),
      ]),
    );
  }

  // ─── SMALLER EXPORT CARD (for EXCHANGES) ─────────────────────
  Widget _buildExportCard(
      {required String title,
      required IconData icon,
      required Color color,
      required VoidCallback onShare,
      VoidCallback? onDownload,
      String? format}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: LabColors.surfaceContainerLow,
          border: Border(left: BorderSide(color: color, width: 2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (format != null)
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              border:
                  Border.all(color: color.withValues(alpha: 0.5), width: 0.5),
            ),
            child: Text(format,
                style: LabStyles.mono(context,
                    fontSize: 6, fontWeight: FontWeight.bold, color: color)),
          ),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(title,
              style: LabStyles.mono(context,
                  fontSize: 9, fontWeight: FontWeight.bold, color: color)),
          Icon(icon, color: color, size: 16),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: InkWell(
                onTap: onShare,
                child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        border: Border.all(color: color, width: 0.5)),
                    alignment: Alignment.center,
                    child: Text('SHARE',
                        style: LabStyles.mono(context,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: color)))),
          ),
          if (onDownload != null) ...[
            const SizedBox(width: 6),
            Expanded(
              child: InkWell(
                  onTap: onDownload,
                  child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                          color: Colors.black,
                          border: Border.all(
                              color: color.withValues(alpha: 0.5), width: 0.5)),
                      alignment: Alignment.center,
                      child: Text('DOWNLOAD',
                          style: LabStyles.mono(context,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: color)))),
            ),
          ],
        ]),
      ]),
    );
  }

  // ─── IMPORT CARD (standardized, single action) ──────────────
  Widget _buildImportCard(
      {required String title,
      required IconData icon,
      required Color color,
      required VoidCallback onTap,
      String? format}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: LabColors.surfaceContainerLow,
          border: Border(left: BorderSide(color: color, width: 2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (format != null)
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              border:
                  Border.all(color: color.withValues(alpha: 0.5), width: 0.5),
            ),
            child: Text(format,
                style: LabStyles.mono(context,
                    fontSize: 6, fontWeight: FontWeight.bold, color: color)),
          ),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(title,
              style: LabStyles.mono(context,
                  fontSize: 9, fontWeight: FontWeight.bold, color: color)),
          Icon(icon, color: color, size: 16),
        ]),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: InkWell(
              onTap: onTap,
              child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      border: Border.all(color: color, width: 0.5)),
                  alignment: Alignment.center,
                  child: Text('IMPORT',
                      style: LabStyles.mono(context,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: color)))),
        ),
      ]),
    );
  }

  Future<void> _downloadExportedFile(String filePath, String fileName) async {
    final bytes = await File(filePath).readAsBytes();
    await FilePicker.platform.saveFile(fileName: fileName, bytes: bytes);
  }

  Color _nexusExchangeColor(String item, Map<String, Color> defaultColors) {
    final settings = ref.watch(themeSettingsProvider).value ?? {};
    return ref.read(themeControllerProvider).getColor(
          settings,
          'NEXUS_$item',
          defaultColor: defaultColors[item],
          nameSeed: item,
        );
  }

  Future<String?> _exportWorkoutBlocksPath() async {
    setState(() => _isProcessing = true);
    try {
      final db = ref.read(databaseProvider);
      final combinedData =
          await ExportService.loadWorkoutBlocksCombinedData(db);
      final filePath =
          await ExportService.exportWorkoutBlocksToXlsx(combinedData, db);
      if (mounted) setState(() => _isProcessing = false);
      return filePath;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("EXPORT_FAILED: $e"),
            backgroundColor: Colors.redAccent));
      }
      if (mounted) setState(() => _isProcessing = false);
      return null;
    }
  }

  Future<String?> _exportExercisesPath({bool share = true}) async {
    setState(() => _isProcessing = true);
    try {
      final db = ref.read(databaseProvider);
      final exercises = await db.select(db.baseExercises).get();
      final filePath =
          await ExportService.exportExercisesToCsv(exercises, share: share);
      if (mounted) setState(() => _isProcessing = false);
      return filePath;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("EXPORT_FAILED: $e"),
            backgroundColor: Colors.redAccent));
      }
      if (mounted) setState(() => _isProcessing = false);
      return null;
    }
  }

  Future<void> _importWorkoutBlocks() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result == null || result.files.single.path == null) return;
    setState(() => _isProcessing = true);
    try {
      final file = File(result.files.single.path!);
      final ext = p.extension(file.path).toLowerCase();
      final db = ref.read(databaseProvider);
      Map<String, int> report;

      if (ext == '.xlsx') {
        final bytes = await file.readAsBytes();
        final db = ref.read(databaseProvider);
        report = await ExportService.importWorkoutBlocksFromExcel(bytes, db);
      } else {
        final content = await file.readAsString();
        report = await ExportService.importWorkoutBlocksFromCsv(content, db);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  "IMPORTED: ${report['blocks']} WBs, ${report['kns']} KNS"),
              backgroundColor: LabColors.primary,
              duration: const Duration(seconds: 5)),
        );
      }
      // Refresh the WB manager list provider so imported WBs appear
      ref.invalidate(workoutBlockListProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("IMPORT_FAILED: $e"),
            backgroundColor: Colors.redAccent));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _generateWorkoutFile(String format) async {
    DateTimeRange? range = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
        builder: (context, child) {
          return Theme(
              data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.dark(
                      primary: LabColors.primary,
                      onPrimary: Colors.black,
                      surface: Colors.black,
                      onSurface: Colors.white),
                  dialogTheme:
                      const DialogThemeData(backgroundColor: Colors.black)),
              child: child!);
        });
    if (range == null) return;
    setState(() => _isProcessing = true);
    try {
      final db = ref.read(databaseProvider);
      final settings = ref.read(themeSettingsProvider).value ?? {};
      final tC = ref.read(themeControllerProvider);

      var query = db.select(db.workoutSets).join([
        innerJoin(db.baseExercises,
            db.baseExercises.id.equalsExp(db.workoutSets.baseExerciseId)),
        innerJoin(
            db.workoutLogs, db.workoutLogs.id.equalsExp(db.workoutSets.logId))
      ]);
      final startOfDay =
          DateTime(range.start.year, range.start.month, range.start.day);
      final endOfDay =
          DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59);
      query.where(db.workoutLogs.date.isBetweenValues(startOfDay, endOfDay));
      query.orderBy([
        OrderingTerm.asc(db.workoutLogs.date),
        OrderingTerm.asc(db.workoutSets.orderIndex),
        OrderingTerm.asc(db.workoutSets.timestamp)
      ]);
      final rows = await query.get();
      final fileName = DateFormat('ddMMyy').format(range.start) !=
              DateFormat('ddMMyy').format(range.end)
          ? "WOLOG_${DateFormat('ddMMyy').format(range.start)}_${DateFormat('ddMMyy').format(range.end)}"
          : "WOLOG_${DateFormat('ddMMyy').format(range.start)}";
      if (format == 'pdf') {
        await ExportService.exportWorkoutsToPdf(rows, db, settings, tC,
            fileName: fileName);
      } else if (format == 'xlsx') {
        await ExportService.exportWorkoutsToExcel(rows, db, settings, tC,
            fileName: fileName);
      } else if (format == 'csv') {
        await ExportService.exportWorkoutsToCsv(rows, db, fileName: fileName);
      } else if (format == 'md') {
        await ExportService.exportWorkoutsToMarkdown(rows, db, settings, tC,
            fileName: fileName);
      }
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("EXPORT_SUCCESSFUL")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("EXPORT_FAILED: $e"),
            backgroundColor: Colors.redAccent));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _exportWorkouts(String format) => _generateWorkoutFile(format);

  Future<void> _downloadWorkoutFile(String format) async {
    setState(() => _isProcessing = true);
    try {
      final db = ref.read(databaseProvider);
      DateTimeRange? range = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
        builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                  primary: LabColors.primary, onPrimary: Colors.black),
            ),
            child: child!),
      );
      if (range == null) {
        if (mounted) setState(() => _isProcessing = false);
        return;
      }
      final settings = ref.read(themeSettingsProvider).value ?? {};
      final tC = ref.read(themeControllerProvider);
      final startOfDay =
          DateTime(range.start.year, range.start.month, range.start.day);
      final endOfDay =
          DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59);
      var query = db.select(db.workoutSets).join([
        innerJoin(db.baseExercises,
            db.baseExercises.id.equalsExp(db.workoutSets.baseExerciseId)),
        innerJoin(
            db.workoutLogs, db.workoutLogs.id.equalsExp(db.workoutSets.logId))
      ]);
      query.where(db.workoutLogs.date.isBetweenValues(startOfDay, endOfDay));
      query.orderBy([
        OrderingTerm.asc(db.workoutLogs.date),
        OrderingTerm.asc(db.workoutSets.orderIndex),
        OrderingTerm.asc(db.workoutSets.timestamp)
      ]);
      final rows = await query.get();
      final fileName = DateFormat('ddMMyy').format(range.start) !=
              DateFormat('ddMMyy').format(range.end)
          ? "WOLOG_${DateFormat('ddMMyy').format(range.start)}_${DateFormat('ddMMyy').format(range.end)}"
          : "WOLOG_${DateFormat('ddMMyy').format(range.start)}";

      final ext = format == 'pdf'
          ? 'pdf'
          : format == 'xlsx'
              ? 'xlsx'
              : format == 'csv'
                  ? 'csv'
                  : 'md';

      if (format == 'pdf') {
        await ExportService.exportWorkoutsToPdf(rows, db, settings, tC,
            fileName: fileName, share: false);
      } else if (format == 'xlsx') {
        await ExportService.exportWorkoutsToExcel(rows, db, settings, tC,
            fileName: fileName, share: false);
      } else if (format == 'csv') {
        await ExportService.exportWorkoutsToCsv(rows, db,
            fileName: fileName, share: false);
      } else if (format == 'md') {
        await ExportService.exportWorkoutsToMarkdown(rows, db, settings, tC,
            fileName: fileName, share: false);
      }
      // Read temp file bytes and save via FilePicker (required on mobile)
      final tempDir = await getTemporaryDirectory();
      final tempFile = File("${tempDir.path}/$fileName.$ext");
      if (!await tempFile.exists()) throw Exception('Temp file not found');
      final bytes = await tempFile.readAsBytes();
      final resultPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save $format file',
        fileName: '$fileName.$ext',
        bytes: bytes,
      );

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("SAVED_TO: $resultPath")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("DOWNLOAD_FAILED: $e"),
            backgroundColor: Colors.redAccent));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _importData(String type) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null && result.files.single.path != null) {
      setState(() => _isProcessing = true);
      try {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        final db = ref.read(databaseProvider);
        Map<String, int> report;
        if (type == 'blueprints') {
          report = await ExportService.importBlueprintsFromCsv(content, db);
        } else {
          report = await ExportService.importFromFitNotes(content, db);
        }
        if (mounted) {
          String msg = type == 'blueprints'
              ? "IMPORTED: ${report['blueprints']} BLUEPRINTS, ${report['exercises']} EXERCISES"
              : "IMPORTED: ${report['logs']} LOGS, ${report['sets']} SETS";
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(msg),
              backgroundColor: LabColors.primary,
              duration: const Duration(seconds: 5)));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("IMPORT_FAILED: $e"),
              backgroundColor: Colors.redAccent));
        }
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  

  Future<void> _importExercises() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null && result.files.single.path != null) {
      setState(() => _isProcessing = true);
      try {
        final file = File(result.files.single.path!);
        final extension = p.extension(file.path).toLowerCase();
        final db = ref.read(databaseProvider);
        int count;

        if (extension == '.xlsx') {
          final bytes = await file.readAsBytes();
          count = await ExportService.importExercisesFromExcel(bytes, db);
        } else {
          // Assume CSV for everything else as fallback
          final content = await file.readAsString();
          count = await ExportService.importExercisesFromCsv(content, db);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("IMPORTED: $count NEW_MOVEMENTS_ADDED"),
              backgroundColor: LabColors.primary,
              duration: const Duration(seconds: 5)));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("IMPORT_FAILED: $e"),
              backgroundColor: Colors.redAccent));
        }
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }
}
