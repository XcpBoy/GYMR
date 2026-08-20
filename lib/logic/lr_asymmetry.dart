// Pure Dart left/right asymmetry math for LR.ALERT (DATA.NLZR). No Flutter
// imports, no side effects - callers (charts_provider.dart) are
// responsible for pulling sets out of the DB and computing `totalLoad`
// using the same load-type rule as export_service.dart/charts_provider.dart
// (LASTRE/EXT.LOAD/JST.BW/UNMOVABLE), so the EORM numbers here match what
// the rest of the app already shows for that exercise.

/// One logged set, reduced to just what the asymmetry math needs.
class SideSetSample {
  final DateTime date;
  final double totalLoad;
  final double reps;
  final String side; // 'RIGHT' or 'LEFT'

  const SideSetSample({
    required this.date,
    required this.totalLoad,
    required this.reps,
    required this.side,
  });
}

class LrAsymmetryResult {
  final double avgRightEorm;
  final double avgLeftEorm;
  final double asymmetryPct;
  final String? weakSide; // null when there's no usable data on both sides
  final bool isAlert;

  const LrAsymmetryResult({
    required this.avgRightEorm,
    required this.avgLeftEorm,
    required this.asymmetryPct,
    required this.weakSide,
    required this.isAlert,
  });

  static const empty = LrAsymmetryResult(
    avgRightEorm: 0,
    avgLeftEorm: 0,
    asymmetryPct: 0,
    weakSide: null,
    isAlert: false,
  );
}

/// Epley 1RM estimate, same formula as WorkoutCalculator.calculateEpley1RM
/// (kept duplicated here so this file stays Flutter-free/dependency-free;
/// lib/logic/calculator.dart has no Flutter imports either but this avoids
/// coupling the two on principle - it's a one-line formula).
double _epley(double weight, double reps) {
  if (reps <= 0) return 0.0;
  if (reps == 1) return weight;
  return weight * (1 + reps / 30);
}

/// For each side, the best (max) EORM per calendar day.
Map<String, Map<String, double>> bestEormPerSidePerDay(List<SideSetSample> samples) {
  final Map<String, Map<String, double>> bestBySideDay = {'RIGHT': {}, 'LEFT': {}};
  for (final s in samples) {
    if (s.side != 'RIGHT' && s.side != 'LEFT') continue;
    final dayKey = "${s.date.year}-${s.date.month}-${s.date.day}";
    final eorm = _epley(s.totalLoad, s.reps);
    final bucket = bestBySideDay[s.side]!;
    final current = bucket[dayKey];
    if (current == null || eorm > current) bucket[dayKey] = eorm;
  }
  return bestBySideDay;
}

/// Averages the best-per-day EORM across all days present in the window for
/// that side, compares strong vs weak side, and flags an alert when the gap
/// (relative to the strong side) crosses [thresholdPct].
LrAsymmetryResult computeAsymmetry(List<SideSetSample> samples, {double thresholdPct = 10.0}) {
  final bestBySideDay = bestEormPerSidePerDay(samples);

  double avg(Map<String, double> m) => m.isEmpty ? 0.0 : m.values.reduce((a, b) => a + b) / m.length;
  final avgR = avg(bestBySideDay['RIGHT']!);
  final avgL = avg(bestBySideDay['LEFT']!);

  if (avgR == 0 && avgL == 0) return LrAsymmetryResult.empty;

  final strong = avgR >= avgL ? avgR : avgL;
  final weak = avgR >= avgL ? avgL : avgR;
  final pct = strong == 0 ? 0.0 : ((strong - weak) / strong) * 100;
  final weakSide = avgR == avgL ? null : (avgR > avgL ? 'LEFT' : 'RIGHT');

  return LrAsymmetryResult(
    avgRightEorm: avgR,
    avgLeftEorm: avgL,
    asymmetryPct: pct,
    weakSide: weakSide,
    isAlert: weakSide != null && pct > thresholdPct,
  );
}
