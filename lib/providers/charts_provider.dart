import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import '../logic/chart_models.dart';
import 'database_provider.dart';
import '../logic/calculator.dart';

// --- Session Metrics ---
final sessionsMetricsProvider = StreamProvider.family<List<SessionMetric>, DateTimeRange?>((ref, range) {
  final db = ref.watch(databaseProvider);
  
  var query = db.select(db.workoutLogs).join([
    innerJoin(db.workoutSets, db.workoutSets.logId.equalsExp(db.workoutLogs.id)),
  ]);

  if (range != null) {
    query.where(db.workoutSets.timestamp.isBetweenValues(range.start, range.end));
  }
  
  query.limit(1000); 

  return query.watch().map((rows) {
    final Map<DateTime, List<TypedResult>> grouped = {};
    for (final row in rows) {
      final log = row.readTable(db.workoutLogs);
      final date = DateTime(log.date.year, log.date.month, log.date.day);
      grouped.putIfAbsent(date, () => []).add(row);
    }

    return grouped.entries.map((e) {
      double volume = 0;
      int sets = 0;
      double reps = 0;
      for (final row in e.value) {
        final set = row.readTable(db.workoutSets);
        volume += set.weight * set.reps;
        sets++;
        reps += set.reps;
      }
      return SessionMetric(date: e.key, volume: volume, sets: sets, reps: reps);
    }).toList()..sort((a, b) => a.date.compareTo(b.date));
  });
});

enum MuscleMetricType { sets, reps, tonnage, workouts }

// --- Muscle Proportions ---
final muscleMetricsProvider = StreamProvider.family<List<MuscleMetric>, (MuscleMetricType, DateTimeRange?)>((ref, arg) {
  final type = arg.$1;
  final range = arg.$2;
  final db = ref.watch(databaseProvider);

  var query = db.select(db.workoutSets).join([
    innerJoin(db.baseExercises, db.baseExercises.id.equalsExp(db.workoutSets.baseExerciseId)),
  ]);

  if (range != null) {
    query.where(db.workoutSets.timestamp.isBetweenValues(range.start, range.end));
  }
  
  query.limit(1000);

  return query.watch().map((rows) {
    final Map<String, double> metrics = {};
    final Map<String, Set<int>> workoutOccurrences = {};

    for (final row in rows) {
      final set = row.readTable(db.workoutSets);
      final exercise = row.readTable(db.baseExercises);
      final muscle = exercise.primaryMuscleGroup ?? "UNKNOWN";

      switch (type) {
        case MuscleMetricType.sets:
          metrics[muscle] = (metrics[muscle] ?? 0) + 1;
          break;
        case MuscleMetricType.reps:
          metrics[muscle] = (metrics[muscle] ?? 0) + set.reps;
          break;
        case MuscleMetricType.tonnage:
          metrics[muscle] = (metrics[muscle] ?? 0) + (set.weight * set.reps);
          break;
        case MuscleMetricType.workouts:
          workoutOccurrences.putIfAbsent(muscle, () => {}).add(set.logId);
          break;
      }
    }

    if (type == MuscleMetricType.workouts) {
      workoutOccurrences.forEach((muscle, logs) {
        metrics[muscle] = logs.length.toDouble();
      });
    }

    return metrics.entries.map((e) => MuscleMetric(muscle: e.key, value: e.value)).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  });
});

// --- Movement Proportions ---
final exerciseMetricsProvider = StreamProvider.family<List<MuscleMetric>, (MuscleMetricType, DateTimeRange?)>((ref, arg) {
  final type = arg.$1;
  final range = arg.$2;
  final db = ref.watch(databaseProvider);

  var query = db.select(db.workoutSets).join([
    innerJoin(db.baseExercises, db.baseExercises.id.equalsExp(db.workoutSets.baseExerciseId)),
  ]);

  if (range != null) {
    query.where(db.workoutSets.timestamp.isBetweenValues(range.start, range.end));
  }
  
  query.limit(1000);

  return query.watch().map((rows) {
    final Map<String, double> metrics = {};
    final Map<String, Set<int>> workoutOccurrences = {};

    for (final row in rows) {
      final set = row.readTable(db.workoutSets);
      final exercise = row.readTable(db.baseExercises);
      final fullName = exercise.fullName;

      switch (type) {
        case MuscleMetricType.sets:
          metrics[fullName] = (metrics[fullName] ?? 0) + 1;
          break;
        case MuscleMetricType.reps:
          metrics[fullName] = (metrics[fullName] ?? 0) + set.reps;
          break;
        case MuscleMetricType.tonnage:
          metrics[fullName] = (metrics[fullName] ?? 0) + (set.weight * set.reps);
          break;
        case MuscleMetricType.workouts:
          workoutOccurrences.putIfAbsent(fullName, () => {}).add(set.logId);
          break;
      }
    }

    if (type == MuscleMetricType.workouts) {
      workoutOccurrences.forEach((name, logs) {
        metrics[name] = logs.length.toDouble();
      });
    }

    return metrics.entries.map((e) => MuscleMetric(muscle: e.key, value: e.value)).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  });
});

