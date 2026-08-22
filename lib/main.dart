import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ui/home_screen.dart';
import 'ui/styles.dart';
import 'ui/ui_font_sets.dart';
import 'providers/ui_tokens_provider.dart';

void main() {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const ProviderScope(
      child: BeyondPerformanceApp(),
    ),
  );
}

class BeyondPerformanceApp extends ConsumerWidget {
  const BeyondPerformanceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watched here (root) so the app-wide ThemeData (used by Slider/Switch/
    // etc Material widgets, not just LabStyles-driven text) reacts to
    // THEME.MDFYR's custom UI tokens too.
    final tokens = ref.watch(uiTokensProvider);

    return MaterialApp(
      title: 'BeyondPerformance',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: LabColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: LabColors.primary,
          brightness: Brightness.dark,
          surface: LabColors.background,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
          fontSizeFactor: tokens.bodySizeMultiplier,
        ),
        primaryTextTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        // Material widgets (Slider, buttons, dialogs) rounding follows the
        // cornerRadius token so a warm/rounded preset feels consistent even
        // where LabStyles.hairlineBorder isn't the thing drawing the shape.
        cardTheme: CardThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(tokens.cornerRadius))),
        dialogTheme: DialogThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(tokens.cornerRadius))),
      ),
      home: const HomeScreen(),
    );
  }
}

// Exposed so any widget can resolve the active font set without needing its
// own provider watch, mirroring LabStyles' pattern.
UiFontSet activeUiFontSet(BuildContext context) => uiFontSetOf(LabStyles.uiTokensOf(context).fontSetId);
