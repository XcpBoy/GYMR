import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart' hide Column, Table;
import 'package:intl/intl.dart';
import '../providers/database_provider.dart';
import '../providers/theme_provider.dart';
import '../database/database.dart';
import '../localization/strings.dart';
import 'styles.dart';
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
  final Map<String, String> _perTableSearch = {};
  bool _isProcessing = false;
  // Global display toggle — cleans up JSON-blob columns (e.g. body_positions)
  // into a plain comma-joined read, instead of raw ["a","b"] / {"k":"v"}.
  bool _jsonPrettyView = false;

  // ── UNDO SYSTEM ──
  final List<_UndoSnapshot> _undoStack = [];
  static const int _maxUndoDepth = 10;

  bool get _canUndo => _undoStack.isNotEmpty;

  // Current language for `tr(...)` calls. Uses `ref.read` since most callers
  // here are async handlers/dialog builders rather than `build()` itself.
  String get _lang => ref.read(languageProvider).value ?? 'en';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tableConfigs.length, vsync: this);
    _loadPersistedColumnConfig();
    // Pre-cache columns and FK refs for all tables, and kick off a
    // lightweight COUNT(*) per table (cheap — just for the tab row-count
    // badges, not a full page fetch) so every tab shows its size upfront.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final db = ref.read(databaseProvider);
      for (final cfg in _tableConfigs) {
        await _refreshColumns(cfg);
        await _refreshFKRefs(cfg);
        _loadTabBadgeCount(db, cfg);
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
      _searchDebounce?.cancel();
      _searchDebounce = Timer(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        setState(() {
          _perTableSearch[_tableConfigs[_tabCtrl.index].key] = _searchCtrl.text;
        });
      });
    });
  }

  Timer? _searchDebounce;

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    _searchDebounce?.cancel();
    for (final c in _headerScrollControllers.values) {
      c.dispose();
    }
    for (final c in _bodyScrollControllers.values) {
      c.dispose();
    }
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
    // BPS (blueprints) hidden from this UI — the table is live and actively
    // used (workout_manager.dart, WB.editor.dart, export_service.dart), with
    // FK references from blueprint_exercises/plan_days, but not removed
    // from the app.
    // BP-EX (blueprint_exercises) hidden from this UI — the table is live
    // and actively used (WB.editor.dart, workout_manager.dart,
    // ledger_screen.dart), but its inspector tab was showing NO_DATA_FOUND;
    // pending investigation, not removed from the app.
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
              content: Text('${tr(_lang, 'UNDO')}: ${snap.label}',
                  style: LabStyles.mono(context))),
        );
        setState(() {});
      }
    } catch (e) {
      debugPrint('DB.EDIT ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${tr(_lang, 'UNDO ERROR')}: $e',
                  style: LabStyles.mono(context)),
              backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // ── DATE FORMATTING ──
  String _formatValue(dynamic val, String col, {bool jsonPretty = false}) {
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
    if (jsonPretty && val is String) {
      final trimmed = val.trim();
      if (trimmed.startsWith('[') || trimmed.startsWith('{')) {
        try {
          final decoded = jsonDecode(trimmed);
          if (decoded is List) {
            if (decoded.isEmpty) return '—';
            // Common app shape: [{"v": "TUCK", "s": true}, ...] — "v" is the
            // actual display value, other keys (like "s") are metadata for
            // the editing UI, not something worth reading here.
            return decoded.map((e) {
              if (e is Map && e.containsKey('v')) return e['v'].toString();
              if (e is Map && e.containsKey('name')) {
                return e['name'].toString();
              }
              return e.toString();
            }).join(', ');
          }
          if (decoded is Map) {
            if (decoded.isEmpty) return '—';
            if (decoded.containsKey('v')) return decoded['v'].toString();
            return decoded.entries.map((e) => '${e.key}: ${e.value}').join(', ');
          }
        } catch (_) {
          // Not actually valid JSON — fall through to raw string.
        }
      }
    }
    return val.toString();
  }

  // ── DOUBLE CONFIRM DIALOG ──
  Future<bool> _confirmAction(String title, String details,
      {String? sanityResult}) async {
    // First confirm
    final c1 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LabColors.surfaceContainerHigh,
        title: Text('${tr(_lang, 'CONFIRM')}: $title',
            style: LabStyles.mono(context,
                color: LabColors.accent, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Text(details, style: LabStyles.mono(context, fontSize: 10)),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr(_lang, 'CANCEL'), style: LabStyles.mono(context))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(tr(_lang, 'PROCEED'),
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
        title: Text(tr(_lang, 'CONFIRM AGAIN'),
            style: LabStyles.mono(context,
                color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr(_lang, 'This action will modify the database.'),
                  style: LabStyles.mono(context, fontSize: 10)),
              if (sanityResult != null) ...[
                const SizedBox(height: 12),
                Text(sanityResult,
                    style: LabStyles.mono(context,
                        fontSize: 8, color: Colors.grey)),
              ],
              const SizedBox(height: 12),
              Text(tr(_lang, 'Type CONFIRM to proceed:'),
                  style: LabStyles.mono(context,
                      fontSize: 10, color: LabColors.accent)),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr(_lang, 'ABORT'),
                  style: LabStyles.mono(context, color: Colors.redAccent))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(tr(_lang, 'CONFIRM'),
                  style: LabStyles.mono(context, color: LabColors.primary))),
        ],
      ),
    );
    return c2 == true;
  }

  /// Text/varchar-affinity columns for a table (via PRAGMA type info) — used
  /// to scope an "all columns" find & replace to columns that actually make
  /// sense to substring-replace (skips ids/numeric/bool columns).
  Future<List<String>> _textColumnsOf(String table) async {
    final db = ref.read(databaseProvider);
    final rows = await db.customSelect('PRAGMA table_info($table)').get();
    return [
      for (final r in rows)
        if ((r.data['type'] as String? ?? '').toUpperCase().contains('TEXT') ||
            (r.data['type'] as String? ?? '').toUpperCase().contains('CHAR'))
          r.data['name'] as String
    ];
  }

  // ── BATCH OPERATIONS ──
  Future<void> _batchFindAndReplace(_TableCfg cfg) async {
    final findCtrl = TextEditingController();
    final replaceCtrl = TextEditingController();
    final visibleCols = _getColumns(cfg).where((c) => c != cfg.pkCol).toList();
    String? selectedColumn =
        visibleCols.contains('name') ? 'name' : visibleCols.firstOrNull;
    bool allColumns = false;
    bool wholeWord = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          backgroundColor: LabColors.surfaceContainerHigh,
          title: Text('${tr(_lang, 'FIND & REPLACE')} — ${cfg.label}',
              style: LabStyles.mono(context, color: LabColors.accent)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => setDState(() => allColumns = !allColumns),
                  child: Row(
                    children: [
                      Icon(
                          allColumns
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          color:
                              allColumns ? LabColors.accent : Colors.grey[600],
                          size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(tr(_lang, 'APPLY TO ALL TEXT COLUMNS'),
                            style: LabStyles.mono(context,
                                fontSize: 10, color: Colors.white)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (!allColumns) ...[
                  DropdownButtonFormField<String>(
                    value: selectedColumn,
                    dropdownColor: LabColors.surfaceContainerHigh,
                    style: LabStyles.mono(context,
                        fontSize: 12, color: Colors.white),
                    decoration: _inputDecoration(tr(_lang, 'Column')),
                    items: visibleCols
                        .map((c) =>
                            DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setDState(() => selectedColumn = v),
                  ),
                  const SizedBox(height: 8),
                ],
                TextField(
                    controller: findCtrl,
                    decoration: _inputDecoration(tr(_lang, 'Find text')),
                    style: LabStyles.mono(context, fontSize: 12)),
                const SizedBox(height: 8),
                TextField(
                    controller: replaceCtrl,
                    decoration: _inputDecoration(tr(_lang, 'Replace with')),
                    style: LabStyles.mono(context, fontSize: 12)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => setDState(() => wholeWord = !wholeWord),
                  child: Row(
                    children: [
                      Icon(
                          wholeWord
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          color: wholeWord ? LabColors.accent : Colors.grey[600],
                          size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                            tr(_lang,
                                'WHOLE WORD ONLY (unchecked: "FL" also matches inside "FLOATING")'),
                            style: LabStyles.mono(context,
                                fontSize: 9, color: Colors.grey[400])),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(tr(_lang, 'CANCEL'), style: LabStyles.mono(context))),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(tr(_lang, 'REPLACE ALL'),
                    style: LabStyles.mono(context, color: LabColors.accent))),
          ],
        ),
      ),
    );

    if (confirmed != true || findCtrl.text.isEmpty) return;
    if (!allColumns && selectedColumn == null) return;

    final targetColumns =
        allColumns ? await _textColumnsOf(cfg.table) : [selectedColumn!];
    if (targetColumns.isEmpty) return;

    final details = allColumns
        ? 'Columns: ALL TEXT COLUMNS (${targetColumns.join(", ")})\nFind: "${findCtrl.text}"\nReplace: "${replaceCtrl.text}"\nWhole word only: $wholeWord\nTable: ${cfg.table}'
        : 'Column: $selectedColumn\nFind: "${findCtrl.text}"\nReplace: "${replaceCtrl.text}"\nWhole word only: $wholeWord\nTable: ${cfg.table}';
    final ok = await _confirmAction('REPLACE ALL', details);
    if (!ok) return;

    final db = ref.read(databaseProvider);
    final wordRegex = wholeWord
        ? RegExp(r'\b' + RegExp.escape(findCtrl.text) + r'\b')
        : null;
    setState(() => _isProcessing = true);
    try {
      for (final column in targetColumns) {
        // Push undo: backup all matching rows before replacement (one
        // snapshot per column, so undo can revert each independently).
        final matchingRows = await db
            .customSelect(
              'SELECT * FROM ${cfg.table} WHERE $column LIKE ?',
              variables:
                  ['%${findCtrl.text}%'].map((e) => Variable(e)).toList(),
            )
            .get();
        if (matchingRows.isEmpty) continue;

        if (wordRegex != null) {
          // Whole-word mode: SQL REPLACE() can't do word boundaries, so
          // compute + write the new value per row instead of one blanket
          // UPDATE ... REPLACE() statement.
          final changedSnapshots = <Map<String, dynamic>>[];
          for (final r in matchingRows) {
            final current = r.data[column];
            if (current is! String || !wordRegex.hasMatch(current)) continue;
            final snapshot = <String, dynamic>{};
            for (final k in r.data.keys) {
              snapshot[k] = r.data[k];
            }
            changedSnapshots.add(snapshot);
            final newValue = current.replaceAll(wordRegex, replaceCtrl.text);
            final pk = r.data[cfg.pkCol];
            await db.customStatement(
              'UPDATE ${cfg.table} SET $column = ? WHERE ${cfg.pkCol} = ?',
              [newValue, pk],
            );
          }
          if (changedSnapshots.isEmpty) continue;
          _pushUndo(_UndoSnapshot(
            table: cfg.table,
            pkCol: cfg.pkCol,
            row: {'_bulk': true, 'rows': changedSnapshots, 'col': column}
                as Map<String, dynamic>,
            label:
                'Replace "${findCtrl.text}" -> "${replaceCtrl.text}" (whole word) in ${cfg.table}.$column (${changedSnapshots.length} rows)',
            isBulkReplace: true,
            findText: findCtrl.text,
            replaceText: replaceCtrl.text,
            targetColumn: column,
          ));
          continue;
        }

        final snapshotRows = matchingRows.map((r) {
          final map = <String, dynamic>{};
          for (final k in r.data.keys) {
            map[k] = r.data[k];
          }
          return map;
        }).toList();

        _pushUndo(_UndoSnapshot(
          table: cfg.table,
          pkCol: cfg.pkCol,
          row: {'_bulk': true, 'rows': snapshotRows, 'col': column}
              as Map<String, dynamic>,
          label:
              'Replace "${findCtrl.text}" -> "${replaceCtrl.text}" in ${cfg.table}.$column (${snapshotRows.length} rows)',
          isBulkReplace: true,
          findText: findCtrl.text,
          replaceText: replaceCtrl.text,
          targetColumn: column,
        ));

        await db.customStatement(
          'UPDATE ${cfg.table} SET $column = REPLACE($column, ?, ?)',
          [findCtrl.text, replaceCtrl.text],
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(tr(_lang, 'REPLACE COMPLETE'), style: LabStyles.mono(context)),
        ));
      }
    } catch (e) {
      debugPrint('DB.EDIT ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${tr(_lang, 'ERROR')}: $e', style: LabStyles.mono(context)),
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
        lang: _lang,
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

    final details = '${tr(_lang, 'Table')}: ${cfg.table}\n'
        '${tr(_lang, 'Column')}: $column\n'
        '${tr(_lang, 'TO REPLACE')}: ${from.display}\n'
        '${tr(_lang, 'REPLACE WITH')}: ${to.display}\n'
        '${tr(_lang, 'AFFECTED ROWS')}: ${snapshotRows.length}';

    final ok = await _confirmAction(tr(_lang, 'CATEGORY REPLACE'), details);
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
                  '${tr(_lang, 'CATEGORY REPLACE COMPLETE')}: ${snapshotRows.length} ${tr(_lang, 'rows')}',
                  style: LabStyles.mono(context))),
        );
        setState(() {});
      }
    } catch (e) {
      debugPrint('DB.EDIT ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${tr(_lang, 'ERROR')}: $e', style: LabStyles.mono(context)),
          backgroundColor: Colors.redAccent,
        ));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  /// Normalizes whitespace/casing on a single column's value per row — never
  /// merges or deletes rows, unlike the removed AUTO-MERGE NAMES feature.
  Future<void> _normalizeColumn(_TableCfg cfg) async {
    final visibleCols = _getColumns(cfg).where((c) => c != cfg.pkCol).toList();
    if (visibleCols.isEmpty) return;
    String? selectedColumn =
        visibleCols.contains('name') ? 'name' : visibleCols.firstOrNull;
    bool uppercase = true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          backgroundColor: LabColors.surfaceContainerHigh,
          title: Text('${tr(_lang, 'NORMALIZE COLUMN')} — ${cfg.label}',
              style: LabStyles.mono(context, color: LabColors.accent)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedColumn,
                  dropdownColor: LabColors.surfaceContainerHigh,
                  style: LabStyles.mono(context,
                      fontSize: 12, color: Colors.white),
                  decoration: _inputDecoration(tr(_lang, 'Column')),
                  items: visibleCols
                      .map((c) =>
                          DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setDState(() => selectedColumn = v),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => setDState(() => uppercase = !uppercase),
                  child: Row(
                    children: [
                      Icon(
                          uppercase
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          color: uppercase ? LabColors.accent : Colors.grey[600],
                          size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(tr(_lang, 'UPPERCASE'),
                            style: LabStyles.mono(context,
                                fontSize: 10, color: Colors.white)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                    tr(_lang,
                        'Trims/collapses whitespace on the selected column only. '
                        'Never merges or deletes rows — two different exercises '
                        'stay two rows.'),
                    style: LabStyles.mono(context,
                        fontSize: 9, color: Colors.grey[400])),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(tr(_lang, 'CANCEL'), style: LabStyles.mono(context))),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(tr(_lang, 'PREVIEW'),
                    style: LabStyles.mono(context, color: LabColors.accent))),
          ],
        ),
      ),
    );

    if (confirmed != true || selectedColumn == null) return;
    final column = selectedColumn!;

    String normalize(String s) {
      var out = s.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (uppercase) out = out.toUpperCase();
      return out;
    }

    final db = ref.read(databaseProvider);
    final qTable = _quoteIdent(cfg.table);
    final qColumn = _quoteIdent(column);
    final allRows =
        await db.customSelect('SELECT * FROM $qTable').get();

    final changes = <({dynamic pk, String oldVal, String newVal, Map<String, dynamic> snapshot})>[];
    for (final r in allRows) {
      final current = r.data[column];
      if (current is! String) continue;
      final newVal = normalize(current);
      if (newVal == current) continue;
      final snapshot = <String, dynamic>{};
      for (final k in r.data.keys) {
        snapshot[k] = r.data[k];
      }
      changes.add((
        pk: r.data[cfg.pkCol],
        oldVal: current,
        newVal: newVal,
        snapshot: snapshot,
      ));
    }

    if (changes.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('NO_CHANGES_NEEDED', style: LabStyles.mono(context)),
        ));
      }
      return;
    }

    final previewLines = changes
        .take(20)
        .map((c) => '"${c.oldVal}" -> "${c.newVal}"')
        .join('\n');
    final details = '${tr(_lang, 'Table')}: ${cfg.table}\n'
        '${tr(_lang, 'Column')}: $column\n'
        '${tr(_lang, 'AFFECTED ROWS')}: ${changes.length}\n\n'
        '$previewLines'
        '${changes.length > 20 ? '\n… ${tr(_lang, 'and')} ${changes.length - 20} ${tr(_lang, 'more')}' : ''}';

    final ok = await _confirmAction(tr(_lang, 'NORMALIZE COLUMN'), details);
    if (!ok) return;

    final snapshotRows = changes.map((c) => c.snapshot).toList();
    _pushUndo(_UndoSnapshot(
      table: cfg.table,
      pkCol: cfg.pkCol,
      row: {'_bulk': true, 'rows': snapshotRows, 'col': column}
          as Map<String, dynamic>,
      label: 'Normalize ${cfg.table}.$column (${changes.length} rows)',
      isBulkReplace: true,
      findText: '(whitespace/case normalize)',
      replaceText: '(whitespace/case normalize)',
      targetColumn: column,
    ));

    setState(() => _isProcessing = true);
    try {
      for (final c in changes) {
        await db.customStatement(
          'UPDATE $qTable SET $qColumn = ? WHERE ${cfg.pkCol} = ?',
          [c.newVal, c.pk],
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              '${tr(_lang, 'NORMALIZE COMPLETE')}: ${changes.length} ${tr(_lang, 'rows')}',
              style: LabStyles.mono(context)),
        ));
        setState(() {});
      }
    } catch (e) {
      debugPrint('DB.EDIT ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${tr(_lang, 'ERROR')}: $e', style: LabStyles.mono(context)),
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
      tr(_lang, 'REPAIR COLUMN TYPES'),
      '${tr(_lang, 'This will fix all columns in')} ${cfg.table} '
          '${tr(_lang, 'that have wrong SQL types.')}'
          '\n\n${tr(_lang, 'Required after a buggy REINDEX changed REAL/INTEGER columns to TEXT.')}',
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
                  content: Text(
                      '${tr(_lang, 'REPAIR')}: ${tr(_lang, 'Fixed table schema (types + defaults)')}',
                      style: LabStyles.mono(context))),
            );
            setState(() {});
          }
        } catch (e) {
          debugPrint('DB.EDIT ERROR: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('${tr(_lang, 'REPAIR ERROR')}: $e',
                      style: LabStyles.mono(context)),
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

      final ok2 = await _confirmAction(tr(_lang, 'REPAIR TYPES'),
          '${tr(_lang, 'Fixing')} ${fixes.length} ${tr(_lang, 'columns in')} ${cfg.table}:\n$details');
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
              'UPDATE ${cfg.table} SET timestamp = CAST(strftime("%s", "now") * 1000 AS INTEGER) WHERE timestamp IS NULL');
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
                  '${tr(_lang, 'REPAIR COMPLETE')}: ${fixes.length} ${tr(_lang, 'columns fixed in')} ${cfg.table}',
                  style: LabStyles.mono(context))),
        );
        setState(() {});
      }
    } catch (e) {
      debugPrint('DB.EDIT ERROR: $e');
      // DB connection might be in bad state on error, try any available db
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${tr(_lang, 'REPAIR ERROR')}: $e',
                  style: LabStyles.mono(context)),
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
      tr(_lang, 'REINDEX ROWS'),
      '${tr(_lang, 'This will reassign sequential IDs (1,2,3...) to all rows in')} ${cfg.table}.'
          '\\n\\n${tr(_lang, 'All FK references in other tables will be updated.')}'
          '\\n\\n${tr(_lang, 'This operation is IRREVERSIBLE.')}',
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
                content: Text(
                    '${tr(_lang, 'REINDEX')}: ${tr(_lang, 'Already sequential, no changes needed')}',
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

        // Build the new table under a throwaway name and RENAME it into
        // place at the end, instead of renaming the original away first.
        // SQLite auto-rewrites other tables' FK reference text whenever the
        // table THEY reference gets renamed - the old version of this method
        // renamed the original away (`base_exercises` -> `_reindex_tmp_
        // base_exercises`), which correctly triggered that rewrite, then
        // created a brand-new `base_exercises` table that SQLite has no way
        // of knowing is a "continuation" of the renamed-away one. Every
        // other table's FK text was left pointing at the temp name forever,
        // silently, since SQLite doesn't validate a FK's target table
        // exists until something with foreign_keys=ON actually touches it
        // - which is exactly what surfaced this as `no such table:
        // main._reindex_tmp_base_exercises` the next time a real delete
        // ran with FK checks on. Building under a temp name and renaming
        // INTO the original name instead means the original table is only
        // ever dropped, never renamed away, so no other table's FK text is
        // ever touched by this operation.
        final tmpName = '_reindex_new_${cfg.table}';

        // 1. Recreate table (throwaway name) with same schema using drift
        // (We reconstruct via raw SQL since we have the column names)
        final nonIdCols = cols.where((c) => c != 'id').toList();
        final colDefs = <String>[];
        if (rows.isNotEmpty) {
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
            'CREATE TABLE $tmpName (${createColsWithDefaults.join(', ')})');

        // 2. Insert rows with new sequential IDs
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
            'INSERT INTO $tmpName (id, ${nonIdCols.join(', ')}) VALUES (${placeholders.join(', ')})',
            values,
          );
        }

        // 3. Update FK VALUES (not the constraint text) in other tables
        for (final fk in fkRefs) {
          for (final entry in idMap.entries) {
            await db.customStatement(
              'UPDATE ${fk.table} SET ${fk.column} = ? WHERE ${fk.column} = ?',
              [entry.value, entry.key],
            );
          }
        }

        // 4. Fix NULL values in columns that Drift expects as non-nullable
        // (is_pr_song, is_pr, is_completed, order_index, timestamp)
        await db.customStatement(
            'UPDATE $tmpName SET is_pr_song = 0 WHERE is_pr_song IS NULL');
        await db.customStatement(
            'UPDATE $tmpName SET is_pr = 0 WHERE is_pr IS NULL');
        await db.customStatement(
            'UPDATE $tmpName SET is_completed = 0 WHERE is_completed IS NULL');
        await db.customStatement(
            'UPDATE $tmpName SET order_index = 0 WHERE order_index IS NULL');
        try {
          await db.customStatement(
              'UPDATE $tmpName SET timestamp = CAST(strftime("%s", "now") * 1000 AS INTEGER) WHERE timestamp IS NULL');
        } catch (_) {
          // Fallback: set to current unix time in ms
          final now = DateTime.now().millisecondsSinceEpoch;
          await db.customStatement(
              'UPDATE $tmpName SET timestamp = ? WHERE timestamp IS NULL',
              [now]);
        }

        // 5. Drop the original table, then rename the rebuilt one into
        // place - the original name is never renamed away, so other
        // tables' FK reference text never needs touching.
        await db.customStatement('DROP TABLE ${cfg.table}');
        await db.customStatement('ALTER TABLE $tmpName RENAME TO ${cfg.table}');

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
                  '${tr(_lang, 'REINDEX COMPLETE')}: ${rows.length} ${tr(_lang, 'rows')}, ${idMap.length} ${tr(_lang, 'IDs remapped')}',
                  style: LabStyles.mono(context))),
        );
        // Force refresh
        _columnsCache.remove(cfg.table);
        _totalCounts[cfg.key] = 0;
        _pageOffsets[cfg.key] = 0;
        setState(() {});
      }
    } catch (e) {
      debugPrint('DB.EDIT ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${tr(_lang, 'REINDEX ERROR')}: $e',
                  style: LabStyles.mono(context)),
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
        title: Text(' ${tr(_lang, 'MERGE ROWS')} — ${cfg.label}',
            style: LabStyles.mono(context, color: LabColors.accent)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(tr(_lang, 'PK to KEEP (survives):'),
                style:
                    LabStyles.mono(context, fontSize: 9, color: Colors.grey)),
            TextField(
                controller: pk1Ctrl,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration(tr(_lang, 'PK 1 (keep)')),
                style: LabStyles.mono(context, fontSize: 12)),
            const SizedBox(height: 12),
            Text(tr(_lang, 'PK to DELETE (merge into PK 1):'),
                style:
                    LabStyles.mono(context, fontSize: 9, color: Colors.grey)),
            TextField(
                controller: pk2Ctrl,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration(tr(_lang, 'PK 2 (delete)')),
                style: LabStyles.mono(context, fontSize: 12)),
            const SizedBox(height: 8),
            Text(
                tr(_lang,
                    'All FK references to PK 2 will be updated to point to PK 1.'),
                style: LabStyles.mono(context,
                    fontSize: 8, color: Colors.orangeAccent)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr(_lang, 'CANCEL'), style: LabStyles.mono(context))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(tr(_lang, 'MERGE'),
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
                  '${tr(_lang, 'MERGED')}: PK $pk2 → PK $pk1 (${fks.length} ${tr(_lang, 'FK tables updated')})',
                  style: LabStyles.mono(context))),
        );
      }
    } catch (e) {
      debugPrint('DB.EDIT ERROR: $e');
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${tr(_lang, 'MERGE ERROR')}: $e',
                style: LabStyles.mono(context)),
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
    final lang = ref.watch(languageProvider).value ?? 'en';
    return MainScaffold(
      title: tr(lang, 'DB.EDIT'),
      screenKey: 'DATASET',
      automaticallyImplyLeading: false,
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
                        hintText: 'FILTER_THIS_TABLE...',
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
                // Undo history — shows the last few actions (most recent
                // first). Only the top entry is actually undoable (undo is
                // strictly LIFO); older entries are shown greyed-out so you
                // can see what's queued without implying you can jump to it.
                PopupMenuButton<int>(
                  enabled: _canUndo,
                  icon: Icon(Icons.undo,
                      size: 16,
                      color: _canUndo ? LabColors.accent : Colors.grey[800]),
                  tooltip:
                      _canUndo ? tr(_lang, 'UNDO HISTORY') : 'NO_UNDO_HISTORY',
                  color: LabColors.surfaceContainerHigh,
                  itemBuilder: (ctx) {
                    final recent = _undoStack.reversed.take(5).toList();
                    return [
                      for (int i = 0; i < recent.length; i++)
                        PopupMenuItem(
                          value: i,
                          enabled: i == 0,
                          child: Text(
                              i == 0
                                  ? '${tr(_lang, 'UNDO')}: ${recent[i].label}'
                                  : '${i + 1}. ${recent[i].label}',
                              style: LabStyles.mono(context,
                                  fontSize: 10,
                                  color: i == 0
                                      ? LabColors.accent
                                      : Colors.grey[600])),
                        ),
                    ];
                  },
                  onSelected: (i) async {
                    if (i != 0) return;
                    final snap = _undoStack.last;
                    final ok = await _confirmAction(
                        tr(_lang, 'UNDO'), '${tr(_lang, 'Revert')}: ${snap.label}');
                    if (ok) await _undoLast();
                  },
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 4),
                // Batch ops menu
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: LabColors.primary),
                  color: LabColors.surfaceContainerHigh,
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      enabled: false,
                      height: 24,
                      child: Text(tr(_lang, 'VIEW'),
                          style: LabStyles.mono(context,
                              fontSize: 8,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold)),
                    ),
                    _batchMenuItem('config', Icons.tune,
                        tr(_lang, 'VIEW CONFIG'), LabColors.primary),
                    const PopupMenuDivider(height: 12),
                    PopupMenuItem(
                      enabled: false,
                      height: 24,
                      child: Text(tr(_lang, 'EDIT'),
                          style: LabStyles.mono(context,
                              fontSize: 8,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold)),
                    ),
                    _batchMenuItem('findReplace', Icons.find_replace,
                        tr(_lang, 'FIND & REPLACE ALL'), LabColors.accent),
                    _batchMenuItem('categoryReplace', Icons.swap_horiz,
                        tr(_lang, 'CATEGORY REPLACE'), LabColors.accent),
                    _batchMenuItem('normalize', Icons.spellcheck,
                        tr(_lang, 'NORMALIZE COLUMN'), LabColors.accent),
                    const PopupMenuDivider(height: 12),
                    PopupMenuItem(
                      enabled: false,
                      height: 24,
                      child: Text(tr(_lang, 'DESTRUCTIVE'),
                          style: LabStyles.mono(context,
                              fontSize: 8,
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold)),
                    ),
                    _batchMenuItem('merge', Icons.call_merge,
                        tr(_lang, 'MERGE ROWS'), Colors.redAccent),
                    _batchMenuItem('reindex', Icons.format_list_numbered,
                        tr(_lang, 'REINDEX ROWS'), Colors.redAccent),
                    _batchMenuItem('repairTypes', Icons.build_circle,
                        tr(_lang, 'REPAIR COLUMN TYPES'), Colors.redAccent),
                  ],
                  onSelected: (v) {
                    final cfg = _tableConfigs[_tabCtrl.index];
                    if (v == 'findReplace') _batchFindAndReplace(cfg);
                    if (v == 'categoryReplace') _showCategoryReplaceDialog(cfg);
                    if (v == 'normalize') _normalizeColumn(cfg);
                    if (v == 'merge') _mergeRows(cfg);
                    if (v == 'reindex') _reindexRows(cfg);
                    if (v == 'repairTypes') _repairColumnTypes(cfg);
                    if (v == 'config') _showConfigDialog(cfg);
                  },
                ),
              ],
            ),
          ),
          // ── Tabs ──
          TabBar(
            controller: _tabCtrl,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            padding: EdgeInsets.zero,
            indicatorColor: LabColors.accent,
            labelColor: LabColors.accent,
            unselectedLabelColor: Colors.grey,
            labelStyle: LabStyles.mono(context,
                fontSize: 8, fontWeight: FontWeight.bold),
            tabs: _tableConfigs.map((t) {
              final count = _tabRowCounts[t.key];
              return Tab(
                icon: Icon(t.icon, size: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(t.label),
                    if (count != null) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: LabColors.surfaceContainerHigh,
                        ),
                        child: Text('$count',
                            style: LabStyles.mono(context,
                                fontSize: 7, color: Colors.grey[400])),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
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
  // Custom column order per table, persisted the same way as hidden columns.
  final _userColumnOrder = <String, List<String>>{};
  Set<String> _hiddenFor(String key) => _userHiddenColumns.containsKey(key)
      ? _userHiddenColumns[key]!
      : (_defaultHiddenColumns[key] ?? {});

  List<String> _orderedColumns(String key, List<String> allCols) {
    final custom = _userColumnOrder[key];
    if (custom == null) return allCols;
    final ordered = <String>[
      for (final c in custom)
        if (allCols.contains(c)) c
    ];
    for (final c in allCols) {
      if (!ordered.contains(c)) ordered.add(c);
    }
    return ordered;
  }

  // ── Column config persistence (theme_settings table, same mechanism used
  // app-wide for booleans/colors — no new table needed) ──
  Future<void> _loadPersistedColumnConfig() async {
    final db = ref.read(databaseProvider);
    final rows = await (db.select(db.themeSettings)
          ..where((t) => t.key.like('DBINSPECTOR_%')))
        .get();
    for (final row in rows) {
      final value = row.value;
      if (value == null) continue;
      if (row.key.startsWith('DBINSPECTOR_HIDDEN_')) {
        final tableKey = row.key.substring('DBINSPECTOR_HIDDEN_'.length);
        try {
          _userHiddenColumns[tableKey] =
              Set<String>.from((jsonDecode(value) as List).cast<String>());
        } catch (_) {}
      } else if (row.key.startsWith('DBINSPECTOR_ORDER_')) {
        final tableKey = row.key.substring('DBINSPECTOR_ORDER_'.length);
        try {
          _userColumnOrder[tableKey] =
              (jsonDecode(value) as List).cast<String>();
        } catch (_) {}
      } else if (row.key == 'DBINSPECTOR_JSON_PRETTY') {
        _jsonPrettyView = value == '1' || value.toLowerCase() == 'true';
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _persistColumnConfig(
      String tableKey, Set<String> hidden, List<String> order) async {
    final tC = ref.read(themeControllerProvider);
    await tC.setValue(
        'DBINSPECTOR_HIDDEN_$tableKey', jsonEncode(hidden.toList()));
    await tC.setValue('DBINSPECTOR_ORDER_$tableKey', jsonEncode(order));
  }

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
  // Which search term `_totalCounts[key]` currently reflects — lets us
  // detect "search changed" and re-count instead of only counting once.
  final Map<String, String?> _countedForSearch = {};
  // One horizontal ScrollController pair per table — header mirrors body.
  final Map<String, ScrollController> _headerScrollControllers = {};
  final Map<String, ScrollController> _bodyScrollControllers = {};

  // Content-aware column widths for the currently loaded page (not the
  // whole table) — replaces the old flat 100px-per-column layout.
  Map<String, double> _computeColWidths(_TableCfg cfg, List<String> columns,
      List<Map<String, dynamic>> rows) {
    const charWidth = 6.2;
    const minWidth = 64.0;
    const maxWidth = 220.0;
    const hPad = 16.0;
    final widths = <String, double>{};
    for (final col in columns) {
      final label = (_columnLabels[cfg.key]?[col] ?? col).toUpperCase();
      var maxLen = label.length;
      for (final row in rows) {
        final len = _formatValue(row[col], col).length;
        if (len > maxLen) maxLen = len;
      }
      widths[col] = (maxLen * charWidth + hPad).clamp(minWidth, maxWidth);
    }
    return widths;
  }

  int _getOffset(String key) => _pageOffsets[key] ?? 0;
  int _getTotal(String key) => _totalCounts[key] ?? 0;

  int _pageSizeFor(_TableCfg cfg) => _pageSizes[cfg.key] ?? _defaultPageSize;

  Widget _buildTableGrid(_TableCfg cfg) {
    // Only the active tab actually queries/renders — TabBarView still needs
    // a child per tab, but the other 7 no longer fire a fresh DB query on
    // every rebuild (this was the dominant cause of lag: every keystroke in
    // the search field was re-querying all 8 tables, not just the visible
    // one). Safe because `physics: NeverScrollableScrollPhysics` means tabs
    // are only reachable via the TabBar itself, never by swiping past an
    // inactive one.
    if (_tableConfigs[_tabCtrl.index].key != cfg.key) {
      return const SizedBox.shrink();
    }

    final db = ref.watch(databaseProvider);
    final offset = _getOffset(cfg.key);
    final total = _getTotal(cfg.key);
    final searchTerm = (_perTableSearch[cfg.key] ?? '').isEmpty
        ? null
        : _perTableSearch[cfg.key];

    // Re-count whenever the search term changes (not just on first load) —
    // otherwise `total`/`totalPages` keep reflecting the unfiltered table
    // while `_fetchPage` applies the search filter, so paging past the end
    // of the actual filtered results looks like "no data" and snaps back.
    if ((total == 0 || _countedForSearch[cfg.key] != searchTerm) &&
        !(_loadingMore[cfg.key] ?? false)) {
      _loadingMore[cfg.key] = true;
      _countedForSearch[cfg.key] = searchTerm;
      _loadCount(db, cfg, search: searchTerm);
    }

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
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.first_page, size: 16),
                    color: offset > 0 ? LabColors.primary : Colors.grey[800],
                    onPressed: offset > 0
                        ? () => setState(() => _pageOffsets[cfg.key] = 0)
                        : null,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 22, minHeight: 28),
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
                        const BoxConstraints(minWidth: 22, minHeight: 28),
                  ),
                  InkWell(
                    onTap: () => _showJumpToPageDialog(cfg, totalPages),
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Text('PG $currentPage/$totalPages',
                          style: LabStyles.mono(context,
                              fontSize: 8,
                              color: LabColors.primary,
                              decoration: TextDecoration.underline)),
                    ),
                  ),
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
                        const BoxConstraints(minWidth: 22, minHeight: 28),
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
                        const BoxConstraints(minWidth: 22, minHeight: 28),
                  ),
                  const SizedBox(width: 2),
                  IconButton(
                    icon: Icon(
                        _jsonPrettyView
                            ? Icons.data_object
                            : Icons.data_object_outlined,
                        size: 16),
                    color: _jsonPrettyView ? LabColors.accent : Colors.grey,
                    tooltip: _jsonPrettyView
                        ? 'JSON_PRETTY_VIEW: ON'
                        : 'JSON_PRETTY_VIEW: OFF',
                    onPressed: () {
                      setState(() => _jsonPrettyView = !_jsonPrettyView);
                      ref
                          .read(themeControllerProvider)
                          .setBool('DBINSPECTOR_JSON_PRETTY', _jsonPrettyView);
                    },
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 22, minHeight: 28),
                  ),
                  const SizedBox(width: 2),
                  IconButton(
                    icon: const Icon(Icons.tune, size: 16),
                    color: LabColors.primary,
                    tooltip: tr(_lang, 'PAGE SIZE / COLUMNS'),
                    onPressed: () => _showConfigDialog(cfg),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 22, minHeight: 28),
                  ),
                ],
              ),
            ),
            // ── Table body: sticky header + independently-scrolling rows,
            // both sharing one horizontal scroll position (the body drives,
            // the header mirrors via a ScrollNotification listener) so
            // columns stay aligned while the header never scrolls away
            // vertically. Column widths are sized to their content (this
            // page only) instead of a flat 100px for everything. ──
            Builder(builder: (context) {
              final colWidths = _computeColWidths(cfg, columns, filtered);
              final totalWidth =
                  colWidths.values.fold(0.0, (a, b) => a + b);
              final headerCtrl = _headerScrollControllers.putIfAbsent(
                  cfg.key, () => ScrollController());
              final bodyCtrl = _bodyScrollControllers.putIfAbsent(
                  cfg.key, () => ScrollController());

              Widget rowCells(Map<String, dynamic>? row) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: columns.map((col) {
                    final width = colWidths[col]!;
                    if (row == null) {
                      // header cell
                      return Container(
                        width: width,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                        child: Text(
                          (_columnLabels[cfg.key]?[col] ?? col).toUpperCase(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: LabStyles.mono(context,
                                  fontSize: 6.5,
                                  color: LabColors.primary,
                                  fontWeight: FontWeight.bold)
                              .copyWith(height: 1.1),
                        ),
                      );
                    }
                    final display =
                        _formatValue(row[col], col, jsonPretty: _jsonPrettyView);
                    final isPK = col == cfg.pkCol;
                    final isMatch = searchTerm != null &&
                        searchTerm.isNotEmpty &&
                        display.toLowerCase().contains(searchTerm.toLowerCase());
                    return Container(
                      width: width,
                      constraints:
                          const BoxConstraints(minHeight: 20, maxHeight: 36),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: isMatch
                          ? BoxDecoration(
                              border: Border.all(
                                  color: LabColors.accent, width: 1.2))
                          : null,
                      child: isPK
                          ? Text(display,
                              style: LabStyles.mono(context,
                                  fontSize: 8, color: LabColors.primary))
                          : InkWell(
                              onTap: () => _editCell(cfg, row, col, display),
                              child: Text(
                                display,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: LabStyles.mono(context, fontSize: 8),
                              ),
                            ),
                    );
                  }).toList(),
                );
              }

              return Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sticky header — mirrors the body's horizontal offset.
                    Container(
                      constraints:
                          const BoxConstraints(minHeight: 24, maxHeight: 40),
                      color: LabColors.primary.withValues(alpha: 0.08),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        controller: headerCtrl,
                        physics: const NeverScrollableScrollPhysics(),
                        child: SizedBox(width: totalWidth, child: rowCells(null)),
                      ),
                    ),
                    Expanded(
                      child: Scrollbar(
                        controller: bodyCtrl,
                        thumbVisibility: true,
                        notificationPredicate: (n) => n.depth == 0,
                        child: NotificationListener<ScrollNotification>(
                          onNotification: (n) {
                            if (n.metrics.axis == Axis.horizontal &&
                                headerCtrl.hasClients) {
                              headerCtrl.jumpTo(n.metrics.pixels);
                            }
                            return false;
                          },
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            controller: bodyCtrl,
                            child: SizedBox(
                              width: totalWidth,
                              child: ListView.builder(
                                itemCount: filtered.length,
                                itemBuilder: (context, i) {
                                  final row = filtered[i];
                                  return Container(
                                    decoration: BoxDecoration(
                                      border: Border(
                                          bottom: BorderSide(
                                              color: LabColors.cyanBorder
                                                  .withValues(alpha: 0.08),
                                              width: 0.5)),
                                    ),
                                    child: rowCells(row),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }

  PopupMenuItem<String> _batchMenuItem(
      String value, IconData icon, String label, Color color) {
    return PopupMenuItem(
      value: value,
      height: 36,
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 10),
          Text(label, style: LabStyles.mono(context, fontSize: 10, color: color)),
        ],
      ),
    );
  }

  Future<void> _showJumpToPageDialog(_TableCfg cfg, int totalPages) async {
    final ctrl = TextEditingController(
        text: ((_getOffset(cfg.key) / _pageSizeFor(cfg)).floor() + 1).toString());
    final target = await showDialog<int>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: LabColors.background,
        title: Text(tr(_lang, 'JUMP TO PAGE'),
            style: LabStyles.mono(context,
                fontSize: 12, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          style: LabStyles.mono(context, color: Colors.white),
          decoration: InputDecoration(
            hintText: '1 - $totalPages',
            hintStyle: LabStyles.mono(context, color: Colors.grey),
            enabledBorder:
                const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
          ),
          onSubmitted: (v) => Navigator.pop(c, int.tryParse(v)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text(tr(_lang, 'CANCEL'),
                style: LabStyles.mono(context, color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, int.tryParse(ctrl.text)),
            child: Text(tr(_lang, 'GO'),
                style: LabStyles.mono(context, color: LabColors.accent)),
          ),
        ],
      ),
    );
    if (target == null) return;
    final page = target.clamp(1, totalPages);
    setState(() => _pageOffsets[cfg.key] = (page - 1) * _pageSizeFor(cfg));
  }

  Future<void> _showConfigDialog(_TableCfg cfg) async {
    final rawCols = _columnsCache[cfg.table] ?? [];
    if (rawCols.isEmpty) return;
    final hidden = _hiddenFor(cfg.key).toSet(); // mutable copy
    final order = _orderedColumns(cfg.key, rawCols).toList(); // mutable copy
    int pageSize = _pageSizes[cfg.key] ?? _defaultPageSize;

    await showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setDState) => AlertDialog(
          backgroundColor: LabColors.background,
          title: Text('${cfg.label} ${tr(_lang, 'CONFIG')}',
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
                      Text(tr(_lang, 'ROWS PER PAGE'),
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            tr(_lang,
                                'VISIBLE COLUMNS  (drag ⋮⋮ to reorder)'),
                            style: LabStyles.mono(context,
                                fontSize: 9,
                                color: Colors.grey[400],
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 320),
                          child: ReorderableListView(
                            shrinkWrap: true,
                            buildDefaultDragHandles: false,
                            onReorder: (oldIndex, newIndex) => setDState(() {
                              if (newIndex > oldIndex) newIndex--;
                              final col = order.removeAt(oldIndex);
                              order.insert(newIndex, col);
                            }),
                            children: [
                              for (final col in order)
                                Padding(
                                  key: ValueKey(col),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 3),
                                  child: Row(children: [
                                    ReorderableDragStartListener(
                                      index: order.indexOf(col),
                                      child: Icon(Icons.drag_indicator,
                                          size: 16, color: Colors.grey[600]),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: InkWell(
                                        onTap: () => setDState(() {
                                          if (hidden.contains(col)) {
                                            hidden.remove(col);
                                          } else {
                                            hidden.add(col);
                                          }
                                        }),
                                        child: Row(children: [
                                          Icon(
                                              hidden.contains(col)
                                                  ? Icons
                                                      .check_box_outline_blank
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
                                    ),
                                  ]),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(c),
                child: Text(tr(_lang, 'CANCEL'),
                    style: LabStyles.mono(context, color: Colors.grey))),
            TextButton(
                onPressed: () async {
                  setState(() {
                    _userHiddenColumns[cfg.key] = hidden;
                    _userColumnOrder[cfg.key] = order;
                    _pageSizes[cfg.key] = pageSize;
                  });
                  await _persistColumnConfig(cfg.key, hidden, order);
                  if (c.mounted) Navigator.pop(c);
                },
                child: Text(tr(_lang, 'APPLY'),
                    style: LabStyles.mono(context, color: LabColors.primary))),
          ],
        ),
      ),
    );
  }

  // Independent from `_totalCounts` (which the pagination bar resets to 0
  // whenever the tab is tapped) — this persists so the tab badge doesn't
  // flicker back to blank every time you switch tabs.
  final Map<String, int> _tabRowCounts = {};

  Future<void> _loadTabBadgeCount(AppDatabase db, _TableCfg cfg) async {
    try {
      final rows =
          await db.executor.runSelect('SELECT COUNT(*) as cnt FROM ${cfg.table}', []);
      if (mounted) {
        setState(() => _tabRowCounts[cfg.key] = rows.first['cnt'] as int);
      }
    } catch (_) {}
  }

  /// Shared WHERE-clause builder for both the paged fetch and the row
  /// count — these must always agree, or `total`/`totalPages` drift out of
  /// sync with what a search filter actually returns (which used to make
  /// "next page" snap back to page 1 once the filtered result set was
  /// smaller than the *unfiltered* total the count query assumed).
  ({String sql, List<dynamic>? args}) _buildWhereClause(
      _TableCfg cfg, String? search) {
    final clauses = <String>[];
    final extraFilter = _extraFilters[cfg.key];
    if (extraFilter != null && extraFilter.isNotEmpty) {
      clauses.add(extraFilter);
    }

    List<dynamic>? args;
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
    return (sql: whereSql, args: args);
  }

  Future<void> _loadCount(AppDatabase db, _TableCfg cfg,
      {String? search}) async {
    try {
      final where = _buildWhereClause(cfg, search);
      final sql = 'SELECT COUNT(*) as cnt FROM ${cfg.table}${where.sql}';
      final rows = (where.args != null && where.args!.isNotEmpty)
          ? await db.customSelect(sql,
              variables: where.args!.map((a) => Variable(a)).toList()).get()
          : await db.customSelect(sql).get();
      final result = rows.first;
      if (mounted) {
        setState(() {
          _totalCounts[cfg.key] = result.data['cnt'] as int;
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
    final where = _buildWhereClause(cfg, search);
    final sql =
        'SELECT * FROM ${cfg.table}${where.sql} ORDER BY id DESC LIMIT ${_pageSizeFor(cfg)} OFFSET $offset';

    final result = (where.args != null && where.args!.isNotEmpty)
        ? await db
            .customSelect(sql,
                variables: where.args!.map((a) => Variable(a)).toList())
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
        title: Text('${tr(_lang, 'EDIT CELL')} — $col',
            style: LabStyles.mono(context, color: LabColors.accent)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                '${tr(_lang, 'Table')}: ${cfg.table}  |  ${tr(_lang, 'PK')}: $pk',
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
              child: Text(tr(_lang, 'CANCEL'), style: LabStyles.mono(context))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text),
              child: Text(tr(_lang, 'SAVE'),
                  style: LabStyles.mono(context, color: LabColors.accent))),
        ],
      ),
    );

    if (newValue == null || newValue == currentValue) return;

    // Double confirm
    final ok = await _confirmAction(
      tr(_lang, 'EDIT CELL'),
      '${tr(_lang, 'Table')}: ${cfg.table}\n${tr(_lang, 'Column')}: $col\n${tr(_lang, 'PK')}: $pk\n\n${tr(_lang, 'From')}: "$currentValue"\n${tr(_lang, 'To')}: "$newValue"',
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
            content: Text(tr(_lang, 'CELL UPDATED'),
                style: LabStyles.mono(context))));
        setState(() {}); // refresh
      }
    } catch (e) {
      debugPrint('DB.EDIT ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${tr(_lang, 'ERROR')}: $e', style: LabStyles.mono(context)),
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
      final allCols = _orderedColumns(cfg.key, _columnsCache[cfg.table]!);
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
  final String lang;

  const _CategoryReplaceDialog({
    required this.cfg,
    required this.columns,
    required this.initialColumn,
    required this.loadValues,
    required this.lang,
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
      debugPrint('DB.EDIT ERROR: $e');
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
      title: Text(
          '${tr(widget.lang, 'CATEGORY REPLACE')} — ${widget.cfg.label}',
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
            _buildSectionHeader(tr(widget.lang, 'COLUMN')),
            const SizedBox(height: 6),
            _buildColumnList(),
            const SizedBox(height: 10),
            _buildValueSelector(
                tr(widget.lang, 'TO REPLACE'), _selectedFrom, (value) {
              setState(() => _selectedFrom = value);
            }),
            const SizedBox(height: 8),
            _buildValueSelector(
                tr(widget.lang, 'REPLACE WITH'), _selectedTo, (value) {
              setState(() => _selectedTo = value);
            }),
            if (_loadError != null) ...[
              const SizedBox(height: 8),
              Text('${tr(widget.lang, 'ERROR')}: $_loadError',
                  style: LabStyles.mono(context,
                      fontSize: 8, color: Colors.redAccent)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr(widget.lang, 'CANCEL'), style: LabStyles.mono(context))),
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
          child: Text(tr(widget.lang, 'APPLY REPLACE'),
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
