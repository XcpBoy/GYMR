import 'dart:convert';

import 'package:drift/drift.dart' as drift;

import '../database/database.dart';

class OvarchPlanInjectionService {
  static Future<List<Map<String, dynamic>>> activeWorkoutBlocks(
      AppDatabase db) async {
    final legacyById = <int, Map<String, dynamic>>{};
    var hasLegacySnapshot = false;
    try {
      final legacyRows =
          await db.customSelect('SELECT data FROM wb_store WHERE id = 1').get();
      hasLegacySnapshot = legacyRows.isNotEmpty;
      if (hasLegacySnapshot) {
        final raw = legacyRows.first.data['data'] as String;
        final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
        for (final item in list) {
          final id = int.tryParse(item['id'].toString().replaceAll('wb_', ''));
          if (id == null || id <= 0) continue;
          final name = (item['name'] as String?).toString().trim();
          if (name.isEmpty) continue;
          legacyById[id] = <String, dynamic>{
            'id': id,
            'name': name.toUpperCase(),
            'intention': item['intention'] as String?,
            'description': item['description'] as String?,
            'createdAt': item['createdAt'] as int?,
            'source': 'legacy',
          };
        }
      }
    } catch (_) {}

    final realRows = await db.customSelect('''
      SELECT id, name, intention, description, created_at, deleted_at
      FROM workout_blocks
      WHERE COALESCE(deleted_at, 0) = 0
      ORDER BY lower(name) ASC
    ''').get();

    final activeById = <int, Map<String, dynamic>>{};
    final deletedRealIds = <int>{};
    for (final row in realRows) {
      final id = row.data['id'] as int;
      final deletedAt = row.data['deleted_at'] as int?;
      if (deletedAt != null && deletedAt > 0) {
        deletedRealIds.add(id);
        continue;
      }
      if (hasLegacySnapshot && !legacyById.containsKey(id)) continue;
      activeById[id] = <String, dynamic>{
        'id': id,
        'name': row.data['name'] as String,
        'intention': row.data['intention'] as String?,
        'description': row.data['description'] as String?,
        'createdAt': row.data['created_at'] as int?,
        'source': 'real',
      };
    }

    for (final entry in legacyById.entries) {
      final id = entry.key;
      if (deletedRealIds.contains(id)) continue;
      final legacy = entry.value;
      if (activeById.containsKey(id)) {
        final real = activeById[id]!;
        if ((real['name'] as String).isEmpty ||
            RegExp(r'^WB\s*\d+$').hasMatch(real['name'] as String)) {
          real['name'] = legacy['name'];
        }
        real['createdAt'] ??= legacy['createdAt'];
      } else {
        activeById[id] = legacy;
      }
    }

    final values = activeById.values.toList()
      ..sort((a, b) => (a['name'] as String)
          .toLowerCase()
          .compareTo((b['name'] as String).toLowerCase()));
    print(
        '[OVARCH_ACTIVE_WB] hasLegacy=$hasLegacySnapshot legacy=${legacyById.length} active=${values.length} deletedReal=${deletedRealIds.length}');
    return values
        .map((item) => <String, dynamic>{
              'id': item['id'] as int,
              'name': item['name'] as String,
              'intention': item['intention'] as String?,
              'description': item['description'] as String?,
              'createdAt': item['createdAt'] as int?,
            })
        .toList();
  }

