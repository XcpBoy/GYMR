import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';
import '../providers/database_provider.dart';
import '../database/database.dart';
import '../localization/strings.dart';
import 'styles.dart';
import 'lab_widgets.dart';
import '../services/export_service.dart';

// A single app-wide toggle: label + persisted key + default state.
class _ConfigToggle {
  final String label;
  final String key;
  final bool defaultValue;
  const _ConfigToggle(this.label, this.key, {this.defaultValue = true});
}

// Toggles that live under VISUALS > C.WO. Adding a new one is a one-line
// addition here.
const List<_ConfigToggle> _cwoToggles = [
  _ConfigToggle("TOGGLES", "APPCFG_SHOW_KNS_TOGGLES"),
  _ConfigToggle("FAILURE.PHASE", "APPCFG_SHOW_FAILURE_PHASE"),
];

// Toggles that live under VISUALS > EDIT_EXERCISE. Each one hides the
// matching field from EDIT_EXERCISE and EXERCISE_CREATOR when off - see
// _fieldVisible() in both screens. Default true so nothing changes for
// existing users until they turn one off.
// PDF report column visibility, under NEXUS_CONFIG > PDF_COLUMNS. Backed by
// ExportService.kPdfColumnKeys/kPdfColumnLabels so the toggle list and the
// PDF-building code (exportWorkoutsToPdf) stay in sync automatically.
final List<_ConfigToggle> _pdfColumnToggles = [
  for (final key in ExportService.kPdfColumnKeys)
    _ConfigToggle(ExportService.kPdfColumnLabels[key]!, 'APPCFG_PDF_COL_$key'),
];

const List<_ConfigToggle> _editExerciseToggles = [
  _ConfigToggle("SECONDARY MUSCLE", "APPCFG_SHOW_SECONDARY_MUSCLE"),
  _ConfigToggle("PATTERN TYPE", "APPCFG_SHOW_PATTERN_TYPE"),
  _ConfigToggle("PURPOSE / INTENTION", "APPCFG_SHOW_PURPOSE"),
  _ConfigToggle("TYPE OF TISSUE", "APPCFG_SHOW_TISSUE_TYPE"),
  _ConfigToggle("NAME OF TISSUE", "APPCFG_SHOW_TISSUE_NAME"),
  _ConfigToggle("PHASES", "APPCFG_SHOW_PHASES"),
];

class AppConfigScreen extends ConsumerStatefulWidget {
  const AppConfigScreen({super.key});

  @override
  ConsumerState<AppConfigScreen> createState() => _AppConfigScreenState();
}

