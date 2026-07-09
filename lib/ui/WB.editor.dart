import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:async';

import '../providers/database_provider.dart';
import '../providers/theme_provider.dart';
import '../database/database.dart';
import '../logic/calculator.dart';
import 'styles.dart';
import 'lab_widgets.dart';
import 'main_scaffold.dart';
import 'complex_metadata_screen.dart';
import 'exercise_history_screen.dart';
import 'edit_exercise_screen.dart';
import 'wb_shared/wb_shared_widgets.dart';

// ─── MUTABLE WB EDITOR STATE ───────────────────────────────────────
// Self-contained: KNS, UTILS, batches — all in memory, no real DB.

class WbEditorState {
  final List<WbEditorKns> knsEntries;
  final String? blockDescription;
  WbEditorState({required this.knsEntries, this.blockDescription});
}

class WbEditorSet {
  final int id;
  final int setNumber;
  double? minReps;
  double? maxReps;
  double? pload;
  double? rpe;
  double? rir;
  List<String> tags;
  String? intention;
  String? side;
  WbEditorSet(
      {required this.id,
      required this.setNumber,
      this.minReps,
      this.maxReps,
      this.pload,
      this.rpe,
      this.rir,
      this.tags = const [],
      this.intention,
      this.side});

  Map<String, dynamic> toJson() => {
        'id': id,
        'setNumber': setNumber,
        'minReps': minReps,
        'maxReps': maxReps,
        'pload': pload,
        'rpe': rpe,
        'rir': rir,
        'tags': tags,
        'intention': intention,
        'side': side,
      };

  factory WbEditorSet.fromJson(Map<String, dynamic> j) => WbEditorSet(
        id: j['id'] as int,
        setNumber: j['setNumber'] as int,
        minReps: (j['minReps'] as num?)?.toDouble(),
        maxReps: (j['maxReps'] as num?)?.toDouble(),
        pload: (j['pload'] as num?)?.toDouble(),
        rpe: (j['rpe'] as num?)?.toDouble(),
        rir: (j['rir'] as num?)?.toDouble(),
        tags: (j['tags'] as List?)?.cast<String>() ?? [],
        intention: j['intention'] as String?,
        side: j['side'] as String?,
      );
}