  static Future<List<Map<String, dynamic>>> planDaysWithBlocks(
      AppDatabase db) async {
    print('[PLAN_DAY_PICKER] planDaysWithBlocks START');
    final rows = await db.customSelect('''
      SELECT
        tp.id AS plan_id,
        tp.name AS plan_name,
        pw.id AS week_id,
        pw.week_number AS week_number,
        pd.id AS day_id,
        pd.day_number AS day_number,
        pd.label AS day_label,
        COUNT(pdb.id) AS block_count
      FROM training_plans tp
      JOIN plan_weeks pw ON pw.plan_id = tp.id
      JOIN plan_days pd ON pd.week_id = pw.id
      LEFT JOIN plan_day_blocks pdb ON pdb.day_id = pd.id
      GROUP BY tp.id, pw.id, pd.id
      HAVING COUNT(pdb.id) > 0
      ORDER BY tp.name ASC, pw.week_number ASC, pd.day_number ASC
    ''').get();
    print('[PLAN_DAY_PICKER] SQL rows=${rows.length}');
    final blockRows = await db.customSelect('''
      SELECT id, day_id, plan_day_id, block_id, workout_block_id, order_index, notes
      FROM plan_day_blocks
      ORDER BY day_id ASC, order_index ASC, id ASC
    ''').get();
    print('[PLAN_DAY_PICKER] plan_day_blocks raw rows=${blockRows.length}');
    for (final row in blockRows) {
      print(
          '[PLAN_DAY_PICKER] plan_day_blocks id=${row.data['id']} day_id=${row.data['day_id']} plan_day_id=${row.data['plan_day_id']} block_id=${row.data['block_id']} workout_block_id=${row.data['workout_block_id']} order=${row.data['order_index']} notes=${row.data['notes']}');
    }

    final result = rows.map((row) {
      final payload = <String, dynamic>{
        'planId': row.data['plan_id'] as int,
        'planName': row.data['plan_name'] as String,
        'weekId': row.data['week_id'] as int,
        'weekNumber': row.data['week_number'] as int,
        'dayId': row.data['day_id'] as int,
        'dayNumber': row.data['day_number'] as int,
        'dayLabel': row.data['day_label'] as String?,
        'blockCount': row.data['block_count'] as int,
      };
      print(
          '[PLAN_DAY_PICKER] row planName=${payload['planName']} week=${payload['weekNumber']} dayId=${payload['dayId']} dayNumber=${payload['dayNumber']} dayLabel=${payload['dayLabel']} blockCount=${payload['blockCount']}');
      return payload;
    }).toList();
    print('[PLAN_DAY_PICKER] END returned=${result.length}');
    return result;
  }

  static Future<Map<String, dynamic>?> workoutBlockById(
      AppDatabase db, int blockId) async {
    print('[OVARCH_INJECT] workoutBlockById START blockId=$blockId');
    final rows = await db.customSelect('''
      SELECT id, name, intention, description, created_at, deleted_at
      FROM workout_blocks
      WHERE id = $blockId AND COALESCE(deleted_at, 0) = 0
    ''').get();
    print(
        '[OVARCH_INJECT] workoutBlockById rows=$blockId rowsFound=${rows.length}');

    if (rows.isEmpty) return null;
    final row = rows.first;
    final payload = <String, dynamic>{
      'id': row.data['id'] as int,
      'name': row.data['name'] as String,
      'intention': row.data['intention'] as String?,
      'description': row.data['description'] as String?,
      'createdAt': row.data['created_at'] as int?,
    };
    print(
        '[OVARCH_INJECT] workoutBlockById FOUND id=${payload['id']} name=${payload['name']}');
    return payload;
  }