class _AppConfigScreenState extends ConsumerState<AppConfigScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 4, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(themeSettingsProvider).value ?? {};
    final tC = ref.read(themeControllerProvider);
    final lang = ref.watch(languageProvider).value ?? 'en';

    return Scaffold(
      backgroundColor: LabColors.background,
      appBar: AppBar(
        backgroundColor: LabColors.background,
        title: Text(tr(lang, "APP.CONFIG"),
            style: LabStyles.mono(context, fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: LabColors.onSurfaceVariant),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: LabColors.onSurfaceVariant,
          indicatorWeight: 2,
          labelColor: LabColors.onSurfaceVariant,
          unselectedLabelColor: Colors.grey[600],
          labelStyle:
              LabStyles.mono(context, fontSize: 10, fontWeight: FontWeight.bold),
          unselectedLabelStyle: LabStyles.mono(context, fontSize: 10),
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(text: tr(lang, "GENERAL")),
            Tab(text: "UI_LOCATIONS"),
            Tab(text: "NEXUS_CONFIG"),
            Tab(text: "TOGGLES"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGeneralTab(context, settings, tC),
          _buildUiLocationsTab(context, settings, tC),
          _buildNexusConfigTab(context, settings, tC),
          _buildTogglesTab(context, settings, tC, lang),
        ],
      ),
      bottomNavigationBar: const LabFooter(),
    );
  }

  Widget _buildGeneralTab(BuildContext context,
      Map<String, ThemeSetting> settings, ThemeController tC) {
    final lang = ref.watch(languageProvider).value ?? 'en';
    final db = ref.read(databaseProvider);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(context, tr(lang, "LANGUAGE"), [
          Row(
            children: [
              Expanded(
                child: _buildLayoutOption(context, "ENGLISH", lang == 'en',
                    () => setLanguage(db, 'en')),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildLayoutOption(context, "ESPAÑOL", lang == 'es',
                    () => setLanguage(db, 'es')),
              ),
            ],
          ),
        ]),
        const SizedBox(height: 12),
        _buildSectionCard(context, tr(lang, "RESET"), [
          SizedBox(
            width: double.infinity,
            child: LabButton(
              label: tr(lang, "RESET COLORS TO DEFAULT"),
              color: Colors.redAccent,
              onPressed: () => _confirmResetColors(context, lang),
            ),
          ),
        ]),
      ],
    );
  }

  Widget _buildUiLocationsTab(BuildContext context,
      Map<String, ThemeSetting> settings, ThemeController tC) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(context, "BOTTOM_RIBBON", [
          for (int i = 0; i < 4; i++) ...[
            _buildRibbonSlotPicker(context, settings, tC, i),
            if (i != 3) const SizedBox(height: 12),
          ],
        ]),
      ],
    );
  }

  Widget _buildNexusConfigTab(BuildContext context,
      Map<String, ThemeSetting> settings, ThemeController tC) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(context, "PDF_COLUMNS", [
          for (final t in _pdfColumnToggles) ...[
            _buildToggleRow(context, settings, tC, t),
            const SizedBox(height: 12),
          ],
        ]),
      ],
    );
  }

  Widget _buildTogglesTab(BuildContext context,
      Map<String, ThemeSetting> settings, ThemeController tC, String lang) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(context, "C.WO", [
          for (final t in _cwoToggles) ...[
            _buildToggleRow(context, settings, tC, t),
            const SizedBox(height: 12),
          ],
          _buildKnsFaceLayoutPicker(context, settings, tC, lang),
        ]),
        const SizedBox(height: 12),
        _buildSectionCard(context, "EDIT_EXERCISE", [
          for (final t in _editExerciseToggles) ...[
            _buildToggleRow(context, settings, tC, t),
            const SizedBox(height: 12),
          ],
        ]),
      ],
    );
  }

  Widget _buildRibbonSlotPicker(BuildContext context,
      Map<String, ThemeSetting> settings, ThemeController tC, int slot) {
    final currentId = tC.getValue(settings, 'APPCFG_RIBBON_SLOT_$slot') ??
        kDefaultRibbonSlots[slot];
    final dest = ribbonDestinationById(currentId);
    return InkWell(
      onTap: () => _showRibbonSlotSheet(context, tC, slot),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(dest.icon, color: LabColors.onSurfaceVariant, size: 16),
              const SizedBox(width: 8),
              Text('SLOT ${slot + 1}',
                  style: LabStyles.mono(context, fontSize: 10, color: Colors.grey[500])),
            ],
          ),
          Row(
            children: [
              Text(dest.label,
                  style: LabStyles.mono(context,
                      fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
            ],
          ),
        ],
      ),
    );
  }

  void _showRibbonSlotSheet(BuildContext context, ThemeController tC, int slot) {
    showModalBottomSheet(
      context: context,
      backgroundColor: LabColors.background,
      isScrollControlled: true,
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SLOT ${slot + 1} DESTINATION',
                  style: LabStyles.headline(context).copyWith(fontSize: 14)),
              const SizedBox(height: 16),
              for (final dest in kRibbonDestinations)
                ListTile(
                  leading: Icon(dest.icon, color: dest.defaultColor),
                  title: Text(dest.label,
                      style: LabStyles.mono(context, fontSize: 12, color: Colors.white)),
                  onTap: () {
                    tC.setValue('APPCFG_RIBBON_SLOT_$slot', dest.id);
                    Navigator.pop(c);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKnsFaceLayoutPicker(BuildContext context,
      Map<String, ThemeSetting> settings, ThemeController tC, String lang) {
    final isOriginal = tC.getBool(
        settings, 'APPCFG_KNS_FACE_LAYOUT_ORIGINAL',
        defaultValue: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr(lang, "KNS CARD FACE"),
            style: LabStyles.mono(context, fontSize: 10, color: Colors.white)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildLayoutOption(context, tr(lang, "NEW"), !isOriginal,
                  () => tC.setBool('APPCFG_KNS_FACE_LAYOUT_ORIGINAL', false)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildLayoutOption(context, tr(lang, "ORIGINAL"), isOriginal,
                  () => tC.setBool('APPCFG_KNS_FACE_LAYOUT_ORIGINAL', true)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLayoutOption(
      BuildContext context, String label, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? LabColors.onSurfaceVariant.withValues(alpha: 0.15)
              : Colors.transparent,
          border: Border.all(
              color: selected ? LabColors.onSurfaceVariant : Colors.grey[800]!,
              width: selected ? 1.5 : 0.5),
        ),
        child: Text(label,
            style: LabStyles.mono(context,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: selected ? LabColors.onSurfaceVariant : Colors.grey[500])),
      ),
    );
  }

  Widget _buildSectionCard(
      BuildContext context, String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: LabColors.surfaceDim,
        border: Border(
          top: BorderSide(
              color: LabColors.onSurfaceVariant.withValues(alpha: 0.4),
              width: 2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: LabStyles.mono(context,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: LabColors.onSurfaceVariant)),
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

  Widget _buildToggleRow(BuildContext context,
      Map<String, ThemeSetting> settings, ThemeController tC, _ConfigToggle t) {
    final value = tC.getBool(settings, t.key, defaultValue: t.defaultValue);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(t.label,
            style: LabStyles.mono(context, fontSize: 10, color: Colors.white)),
        Switch(
          value: value,
          activeColor: LabColors.onSurfaceVariant,
          onChanged: (v) => tC.setBool(t.key, v),
        ),
      ],
    );
  }

  void _confirmResetColors(BuildContext context, String lang) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: LabColors.background,
        title: Text('RESET_COLORS',
            style: LabStyles.headline(c).copyWith(fontSize: 14)),
        content: Text(
            tr(lang,
                'This will erase every color you\'ve customized across the whole app and restore defaults. Wallpaper and toggle settings are not affected.\n\nThis cannot be undone.'),
            style: LabStyles.mono(c, fontSize: 11, color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text(tr(lang, 'CANCEL'), style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(themeControllerProvider).resetAllColors();
              if (c.mounted) Navigator.pop(c);
            },
            child: Text(tr(lang, 'RESET'), style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