class WbEditorKns {
  final int id;
  final int baseExerciseId;
  final String exerciseName;
  final String? intention;
  final bool isUnilateral;
  final String? field;
  final String? primaryMuscleGroup;
  final String? prefixes;
  final String? suffixes;
  final String? bodyPositions;
  final String? implements;
  final int orderIndex;
  final List<String> utilities;
  final String? batchName;
  final List<WbEditorSet> sets;
  WbEditorKns({
    required this.id,
    required this.baseExerciseId,
    required this.exerciseName,
    this.intention,
    this.isUnilateral = false,
    this.field,
    this.primaryMuscleGroup,
    this.prefixes,
    this.suffixes,
    this.bodyPositions,
    this.implements,
    required this.orderIndex,
    this.utilities = const [],
    this.batchName,
    this.sets = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'baseExerciseId': baseExerciseId,
        'exerciseName': exerciseName,
        'intention': intention,
        'isUnilateral': isUnilateral,
        'field': field,
        'primaryMuscleGroup': primaryMuscleGroup,
        'prefixes': prefixes,
        'suffixes': suffixes,
        'bodyPositions': bodyPositions,
        'implements': implements,
        'orderIndex': orderIndex,
        'utilities': utilities,
        'batchName': batchName,
        'sets': sets.map((s) => s.toJson()).toList(),
      };

  static WbEditorKns fromJson(Map<String, dynamic> j) => WbEditorKns(
        id: j['id'] as int,
        baseExerciseId: j['baseExerciseId'] as int,
        exerciseName: j['exerciseName'] as String,
        intention: j['intention'] as String?,
        isUnilateral: j['isUnilateral'] as bool? ?? false,
        field: j['field'] as String?,
        primaryMuscleGroup: j['primaryMuscleGroup'] as String?,
        prefixes: j['prefixes'] as String?,
        suffixes: j['suffixes'] as String?,
        bodyPositions: j['bodyPositions'] as String?,
        implements: j['implements'] as String?,
        orderIndex: j['orderIndex'] as int,
        utilities: (j['utilities'] as List?)?.cast<String>() ?? [],
        batchName: j['batchName'] as String?,
        sets: (j['sets'] as List?)
                ?.map((sj) => WbEditorSet.fromJson(sj as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class WbEditorNotifier extends StateNotifier<WbEditorState> {
  final AppDatabase _db;
  int _blockId;
  bool _tableReady = false;

  WbEditorNotifier(this._db, this._blockId)
      : super(WbEditorState(knsEntries: []));

  Future<void> ensureTable() async {
    if (_tableReady) return;
    // Ensure real tables exist + have all columns (hot-restart safe)
    try {
      await _db.customStatement(
          'ALTER TABLE workout_blocks ADD COLUMN intention TEXT');
    } catch (_) {}
    try {
      await _db.customStatement(
          'ALTER TABLE workout_blocks ADD COLUMN description TEXT');
    } catch (_) {}
    try {
      await _db.customStatement(
          'ALTER TABLE workout_blocks ADD COLUMN deleted_at INTEGER');
    } catch (_) {}
    try {
      await _db.customStatement(
          'ALTER TABLE workout_block_kns ADD COLUMN utilities TEXT');
    } catch (_) {}
    try {
      await _db.customStatement(
          'ALTER TABLE workout_block_kns ADD COLUMN batch_name TEXT');
    } catch (_) {}
    try {
      await _db.customStatement(
          'ALTER TABLE workout_block_kns ADD COLUMN metadata TEXT');
    } catch (_) {}
    try {
      await _db.customStatement(
          'ALTER TABLE workout_block_sets ADD COLUMN reps_min REAL');
    } catch (_) {}
    try {
      await _db.customStatement(
          'ALTER TABLE workout_block_sets ADD COLUMN reps_max REAL');
    } catch (_) {}
    try {
      await _db.customStatement(
          'ALTER TABLE workout_block_sets ADD COLUMN pload REAL');
    } catch (_) {}
    try {
      await _db.customStatement(
          'ALTER TABLE workout_block_sets ADD COLUMN rpe REAL');
    } catch (_) {}
    try {
      await _db.customStatement(
          'ALTER TABLE workout_block_sets ADD COLUMN rir REAL');
    } catch (_) {}
    try {
      await _db.customStatement(
          'ALTER TABLE workout_block_sets ADD COLUMN set_intention TEXT');
    } catch (_) {}
    try {
      await _db.customStatement(
          'ALTER TABLE workout_block_sets ADD COLUMN side TEXT');
    } catch (_) {}
    try {
      await _db.customStatement(
          'ALTER TABLE workout_block_sets ADD COLUMN tags TEXT');
    } catch (_) {}
    try {
      await _db.customStatement(
          'ALTER TABLE workout_block_sets ADD COLUMN metadata TEXT');
    } catch (_) {}
    _tableReady = true;
  }

  Future<void> _save() async {
    try {
      // Ensure workout_blocks row exists for FK integrity
      await _db.customStatement(
          'INSERT OR IGNORE INTO workout_blocks (id, name, created_at, deleted_at) VALUES (?, ?, ?, 0)',
          [_blockId, 'WB $_blockId', DateTime.now().millisecondsSinceEpoch]);
      await _db.customStatement(
          'UPDATE workout_blocks SET deleted_at = 0 WHERE id = ?', [_blockId]);
      // Sync KNS ONLY — NEVER touch workout_block_sets (field values managed by _onChanged → db.update)
      // Delete KNS that no longer exist in state (cascade handles sets)
      final existingIds = state.knsEntries.map((k) => k.id).toList();
      if (existingIds.isNotEmpty) {
        await _db.customStatement(
            'DELETE FROM workout_block_kns WHERE block_id = ${_blockId} AND id NOT IN (${existingIds.join(',')})');
      } else {
        await _db.customStatement(
            'DELETE FROM workout_block_kns WHERE block_id = ${_blockId}');
      }
      // Insert KNS (IGNORE — don't trigger cascade delete on existing sets)
      for (final kns in state.knsEntries) {
        await _db.customStatement(
            'INSERT OR IGNORE INTO workout_block_kns (id, block_id, base_exercise_id, order_index) VALUES (?, ?, ?, ?)',
            [kns.id, _blockId, kns.baseExerciseId, kns.orderIndex]);
        // UPDATE KNS fields separately (IGNORE doesn't update, REPLACE cascades to sets)
        final knsMeta = <String, dynamic>{};
        if (kns.intention != null && kns.intention!.isNotEmpty)
          knsMeta['intention'] = kns.intention;
        await _db.customStatement(
            'UPDATE workout_block_kns SET utilities = ?, batch_name = ?, metadata = ? WHERE id = ?',
            [
              kns.utilities.isNotEmpty ? jsonEncode(kns.utilities) : null,
              kns.batchName,
              knsMeta.isNotEmpty ? jsonEncode(knsMeta) : null,
              kns.id
            ]);
        // Ensure set rows exist (INSERT OR IGNORE — doesn't overwrite field values)
        for (final s in kns.sets) {
          await _db.customStatement(
              'INSERT OR IGNORE INTO workout_block_sets (id, kns_id, set_number, side) VALUES (?, ?, ?, ?)',
              [s.id, kns.id, s.setNumber, s.side]);
          final updatedRows = await _db.executor.runUpdate(
            'UPDATE workout_block_sets SET set_number = ?, reps_min = ?, reps_max = ?, pload = ?, rpe = ?, rir = ?, set_intention = ?, side = ?, tags = ?, metadata = ? WHERE id = ? AND kns_id = ?',
            [
              s.setNumber,
              s.minReps,
              s.maxReps,
              s.pload,
              s.rpe,
              s.rir,
              s.intention,
              s.side,
              jsonEncode(s.tags),
              jsonEncode(<String, dynamic>{}),
              s.id,
              kns.id,
            ],
          );
          if (updatedRows == 0) {
            await _db.customStatement(
              'INSERT INTO workout_block_sets (id, kns_id, set_number, reps_min, reps_max, pload, rpe, rir, set_intention, side, tags, metadata) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
              [
                s.id,
                kns.id,
                s.setNumber,
                s.minReps,
                s.maxReps,
                s.pload,
                s.rpe,
                s.rir,
                s.intention,
                s.side,
                jsonEncode(s.tags),
                jsonEncode(<String, dynamic>{}),
              ],
            );
          }
        }
      }
      debugPrint(
          '[WB_REAL_SAVE] block=$_blockId kns=${state.knsEntries.length}');
    } catch (e) {
      debugPrint('[WB_REAL_SAVE] error: $e');
    }
  }

  Future<void> _load() async {
    try {
      final knsRows = await _db
          .customSelect(
              'SELECT id, base_exercise_id, order_index, utilities, batch_name, metadata FROM workout_block_kns WHERE block_id = ${_blockId} ORDER BY order_index ASC')
          .get();
      final List<WbEditorKns> loaded = [];
      for (final kRow in knsRows) {
        final knsId = kRow.data['id'] as int;
        final baseExId = kRow.data['base_exercise_id'] as int;
        final orderIdx = (kRow.data['order_index'] as num?)?.toInt() ?? 0;
        final utilsRaw = kRow.data['utilities'] as String?;
        final batchName = kRow.data['batch_name'] as String?;
        final metaRaw = kRow.data['metadata'] as String?;
        final List<String> utilities = utilsRaw != null
            ? (jsonDecode(utilsRaw) as List).cast<String>()
            : [];
        // Restore kns intention from metadata
        String? intention;
        if (metaRaw != null) {
          try {
            final m = jsonDecode(metaRaw);
            intention = m['intention'] as String?;
          } catch (_) {}
        }

        // Resolve exercise name (NO intention — KNS purpose is user-written, not exercise metadata)
        String exName = '';
        String? field,
            primaryMuscleGroup,
            prefixes,
            suffixes,
            bodyPositions,
            implements;
        bool isUnilateral = false;
        try {
          final ex = await (_db.select(_db.baseExercises)
                ..where((t) => t.id.equals(baseExId)))
              .getSingleOrNull();
          if (ex != null) {
            exName = ex.name;
            field = ex.field;
            primaryMuscleGroup = ex.primaryMuscleGroup;
            prefixes = ex.prefixes;
            suffixes = ex.suffixes;
            bodyPositions = ex.bodyPositions;
            implements = ex.implements;
            isUnilateral = ex.isUnilateral;
          }
        } catch (_) {}

        // Load sets for this KNS
        final setRows = await _db
            .customSelect(
                'SELECT id, set_number, reps_min, reps_max, pload, rpe, rir, set_intention, side FROM workout_block_sets WHERE kns_id = $knsId ORDER BY set_number ASC')
            .get();
        final sets = setRows.map((sRow) {
          return WbEditorSet(
            id: sRow.data['id'] as int,
            setNumber: (sRow.data['set_number'] as num).toInt(),
            minReps: (sRow.data['reps_min'] as num?)?.toDouble(),
            maxReps: (sRow.data['reps_max'] as num?)?.toDouble(),
            pload: (sRow.data['pload'] as num?)?.toDouble(),
            rpe: (sRow.data['rpe'] as num?)?.toDouble(),
            rir: (sRow.data['rir'] as num?)?.toDouble(),
            intention: sRow.data['set_intention'] as String?,
            side: sRow.data['side'] as String?,
          );
        }).toList();

        loaded.add(WbEditorKns(
          id: knsId,
          baseExerciseId: baseExId,
          exerciseName: exName,
          intention: intention,
          isUnilateral: isUnilateral,
          field: field,
          primaryMuscleGroup: primaryMuscleGroup,
          prefixes: prefixes,
          suffixes: suffixes,
          bodyPositions: bodyPositions,
          implements: implements,
          orderIndex: orderIdx,
          utilities: utilities,
          batchName: batchName,
          sets: sets,
        ));
      }
      state = WbEditorState(knsEntries: loaded);
      debugPrint('[WB_REAL_LOAD] block=$_blockId loaded ${loaded.length} kns');
    } catch (e) {
      debugPrint('[WB_REAL_LOAD] error: $e');
    }
  }

  Future<void> reload({int? blockId}) async {
    if (blockId != null) _blockId = blockId;
    debugPrint('[WB_KNS_RELOAD] block=$_blockId');
    await ensureTable();
    await _load();
  }

  void setBlockDescription(String desc) {
    state = WbEditorState(knsEntries: state.knsEntries, blockDescription: desc);
    _db.customStatement(
      'INSERT OR IGNORE INTO workout_blocks (id, name, description, created_at, deleted_at) VALUES (?, ?, ?, ?, 0)',
      [_blockId, 'WB $_blockId', desc, DateTime.now().millisecondsSinceEpoch],
    );
    _db.customStatement(
      'UPDATE workout_blocks SET description = ?, deleted_at = 0 WHERE id = ?',
      [desc, _blockId],
    );
    _save();
  }

  void setKnsPurpose(int knsId, String purpose) {
    state = WbEditorState(
        blockDescription: state.blockDescription,
        knsEntries: state.knsEntries.map((k) {
          if (k.id != knsId) return k;
          return WbEditorKns(
              id: k.id,
              baseExerciseId: k.baseExerciseId,
              exerciseName: k.exerciseName,
              intention: purpose,
              isUnilateral: k.isUnilateral,
              field: k.field,
              primaryMuscleGroup: k.primaryMuscleGroup,
              prefixes: k.prefixes,
              suffixes: k.suffixes,
              bodyPositions: k.bodyPositions,
              implements: k.implements,
              orderIndex: k.orderIndex,
              utilities: k.utilities,
              batchName: k.batchName,
              sets: k.sets);
        }).toList());
    _save();
  }

  void clearAll() {
    state =
        WbEditorState(knsEntries: [], blockDescription: state.blockDescription);
    _save();
  }

  void addKns(BaseExercise exercise) {
    final newId = DateTime.now().microsecondsSinceEpoch;
    final List<WbEditorSet> defaultSets;
    if (exercise.isUnilateral) {
      defaultSets = [
        WbEditorSet(id: newId + 1, setNumber: 1, side: "RIGHT"),
        WbEditorSet(id: newId + 2, setNumber: 2, side: "LEFT"),
      ];
    } else {
      defaultSets = [WbEditorSet(id: newId + 1, setNumber: 1)];
    }
    state =
        WbEditorState(blockDescription: state.blockDescription, knsEntries: [
      ...state.knsEntries,
      WbEditorKns(
          id: newId,
          baseExerciseId: exercise.id,
          exerciseName: exercise.name,
          intention: null,
          isUnilateral: exercise.isUnilateral,
          field: exercise.field,
          primaryMuscleGroup: exercise.primaryMuscleGroup,
          prefixes: exercise.prefixes,
          suffixes: exercise.suffixes,
          bodyPositions: exercise.bodyPositions,
          implements: exercise.implements,
          orderIndex: state.knsEntries.length,
          sets: defaultSets),
    ]);
    debugPrint(
        '[WB_ADDKNS_DEBUG] knsId=$newId sets=${defaultSets.length} state_sets=${state.knsEntries.last.sets.length}');
    _save();
  }

  Future<void> copyFromSpecificDay(
      Map<int, List<drift.TypedResult>> groupedRows) async {
    if (groupedRows.isEmpty) return;

    var idSeed = DateTime.now().microsecondsSinceEpoch + 1000000000;
    final copiedEntries = <WbEditorKns>[];

    for (final entry in groupedRows.entries) {
      final rows = entry.value;
      if (rows.isEmpty) continue;

      final first = rows.first;
      final ex = first.readTable(_db.baseExercises);
      final sets = <WbEditorSet>[];
      var setNumber = 1;

      for (final row in rows) {
        final sourceSet = row.readTable(_db.workoutSets);
        final meta = _parseMetadata(sourceSet.complexMetadata);
        sets.add(WbEditorSet(
          id: idSeed + setNumber,
          setNumber: setNumber,
          minReps: null,
          maxReps: sourceSet.reps,
          pload: sourceSet.weight,
          rpe: sourceSet.rpe,
          rir: sourceSet.rir,
          tags: _tagsFromMetadata(meta),
          intention: meta['intention'] as String?,
          side: meta['side'] as String?,
        ));
        setNumber++;
      }

      final knsId = idSeed;
      idSeed += 1000000;
      final nextOrder = state.knsEntries.isEmpty
          ? 0
          : state.knsEntries
                  .map((k) => k.orderIndex)
                  .reduce((a, b) => a > b ? a : b) +
              1;

      copiedEntries.add(WbEditorKns(
        id: knsId,
        baseExerciseId: ex.id,
        exerciseName: ex.name,
        intention: null,
        isUnilateral: ex.isUnilateral,
        field: ex.field,
        primaryMuscleGroup: ex.primaryMuscleGroup,
        prefixes: ex.prefixes,
        suffixes: ex.suffixes,
        bodyPositions: ex.bodyPositions,
        implements: ex.implements,
        orderIndex: nextOrder,
        sets: sets,
      ));
    }

    if (copiedEntries.isEmpty) return;

    state = WbEditorState(
      blockDescription: state.blockDescription,
      knsEntries: [...state.knsEntries, ...copiedEntries],
    );
    await _save();
  }

  static Map<String, dynamic> _parseMetadata(String? raw) {
    if (raw == null || raw.isEmpty) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  static List<String> _tagsFromMetadata(Map<String, dynamic> meta) {
    final tags = <String>{};
    final rawTags = meta['tags'];
    if (rawTags is List) {
      tags.addAll(rawTags.whereType<String>());
    }
    final priority = meta['priority'];
    if (priority is String && priority.isNotEmpty) tags.add(priority);
    return tags.toList();
  }

  void setUtilities(int knsId, List<String> utilities) {
    state = WbEditorState(
        blockDescription: state.blockDescription,
        knsEntries: state.knsEntries.map((k) {
          if (k.id != knsId) return k;
          return WbEditorKns(
              id: k.id,
              baseExerciseId: k.baseExerciseId,
              exerciseName: k.exerciseName,
              intention: k.intention,
              isUnilateral: k.isUnilateral,
              field: k.field,
              primaryMuscleGroup: k.primaryMuscleGroup,
              prefixes: k.prefixes,
              suffixes: k.suffixes,
              bodyPositions: k.bodyPositions,
              implements: k.implements,
              orderIndex: k.orderIndex,
              utilities: utilities,
              batchName: k.batchName);
        }).toList());
    _save();
  }

  void setBatch(int knsId, String batchName) {
    state = WbEditorState(
        blockDescription: state.blockDescription,
        knsEntries: state.knsEntries.map((k) {
          if (k.id != knsId) return k;
          return WbEditorKns(
              id: k.id,
              baseExerciseId: k.baseExerciseId,
              exerciseName: k.exerciseName,
              intention: k.intention,
              isUnilateral: k.isUnilateral,
              field: k.field,
              primaryMuscleGroup: k.primaryMuscleGroup,
              prefixes: k.prefixes,
              suffixes: k.suffixes,
              bodyPositions: k.bodyPositions,
              implements: k.implements,
              orderIndex: k.orderIndex,
              utilities: k.utilities,
              batchName: batchName,
              sets: k.sets);
        }).toList());
    _save();
  }

  void removeKns(int knsId) {
    state = WbEditorState(
        blockDescription: state.blockDescription,
        knsEntries: state.knsEntries.where((k) => k.id != knsId).toList());
    _save();
  }

  void addSetToKns(int knsId, WbEditorSet set) {
    state = WbEditorState(
        blockDescription: state.blockDescription,
        knsEntries: state.knsEntries.map((k) {
          if (k.id != knsId) return k;
          return WbEditorKns(
              id: k.id,
              baseExerciseId: k.baseExerciseId,
              exerciseName: k.exerciseName,
              intention: k.intention,
              isUnilateral: k.isUnilateral,
              field: k.field,
              primaryMuscleGroup: k.primaryMuscleGroup,
              prefixes: k.prefixes,
              suffixes: k.suffixes,
              bodyPositions: k.bodyPositions,
              implements: k.implements,
              orderIndex: k.orderIndex,
              utilities: k.utilities,
              batchName: k.batchName,
              sets: [...k.sets, set]);
        }).toList());
    _save();
  }

  void removeSet(int knsId, int setId) {
    state = WbEditorState(
        blockDescription: state.blockDescription,
        knsEntries: state.knsEntries.map((k) {
          if (k.id != knsId) return k;
          return WbEditorKns(
              id: k.id,
              baseExerciseId: k.baseExerciseId,
              exerciseName: k.exerciseName,
              intention: k.intention,
              isUnilateral: k.isUnilateral,
              field: k.field,
              primaryMuscleGroup: k.primaryMuscleGroup,
              prefixes: k.prefixes,
              suffixes: k.suffixes,
              bodyPositions: k.bodyPositions,
              implements: k.implements,
              orderIndex: k.orderIndex,
              utilities: k.utilities,
              batchName: k.batchName,
              sets: k.sets.where((s) => s.id != setId).toList());
        }).toList());
    _save();
  }

  void updateSet(int knsId, int setId,
      {double? minReps,
      double? maxReps,
      double? pload,
      double? rpe,
      double? rir,
      List<String>? tags,
      String? intention}) {
    state = WbEditorState(
        blockDescription: state.blockDescription,
        knsEntries: state.knsEntries.map((k) {
          if (k.id != knsId) return k;
          // Create new sets list with new WbEditorSet objects (immutable-style — no in-place mutation)
          final updatedSets = k.sets.map((s) {
            if (s.id != setId) return s;
            return WbEditorSet(
              id: s.id,
              setNumber: s.setNumber,
              minReps: minReps,
              maxReps: maxReps,
              pload: pload,
              rpe: rpe,
              rir: rir,
              tags: tags ?? s.tags,
              intention: intention,
              side: s.side,
            );
          }).toList();
          return WbEditorKns(
              id: k.id,
              baseExerciseId: k.baseExerciseId,
              exerciseName: k.exerciseName,
              intention: k.intention,
              isUnilateral: k.isUnilateral,
              field: k.field,
              primaryMuscleGroup: k.primaryMuscleGroup,
              prefixes: k.prefixes,
              suffixes: k.suffixes,
              bodyPositions: k.bodyPositions,
              implements: k.implements,
              orderIndex: k.orderIndex,
              utilities: k.utilities,
              batchName: k.batchName,
              sets: updatedSets);
        }).toList());
    // DEBUG: check what toJson actually produces for the first set
    if (state.knsEntries.isNotEmpty && state.knsEntries.first.sets.isNotEmpty) {
      final firstSet = state.knsEntries.first.sets.first;
      debugPrint(
          '[WB_UPDATESET_DEBUG] setId=${firstSet.id} pload_field=${firstSet.pload} json=${jsonEncode(firstSet.toJson())}');
    }
    _save();
  }
}

final wbEditorProvider =
    StateNotifierProvider<WbEditorNotifier, WbEditorState>((ref) {
  final db = ref.read(databaseProvider);
  return WbEditorNotifier(db, 0);
});

final editorBlockIdProvider = StateProvider<int>((ref) => 0);

final knsVersionProvider = StateProvider<int>((ref) => 0);

// ─── SET INTENT DEFINITIONS ──────────────────────────────────────
// User-defined intents with colors, stored in a custom SQLite table.
// Like batch_definitions but for SET INTENT.

class IntentionDef {
  final String name;
  final String color; // hex color string e.g. '#FF5722'
  IntentionDef({required this.name, required this.color});
  Map<String, dynamic> toJson() => {'name': name, 'color': color};
  factory IntentionDef.fromJson(Map<String, dynamic> j) => IntentionDef(
        name: j['name'] as String,
        color: j['color'] as String? ?? '#FF5722',
      );
}

/// Reads all available set intentions from the custom table.
final setIntentionsProvider = FutureProvider<List<IntentionDef>>((ref) async {
  final db = ref.read(databaseProvider);
  await db.customStatement('''
    CREATE TABLE IF NOT EXISTS set_intent_definitions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE,
      color TEXT NOT NULL DEFAULT '#FF5722',
      created_at INTEGER NOT NULL DEFAULT 0
    )
  ''');
  final rows = await db.executor.runSelect(
      'SELECT name, color FROM set_intent_definitions ORDER BY name ASC', []);
  return rows
      .map((r) => IntentionDef(
            name: r['name'] as String,
            color: r['color'] as String? ?? '#FF5722',
          ))
      .toList();
});

/// Adds or removes a set intention definition.
final setIntentionActionsProvider = Provider<SetIntentionActions>((ref) {
  return SetIntentionActions(ref.read(databaseProvider));
});

class SetIntentionActions {
  final AppDatabase _db;
  SetIntentionActions(this._db);

  Future<void> add(String name, String color) async {
    await _db.customStatement(
        "INSERT OR IGNORE INTO set_intent_definitions (name, color, created_at) "
        "VALUES ('${name.replaceAll("'", "''")}', '$color', ${DateTime.now().millisecondsSinceEpoch})");
  }

  Future<void> rename(String oldName, String newName) async {
    final safeOld = oldName.replaceAll("'", "''");
    final safeNew = newName.replaceAll("'", "''");
    await _db.customStatement(
        "INSERT OR IGNORE INTO set_intent_definitions (name, color, created_at) "
        "VALUES ('$safeNew', '#FF5722', ${DateTime.now().millisecondsSinceEpoch})");
    await _db.customStatement(
        "DELETE FROM set_intent_definitions WHERE name = '$safeOld'");
    // Update all sets that reference the old name
    final affected = await _db.executor.runSelect(
        "SELECT id, complex_metadata FROM workout_sets WHERE complex_metadata LIKE '%\"intention\":\"$safeOld\"%'",
        []);
    for (final row in affected) {
      final sid = row['id'] as int;
      final cm = row['complex_metadata'] as String?;
      if (cm == null) continue;
      try {
        final meta = jsonDecode(cm) as Map<String, dynamic>;
        if (meta['intention'] == oldName) {
          meta['intention'] = newName;
          await (_db.update(_db.workoutSets)..where((t) => t.id.equals(sid)))
              .write(WorkoutSetsCompanion(
                  complexMetadata: drift.Value(jsonEncode(meta))));
        }
      } catch (_) {}
    }
  }

  Future<void> delete(String name) async {
    final safeName = name.replaceAll("'", "''");
    await _db.customStatement(
        "DELETE FROM set_intent_definitions WHERE name = '$safeName'");
  }

  String getColor(List<IntentionDef> defs, String name) {
    final match = defs.where((d) => d.name == name);
    return match.isNotEmpty ? match.first.color : '#FF5722';
  }
}

// Legacy providers kept for backward compat with C.WO widget code
final currentWorkoutLogProvider = StreamProvider<WorkoutLog?>((ref) {
  return Stream.value(WorkoutLog(
      id: 1, date: DateTime.now(), accumulatedSeconds: 0, notes: 'WB EDITOR'));
});

final timerTickProvider = StreamProvider<int>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (x) => x);
});

final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

// WB Editor provider — reads DIRECTLY from real workout_block_kns + workout_block_sets tables.
// No StateNotifier dependency for field values. Reactive via knsVersionProvider.
final workoutSetsProvider =
    StreamProvider.family<List<drift.TypedResult>, DateTime>((ref, date) {
  final db = ref.read(databaseProvider);
  ref.watch(knsVersionProvider);
  final blockId = ref.watch(editorBlockIdProvider);
  final now = DateTime.now();
  final log =
      WorkoutLog(id: 1, date: now, accumulatedSeconds: 0, notes: 'WB EDITOR');

  // Reactive stream: re-query DB whenever knsVersionProvider ticks
  return Stream.fromFuture(Future(() async {
    final results = <drift.TypedResult>[];
    try {
      // Read KNS from real table
      final knsRows = await db
          .customSelect(
              'SELECT id, base_exercise_id, order_index, utilities, batch_name FROM workout_block_kns WHERE block_id = $blockId ORDER BY order_index ASC')
          .get();

      for (final kRow in knsRows) {
        final knsId = kRow.data['id'] as int;
        final baseExId = kRow.data['base_exercise_id'] as int;
        final orderIdx = (kRow.data['order_index'] as num?)?.toInt() ?? 0;
        final utilsRaw = kRow.data['utilities'] as String?;
        final batchName = kRow.data['batch_name'] as String?;
        final List<String> utilities = utilsRaw != null
            ? (jsonDecode(utilsRaw) as List).cast<String>()
            : [];

        // Read exercise info
        final ex = await (db.select(db.baseExercises)
              ..where((t) => t.id.equals(baseExId)))
            .getSingleOrNull();
        if (ex == null) continue;

        // Read sets from real table
        final setRows = await db
            .customSelect(
                'SELECT id, set_number, reps_min, reps_max, pload, rpe, rir, set_intention, side FROM workout_block_sets WHERE kns_id = $knsId ORDER BY set_number ASC')
            .get();

        if (setRows.isEmpty) {
          // Fallback: one empty set
          final meta = <String, dynamic>{};
          if (utilities.isNotEmpty) meta['utilities'] = utilities;
          if (batchName != null) meta['batch'] = batchName;
          final set = WorkoutSet(
            id: knsId,
            logId: 1,
            baseExerciseId: baseExId,
            weight: 0,
            reps: 0,
            rpe: null,
            rir: null,
            technique: null,
            failurePhase: null,
            restTimeSeconds: null,
            notes: null,
            trackName: null,
            hypeLevel: null,
            isPrSong: false,
            isPr: false,
            isCompleted: false,
            orderIndex: orderIdx,
            timestamp: now,
            complexMetadata: meta.isNotEmpty ? jsonEncode(meta) : null,
            priority: utilities.isNotEmpty ? utilities.first : null,
            supersetGroupId: null,
            supersetName: null,
          );
          results.add(drift.TypedResult({
            db.workoutSets: set,
            db.baseExercises: ex,
            db.workoutLogs: log,
          }, drift.QueryRow({}, db)));
        } else {
          for (final sRow in setRows) {
            final setId = sRow.data['id'] as int;
            final setNum = (sRow.data['set_number'] as num).toInt();
            final pload = (sRow.data['pload'] as num?)?.toDouble() ?? 0;
            final repsMax = (sRow.data['reps_max'] as num?)?.toDouble() ?? 0;
            final repsMin = (sRow.data['reps_min'] as num?)?.toDouble();
            final rpe = (sRow.data['rpe'] as num?)?.toDouble();
            final rir = (sRow.data['rir'] as num?)?.toDouble();
            final side = sRow.data['side'] as String?;
            final setIntention = sRow.data['set_intention'] as String?;

            final meta = <String, dynamic>{};
            if (utilities.isNotEmpty) meta['utilities'] = utilities;
            if (batchName != null) meta['batch'] = batchName;
            if (setIntention != null && setIntention.isNotEmpty)
              meta['intention'] = setIntention;
            if (side != null) meta['side'] = side;
            meta['knsId'] =
                knsId; // inject knsId so _ExerciseModule doesn't need StateNotifier

            final set = WorkoutSet(
              id: setId,
              logId: 1,
              baseExerciseId: baseExId,
              weight: pload,
              reps: repsMax,
              rpe: rpe,
              rir: rir,
              technique: repsMin?.toInt(),
              failurePhase: null,
              restTimeSeconds: null,
              notes: null,
              trackName: null,
              hypeLevel: null,
              isPrSong: false,
              isPr: false,
              isCompleted: false,
              orderIndex: orderIdx + setNum,
              timestamp: now,
              complexMetadata: meta.isNotEmpty ? jsonEncode(meta) : null,
              priority: utilities.isNotEmpty ? utilities.first : null,
              supersetGroupId: null,
              supersetName: null,
            );
            debugPrint(
                '[WB_PROVIDER_SET] setId=$setId dbPload=$pload dbMaxReps=$repsMax dbMinReps=$repsMin side=$side set.weight=${set.weight}');
            results.add(drift.TypedResult({
              db.workoutSets: set,
              db.baseExercises: ex,
              db.workoutLogs: log,
            }, drift.QueryRow({}, db)));
          }
        }
      }
    } catch (e) {
      debugPrint('[WB_PROVIDER_ERROR] $e');
    }
    debugPrint('[WB_PROVIDER] built ${results.length} TypedResults from DB');
    return results;
  }));
});

final bodyWeightAtDateProvider =
    StreamProvider.family<double, DateTime>((ref, date) {
  return Stream.value(51.5);
});

final sessionNumbersProvider = StreamProvider<Map<String, int>>((ref) {
  return Stream.value({'2026-06-06': 1});
});

class WorkoutBlocksEditor extends ConsumerStatefulWidget {
  final DateTime? initialDate;
  final String? blockName;
  final int blockId;
  const WorkoutBlocksEditor(
      {super.key, this.initialDate, this.blockName, this.blockId = 0});

  @override
  ConsumerState<WorkoutBlocksEditor> createState() =>
      _WorkoutManagerScreenState();
}

class _WorkoutManagerScreenState extends ConsumerState<WorkoutBlocksEditor> {
  late PageController _pageController;
  static const int _centerPage = 10000;
  bool _isSwiping = false;

  @override
  void initState() {
    super.initState();
    int initialPage = _centerPage;
    if (widget.initialDate != null) {
      initialPage = _centerPage +
          widget.initialDate!
              .difference(DateTime(DateTime.now().year, DateTime.now().month,
                  DateTime.now().day))
              .inDays;
    }
    _pageController = PageController(initialPage: initialPage);
    // Set block ID once, trigger load of KNS data
    Future.microtask(() {
      ref.read(editorBlockIdProvider.notifier).state = widget.blockId;
      ref.read(editorBlockIdProvider.notifier).state = widget.blockId;
      Future.microtask(() async {
        await ref
            .read(wbEditorProvider.notifier)
            .reload(blockId: widget.blockId);
        ref.read(knsVersionProvider.notifier).state++;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final titleText = widget.blockName ?? '';
    return MainScaffold(
      title: titleText,
      screenKey: 'WORKOUT',
      actions: [
        GestureDetector(
          onTap: () {
            ref.read(wbEditorProvider.notifier)._save();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('WB_SAVED'), duration: Duration(seconds: 1)));
          },
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: LabColors.primary, width: 0.5),
            ),
            child: Text('SAVE WB',
                style: LabStyles.mono(context,
                    fontSize: 9,
                    color: LabColors.primary,
                    fontWeight: FontWeight.bold)),
          ),
        ),
      ],
      body: SafeArea(
          child: _WorkoutDayPage(
              date: DateTime.now(),
              isScrolling: false,
              blockName: widget.blockName)),
      bottomNavigationBar: const LabFooter(),
    );
  }
}

class _WorkoutDayPage extends ConsumerStatefulWidget {
  final DateTime date;
  final bool isScrolling;
  final String? blockName;
  const _WorkoutDayPage(
      {required this.date, required this.isScrolling, this.blockName});

  @override
  ConsumerState<_WorkoutDayPage> createState() => _WorkoutDayPageState();
}

class _WorkoutDayPageState extends ConsumerState<_WorkoutDayPage> {
  late ScrollController _scrollController;
  final Set<String> _expandedUtils = {};
  TextEditingController? _descController;
  bool _descLoaded = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _descController?.dispose();
    super.dispose();
  }

  TextEditingController _getDescController() {
    if (_descController == null) {
      final desc = ref.read(wbEditorProvider).blockDescription;
      _descController = TextEditingController(text: desc ?? '');
    } else if (!_descLoaded) {
      final desc = ref.read(wbEditorProvider).blockDescription;
      if (desc != null && desc.isNotEmpty && _descController!.text != desc) {
        _descController!.text = desc;
      }
      _descLoaded = true;
    }
    return _descController!;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isScrolling) {
      return Center(
          child: Text(
              DateFormat('EEEE, MMM d, yyyy').format(widget.date).toUpperCase(),
              style: LabStyles.mono(context, color: Colors.grey[800])));
    }

    final db = ref.watch(databaseProvider);
    final workoutAsync = ref.watch(workoutSetsProvider(widget.date));
    final isToday = DateFormat('yyyy-MM-dd').format(widget.date) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());
    final bw = ref.watch(bodyWeightAtDateProvider(widget.date)).value ?? 0.0;
    final settings = ref.watch(themeSettingsProvider).value ?? {};
    final tC = ref.read(themeControllerProvider);