// --- Timeline State ---
final selectedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1);
});

int getIsoWeek(DateTime date) {
  final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
  return ((dayOfYear - date.weekday + 10) / 7).floor();
}

final timelineProvider = StreamProvider.family<List<TimelineWeek>, DateTime>((ref, month) {
  final db = ref.watch(databaseProvider);
  final startOfMonth = DateTime(month.year, month.month, 1);
  final endOfMonth = DateTime(month.year, month.month + 1, 1).subtract(const Duration(milliseconds: 1));

  final query = db.select(db.workoutLogs).join([
    innerJoin(db.workoutSets, db.workoutSets.logId.equalsExp(db.workoutLogs.id)),
    innerJoin(db.baseExercises, db.baseExercises.id.equalsExp(db.workoutSets.baseExerciseId)),
  ])
    ..where(db.workoutLogs.date.isBetweenValues(startOfMonth, endOfMonth));

  return query.watch().map((rows) {
    final Map<String, List<TypedResult>> groupedByDay = {};
    for (final row in rows) {
      final log = row.readTable(db.workoutLogs);
      final dayKey = "${log.date.year}-${log.date.month}-${log.date.day}";
      groupedByDay.putIfAbsent(dayKey, () => []).add(row);
    }

    final List<TimelineDay> timelineDays = groupedByDay.entries.map((e) {
      final rows = e.value;
      final log = rows.first.readTable(db.workoutLogs);
      
      final Map<String, String> exToPat = {};
      final Set<String> exercises = {};
      
      for (var r in rows) {
        final ex = r.readTable(db.baseExercises);
        exercises.add(ex.fullName);
        exToPat[ex.fullName] = ex.patternType ?? "NONE";
      }

      final fields = rows.map((r) => r.readTable(db.baseExercises).field ?? "NONE").toSet().toList();
      final patterns = rows.map((r) => r.readTable(db.baseExercises).patternType ?? "NONE").toSet().toList();
      final totalVolume = rows.fold(0.0, (sum, r) => sum + (r.readTable(db.workoutSets).weight * r.readTable(db.workoutSets).reps));
      final hasPr = rows.any((r) => r.readTable(db.workoutSets).isPr);

      return TimelineDay(
        date: log.date,
        exercises: exercises.toList(),
        fields: fields,
        patterns: patterns,
        exercisePatterns: exToPat,
        totalVolume: totalVolume,
        hasPr: hasPr,
      );
    }).toList();

    final Map<String, List<TimelineDay>> groupedByWeek = {};
    for (final day in timelineDays) {
      final weekNum = getIsoWeek(day.date);
      final weekKey = "${day.date.year}-W$weekNum";
      groupedByWeek.putIfAbsent(weekKey, () => []).add(day);
    }

    return groupedByWeek.entries.map((e) {
      final parts = e.key.split('-W');
      final year = int.parse(parts[0]);
      final weekNum = int.parse(parts[1]);
      final days = e.value..sort((a, b) => a.date.compareTo(b.date));
      return TimelineWeek(weekNumber: weekNum, year: year, days: days);
    }).toList()..sort((a, b) => (a.year * 100 + a.weekNumber).compareTo(b.year * 100 + b.weekNumber));
  });
});

// --- Other Analytics ---
final oneRmProgressionProvider = StreamProvider.family<List<OneRmPoint>, (int, DateTimeRange?)>((ref, arg) {
  final exerciseId = arg.$1;
  final range = arg.$2;
  final db = ref.watch(databaseProvider);

  var query = db.select(db.workoutSets).join([
    innerJoin(db.workoutLogs, db.workoutLogs.id.equalsExp(db.workoutSets.logId)),
    innerJoin(db.baseExercises, db.baseExercises.id.equalsExp(db.workoutSets.baseExerciseId)),
  ])..where(db.workoutSets.baseExerciseId.equals(exerciseId));

  if (range != null) {
    query.where(db.workoutSets.timestamp.isBetweenValues(range.start, range.end));
  }

  // Use asyncMap to fetch bodyweight per date for LASTRE/JST.BW exercises
  return query.watch().asyncMap((rows) async {
    // Collect unique dates to batch-fetch bodyweight
    final dateKeys = <int>{};
    for (final row in rows) {
      final log = row.readTable(db.workoutLogs);
      dateKeys.add(DateTime(log.date.year, log.date.month, log.date.day).millisecondsSinceEpoch);
    }

    // Cache bodyweight per date
    final Map<int, double> bwCache = {};
    for (final dateMs in dateKeys) {
      final date = DateTime.fromMillisecondsSinceEpoch(dateMs);
      final result = await (db.select(db.anthropometricLogs)
            ..where((t) => t.label.equals('WEIGHT'))
            ..where((t) => t.date.isSmallerOrEqualValue(date))
            ..orderBy([(t) => OrderingTerm.desc(t.date)])
            ..limit(1))
          .getSingleOrNull();
      bwCache[dateMs] = result?.value ?? 0.0;
    }

    return rows.map((row) {
      final set = row.readTable(db.workoutSets);
      final log = row.readTable(db.workoutLogs);
      final exercise = row.readTable(db.baseExercises);

      // Detect load type (matches C.WO logic)
      final intentionText = exercise.intention ?? '';
      final metaMatch = RegExp(r'\[NT:(.*)\|ISO:(.*)\]').firstMatch(intentionText);
      final isL = (metaMatch?.group(1) == 'LASTRE') || exercise.field == 'LASTRE';
      final isJst = (metaMatch?.group(1) == 'JST.BW') || exercise.field == 'JST.BW';

      final dateMs = DateTime(log.date.year, log.date.month, log.date.day).millisecondsSinceEpoch;
      final bw = bwCache[dateMs] ?? 0.0;

      double totalLoad;
      if (isJst) {
        totalLoad = bw; // Bodyweight-only (e.g. pull-ups)
      } else if (isL) {
        totalLoad = set.weight + bw; // Added weight + bodyweight (e.g. weighted pull-ups)
      } else {
        totalLoad = set.weight; // External load only (e.g. bench press)
      }

      return OneRmPoint(
        date: log.date,
        oneRm: WorkoutCalculator.calculateEpley1RM(totalLoad, set.reps),
        weight: set.weight,
        reps: set.reps,
      );
    }).toList()..sort((a, b) => a.date.compareTo(b.date));
  });
});

