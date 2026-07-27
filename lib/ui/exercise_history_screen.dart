import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' as drift;

import '../providers/database_provider.dart';
import '../database/database.dart';
import 'styles.dart';
import 'lab_widgets.dart';
import 'main_scaffold.dart';
import 'charts/performance_dashboard.dart';
import 'workout_manager.dart'; // To access selectedDateProvider

class ExerciseHistoryScreen extends ConsumerWidget {
  final BaseExercise exercise;
  const ExerciseHistoryScreen({super.key, required this.exercise});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(exerciseFullHistoryProvider(exercise.id));
    final bw = ref.watch(_latestBodyWeightProvider).valueOrNull ?? 0.0;

    return MainScaffold(
      title: 'KNS.HISTORICAL_REPORT',
      screenKey: 'HISTORY',
      body: Column(
        children: [
          _buildExerciseHeader(context, ref),
          _buildJumpToAnalyzerButton(context),
          const Divider(height: 1, color: LabColors.cyanBorder, thickness: 0.5),
          Expanded(
            child: historyAsync.when(
              data: (data) {
                if (data.isEmpty) return _buildEmptyState(context);

                // Group by date
                final Map<String, List<_HistSet>> groupedByDate = {};
                for (var row in data) {
                  final dateStr = DateFormat('yyyy-MM-dd').format(row.logDate);
                  groupedByDate.putIfAbsent(dateStr, () => []).add(row);
                }

                final sortedDates = groupedByDate.keys.toList()..sort((a, b) => b.compareTo(a));

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sortedDates.length,
                  itemBuilder: (context, index) {
                    final dateStr = sortedDates[index];
                    final date = DateTime.parse(dateStr);
                    final rows = groupedByDate[dateStr]!;
                    return _buildDateGroup(context, ref, date, rows, bw);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: LabColors.primary)),
              error: (e, s) => Center(child: Text("ERR: $e", style: LabStyles.mono(context, color: Colors.redAccent))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseHeader(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: LabColors.surfaceDim,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('MOVEMENT_IDENTIFIER', style: LabStyles.mono(context, fontSize: 8, color: LabColors.primary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(exercise.fullName.toUpperCase(), style: LabStyles.headline(context).copyWith(fontSize: 20)),
          const SizedBox(height: 8),
          Row(
            children: [
              if (exercise.primaryMuscleGroup != null)
                _buildTag(context, exercise.primaryMuscleGroup!, LabColors.primary),
              const SizedBox(width: 8),
              if (exercise.field != null)
                _buildTag(context, exercise.field!, LabColors.accent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(border: Border.all(color: color, width: 0.5)),
      child: Text(label.toUpperCase(), style: LabStyles.mono(context, fontSize: 8, color: color, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildJumpToAnalyzerButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: LabButton(
        label: "JUMP TO GRFCL HISTORY",
        color: LabColors.visualsNeon,
        isOutlined: true,
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (c) => PerformanceDashboard(
            initialTab: ChartTab.oneRm,
            initialExerciseId: exercise.id,
          )));
        },
      ),
    );
  }

  Widget _buildDateGroup(BuildContext context, WidgetRef ref, DateTime date, List<_HistSet> rows, double bw) {
    final intentionText = exercise.intention ?? '';
    bool isIso = intentionText.contains('[ISO:true]') || intentionText.startsWith('[ISO]');
    final metaMatch = RegExp(r'\[NT:.*\|ISO:(.*)\]').firstMatch(intentionText);
    if (metaMatch != null) {
      isIso = metaMatch.group(1) == 'true';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: LabStyles.hairlineBorder(color: Colors.grey[900]!),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (c) => WorkoutManagerScreen(initialDate: date)),
                (route) => route.isFirst,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: LabColors.surfaceContainerHigh,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 10, color: LabColors.primary),
                      const SizedBox(width: 8),
                      Text(DateFormat('EEEE, MMM d, yyyy').format(date).toUpperCase(), style: LabStyles.mono(context, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  if (bw > 0)
                    Text("BW: ${bw.toStringAsFixed(1)} KG", style: LabStyles.mono(context, fontSize: 8, color: Colors.grey)),
                ],
              ),
            ),
          ),
          _buildTableHeader(context, isIso: isIso),
          ...rows.map((set) {
            return _buildSetRow(context, ref, set, bw, isIso: isIso);
          }),
        ],
      ),
    );
  }

  Widget _buildTableHeader(BuildContext context, {bool isIso = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text('LOAD', style: LabStyles.mono(context, fontSize: 7, color: Colors.grey))),
          Expanded(flex: 2, child: Text(isIso ? 'SECS' : 'REPS', style: LabStyles.mono(context, fontSize: 7, color: Colors.grey))),
          Expanded(flex: 2, child: Text('RPE', style: LabStyles.mono(context, fontSize: 7, color: Colors.grey))),
          Expanded(flex: 2, child: Text('RIR', style: LabStyles.mono(context, fontSize: 7, color: Colors.grey))),
          Expanded(flex: 1, child: Text('PR', textAlign: TextAlign.center, style: LabStyles.mono(context, fontSize: 7, color: Colors.grey))),
          const SizedBox(width: 40), // Space for inject button
        ],
      ),
    );
  }