    return Stack(children: [
      SingleChildScrollView(
          controller: _scrollController,
          padding:
              const EdgeInsets.only(top: 40, left: 16, right: 16, bottom: 150),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildHeader(context, widget.date, ref, workoutAsync.value ?? []),
            const SizedBox(height: 16),
            // WB-level metadata: description
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white12, width: 0.5),
                color: LabColors.surfaceContainerLow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _getDescController(),
                          style: LabStyles.mono(context,
                              fontSize: 9, color: Colors.grey[300]),
                          decoration: InputDecoration(
                            hintText: 'BLOCK DESCRIPTION...',
                            hintStyle:
                                TextStyle(color: Colors.grey[700], fontSize: 9),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (v) {
                            if (mounted) {
                              ref
                                  .read(wbEditorProvider.notifier)
                                  .setBlockDescription(v);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            border:
                                Border.all(color: Colors.white24, width: 0.5),
                          ),
                          child: Text('WB META',
                              style: LabStyles.mono(context,
                                  fontSize: 7, color: Colors.grey[500])),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (c) => AlertDialog(
                    backgroundColor: LabColors.background,
                    title: Text('DELETE ALL KNS?',
                        style: LabStyles.mono(context,
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold)),
                    content: Text(
                        'This will remove all exercises from this WB.',
                        style: LabStyles.mono(context, fontSize: 11)),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(c),
                          child:
                              Text('CANCEL', style: LabStyles.mono(context))),
                      TextButton(
                          onPressed: () {
                            ref.read(wbEditorProvider.notifier).clearAll();
                            ref.read(knsVersionProvider.notifier).state++;
                            Navigator.pop(c);
                          },
                          child: Text('DELETE ALL',
                              style: LabStyles.mono(context,
                                  color: Colors.redAccent))),
                    ],
                  ),
                );
              },
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.12),
                  border: Border.all(color: Colors.redAccent, width: 0.5),
                ),
                child: Text(
                  'DELETE ALL KNS',
                  style: LabStyles.mono(context,
                      fontSize: 9,
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (isToday) ...[
              workoutAsync.when(
                data: (results) => results.isNotEmpty
                    ? Column(
                        children: [
                          const SizedBox(height: 24),
                        ],
                      )
                    : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (e, s) => const SizedBox.shrink(),
              ),
            ],
            workoutAsync.when(
              data: (results) {
                if (results.isEmpty) return _buildEmptyState(context);

                final Map<int, List<drift.TypedResult>> groupedByEx = {};
                final List<int> exerciseIdsInOrder = [];
                WorkoutLog? currentLog;

                for (var row in results) {
                  final exId = row.readTable(db.baseExercises).id;
                  currentLog ??= row.readTable(db.workoutLogs);
                  if (!groupedByEx.containsKey(exId)) {
                    groupedByEx[exId] = [];
                    exerciseIdsInOrder.add(exId);
                  }
                  groupedByEx[exId]!.add(row);
                }

                // --- ROBUST SUPERSET GROUPING LOGIC ---
                final List<List<int>> supersetGroups = [];
                final Set<int> processed = {};

                for (var exId in exerciseIdsInOrder) {
                  if (processed.contains(exId)) continue;

                  final firstSet =
                      groupedByEx[exId]!.first.readTable(db.workoutSets);
                  if (firstSet.supersetGroupId != null) {
                    final String gId = firstSet.supersetGroupId!;
                    final List<int> group = [];
                    for (var id in exerciseIdsInOrder) {
                      if (groupedByEx[id]!
                              .first
                              .readTable(db.workoutSets)
                              .supersetGroupId ==
                          gId) {
                        group.add(id);
                        processed.add(id);
                      }
                    }
                    supersetGroups.add(group);
                  } else {
                    supersetGroups.add([exId]);
                    processed.add(exId);
                  }
                }

                // --- BUILD INTERLEAVED LIST (batches + unbatched in orderIndex order) ---
                // Walk supersetGroups sequentially: when a batch is encountered, start a section;
                // when an unbatched group appears, close any open batch and render solo.
                final List<Object> interleavedItems = [];
                String? currentBatchName;
                List<List<int>> currentBatchGroups = [];

                for (final group in supersetGroups) {
                  final firstSet =
                      groupedByEx[group.first]!.first.readTable(db.workoutSets);
                  String? batchName;
                  if (firstSet.complexMetadata != null) {
                    try {
                      final meta = jsonDecode(firstSet.complexMetadata!);
                      if (meta['batch'] != null) {
                        final b = meta['batch'].toString();
                        if (b.isNotEmpty) batchName = b;
                      }
                    } catch (_) {}
                  }

                  if (batchName != null) {
                    if (currentBatchName != batchName) {
                      // Flush previous batch section
                      if (currentBatchName != null) {
                        interleavedItems.add(MapEntry(currentBatchName!,
                            List<List<int>>.from(currentBatchGroups)));
                        currentBatchGroups.clear();
                      }
                      currentBatchName = batchName;
                    }
                    currentBatchGroups.add(group);
                  } else {
                    // Flush any open batch section
                    if (currentBatchName != null) {
                      interleavedItems.add(MapEntry(currentBatchName!,
                          List<List<int>>.from(currentBatchGroups)));
                      currentBatchName = null;
                      currentBatchGroups.clear();
                    }
                    interleavedItems.add(group);
                  }
                }
                // Flush final batch
                if (currentBatchName != null) {
                  interleavedItems.add(MapEntry(currentBatchName!,
                      List<List<int>>.from(currentBatchGroups)));
                }

                // Build all widgets in order, one flatIdx for the entire list
                final List<Widget> mainWidgets = [];
                int flatIdx = 0;
                int globalSetCounter = 0;
                for (final item in interleavedItems) {
                  if (item is List<int>) {
                    // ── Unbatched group ──
                    final group = item;
                    final firstExId = group.first;
                    final firstSet =
                        groupedByEx[firstExId]!.first.readTable(db.workoutSets);
                    final isSuperset = firstSet.supersetGroupId != null;
                    final supersetName = firstSet.supersetName;
                    Color groupColor = Colors.transparent;
                    if (isSuperset && supersetName != null) {
                      groupColor = tC.getColor(
                          settings, "SUPERSET_$supersetName",
                          nameSeed: supersetName);
                    }
                    mainWidgets.add(_buildGroupWidget(group,
                        groupIdx: flatIdx,
                        groupColor: groupColor,
                        isSuperset: isSuperset,
                        supersetName: supersetName,
                        groupedByEx: groupedByEx,
                        db: db,
                        bw: bw,
                        globalSetStart: globalSetCounter));
                    // Update counter for next group: count all sets in this group's exercises
                    for (final exId in group) {
                      globalSetCounter += groupedByEx[exId]!.length;
                    }
                    flatIdx++;
                  } else if (item is MapEntry<String, List<List<int>>>) {
                    // ── Batch section ──
                    final batchName = item.key;
                    final groups = item.value;
                    final isExpanded =
                        _expandedUtils.contains('batch_$batchName');

                    final batchGroupWidgets = groups.map((group) {
                      final firstExId = group.first;
                      final firstSet = groupedByEx[firstExId]!
                          .first
                          .readTable(db.workoutSets);
                      final isSuperset = firstSet.supersetGroupId != null;
                      final supersetName = firstSet.supersetName;
                      Color groupColor = Colors.transparent;
                      if (isSuperset && supersetName != null) {
                        groupColor = tC.getColor(
                            settings, "SUPERSET_$supersetName",
                            nameSeed: supersetName);
                      }
                      final w = _buildGroupWidget(group,
                          groupIdx: flatIdx++,
                          groupColor: groupColor,
                          isSuperset: isSuperset,
                          supersetName: supersetName,
                          groupedByEx: groupedByEx,
                          db: db,
                          bw: bw,
                          globalSetStart: globalSetCounter);
                      for (final exId in group) {
                        globalSetCounter += groupedByEx[exId]!.length;
                      }
                      return w;
                    }).toList();

                    mainWidgets.add(
                      Container(
                        key: ValueKey('batch_$batchName'),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () => setState(() {
                                if (isExpanded) {
                                  _expandedUtils.remove('batch_$batchName');
                                } else {
                                  _expandedUtils.add('batch_$batchName');
                                }
                              }),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: tC
                                      .getColor(
                                          settings, 'UI_TAG_BATCH_$batchName',
                                          nameSeed: batchName)
                                      .withValues(alpha: 0.1),
                                  border: Border(
                                      left: BorderSide(
                                          color: tC.getColor(settings,
                                              'UI_TAG_BATCH_$batchName',
                                              nameSeed: batchName),
                                          width: 3)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.drag_indicator,
                                        size: 14, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text(isExpanded ? '[ − ]' : '[ + ]',
                                        style: LabStyles.mono(context,
                                            fontSize: 10,
                                            color: Colors.grey[400])),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(batchName.toUpperCase(),
                                          style: LabStyles.mono(context,
                                              fontSize: 11,
                                              color: tC.getColor(settings,
                                                  'UI_TAG_BATCH_$batchName',
                                                  nameSeed: batchName),
                                              fontWeight: FontWeight.bold)),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                      child: Text('${groups.length} KNS',
                                          style: LabStyles.mono(context,
                                              fontSize: 8,
                                              color: Colors.grey[500])),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (isExpanded) ...[
                              const SizedBox(height: 8),
                              ReorderableListView(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                buildDefaultDragHandles: false,
                                onReorder: (oldIdx, newIdx) async {
                                  if (newIdx > oldIdx) newIdx--;
                                  final reordered =
                                      List<List<int>>.from(groups);
                                  final moved = reordered.removeAt(oldIdx);
                                  reordered.insert(newIdx, moved);
                                  // Recalculate full order from interleavedItems with this batch reordered
                                  final List<int> orderIds = [];
                                  for (final oi in interleavedItems) {
                                    if (oi is List<int>) {
                                      orderIds.addAll(oi);
                                    } else if (oi
                                        is MapEntry<String, List<List<int>>>) {
                                      final bg = (oi.key == batchName)
                                          ? reordered
                                          : oi.value;
                                      for (final g in bg) {
                                        orderIds.addAll(g);
                                      }
                                    }
                                  }
                                  await db.transaction(() async {
                                    for (int i = 0; i < orderIds.length; i++) {
                                      final exId = orderIds[i];
                                      final setIds = groupedByEx[exId]!
                                          .map((r) =>
                                              r.readTable(db.workoutSets).id)
                                          .toList();
                                      await (db.update(db.workoutSets)
                                            ..where((t) => t.id.isIn(setIds)))
                                          .write(WorkoutSetsCompanion(
                                              orderIndex: drift.Value(i)));
                                    }
                                  });
                                },
                                children: batchGroupWidgets,
                              ),
                              const SizedBox(height: 8),
                            ],
                          ],
                        ),
                      ),
                    );
                  }
                }

                return Column(
                  children: [
                    ReorderableListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      buildDefaultDragHandles: false,
                      onReorder: (oldIdx, newIdx) async {
                        if (newIdx > oldIdx) newIdx--;
                        final reorderedList =
                            List<Object>.from(interleavedItems);
                        final moved = reorderedList.removeAt(oldIdx);
                        reorderedList.insert(newIdx, moved);
                        // Calculate flat orderIndex for ALL sets
                        final List<int> orderIds = [];
                        for (final oi in reorderedList) {
                          if (oi is List<int>) {
                            orderIds.addAll(oi);
                          } else if (oi is MapEntry<String, List<List<int>>>) {
                            for (final g in oi.value) {
                              orderIds.addAll(g);
                            }
                          }
                        }
                        await db.transaction(() async {
                          for (int i = 0; i < orderIds.length; i++) {
                            final exId = orderIds[i];
                            final setIds = groupedByEx[exId]!
                                .map((r) => r.readTable(db.workoutSets).id)
                                .toList();
                            await (db.update(db.workoutSets)
                                  ..where((t) => t.id.isIn(setIds)))
                                .write(WorkoutSetsCompanion(
                                    orderIndex: drift.Value(i)));
                          }
                        });
                      },
                      children: mainWidgets,
                    ),
                    if (currentLog != null) ...[
                      GeneralNotesModule(
                          key: const ValueKey('general_notes'),
                          log: currentLog,
                          cardKey: 'WB.NOTES'),
                    ],
                  ],
                );
              },
              loading: () => const Center(
                  child: Padding(
                padding: EdgeInsets.only(top: 100),
                child: CircularProgressIndicator(color: LabColors.primary),
              )),
              error: (e, s) => Center(
                  child: Padding(
                padding: const EdgeInsets.only(top: 100),
                child: Text("ERR: $e",
                    style: LabStyles.mono(context, color: Colors.redAccent)),
              )),
            ),
          ])),
      Positioned(
          bottom: 24,
          right: 24,
          child: FloatingActionButton(
              backgroundColor: LabColors.primary,
              onPressed: () => _showExercisePicker(context, ref, widget.date),
              child: const Icon(Icons.add, color: Colors.black, size: 32))),
    ]);
  }

  Widget _buildHeader(BuildContext context, DateTime date, WidgetRef ref,
      List<drift.TypedResult> results) {
    final isToday = DateFormat('yyyy-MM-dd').format(date) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());
    final settings = ref.watch(themeSettingsProvider).value ?? {};
    final tC = ref.read(themeControllerProvider);
    final dateColor =
        tC.getColor(settings, 'UI_DATE_DISPLAY', defaultColor: Colors.white);
    final sessionNums = ref.watch(sessionNumbersProvider).value ?? {};
    final seshNum = sessionNums[DateFormat('yyyy-MM-dd').format(date)];
    final db = ref.read(databaseProvider);

    // Metrics
    final totalSets = results.length;
    final knsCount = results
        .map((r) => r.readTable(db.workoutSets).baseExerciseId)
        .toSet()
        .length;
    final prCount =
        results.where((r) => r.readTable(db.workoutSets).isPr).length;
    final utilSet = results
        .map((r) => r.readTable(db.workoutSets).priority ?? '')
        .where((p) => p.isNotEmpty)
        .toSet()
        .toList();
    final utilOrder = [
      'PRIMARY',
      'SECONDARY',
      'ARM WRSTLN',
      'TERCIARY',
      'PRACTICE',
      'GTG',
      'PUMP',
      'COMPLEMENT',
      'PREHAB',
      'RECOVERY',
      'BLOOD FLOW',
      'REHAB',
      'TENDONS',
      'BODYBUILDING'
    ];
    utilSet.sort((a, b) {
      final ai = utilOrder.indexOf(a);
      final bi = utilOrder.indexOf(b);
      if (ai == -1 && bi == -1) return a.compareTo(b);
      if (ai == -1) return 1;
      if (bi == -1) return -1;
      return ai.compareTo(bi);
    });

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white12, width: 0.5),
          ),
          child: Row(
            children: [
              Text('$totalSets SETS',
                  style: LabStyles.mono(context,
                      fontSize: 9,
                      color: Colors.white70,
                      fontWeight: FontWeight.bold)),
              Container(
                  width: 1,
                  height: 12,
                  color: Colors.white12,
                  margin: const EdgeInsets.symmetric(horizontal: 8)),
              Text('$knsCount KNS',
                  style: LabStyles.mono(context,
                      fontSize: 9,
                      color: Colors.cyanAccent,
                      fontWeight: FontWeight.bold)),
              Container(
                  width: 1,
                  height: 12,
                  color: Colors.white12,
                  margin: const EdgeInsets.symmetric(horizontal: 8)),
              Text('$prCount PRs',
                  style: LabStyles.mono(context,
                      fontSize: 9,
                      color: LabColors.accent,
                      fontWeight: FontWeight.bold)),
              if (utilSet.isNotEmpty) ...[
                Container(
                    width: 1,
                    height: 12,
                    color: Colors.white12,
                    margin: const EdgeInsets.symmetric(horizontal: 8)),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: utilSet
                          .map((u) => Container(
                                margin: const EdgeInsets.only(right: 4),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: tC
                                      .getColor(settings,
                                          'UI_TAG_${u.replaceAll(' ', '_')}',
                                          nameSeed: u)
                                      .withValues(alpha: 0.15),
                                  border: Border.all(
                                      color: tC
                                          .getColor(settings,
                                              'UI_TAG_${u.replaceAll(' ', '_')}',
                                              nameSeed: u)
                                          .withValues(alpha: 0.5),
                                      width: 0.5),
                                ),
                                child: Text(u,
                                    style: LabStyles.mono(context,
                                        fontSize: 7, color: Colors.white)),
                              ))
                          .toList(),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGroupWidget(List<int> group,
      {required int groupIdx,
      required Color groupColor,
      required bool isSuperset,
      String? supersetName,
      required Map<int, List<drift.TypedResult>> groupedByEx,
      required AppDatabase db,
      required double bw,
      int globalSetStart = 0,
      bool showDragHandle = true}) {
    final firstExId = group.first;
    int runningGlobal = globalSetStart;
    return Container(
      key: ValueKey('gw_${firstExId}_$groupIdx'),
      margin: const EdgeInsets.only(bottom: 1),
      decoration: isSuperset
          ? BoxDecoration(
              border: Border.all(
                  color: groupColor.withValues(alpha: 0.8), width: 1.5),
              color: groupColor.withValues(alpha: 0.05),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isSuperset)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              color: groupColor.withValues(alpha: 0.8),
              child: Text(supersetName!.toUpperCase(),
                  style: LabStyles.mono(context,
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
          ...group.map((exId) {
            final exSets = groupedByEx[exId]!.length;
            final mod = _ExerciseModule(
              key: ValueKey('ex_${firstExId}_$exId'),
              exercise: groupedByEx[exId]!.first.readTable(db.baseExercises),
              results: groupedByEx[exId]!,
              date: widget.date,
              bodyWeight: bw,
              index: groupIdx,
              globalSetStart: runningGlobal,
              scrollController: _scrollController,
              showDragHandle: showDragHandle,
            );
            runningGlobal += exSets;
            return mod;
          }),
        ],
      ),
    );
  }

  // ─── WORKOUT OPTS ─────────────────────────────────────────────
  void _showWorkoutOptsSheet(
      BuildContext context, WidgetRef ref, List<drift.TypedResult> results) {
    showModalBottomSheet(
      context: context,
      backgroundColor: LabColors.background,
      isScrollControlled: true,
      builder: (ctx) => _WorkoutOptsSheet(
        results: results,
        onMakeBlueprint: () {
          Navigator.pop(ctx);
          _createBlueprintFromCurrentDay(context, ref, results);
        },
        onDeleteAll: () {
          Navigator.pop(ctx);
          _deleteAllSets(context, ref, results);
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // WORKOUT OPTS BOTTOM SHEET — modular slice architecture
  // ═══════════════════════════════════════════════════════════════
  // To add a new option: add a _WorkoutOptsSlice entry in the
  // slices list inside _WorkoutOptsSheetState.build().
  // Each slice is self-contained (label, icon, color, action).
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSessionTimer(BuildContext context, WidgetRef ref) {
    return EditableSessionTimer(
        logProvider: currentWorkoutLogProvider,
        tickProvider: timerTickProvider);
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
        child: Padding(
            padding: const EdgeInsets.only(top: 100),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.inbox, size: 48, color: Colors.grey[800]),
              const SizedBox(height: 16),
              Text('NO_MOVEMENTS_LOGGED_FOR_THIS_PERIOD',
                  style: LabStyles.mono(context,
                      color: Colors.grey[600]!, fontSize: 10))
            ])));
  }

  void _showExercisePicker(
      BuildContext context, WidgetRef ref, DateTime date) async {
    final settings = ref.watch(themeSettingsProvider).value ?? {};
    final tC = ref.read(themeControllerProvider);
    final copyColor = tC.getColor(
      settings,
      'INJECTION_COPY_FROM_SPECIFIC_DAY',
      defaultColor: LabColors.secondary,
      nameSeed: 'COPY_FROM_SPECIFIC_DAY',
    );
    showModalBottomSheet(
        context: context,
        backgroundColor: LabColors.background,
        isScrollControlled: true,
        builder: (context) => Container(
            padding: const EdgeInsets.all(24),
            height: MediaQuery.of(context).size.height * 0.4,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('INJECTION TYPE',
                  style: LabStyles.headline(context, color: LabColors.primary)
                      .copyWith(fontSize: 18, letterSpacing: 2)),
              const SizedBox(height: 24),
              LabButton(
                  label: 'Individual Movement',
                  color: LabColors.tertiary,
                  onPressed: () async {
                    Navigator.pop(context);
                    final db = ref.read(databaseProvider);
                    final all = await db.select(db.baseExercises).get();
                    if (context.mounted)
                      showModalBottomSheet(
                          context: context,
                          backgroundColor: LabColors.background,
                          isScrollControlled: true,
                          builder: (c) => ExerciseSearchPicker(
                              exercises: all,
                              onSelected: (e) =>
                                  _addExerciseToDate(ref, date, e)));
                  }),
              const SizedBox(height: 12),
              LabButton(
                  label: 'Copy From Specific Day',
                  color: copyColor,
                  onPressed: () => _copyFromSpecificDay(context, ref, date)),
            ])));
  }

  Future<void> _copyFromSpecificDay(
      BuildContext context, WidgetRef ref, DateTime targetDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: targetDate.subtract(const Duration(days: 1)),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
              primary: LabColors.primary,
              onPrimary: Colors.black,
              surface: LabColors.background,
              onSurface: Colors.white),
          textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: LabColors.primary)),
        ),
        child: child!,
      ),
    );

    if (picked == null || !context.mounted) return;

    final db = ref.read(databaseProvider);
    final sourceStart = DateTime(picked.year, picked.month, picked.day);
    final sourceEnd =
        DateTime(picked.year, picked.month, picked.day, 23, 59, 59);

    final sourceRows = await (db.select(db.workoutSets).join([
      drift.innerJoin(
          db.workoutLogs, db.workoutLogs.id.equalsExp(db.workoutSets.logId)),
      drift.innerJoin(db.baseExercises,
          db.baseExercises.id.equalsExp(db.workoutSets.baseExerciseId)),
    ])
          ..where(db.workoutLogs.date.isBetweenValues(sourceStart, sourceEnd))
          ..orderBy([
            drift.OrderingTerm.asc(db.workoutSets.orderIndex),
            drift.OrderingTerm.asc(db.workoutSets.timestamp)
          ]))
        .get();

    if (sourceRows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("NO_DATA_FOUND_FOR_SELECTED_DATE")));
      return;
    }

    final groupedRows = <int, List<drift.TypedResult>>{};
    for (final row in sourceRows) {
      final exId = row.readTable(db.baseExercises).id;
      groupedRows.putIfAbsent(exId, () => <drift.TypedResult>[]).add(row);
    }

    try {
      await ref
          .read(wbEditorProvider.notifier)
          .copyFromSpecificDay(groupedRows);
      ref.read(knsVersionProvider.notifier).state++;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("SESSION_CLONED_SUCCESSFULLY")));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("COPY_FROM_SPECIFIC_DAY_FAILED: $e")));
      }
    }
  }

  Future<void> _addExerciseToDate(
      WidgetRef ref, DateTime d, BaseExercise e) async {
    ref.read(wbEditorProvider.notifier).addKns(e);
    ref.read(knsVersionProvider.notifier).state++;
  }

  void _deleteAllSets(
      BuildContext context, WidgetRef ref, List<drift.TypedResult> results) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: LabColors.background,
        title: Text('CRITICAL_PURGE',
            style: LabStyles.mono(context,
                color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: Text('DELETE ALL LOGGED SETS FOR THIS SESSION?',
            style: LabStyles.mono(context, fontSize: 12)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c),
              child: Text('ABORT', style: LabStyles.mono(context))),
          TextButton(
            onPressed: () async {
              final db = ref.read(databaseProvider);
              final ids =
                  results.map((r) => r.readTable(db.workoutSets).id).toList();
              await (db.delete(db.workoutSets)..where((t) => t.id.isIn(ids)))
                  .go();
              if (context.mounted) Navigator.pop(c);
            },
            child: Text('PURGE_ALL',
                style: LabStyles.mono(context, color: Colors.redAccent)),
          )
        ],
      ),
    );
  }

  void _createBlueprintFromCurrentDay(BuildContext context, WidgetRef ref,
      List<drift.TypedResult> results) async {
    final nameC = TextEditingController();
    final db = ref.read(databaseProvider);

    final Map<int, int> exerciseSetCounts = {};
    final List<int> exerciseOrder = [];

    for (var row in results) {
      final exId = row.readTable(db.baseExercises).id;
      if (!exerciseSetCounts.containsKey(exId)) {
        exerciseSetCounts[exId] = 0;
        exerciseOrder.add(exId);
      }
      exerciseSetCounts[exId] = exerciseSetCounts[exId]! + 1;
    }

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          backgroundColor: LabColors.background,
          title: Text('GENERATE_BLUEPRINT',
              style: LabStyles.headline(context).copyWith(fontSize: 16)),
          content: LabTextField(
              controller: nameC,
              label: 'BLUEPRINT_NAME',
              placeholder: 'NAME_YOUR_TEMPLATE...'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(c),
                child: Text('ABORT', style: LabStyles.mono(context))),
            TextButton(
              onPressed: () async {
                if (nameC.text.isEmpty) return;
                final bpId = await db
                    .into(db.blueprints)
                    .insert(BlueprintsCompanion.insert(
                      name: nameC.text.toUpperCase(),
                      intention: "GENERATED_FROM_SESSION",
                    ));
                for (int i = 0; i < exerciseOrder.length; i++) {
                  final exId = exerciseOrder[i];
                  await db
                      .into(db.blueprintExercises)
                      .insert(BlueprintExercisesCompanion.insert(
                        blueprintId: bpId,
                        baseExerciseId: exId,
                        targetSetsReps:
                            drift.Value("${exerciseSetCounts[exId]} SETS"),
                        orderIndex: i,
                      ));
                }
                if (context.mounted) {
                  Navigator.pop(c);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('BLUEPRINT_CREATED_SUCCESSFULLY')));
                }
              },
              child: Text('GENERATE',
                  style: LabStyles.mono(context, color: LabColors.accent)),
            )
          ],
        ),
      );
    }
  }
}