final phaseFailureProvider = StreamProvider.family<List<PhaseMetric>, (int?, DateTimeRange?)>((ref, arg) {
  final exerciseId = arg.$1;
  final range = arg.$2;
  final db = ref.watch(databaseProvider);

  var query = db.select(db.workoutSets).join([
    innerJoin(db.baseExercises, db.baseExercises.id.equalsExp(db.workoutSets.baseExerciseId)),
  ])..where(db.workoutSets.failurePhase.isNotNull());
  
  if (exerciseId != null) {
    query.where(db.workoutSets.baseExerciseId.equals(exerciseId));
  }
  if (range != null) {
    query.where(db.workoutSets.timestamp.isBetweenValues(range.start, range.end));
  }

  return query.watch().map((rows) {
    final Map<int, int> phases = {};
    final Map<int, String?> phaseNames = {};
    
    for (final row in rows) {
      final set = row.readTable(db.workoutSets);
      final exercise = row.readTable(db.baseExercises);
      final phaseNum = set.failurePhase!;
      
      phases[phaseNum] = (phases[phaseNum] ?? 0) + 1;
      
      if (!phaseNames.containsKey(phaseNum) && exercise.phaseDescriptions != null) {
        try {
          final Map<String, dynamic> descs = jsonDecode(exercise.phaseDescriptions!);
          if (descs.containsKey(phaseNum.toString())) {
            phaseNames[phaseNum] = descs[phaseNum.toString()].toString().toUpperCase();
          }
        } catch (_) {}
      }
    }
    
    return phases.entries.map((e) => PhaseMetric(
      phase: e.key, 
      phaseName: phaseNames[e.key],
      count: e.value
    )).toList()..sort((a, b) => a.phase.compareTo(b.phase));
  });
});

final discomfortMetricsProvider = StreamProvider.family<List<DiscomfortMetric>, DateTimeRange?>((ref, range) {
  final db = ref.watch(databaseProvider);

  return db.customSelect(
    "SELECT tags FROM somatic_logs WHERE tags IS NOT NULL AND tags != ''",
  ).watch().map((rows) {
    final Map<String, int> tags = {};
    for (final row in rows) {
      final tagsStr = (row.data['tags'] as String?) ?? '';
      for (final tag in tagsStr.split(RegExp(r',\s*'))) {
        final trimmed = tag.trim();
        if (trimmed.isNotEmpty) {
          tags[trimmed] = (tags[trimmed] ?? 0) + 1;
        }
      }
    }
    return tags.entries.map((e) => DiscomfortMetric(tag: e.key, count: e.value)).toList()
      ..sort((a, b) => b.count.compareTo(a.count));
  });
});

final discomfortDetailsProvider = StreamProvider.family<List<QueryRow>, DateTime?>((ref, selectedDay) {
  final db = ref.watch(databaseProvider);

  var sql = 'SELECT sl.id, sl.set_id, sl.description, sl.spectrum_value, sl.tags, sl.created_at, be.name AS exercise_name '
      'FROM somatic_logs sl '
      'INNER JOIN workout_sets ws ON ws.id = sl.set_id '
      'INNER JOIN base_exercises be ON be.id = ws.base_exercise_id';

  if (selectedDay != null) {
    final start = DateTime(selectedDay.year, selectedDay.month, selectedDay.day).millisecondsSinceEpoch;
    final end = start + const Duration(days: 1).inMilliseconds;
    sql += ' WHERE sl.created_at >= $start AND sl.created_at < $end';
  }

  sql += ' ORDER BY sl.created_at DESC';

  return db.customSelect(sql).watch();
});