  Widget _buildSetRow(BuildContext context, WidgetRef ref, _HistSet set, double bw, {bool isIso = false}) {
    final hasPr = set.isPr;
    final isRed = set.trackName?.contains('[RED_PR]') ?? false;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text("${set.weight.toStringAsFixed(1)} KG", style: LabStyles.mono(context, fontSize: 12, fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text("${set.reps.toStringAsFixed(0)}${isIso ? 'S' : ''}", style: LabStyles.mono(context, fontSize: 12))),
          Expanded(flex: 2, child: Text(set.rpe?.toStringAsFixed(1) ?? '-', style: LabStyles.mono(context, fontSize: 12, color: Colors.grey))),
          Expanded(flex: 2, child: Text(set.rir?.toStringAsFixed(1) ?? '-', style: LabStyles.mono(context, fontSize: 12, color: Colors.grey))),
          Expanded(
            flex: 1, 
            child: hasPr 
              ? Icon(Icons.emoji_events, color: isRed ? Colors.redAccent : LabColors.accent, size: 14)
              : const SizedBox(),
          ),
          _buildInjectButton(context, ref, set),
        ],
      ),
    );
  }

  Widget _buildInjectButton(BuildContext context, WidgetRef ref, _HistSet historicalSet) {
    return InkWell(
      onTap: () => _injectSet(context, ref, historicalSet),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: LabColors.primary.withValues(alpha: 0.1),
          border: Border.all(color: LabColors.primary, width: 0.5),
        ),
        child: const Icon(Icons.add, color: LabColors.primary, size: 14),
      ),
    );
  }

  Future<void> _injectSet(BuildContext context, WidgetRef ref, _HistSet historicalSet) async {
    final db = ref.read(databaseProvider);
    final targetDate = ref.read(selectedDateProvider);
    
    final targetStart = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final targetEnd = DateTime(targetDate.year, targetDate.month, targetDate.day, 23, 59, 59);
    
    final logs = await (db.select(db.workoutLogs)..where((t) => t.date.isBetweenValues(targetStart, targetEnd))).get();
    int logId = logs.isEmpty ? await db.into(db.workoutLogs).insert(WorkoutLogsCompanion.insert(date: targetDate)) : logs.first.id;
    
    // Find current max orderIndex for this exercise today
    final existingSets = await (db.select(db.workoutSets)
      ..where((t) => t.logId.equals(logId) & t.baseExerciseId.equals(historicalSet.baseExerciseId))
      ..orderBy([(t) => drift.OrderingTerm.desc(t.orderIndex)])
      ..limit(1)).get();
      
    int orderIndex = existingSets.isNotEmpty ? existingSets.first.orderIndex : 0;

    await db.into(db.workoutSets).insert(WorkoutSetsCompanion.insert(
      logId: logId,
      baseExerciseId: historicalSet.baseExerciseId,
      weight: historicalSet.weight,
      reps: historicalSet.reps,
      rpe: drift.Value(historicalSet.rpe),
      notes: drift.Value(historicalSet.notes),
      trackName: drift.Value(historicalSet.trackName?.replaceFirst('[RED_PR] ', '').trim()),
      hypeLevel: drift.Value(historicalSet.hypeLevel),
      isPrSong: drift.Value(historicalSet.isPrSong),
      technique: drift.Value(historicalSet.technique),
      complexMetadata: drift.Value(historicalSet.complexMetadata),
      orderIndex: drift.Value(orderIndex),
      timestamp: drift.Value(DateTime.now()),
    ));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("SET_INJECTED_SUCCESSFULLY")));
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history, size: 48, color: Colors.grey[800]),
          const SizedBox(height: 16),
          Text('NO_HISTORICAL_RECORDS_FOUND', style: LabStyles.mono(context, color: Colors.grey[600]!, fontSize: 10)),
        ],
      ),
    );
  }
}