class _ExerciseModule extends ConsumerStatefulWidget {
  final BaseExercise exercise;
  final List<drift.TypedResult> results;
  final DateTime date;
  final double bodyWeight;
  final int index;
  final int globalSetStart;
  final ScrollController scrollController;
  final bool showDragHandle;
  const _ExerciseModule(
      {super.key,
      required this.exercise,
      required this.results,
      required this.date,
      required this.bodyWeight,
      required this.index,
      required this.globalSetStart,
      required this.scrollController,
      this.showDragHandle = true});
  @override
  ConsumerState<_ExerciseModule> createState() => _ExerciseModuleState();
}

class _ExerciseModuleState extends ConsumerState<_ExerciseModule> {
  bool _isExpanded = true;
  TextEditingController? _purposeController;
  bool _purposeLoaded = false;

  @override
  void dispose() {
    _purposeController?.dispose();
    super.dispose();
  }

  int _knsId() => ref
      .read(wbEditorProvider)
      .knsEntries
      .firstWhere((k) => k.baseExerciseId == widget.exercise.id,
          orElse: () => WbEditorKns(
              id: 0,
              baseExerciseId: 0,
              exerciseName: '',
              orderIndex: 0,
              prefixes: null,
              suffixes: null,
              bodyPositions: null,
              implements: null))
      .id;

