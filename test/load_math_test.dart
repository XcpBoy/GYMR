// Regression test for lib/logic/load_math.dart - the shared load-type
// detection + effective-load calculation that replaced five independent
// (and silently diverging) copies of this logic across export_service.dart,
// workout_manager.dart, WB.editor.dart, charts_provider.dart and
// full_dataset_screen.dart (see the assistance/bands overhaul, schema v34).
import 'package:flutter_test/flutter_test.dart';
import 'package:beyond_performance/logic/load_math.dart';

void main() {
  group('detectLoadDetails', () {
    test('reads type/isometric from the [NT:...|ISO:...] bracket', () {
      final d = detectLoadDetails(intention: '[NT:LASTRE|ISO:true] pull');
      expect(d.type, 'LASTRE');
      expect(d.isIsometric, isTrue);
    });

    test('BANDED is no longer recognized - legacy un-migrated rows fall '
        'back to EXT.LOAD, exactly like every load-type switch already '
        'silently treated BANDED before the v34 migration', () {
      final d = detectLoadDetails(intention: '[NT:BANDED|ISO:false] curl');
      expect(d.type, 'BANDED');
      // detectLoadDetails itself is a pure regex reader (it trusts the
      // bracket verbatim) - it's computeEffectiveLoad's switch, not this
      // function, that no longer has a BANDED case and falls through to
      // the EXT.LOAD-shaped default. The real migration (database.dart
      // v34) rewrites the bracket to EXT.LOAD outright, so BANDED should
      // never actually reach here on a migrated database.
    });

    test('falls back to tissueName/field when there is no bracket', () {
      expect(detectLoadDetails(tissueName: 'JST.BW').type, 'JST.BW');
      expect(detectLoadDetails(field: 'UNMOVABLE').type, 'UNMOVABLE');
      expect(detectLoadDetails().type, 'EXT.LOAD');
    });

    test('tissueName takes priority over field', () {
      expect(
          detectLoadDetails(tissueName: 'LASTRE', field: 'JST.BW').type,
          'LASTRE');
    });
  });

  group('computeEffectiveLoad', () {
    test('EXT.LOAD: modifier applies directly to raw weight', () {
      expect(
          computeEffectiveLoad(loadType: 'EXT.LOAD', rawWeight: 60, bodyweight: 80),
          60);
      // negative = assisted (a band/machine reduces effective load)
      expect(
          computeEffectiveLoad(
              loadType: 'EXT.LOAD',
              rawWeight: 60,
              bodyweight: 80,
              resistanceModifier: -15),
          45);
      // positive = added band resistance (accommodating resistance)
      expect(
          computeEffectiveLoad(
              loadType: 'EXT.LOAD',
              rawWeight: 60,
              bodyweight: 80,
              resistanceModifier: 10),
          70);
    });

    test('JST.BW: only bodyweight + modifier, raw weight ignored', () {
      expect(
          computeEffectiveLoad(loadType: 'JST.BW', rawWeight: 999, bodyweight: 80),
          80);
      expect(
          computeEffectiveLoad(
              loadType: 'JST.BW',
              rawWeight: 999,
              bodyweight: 80,
              resistanceModifier: -20),
          60,
          reason: 'assisted pull-up: bodyweight minus assistance');
    });

    test('LASTRE and UNMOVABLE: raw weight + bodyweight + modifier', () {
      expect(
          computeEffectiveLoad(loadType: 'LASTRE', rawWeight: 20, bodyweight: 80),
          100);
      expect(
          computeEffectiveLoad(
              loadType: 'UNMOVABLE',
              rawWeight: 20,
              bodyweight: 80,
              resistanceModifier: 5),
          105);
    });

    test('never returns negative, even with an assistance modifier larger '
        'than the raw load', () {
      expect(
          computeEffectiveLoad(
              loadType: 'EXT.LOAD',
              rawWeight: 10,
              bodyweight: 0,
              resistanceModifier: -50),
          0);
    });

    test('an unrecognized/legacy BANDED loadType degrades to the EXT.LOAD '
        'shape (no case for it, falls through to default) - matches what '
        'every totalLoad switch already did before this file existed', () {
      expect(
          computeEffectiveLoad(
              loadType: 'BANDED', rawWeight: 40, bodyweight: 80, resistanceModifier: 8),
          48);
    });
  });
}
