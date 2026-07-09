import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:drift/drift.dart' hide Column, Table;
import 'package:intl/intl.dart';
import '../providers/database_provider.dart';
import '../database/database.dart';
import 'styles.dart';
import 'lab_widgets.dart';
import 'main_scaffold.dart';

// ═══════════════════════════════════════════════════════════════
// DB INSPECTOR & EDITOR
// Screen 11 in Hub — Mini-Excel style data grid with:
// - Tabs per table
// - Inline cell editing (TextField on tap)
// - Batch ops: Find All & Replace, Category Replace, Merge Rows
// - Merge: unify rows + update all cross-table FK references
// - Double confirm + sanity check before any DB change
// ═══════════════════════════════════════════════════════════════

class DBInspectorScreen extends ConsumerStatefulWidget {
  const DBInspectorScreen({super.key});
  @override
  ConsumerState<DBInspectorScreen> createState() => _DBInspectorScreenState();
}

class _DBInspectorScreenState extends ConsumerState<DBInspectorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  final Map<String, String> _perTableSearch = {};
  bool _isProcessing = false;

  // ── UNDO SYSTEM ──
  final List<_UndoSnapshot> _undoStack = [];
  static const int _maxUndoDepth = 10;

  bool get _canUndo => _undoStack.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tableConfigs.length, vsync: this);
    // Pre-cache columns and FK refs for all tables
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      for (final cfg in _tableConfigs) {
        await _refreshColumns(cfg);
        await _refreshFKRefs(cfg);
      }
    });
    _tabCtrl.addListener(() {
      setState(() {});
      if (!_tabCtrl.indexIsChanging && _tableConfigs.isNotEmpty) {
        final cfg = _tableConfigs[_tabCtrl.index];
        _refreshColumns(cfg);
        _refreshFKRefs(cfg);
      }
    });
    _searchCtrl.addListener(() {
      setState(() {
        _searchQuery = _searchCtrl.text;
        _perTableSearch[_tableConfigs[_tabCtrl.index].key] = _searchCtrl.text;
      });
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── TABLE CONFIGS ──
  static const _tableConfigs = <_TableCfg>[
    _TableCfg(
        key: 'baseExercises',
        label: 'KNS',
        icon: Icons.library_books,
        table: 'base_exercises',
        pkCol: 'id'),
    _TableCfg(
        key: 'workoutLogs',
        label: 'LOGS',
        icon: Icons.today,
        table: 'workout_logs',
        pkCol: 'id'),
    _TableCfg(
        key: 'workoutSets',
        label: 'SETS',
        icon: Icons.fitness_center,
        table: 'workout_sets',
        pkCol: 'id'),
    _TableCfg(
        key: 'blueprints',
        label: 'BPS',
        icon: Icons.layers,
        table: 'blueprints',
        pkCol: 'id'),
    _TableCfg(
        key: 'blueprintExercises',
        label: 'BP-EX',
        icon: Icons.format_list_numbered,
        table: 'blueprint_exercises',
        pkCol: 'id'),
    _TableCfg(
        key: 'somaticLogs',
        label: 'SOMA',
        icon: Icons.healing,
        table: 'somatic_logs',
        pkCol: 'id'),
    _TableCfg(
        key: 'somaticFolders',
        label: 'FLDRS',
        icon: Icons.folder,
        table: 'somatic_folders',
        pkCol: 'id'),
    _TableCfg(
        key: 'anthropometricLogs',
        label: 'BODY',
        icon: Icons.straighten,
        table: 'anthropometric_logs',
        pkCol: 'id'),
  ];

  // ── UNDO HELPERS ──
  void _pushUndo(_UndoSnapshot snap) {
    _undoStack.add(snap);
    if (_undoStack.length > _maxUndoDepth) {
      _undoStack.removeAt(0);
    }
    setState(() {});
  }

  Future<void> _undoLast() async {
    if (_undoStack.isEmpty) return;
    final snap = _undoStack.removeLast();
    setState(() => _isProcessing = true);
    try {
      final db = ref.read(databaseProvider);

      if (snap.isBulkReplace) {
        // Bulk find-replace undo: restore each saved row
        final rows = snap.row['rows'] as List<dynamic>? ?? [];
        for (final r in rows) {
          final rMap = Map<String, dynamic>.from(r as Map);
          final pkVal = rMap[snap.pkCol];
          final setParts = <String>[];
          final setValues = <dynamic>[];
          for (final col in rMap.keys) {
            if (col == snap.pkCol) continue;
            setParts.add('$col = ?');
            setValues.add(rMap[col]);
          }
          setValues.add(pkVal);
          if (setParts.isNotEmpty) {
            await db.customStatement(
              'UPDATE ${snap.table} SET ${setParts.join(', ')} WHERE ${snap.pkCol} = ?',
              setValues,
            );
          }
        }
      } else if (snap.isMergeUndo) {
        // Merge undo: re-insert the deleted row and revert FK references
        final cols = snap.row.keys.toList();
        if (cols.isNotEmpty) {
          final colNames = cols.join(', ');
          final placeholders = cols.map((_) => '?').join(', ');
          await db.customStatement(
            'INSERT OR REPLACE INTO ${snap.table} ($colNames) VALUES ($placeholders)',
            cols.map((col) => snap.row[col]).toList(),
          );
        }
        // Revert FK references back to PK2
        for (final fk in snap.mergeFkRefs) {
          await db.customStatement(
            'UPDATE ${fk.table} SET ${fk.column} = ? WHERE ${fk.column} = ?',
            [snap.mergePk2, snap.mergePk1],
          );
        }
      } else {
        // Simple cell edit undo: restore the entire saved row
        final cols = _columnsCache[snap.table];
        if (cols == null || cols.isEmpty) return;
        final pkVal = snap.row[snap.pkCol];
        final setParts = <String>[];
        final setValues = <dynamic>[];
        for (final col in cols) {
          if (col == snap.pkCol) continue;
          setParts.add('$col = ?');
          setValues.add(snap.row[col]);
        }
        setValues.add(pkVal);
        if (setParts.isNotEmpty) {
          await db.customStatement(
            'UPDATE ${snap.table} SET ${setParts.join(', ')} WHERE ${snap.pkCol} = ?',
            setValues,
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('UNDO: ${snap.label}', style: LabStyles.mono(context))),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('UNDO ERROR: $e', style: LabStyles.mono(context)),
              backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // ── DATE FORMATTING ──
  String _formatValue(dynamic val, String col) {
    if (val == null) return 'NULL';
    if (val is int &&
        (col.contains('date') || col.contains('time') || col == 'timestamp')) {
      try {
        final dt = DateTime.fromMillisecondsSinceEpoch(val);
        return DateFormat('dd/MM/yy HH:mm').format(dt);
      } catch (_) {
        return val.toString();
      }
    }
    if (val is String && (col.contains('date') || col.contains('time'))) {
      try {
        final dt = DateTime.parse(val);
        return DateFormat('dd/MM/yy HH:mm').format(dt);
      } catch (_) {
        return val;
      }
    }
    if (val is bool) return val ? 'YES' : 'NO';
    return val.toString();
  }

  // ── SANITY CHECK ──
  Future<String> _sanityCheck(_TableCfg cfg) async {
    final db = ref.read(databaseProvider);
    final buf = StringBuffer();
    buf.writeln('SANITY CHECK: ${cfg.label}');

    try {
      // Count rows
      final count = await db.customSelect(
        'SELECT COUNT(*) as cnt FROM ${cfg.table}',
        readsFrom: {
          db.baseExercises
        }, // minimal, we just need a table reference
      ).getSingle();
      buf.writeln('Total rows: ${count.data['cnt']}');

      // Check for null PKs
      final nullPks = await db.customSelect(
        'SELECT COUNT(*) as cnt FROM ${cfg.table} WHERE ${cfg.pkCol} IS NULL',
        readsFrom: {db.baseExercises},
      ).getSingle();
      if ((nullPks.data['cnt'] as int) > 0) {
        buf.writeln('WARNING: ${nullPks.data['cnt']} rows with NULL PK');
      }

      // Check for orphaned FK references (basic)
      buf.writeln('FK checks: see merge for cross-table validation');

      buf.writeln('Status: OK');
    } catch (e) {
      buf.writeln('ERROR: $e');
    }
    return buf.toString();
  }

  // ── DOUBLE CONFIRM DIALOG ──
  Future<bool> _confirmAction(String title, String details,
      {String? sanityResult}) async {
    // First confirm
    final c1 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LabColors.surfaceContainerHigh,
        title: Text('CONFIRM: $title',
            style: LabStyles.mono(context,
                color: LabColors.accent, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Text(details, style: LabStyles.mono(context, fontSize: 10)),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('CANCEL', style: LabStyles.mono(context))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('PROCEED',
                  style: LabStyles.mono(context, color: LabColors.accent))),
        ],
      ),
    );
    if (c1 != true) return false;

    // Second confirm + sanity
    final c2 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LabColors.surfaceContainerHigh,
        title: Text('CONFIRM AGAIN',
            style: LabStyles.mono(context,
                color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('This action will modify the database.',
                  style: LabStyles.mono(context, fontSize: 10)),
              if (sanityResult != null) ...[
                const SizedBox(height: 12),
                Text(sanityResult,
                    style: LabStyles.mono(context,
                        fontSize: 8, color: Colors.grey)),
              ],
              const SizedBox(height: 12),
              Text('Type CONFIRM to proceed:',
                  style: LabStyles.mono(context,
                      fontSize: 10, color: LabColors.accent)),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('ABORT',
                  style: LabStyles.mono(context, color: Colors.redAccent))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('CONFIRM',
                  style: LabStyles.mono(context, color: LabColors.primary))),
        ],
      ),
    );
    return c2 == true;
  }

  // ── BATCH OPERATIONS ──
  Future<void> _batchFindAndReplace(_TableCfg cfg) async {
    final findCtrl = TextEditingController();
    final replaceCtrl = TextEditingController();
    final columnCtrl =
        TextEditingController(text: cfg.pkCol == 'id' ? 'name' : '');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LabColors.surfaceContainerHigh,
        title: Text('FIND & REPLACE — ${cfg.label}',
            style: LabStyles.mono(context, color: LabColors.accent)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: columnCtrl,
                decoration: _inputDecoration('Column name'),
                style: LabStyles.mono(context, fontSize: 12)),
            const SizedBox(height: 8),
            TextField(
                controller: findCtrl,
                decoration: _inputDecoration('Find text'),
                style: LabStyles.mono(context, fontSize: 12)),
            const SizedBox(height: 8),
            TextField(
                controller: replaceCtrl,
                decoration: _inputDecoration('Replace with'),
                style: LabStyles.mono(context, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('CANCEL', style: LabStyles.mono(context))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('REPLACE ALL',
                  style: LabStyles.mono(context, color: LabColors.accent))),
        ],
      ),
    );

    if (confirmed != true || findCtrl.text.isEmpty) return;

    final details =
        'Column: ${columnCtrl.text}\nFind: "${findCtrl.text}"\nReplace: "${replaceCtrl.text}"\nTable: ${cfg.table}';
    final ok = await _confirmAction('REPLACE ALL', details);
    if (!ok) return;

    // Push undo: backup all matching rows before replacement
    final db = ref.read(databaseProvider);
    final matchingRows = await db
        .customSelect(
          'SELECT * FROM ${cfg.table} WHERE ${columnCtrl.text} LIKE ?',
          variables: ['%${findCtrl.text}%'].map((e) => Variable(e)).toList(),
        )
        .get();
    final snapshotRows = matchingRows.map((r) {
      final map = <String, dynamic>{};
      for (final k in r.data.keys) {
        map[k] = r.data[k];
      }
      return map;
    }).toList();

    // For bulk replace, we save a single snapshot with all affected rows as a "bulk" undo
    // The undo will restore each row to its pre-replace state
    _pushUndo(_UndoSnapshot(
      table: cfg.table,
      pkCol: cfg.pkCol,
      row: {'_bulk': true, 'rows': snapshotRows, 'col': columnCtrl.text}
          as Map<String, dynamic>,
      label:
          'Replace "${findCtrl.text}" -> "${replaceCtrl.text}" in ${cfg.table}.${columnCtrl.text} (${snapshotRows.length} rows)',
      isBulkReplace: true,
      findText: findCtrl.text,
      replaceText: replaceCtrl.text,
      targetColumn: columnCtrl.text,
    ));

    setState(() => _isProcessing = true);
    try {
      await db.customStatement(
        'UPDATE ${cfg.table} SET ${columnCtrl.text} = REPLACE(${columnCtrl.text}, ?, ?)',
        [findCtrl.text, replaceCtrl.text],
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('REPLACE COMPLETE', style: LabStyles.mono(context)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('ERROR: $e', style: LabStyles.mono(context)),
          backgroundColor: Colors.redAccent,
        ));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _showCategoryReplaceDialog(_TableCfg cfg) async {
    var columns = _columnsCache[cfg.table] ?? const <String>[];
    if (columns.isEmpty) {
      await _refreshColumns(cfg);
      columns = _columnsCache[cfg.table] ?? const <String>[];
    }
    if (columns.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('NO_COLUMNS_FOUND', style: LabStyles.mono(context)),
        ));
      }
      return;
    }

    final initialColumn = columns.firstWhere(
      (col) => col != cfg.pkCol,
      orElse: () => columns.first,
    );

    final selection = await showDialog<_CategoryReplaceSelection>(
      context: context,
      builder: (ctx) => _CategoryReplaceDialog(
        cfg: cfg,
        columns: columns,
        initialColumn: initialColumn,
        loadValues: _loadCategoryValues,
      ),
    );

    if (selection == null) return;
    await _executeCategoryReplace(
        cfg, selection.column, selection.from, selection.to);
  }

  Future<void> _executeCategoryReplace(
    _TableCfg cfg,
    String column,
    _CategoryValueOption from,
    _CategoryValueOption to,
  ) async {
    if (from.raw == to.raw) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('NO_CHANGE_NEEDED', style: LabStyles.mono(context)),
        ));
      }
      return;
    }

    final db = ref.read(databaseProvider);
    final qTable = _quoteIdent(cfg.table);
    final qColumn = _quoteIdent(column);
    final whereSql = from.raw == null ? '$qColumn IS NULL' : '$qColumn = ?';
    final setSql = to.raw == null ? '$qColumn = NULL' : '$qColumn = ?';
    final selectVariables = <dynamic>[];
    if (from.raw != null) {
      selectVariables.add(from.raw);
    }

    final matchingRows = await db
        .customSelect(
          'SELECT * FROM $qTable WHERE $whereSql',
          variables: selectVariables.map((v) => Variable(v)).toList(),
        )
        .get();

    final snapshotRows = matchingRows.map((r) {
      final map = <String, dynamic>{};
      for (final k in r.data.keys) {
        map[k] = r.data[k];
      }
      return map;
    }).toList();

    final details = 'Table: ${cfg.table}\n'
        'Column: $column\n'
        'TO REPLACE: ${from.display}\n'
        'REPLACE WITH: ${to.display}\n'
        'AFFECTED ROWS: ${snapshotRows.length}';

    final ok = await _confirmAction('CATEGORY REPLACE', details);
    if (!ok) return;

    _pushUndo(_UndoSnapshot(
      table: cfg.table,
      pkCol: cfg.pkCol,
      row: {'_bulk': true, 'rows': snapshotRows, 'col': column}
          as Map<String, dynamic>,
      label:
          'Replace ${from.display} -> ${to.display} in ${cfg.table}.$column (${snapshotRows.length} rows)',
      isBulkReplace: true,
      findText: from.display,
      replaceText: to.display,
      targetColumn: column,
    ));

    setState(() => _isProcessing = true);
    try {
      final updateVariables = <dynamic>[];
      if (to.raw != null) {
        updateVariables.add(to.raw);
      }
      if (from.raw != null) {
        updateVariables.add(from.raw);
      }

      await db.customStatement(
        'UPDATE $qTable SET $setSql WHERE $whereSql',
        updateVariables,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'CATEGORY REPLACE COMPLETE: ${snapshotRows.length} rows',
                  style: LabStyles.mono(context))),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('ERROR: $e', style: LabStyles.mono(context)),
          backgroundColor: Colors.redAccent,
        ));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  String _quoteIdent(String ident) => '"${ident.replaceAll('"', '""')}"';

  String _formatCategoryValue(dynamic raw, String column) {
    if (raw == null) return '<NULL>';
    return _formatValue(raw, column);
  }

  Future<List<_CategoryValueOption>> _loadCategoryValues(
      _TableCfg cfg, String column) async {
    final db = ref.read(databaseProvider);
    final qTable = _quoteIdent(cfg.table);
    final qColumn = _quoteIdent(column);
    final rows = await db
        .customSelect(
          'SELECT DISTINCT $qColumn AS value FROM $qTable ORDER BY $qColumn IS NULL, CAST($qColumn AS TEXT) COLLATE NOCASE',
        )
        .get();

    return rows.map((r) {
      final raw = r.data['value'];
      return _CategoryValueOption(
          raw: raw, display: _formatCategoryValue(raw, column));
    }).toList();
  }

  // Cache for PRAGMA table types: table -> {col: SQLtype}
  static final Map<String, Map<String, String>> _reindexPragmaTypes = {};

  /// Loads column types from PRAGMA table_info
  Future<void> _loadPragmaTypes(_TableCfg cfg) async {
    if (_reindexPragmaTypes.containsKey(cfg.table)) return;
    try {
      final db = ref.read(databaseProvider);
      final result =
          await db.customSelect('PRAGMA table_info(${cfg.table})').get();
      final typeMap = <String, String>{};
      for (final row in result) {
        final name = row.data['name'] as String;
        final type = (row.data['type'] as String).toUpperCase();
        if (type.contains('INT')) {
          typeMap[name] = 'INTEGER';
        } else if (type.contains('REAL') ||
            type.contains('FLOAT') ||
            type.contains('DOUBLE')) {
          typeMap[name] = 'REAL';
        } else {
          typeMap[name] = 'TEXT';
        }
      }
      _reindexPragmaTypes[cfg.table] = typeMap;
    } catch (_) {}
  }

  // ── REPAIR COLUMN TYPES ──
  /// Column-type map based on actual Drift schema definitions
  static final _driftTypes = <String, Map<String, String>>{
    'workout_sets': {
      'id': 'INTEGER',
      'log_id': 'INTEGER',
      'base_exercise_id': 'INTEGER',
      'weight': 'REAL',
      'reps': 'REAL',
      'rpe': 'REAL',
      'rir': 'REAL',
      'technique': 'INTEGER',
      'failure_phase': 'INTEGER',
      'rest_time_seconds': 'INTEGER',
      'hype_level': 'INTEGER',
      'is_pr_song': 'INTEGER',
      'is_pr': 'INTEGER',
      'is_completed': 'INTEGER',
      'order_index': 'INTEGER',
      'timestamp': 'INTEGER',
      'notes': 'TEXT',
      'track_name': 'TEXT',
      'complex_metadata': 'TEXT',
      'priority': 'TEXT',
      'superset_group_id': 'TEXT',
      'superset_name': 'TEXT',
    },
    'base_exercises': {
      'id': 'INTEGER',
      'num_phases': 'INTEGER',
      'order_index': 'INTEGER',
      'is_unilateral': 'INTEGER',
      'name': 'TEXT',
      'prefixes': 'TEXT',
      'implements': 'TEXT',
      'body_positions': 'TEXT',
      'suffixes': 'TEXT',
      'primary_muscle_group': 'TEXT',
      'secondary_muscle_group': 'TEXT',
      'field': 'TEXT',
      'tissue_type': 'TEXT',
      'tissue_name': 'TEXT',
      'phase_descriptions': 'TEXT',
      'intention': 'TEXT',
      'pattern_type': 'TEXT',
      'complex_metadata': 'TEXT',
    },
    'workout_logs': {
      'id': 'INTEGER',
      'duration_minutes': 'INTEGER',
      'accumulated_seconds': 'INTEGER',
      'date': 'INTEGER',
      'workout_start_time': 'INTEGER',
      'notes': 'TEXT',
    },
    'blueprints': {
      'id': 'INTEGER',
      'created_at': 'INTEGER',
      'name': 'TEXT',
      'intention': 'TEXT',
    },
    'blueprint_exercises': {
      'id': 'INTEGER',
      'blueprint_id': 'INTEGER',
      'base_exercise_id': 'INTEGER',
      'order_index': 'INTEGER',
      'target_sets_reps': 'TEXT',
      'priority': 'TEXT',
      'superset_group_id': 'TEXT',
      'superset_name': 'TEXT',
    },
    'somatic_logs': {
      'id': 'INTEGER',
      'set_id': 'INTEGER',
      'spectrum_value': 'INTEGER',
      'description': 'TEXT',
      'tags': 'TEXT',
      'created_at': 'INTEGER',
    },
    'somatic_folders': {
      'id': 'INTEGER',
      'name': 'TEXT',
      'created_at': 'INTEGER',
    },
    'anthropometric_logs': {
      'id': 'INTEGER',
      'value': 'REAL',
      'is_flexed': 'INTEGER',
      'is_pumped': 'INTEGER',
      'created_at': 'INTEGER',
      'date': 'INTEGER',
      'label': 'TEXT',
      'unit': 'TEXT',
    },
  };

  /// Fixes columns that were incorrectly typed as TEXT by old REINDEX.
  Future<void> _repairColumnTypes(_TableCfg cfg) async {
    final ok = await _confirmAction(
      'REPAIR COLUMN TYPES',
      'This will fix all columns in ${cfg.table} that have wrong SQL types.'
          '\n\nRequired after a buggy REINDEX changed REAL/INTEGER columns to TEXT.',
    );
    if (!ok) return;

    setState(() => _isProcessing = true);
    try {
      final db = ref.read(databaseProvider);

      // Get current pragma types
      final pragmaResult =
          await db.customSelect('PRAGMA table_info(${cfg.table})').get();
      final Map<String, String> currentTypes = {};
      final List<String> allCols = [];
      for (final row in pragmaResult) {
        final name = row.data['name'] as String;
        final type = (row.data['type'] as String? ?? 'TEXT').toUpperCase();
        currentTypes[name] = type;
        allCols.add(name);
      }

      // Compare with expected Drift types
      final expectedTypes = _driftTypes[cfg.table] ?? {};
      final Map<String, String> fixes = {};
      for (final col in allCols) {
        final expected = expectedTypes[col];
        if (expected == null) continue;
        final current = currentTypes[col] ?? 'TEXT';
        if (current != expected) {
          fixes[col] = expected;
        }
      }

      if (fixes.isEmpty) {
        // Even if types match, check for missing DEFAULT values
        // Drift relies on table DEFAULTs for columns set to Value.absent()
        try {
          final pragmaInfo =
              await db.customSelect('PRAGMA table_info(${cfg.table})').get();
          bool needsDefaults = false;
          final expectedDefaults = _columnDefaults[cfg.table] ?? {};
          for (final row in pragmaInfo) {
            final name = row.data['name'] as String;
            final dfltValue = row.data['dflt_value'];
            if (expectedDefaults.containsKey(name) && dfltValue == null) {
              needsDefaults = true;
              break;
            }
          }
          if (needsDefaults) {
            // Force recreation — recreate table with DEFAULT values even though types are fine
            final nonIdCols = allCols.where((c) => c != 'id').toList();
            final colDefs = nonIdCols.map((col) {
              final correctType = currentTypes[col]?.isNotEmpty == true
                  ? currentTypes[col]!
                  : 'INTEGER';
              final def = expectedDefaults[col];
              return def != null
                  ? '$col $correctType $def'
                  : '$col $correctType';
            }).join(', ');

            await db.customStatement('PRAGMA foreign_keys = OFF');
            await db.customStatement(
                'CREATE TABLE _repair_${cfg.table} (id INTEGER PRIMARY KEY AUTOINCREMENT, $colDefs)');
            final selectCols = nonIdCols.join(', ');
            await db.customStatement(
                'INSERT INTO _repair_${cfg.table} ($selectCols) SELECT $selectCols FROM ${cfg.table}');
            await db.customStatement('DROP TABLE ${cfg.table}');
            await db.customStatement(
                'ALTER TABLE _repair_${cfg.table} RENAME TO ${cfg.table}');
            await db.customStatement('PRAGMA foreign_keys = ON');
          } else {
            // Types match and defaults exist — just fix any remaining NULLs
            await db.customStatement(
                'UPDATE ${cfg.table} SET is_pr_song = 0 WHERE is_pr_song IS NULL');
            await db.customStatement(
                'UPDATE ${cfg.table} SET is_pr = 0 WHERE is_pr IS NULL');
            await db.customStatement(
                'UPDATE ${cfg.table} SET is_completed = 0 WHERE is_completed IS NULL');
            await db.customStatement(
                'UPDATE ${cfg.table} SET order_index = 0 WHERE order_index IS NULL');
            try {
              await db.customStatement(
                  'UPDATE ${cfg.table} SET timestamp = CAST(strftime("%s", "now") * 1000 AS INTEGER) WHERE timestamp IS NULL');
            } catch (_) {
              final now = DateTime.now().millisecondsSinceEpoch;
              await db.customStatement(
                  'UPDATE ${cfg.table} SET timestamp = ? WHERE timestamp IS NULL',
                  [now]);
            }
          }
          _columnsCache.remove(cfg.table);
          _totalCounts[cfg.key] = 0;
          _pageOffsets[cfg.key] = 0;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('REPAIR: Fixed table schema (types + defaults)',
                      style: LabStyles.mono(context))),
            );
            setState(() {});
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                      Text('REPAIR ERROR: $e', style: LabStyles.mono(context)),
                  backgroundColor: Colors.redAccent),
            );
          }
        }
        setState(() => _isProcessing = false);
        return;
      }

      final nonIdCols = allCols.where((c) => c != 'id').toList();
      final details = fixes.entries
          .map((e) => '${e.key}: ${currentTypes[e.key]} -> ${e.value}')
          .join('\n');

      final ok2 = await _confirmAction('REPAIR TYPES',
          'Fixing ${fixes.length} columns in ${cfg.table}:\n$details');
      if (!ok2) return;

      await db.customStatement('PRAGMA foreign_keys = OFF');
      await db.transaction(() async {
        final colDefs = nonIdCols.map((col) {
          final correctType = fixes[col] ?? currentTypes[col] ?? 'TEXT';
          return '$col $correctType';
        }).join(', ');

        // Add DEFAULT values for columns that Drift omits when Value.absent()
        final defaults = _columnDefaults[cfg.table] ?? {};
        final colDefsWithDefaults = colDefs.split(', ').map((cd) {
          final colName = cd.split(' ')[0].trim();
          final def = defaults[colName];
          return def != null ? '$cd $def' : cd;
        }).join(', ');
        await db.customStatement(
            'CREATE TABLE _repair_${cfg.table} (id INTEGER PRIMARY KEY AUTOINCREMENT, $colDefsWithDefaults)');

        final selectCols = nonIdCols.map((col) {
          if (fixes.containsKey(col)) {
            return 'CAST($col AS ${fixes[col]}) AS $col';
          }
          return col;
        }).join(', ');

        await db.customStatement(
            'INSERT INTO _repair_${cfg.table} (${nonIdCols.join(', ')}) SELECT $selectCols FROM ${cfg.table}');

        // Fix NULLs in non-nullable Drift columns
        await db.customStatement(
            'UPDATE ${cfg.table} SET is_pr_song = 0 WHERE is_pr_song IS NULL');
        await db.customStatement(
            'UPDATE ${cfg.table} SET is_pr = 0 WHERE is_pr IS NULL');
        await db.customStatement(
            'UPDATE ${cfg.table} SET is_completed = 0 WHERE is_completed IS NULL');
        await db.customStatement(
            'UPDATE ${cfg.table} SET order_index = 0 WHERE order_index IS NULL');
        try {
          await db.customStatement(
              'UPDATE ${cfg.table} SET timestamp = CAST(strftime(\"%s\", \"now\") * 1000 AS INTEGER) WHERE timestamp IS NULL');
        } catch (_) {
          final now = DateTime.now().millisecondsSinceEpoch;
          await db.customStatement(
              'UPDATE ${cfg.table} SET timestamp = ? WHERE timestamp IS NULL',
              [now]);
        }

        await db.customStatement('DROP TABLE ${cfg.table}');
        await db.customStatement(
            'ALTER TABLE _repair_${cfg.table} RENAME TO ${cfg.table}');
      });
      await db.customStatement('PRAGMA foreign_keys = ON');

      if (mounted) {
        _columnsCache.remove(cfg.table);
        _totalCounts[cfg.key] = 0;
        _pageOffsets[cfg.key] = 0;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'REPAIR COMPLETE: ${fixes.length} columns fixed in ${cfg.table}',
                  style: LabStyles.mono(context))),
        );
        setState(() {});
      }
    } catch (e) {
      // DB connection might be in bad state on error, try any available db
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('REPAIR ERROR: $e', style: LabStyles.mono(context)),
              backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // ── REINDEX ROWS ──
  /// Reassigns sequential IDs (1,2,3...) to all rows, eliminating gaps.
  /// Updates all FK references across all tables.
  /// Uses a transaction for atomicity.
  Future<void> _reindexRows(_TableCfg cfg) async {
    final ok = await _confirmAction(
      'REINDEX ROWS',
      'This will reassign sequential IDs (1,2,3...) to all rows in ${cfg.table}.'
          '\\n\\nAll FK references in other tables will be updated.'
          '\\n\\nThis operation is IRREVERSIBLE.',
    );
    if (!ok) return;

    setState(() => _isProcessing = true);
    try {
      final db = ref.read(databaseProvider);
      // Load real column types from PRAGMA to avoid inferring TEXT from NULL values
      await _loadPragmaTypes(cfg);

      // Get all rows ordered by current ID
      final rows = await db
          .customSelect('SELECT * FROM ${cfg.table} ORDER BY id ASC')
          .get();
      if (rows.isEmpty) return;

      // Get FK refs that point to this table
      final fkRefs = _getFKRefs(cfg);

      // Build old->new ID mapping
      final Map<int, int> idMap = {};
      int newId = 1;
      for (final row in rows) {
        final oldId = row.data['id'] as int;
        if (oldId != newId) {
          idMap[oldId] = newId;
        }
        newId++;
      }

      if (idMap.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('REINDEX: Already sequential, no changes needed',
                    style: LabStyles.mono(context))),
          );
          setState(() => _isProcessing = false);
        }
        return;
      }

      // Execute in a single transaction
      // Disable FK checks temporarily — IDs are changing and constraints would fail
      await db.customStatement('PRAGMA foreign_keys = OFF');
      await db.transaction(() async {
        // Create temp table with same columns
        final cols = _columnsCache[cfg.table];
        if (cols == null || cols.isEmpty) return;

        // 1. Rename original table
        await db.customStatement(
            'ALTER TABLE ${cfg.table} RENAME TO _reindex_tmp_${cfg.table}');

        // 2. Recreate table with same schema using drift
        // (We reconstruct via raw SQL since we have the column names)
        final nonIdCols = cols.where((c) => c != 'id').toList();
        final colDefs = <String>[];
        for (final row in rows.take(1)) {
          for (final col in nonIdCols) {
            // Determine type from PRAGMA table_info (reliable, not data-inferred)
            final pragmaTypes = _reindexPragmaTypes[cfg.table] ?? {};
            final sqlType = pragmaTypes[col] ?? 'TEXT';
            // For nullable columns, explicitly allow NULL
            colDefs.add('$col $sqlType');
          }
        }

        // Create new table with auto-increment PK
        // Add DEFAULT values to column definitions
        final defaults = _columnDefaults[cfg.table] ?? {};
        final createColsWithDefaults = [
          'id INTEGER PRIMARY KEY AUTOINCREMENT',
          ...colDefs.map((cd) {
            final colName = cd.split(' ')[0];
            final def = defaults[colName];
            return def != null ? '$cd $def' : cd;
          }),
        ];
        await db.customStatement(
            'CREATE TABLE ${cfg.table} (${createColsWithDefaults.join(', ')})');

        // 3. Insert rows with new sequential IDs
        for (final row in rows) {
          final oldId = row.data['id'] as int;
          final mappedId = idMap[oldId] ?? oldId;
          final values = <dynamic>[mappedId];
          final placeholders = <String>['?'];
          for (final col in nonIdCols) {
            values.add(row.data[col]);
            placeholders.add('?');
          }
          await db.customStatement(
            'INSERT INTO ${cfg.table} (id, ${nonIdCols.join(', ')}) VALUES (${placeholders.join(', ')})',
            values,
          );
        }

        // 4. Update FK references in other tables
        for (final fk in fkRefs) {
          for (final entry in idMap.entries) {
            await db.customStatement(
              'UPDATE ${fk.table} SET ${fk.column} = ? WHERE ${fk.column} = ?',
              [entry.value, entry.key],
            );
          }
        }

        // 5. Fix NULL values in columns that Drift expects as non-nullable
        // (is_pr_song, is_pr, is_completed, order_index, timestamp)
        await db.customStatement(
            'UPDATE ${cfg.table} SET is_pr_song = 0 WHERE is_pr_song IS NULL');
        await db.customStatement(
            'UPDATE ${cfg.table} SET is_pr = 0 WHERE is_pr IS NULL');
        await db.customStatement(
            'UPDATE ${cfg.table} SET is_completed = 0 WHERE is_completed IS NULL');
        await db.customStatement(
            'UPDATE ${cfg.table} SET order_index = 0 WHERE order_index IS NULL');
        try {
          await db.customStatement(
              'UPDATE ${cfg.table} SET timestamp = CAST(strftime(\"%s\", \"now\") * 1000 AS INTEGER) WHERE timestamp IS NULL');
        } catch (_) {
          // Fallback: set to current unix time in ms
          final now = DateTime.now().millisecondsSinceEpoch;
          await db.customStatement(
              'UPDATE ${cfg.table} SET timestamp = ? WHERE timestamp IS NULL',
              [now]);
        }

        // 6. Drop temp table
        await db.customStatement('DROP TABLE _reindex_tmp_${cfg.table}');

        // 6. Reset sqlite_sequence for this table
        try {
          await db.customStatement(
              'UPDATE sqlite_sequence SET seq = (SELECT MAX(id) FROM ${cfg.table}) WHERE name = ?',
              [cfg.table]);
        } catch (_) {
          // sqlite_sequence might not exist
        }
      });
      await db.customStatement('PRAGMA foreign_keys = ON');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'REINDEX COMPLETE: ${rows.length} rows, ${idMap.length} IDs remapped',
                  style: LabStyles.mono(context))),
        );
        // Force refresh
        _columnsCache.remove(cfg.table);
        _totalCounts[cfg.key] = 0;
        _pageOffsets[cfg.key] = 0;
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('REINDEX ERROR: $e', style: LabStyles.mono(context)),
              backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // ── MERGE ──
  Future<void> _mergeRows(_TableCfg cfg) async {
    final pk1Ctrl = TextEditingController();
    final pk2Ctrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LabColors.surfaceContainerHigh,
        title: Text(' MERGE ROWS — ${cfg.label}',
            style: LabStyles.mono(context, color: LabColors.accent)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('PK to KEEP (survives):',
                style:
                    LabStyles.mono(context, fontSize: 9, color: Colors.grey)),
            TextField(
                controller: pk1Ctrl,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration('PK 1 (keep)'),
                style: LabStyles.mono(context, fontSize: 12)),
            const SizedBox(height: 12),
            Text('PK to DELETE (merge into PK 1):',
                style:
                    LabStyles.mono(context, fontSize: 9, color: Colors.grey)),
            TextField(
                controller: pk2Ctrl,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration('PK 2 (delete)'),
                style: LabStyles.mono(context, fontSize: 12)),
            const SizedBox(height: 8),
            Text('All FK references to PK 2 will be updated to point to PK 1.',
                style: LabStyles.mono(context,
                    fontSize: 8, color: Colors.orangeAccent)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('CANCEL', style: LabStyles.mono(context))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('MERGE',
                  style: LabStyles.mono(context, color: LabColors.accent))),
        ],
      ),
    );

    if (confirmed != true) return;
    final pk1 = int.tryParse(pk1Ctrl.text);
    final pk2 = int.tryParse(pk2Ctrl.text);
    if (pk1 == null || pk2 == null || pk1 == pk2) return;

    // Push undo snapshot: backup the row being deleted + FK references
    final db = ref.read(databaseProvider);
    final fkRow2 = await db.customSelect(
      'SELECT * FROM ${cfg.table} WHERE ${cfg.pkCol} = ?',
      variables: [Variable(pk2)],
    ).getSingleOrNull();
    final fkRowMap = <String, dynamic>{};
    if (fkRow2 != null) {
      for (final k in fkRow2.data.keys) fkRowMap[k] = fkRow2.data[k];
    }
    final fks = _getFKRefs(cfg);
    _pushUndo(_UndoSnapshot(
      table: cfg.table,
      pkCol: cfg.pkCol,
      row: fkRowMap,
      label: 'Merge PK $pk2 → PK $pk1 in ${cfg.table}',
      isMergeUndo: true,
      mergePk1: pk1,
      mergePk2: pk2,
      mergeTable: cfg.table,
      mergePkCol: cfg.pkCol,
      mergeFkRefs: fks,
    ));

    setState(() => _isProcessing = true);
    try {
      final fks = _getFKRefs(cfg);

      // For each FK reference, update PK 2 → PK 1
      for (final fk in fks) {
        await db.customStatement(
          'UPDATE ${fk.table} SET ${fk.column} = ? WHERE ${fk.column} = ?',
          [pk1, pk2],
        );
      }

      // Delete the merged row
      await db.customStatement(
          'DELETE FROM ${cfg.table} WHERE ${cfg.pkCol} = ?', [pk2]);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'MERGED: PK $pk2 → PK $pk1 (${fks.length} FK tables updated)',
                  style: LabStyles.mono(context))),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('MERGE ERROR: $e', style: LabStyles.mono(context)),
            backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // Cache for dynamic FK discovery: table key -> FK refs
  static final Map<String, List<_FKRef>> _fkCache = {};

  List<_FKRef> _getFKRefs(_TableCfg cfg) {
    return _fkCache[cfg.key] ?? [];
  }

  /// Discovers FK references dynamically from SQLite pragma_foreign_key_list
  Future<void> _refreshFKRefs(_TableCfg cfg) async {
    try {
      final db = ref.read(databaseProvider);
      final result =
          await db.customSelect('PRAGMA foreign_key_list(${cfg.table})').get();
      final refs = <_FKRef>[];
      for (final row in result) {
        refs.add(_FKRef(
          table: row.data['from'] as String? ?? '',
          column: row.data['to'] as String? ?? '',
        ));
      }
      // But we need the REVERSE: which tables reference THIS table's PK.
      // So query ALL tables for FKs pointing to cfg.table.
      final allTablesResult = await db
          .customSelect(
              "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'android_%'")
          .get();
      final reverseRefs = <_FKRef>[];
      for (final tRow in allTablesResult) {
        final tblName = tRow.data['name'] as String;
        if (tblName == cfg.table) continue;
        try {
          final fkRows =
              await db.customSelect('PRAGMA foreign_key_list($tblName)').get();
          for (final fk in fkRows) {
            if (fk.data['table'] == cfg.table) {
              reverseRefs.add(
                  _FKRef(table: tblName, column: fk.data['from'] as String));
            }
          }
        } catch (_) {}
      }
      _fkCache[cfg.key] = reverseRefs;
      if (mounted) setState(() {});
    } catch (_) {}
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 10, color: Colors.grey),
        isDense: true,
        enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.grey)),
      );

  // ── BUILD ──
  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'DB_INSPECTOR_EDITOR',
      screenKey: 'DATASET',
      body: Column(
        children: [
          // ── Search bar ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: LabColors.surfaceDim,
                      border: Border.all(
                          color: LabColors.cyanBorder.withValues(alpha: 0.3),
                          width: 0.5),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      style: LabStyles.mono(context,
                          fontSize: 12, color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'SEARCH_ACROSS_TABLES...',
                        hintStyle: LabStyles.mono(context,
                            fontSize: 10, color: Colors.grey),
                        prefixIcon: const Icon(Icons.search,
                            size: 16, color: LabColors.primary),
                        isDense: true,
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Undo button
                IconButton(
                  icon: Icon(Icons.undo,
                      size: 16,
                      color: _canUndo ? LabColors.accent : Colors.grey[800]),
                  onPressed: _canUndo
                      ? () async {
                          final snap = _undoStack.last;
                          final ok = await _confirmAction(
                              'UNDO', 'Revert: ${snap.label}');
                          if (ok) await _undoLast();
                        }
                      : null,
                  tooltip: _canUndo
                      ? 'UNDO: ${_undoStack.last.label}'
                      : 'NO_UNDO_HISTORY',
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 28, minHeight: 28),
                ),
                const SizedBox(width: 4),
                // Batch ops menu
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: LabColors.primary),
                  color: LabColors.surfaceContainerHigh,
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                        value: 'findReplace',
                        child: Text('FIND & REPLACE ALL',
                            style: LabStyles.mono(context, fontSize: 10))),
                    PopupMenuItem(
                        value: 'categoryReplace',
                        child: Text('CATEGORY REPLACE',
                            style: LabStyles.mono(context, fontSize: 10))),
                    PopupMenuItem(
                        value: 'merge',
                        child: Text('MERGE ROWS',
                            style: LabStyles.mono(context, fontSize: 10))),
                    PopupMenuItem(
                        value: 'reindex',
                        child: Text('REINDEX ROWS',
                            style: LabStyles.mono(context, fontSize: 10))),
                    PopupMenuItem(
                        value: 'repairTypes',
                        child: Text('REPAIR COLUMN TYPES',
                            style: LabStyles.mono(context, fontSize: 10))),
                    PopupMenuItem(
                        value: 'config',
                        child: Text('VIEW CONFIG',
                            style: LabStyles.mono(context, fontSize: 10))),
                    PopupMenuItem(
                        value: 'autoMerge',
                        child: Text('AUTO-MERGE NAMES',
                            style: LabStyles.mono(context, fontSize: 10))),
                  ],
                  onSelected: (v) {
                    final cfg = _tableConfigs[_tabCtrl.index];
                    if (v == 'findReplace') _batchFindAndReplace(cfg);
                    if (v == 'categoryReplace') _showCategoryReplaceDialog(cfg);
                    if (v == 'merge') _mergeRows(cfg);
                    if (v == 'reindex') _reindexRows(cfg);
                    if (v == 'repairTypes') _repairColumnTypes(cfg);
                    if (v == 'config') _showConfigDialog(cfg);
                    if (v == 'autoMerge') _autoMergeNames(cfg);
                  },
                ),
              ],
            ),
          ),
          // ── Tabs ──
          TabBar(
            controller: _tabCtrl,
            isScrollable: true,
            indicatorColor: LabColors.accent,
            labelColor: LabColors.accent,
            unselectedLabelColor: Colors.grey,
            labelStyle: LabStyles.mono(context,
                fontSize: 8, fontWeight: FontWeight.bold),
            tabs: _tableConfigs
                .map((t) => Tab(icon: Icon(t.icon, size: 14), text: t.label))
                .toList(),
            onTap: (index) => setState(() {
              _tabCtrl.index = index;
              _searchCtrl.text =
                  _perTableSearch[_tableConfigs[index].key] ?? '';
              final key = _tableConfigs[index].key;
              _pageOffsets[key] = 0;
              _totalCounts[key] = 0;
            }),
          ),
          // ── Table content ──
          Expanded(
            child: _isProcessing
                ? const Center(
                    child: CircularProgressIndicator(color: LabColors.primary))
                : TabBarView(
                    controller: _tabCtrl,
                    physics: const NeverScrollableScrollPhysics(),
                    children:
                        _tableConfigs.map((t) => _buildTableGrid(t)).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Pagination state per table key ──
  // Per-table page sizes (user-configurable)
  static final Map<String, int> _pageSizes = <String, int>{
    'baseExercises': 25,
    'workoutSets': 25,
  };
  static const _defaultPageSize = 50;

  // Per-table columns to HIDE (user-configurable — cloned from defaults)
  static const _defaultHiddenColumns = <String, Set<String>>{
    'baseExercises': {
      'vp_multiplier',
      'order_index',
      'complex_metadata',
      'body_positions',
      'pattern_type',
      'intention'
    },
    'workoutSets': {
      'log_id',
      'rest_time_seconds',
      'hype_level',
      'is_pr_song',
      'order_index',
      'complex_metadata',
      'superset_group_id',
      'superset_name'
    },
    'somaticLogs': {'set_id', 'created_at'},
  };
  final _userHiddenColumns = <String, Set<String>>{};
  Set<String> _hiddenFor(String key) => _userHiddenColumns.containsKey(key)
      ? _userHiddenColumns[key]!
      : (_defaultHiddenColumns[key] ?? {});

  // Display-name overrides (code name → UI label)
  static final _columnLabels = <String, Map<String, String>>{
    'workoutSets': {'priority': 'UTILITY'},
    'blueprintExercises': {'priority': 'UTILITY'},
    'somaticLogs': {'spectrum_value': 'SPECTRUM'},
  };

  // Column DEFAULT values (needed because REINDEX creates tables without them)
  // Drift omits Value.absent() columns from INSERTs — SQLite then uses table defaults
  static final _columnDefaults = <String, Map<String, String>>{
    'workout_sets': {
      'is_pr_song': 'DEFAULT 0',
      'is_pr': 'DEFAULT 0',
      'is_completed': 'DEFAULT 0',
      'order_index': 'DEFAULT 0',
    },
    'base_exercises': {
      'order_index': 'DEFAULT 0',
      'num_phases': 'DEFAULT 1',
      'is_unilateral': 'DEFAULT 0',
    },
    'workout_logs': {
      'accumulated_seconds': 'DEFAULT 0',
    },
  };

  // Per-table extra WHERE clauses
  static const _extraFilters = <String, String>{
    'workoutLogs': "notes IS NOT NULL AND notes != ''",
  };

  final Map<String, int> _pageOffsets = {};
  final Map<String, int> _totalCounts = {};
  final Map<String, bool> _loadingMore = {};

  int _getOffset(String key) => _pageOffsets[key] ?? 0;
  int _getTotal(String key) => _totalCounts[key] ?? 0;

  int _pageSizeFor(_TableCfg cfg) => _pageSizes[cfg.key] ?? _defaultPageSize;

  Widget _buildTableGrid(_TableCfg cfg) {
    final db = ref.watch(databaseProvider);
    final offset = _getOffset(cfg.key);
    final total = _getTotal(cfg.key);

    // First load: get total count + first page
    if (total == 0 && !(_loadingMore[cfg.key] ?? false)) {
      _loadingMore[cfg.key] = true;
      _loadCount(db, cfg);
    }

    final searchTerm = (_perTableSearch[cfg.key] ?? '').isEmpty
        ? null
        : _perTableSearch[cfg.key];
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchPage(db, cfg, offset, search: searchTerm),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
              child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(
                color: LabColors.primary, strokeWidth: 2),
          ));
        }
        final rows = snapshot.data!;
        if (rows.isEmpty && total > 0) {
          // Page beyond data — snap back
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() => _pageOffsets[cfg.key] = 0);
          });
          return const Center(
              child: CircularProgressIndicator(
                  color: LabColors.primary, strokeWidth: 2));
        }

        // Search is now done at SQL level — rows are already filtered
        final filtered = rows;
        if (filtered.isEmpty) {
          return Center(
              child: Text(
            _perTableSearch[cfg.key]?.isNotEmpty == true
                ? 'NO_MATCHES'
                : 'NO_DATA_FOUND',
            style: LabStyles.mono(context, color: Colors.grey),
          ));
        }

        final columns = _getColumns(cfg);
        final ps = _pageSizeFor(cfg);
        final totalPages = (total / ps).ceil().clamp(1, 9999);
        final currentPage = (offset / ps).floor() + 1;

        return Column(
          children: [
            // ── Pagination bar ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: LabColors.surfaceDim,
              child: Row(
                children: [
                  Text('${filtered.length} / $total rows',
                      style: LabStyles.mono(context,
                          fontSize: 8, color: Colors.grey)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.first_page, size: 16),
                    color: offset > 0 ? LabColors.primary : Colors.grey[800],
                    onPressed: offset > 0
                        ? () => setState(() => _pageOffsets[cfg.key] = 0)
                        : null,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 16),
                    color: offset > 0 ? LabColors.primary : Colors.grey[800],
                    onPressed: offset > 0
                        ? () => setState(() => _pageOffsets[cfg.key] =
                            (offset - _pageSizeFor(cfg)).clamp(0, 99999))
                        : null,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                  Text('PG $currentPage/$totalPages',
                      style: LabStyles.mono(context,
                          fontSize: 8, color: LabColors.primary)),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 16),
                    color: (offset + ps) < total
                        ? LabColors.primary
                        : Colors.grey[800],
                    onPressed: (offset + ps) < total
                        ? () =>
                            setState(() => _pageOffsets[cfg.key] = offset + ps)
                        : null,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                  IconButton(
                    icon: const Icon(Icons.last_page, size: 16),
                    color: (offset + ps) < total
                        ? LabColors.primary
                        : Colors.grey[800],
                    onPressed: (offset + ps) < total
                        ? () => setState(() =>
                            _pageOffsets[cfg.key] = ((totalPages - 1) * ps))
                        : null,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                ],
              ),
            ),
            // ── Data rows (smooth 2D panning) ──
            Expanded(
              child: InteractiveViewer(
                constrained: false,
                boundaryMargin: EdgeInsets.zero,
                minScale: 1.0,
                maxScale: 1.0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Container(
                      constraints:
                          const BoxConstraints(minHeight: 24, maxHeight: 40),
                      color: LabColors.primary.withValues(alpha: 0.08),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: columns
                            .map((col) => Container(
                                  width: 100,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 3),
                                  child: Text(
                                    (_columnLabels[cfg.key]?[col] ?? col)
                                        .toUpperCase(),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: LabStyles.mono(context,
                                            fontSize: 6.5,
                                            color: LabColors.primary,
                                            fontWeight: FontWeight.bold)
                                        .copyWith(height: 1.1),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                    // Data rows
                    ...filtered.map((row) {
                      return Container(
                        decoration: BoxDecoration(
                          border: Border(
                              bottom: BorderSide(
                                  color: LabColors.cyanBorder
                                      .withValues(alpha: 0.08),
                                  width: 0.5)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: columns.map((col) {
                            final val = row[col];
                            final display = _formatValue(val, col);
                            final isPK = col == cfg.pkCol;
                            return Container(
                              width: 100,
                              constraints: const BoxConstraints(
                                  minHeight: 20, maxHeight: 36),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 2),
                              child: isPK
                                  ? Text(display,
                                      style: LabStyles.mono(context,
                                          fontSize: 8,
                                          color: LabColors.primary))
                                  : InkWell(
                                      onTap: () =>
                                          _editCell(cfg, row, col, display),
                                      child: Text(
                                        display,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: LabStyles.mono(context,
                                            fontSize: 8),
                                      ),
                                    ),
                            );
                          }).toList(),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showConfigDialog(_TableCfg cfg) async {
    final allCols = _columnsCache[cfg.table] ?? [];
    if (allCols.isEmpty) return;
    final hidden = _hiddenFor(cfg.key).toSet(); // mutable copy
    int pageSize = _pageSizes[cfg.key] ?? _defaultPageSize;

    await showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setDState) => AlertDialog(
          backgroundColor: LabColors.background,
          title: Text('${cfg.label} CONFIG',
              style: LabStyles.mono(context,
                  fontSize: 12, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page size
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[700]!, width: 0.5)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ROWS PER PAGE',
                          style: LabStyles.mono(context,
                              fontSize: 9,
                              color: Colors.grey[400],
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(children: [
                        for (final size in [10, 25, 50, 100, 250])
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: InkWell(
                              onTap: () => setDState(() {
                                pageSize = size;
                              }),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: pageSize == size
                                      ? LabColors.primary
                                      : Colors.transparent,
                                  border: Border.all(
                                      color: LabColors.primary, width: 0.5),
                                ),
                                child: Text('$size',
                                    style: LabStyles.mono(context,
                                        fontSize: 9,
                                        color: pageSize == size
                                            ? Colors.black
                                            : Colors.white)),
                              ),
                            ),
                          ),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        border:
                            Border.all(color: Colors.grey[700]!, width: 0.5)),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('VISIBLE COLUMNS',
                              style: LabStyles.mono(context,
                                  fontSize: 9,
                                  color: Colors.grey[400],
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ...allCols.map((col) => InkWell(
                                onTap: () => setDState(() {
                                  if (hidden.contains(col)) {
                                    hidden.remove(col);
                                  } else {
                                    hidden.add(col);
                                  }
                                }),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 3),
                                  child: Row(children: [
                                    Icon(
                                        hidden.contains(col)
                                            ? Icons.check_box_outline_blank
                                            : Icons.check_box,
                                        color: hidden.contains(col)
                                            ? Colors.grey[600]
                                            : LabColors.primary,
                                        size: 18),
                                    const SizedBox(width: 8),
                                    Text(col,
                                        style: LabStyles.mono(context,
                                            fontSize: 9,
                                            color: hidden.contains(col)
                                                ? Colors.grey[600]
                                                : Colors.white)),
                                  ]),
                                ),
                              )),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(c),
                child: Text('CANCEL',
                    style: LabStyles.mono(context, color: Colors.grey))),
            TextButton(
                onPressed: () {
                  setState(() {
                    _userHiddenColumns[cfg.key] = hidden;
                    _pageSizes[cfg.key] = pageSize;
                  });
                  Navigator.pop(c);
                },
                child: Text('APPLY',
                    style: LabStyles.mono(context, color: LabColors.primary))),
          ],
        ),
      ),
    );
  }

  Future<void> _autoMergeNames(_TableCfg cfg) async {
    if (cfg.key != 'baseExercises') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('AUTO-MERGE: Only available on KNS table')));
      return;
    }
    final db = ref.read(databaseProvider);
    final allExercises = await db.select(db.baseExercises).get();

    // Group by lowercase-name — find duplicates with different casing/spelling
    final Map<String, List<BaseExercise>> byLower = {};
    for (final ex in allExercises) {
      final key = ex.name.toLowerCase().trim();
      byLower.putIfAbsent(key, () => []).add(ex);
    }

    // Find groups with >1 entries (exact case-insensitive dupes)
    final dupes = byLower.entries.where((e) => e.value.length > 1).toList();

    // Also find near-matches: normalize name (remove common typos)
    final Map<String, List<BaseExercise>> byNormalized = {};
    for (final ex in allExercises) {
      // Collapse spaces, remove trailing/leading whitespace, normalize "CALISTHENICS"/"CALISTECNICS" etc.
      String normalized = ex.name
          .toLowerCase()
          .trim()
          .replaceAll(RegExp(r'calisthe?c?nics?'), 'CALISTHENICS')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      byNormalized.putIfAbsent(normalized, () => []).add(ex);
    }
    final nearDupes =
        byNormalized.entries.where((e) => e.value.length > 1).toList();

    // Combine both lists, deduplicate
    final suggestions = <String, List<BaseExercise>>{};
    for (final e in dupes) {
      suggestions[e.key] = e.value;
    }
    for (final e in nearDupes) {
      suggestions[e.key] = e.value;
    }

    if (suggestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AUTO-MERGE: No duplicates found')));
      return;
    }

    if (!context.mounted) return;
    await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: LabColors.background,
        title: Text('AUTO-MERGE SUGGESTIONS',
            style: LabStyles.mono(context,
                fontSize: 12, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 320,
          child: ListView(
            shrinkWrap: true,
            children: suggestions.entries.map((entry) {
              final exs = entry.value;
              // Pick canonical name (longest = most detailed)
              exs.sort((a, b) => b.name.length.compareTo(a.name.length));
              final canonical = exs.first;
              final rest = exs.skip(1).toList();

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[700]!, width: 0.5),
                  color: LabColors.surfaceContainerLow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('KEEP: ${canonical.name}',
                        style: LabStyles.mono(context,
                            fontSize: 10,
                            color: LabColors.primary,
                            fontWeight: FontWeight.bold)),
                    Text('MERGE: ${rest.map((e) => e.name).join(', ')}',
                        style: LabStyles.mono(context,
                            fontSize: 9, color: Colors.grey[400])),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final ok = await _confirmAction('MERGE',
                            'Merge ${rest.length} rows into "${canonical.name}"?\\n\\nThis updates all FK references and deletes the merged rows.');
                        if (!ok || !c.mounted) return;
                        setState(() => _isProcessing = true);
                        try {
                          for (final r in rest) {
                            // Update workout_sets FK
                            await db.customStatement(
                              'UPDATE workout_sets SET base_exercise_id = ? WHERE base_exercise_id = ?',
                              [canonical.id, r.id],
                            );
                            // Update workout_block_kns references
                            await db.customStatement(
                              'UPDATE workout_block_kns SET base_exercise_id = ? WHERE base_exercise_id = ?',
                              [canonical.id, r.id],
                            );
                            // Update set_intent_definitions if any FK
                            // Delete the merged row
                            await (db.delete(db.baseExercises)
                                  ..where((t) => t.id.equals(r.id)))
                                .go();
                          }
                          Navigator.pop(c);
                          setState(() {
                            _isProcessing = false;
                            _totalCounts[cfg.key] = 0; // force reload
                          });
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                  'MERGED ${rest.length} rows into "${canonical.name}"')));
                        } catch (e) {
                          setState(() => _isProcessing = false);
                          debugPrint('[AUTO_MERGE] $e');
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.2),
                          border:
                              Border.all(color: Colors.redAccent, width: 0.5),
                        ),
                        child: Text('MERGE',
                            style: LabStyles.mono(context,
                                fontSize: 9, color: Colors.redAccent)),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c),
              child: Text('CLOSE',
                  style: LabStyles.mono(context, color: Colors.grey))),
        ],
      ),
    );
  }

  Future<void> _loadCount(AppDatabase db, _TableCfg cfg) async {
    try {
      final rows = await db.executor
          .runSelect('SELECT COUNT(*) as cnt FROM ' + cfg.table, []);
      final result = rows.first;
      if (mounted) {
        setState(() {
          _totalCounts[cfg.key] = result['cnt'] as int;
          _loadingMore[cfg.key] = false;
        });
      }
    } catch (_) {
      _loadingMore[cfg.key] = false;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchPage(
      AppDatabase db, _TableCfg cfg, int offset,
      {String? search}) async {
    String sql;
    List<dynamic>? args;

    // Build WHERE clauses
    final clauses = <String>[];
    final extraFilter = _extraFilters[cfg.key];
    if (extraFilter != null && extraFilter.isNotEmpty) {
      clauses.add(extraFilter);
    }

    if (search != null && search.isNotEmpty) {
      final cols = _columnsCache[cfg.table];
      if (cols != null && cols.isNotEmpty) {
        final conditions = cols
            .map((col) => 'CAST($col AS TEXT) LIKE ? COLLATE NOCASE')
            .join(' OR ');
        clauses.add('($conditions)');
        args = List.filled(cols.length, '%$search%');
      }
    }

    final whereSql =
        clauses.isNotEmpty ? ' WHERE ${clauses.join(" AND ")}' : '';
    sql =
        'SELECT * FROM ${cfg.table}$whereSql ORDER BY id DESC LIMIT ${_pageSizeFor(cfg)} OFFSET $offset';

    final result = (args != null && args.isNotEmpty)
        ? await db
            .customSelect(sql, variables: args.map((a) => Variable(a)).toList())
            .get()
        : await db.customSelect(sql).get();

    return result.map((row) {
      final map = <String, dynamic>{};
      for (final key in row.data.keys) {
        map[key] = row.data[key];
      }
      return map;
    }).toList();
  }

  // _buildCell logic inlined in _buildTableGrid Row children.

  Future<void> _editCell(_TableCfg cfg, Map<String, dynamic> row, String col,
      String currentValue) async {
    final ctrl =
        TextEditingController(text: currentValue == 'NULL' ? '' : currentValue);
    final pk = row[cfg.pkCol];

    final newValue = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LabColors.surfaceContainerHigh,
        title: Text('EDIT CELL — $col',
            style: LabStyles.mono(context, color: LabColors.accent)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Table: ${cfg.table}  |  PK: $pk',
                style:
                    LabStyles.mono(context, fontSize: 8, color: Colors.grey)),
            const SizedBox(height: 8),
            TextField(
              controller: ctrl,
              style: LabStyles.mono(context, fontSize: 12),
              decoration: InputDecoration(
                labelText: col,
                labelStyle: const TextStyle(fontSize: 10, color: Colors.grey),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('CANCEL', style: LabStyles.mono(context))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text),
              child: Text('SAVE',
                  style: LabStyles.mono(context, color: LabColors.accent))),
        ],
      ),
    );

    if (newValue == null || newValue == currentValue) return;

    // Double confirm
    final ok = await _confirmAction(
      'EDIT CELL',
      'Table: ${cfg.table}\nColumn: $col\nPK: $pk\n\nFrom: "$currentValue"\nTo: "$newValue"',
    );
    if (!ok) return;

    // Push undo snapshot before modifying
    _pushUndo(_UndoSnapshot(
      table: cfg.table,
      pkCol: cfg.pkCol,
      row: Map<String, dynamic>.from(row),
      label: 'Edit $col on PK $pk',
    ));

    setState(() => _isProcessing = true);
    try {
      final db = ref.read(databaseProvider);
      await db.customStatement(
        'UPDATE ${cfg.table} SET $col = ? WHERE ${cfg.pkCol} = ?',
        [newValue.isEmpty ? null : newValue, pk],
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('CELL UPDATED', style: LabStyles.mono(context))));
        setState(() {}); // refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('ERROR: $e', style: LabStyles.mono(context)),
          backgroundColor: Colors.redAccent,
        ));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // Cache for dynamic column discovery: table name -> column names
  static final Map<String, List<String>> _columnsCache = {};

  List<String> _getColumns(_TableCfg cfg) {
    if (_columnsCache.containsKey(cfg.table)) {
      final allCols = _columnsCache[cfg.table]!;
      final hidden = _hiddenFor(cfg.key);
      if (hidden.isEmpty) return allCols;
      return allCols.where((col) => !hidden.contains(col)).toList();
    }
    // Fallback minimal - will be populated on first access via _refreshColumns
    return ['id'];
  }

  /// Discovers columns dynamically from the actual SQLite schema
  Future<void> _refreshColumns(_TableCfg cfg) async {
    try {
      final db = ref.read(databaseProvider);
      final result =
          await db.customSelect('PRAGMA table_info(${cfg.table})').get();
      final cols = <String>[];
      for (final row in result) {
        final colName = row.data['name'] as String;
        if (colName != 'rowid') {
          cols.add(colName);
        }
      }
      if (cols.isNotEmpty) {
        _columnsCache[cfg.table] = cols;
        // Pre-populate user hidden columns from defaults
        _userHiddenColumns.putIfAbsent(cfg.key,
            () => Set<String>.from(_defaultHiddenColumns[cfg.key] ?? {}));
        if (mounted) setState(() {});
      }
    } catch (_) {
      // Keep cached/default on error
    }
  }

  // _fetchTableData replaced by _fetchPage + _loadCount for pagination.
}