  static Future<void> injectWorkoutBlock(
    AppDatabase db,
    DateTime date,
    Map<String, dynamic> wbData, {
    bool usePload = false,
    bool allSets = true,
    bool trackSourceBlock = true,
  }) async {
    final blockId = wbData['id'] as int;
    final blockName = wbData['name'] as String;
    final blockIntention = wbData['intention'] as String?;
    var insertedSets = 0;
    print(
        '[OVARCH_INJECT] START blockId=$blockId block=$blockName usePload=$usePload allSets=$allSets track=$trackSourceBlock date=${date.toIso8601String()}');

    await db.transaction(() async {
      final todayStart = DateTime(date.year, date.month, date.day);
      final todayEnd = DateTime(date.year, date.month, date.day, 23, 59, 59);
      print(
          '[OVARCH_INJECT] dateRange start=${todayStart.toIso8601String()} end=${todayEnd.toIso8601String()}');

      final logs = await (db.select(db.workoutLogs)
            ..where((t) => t.date.isBetweenValues(todayStart, todayEnd)))
          .get();
      print('[OVARCH_INJECT] existingLogsForDate count=${logs.length}');
      final logId = logs.isEmpty
          ? await db
              .into(db.workoutLogs)
              .insert(WorkoutLogsCompanion.insert(date: date))
          : logs.first.id;
      print('[OVARCH_INJECT] targetLogId=$logId created=${logs.isEmpty}');

      final allSetsToday = await (db.select(db.workoutSets).join([
        drift.innerJoin(
            db.workoutLogs, db.workoutLogs.id.equalsExp(db.workoutSets.logId))
      ])
            ..where(db.workoutLogs.date.isBetweenValues(todayStart, todayEnd)))
          .get();
      print('[OVARCH_INJECT] existingSetsForDate count=${allSetsToday.length}');

      int currentMaxOrder = -1;
      for (final row in allSetsToday) {
        final s = row.readTable(db.workoutSets);
        if (s.orderIndex > currentMaxOrder) currentMaxOrder = s.orderIndex;
      }
      print('[OVARCH_INJECT] currentMaxOrder=$currentMaxOrder');

      final knsRows = await db.customSelect('''
        SELECT id, base_exercise_id, order_index, utilities, batch_name
        FROM workout_block_kns
        WHERE block_id = $blockId
        ORDER BY order_index ASC, id ASC
      ''').get();
      print('[OVARCH_INJECT] workout_block_kns rows=${knsRows.length}');
      for (final row in knsRows) {
        print(
            '[OVARCH_INJECT] knsRow id=${row.data['id']} baseEx=${row.data['base_exercise_id']} order=${row.data['order_index']} utilities=${row.data['utilities']} batch=${row.data['batch_name']}');
      }

      if (knsRows.isEmpty) {
        print('[OVARCH_INJECT] THROW WB_HAS_NO_KNS blockId=$blockId');
        throw StateError('WB_HAS_NO_KNS');
      }

      for (final knsRow in knsRows) {
        final int baseExId = knsRow.data['base_exercise_id'] as int;
        final List<String> utilities =
            _parseStringList(knsRow.data['utilities'] as String?);
        final String? batchName = knsRow.data['batch_name'] as String?;
        final int knsId = knsRow.data['id'] as int;
        final setRows = await db.customSelect('''
          SELECT id, set_number, reps_min, reps_max, pload, side
          FROM workout_block_sets
          WHERE kns_id = $knsId
          ORDER BY set_number ASC, id ASC
        ''').get();
        print(
            '[OVARCH_INJECT] knsId=$knsId baseExId=$baseExId setRows count=${setRows.length}');
        for (final sRow in setRows) {
          print(
              '[OVARCH_INJECT] setRow id=${sRow.data['id']} setNumber=${sRow.data['set_number']} repsMax=${sRow.data['reps_max']} pload=${sRow.data['pload']} side=${sRow.data['side']}');
        }

        final ex = await (db.select(db.baseExercises)
              ..where((t) => t.id.equals(baseExId)))
            .getSingleOrNull();
        final bool isUnilateral = ex?.isUnilateral ?? false;
        print(
            '[OVARCH_INJECT] baseExercise baseExId=$baseExId found=${ex != null} isUnilateral=$isUnilateral name=${ex?.fullName}');
        final Map<String, dynamic> meta = <String, dynamic>{};
        if (blockIntention != null && blockIntention.isNotEmpty)
          meta['blockIntention'] = blockIntention;
        if (utilities.isNotEmpty) meta['utilities'] = utilities;
        if (batchName != null && batchName.isNotEmpty)
          meta['batch'] = batchName;
        if (trackSourceBlock) meta['injectedFromBlock'] = blockId;
        print('[OVARCH_INJECT] meta=$meta');

        final List<Map<String, dynamic>> setsToInject =
            setRows.isEmpty || !allSets
                ? <Map<String, dynamic>>[<String, dynamic>{}]
                : setRows
                    .map((sRow) => <String, dynamic>{
                          'pload': sRow.data['pload'] as num?,
                          'maxReps': sRow.data['reps_max'] as num?,
                          'side': sRow.data['side'] as String?,
                        })
                    .toList();
        print('[OVARCH_INJECT] setsToInject count=${setsToInject.length}');

        for (final setData in setsToInject) {
          final pload = setData['pload'];
          final maxReps = setData['maxReps'];
          final setSide = setData['side'] as String?;
          final double weight = usePload && pload != null
              ? (pload is num
                  ? pload.toDouble()
                  : double.tryParse(pload.toString()) ?? 0)
              : 0;
          final double reps = maxReps != null
              ? (maxReps is num
                  ? maxReps.toDouble()
                  : double.tryParse(maxReps.toString()) ?? 0)
              : 0;

          if (isUnilateral) {
            for (final side in const ['RIGHT', 'LEFT']) {
              currentMaxOrder++;
              final orderIndex = currentMaxOrder;
              final setMeta = Map<String, dynamic>.from(meta);
              setMeta['side'] = side;
              print(
                  '[OVARCH_INJECT] BEFORE_INSERT unilateral blockId=$blockId knsId=$knsId baseExId=$baseExId order=$orderIndex side=$side weight=$weight reps=$reps meta=$setMeta');
              await db.into(db.workoutSets).insert(WorkoutSetsCompanion.insert(
                    logId: logId,
                    baseExerciseId: baseExId,
                    weight: weight,
                    reps: reps,
                    orderIndex: drift.Value(orderIndex),
                    priority: drift.Value(
                        utilities.isNotEmpty ? utilities.first : null),
                    complexMetadata: drift.Value(jsonEncode(setMeta)),
                    timestamp: drift.Value(DateTime(
                            date.year,
                            date.month,
                            date.day,
                            DateTime.now().hour,
                            DateTime.now().minute,
                            DateTime.now().second)
                        .add(Duration(milliseconds: orderIndex))),
                  ));
              insertedSets++;
              print(
                  '[OVARCH_INJECT] AFTER_INSERT unilateral insertedSets=$insertedSets order=$orderIndex side=$side');
            }
          } else {
            currentMaxOrder++;
            final orderIndex = currentMaxOrder;
            final setMeta = Map<String, dynamic>.from(meta);
            if (setSide != null) setMeta['side'] = setSide;
            print(
                '[OVARCH_INJECT] BEFORE_INSERT blockId=$blockId knsId=$knsId baseExId=$baseExId order=$orderIndex side=$setSide weight=$weight reps=$reps meta=$setMeta');
            await db.into(db.workoutSets).insert(WorkoutSetsCompanion.insert(
                  logId: logId,
                  baseExerciseId: baseExId,
                  weight: weight,
                  reps: reps,
                  orderIndex: drift.Value(orderIndex),
                  priority: drift.Value(
                      utilities.isNotEmpty ? utilities.first : null),
                  complexMetadata: drift.Value(
                      setMeta.isNotEmpty ? jsonEncode(setMeta) : null),
                  timestamp: drift.Value(DateTime(
                          date.year,
                          date.month,
                          date.day,
                          DateTime.now().hour,
                          DateTime.now().minute,
                          DateTime.now().second)
                      .add(Duration(milliseconds: orderIndex))),
                ));
            insertedSets++;
            print(
                '[OVARCH_INJECT] AFTER_INSERT insertedSets=$insertedSets order=$orderIndex side=$setSide');
          }
        }
      }
    });

    print(
        '[OVARCH_INJECT] DONE blockId=$blockId block=$blockName insertedSets=$insertedSets');
  }

