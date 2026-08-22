// Builds the real app once per built-in UI preset and pumps a frame,
// catching any TextStyle/Border/Slider assertion the way the crash from
// PNDEV #133/#134 (TextTheme.apply(fontSizeFactor:) asserting on any
// bodySizeMultiplier != 1.0) would have shown up here if this test had
// existed first. Exists so a future token added to a preset that breaks
// some Flutter widget's assertion fails loudly in CI instead of on a
// phone mid-workout.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';

import 'package:beyond_performance/database/database.dart';
import 'package:beyond_performance/providers/database_provider.dart';
import 'package:beyond_performance/providers/theme_provider.dart';
import 'package:beyond_performance/providers/ui_tokens_provider.dart';
import 'package:beyond_performance/logic/ui_tokens.dart';
import 'package:beyond_performance/main.dart';

AppDatabase _testDb() => AppDatabase.forTesting(NativeDatabase.memory());

void main() {
  for (final preset in kBuiltInUiPresets) {
    testWidgets('${preset.id} preset builds without throwing', (tester) async {
      final db = _testDb();
      addTearDown(db.close);
      final tC = ThemeController(db);
      await tC.applyUiPreset(preset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: const BeyondPerformanceApp(),
        ),
      );
      // Let the theme_settings stream (which uiTokensProvider derives from)
      // deliver the freshly-written preset before asserting.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull, reason: 'Preset ${preset.id} threw during build/layout');

      // Drift's StreamQueryStore schedules a same-tick zero-duration Timer
      // when a watched query stream is torn down; the test binding asserts
      // no pending timers survive the widget tree's disposal. One more pump
      // lets that timer fire before the test ends - unrelated to the app
      // itself, just Drift + the test binding's teardown ordering.
      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    });
  }
}