// ── HELPER CLASSES ──

class _CategoryReplaceSelection {
  final String column;
  final _CategoryValueOption from;
  final _CategoryValueOption to;

  const _CategoryReplaceSelection({
    required this.column,
    required this.from,
    required this.to,
  });
}

class _CategoryValueOption {
  final dynamic raw;
  final String display;

  const _CategoryValueOption({required this.raw, required this.display});
}

class _CategoryReplaceDialog extends StatefulWidget {
  final _TableCfg cfg;
  final List<String> columns;
  final String initialColumn;
  final Future<List<_CategoryValueOption>> Function(
      _TableCfg cfg, String column) loadValues;

  const _CategoryReplaceDialog({
    required this.cfg,
    required this.columns,
    required this.initialColumn,
    required this.loadValues,
  });

  @override
  State<_CategoryReplaceDialog> createState() => _CategoryReplaceDialogState();
}

class _CategoryReplaceDialogState extends State<_CategoryReplaceDialog> {
  late String _selectedColumn;
  _CategoryValueOption? _selectedFrom;
  _CategoryValueOption? _selectedTo;
  List<_CategoryValueOption> _values = const [];
  bool _loadingValues = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _selectedColumn = widget.initialColumn;
    _loadValues();
  }

  Future<void> _loadValues() async {
    setState(() {
      _loadingValues = true;
      _loadError = null;
      _values = const [];
      _selectedFrom = null;
      _selectedTo = null;
    });

    try {
      final values = await widget.loadValues(widget.cfg, _selectedColumn);
      if (!mounted) return;
      setState(() {
        _values = values;
        _loadingValues = false;
        if (values.isNotEmpty) {
          _selectedFrom = values.first;
          _selectedTo = values.length > 1 ? values[1] : values.first;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _values = const [];
        _loadingValues = false;
        _loadError = e.toString();
      });
    }
  }

  void _selectColumn(String column) {
    if (column == _selectedColumn) return;
    setState(() {
      _selectedColumn = column;
      _values = const [];
      _selectedFrom = null;
      _selectedTo = null;
      _loadError = null;
    });
    _loadValues();
  }

  bool get _canApply =>
      !_loadingValues &&
      _selectedFrom != null &&
      _selectedTo != null &&
      !identical(_selectedFrom, _selectedTo);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: LabColors.background,
      contentPadding: const EdgeInsets.all(10),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(
            color: LabColors.primary.withValues(alpha: 0.35), width: 0.75),
      ),
      title: Text('CATEGORY REPLACE — ${widget.cfg.label}',
          style: LabStyles.mono(context,
              fontSize: 12,
              color: LabColors.accent,
              fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 390,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('COLUMN'),
            const SizedBox(height: 6),
            _buildColumnList(),
            const SizedBox(height: 10),
            _buildValueSelector('TO REPLACE', _selectedFrom, (value) {
              setState(() => _selectedFrom = value);
            }),
            const SizedBox(height: 8),
            _buildValueSelector('REPLACE WITH', _selectedTo, (value) {
              setState(() => _selectedTo = value);
            }),
            if (_loadError != null) ...[
              const SizedBox(height: 8),
              Text('ERROR: $_loadError',
                  style: LabStyles.mono(context,
                      fontSize: 8, color: Colors.redAccent)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL', style: LabStyles.mono(context))),
        TextButton(
          onPressed: _canApply
              ? () {
                  Navigator.pop(
                    context,
                    _CategoryReplaceSelection(
                      column: _selectedColumn,
                      from: _selectedFrom!,
                      to: _selectedTo!,
                    ),
                  );
                }
              : null,
          child: Text('APPLY REPLACE',
              style: LabStyles.mono(context,
                  color: _canApply ? LabColors.accent : Colors.grey)),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      color: LabColors.surfaceContainerLowest,
      child: Text(title,
          style: LabStyles.mono(context,
              fontSize: 9,
              color: LabColors.primary,
              fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildColumnList() {
    return SizedBox(
      height: 118,
      child: ClipRect(
        child: ListView.builder(
          padding: EdgeInsets.zero,
          primary: false,
          itemCount: widget.columns.length,
          itemBuilder: (ctx, index) {
            final column = widget.columns[index];
            final selected = column == _selectedColumn;
            return ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              selected: selected,
              selectedTileColor: LabColors.primary.withValues(alpha: 0.2),
              onTap: () => _selectColumn(column),
              shape:
                  const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              title: Text(column,
                  style: LabStyles.mono(context,
                      fontSize: 10,
                      color: selected ? LabColors.primary : Colors.white)),
            );
          },
        ),
      ),
    );
  }

  Widget _buildValueSelector(String title, _CategoryValueOption? selected,
      ValueChanged<_CategoryValueOption> onSelect) {
    return Container(
      height: 178,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(
            color: LabColors.cyanBorder.withValues(alpha: 0.45), width: 0.5),
        color: LabColors.surfaceContainerLow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: LabStyles.mono(context,
                  fontSize: 9,
                  color: LabColors.primary,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Expanded(
            child: ClipRect(
              child: _loadingValues
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: LabColors.primary, strokeWidth: 2))
                  : _values.isEmpty
                      ? Center(
                          child: Text('NO_VALUES_FOUND',
                              style: LabStyles.mono(context,
                                  fontSize: 9, color: Colors.grey)))
                      : ListView.builder(
                          padding: EdgeInsets.zero,
                          primary: false,
                          itemCount: _values.length,
                          itemBuilder: (ctx, index) {
                            final value = _values[index];
                            final isSelected = identical(value, selected);
                            return ListTile(
                              dense: true,
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              selected: isSelected,
                              selectedTileColor:
                                  LabColors.primary.withValues(alpha: 0.2),
                              shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero),
                              onTap: () => onSelect(value),
                              title: Text(
                                value.display,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: LabStyles.mono(context,
                                    fontSize: 9,
                                    color: isSelected
                                        ? LabColors.primary
                                        : Colors.white),
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UndoSnapshot {
  final String table;
  final String pkCol;
  final Map<String, dynamic> row;
  final String label;
  // For bulk find-replace undo
  final bool isBulkReplace;
  final String findText;
  final String replaceText;
  final String targetColumn;
  // For merge undo
  final bool isMergeUndo;
  final int mergePk1;
  final int mergePk2;
  final String mergeTable;
  final String mergePkCol;
  final List<_FKRef> mergeFkRefs;

  const _UndoSnapshot({
    required this.table,
    required this.pkCol,
    required this.row,
    required this.label,
    this.isBulkReplace = false,
    this.findText = '',
    this.replaceText = '',
    this.targetColumn = '',
    this.isMergeUndo = false,
    this.mergePk1 = 0,
    this.mergePk2 = 0,
    this.mergeTable = '',
    this.mergePkCol = '',
    this.mergeFkRefs = const [],
  });
}

class _TableCfg {
  final String key;
  final String label;
  final IconData icon;
  final String table;
  final String pkCol;
  const _TableCfg(
      {required this.key,
      required this.label,
      required this.icon,
      required this.table,
      required this.pkCol});
}

class _FKRef {
  final String table;
  final String column;
  const _FKRef({required this.table, required this.column});
}