  TextEditingController _purposeCtrl() {
    if (_purposeController == null) {
      final kns = ref
          .read(wbEditorProvider)
          .knsEntries
          .where((k) => k.baseExerciseId == widget.exercise.id);
      _purposeController = TextEditingController(
          text: kns.isNotEmpty ? (kns.first.intention ?? '') : '');
    } else if (!_purposeLoaded) {
      final kns = ref
          .read(wbEditorProvider)
          .knsEntries
          .where((k) => k.baseExerciseId == widget.exercise.id);
      final saved = kns.isNotEmpty ? (kns.first.intention ?? '') : '';
      if (saved.isNotEmpty && _purposeController!.text != saved) {
        _purposeController!.text = saved;
      }
      _purposeLoaded = true;
    }
    return _purposeController!;
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.exercise;
    final intentionText = e.intention ?? '';
    final metaMatch =
        RegExp(r'\[NT:(.*)\|ISO:(.*)\]').firstMatch(intentionText);
    String loadType = 'EXT.LOAD';
    bool isIso = intentionText.startsWith('[ISO]');
    if (metaMatch != null) {
      loadType = metaMatch.group(1) ?? 'EXT.LOAD';
      isIso = metaMatch.group(2) == 'true';
    } else if (['LASTRE', 'EXT.LOAD', 'JST.BW'].contains(e.field)) {
      loadType = e.field!;
    }

    final settings = ref.watch(themeSettingsProvider).value ?? {};
    final tC = ref.read(themeControllerProvider);
    final firstSet =
        widget.results.first.readTable(ref.read(databaseProvider).workoutSets);
    // Read utilities from complex_metadata (priority field fallback)
    List<String> utilities = [];
    if (firstSet.complexMetadata != null) {
      try {
        final meta = jsonDecode(firstSet.complexMetadata!);
        utilities = List<String>.from(meta['utilities'] ?? []);
      } catch (_) {}
    }
    if (utilities.isEmpty &&
        firstSet.priority != null &&
        firstSet.priority!.isNotEmpty) {
      utilities = [firstSet.priority!];
    }
    final bool hasUtility = utilities.isNotEmpty;
    final utilityColor = hasUtility
        ? tC.getColor(settings, "PRIORITY_${utilities.first}",
            nameSeed: utilities.first)
        : Colors.transparent;

    // Resolve tag colors from theme
    final uiTagLastre =
        tC.getColor(settings, "UI_TAG_LASTRE", nameSeed: "LASTRE");
    final uiTagJstbw = tC.getColor(settings, "UI_TAG_JSTBW", nameSeed: "JSTBW");
    final uiTagExtload =
        tC.getColor(settings, "UI_TAG_EXTLOAD", nameSeed: "EXTLOAD");
    final uiTagIso = tC.getColor(settings, "UI_TAG_ISO", nameSeed: "ISO");
    final uiTagBodyposition =
        tC.getColor(settings, "UI_TAG_BODYPOSITION", nameSeed: "BODYPOSITION");
    final uiTagPrimaryMuscle = tC.getColor(settings, "UI_TAG_PRIMARY_MUSCLE",
        nameSeed: "PRIMARY_MUSCLE");

    Color typeColor;
    switch (loadType) {
      case 'LASTRE':
        typeColor = uiTagLastre;
        break;
      case 'JST.BW':
        typeColor = uiTagJstbw;
        break;
      case 'EXT.LOAD':
        typeColor = uiTagExtload;
        break;
      default:
        typeColor = LabColors.primary;
    }
    final isoColor = uiTagIso;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: LabColors.surfaceDim,
        border: Border.all(
            color: hasUtility
                ? utilityColor
                : LabColors.cyanBorder
                    .withValues(alpha: _isExpanded ? 0.5 : 0.2),
            width: hasUtility ? 1.5 : 0.5),
        boxShadow: hasUtility
            ? [
                BoxShadow(
                    color: utilityColor.withValues(alpha: 0.1), blurRadius: 10)
              ]
            : null,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // [UTIL] row — OUTSIDE InkWell to avoid gesture conflict
                    GestureDetector(
                      onTap: () => _showUtilityEditDialog(context),
                      child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ...utilities.take(4).map((u) {
                                  final chipColor = tC.getColor(
                                      settings, "PRIORITY_$u",
                                      nameSeed: u);
                                  return Container(
                                    margin: const EdgeInsets.only(right: 3),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: chipColor.withValues(alpha: 0.2),
                                      border: Border.all(
                                          color: chipColor, width: 0.5),
                                    ),
                                    child: Text(
                                      u.toUpperCase(),
                                      style: LabStyles.mono(context,
                                          color: chipColor,
                                          fontSize: 7,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  );
                                }),
                                if (!hasUtility)
                                  Text('[ UTIL ]',
                                      style: LabStyles.mono(context,
                                          color: Colors.grey[600]!,
                                          fontSize: 8)),
                              ],
                            ),
                            if (isIso)
                              Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 1),
                                  margin: const EdgeInsets.only(right: 4),
                                  decoration: BoxDecoration(
                                      border: Border.all(
                                          color: isoColor, width: 0.5)),
                                  child: Text('ISO',
                                      style: LabStyles.mono(context,
                                          color: isoColor,
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold))),
                            Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                    border: Border.all(
                                        color: typeColor, width: 0.5)),
                                child: Text(loadType,
                                    style: LabStyles.mono(context,
                                        color: typeColor,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold))),
                          ]),
                    ),
                    const SizedBox(height: 6),
                    // Exercise name + tags — the expand/collapse area
                    GestureDetector(
                      onTap: () => setState(() => _isExpanded = !_isExpanded),
                      onLongPress: () => _showComplexModsModal(context),
                      child: Container(
                        color: Colors.transparent,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Builder(builder: (c) {
                              return Text(e.fullName,
                                  style: LabStyles.headline(context).copyWith(
                                      fontSize: 18, color: Colors.white));
                            }),
                            const SizedBox(height: 4),
                            // KNS-level metadata: purpose
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 6),
                              margin: const EdgeInsets.only(bottom: 6),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: Colors.white12, width: 0.5),
                                color: Colors.black.withValues(alpha: 0.3),
                              ),
                              child: TextField(
                                controller: _purposeCtrl(),
                                style: LabStyles.mono(context,
                                    fontSize: 9, color: Colors.grey[300]),
                                decoration: InputDecoration(
                                  hintText: 'KNS PURPOSE...',
                                  hintStyle: TextStyle(
                                      color: Colors.grey[700], fontSize: 9),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (v) {
                                  if (mounted) {
                                    final kid = _knsId();
                                    if (kid != 0) {
                                      ref
                                          .read(wbEditorProvider.notifier)
                                          .setKnsPurpose(kid, v);
                                    }
                                  }
                                },
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                if (e.primaryMuscleGroup != null)
                                  Text(e.primaryMuscleGroup!.toUpperCase(),
                                      style: LabStyles.mono(context,
                                          color: uiTagPrimaryMuscle,
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold)),
                                ...e.bodyPositionTags.map((tag) => Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: uiTagBodyposition.withValues(
                                            alpha: 0.1),
                                        border: Border.all(
                                            color: uiTagBodyposition.withValues(
                                                alpha: 0.3),
                                            width: 0.5),
                                      ),
                                      child: Text(tag.toUpperCase(),
                                          style: LabStyles.mono(context,
                                              fontSize: 7,
                                              color: uiTagBodyposition)),
                                    )),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Row(mainAxisSize: MainAxisSize.min, children: [
                if (widget.showDragHandle)
                  ReorderableDragStartListener(
                    index: widget.index,
                    child: const Padding(
                      padding: EdgeInsets.only(
                          left: 32, right: 6, top: 2, bottom: 2),
                      child: Icon(Icons.drag_handle,
                          color: LabColors.primary, size: 20),
                    ),
                  ),
                IconButton(
                    icon: const Icon(Icons.history,
                        color: LabColors.primary, size: 20),
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (c) => ExerciseHistoryScreen(
                                exercise: widget.exercise)))),
              ]),
            ],
          ),
        ),
        if (_isExpanded) ...[
          const Divider(height: 1, color: LabColors.cyanBorder, thickness: 0.2),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ReorderableListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  onReorder: (oldIdx, newIdx) async {
                    if (newIdx > oldIdx) newIdx--;
                    final sets = widget.results
                        .map((r) =>
                            r.readTable(ref.read(databaseProvider).workoutSets))
                        .toList();
                    final moved = sets.removeAt(oldIdx);
                    sets.insert(newIdx, moved);

                    final db = ref.read(databaseProvider);
                    for (int i = 0; i < sets.length; i++) {
                      await (db.update(db.workoutSets)
                            ..where((t) => t.id.equals(sets[i].id)))
                          .write(
                              WorkoutSetsCompanion(orderIndex: drift.Value(i)));
                    }
                  },
                  children: _buildGroupedSets(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                        child: LabButton(
                            label: 'Add Set',
                            onPressed: () => _addNewSet(context),
                            isOutlined: true,
                            color: Colors.white)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ]),
    );
  }

  void _showComplexModsModal(BuildContext context) {
    final bool isLinked = widget.results.first
            .readTable(ref.read(databaseProvider).workoutSets)
            .supersetGroupId !=
        null;

    showModalBottomSheet(
      context: context,
      backgroundColor: LabColors.background,
      builder: (c) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('COMPLEX_C.WO_MODS',
                style: LabStyles.headline(context).copyWith(fontSize: 16)),
            const SizedBox(height: 24),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _buildModCard(context, 'SUPERSET', Icons.link,
                    LabColors.primary, () => _handleCreateSuperset(context)),
                if (isLinked)
                  _buildModCard(context, 'BREAK_LINK', Icons.link_off,
                      Colors.orangeAccent, () => _handleBreakSuperset(context)),
                _buildModCard(context, 'EDIT MOVEMENT', Icons.settings,
                    LabColors.accent, () => _navigateToEdit(context)),
                _buildModCard(context, 'PURGE', Icons.delete_forever,
                    Colors.redAccent, () => _confirmPurge(context)),
                _buildModCard(context, 'MOVE TO TOP', Icons.arrow_upward,
                    Colors.white, () => _moveExerciseToExtreme(true)),
                _buildModCard(context, 'MOVE TO BOTTOM', Icons.arrow_downward,
                    Colors.white, () => _moveExerciseToExtreme(false)),
                _buildModCard(context, 'ASSIGN BATCH', Icons.folder,
                    Colors.tealAccent, () => _showBatchPopup(context)),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _moveExerciseToExtreme(bool toTop) async {
    final db = ref.read(databaseProvider);
    final start =
        DateTime(widget.date.year, widget.date.month, widget.date.day);
    final end = DateTime(
        widget.date.year, widget.date.month, widget.date.day, 23, 59, 59);

    final allSetsDay = await (db.select(db.workoutSets).join([
      drift.innerJoin(
          db.workoutLogs, db.workoutLogs.id.equalsExp(db.workoutSets.logId))
    ])
          ..where(db.workoutLogs.date.isBetweenValues(start, end))
          ..orderBy([
            drift.OrderingTerm.asc(db.workoutSets.orderIndex),
            drift.OrderingTerm.asc(db.workoutSets.timestamp)
          ]))
        .get();

    if (allSetsDay.isEmpty) return;

    final targetExId = widget.exercise.id;
    final List<int> exOrder = [];
    final Map<int, List<int>> setsByEx = {};

    for (var row in allSetsDay) {
      final s = row.readTable(db.workoutSets);
      if (!exOrder.contains(s.baseExerciseId)) exOrder.add(s.baseExerciseId);
      setsByEx.putIfAbsent(s.baseExerciseId, () => []).add(s.id);
    }

    exOrder.remove(targetExId);
    if (toTop) {
      exOrder.insert(0, targetExId);
    } else {
      exOrder.add(targetExId);
    }

    await db.transaction(() async {
      for (int i = 0; i < exOrder.length; i++) {
        final sets = setsByEx[exOrder[i]]!;
        await (db.update(db.workoutSets)..where((t) => t.id.isIn(sets)))
            .write(WorkoutSetsCompanion(orderIndex: drift.Value(i)));
      }
    });
  }

  Future<void> _showBatchPopup(BuildContext context) async {
    final db = ref.read(databaseProvider);
    // Ensure table exists (safety net for hot reloads)
    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS batch_definitions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        created_at INTEGER NOT NULL DEFAULT 0
      )
    ''');
    // Read ALL global batch names from batch_definitions table
    final rows = await db.executor
        .runSelect('SELECT name FROM batch_definitions ORDER BY name ASC', []);
    final batchList = rows.map((r) => r['name'] as String).toList();
    final nameC = TextEditingController();

    // Show dialog on top of mods modal (don't pop it)
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: LabColors.background,
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ASSIGN_BATCH',
                    style: LabStyles.headline(context).copyWith(fontSize: 16)),
                const SizedBox(height: 16),
                TextField(
                  controller: nameC,
                  style: LabStyles.mono(context,
                      fontSize: 12, color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'BATCH_NAME',
                    hintStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
                    border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24)),
                  ),
                ),
                if (batchList.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('EXISTING_BATCHES:',
                      style: LabStyles.mono(context,
                          fontSize: 9, color: Colors.grey[500])),
                  const SizedBox(height: 8),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                    childAspectRatio: 3.5,
                    children: batchList
                        .map((name) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 2, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                border: Border.all(
                                    color: Colors.white12, width: 0.5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        nameC.text = name.toUpperCase();
                                        nameC.selection =
                                            TextSelection.fromPosition(
                                          TextPosition(
                                              offset: nameC.text.length),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 6),
                                        child: Text(name.toUpperCase(),
                                            style: LabStyles.mono(context,
                                                fontSize: 10,
                                                color: Colors.tealAccent),
                                            overflow: TextOverflow.ellipsis),
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () async {
                                      await _renameBatch(db, name, c);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 3, vertical: 6),
                                      child: Icon(Icons.edit,
                                          size: 11, color: Colors.amber),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () async {
                                      await _deleteBatch(db, name, c);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 3, vertical: 6),
                                      child: Icon(Icons.delete,
                                          size: 11, color: Colors.redAccent),
                                    ),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: LabButton(
                    label: 'ASSIGN',
                    color: Colors.tealAccent,
                    onPressed: () async {
                      final name = nameC.text.trim();
                      if (name.isNotEmpty) {
                        await _assignBatch(db, name.toUpperCase());
                        if (c.mounted) Navigator.pop(c);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _assignBatch(AppDatabase db, String batchName) async {
    // 1) Ensure table exists (safety net for hot reloads)
    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS batch_definitions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        created_at INTEGER NOT NULL DEFAULT 0
      )
    ''');
    // 2) Ensure the batch exists globally in batch_definitions
    await db.customStatement(
        "INSERT OR IGNORE INTO batch_definitions (name, created_at) "
        "VALUES ('${batchName.replaceAll("'", "''")}', ${DateTime.now().millisecondsSinceEpoch})");
    // 2) Assign to selected sets (complex_metadata)
    final setIds =
        widget.results.map((r) => r.readTable(db.workoutSets).id).toList();
    for (final sid in setIds) {
      // Skip if set doesn't exist in real DB (mock data)
      final rows = await (db.select(db.workoutSets)
            ..where((t) => t.id.equals(sid)))
          .get();
      if (rows.isEmpty) continue;
      final row = rows.first;
      Map<String, dynamic> meta = {};
      if (row.complexMetadata != null) {
        try {
          meta = jsonDecode(row.complexMetadata!);
        } catch (_) {}
      }
      meta['batch'] = batchName;
      await (db.update(db.workoutSets)..where((t) => t.id.equals(sid))).write(
          WorkoutSetsCompanion(complexMetadata: drift.Value(jsonEncode(meta))));
    }
    // 3) Invalidate batch names provider so THEME.MDFYR updates
    // 4) Also update the WB Editor mock
    if (setIds.isNotEmpty) {
      final knsId = ref
          .read(wbEditorProvider)
          .knsEntries
          .firstWhere((k) => k.baseExerciseId == widget.exercise.id,
              orElse: () => WbEditorKns(
                  id: 0,
                  baseExerciseId: 0,
                  exerciseName: '',
                  orderIndex: 0,
                  prefixes: null,
                  suffixes: null,
                  bodyPositions: null,
                  implements: null))
          .id;
      if (knsId != 0) {
        ref.read(wbEditorProvider.notifier).setBatch(knsId, batchName);
      }
    }
    if (context.mounted) ref.invalidate(allBatchNamesProvider);
  }

  Future<void> _renameBatch(
      AppDatabase db, String oldName, BuildContext dialogContext) async {
    final newNameC = TextEditingController(text: oldName);
    final result = await showDialog<String>(
      context: dialogContext,
      builder: (c2) => AlertDialog(
        backgroundColor: LabColors.background,
        title: Text('RENAME_BATCH',
            style: LabStyles.headline(c2).copyWith(fontSize: 14)),
        content: TextField(
          controller: newNameC,
          style: LabStyles.mono(c2, fontSize: 12, color: Colors.white),
          decoration: InputDecoration(
            hintText: 'NEW_NAME',
            hintStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
            border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white24)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c2, null),
            child: Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(c2, newNameC.text.trim().toUpperCase()),
            child: Text('RENAME', style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty || result == oldName) return;
    final safeOld = oldName.replaceAll("'", "''");
    final safeNew = result.replaceAll("'", "''");
    // Ensure table + rename in batch_definitions
    await db.customStatement(
        "INSERT OR IGNORE INTO batch_definitions (name, created_at) VALUES ('$safeNew', ${DateTime.now().millisecondsSinceEpoch})");
    await db.customStatement(
        "DELETE FROM batch_definitions WHERE name = '$safeOld'");
    // Update all workout_sets complex_metadata that reference the old name
    final affected = await db.executor.runSelect(
        "SELECT id, complex_metadata FROM workout_sets WHERE complex_metadata LIKE '%\"batch\":\"$safeOld\"%'",
        []);
    for (final row in affected) {
      final sid = row['id'] as int;
      final cm = row['complex_metadata'] as String?;
      if (cm == null) continue;
      try {
        final meta = jsonDecode(cm) as Map<String, dynamic>;
        if (meta['batch'] == oldName) {
          meta['batch'] = result;
          await (db.update(db.workoutSets)..where((t) => t.id.equals(sid)))
              .write(WorkoutSetsCompanion(
                  complexMetadata: drift.Value(jsonEncode(meta))));
        }
      } catch (_) {}
    }
    if (context.mounted) ref.invalidate(allBatchNamesProvider);
  }

  Future<void> _deleteBatch(
      AppDatabase db, String batchName, BuildContext dialogContext) async {
    final confirmed = await showDialog<bool>(
      context: dialogContext,
      builder: (c2) => AlertDialog(
        backgroundColor: LabColors.background,
        title: Text('DELETE_BATCH',
            style: LabStyles.headline(c2).copyWith(fontSize: 14)),
        content: Text(
            'Delete batch "${batchName.toUpperCase()}"?\nThis will remove it from all sets.',
            style: LabStyles.mono(c2, fontSize: 11, color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c2, false),
            child: Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c2, true),
            child: Text('DELETE', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final safeName = batchName.replaceAll("'", "''");
    // Remove from batch_definitions
    await db.customStatement(
        "DELETE FROM batch_definitions WHERE name = '$safeName'");
    // Clear 'batch' key from all workout_sets complex_metadata
    final affected = await db.executor.runSelect(
        "SELECT id, complex_metadata FROM workout_sets WHERE complex_metadata LIKE '%\"batch\":\"$safeName\"%'",
        []);
    for (final row in affected) {
      final sid = row['id'] as int;
      final cm = row['complex_metadata'] as String?;
      if (cm == null) continue;
      try {
        final meta = jsonDecode(cm) as Map<String, dynamic>;
        if (meta['batch'] == batchName) {
          meta.remove('batch');
          await (db.update(db.workoutSets)..where((t) => t.id.equals(sid)))
              .write(WorkoutSetsCompanion(
                  complexMetadata: drift.Value(jsonEncode(meta))));
        }
      } catch (_) {}
    }
    if (context.mounted) ref.invalidate(allBatchNamesProvider);
  }

  Widget _buildModCard(BuildContext context, String label, IconData icon,
      Color color, VoidCallback onTap) {
    return Material(
      color: LabColors.surfaceContainerHigh,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          onTap();
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(label,
                style: LabStyles.mono(context,
                    fontSize: 8, color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _navigateToEdit(BuildContext context) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (c) => EditExerciseScreen(exercise: widget.exercise)));
  }

  void _handleBreakSuperset(BuildContext context) async {
    final db = ref.read(databaseProvider);
    final firstSet = widget.results.first.readTable(db.workoutSets);
    final gId = firstSet.supersetGroupId;
    if (gId == null) return;

    await (db.update(db.workoutSets)
          ..where((t) => t.supersetGroupId.equals(gId)))
        .write(const WorkoutSetsCompanion(
            supersetGroupId: drift.Value(null),
            supersetName: drift.Value(null)));

    if (context.mounted)
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("SUPERSET_DISSOLVED")));
  }

  void _handleCreateSuperset(BuildContext context) async {
    final db = ref.read(databaseProvider);
    final start =
        DateTime(widget.date.year, widget.date.month, widget.date.day);
    final end = DateTime(
        widget.date.year, widget.date.month, widget.date.day, 23, 59, 59);

    final daySets = await (db.select(db.workoutSets).join([
      drift.innerJoin(db.baseExercises,
          db.baseExercises.id.equalsExp(db.workoutSets.baseExerciseId)),
      drift.innerJoin(
          db.workoutLogs, db.workoutLogs.id.equalsExp(db.workoutSets.logId))
    ])
          ..where(db.workoutLogs.date.isBetweenValues(start, end)))
        .get();

    final Map<int, List<drift.TypedResult>> grouped = {};
    for (var row in daySets) {
      final exId = row.readTable(db.baseExercises).id;
      grouped.putIfAbsent(exId, () => []).add(row);
    }

    final others =
        grouped.entries.where((e) => e.key != widget.exercise.id).toList();
    final Set<int> selectedIds = {};
    final nameC = TextEditingController();

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: LabColors.background,
      builder: (c) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('FORGE_SUPERSET_IN_VIVO',
                  style: LabStyles.headline(context).copyWith(fontSize: 16)),
              const SizedBox(height: 24),
              LabTextField(
                  controller: nameC,
                  label: 'SUPERSET_NAME',
                  placeholder: 'e.g. AGONIST_STATIC'),
              const SizedBox(height: 16),
              Text('SELECT MOVEMENTS TO LINK:',
                  style:
                      LabStyles.mono(context, fontSize: 8, color: Colors.grey)),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: LabStyles.hairlineBorder(),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: others.length,
                  itemBuilder: (context, i) {
                    final ex =
                        others[i].value.first.readTable(db.baseExercises);
                    final firstS =
                        others[i].value.first.readTable(db.workoutSets);
                    final bool isLinked = firstS.supersetGroupId != null;

                    return CheckboxListTile(
                      title: Text(ex.fullName,
                          style: LabStyles.mono(context, fontSize: 10)),
                      value: selectedIds.contains(ex.id),
                      subtitle: isLinked
                          ? Text('ALREADY LINKED: ${firstS.supersetName}',
                              style: LabStyles.mono(context,
                                  fontSize: 7, color: Colors.orangeAccent))
                          : null,
                      onChanged: (val) {
                        setModalState(() {
                          if (val == true) {
                            selectedIds.add(ex.id);
                          } else {
                            selectedIds.remove(ex.id);
                          }
                        });
                      },
                      activeColor: LabColors.primary,
                      checkColor: Colors.black,
                      selected: selectedIds.contains(ex.id),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              LabButton(
                  label: 'Forge Link',
                  onPressed: () async {
                    final String sName = nameC.text.toUpperCase().trim();
                    if (sName.isEmpty || selectedIds.isEmpty) return;

                    final String gId =
                        DateTime.now().millisecondsSinceEpoch.toString();

                    await db.transaction(() async {
                      // Update target sets
                      final targetSets = widget.results
                          .map((r) => r.readTable(db.workoutSets).id)
                          .toList();
                      await (db.update(db.workoutSets)
                            ..where((t) => t.id.isIn(targetSets)))
                          .write(WorkoutSetsCompanion(
                              supersetGroupId: drift.Value(gId),
                              supersetName: drift.Value(sName)));

                      // Update selected others
                      for (int exId in selectedIds) {
                        final otherSets = grouped[exId]!
                            .map((r) => r.readTable(db.workoutSets).id)
                            .toList();
                        await (db.update(db.workoutSets)
                              ..where((t) => t.id.isIn(otherSets)))
                            .write(WorkoutSetsCompanion(
                                supersetGroupId: drift.Value(gId),
                                supersetName: drift.Value(sName)));
                      }
                    });

                    if (context.mounted) Navigator.pop(context);
                  }),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showUtilityEditDialog(BuildContext context) async {
    final db = ref.read(databaseProvider);
    final allSets = await db.select(db.workoutSets).get();
    final Set<String> existingUtilities = {};
    final Map<String, int> utilFrequency = {};
    for (final set in allSets) {
      if (set.priority != null && set.priority!.isNotEmpty) {
        existingUtilities.add(set.priority!);
        utilFrequency[set.priority!] = (utilFrequency[set.priority!] ?? 0) + 1;
      }
      if (set.complexMetadata != null) {
        try {
          final meta = jsonDecode(set.complexMetadata!);
          final utils = meta['utilities'] as List? ?? [];
          for (final u in utils.cast<String>()) {
            existingUtilities.add(u);
            utilFrequency[u] = (utilFrequency[u] ?? 0) + 1;
          }
        } catch (_) {}
      }
    }
    final existingList = existingUtilities.toList()..sort();
    if (!context.mounted) return;

    final firstSet = widget.results.first.readTable(db.workoutSets);
    List<String> currentUtilities = [];
    if (firstSet.complexMetadata != null) {
      try {
        final meta = jsonDecode(firstSet.complexMetadata!);
        currentUtilities = List<String>.from(meta['utilities'] ?? []);
      } catch (_) {}
    }
    if (currentUtilities.isEmpty &&
        firstSet.priority != null &&
        firstSet.priority!.isNotEmpty) {
      currentUtilities = [firstSet.priority!];
    }

    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: LabColors.background,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Padding(
            padding: const EdgeInsets.only(left: 24, right: 24, top: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('EDIT_MOVEMENT_UTILITY',
                    style: LabStyles.headline(context).copyWith(fontSize: 16)),
                const SizedBox(height: 24),
                Flexible(
                  child: SingleChildScrollView(
                    child: LabUtilitySelector(
                      selected: currentUtilities,
                      suggestions: existingList,
                      utilityFrequency: utilFrequency,
                      onChanged: (updated) =>
                          setDialogState(() => currentUtilities = updated),
                      onRename: (oldN, newN) =>
                          _propagatePriorityChange(oldN, newN),
                      onDelete: (name) => _propagatePriorityChange(name, null),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                LabButton(
                    label: 'Apply Utility',
                    onPressed: () async {
                      final sets = widget.results
                          .map((r) => r.readTable(db.workoutSets).id)
                          .toList();
                      for (final setId in sets) {
                        final rows = await (db.select(db.workoutSets)
                              ..where((t) => t.id.equals(setId)))
                            .get();
                        if (rows.isEmpty) continue;
                        final rowSet = rows.first;
                        Map<String, dynamic> meta = {};
                        if (rowSet.complexMetadata != null) {
                          try {
                            meta = jsonDecode(rowSet.complexMetadata!);
                          } catch (_) {}
                        }
                        if (currentUtilities.isEmpty) {
                          meta.remove('utilities');
                        } else {
                          meta['utilities'] = currentUtilities;
                        }
                        await (db.update(db.workoutSets)
                              ..where((t) => t.id.equals(setId)))
                            .write(WorkoutSetsCompanion(
                          complexMetadata: drift.Value(
                              meta.isNotEmpty ? jsonEncode(meta) : null),
                          priority: drift.Value(currentUtilities.isNotEmpty
                              ? currentUtilities.first
                              : null),
                        ));
                      }
                      // Also update the WB Editor mock
                      if (sets.isNotEmpty && context.mounted) {
                        final knsId = ref
                            .read(wbEditorProvider)
                            .knsEntries
                            .firstWhere(
                                (k) => k.baseExerciseId == widget.exercise.id,
                                orElse: () => WbEditorKns(
                                    id: 0,
                                    baseExerciseId: 0,
                                    exerciseName: '',
                                    orderIndex: 0,
                                    prefixes: null,
                                    suffixes: null,
                                    bodyPositions: null,
                                    implements: null))
                            .id;
                        if (knsId != 0) {
                          ref
                              .read(wbEditorProvider.notifier)
                              .setUtilities(knsId, currentUtilities);
                        }
                      }
                      if (context.mounted) Navigator.pop(context);
                    }),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _propagatePriorityChange(String oldName, String? newName) async {
    final db = ref.read(databaseProvider);
    await db.transaction(() async {
      // Update Workout Logs
      await (db.update(db.workoutSets)
            ..where((t) => t.priority.equals(oldName)))
          .write(WorkoutSetsCompanion(priority: drift.Value(newName)));
    });
  }

  List<Widget> _buildGroupedSets() {
    final db = ref.read(databaseProvider);
    final List<Widget> items = [];
    final sets = widget.results.asMap().entries.toList();

    int i = 0;
    while (i < sets.length) {
      final entry = sets[i];
      final s = entry.value.readTable(db.workoutSets);
      final l = entry.value.readTable(db.workoutLogs);

      Map<String, dynamic> meta = {};
      try {
        if (s.complexMetadata != null) meta = jsonDecode(s.complexMetadata!);
      } catch (_) {}

      // Check if it's the start of a unilateral pair
      if (widget.exercise.isUnilateral &&
          meta["side"] == "RIGHT" &&
          (i + 1) < sets.length) {
        final nextEntry = sets[i + 1];
        final ns = nextEntry.value.readTable(db.workoutSets);
        Map<String, dynamic> nMeta = {};
        try {
          if (ns.complexMetadata != null)
            nMeta = jsonDecode(ns.complexMetadata!);
        } catch (_) {}

        if (nMeta["side"] == "LEFT") {
          // It's a pair! Group them
          // Extract knsId from complexMetadata
          int knsIdR = 0, knsIdL = 0;
          try {
            final cm = jsonDecode(s.complexMetadata ?? '{}');
            knsIdR = (cm['knsId'] as num?)?.toInt() ?? 0;
          } catch (_) {}
          try {
            final cm = jsonDecode(ns.complexMetadata ?? '{}');
            knsIdL = (cm['knsId'] as num?)?.toInt() ?? 0;
          } catch (_) {}
          items.add(UnilateralPairFrame(
            key: ValueKey('pair_${s.id}_${ns.id}'),
            rightSet: _WorkoutSetInstance(
              key: ValueKey('set_${s.id}'),
              set: s,
              log: l,
              exercise: widget.exercise,
              index: i,
              globalIndex: widget.globalSetStart + i + 1,
              bodyWeight: widget.bodyWeight,
              side: "RIGHT",
              knsId: knsIdR,
            ),
            leftSet: _WorkoutSetInstance(
              key: ValueKey('set_${ns.id}'),
              set: ns,
              log: l,
              exercise: widget.exercise,
              index: i + 1,
              globalIndex: widget.globalSetStart + i + 2,
              bodyWeight: widget.bodyWeight,
              side: "LEFT",
              knsId: knsIdL,
            ),
            index: (i ~/ 2) + 1,
          ));
          i += 2;
          continue;
        }
      }

      // Single set (standard or fallback)
      // Read knsId from complexMetadata (injected by provider, no StateNotifier dependency)
      final int knsId2 = () {
        try {
          final cm = jsonDecode(s.complexMetadata ?? '{}');
          return (cm['knsId'] as num?)?.toInt() ?? 0;
        } catch (_) {
          return 0;
        }
      }();
      items.add(_WorkoutSetInstance(
        key: ValueKey('set_${s.id}'),
        set: s,
        log: l,
        exercise: widget.exercise,
        index: i,
        globalIndex: widget.globalSetStart + i + 1,
        bodyWeight: widget.bodyWeight,
        knsId: knsId2,
      ));
      i++;
    }
    return items;
  }

  // Remove old _buildExerciseReorderControls and _moveExercise
  Future<void> _addNewSet(BuildContext c) async {
    // Add to mock and also to the notifier for persistence
    final db = ref.read(databaseProvider);
    final fS = widget.results.first.readTable(db.workoutSets);
    final now = DateTime.now();
    final maxOrder = widget.results
        .map((r) => r.readTable(db.workoutSets).orderIndex)
        .reduce((a, b) => a > b ? a : b);
    final baseId = -now.microsecondsSinceEpoch;
    final log = widget.results.first.readTable(db.workoutLogs);
    final ex = widget.results.first.readTable(db.baseExercises);

    final List<Map<String, dynamic>> newSetDefs;
    if (widget.exercise.isUnilateral) {
      newSetDefs = [
        {
          'id': baseId,
          'side': 'RIGHT',
          'order': maxOrder + 1,
          'meta': jsonEncode({'side': 'RIGHT'})
        },
        {
          'id': baseId + 1,
          'side': 'LEFT',
          'order': maxOrder + 2,
          'meta': jsonEncode({'side': 'LEFT'})
        },
      ];
    } else {
      newSetDefs = [
        {'id': baseId, 'side': null, 'order': maxOrder + 1, 'meta': null},
      ];
    }

    setState(() {
      for (final def in newSetDefs) {
        final setId = def['id'] as int;
        final side = def['side'] as String?;
        final metaStr = def['meta'] as String?;
        final order = def['order'] as int;
        final newSet = WorkoutSet(
          id: setId,
          logId: fS.logId,
          baseExerciseId: widget.exercise.id,
          weight: 0,
          reps: 0,
          rpe: null,
          rir: null,
          technique: null,
          failurePhase: null,
          restTimeSeconds: null,
          notes: null,
          trackName: null,
          hypeLevel: null,
          isPrSong: false,
          isPr: false,
          isCompleted: false,
          orderIndex: order,
          timestamp: now.add(Duration(milliseconds: order)),
          complexMetadata: metaStr,
          priority: null,
          supersetGroupId: null,
          supersetName: null,
        );
        final newTr = drift.TypedResult({
          db.workoutSets: newSet,
          db.baseExercises: ex,
          db.workoutLogs: log,
        }, drift.QueryRow({}, db));
        widget.results.add(newTr);
      }
    });
    // Also add to notifier for persistence
    final notifier = ref.read(wbEditorProvider.notifier);
    final knsId = ref
        .read(wbEditorProvider)
        .knsEntries
        .firstWhere((k) => k.baseExerciseId == widget.exercise.id,
            orElse: () => WbEditorKns(
                id: 0,
                baseExerciseId: 0,
                exerciseName: '',
                orderIndex: 0,
                prefixes: null,
                suffixes: null,
                bodyPositions: null,
                implements: null))
        .id;
    if (knsId != 0) {
      for (final def in newSetDefs) {
        final setId = def['id'] as int;
        final side = def['side'] as String?;
        // setNumber = current count + 1 after each addition
        final currentCount = ref
            .read(wbEditorProvider)
            .knsEntries
            .firstWhere((k) => k.id == knsId,
                orElse: () => WbEditorKns(
                    id: 0,
                    baseExerciseId: 0,
                    exerciseName: '',
                    orderIndex: 0,
                    prefixes: null,
                    suffixes: null,
                    bodyPositions: null,
                    implements: null))
            .sets
            .length;
        notifier.addSetToKns(knsId,
            WbEditorSet(id: setId, setNumber: currentCount + 1, side: side));
      }
    }
  }

  void _confirmPurge(BuildContext c) {
    showDialog(
        context: c,
        builder: (c) => AlertDialog(
                backgroundColor: LabColors.background,
                title: Text('PURGE_MODULE',
                    style: LabStyles.mono(context,
                        color: Colors.redAccent, fontWeight: FontWeight.bold)),
                content: Text('DELETE ALL SETS?',
                    style: LabStyles.mono(context, fontSize: 12)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c),
                      child: Text('ABORT', style: LabStyles.mono(context))),
                  TextButton(
                      onPressed: () {
                        final kId = ref
                            .read(wbEditorProvider)
                            .knsEntries
                            .firstWhere(
                                (k) => k.baseExerciseId == widget.exercise.id,
                                orElse: () => WbEditorKns(
                                    id: 0,
                                    baseExerciseId: 0,
                                    exerciseName: '',
                                    orderIndex: 0,
                                    prefixes: null,
                                    suffixes: null,
                                    bodyPositions: null,
                                    implements: null))
                            .id;
                        if (kId != 0)
                          ref.read(wbEditorProvider.notifier).removeKns(kId);
                        ref.read(knsVersionProvider.notifier).state++;
                        if (context.mounted) Navigator.pop(c);
                      },
                      child: Text('PURGE',
                          style:
                              LabStyles.mono(context, color: Colors.redAccent)))
                ]));
  }

  Future<void> _copyPreviousWorkoutData() async {
    final db = ref.read(databaseProvider);
    final today =
        DateTime(widget.date.year, widget.date.month, widget.date.day);

    // 1. Find the most recent date before today for this exercise
    final previousSessionRows = await (db.select(db.workoutSets).join([
      drift.innerJoin(
          db.workoutLogs, db.workoutLogs.id.equalsExp(db.workoutSets.logId))
    ])
          ..where(db.workoutSets.baseExerciseId.equals(widget.exercise.id) &
              db.workoutLogs.date.isSmallerThanValue(today))
          ..orderBy([
            drift.OrderingTerm.desc(db.workoutLogs.date),
            drift.OrderingTerm.asc(db.workoutSets.orderIndex),
            drift.OrderingTerm.asc(db.workoutSets.timestamp)
          ]))
        .get();

    if (previousSessionRows.isEmpty) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("NO_PREVIOUS_SESSION_FOUND")));
      return;
    }

    // Group previous sets by their date to get ONLY the most recent one
    final lastDate = previousSessionRows.first.readTable(db.workoutLogs).date;
    final lastSets = previousSessionRows
        .where((r) => r.readTable(db.workoutLogs).date == lastDate)
        .toList();

    // 2. Map current sets
    final currentSets =
        widget.results.map((r) => r.readTable(db.workoutSets)).toList();

    // 3. Update today's sets with previous values
    await db.transaction(() async {
      for (int i = 0; i < currentSets.length; i++) {
        if (i < lastSets.length) {
          final prevSet = lastSets[i].readTable(db.workoutSets);
          await (db.update(db.workoutSets)
                ..where((t) => t.id.equals(currentSets[i].id)))
              .write(WorkoutSetsCompanion(
            weight: drift.Value(prevSet.weight),
            reps: drift.Value(prevSet.reps),
          ));
        }
      }
    });

    if (mounted)
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("PREVIOUS_DATA_COPIED")));
  }
}

class _WorkoutSetInstance extends ConsumerStatefulWidget {
  final WorkoutSet set;
  final WorkoutLog log;
  final BaseExercise exercise;
  final int index;
  final int globalIndex;
  final double bodyWeight;
  final String? side;
  final int knsId;
  const _WorkoutSetInstance(
      {super.key,
      required this.set,
      required this.log,
      required this.exercise,
      required this.index,
      required this.globalIndex,
      required this.bodyWeight,
      this.side,
      this.knsId = 0});
  @override
  ConsumerState<_WorkoutSetInstance> createState() =>
      _WorkoutSetInstanceState();
}

class _WorkoutSetInstanceState extends ConsumerState<_WorkoutSetInstance> {
  late TextEditingController _lC,
      _rC,
      _rpeC,
      _rirC,
      _ploadC,
      _commentC;
  Timer? _db;
  bool _exp = false;
  bool _showComment = false;
  bool _isIso = false;
  final List<String> _setTags = [];
  final List<String> _availableTags = [
    'TOP_SET',
    'BACKOFF',
    'MAIN_LIFT',
    'ASSISTANCE',
    'WEAKNESS',
    'PRIMER',
    'MEAT',
    'FEEDER',
    'WARMUP'
  ];
  String? _currentIntent;

  @override
  void initState() {
    super.initState();
    _initControllers(widget.set);
  }

  @override
  void didUpdateWidget(_WorkoutSetInstance oldWidget) {
    super.didUpdateWidget(oldWidget);
    debugPrint(
        '[WB_DIDUPDATE] oldId=${oldWidget.set.id} newId=${widget.set.id} oldW=${oldWidget.set.weight} newW=${widget.set.weight}');
    _lC.text = widget.set.technique?.toString() ?? '';
    _rC.text = widget.set.reps.toString();
    _rpeC.text = widget.set.rpe?.toString() ?? '';
    _rirC.text = widget.set.rir?.toString() ?? '';
    _ploadC.text = widget.set.weight.toString();
    _setTags.clear();
    if (widget.set.notes != null && widget.set.notes!.isNotEmpty) {
      _setTags.addAll(widget.set.notes!.split(',').where((t) => t.isNotEmpty));
    }
    _currentIntent = null;
    if (widget.set.complexMetadata != null) {
      try {
        final meta = jsonDecode(widget.set.complexMetadata!);
        if (meta['intention'] != null)
          _currentIntent = meta['intention'].toString();
      } catch (_) {}
    }
  }

  void _initControllers(WorkoutSet set) {
    _lC = TextEditingController(text: set.technique?.toString() ?? '');
    _rC = TextEditingController(text: set.reps.toString());
    _rpeC = TextEditingController(text: set.rpe?.toString() ?? '');
    _rirC = TextEditingController(text: set.rir?.toString() ?? '');
    _ploadC = TextEditingController(text: set.weight.toString());
    _commentC = TextEditingController(text: set.notes);
    // Restore tags from notes (backward compat)
    _setTags.clear();
    if (set.notes != null && set.notes!.isNotEmpty) {
      _setTags.addAll(set.notes!.split(',').where((t) => t.isNotEmpty));
    }
    // Restore intent from complexMetadata intention key
    if (set.complexMetadata != null) {
      try {
        final meta = jsonDecode(set.complexMetadata!);
        if (meta['intention'] != null)
          _currentIntent = meta['intention'].toString();
      } catch (_) {}
    }

    final intentionText = widget.exercise.intention ?? '';
    final metaMatch =
        RegExp(r'\[NT:(.*)\|ISO:(.*)\]').firstMatch(intentionText);
    final isJst =
        (metaMatch?.group(1) == 'JST.BW') || widget.exercise.field == 'JST.BW';
    // Isometric detection for conditional UI
    _isIso = (metaMatch?.group(2) == 'true') ||
        intentionText.startsWith('[ISO]') ||
        widget.exercise.parsedComplexMetadata['isIsometric'] == true;
  }

  @override
  void dispose() {
    _db?.cancel();
    _lC.dispose();
    _rC.dispose();
    _rpeC.dispose();
    _rirC.dispose();
    _ploadC.dispose();
    _commentC.dispose();
    super.dispose();
  }

  void _onChanged() {
    _db?.cancel();
    _db = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      final notifier = ref.read(wbEditorProvider.notifier);
      final db = ref.read(databaseProvider);
      final m = double.tryParse(_lC.text);
      final mx = double.tryParse(_rC.text);
      final p = double.tryParse(_ploadC.text);
      final rpe = double.tryParse(_rpeC.text);
      final rir = double.tryParse(_rirC.text);
      debugPrint(
          '[WB_ONCHANGED] kid=${widget.knsId} sid=${widget.set.id} min=$m max=$mx pload=$p intent=$_currentIntent');
      // Update StateNotifier for UI reactivity
      notifier.updateSet(
        widget.knsId,
        widget.set.id,
        minReps: m,
        maxReps: mx,
        pload: p,
        rpe: rpe,
        rir: rir,
        intention: _currentIntent,
      );
      // Write DIRECTLY to real workout_block_sets table (fire-and-forget)
      unawaited((() async {
        try {
          // UPDATE existing row (row created by _save() which has correct kns_id)
          await (db.update(db.workoutBlockSets)
                ..where((t) => t.id.equals(widget.set.id)))
              .write(WorkoutBlockSetsCompanion(
            repsMin: drift.Value(m),
            repsMax: drift.Value(mx),
            pload: drift.Value(p),
            rpe: drift.Value(rpe),
            rir: drift.Value(rir),
            setIntention: drift.Value(_currentIntent),
          ));
          debugPrint('[WB_DB_UPDATE] ok setId=${widget.set.id} pload=$p');
        } catch (e) {
          debugPrint('[WB_DB_UPDATE] error: $e');
        }
      })());
    });
  }

  void _showComplexSetModsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: LabColors.background,
      isScrollControlled: true,
      builder: (c) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('COMPLEX_SET_MODS',
                  style: LabStyles.headline(context).copyWith(fontSize: 16)),
              const SizedBox(height: 24),

              // --- ACTION SECTION ---
              _buildModCard(context, 'PURGE_SET', Icons.delete_forever,
                  Colors.redAccent, () => _confirmDel(context)),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModalGridInput(
      BuildContext context, String l, TextEditingController c) {
    return Container(
        decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[800]!, width: 0.5)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4),
              color: LabColors.surfaceContainerHigh,
              child: Text(l,
                  textAlign: TextAlign.center,
                  style: LabStyles.mono(context,
                      fontSize: 8, color: Colors.grey))),
          Container(
              height: 44,
              alignment: Alignment.center,
              child: TextField(
                  controller: c,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: LabStyles.mono(context,
                      fontSize: 20, color: Colors.white),
                  decoration: const InputDecoration(
                      border: InputBorder.none, isDense: true),
                  onChanged: (_) => _onChanged()))
        ]));
  }

  Widget _buildModCard(BuildContext context, String label, IconData icon,
      Color color, VoidCallback onTap) {
    return Material(
      color: LabColors.surfaceContainerHigh,
      child: InkWell(
        onTap: () {
          onTap();
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(label,
                style: LabStyles.mono(context,
                    fontSize: 8, color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Future<void> _moveSetToExtreme(bool toTop) async {
    final db = ref.read(databaseProvider);
    final today = DateTime(widget.set.timestamp.year,
        widget.set.timestamp.month, widget.set.timestamp.day);
    final nextDay = today.add(const Duration(days: 1));
    final sets = await (db.select(db.workoutSets)
          ..where((t) =>
              t.baseExerciseId.equals(widget.exercise.id) &
              t.timestamp.isBetweenValues(today, nextDay))
          ..orderBy([
            (t) => drift.OrderingTerm.asc(t.orderIndex),
            (t) => drift.OrderingTerm.asc(t.timestamp)
          ]))
        .get();

    final currentIndex = sets.indexWhere((s) => s.id == widget.set.id);
    if (currentIndex == -1) return;

    final List<int> ids = sets.map((s) => s.id).toList();
    final targetId = ids.removeAt(currentIndex);
    if (toTop) {
      ids.insert(0, targetId);
    } else {
      ids.add(targetId);
    }

    await db.transaction(() async {
      for (int i = 0; i < ids.length; i++) {
        await (db.update(db.workoutSets)..where((t) => t.id.equals(ids[i])))
            .write(WorkoutSetsCompanion(orderIndex: drift.Value(i)));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final intentionText = widget.exercise.intention ?? '';
    final metaMatch =
        RegExp(r'\[NT:(.*)\|ISO:(.*)\]').firstMatch(intentionText);
    final isL =
        (metaMatch?.group(1) == 'LASTRE') || widget.exercise.field == 'LASTRE';
    final isJst =
        (metaMatch?.group(1) == 'JST.BW') || widget.exercise.field == 'JST.BW';
    final w = isJst ? widget.bodyWeight : (double.tryParse(_lC.text) ?? 0);
    final tL = w + (isL ? widget.bodyWeight : 0);
    final isRed = (widget.set.trackName ?? '').contains('[RED_PR]');
    const completedColor =
        Colors.greenAccent; // Neon green for better visibility

    final settings = ref.watch(themeSettingsProvider).value ?? {};
    final tC = ref.read(themeControllerProvider);
    Color? sideColor;
    if (widget.side == "RIGHT") {
      sideColor =
          tC.getColor(settings, "UI_UNILATERAL_RIGHT", nameSeed: "RIGHT");
    } else if (widget.side == "LEFT") {
      sideColor = tC.getColor(settings, "UI_UNILATERAL_LEFT", nameSeed: "LEFT");
    }

    return Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  decoration: BoxDecoration(
                      border: Border.all(
                          color: _exp
                              ? LabColors.primary.withValues(alpha: 0.4)
                              : Colors.grey[800]!,
                          width: 0.5),
                      color: _exp
                          ? LabColors.surfaceContainerLow
                          : Colors.transparent),
                  child: IntrinsicHeight(
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                        _buildSetNumberWithCheckbox(completedColor,
                            (widget.index + 1).toString().padLeft(2, '0'),
                            flex: 15, sideColor: sideColor),
                        _buildGridInput(_isIso ? 'MIN SEC' : 'MIN REPS', _lC,
                            flex: 25),
                        _buildGridInput('P.LOAD', _ploadC, flex: 25),
                        _buildGridInput(_isIso ? 'MAX SEC' : 'MAX REPS', _rC,
                            flex: 25),
                      ]))),
              if (_showComment)
                Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: LabColors.surfaceDim,
                        border: Border(
                            left: const BorderSide(
                                color: LabColors.primary, width: 1),
                            bottom: BorderSide(
                                color: Colors.grey[900]!, width: 0.5),
                            right: BorderSide(
                                color: Colors.grey[900]!, width: 0.5))),
                    child: TextField(
                        controller: _commentC,
                        maxLines: null,
                        style: LabStyles.mono(context,
                            fontSize: 10, color: Colors.white),
                        decoration: InputDecoration(
                            hintText: 'WRITE_SESSION_INTEL...',
                            hintStyle: LabStyles.mono(context,
                                fontSize: 8, color: Colors.grey[700]!),
                            border: InputBorder.none,
                            isDense: true),
                        onChanged: (_) => _onChanged())),
              if (_exp) ...[
                const SizedBox(height: 12),
                Row(children: [
                  _buildSummaryBox(
                      'TONNAGE',
                      (tL * (double.tryParse(_rC.text) ?? 0))
                          .toStringAsFixed(1)),
                  const SizedBox(width: 4),
                  _buildSummaryBox(
                      'eORM',
                      WorkoutCalculator.calculateEpley1RM(
                              tL, double.tryParse(_rC.text) ?? 0)
                          .toStringAsFixed(1)),
                ]),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[700]!, width: 0.5),
                    color: LabColors.surfaceContainerLow,
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        _buildGridInput('RPE', _rpeC, flex: 1, noBorder: true),
                        if (!_isIso) ...[
                          Container(width: 0.5, color: Colors.grey[700]),
                          _buildGridInput('RIR', _rirC,
                              flex: 1, noBorder: true),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Set-level metadata button + intent chip
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white12, width: 0.5),
                    color: LabColors.surfaceContainerLow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('SET INTENT',
                              style: LabStyles.mono(context,
                                  fontSize: 7, color: Colors.grey[500])),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => _showSetIntentPicker(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: Colors.white24, width: 0.5),
                              ),
                              child: Text('SET INTENT',
                                  style: LabStyles.mono(context,
                                      fontSize: 7, color: Colors.grey[500])),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_currentIntent != null)
                        GestureDetector(
                          onTap: () => _showSetIntentPicker(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: LabColors.primary.withValues(alpha: 0.15),
                              border: Border.all(
                                  color: LabColors.primary, width: 0.5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                        color: _intentColor(),
                                        shape: BoxShape.circle)),
                                const SizedBox(width: 6),
                                Text(_currentIntent!,
                                    style: LabStyles.mono(context,
                                        fontSize: 8,
                                        color: LabColors.primary,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _currentIntent = null;
                                    });
                                    _onChanged();
                                  },
                                  child: Icon(Icons.close,
                                      size: 10, color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        GestureDetector(
                          onTap: () => _showSetIntentPicker(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: Colors.grey[700]!, width: 0.5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add,
                                    size: 10, color: Colors.grey[500]),
                                const SizedBox(width: 4),
                                Text('SET INTENT',
                                    style: LabStyles.mono(context,
                                        fontSize: 7, color: Colors.grey[500])),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12), _buildParticularTogglesCard(),
                const SizedBox(height: 20),
              ]
            ])));
  }

  Color _intentColor() {
    try {
      final defs = ref.read(setIntentionsProvider).valueOrNull ?? [];
      final match = defs.where((d) => d.name == _currentIntent);
      if (match.isNotEmpty) {
        final hex = match.first.color.replaceAll('#', '');
        if (hex.length == 6) {
          return Color(int.parse('FF$hex', radix: 16));
        }
      }
    } catch (_) {}
    return LabColors.primary;
  }

  void _showSetIntentPicker(BuildContext context) {
    final intentsAsync = ref.read(setIntentionsProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: LabColors.background,
      isScrollControlled: true,
      builder: (c) => _SetIntentPicker(
        currentIntent: _currentIntent,
        onSelected: (intentName) {
          setState(() {
            _currentIntent = intentName;
          });
          _onChanged();
        },
      ),
    );
  }

  Widget _buildModsTrigger({required int flex}) {
    return Expanded(
      flex: flex,
      child: Material(
        color: LabColors.surfaceContainerHigh,
        child: InkWell(
          onTap: () => _showComplexSetModsModal(context),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(
                  left: BorderSide(color: Colors.grey[800]!, width: 0.5)),
            ),
            child:
                const Icon(Icons.more_vert, color: LabColors.primary, size: 18),
          ),
        ),
      ),
    );
  }

  Widget _buildParticularTogglesCard() {
    final Map<String, dynamic> exerciseMeta =
        widget.exercise.parsedComplexMetadata;
    final List<dynamic> rawToggles = exerciseMeta["particular_toggles"] ?? [];

    if (rawToggles.isEmpty) return const SizedBox.shrink();

    // Map new format or legacy string format to just names for the UI list
    final List<String> availableToggles = rawToggles
        .map((t) => (t is Map) ? (t["name"] as String) : (t.toString()))
        .toList();

    Map<String, dynamic> setMeta = {};
    if (widget.set.complexMetadata != null &&
        widget.set.complexMetadata!.isNotEmpty) {
      try {
        setMeta = jsonDecode(widget.set.complexMetadata!);
      } catch (_) {}
    }
    final Map<String, bool> states = {
      for (var t in availableToggles) t: (setMeta[t] == true)
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LabColors.surfaceContainerLow,
        border: Border.all(
            color: Colors.cyanAccent.withValues(alpha: 0.1), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TOGGLES',
              style: LabStyles.mono(context, fontSize: 8, color: Colors.grey)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: availableToggles.map((t) {
              final active = states[t] ?? false;
              return GestureDetector(
                onTap: () => _toggleParticularValue(t, !active),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: active
                        ? Colors.cyanAccent.withValues(alpha: 0.2)
                        : Colors.black,
                    border: Border.all(
                        color: active ? Colors.cyanAccent : Colors.grey[800]!,
                        width: 0.5),
                  ),
                  child: Text(
                    t,
                    style: LabStyles.mono(context,
                        fontSize: 8,
                        color: active ? Colors.cyanAccent : Colors.grey[400]!),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleParticularValue(String key, bool value) async {
    Map<String, dynamic> setMeta = {};
    if (widget.set.complexMetadata != null &&
        widget.set.complexMetadata!.isNotEmpty) {
      try {
        setMeta = jsonDecode(widget.set.complexMetadata!);
      } catch (_) {}
    }
    setMeta[key] = value;
    final db = ref.read(databaseProvider);
    await (db.update(db.workoutSets)..where((t) => t.id.equals(widget.set.id)))
        .write(WorkoutSetsCompanion(
            complexMetadata: drift.Value(jsonEncode(setMeta))));
  }

  Widget _buildNotesToggleCard() {
    final hasNotes = widget.set.notes?.isNotEmpty ?? false;
    return InkWell(
        onTap: () => setState(() => _showComment = !_showComment),
        child: Container(
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                border:
                    Border.all(color: LabColors.primary.withValues(alpha: 0.5)),
                color: _showComment
                    ? LabColors.primary.withValues(alpha: 0.05)
                    : Colors.transparent),
            child: Text(
                hasNotes ? '[ ! ] EDIT SET NOTES' : '[ + ] ADD SET NOTES',
                textAlign: TextAlign.center,
                style: LabStyles.mono(context,
                    fontSize: 8, color: LabColors.primary))));
  }

  Widget _buildSetNumberWithCheckbox(Color completedColor, String value,
      {int flex = 2, Color? sideColor}) {
    final globalNum = widget.globalIndex;
    return Expanded(
      flex: flex,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            border:
                Border(right: BorderSide(color: Colors.grey[800]!, width: 0.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // TOP: Global set number (session-wide)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 4),
                color: LabColors.surfaceContainerHigh,
                alignment: Alignment.center,
                child: Text(
                  "#$globalNum",
                  style:
                      LabStyles.mono(context, fontSize: 8, color: Colors.grey),
                ),
              ),
              // BOTTOM: Intra-card Set Number + Checkbox
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _exp = !_exp),
                  child: Container(
                    alignment: Alignment.center,
                    child: Text(
                      value,
                      style: LabStyles.mono(context,
                          fontSize: 18,
                          color: sideColor ?? Colors.white,
                          fontWeight: sideColor != null
                              ? FontWeight.bold
                              : FontWeight.normal),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReorderColumn() {
    return Container(
      width: 32,
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: Colors.grey[800]!, width: 0.5)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildReorderArrow(Icons.arrow_drop_up, -1),
          _buildReorderArrow(Icons.arrow_drop_down, 1),
        ],
      ),
    );
  }

  Widget _buildReorderArrow(IconData icon, int offset) {
    return Expanded(
      child: InkWell(
        onTap: () => _moveSet(offset),
        child: Icon(icon,
            size: 16, color: LabColors.primary.withValues(alpha: 0.5)),
      ),
    );
  }

  Future<void> _moveSet(int direction) async {
    final db = ref.read(databaseProvider);
    final today = DateTime(widget.set.timestamp.year,
        widget.set.timestamp.month, widget.set.timestamp.day);
    final nextDay = today.add(const Duration(days: 1));
    final sets = await (db.select(db.workoutSets)
          ..where((t) =>
              t.baseExerciseId.equals(widget.exercise.id) &
              t.timestamp.isBetweenValues(today, nextDay))
          ..orderBy([
            (t) => drift.OrderingTerm.asc(t.orderIndex),
            (t) => drift.OrderingTerm.asc(t.timestamp)
          ]))
        .get();

    final currentIndex = sets.indexWhere((s) => s.id == widget.set.id);
    if (currentIndex == -1) return;
    final targetIndex = currentIndex + direction;
    if (targetIndex < 0 || targetIndex >= sets.length) return;

    final currentSet = sets[currentIndex];
    final otherSet = sets[targetIndex];

    int currentOrder =
        currentSet.orderIndex == 0 ? currentIndex : currentSet.orderIndex;
    int otherOrder =
        otherSet.orderIndex == 0 ? targetIndex : otherSet.orderIndex;
    if (currentOrder == otherOrder) {
      currentOrder = currentIndex;
      otherOrder = targetIndex;
    }

    await (db.update(db.workoutSets)..where((t) => t.id.equals(currentSet.id)))
        .write(WorkoutSetsCompanion(orderIndex: drift.Value(otherOrder)));
    await (db.update(db.workoutSets)..where((t) => t.id.equals(otherSet.id)))
        .write(WorkoutSetsCompanion(orderIndex: drift.Value(currentOrder)));
  }

  Widget _buildPRBox({int flex = 1, bool isRed = false}) {
    final hasPr = widget.set.isPr;
    final settings = ref.watch(themeSettingsProvider).value ?? {};
    final highlightColor = ref
        .read(themeControllerProvider)
        .getColor(settings, 'UI_EORM_HIGHLIGHT', nameSeed: 'EORM_HIGHLIGHT');
    const completedColor = Colors.greenAccent;

    return Expanded(
        flex: flex,
        child: Container(
            decoration: BoxDecoration(
                border: Border(
                    right: BorderSide(color: Colors.grey[800]!, width: 0.5))),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // TOP: PR label
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 4),
                color: isRed
                    ? highlightColor.withValues(alpha: 0.2)
                    : (hasPr
                        ? Colors.white.withValues(alpha: 0.05)
                        : LabColors.surfaceContainerHigh),
                child: Text('PR',
                    textAlign: TextAlign.center,
                    style: LabStyles.mono(context,
                        fontSize: 8,
                        color: isRed
                            ? Colors.white
                            : (hasPr ? LabColors.accent : Colors.grey))),
              ),
              // BOTTOM: Trophy / empty
              Container(
                  height: 44,
                  alignment: Alignment.center,
                  child: hasPr
                      ? (isRed
                          ? Icon(Icons.emoji_events,
                              color: highlightColor, size: 24)
                          : ShaderMask(
                              shaderCallback: (bounds) =>
                                  const LinearGradient(colors: [
                                    Colors.red,
                                    Colors.orange,
                                    Colors.yellow,
                                    Colors.green,
                                    Colors.blue,
                                    Colors.purple
                                  ]).createShader(bounds),
                              child: const Icon(Icons.emoji_events,
                                  color: Colors.white, size: 20)))
                      : const SizedBox())
            ])));
  }

  Widget _buildSummaryBox(String l, String v) {
    return Expanded(
        child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            decoration: BoxDecoration(
                color: LabColors.surfaceDim,
                border: Border.all(
                    color: LabColors.cyanBorder.withValues(alpha: 0.1),
                    width: 0.5)),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l,
                      style: LabStyles.mono(context,
                          fontSize: 7, color: Colors.grey)),
                  Text(v,
                      style: LabStyles.mono(context,
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold))
                ])));
  }

  Widget _buildGridInput(String l, TextEditingController c,
      {int flex = 1, bool enabled = true, bool noBorder = false}) {
    return Expanded(
        flex: flex,
        child: Material(
            color: Colors.transparent,
            child: Container(
            decoration: BoxDecoration(
                border: noBorder
                    ? null
                    : Border(
                        right:
                            BorderSide(color: Colors.grey[800]!, width: 0.5))),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  color: LabColors.surfaceContainerHigh,
                  child: Text(l,
                      textAlign: TextAlign.center,
                      style: LabStyles.mono(context,
                          fontSize: 8, color: Colors.grey))),
              Container(
                  height: 44,
                  alignment: Alignment.center,
                  child: TextField(
                      controller: c,
                      enabled: enabled,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: LabStyles.mono(context,
                          fontSize: 20,
                          color: enabled ? Colors.white : Colors.grey),
                      decoration: const InputDecoration(
                          border: InputBorder.none, isDense: true),
                      onChanged: (_) => _onChanged()))
            ]))));
  }

  void _confirmDel(BuildContext c) {
    showDialog(
        context: c,
        builder: (c) => AlertDialog(
                backgroundColor: LabColors.background,
                title: Text('PURGE_SET',
                    style: LabStyles.mono(context, color: Colors.redAccent)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c),
                      child: const Text('ABORT')),
                  TextButton(
                      onPressed: () {
                        final notifier = ref.read(wbEditorProvider.notifier);
                        notifier.removeSet(widget.knsId, widget.set.id);
                        Navigator.pop(c);
                      },
                      child: const Text('PURGE'))
                ]));
  }

  Widget _buildFailurePhaseCard() {
    Map<String, dynamic> phs = {};
    if (widget.exercise.phaseDescriptions != null) {
      try {
        final Map<String, dynamic> meta =
            jsonDecode(widget.exercise.phaseDescriptions!);
        phs = meta["phases"] as Map<String, dynamic>? ?? {};
      } catch (_) {}
    }
    final cnt = widget.exercise.numPhases ?? (phs.isEmpty ? 1 : phs.length);
    return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: LabColors.surfaceContainerLow,
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.1), width: 0.5)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('FAILURE PHASE',
              style: LabStyles.mono(context, fontSize: 8, color: Colors.grey)),
          const SizedBox(height: 12),
          GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisExtent: 40,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8),
              itemCount: cnt,
              itemBuilder: (c, i) {
                final pI = i + 1;
                final sel = widget.set.failurePhase == pI;
                final name = (phs[pI.toString()] ?? 'PHASE_$pI')
                    .toString()
                    .toUpperCase();
                return GestureDetector(
                    onTap: () async {
                      await (ref
                              .read(databaseProvider)
                              .update(ref.read(databaseProvider).workoutSets)
                            ..where((t) => t.id.equals(widget.set.id)))
                          .write(WorkoutSetsCompanion(
                              failurePhase: drift.Value(pI)));
                    },
                    child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                            color: sel
                                ? LabColors.primary.withValues(alpha: 0.2)
                                : Colors.black,
                            border: Border.all(
                                color:
                                    sel ? LabColors.primary : Colors.grey[800]!,
                                width: 0.5)),
                        child: Center(
                            child: Text(name,
                                style: LabStyles.mono(context,
                                    fontSize: 8,
                                    color: sel
                                        ? LabColors.primary
                                        : Colors.grey[400]!)))));
              })
        ]));
  }

  Widget _buildSomaticCard() {
    final db = ref.read(databaseProvider);
    return FutureBuilder<List<drift.QueryRow>>(
        future: db
            .customSelect(
                "SELECT id, description, spectrum_value, tags FROM somatic_logs WHERE set_id = ${widget.set.id} ORDER BY created_at DESC")
            .get(),
        builder: (context, snapshot) {
          final allLogs = snapshot.data ?? [];
          final anomalies = allLogs
              .where((r) => (r.data['spectrum_value'] as int) < 0)
              .toList();
          final recoveries = allLogs
              .where((r) => (r.data['spectrum_value'] as int) > 0)
              .toList();

          return Row(
            children: [
              Expanded(
                child: anomalies.isEmpty
                    ? InkWell(
                        onTap: () => _showDiscomfortOverlay(context, false),
                        child: Container(
                          height: 52,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              border: Border.all(
                                  color:
                                      Colors.redAccent.withValues(alpha: 0.5))),
                          child: Text('[ + ] SOMATIC ANOMALY',
                              textAlign: TextAlign.center,
                              style: LabStyles.mono(context,
                                  fontSize: 8, color: Colors.redAccent)),
                        ),
                      )
                    : InkWell(
                        onTap: () => _showDiscomfortOverlay(context, false),
                        child: Container(
                          height: 52,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.1),
                              border: Border.all(
                                  color: Colors.redAccent, width: 1)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                  child: Text(
                                      'SOMATIC_ANOMALIES: ${anomalies.length}',
                                      style: LabStyles.mono(context,
                                          fontSize: 7,
                                          color: Colors.redAccent,
                                          fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis)),
                              Text('EDIT',
                                  style: LabStyles.mono(context,
                                      fontSize: 7,
                                      color: Colors.white70,
                                      decoration: TextDecoration.underline)),
                            ],
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: recoveries.isEmpty
                    ? InkWell(
                        onTap: () => _showDiscomfortOverlay(context, true),
                        child: Container(
                          height: 52,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              border: Border.all(
                                  color: Colors.greenAccent
                                      .withValues(alpha: 0.5))),
                          child: Text('[ + ] SOMATIC RECOVERY',
                              textAlign: TextAlign.center,
                              style: LabStyles.mono(context,
                                  fontSize: 8, color: Colors.greenAccent)),
                        ),
                      )
                    : InkWell(
                        onTap: () => _showDiscomfortOverlay(context, true),
                        child: Container(
                          height: 52,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                              color: Colors.greenAccent.withValues(alpha: 0.1),
                              border: Border.all(
                                  color: Colors.greenAccent, width: 1)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                  child: Text(
                                      'SOMATIC_RECOVERIES: ${recoveries.length}',
                                      style: LabStyles.mono(context,
                                          fontSize: 7,
                                          color: Colors.greenAccent,
                                          fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis)),
                              Text('EDIT',
                                  style: LabStyles.mono(context,
                                      fontSize: 7,
                                      color: Colors.white70,
                                      decoration: TextDecoration.underline)),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          );
        });
  }

  void _showDiscomfortOverlay(BuildContext context, bool isRecovery) {
    final db = ref.read(databaseProvider);
    final dC = TextEditingController();
    final tC = TextEditingController();
    int selectedIntensity = 5;
    int? editingLogId;
    int? _selectedFolderId;

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (c) => StatefulBuilder(
            builder: (context, setModalState) => Container(
                height: MediaQuery.of(context).size.height * 0.85,
                decoration: BoxDecoration(
                    color: LabColors.background,
                    border: Border(
                        top: BorderSide(
                            color: isRecovery
                                ? Colors.greenAccent
                                : Colors.redAccent,
                            width: 2))),
                padding: const EdgeInsets.all(24),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              editingLogId != null
                                  ? 'EDIT'
                                  : (isRecovery
                                      ? 'SOMATIC_RECOVERY_REGISTRATION'
                                      : 'SOMATIC_ANOMALY_REGISTRATION'),
                              style: LabStyles.headline(context,
                                      color: isRecovery
                                          ? Colors.greenAccent
                                          : Colors.redAccent)
                                  .copyWith(fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (editingLogId != null)
                            TextButton(
                              onPressed: () => setModalState(() {
                                editingLogId = null;
                                dC.clear();
                                tC.clear();
                                selectedIntensity = 5;
                              }),
                              child: Text("CANCEL_EDIT",
                                  style: LabStyles.mono(context,
                                      fontSize: 8, color: Colors.orangeAccent)),
                            ),
                          IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close,
                                  color: Colors.grey, size: 20)),
                        ],
                      ),
                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Text(
                              isRecovery
                                  ? 'SPECTRUM_VALUE'
                                  : 'INTENSITY_LEVEL (1-10)',
                              style: LabStyles.mono(context,
                                  fontSize: 8,
                                  color: isRecovery
                                      ? Colors.greenAccent
                                      : Colors.grey)),
                          const Spacer(),
                          GestureDetector(
                            onTap: () =>
                                _showSpectrumReferencePopup(context, db),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                  border: Border.all(
                                      color: isRecovery
                                          ? Colors.greenAccent
                                              .withValues(alpha: 0.3)
                                          : Colors.redAccent
                                              .withValues(alpha: 0.3),
                                      width: 0.5)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.info_outline,
                                      size: 10,
                                      color: isRecovery
                                          ? Colors.greenAccent
                                          : Colors.redAccent),
                                  const SizedBox(width: 4),
                                  Text('REF',
                                      style: LabStyles.mono(context,
                                          fontSize: 7,
                                          color: isRecovery
                                              ? Colors.greenAccent
                                              : Colors.redAccent)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(10, (i) {
                            final val = i + 1;
                            final isSelected = selectedIntensity >= val;
                            return GestureDetector(
                                onTap: () => setModalState(
                                    () => selectedIntensity = val),
                                child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                        color: isSelected
                                            ? (isRecovery
                                                ? Colors.greenAccent
                                                : Colors.redAccent)
                                            : Colors.transparent,
                                        border: Border.all(
                                            color: isRecovery
                                                ? Colors.greenAccent
                                                : Colors.redAccent,
                                            width: 0.5)),
                                    child: Center(
                                        child: Text("$val",
                                            style: LabStyles.mono(context,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: isSelected
                                                    ? Colors.black
                                                    : Colors.white)))));
                          })),
                      const SizedBox(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                              child: LabTextField(
                                  controller: dC, label: 'DESCRIPTION')),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 48,
                            height: 42,
                            child: QuickActionButton(
                              label: "SEARCH",
                              icon: Icons.search,
                              color: LabColors.accent,
                              onTap: () async {
                                final rows = await db.executor.runSelect(
                                  "SELECT DISTINCT description FROM somatic_logs WHERE description IS NOT NULL AND description != ''",
                                  [],
                                );
                                final descs = rows
                                    .map((r) => r['description'] as String)
                                    .toList()
                                  ..sort();
                                if (!context.mounted) return;
                                showModalBottomSheet(
                                  context: context,
                                  backgroundColor: LabColors.background,
                                  isScrollControlled: true,
                                  builder: (c) => QualitySearchPicker(
                                    title: "SELECT_DESCRIPTION",
                                    values: descs,
                                    onSelected: (val) =>
                                        setModalState(() => dC.text = val),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                              child: LabTextField(
                                  controller: tC,
                                  label: 'TAGS (COMMA_SEPARATED)')),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 48,
                            height: 42,
                            child: QuickActionButton(
                              label: "SEARCH",
                              icon: Icons.tag,
                              color: Colors.purpleAccent,
                              onTap: () async {
                                final rows = await db.executor.runSelect(
                                  "SELECT DISTINCT tags FROM somatic_logs WHERE tags IS NOT NULL AND tags != ''",
                                  [],
                                );
                                final tagNames = rows
                                    .expand((r) => ((r['tags'] ?? '') as String)
                                        .split(RegExp(r',\s*'))
                                        .where((t) => t.trim().isNotEmpty))
                                    .map((t) => t.trim())
                                    .toSet()
                                    .toList()
                                  ..sort();
                                if (!context.mounted) return;
                                showModalBottomSheet(
                                  context: context,
                                  backgroundColor: LabColors.background,
                                  isScrollControlled: true,
                                  builder: (c) => QualitySearchPicker(
                                    title: "SELECT_TAG",
                                    values: tagNames,
                                    onSelected: (val) {
                                      setModalState(() {
                                        final current = tC.text
                                            .split(RegExp(r',\s*'))
                                            .where((t) => t.trim().isNotEmpty)
                                            .toList();
                                        if (!current.contains(val)) {
                                          current.add(val);
                                          tC.text = current.join(", ");
                                        }
                                      });
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      // Folder picker
                      Row(
                        children: [
                          Expanded(
                            child: FutureBuilder<List<drift.QueryRow>>(
                              future: db
                                  .customSelect(
                                      'SELECT id, name FROM somatic_folders ORDER BY name')
                                  .get(),
                              builder: (c, snap) {
                                final folders = snap.data ?? [];
                                return DropdownButtonFormField<int>(
                                  value: _selectedFolderId,
                                  dropdownColor: LabColors.background,
                                  style: LabStyles.mono(c,
                                      fontSize: 10, color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: 'FOLDER (OPTIONAL)',
                                    labelStyle: LabStyles.mono(c,
                                        fontSize: 8, color: Colors.grey),
                                    border: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Colors.white12, width: 0.5)),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    isDense: true,
                                  ),
                                  items: folders
                                      .map((r) => DropdownMenuItem(
                                            value: r.data['id'] as int,
                                            child: Text(
                                                (r.data['name'] as String)
                                                    .toUpperCase(),
                                                style: LabStyles.mono(c,
                                                    fontSize: 9,
                                                    color: Colors.white)),
                                          ))
                                      .toList(),
                                  onChanged: (v) => setModalState(
                                      () => _selectedFolderId = v),
                                );
                              },
                            ),
                          ),
                          if (_selectedFolderId != null)
                            IconButton(
                              icon: const Icon(Icons.close,
                                  size: 14, color: Colors.grey),
                              onPressed: () =>
                                  setModalState(() => _selectedFolderId = null),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 16),

                      Expanded(
                        child: StreamBuilder<List<drift.QueryRow>>(
                          stream: db
                              .customSelect(
                                "SELECT id, set_id, description, spectrum_value, tags, created_at FROM somatic_logs WHERE set_id = ${widget.set.id} AND spectrum_value ${isRecovery ? '> 0' : '< 0'} ORDER BY created_at DESC",
                              )
                              .watch(),
                          builder: (context, snapshot) {
                            final rows = snapshot.data ?? [];
                            if (rows.isEmpty)
                              return Center(
                                  child: Text(
                                      isRecovery
                                          ? "NO_RECOVERY_LOGS_YET"
                                          : "NO_ANOMALIES_REGISTERED_YET",
                                      style: LabStyles.mono(context,
                                          fontSize: 8,
                                          color: Colors.grey[800]!)));
                            return ListView.builder(
                              itemCount: rows.length,
                              itemBuilder: (context, index) {
                                final row = rows[index];
                                final logId = row.data['id'] as int;
                                final logDescription =
                                    row.data['description'] as String;
                                final logSpectrum =
                                    row.data['spectrum_value'] as int;
                                final logTags =
                                    (row.data['tags'] as String?) ?? '';
                                final isRecovery = logSpectrum > 0;
                                final isEditingThis = editingLogId == logId;
                                return InkWell(
                                  onTap: () async {
                                    setModalState(() {
                                      editingLogId = logId;
                                      dC.text = logDescription;
                                      selectedIntensity = isRecovery
                                          ? logSpectrum
                                          : logSpectrum.abs();
                                      tC.text = logTags;
                                    });
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                        color: isEditingThis
                                            ? (isRecovery
                                                    ? Colors.greenAccent
                                                    : Colors.redAccent)
                                                .withValues(alpha: 0.1)
                                            : Colors.white
                                                .withValues(alpha: 0.05),
                                        border: Border.all(
                                            color: isEditingThis
                                                ? (isRecovery
                                                    ? Colors.greenAccent
                                                    : Colors.redAccent)
                                                : Colors.white10,
                                            width: 0.5)),
                                    child: Row(
                                      children: [
                                        Container(
                                            width: 3,
                                            height: 20,
                                            color: isRecovery
                                                ? Colors.greenAccent
                                                : Colors.redAccent),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(logDescription.toUpperCase(),
                                                  style: LabStyles.mono(context,
                                                      fontSize: 9,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: isEditingThis
                                                          ? (isRecovery
                                                              ? Colors
                                                                  .greenAccent
                                                              : Colors
                                                                  .redAccent)
                                                          : Colors.white)),
                                              Text("SPECTRUM: $logSpectrum",
                                                  style: LabStyles.mono(context,
                                                      fontSize: 8,
                                                      color: Colors.grey)),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline,
                                              color: Colors.redAccent,
                                              size: 16),
                                          onPressed: () async {
                                            await db.customStatement(
                                                'DELETE FROM somatic_logs WHERE id = $logId');
                                            if (editingLogId == logId) {
                                              setModalState(() {
                                                editingLogId = null;
                                                dC.clear();
                                                tC.clear();
                                                selectedIntensity = 5;
                                              });
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 16),
                      LabButton(
                          label: editingLogId != null
                              ? (isRecovery ? 'UPDATE_RECOVERY' : 'UPDATE')
                              : (isRecovery
                                  ? 'REGISTER_RECOVERY'
                                  : 'REGISTER_ANOMALY'),
                          color: isRecovery
                              ? Colors.greenAccent
                              : Colors.redAccent,
                          onPressed: () async {
                            if (dC.text.trim().isEmpty) return;

                            final now = DateTime.now().millisecondsSinceEpoch;
                            final spectrumVal = isRecovery
                                ? selectedIntensity
                                : -selectedIntensity;
                            final tagsStr = tC.text.trim();

                            if (editingLogId != null) {
                              await db.customStatement(
                                "UPDATE somatic_logs SET description = '${dC.text.replaceAll("'", "''")}', spectrum_value = $spectrumVal, tags = '${tagsStr.replaceAll("'", "''")}' WHERE id = ${editingLogId!}",
                              );
                            } else {
                              await db.customStatement(
                                "INSERT INTO somatic_logs (set_id, description, spectrum_value, tags, created_at) VALUES (${widget.set.id}, '${dC.text.replaceAll("'", "''")}', $spectrumVal, '${tagsStr.replaceAll("'", "''")}', $now)",
                              );
                              if (_selectedFolderId != null) {
                                final idRows = await db.executor.runSelect(
                                    'SELECT last_insert_rowid() AS id', []);
                                if (idRows.isNotEmpty) {
                                  final newLogId = idRows.first['id'] as int;
                                  await db.customStatement(
                                    "INSERT OR IGNORE INTO somatic_folder_logs (folder_id, log_id) VALUES ($_selectedFolderId, $newLogId)",
                                  );
                                }
                              }
                            }

                            setModalState(() {
                              editingLogId = null;
                              dC.clear();
                              tC.clear();
                              selectedIntensity = 5;
                            });
                          }),
                      const SizedBox(height: 8),
                      LabButton(
                          label: 'CLOSE',
                          isOutlined: true,
                          color: Colors.grey,
                          onPressed: () => Navigator.pop(context)),
                    ]))));
  }

  Future<void> _showSpectrumReferencePopup(
      BuildContext context, AppDatabase db) async {
    final refs = await db
        .customSelect(
            'SELECT value, label, description FROM spectrum_references ORDER BY value')
        .get();
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: LabColors.background,
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('SPECTRUM_REFERENCES',
                      style: LabStyles.headline(c, color: Colors.white)
                          .copyWith(fontSize: 14)),
                  const Spacer(),
                  IconButton(
                      onPressed: () => Navigator.pop(c),
                      icon: const Icon(Icons.close,
                          color: Colors.grey, size: 18)),
                ],
              ),
              const Divider(color: Colors.white10),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  itemCount: refs.length,
                  separatorBuilder: (_, __) =>
                      const Divider(color: Colors.white10, height: 1),
                  itemBuilder: (c, i) {
                    final row = refs[i];
                    final val = row.data['value'] as int;
                    final label = row.data['label'] as String;
                    final desc = row.data['description'] as String;
                    Color vColor;
                    if (val < 0) {
                      final t = (val + 10) / 10.0;
                      vColor =
                          Color.lerp(Colors.redAccent, Colors.grey[600]!, t)!;
                    } else if (val == 0) {
                      vColor = Colors.grey[600]!;
                    } else {
                      vColor = Color.lerp(
                          Colors.greenAccent, Colors.blueAccent, val / 10.0)!;
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: vColor.withValues(alpha: 0.5),
                                  width: 0.5),
                              color: vColor.withValues(alpha: 0.1),
                            ),
                            child: Center(
                                child: Text('$val',
                                    style: LabStyles.mono(c,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: vColor))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(label,
                                    style: LabStyles.mono(c,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white)),
                                Text(desc,
                                    style: LabStyles.mono(c,
                                        fontSize: 8, color: Colors.grey[400]!)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// WORKOUT OPTS BOTTOM SHEET — modular slice architecture
// ═══════════════════════════════════════════════════════════════
// To add a new option: add a _WorkoutOptsSlice entry in the
// slices list inside _WorkoutOptsSheetState.build().
// Each slice is self-contained (label, icon, color, action).
// ═══════════════════════════════════════════════════════════════

class _WorkoutOptsSheet extends ConsumerStatefulWidget {
  final List<drift.TypedResult> results;
  final VoidCallback onMakeBlueprint;
  final VoidCallback onDeleteAll;

  const _WorkoutOptsSheet({
    required this.results,
    required this.onMakeBlueprint,
    required this.onDeleteAll,
  });

  @override
  ConsumerState<_WorkoutOptsSheet> createState() => _WorkoutOptsSheetState();
}

class _WorkoutOptsSheetState extends ConsumerState<_WorkoutOptsSheet> {
  Color _tc(String key, String nameSeed) {
    final settings = ref.watch(themeSettingsProvider).value ?? {};
    return ref
        .read(themeControllerProvider)
        .getColor(settings, key, nameSeed: nameSeed);
  }

  @override
  Widget build(BuildContext context) {
    // -- Define slices here -------------------------------------------
    // Add / remove / reorder slices freely. Each slice is modular.
    final slices = <WorkoutOptsSlice>[
      WorkoutOptsSlice(
        label: 'MAKE BLUEPRINT\nFROM CURRENT',
        icon: Icons.layers,
        color: _tc('UI_TAG_WO_BLUEPRINT', 'WO_BLUEPRINT'),
        onTap: widget.onMakeBlueprint,
      ),
      WorkoutOptsSlice(
        label: 'DELETE\nALL SETS',
        icon: Icons.delete_forever,
        color: _tc('UI_TAG_WO_PURGE', 'WO_PURGE'),
        onTap: widget.onDeleteAll,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('WORKOUT OPTS',
                  style: LabStyles.headline(context,
                          color: _tc('UI_TAG_WORKOUT_OPTS', 'WORKOUT_OPTS'))
                      .copyWith(fontSize: 16, letterSpacing: 2)),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: slices.map((s) => _buildSlice(context, s)).toList(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSlice(BuildContext context, WorkoutOptsSlice slice) {
    return GestureDetector(
      onTap: slice.onTap,
      child: Container(
        width: (MediaQuery.of(context).size.width - 60) / 2,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: slice.color.withValues(alpha: 0.08),
          border:
              Border.all(color: slice.color.withValues(alpha: 0.4), width: 0.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(slice.icon, color: slice.color, size: 28),
            const SizedBox(height: 10),
            Text(
              slice.label,
              textAlign: TextAlign.center,
              style: LabStyles.mono(context,
                  fontSize: 8,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}


// ─── SET INTENT PICKER ───────────────────────────────────────────
// Searchable/sortable picker for set intents. User can create new
// intents with colors, edit, and delete existing ones.

class _SetIntentPicker extends ConsumerStatefulWidget {
  final String? currentIntent;
  final Function(String) onSelected;

  const _SetIntentPicker(
      {required this.currentIntent, required this.onSelected});

  @override
  ConsumerState<_SetIntentPicker> createState() => _SetIntentPickerState();
}

class _SetIntentPickerState extends ConsumerState<_SetIntentPicker> {
  final TextEditingController _searchC = TextEditingController();
  final TextEditingController _nameC = TextEditingController();
  final TextEditingController _colorC = TextEditingController();
  bool _showCreateForm = false;
  List<IntentionDef>? _filtered;

  @override
  void initState() {
    super.initState();
    _searchC.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchC.dispose();
    _nameC.dispose();
    _colorC.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchC.text.toLowerCase();
    setState(() {
      final all = ref.read(setIntentionsProvider).valueOrNull ?? [];
      if (q.isEmpty) {
        _filtered = null;
      } else {
        _filtered = all.where((d) => d.name.toLowerCase().contains(q)).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final intentsAsync = ref.watch(setIntentionsProvider);
    return intentsAsync.when(
      data: (intents) {
        final display = _filtered ?? intents;
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('SET INTENT',
                      style:
                          LabStyles.headline(context).copyWith(fontSize: 16)),
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white)),
                ],
              ),
              const SizedBox(height: 16),
              // Search bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[700]!, width: 0.5),
                  color: LabColors.surfaceContainerLow,
                ),
                child: TextField(
                  controller: _searchC,
                  style: LabStyles.mono(context,
                      fontSize: 11, color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'SEARCH INTENT...',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Create new intent button
              LabButton(
                label: _showCreateForm ? 'CANCEL' : '+ CREATE INTENT',
                color: _intentActionColor(context),
                isOutlined: true,
                onPressed: () =>
                    setState(() => _showCreateForm = !_showCreateForm),
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                fontSize: 9,
              ),
              if (_showCreateForm) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _nameC,
                  style: LabStyles.mono(context,
                      fontSize: 12, color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'INTENT NAME',
                    hintStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
                    border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24)),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _colorC,
                  style: LabStyles.mono(context,
                      fontSize: 12, color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'COLOR HEX (e.g. #FF5722)',
                    hintStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
                    border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24)),
                  ),
                ),
                const SizedBox(height: 12),
                LabButton(
                  label: 'SAVE',
                  color: LabColors.primary,
                  onPressed: () async {
                    final name = _nameC.text.trim().toUpperCase();
                    final color = _colorC.text.trim().isNotEmpty
                        ? _colorC.text.trim()
                        : '#FF5722';
                    if (name.isEmpty) return;
                    await ref
                        .read(setIntentionActionsProvider)
                        .add(name, color);
                    ref.invalidate(setIntentionsProvider);
                    _nameC.clear();
                    _colorC.clear();
                    setState(() => _showCreateForm = false);
                  },
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                ),
              ],
              const SizedBox(height: 16),
              // Existing intents list
              Expanded(
                child: display.isEmpty
                    ? Center(
                        child: Text('NO INTENTS DEFINED',
                            style: LabStyles.mono(context,
                                fontSize: 10, color: Colors.grey[600])))
                    : ListView.builder(
                        itemCount: display.length,
                        itemBuilder: (context, i) {
                          final intent = display[i];
                          final isSelected =
                              intent.name == widget.currentIntent;
                          Color chipColor;
                          try {
                            final hex = intent.color.replaceAll('#', '');
                            chipColor = Color(int.parse('FF$hex', radix: 16));
                          } catch (_) {
                            chipColor = LabColors.primary;
                          }
                          return Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? chipColor.withValues(alpha: 0.15)
                                  : Colors.transparent,
                              border: Border.all(
                                color:
                                    isSelected ? chipColor : Colors.grey[800]!,
                                width: isSelected ? 1 : 0.5,
                              ),
                            ),
                            child: ListTile(
                              dense: true,
                              leading: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                    color: chipColor, shape: BoxShape.circle),
                              ),
                              title: Text(intent.name,
                                  style: LabStyles.mono(context,
                                      fontSize: 10,
                                      color:
                                          isSelected ? chipColor : Colors.white,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal)),
                              subtitle: Text(intent.color,
                                  style: LabStyles.mono(context,
                                      fontSize: 7, color: Colors.grey[600])),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isSelected)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4, vertical: 2),
                                      decoration: BoxDecoration(
                                          color:
                                              chipColor.withValues(alpha: 0.2)),
                                      child: Text('SELECTED',
                                          style: LabStyles.mono(context,
                                              fontSize: 7,
                                              color: chipColor,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () {
                                      final newNameC = TextEditingController(
                                          text: intent.name);
                                      final newColorC = TextEditingController(
                                          text: intent.color);
                                      showDialog(
                                        context: context,
                                        builder: (c2) => AlertDialog(
                                          backgroundColor: LabColors.background,
                                          title: Text('EDIT INTENT',
                                              style: LabStyles.mono(c2)
                                                  .copyWith(
                                                      fontSize: 12,
                                                      color: Colors.amber)),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              TextField(
                                                  controller: newNameC,
                                                  style: LabStyles.mono(c2,
                                                      fontSize: 12,
                                                      color: Colors.white),
                                                  decoration: const InputDecoration(
                                                      hintText: 'NAME',
                                                      border:
                                                          OutlineInputBorder())),
                                              const SizedBox(height: 8),
                                              TextField(
                                                  controller: newColorC,
                                                  style: LabStyles.mono(c2,
                                                      fontSize: 12,
                                                      color: Colors.white),
                                                  decoration: const InputDecoration(
                                                      hintText: 'COLOR HEX',
                                                      border:
                                                          OutlineInputBorder())),
                                            ],
                                          ),
                                          actions: [
                                            TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(c2),
                                                child: Text('CANCEL',
                                                    style: TextStyle(
                                                        color: Colors.grey))),
                                            TextButton(
                                                onPressed: () async {
                                                  final nn = newNameC.text
                                                      .trim()
                                                      .toUpperCase();
                                                  final nc =
                                                      newColorC.text.trim();
                                                  if (nn.isEmpty) return;
                                                  if (nn != intent.name) {
                                                    await ref
                                                        .read(
                                                            setIntentionActionsProvider)
                                                        .rename(
                                                            intent.name, nn);
                                                  }
                                                  if (nc.isNotEmpty &&
                                                      nc != intent.color) {
                                                    await ref
                                                        .read(
                                                            setIntentionActionsProvider)
                                                        .add(nn, nc);
                                                  }
                                                  ref.invalidate(
                                                      setIntentionsProvider);
                                                  if (c2.mounted)
                                                    Navigator.pop(c2);
                                                },
                                                child: Text('SAVE',
                                                    style: TextStyle(
                                                        color: Colors.amber))),
                                            TextButton(
                                                onPressed: () async {
                                                  await ref
                                                      .read(
                                                          setIntentionActionsProvider)
                                                      .delete(intent.name);
                                                  ref.invalidate(
                                                      setIntentionsProvider);
                                                  if (c2.mounted)
                                                    Navigator.pop(c2);
                                                },
                                                child: Text('DELETE',
                                                    style: TextStyle(
                                                        color:
                                                            Colors.redAccent))),
                                          ],
                                        ),
                                      );
                                    },
                                    child: Icon(Icons.edit,
                                        size: 14, color: Colors.grey[500]),
                                  ),
                                ],
                              ),
                              onTap: () {
                                widget.onSelected(intent.name);
                                Navigator.pop(context);
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(
          child: CircularProgressIndicator(color: LabColors.primary)),
      error: (e, s) => Center(
          child: Text('ERROR: $e', style: TextStyle(color: Colors.redAccent))),
    );
  }

  Color _intentActionColor(BuildContext context) {
    try {
      final settings = ref.read(themeSettingsProvider).value ?? {};
      return ref
          .read(themeControllerProvider)
          .getColor(settings, 'UI_TAG_SET_INTENT', nameSeed: 'SET_INTENT');
    } catch (_) {
      return LabColors.primary;
    }
  }
}
