import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/theme_provider.dart';
import '../providers/ui_tokens_provider.dart';
import '../logic/ui_tokens.dart';
import '../database/database.dart';
import 'styles.dart';
import 'ui_font_sets.dart';
import 'ui_texture_painter.dart';
import 'lab_widgets.dart';
import 'main_hub_screen.dart';

/// THEME.MDFYR's custom UI importer: design tokens (spacing/corner radius/
/// border/font/font size/texture) with 5 built-in presets, JSON export/
/// import, and a hub-layout reorder/hide editor. See lib/logic/ui_tokens.dart
/// for the token model and PNDEV #133 for the scoping discussion (this
/// retheme's the shared widgets every screen goes through, not every one of
/// the ~484 hardcoded EdgeInsets calls scattered across individual screens).
class CustomUiScreen extends ConsumerWidget {
  const CustomUiScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(themeSettingsProvider).value ?? {};
    final tC = ref.read(themeControllerProvider);
    final tokens = ref.watch(uiTokensProvider);
    final activePresetId = ref.watch(activeUiPresetIdProvider);

    return Scaffold(
      backgroundColor: LabColors.background,
      appBar: AppBar(
        backgroundColor: LabColors.background,
        title: Text('CUSTOM_UI', style: LabStyles.mono(context, fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: LabColors.primary),
        actions: [
          IconButton(
            tooltip: 'EXPORT',
            icon: const Icon(Icons.upload_file, color: LabColors.primary),
            onPressed: () => _exportTokens(context, tC, tokens),
          ),
          IconButton(
            tooltip: 'IMPORT',
            icon: const Icon(Icons.download, color: LabColors.primary),
            onPressed: () => _importTokens(context, tC),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionCard(context, 'PRESETS', [
            for (final preset in kBuiltInUiPresets) _presetTile(context, tC, preset, activePresetId == preset.id),
          ]),
          const SizedBox(height: 12),
          _sectionCard(context, 'SPACING & SHAPE', [
            _sliderRow(context, tC, 'SPACING', tokens.spacingScale, 0.7, 1.4, (v) => tC.setUiToken(spacingScale: v)),
            _sliderRow(context, tC, 'CORNER RADIUS', tokens.cornerRadius, 0, 24, (v) => tC.setUiToken(cornerRadius: v), decimals: 0),
            _sliderRow(context, tC, 'BORDER WIDTH', tokens.borderWidth, 0, 2, (v) => tC.setUiToken(borderWidth: v)),
          ]),
          const SizedBox(height: 12),
          _sectionCard(context, 'FONT', [
            _fontPicker(context, tC, tokens),
            const SizedBox(height: 12),
            _sliderRow(context, tC, 'HEADLINE SIZE', tokens.headlineSizeMultiplier, 0.7, 1.4, (v) => tC.setUiToken(headlineSizeMultiplier: v)),
            _sliderRow(context, tC, 'BODY SIZE', tokens.bodySizeMultiplier, 0.7, 1.4, (v) => tC.setUiToken(bodySizeMultiplier: v)),
            _sliderRow(context, tC, 'MONO/PRIMARY SIZE', tokens.monoSizeMultiplier, 0.7, 1.4, (v) => tC.setUiToken(monoSizeMultiplier: v)),
            _sliderRow(context, tC, 'LABEL SIZE', tokens.labelSizeMultiplier, 0.7, 1.4, (v) => tC.setUiToken(labelSizeMultiplier: v)),
          ]),
          const SizedBox(height: 12),
          _sectionCard(context, 'TEXTURE', [
            _texturePicker(context, tC, tokens),
            const SizedBox(height: 12),
            _sliderRow(context, tC, 'INTENSITY', tokens.textureIntensity, 0, 1, (v) => tC.setUiToken(textureIntensity: v)),
          ]),
          const SizedBox(height: 12),
          _sectionCard(context, 'HUB LAYOUT', [
            _HubLayoutEditor(settings: settings, tC: tC),
          ]),
        ],
      ),
      bottomNavigationBar: const LabFooter(),
    );
  }

  Widget _sectionCard(BuildContext context, String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: LabColors.surfaceDim,
        border: Border(top: BorderSide(color: LabColors.primary.withValues(alpha: 0.4), width: 2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: LabStyles.mono(context, fontSize: 11, fontWeight: FontWeight.bold, color: LabColors.primary)),
            const SizedBox(height: 12),
            for (int i = 0; i < children.length; i++) ...[
              children[i],
              if (i != children.length - 1) const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }

  Widget _presetTile(BuildContext context, ThemeController tC, UiPreset preset, bool active) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => tC.applyUiPreset(preset),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: active ? LabColors.primary.withValues(alpha: 0.08) : Colors.transparent,
            border: Border.all(color: active ? LabColors.primary : Colors.grey[800]!, width: active ? 1 : 0.5),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(preset.label, style: LabStyles.mono(context, fontWeight: FontWeight.bold, fontSize: 11, color: active ? LabColors.primary : Colors.white)),
                    const SizedBox(height: 2),
                    Text(preset.description, style: LabStyles.mono(context, fontSize: 8, color: Colors.grey)),
                  ],
                ),
              ),
              if (active) const Icon(Icons.check, color: LabColors.primary, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sliderRow(BuildContext context, ThemeController tC, String label, double value, double min, double max, void Function(double) onChanged, {int decimals = 2}) {
    return Row(
      children: [
        SizedBox(width: 110, child: Text(label, style: LabStyles.mono(context, fontSize: 9, color: Colors.grey))),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: LabColors.primary,
              inactiveTrackColor: LabColors.surfaceBright,
              thumbColor: LabColors.primary,
              trackHeight: 2,
            ),
            child: Slider(value: value.clamp(min, max), min: min, max: max, onChanged: onChanged),
          ),
        ),
        SizedBox(
          width: 44,
          child: Text(value.toStringAsFixed(decimals), textAlign: TextAlign.right, style: LabStyles.mono(context, fontSize: 9, fontWeight: FontWeight.bold, color: LabColors.primary)),
        ),
      ],
    );
  }

  Widget _fontPicker(BuildContext context, ThemeController tC, UiTokens tokens) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: kUiFontSets.values.map((set) {
        final active = tokens.fontSetId == set.id;
        return InkWell(
          onTap: () => tC.setUiToken(fontSetId: set.id),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: active ? LabColors.primary.withValues(alpha: 0.12) : Colors.transparent,
              border: Border.all(color: active ? LabColors.primary : Colors.grey[800]!, width: 0.5),
            ),
            child: Text(set.label, style: set.primary(fontSize: 10, fontWeight: FontWeight.bold, color: active ? LabColors.primary : Colors.white)),
          ),
        );
      }).toList(),
    );
  }

  Widget _texturePicker(BuildContext context, ThemeController tC, UiTokens tokens) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: kUiTextureIds.map((id) {
        final active = tokens.textureId == id;
        return InkWell(
          onTap: () => tC.setUiToken(textureId: id),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: active ? LabColors.primary.withValues(alpha: 0.12) : Colors.transparent,
              border: Border.all(color: active ? LabColors.primary : Colors.grey[800]!, width: 0.5),
            ),
            child: Text(kUiTextureLabels[id]!, style: LabStyles.mono(context, fontSize: 9, fontWeight: FontWeight.bold, color: active ? LabColors.primary : Colors.white)),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _exportTokens(BuildContext context, ThemeController tC, UiTokens tokens) async {
    final json = tC.exportUiTokensJson(tokens);
    final bytes = Uint8List.fromList(json.codeUnits);
    final fileName = 'gymr_custom_ui_${DateTime.now().millisecondsSinceEpoch}.json';
    await FilePicker.platform.saveFile(fileName: fileName, bytes: bytes);
  }

  Future<void> _importTokens(BuildContext context, ThemeController tC) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result == null || result.files.single.path == null) return;
    try {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      await tC.importUiTokensJson(content);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CUSTOM_UI_IMPORTED'), backgroundColor: LabColors.primary));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('IMPORT_FAILED: $e'), backgroundColor: Colors.redAccent));
      }
    }
  }
}

