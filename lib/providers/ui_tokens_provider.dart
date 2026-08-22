import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import '../logic/ui_tokens.dart';
import 'theme_provider.dart';

// Same theme_settings KV pattern as every other APPCFG_ setting - no new
// table. One row per token (easy to read/patch individually from the UI),
// plus applyPreset()/importTokensJson() below writing them all at once.
const _kSpacing = 'APPCFG_UI_SPACING';
const _kRadius = 'APPCFG_UI_RADIUS';
const _kBorderWidth = 'APPCFG_UI_BORDER_WIDTH';
const _kFontSet = 'APPCFG_UI_FONT_SET';
const _kFontHeadline = 'APPCFG_UI_FONTSIZE_HEADLINE';
const _kFontBody = 'APPCFG_UI_FONTSIZE_BODY';
const _kFontMono = 'APPCFG_UI_FONTSIZE_MONO';
const _kFontLabel = 'APPCFG_UI_FONTSIZE_LABEL';
const _kTexture = 'APPCFG_UI_TEXTURE';
const _kTextureIntensity = 'APPCFG_UI_TEXTURE_INTENSITY';
const _kActivePreset = 'APPCFG_UI_ACTIVE_PRESET'; // display-only bookkeeping

double _d(Map<String, ThemeSetting> settings, String key, double fallback) {
  final raw = settings[key]?.value;
  if (raw == null) return fallback;
  return double.tryParse(raw) ?? fallback;
}

UiTokens uiTokensFromSettings(Map<String, ThemeSetting> settings) {
  const d = UiTokens.defaults;
  return UiTokens(
    spacingScale: _d(settings, _kSpacing, d.spacingScale),
    cornerRadius: _d(settings, _kRadius, d.cornerRadius),
    borderWidth: _d(settings, _kBorderWidth, d.borderWidth),
    fontSetId: settings[_kFontSet]?.value ?? d.fontSetId,
    headlineSizeMultiplier: _d(settings, _kFontHeadline, d.headlineSizeMultiplier),
    bodySizeMultiplier: _d(settings, _kFontBody, d.bodySizeMultiplier),
    monoSizeMultiplier: _d(settings, _kFontMono, d.monoSizeMultiplier),
    labelSizeMultiplier: _d(settings, _kFontLabel, d.labelSizeMultiplier),
    textureId: settings[_kTexture]?.value ?? d.textureId,
    textureIntensity: _d(settings, _kTextureIntensity, d.textureIntensity),
  );
}

// Derived from themeSettingsProvider (already watched app-wide) rather than
// its own DB query, so token changes ride the same stream everything else
// already listens to.
final uiTokensProvider = Provider<UiTokens>((ref) {
  final settings = ref.watch(themeSettingsProvider).value ?? {};
  return uiTokensFromSettings(settings);
});

final activeUiPresetIdProvider = Provider<String?>((ref) {
  final settings = ref.watch(themeSettingsProvider).value ?? {};
  return settings[_kActivePreset]?.value;
});

extension UiTokensController on ThemeController {
  Future<void> setUiTokens(UiTokens tokens) async {
    await setValue(_kSpacing, tokens.spacingScale.toString());
    await setValue(_kRadius, tokens.cornerRadius.toString());
    await setValue(_kBorderWidth, tokens.borderWidth.toString());
    await setValue(_kFontSet, tokens.fontSetId);
    await setValue(_kFontHeadline, tokens.headlineSizeMultiplier.toString());
    await setValue(_kFontBody, tokens.bodySizeMultiplier.toString());
    await setValue(_kFontMono, tokens.monoSizeMultiplier.toString());
    await setValue(_kFontLabel, tokens.labelSizeMultiplier.toString());
    await setValue(_kTexture, tokens.textureId);
    await setValue(_kTextureIntensity, tokens.textureIntensity.toString());
  }

  Future<void> applyUiPreset(UiPreset preset) async {
    await setUiTokens(preset.tokens);
    await setValue(_kActivePreset, preset.id);
  }

  Future<void> setUiToken({
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
  }) async {
    if (spacingScale != null) await setValue(_kSpacing, spacingScale.toString());
    if (cornerRadius != null) await setValue(_kRadius, cornerRadius.toString());
    if (borderWidth != null) await setValue(_kBorderWidth, borderWidth.toString());
    if (fontSetId != null) await setValue(_kFontSet, fontSetId);
    if (headlineSizeMultiplier != null) await setValue(_kFontHeadline, headlineSizeMultiplier.toString());
    if (bodySizeMultiplier != null) await setValue(_kFontBody, bodySizeMultiplier.toString());
    if (monoSizeMultiplier != null) await setValue(_kFontMono, monoSizeMultiplier.toString());
    if (labelSizeMultiplier != null) await setValue(_kFontLabel, labelSizeMultiplier.toString());
    if (textureId != null) await setValue(_kTexture, textureId);
    if (textureIntensity != null) await setValue(_kTextureIntensity, textureIntensity.toString());
    // Any manual tweak detaches from the "active preset" bookkeeping label.
    await setValue(_kActivePreset, '');
  }

  String exportUiTokensJson(UiTokens tokens) => const JsonEncoder.withIndent('  ').convert(tokens.toJson());

  Future<void> importUiTokensJson(String jsonStr) async {
    final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
    await setUiTokens(UiTokens.fromJson(decoded));
  }
}

// --- HUB layout (module grid order/visibility) ---

const _kHubOrder = 'APPCFG_HUB_ORDER';
const _kHubHidden = 'APPCFG_HUB_HIDDEN';

/// Ordered list of module ids for the hub grid, falling back to
/// [defaultOrder] for any id the user hasn't customized (new modules added
/// later just appear at the end instead of vanishing).
List<String> hubOrderFromSettings(Map<String, ThemeSetting> settings, List<String> defaultOrder) {
  final raw = settings[_kHubOrder]?.value;
  if (raw == null || raw.isEmpty) return defaultOrder;
  final stored = raw.split(',').where((s) => s.isNotEmpty).toList();
  final known = stored.where((id) => defaultOrder.contains(id)).toList();
  final missing = defaultOrder.where((id) => !known.contains(id));
  return [...known, ...missing];
}

Set<String> hubHiddenFromSettings(Map<String, ThemeSetting> settings) {
  final raw = settings[_kHubHidden]?.value;
  if (raw == null || raw.isEmpty) return {};
  return raw.split(',').where((s) => s.isNotEmpty).toSet();
}

extension HubLayoutController on ThemeController {
  Future<void> setHubOrder(List<String> order) => setValue(_kHubOrder, order.join(','));
  Future<void> setHubHidden(Set<String> hidden) => setValue(_kHubHidden, hidden.join(','));
}
