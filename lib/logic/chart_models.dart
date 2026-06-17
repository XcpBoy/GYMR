import 'package:flutter/material.dart';

class SessionMetric {
  final DateTime date;
  final double volume;
  final int sets;
  final double reps;

  SessionMetric({
    required this.date,
    required this.volume,
    required this.sets,
    required this.reps,
  });
}

class MuscleMetric {
  final String muscle;
  final double value; 
  final Color color;

  MuscleMetric({
    required this.muscle,
    required this.value,
    this.color = Colors.cyan,
  });
}

class AcousticMetric {
  final String trackName;
  final String exerciseName;
  final int count;

  AcousticMetric({
    required this.trackName,
    required this.exerciseName,
    required this.count,
  });
}

class PhaseMetric {
  final int phase;
  final String? phaseName;
  final int count;

  PhaseMetric({
    required this.phase,
    this.phaseName,
    required this.count,
  });
}

class DiscomfortMetric {
  final String tag;
  final int count;

  DiscomfortMetric({
    required this.tag,
    required this.count,
  });
}

class OneRmPoint {
  final DateTime date;
  final double oneRm;
  final double weight;
  final double reps;

  OneRmPoint({
    required this.date,
    required this.oneRm,
    required this.weight,
    required this.reps,
  });
}

// --- NEW: Timeline Models ---

class TimelineDay {
  final DateTime date;
  final List<String> exercises;
  final List<String> fields;
  final List<String> patterns;
  final Map<String, String> exercisePatterns; // Link exercise name to pattern
  final double totalVolume;
  final bool hasPr;

  TimelineDay({
    required this.date,
    required this.exercises,
    required this.fields,
    required this.patterns,
    this.exercisePatterns = const {},
    required this.totalVolume,
    this.hasPr = false,
  });
}

class TimelineWeek {
  final int weekNumber;
  final int year;
  final List<TimelineDay> days;

  TimelineWeek({
    required this.weekNumber,
    required this.year,
    required this.days,
  });
}