class _HubLayoutEditor extends StatefulWidget {
  final Map<String, ThemeSetting> settings;
  final ThemeController tC;

  const _HubLayoutEditor({required this.settings, required this.tC});

  @override
  State<_HubLayoutEditor> createState() => _HubLayoutEditorState();
}

class _HubLayoutEditorState extends State<_HubLayoutEditor> {
  late List<String> _order;
  late Set<String> _hidden;

  @override
  void initState() {
    super.initState();
    _order = hubOrderFromSettings(widget.settings, kHubModuleSpecs.map((s) => s.id).toList());
    _hidden = hubHiddenFromSettings(widget.settings);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > oldIndex) newIndex -= 1;
              final id = _order.removeAt(oldIndex);
              _order.insert(newIndex, id);
            });
            widget.tC.setHubOrder(_order);
          },
          children: [
            for (int i = 0; i < _order.length; i++)
              _hubRow(context, key: ValueKey(_order[i]), index: i, id: _order[i]),
          ],
        ),
      ],
    );
  }

  Widget _hubRow(BuildContext context, {required Key key, required int index, required String id}) {
    final spec = kHubModuleSpecs.firstWhere((s) => s.id == id);
    final hidden = _hidden.contains(id);
    return Padding(
      key: key,
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: index,
            child: const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.drag_handle, color: Colors.grey, size: 18),
            ),
          ),
          Icon(spec.icon, color: hidden ? Colors.grey[700] : spec.defaultColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(spec.label, style: LabStyles.mono(context, fontSize: 10, fontWeight: FontWeight.bold, color: hidden ? Colors.grey : Colors.white)),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(hidden ? Icons.visibility_off : Icons.visibility, color: hidden ? Colors.grey : LabColors.primary, size: 18),
            onPressed: () {
              setState(() {
                if (hidden) {
                  _hidden.remove(id);
                } else {
                  _hidden.add(id);
                }
              });
              widget.tC.setHubHidden(_hidden);
            },
          ),
        ],
      ),
    );
  }
}
