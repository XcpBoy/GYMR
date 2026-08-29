import 'package:flutter_test/flutter_test.dart';
import 'package:beyond_performance/logic/kns_search.dart';

void main() {
  group('matchesKnsQuery', () {
    test('matches on shorthand even when it does not appear in the name', () {
      expect(
        matchesKnsQuery('wmu', fullName: 'WEIGHTED MUSCLE UPS', shorthand: 'WMU'),
        isTrue,
      );
    });

    test('matches on the full name as before when shorthand is unset', () {
      expect(
        matchesKnsQuery('muscle', fullName: 'WEIGHTED MUSCLE UPS', shorthand: ''),
        isTrue,
      );
    });

    test('is case-insensitive on both name and shorthand', () {
      expect(matchesKnsQuery('WmU', fullName: 'weighted muscle ups', shorthand: 'wmu'), isTrue);
    });

    test('empty query matches everything', () {
      expect(matchesKnsQuery('', fullName: 'ANYTHING', shorthand: null), isTrue);
    });

    test('does not match unrelated queries', () {
      expect(matchesKnsQuery('bench', fullName: 'WEIGHTED MUSCLE UPS', shorthand: 'WMU'), isFalse);
    });
  });
}
