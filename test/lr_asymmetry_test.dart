import 'package:flutter_test/flutter_test.dart';
import 'package:beyond_performance/logic/lr_asymmetry.dart';

void main() {
  group('computeAsymmetry', () {
    test('flags a clear imbalance with the correct weak side', () {
      // Same weight both sides, but LEFT does far fewer reps -> lower EORM.
      final samples = [
        SideSetSample(date: DateTime(2026, 1, 1), totalLoad: 40, reps: 20, side: 'RIGHT'),
        SideSetSample(date: DateTime(2026, 1, 1), totalLoad: 40, reps: 3, side: 'LEFT'),
      ];

      final result = computeAsymmetry(samples, thresholdPct: 10);

      expect(result.weakSide, 'LEFT');
      expect(result.isAlert, isTrue);
      expect(result.asymmetryPct, greaterThan(10));
    });

    test('does not alert when both sides are close', () {
      final samples = [
        SideSetSample(date: DateTime(2026, 1, 1), totalLoad: 40, reps: 10, side: 'RIGHT'),
        SideSetSample(date: DateTime(2026, 1, 1), totalLoad: 40, reps: 9, side: 'LEFT'),
      ];

      final result = computeAsymmetry(samples, thresholdPct: 10);

      expect(result.isAlert, isFalse);
    });

    test('takes the best set per day per side, not an average of all sets', () {
      final samples = [
        SideSetSample(date: DateTime(2026, 1, 1), totalLoad: 20, reps: 5, side: 'RIGHT'),
        SideSetSample(date: DateTime(2026, 1, 1), totalLoad: 40, reps: 8, side: 'RIGHT'), // best set of the day
        SideSetSample(date: DateTime(2026, 1, 1), totalLoad: 40, reps: 8, side: 'LEFT'),
      ];

      final result = computeAsymmetry(samples);

      expect(result.avgRightEorm, result.avgLeftEorm);
      expect(result.weakSide, isNull);
    });

    test('returns empty when there is no unilateral data', () {
      final result = computeAsymmetry(const []);
      expect(result.weakSide, isNull);
      expect(result.isAlert, isFalse);
    });
  });
}