// Lightweight row shape used by the history screen. Avoids Drift's typed
// row decoding, which throws "Null check operator used on a null value"
// against on-device DBs where a legacy row is missing a value for a
// column that later gained a non-nullable Dart type / default.
class _HistSet {
  final int id;
  final int logId;
  final int baseExerciseId;
  final double weight;
  final double reps;
  final double? rpe;
  final double? rir;
  final String? notes;
  final String? trackName;
  final int? hypeLevel;
  final bool isPrSong;
  final bool isPr;
  final int? technique;
  final String? complexMetadata;
  final int orderIndex;
  final DateTime logDate;

  _HistSet({
    required this.id,
    required this.logId,
    required this.baseExerciseId,
    required this.weight,
    required this.reps,
    required this.rpe,
    required this.rir,
    required this.notes,
    required this.trackName,
    required this.hypeLevel,
    required this.isPrSong,
    required this.isPr,
    required this.technique,
    required this.complexMetadata,
    required this.orderIndex,
    required this.logDate,
  });
}

final _latestBodyWeightProvider = StreamProvider<double>((ref) {
  final db = ref.watch(databaseProvider);
  return db.customSelect(
    "SELECT value FROM anthropometric_logs WHERE label = 'WEIGHT' ORDER BY date DESC LIMIT 1",
    readsFrom: {db.anthropometricLogs},
  ).watchSingleOrNull().map((row) => (row?.data['value'] as num?)?.toDouble() ?? 0.0);
});

// Provider for exercise history
final exerciseFullHistoryProvider = StreamProvider.family<List<_HistSet>, int>((ref, exId) {
  final db = ref.watch(databaseProvider);

  return db.customSelect(
    'SELECT ws.id AS id, ws.log_id AS log_id, ws.base_exercise_id AS base_exercise_id, '
    'ws.weight AS weight, ws.reps AS reps, ws.rpe AS rpe, ws.rir AS rir, ws.notes AS notes, '
    'ws.track_name AS track_name, ws.hype_level AS hype_level, ws.is_pr_song AS is_pr_song, '
    'ws.is_pr AS is_pr, ws.technique AS technique, ws.complex_metadata AS complex_metadata, '
    'ws.order_index AS order_index, ws.timestamp AS ws_timestamp, wl.date AS log_date '
    'FROM workout_sets ws INNER JOIN workout_logs wl ON wl.id = ws.log_id '
    'WHERE ws.base_exercise_id = ? '
    'ORDER BY wl.date DESC, ws.order_index ASC, ws.timestamp ASC',
    variables: [drift.Variable(exId)],
    readsFrom: {db.workoutSets, db.workoutLogs},
  ).watch().map((rows) => rows.map((row) {
        final data = row.data;
        final logDateSeconds = (data['log_date'] as num?)?.toInt() ?? 0;
        return _HistSet(
          id: data['id'] as int,
          logId: data['log_id'] as int,
          baseExerciseId: data['base_exercise_id'] as int,
          weight: (data['weight'] as num?)?.toDouble() ?? 0.0,
          reps: (data['reps'] as num?)?.toDouble() ?? 0.0,
          rpe: (data['rpe'] as num?)?.toDouble(),
          rir: (data['rir'] as num?)?.toDouble(),
          notes: data['notes'] as String?,
          trackName: data['track_name'] as String?,
          hypeLevel: (data['hype_level'] as num?)?.toInt(),
          isPrSong: (data['is_pr_song'] as int?) == 1,
          isPr: (data['is_pr'] as int?) == 1,
          technique: (data['technique'] as num?)?.toInt(),
          complexMetadata: data['complex_metadata'] as String?,
          orderIndex: (data['order_index'] as num?)?.toInt() ?? 0,
          logDate: DateTime.fromMillisecondsSinceEpoch(logDateSeconds * 1000),
        );
      }).toList());
});