  static Future<Map<String, int>> injectPlanDay(
      AppDatabase db, DateTime date, List<PlanDayBlock> dayBlocks) async {
    print(
        '[OVARCH_PLAN_DAY_INJECT] START date=${date.toIso8601String()} inputBlocks=${dayBlocks.length}');
    for (final b in dayBlocks) {
      print(
          '[OVARCH_PLAN_DAY_INJECT] inputBlock id=${b.id} dayId=${b.dayId} blockId=${b.blockId} order=${b.orderIndex}');
    }
    final orderedBlocks = List<PlanDayBlock>.from(dayBlocks)
      ..sort((a, b) {
        final order = a.orderIndex.compareTo(b.orderIndex);
        return order != 0 ? order : a.id.compareTo(b.id);
      });
    print('[OVARCH_PLAN_DAY_INJECT] orderedBlocks=${orderedBlocks.length}');
    for (final b in orderedBlocks) {
      print(
          '[OVARCH_PLAN_DAY_INJECT] orderedBlock id=${b.id} dayId=${b.dayId} blockId=${b.blockId} order=${b.orderIndex}');
    }

    var injectedBlocks = 0;
    var skippedBlocks = 0;
    for (final dayBlock in orderedBlocks) {
      print(
          '[OVARCH_PLAN_DAY_INJECT] resolving block dayBlockId=${dayBlock.id} blockId=${dayBlock.blockId}');
      final block = await workoutBlockById(db, dayBlock.blockId);
      if (block == null) {
        print(
            '[OVARCH_PLAN_DAY_INJECT] SKIP deleted/missing blockId=${dayBlock.blockId}');
        skippedBlocks++;
        continue;
      }
      try {
        print(
            '[OVARCH_PLAN_DAY_INJECT] calling injectWorkoutBlock blockId=${dayBlock.blockId}');
        await injectWorkoutBlock(
          db,
          date,
          block,
          usePload: false,
          allSets: true,
          trackSourceBlock: true,
        );
        injectedBlocks++;
        print(
            '[OVARCH_PLAN_DAY_INJECT] block accepted injectedBlocks=$injectedBlocks blockId=${dayBlock.blockId}');
      } catch (e, stackTrace) {
        skippedBlocks++;
        print(
            '[OVARCH_PLAN_DAY_INJECT] ERROR blockId=${dayBlock.blockId} error=$e');
        print(stackTrace);
      }
    }
    print(
        '[OVARCH_PLAN_DAY_INJECT] DONE injected=$injectedBlocks skipped=$skippedBlocks');
    return <String, int>{'injected': injectedBlocks, 'skipped': skippedBlocks};
  }

  static List<String> _parseStringList(String? raw) {
    if (raw == null || raw.isEmpty) return <String>[];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded.whereType<String>().toList();
    } catch (_) {
      return raw
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
  }
}
