// Pure math for SLPTRCKR - ported from JRNLR's lib/models/sleep_stats.dart
// (same mechanic: bedAt/wakeAt session, pausedSeconds excluded from
// duration). Separate app/DB, so this is a fresh copy, not a shared import.
import 'dart:math' as math;

import '../database/database.dart';

/// Hours spent in bed for a completed session - null while still open (no
/// [SleepLog.wakeAt] yet). Excludes any tap-to-stop/tap-to-continue pauses.
double? hoursInBed(SleepLog log) {
  if (log.wakeAt == null) return null;
  final rawSeconds = log.wakeAt!.difference(log.bedAt).inSeconds;
  return (rawSeconds - log.pausedSeconds) / 3600.0;
}

/// (day, hours) points for every completed session, sorted oldest→newest,
/// day-keyed by the date the session started (when you went to bed).
List<({DateTime day, double hours})> hoursByDay(List<SleepLog> logs) {
  final points = logs
      .map((l) {
        final hours = hoursInBed(l);
        if (hours == null) return null;
        final d = l.bedAt;
        return (day: DateTime(d.year, d.month, d.day), hours: hours);
      })
      .whereType<({DateTime day, double hours})>()
      .toList()
    ..sort((a, b) => a.day.compareTo(b.day));
  return points;
}

double mean(List<double> xs) {
  if (xs.isEmpty) return 0;
  return xs.reduce((a, b) => a + b) / xs.length;
}

double median(List<double> xs) {
  if (xs.isEmpty) return 0;
  final sorted = [...xs]..sort();
  final mid = sorted.length ~/ 2;
  if (sorted.length.isOdd) return sorted[mid];
  return (sorted[mid - 1] + sorted[mid]) / 2;
}

/// Sample standard deviation (n-1 denominator). 0 for fewer than 2 points
/// rather than dividing by zero.
double stdDev(List<double> xs) {
  if (xs.length < 2) return 0;
  final m = mean(xs);
  final variance =
      xs.map((x) => (x - m) * (x - m)).reduce((a, b) => a + b) /
          (xs.length - 1);
  return math.sqrt(variance);
}

/// Wall-clock elapsed time for a running session, minus every paused
/// stretch - [pausedSeconds] is everything already folded in by a past
/// pause/resume cycle, and [pausedAt] (non-null while currently paused)
/// covers the one still in progress.
Duration activeElapsed({
  required DateTime start,
  required int pausedSeconds,
  required DateTime? pausedAt,
  DateTime? now,
}) {
  final n = now ?? DateTime.now();
  final raw = n.difference(start);
  final paused = Duration(seconds: pausedSeconds) +
      (pausedAt != null ? n.difference(pausedAt) : Duration.zero);
  final result = raw - paused;
  return result.isNegative ? Duration.zero : result;
}
