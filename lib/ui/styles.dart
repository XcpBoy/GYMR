import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logic/ui_tokens.dart';
import '../providers/ui_tokens_provider.dart';
import 'ui_font_sets.dart';

class LabColors {
  static const Color background = Color(0xFF000000);
  static const Color surfaceDim = Color(0xFF131313);
  static const Color surfaceContainerLowest = Color(0xFF0E0E0E);
  static const Color surfaceContainerLow = Color(0xFF1B1B1B);
  static const Color surfaceContainer = Color(0xFF1F1F1F);
  static const Color surfaceContainerHigh = Color(0xFF2A2A2A);
  static const Color surfaceBright = Color(0xFF393939);
  static const Color surfaceVariant = Color(0xFF353535);
  
  static const Color primary = Color(0xFF00FFFF); 
  static const Color primaryDim = Color(0xFF00DDDD);
  static const Color primaryFixed = Color(0xFF00FBFB);
  
  static const Color accent = Color(0xFFD4AF37); 
  static const Color secondary = Color(0xFFFFB4A8);
  static const Color tertiary = Color(0xFF77FF61); 
  
  static const Color onSurface = Color(0xFFE2E2E2);
  static const Color onSurfaceVariant = Color(0xFFB9CAC9);
  
  static const Color cyanBorder = Color(0x4D00FFFF); 

  // --- Technical Module Colors ---
  static const Color workoutRed = Color(0xFFFF0000);
  static const Color dashboardRed = Color(0xFF00FFFF); // Back to Neon Cyan
  static const Color inventoryOrange = Color(0xFFFF8C00);
  static const Color blueprintBlue = Color(0xFF0044CC);
  static const Color timelineGrey = Color(0xFF707070);
  static const Color biometricYellow = Color(0xFFEEEE00);
  static const Color visualsNeon = Color(0xFF00FF44);
  static const Color datasetGold = Color(0xFFFFD700);
  static const Color nexusPurple = Color(0xFFAA00FF);
  static const Color themeWhite = Color(0xFFFFFFFF);
  static const Color supersetBlockDefault = Color(0xFF00FA9A);
}

class LabStyles {
  // Reads the derived UiTokens directly off the ProviderContainer instead
  // of via ref.watch, so headline/mono/body/hairlineBorder keep their
  // existing (context, ...) call signatures used across ~30 files. This
  // relies on the calling widget already watching themeSettingsProvider
  // (true nearly everywhere - every screen already reads it for
  // tC.getColor), which is what actually triggers the rebuild that picks
  // up a fresh read here; a screen that never watches theme settings at
  // all won't repaint on a token change until its next rebuild for other
  // reasons. Acceptable for v1 - see PNDEV for the tradeoff.
  static UiFontSet _fontSet(BuildContext context) => uiFontSetOf(uiTokensOf(context).fontSetId);
  static UiTokens uiTokensOf(BuildContext context) => ProviderScope.containerOf(context).read(uiTokensProvider);

  static TextStyle headline(BuildContext context, {Color? color}) {
    final tokens = uiTokensOf(context);
    return _fontSet(context).headline(
      fontSize: 24 * tokens.headlineSizeMultiplier,
      fontWeight: FontWeight.bold,
      color: color ?? LabColors.onSurface,
      letterSpacing: -0.5,
    );
  }

  static TextStyle mono(BuildContext context, {double fontSize = 12, Color? color, FontWeight? fontWeight, TextDecoration? decoration}) {
    final tokens = uiTokensOf(context);
    return _fontSet(context).primary(
      fontSize: fontSize * tokens.monoSizeMultiplier,
      fontWeight: fontWeight ?? FontWeight.normal,
      color: color ?? LabColors.onSurface,
      decoration: decoration,
    );
  }

  static TextStyle body(BuildContext context, {double fontSize = 14, Color? color}) {
    final tokens = uiTokensOf(context);
    return _fontSet(context).body(
      fontSize: fontSize * tokens.bodySizeMultiplier,
      color: color ?? LabColors.onSurface,
    );
  }

  static BoxDecoration hairlineBorder(BuildContext context, {Color color = LabColors.cyanBorder}) {
    final tokens = uiTokensOf(context);
    return BoxDecoration(
      border: Border.all(color: color, width: tokens.borderWidth),
      borderRadius: tokens.cornerRadius > 0 ? BorderRadius.circular(tokens.cornerRadius) : null,
    );
  }

  static BoxDecoration glowBox({Color color = LabColors.primary}) {
    return BoxDecoration(
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: 0.1),
          blurRadius: 10,
          spreadRadius: 2,
        ),
      ],
    );
  }
}

