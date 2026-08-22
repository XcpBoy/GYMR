// Pure Dart design-token model for THEME.MDFYR's custom UI importer. No
// Flutter imports - the actual font/texture rendering lives in lib/ui/
// (ui_font_sets.dart, ui_texture_painter.dart), which map the string ids
// here to GoogleFonts/CustomPainters. Kept separate so the token values
// themselves stay trivially JSON-serializable for import/export.
//
// Scope note: this does NOT retheme every one of the ~484 hardcoded
// EdgeInsets calls scattered across individual screens - that would be a
// full app rewrite. It retheme's the shared building blocks every screen
// already goes through: LabStyles (fonts/sizes), LabStyles.hairlineBorder
// (corner radius/border width), MainScaffold (background texture), and the
// hub module grid (layout/visibility). That's enough for a preset to
// visibly change the whole app's character without touching every screen.
class UiTokens {
  final double spacingScale; // multiplies padding in shared widgets, ~0.7-1.4
  final double cornerRadius; // px, 0 = sharp (current app default)
  final double borderWidth; // px, default 0.5 (current app default)
  final String fontSetId; // key into kUiFontSets (lib/ui/ui_font_sets.dart)
  final double headlineSizeMultiplier;
  final double bodySizeMultiplier;
  final double monoSizeMultiplier;
  final double labelSizeMultiplier;
  final String textureId; // key into kUiTextures (lib/ui/ui_texture_painter.dart)
  final double textureIntensity; // 0..1

  const UiTokens({
    required this.spacingScale,
    required this.cornerRadius,
    required this.borderWidth,
    required this.fontSetId,
    required this.headlineSizeMultiplier,
    required this.bodySizeMultiplier,
    required this.monoSizeMultiplier,
    required this.labelSizeMultiplier,
    required this.textureId,
    required this.textureIntensity,
  });

  static const defaults = UiTokens(
    spacingScale: 1.0,
    cornerRadius: 0,
    borderWidth: 0.5,
    fontSetId: 'jetbrains_mono',
    headlineSizeMultiplier: 1.0,
    bodySizeMultiplier: 1.0,
    monoSizeMultiplier: 1.0,
    labelSizeMultiplier: 1.0,
    textureId: 'none',
    textureIntensity: 0.3,
  );

  UiTokens copyWith({
    double? spacingScale,
    double? cornerRadius,
    double? borderWidth,
    String? fontSetId,
    double? headlineSizeMultiplier,
    double? bodySizeMultiplier,
    double? monoSizeMultiplier,
    double? labelSizeMultiplier,
    String? textureId,
    double? textureIntensity,
  }) {
    return UiTokens(
      spacingScale: spacingScale ?? this.spacingScale,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      borderWidth: borderWidth ?? this.borderWidth,
      fontSetId: fontSetId ?? this.fontSetId,
      headlineSizeMultiplier: headlineSizeMultiplier ?? this.headlineSizeMultiplier,
      bodySizeMultiplier: bodySizeMultiplier ?? this.bodySizeMultiplier,
      monoSizeMultiplier: monoSizeMultiplier ?? this.monoSizeMultiplier,
      labelSizeMultiplier: labelSizeMultiplier ?? this.labelSizeMultiplier,
      textureId: textureId ?? this.textureId,
      textureIntensity: textureIntensity ?? this.textureIntensity,
    );
  }

  Map<String, dynamic> toJson() => {
        'spacingScale': spacingScale,
        'cornerRadius': cornerRadius,
        'borderWidth': borderWidth,
        'fontSetId': fontSetId,
        'headlineSizeMultiplier': headlineSizeMultiplier,
        'bodySizeMultiplier': bodySizeMultiplier,
        'monoSizeMultiplier': monoSizeMultiplier,
        'labelSizeMultiplier': labelSizeMultiplier,
        'textureId': textureId,
        'textureIntensity': textureIntensity,
      };

  factory UiTokens.fromJson(Map<String, dynamic> json) {
    double d(String key, double fallback) => (json[key] as num?)?.toDouble() ?? fallback;
    return UiTokens(
      spacingScale: d('spacingScale', defaults.spacingScale),
      cornerRadius: d('cornerRadius', defaults.cornerRadius),
      borderWidth: d('borderWidth', defaults.borderWidth),
      fontSetId: json['fontSetId'] as String? ?? defaults.fontSetId,
      headlineSizeMultiplier: d('headlineSizeMultiplier', defaults.headlineSizeMultiplier),
      bodySizeMultiplier: d('bodySizeMultiplier', defaults.bodySizeMultiplier),
      monoSizeMultiplier: d('monoSizeMultiplier', defaults.monoSizeMultiplier),
      labelSizeMultiplier: d('labelSizeMultiplier', defaults.labelSizeMultiplier),
      textureId: json['textureId'] as String? ?? defaults.textureId,
      textureIntensity: d('textureIntensity', defaults.textureIntensity),
    );
  }
}

class UiPreset {
  final String id;
  final String label;
  final String description;
  final UiTokens tokens;

  const UiPreset({required this.id, required this.label, required this.description, required this.tokens});
}

// 5 built-in presets. 2 are deliberately warm/approachable (WARM_STUDIO,
// SOFT_FOCUS) instead of the app's default lab aesthetic, and one
// (TRAINING_JOURNAL) leans into a handwritten training-notebook feel via
// its font set + paper texture. See ui_font_sets.dart for what each
// fontSetId actually renders.
const List<UiPreset> kBuiltInUiPresets = [
  UiPreset(
    id: 'technical_brutalism',
    label: 'TECHNICAL BRUTALISM',
    description: 'GYMR default - sharp edges, dense mono type, no texture.',
    tokens: UiTokens.defaults,
  ),
  UiPreset(
    id: 'dense_lab',
    label: 'DENSE LAB',
    description: 'Tighter spacing, faint technical grid, IBM Plex Mono.',
    tokens: UiTokens(
      spacingScale: 0.8,
      cornerRadius: 0,
      borderWidth: 0.5,
      fontSetId: 'ibm_plex',
      headlineSizeMultiplier: 0.95,
      bodySizeMultiplier: 0.95,
      monoSizeMultiplier: 0.9,
      labelSizeMultiplier: 0.9,
      textureId: 'grid',
      textureIntensity: 0.18,
    ),
  ),
  UiPreset(
    id: 'warm_studio',
    label: 'WARM STUDIO',
    description: 'Rounded corners, no borders, friendly rounded type.',
    tokens: UiTokens(
      spacingScale: 1.15,
      cornerRadius: 14,
      borderWidth: 0,
      fontSetId: 'nunito',
      headlineSizeMultiplier: 1.05,
      bodySizeMultiplier: 1.05,
      monoSizeMultiplier: 1.0,
      labelSizeMultiplier: 1.0,
      textureId: 'none',
      textureIntensity: 0.0,
    ),
  ),
  UiPreset(
    id: 'soft_focus',
    label: 'SOFT FOCUS',
    description: 'Extra spacing, soft grain texture, rounded geometric type.',
    tokens: UiTokens(
      spacingScale: 1.25,
      cornerRadius: 20,
      borderWidth: 0,
      fontSetId: 'quicksand',
      headlineSizeMultiplier: 1.1,
      bodySizeMultiplier: 1.05,
      monoSizeMultiplier: 1.0,
      labelSizeMultiplier: 1.0,
      textureId: 'noise',
      textureIntensity: 0.08,
    ),
  ),
  UiPreset(
    id: 'training_journal',
    label: 'TRAINING JOURNAL',
    description: 'Handwritten headlines over a ruled paper texture.',
    tokens: UiTokens(
      spacingScale: 1.1,
      cornerRadius: 6,
      borderWidth: 1,
      fontSetId: 'caveat',
      headlineSizeMultiplier: 1.2,
      bodySizeMultiplier: 1.0,
      monoSizeMultiplier: 0.95,
      labelSizeMultiplier: 0.95,
      textureId: 'paper',
      textureIntensity: 0.45,
    ),
  ),
];

UiPreset? uiPresetById(String id) {
  for (final p in kBuiltInUiPresets) {
    if (p.id == id) return p;
  }
  return null;
}
