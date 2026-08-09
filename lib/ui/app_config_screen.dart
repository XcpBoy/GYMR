import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';
import '../providers/database_provider.dart';
import '../database/database.dart';
import '../localization/strings.dart';
import 'styles.dart';
import 'lab_widgets.dart';

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

class AppConfigScreen extends ConsumerStatefulWidget {
  const AppConfigScreen({super.key});

  @override
  ConsumerState<AppConfigScreen> createState() => _AppConfigScreenState();
}

class _AppConfigScreenState extends ConsumerState<AppConfigScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 2, vsync: this);

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
          tabs: [Tab(text: tr(lang, "GENERAL")), Tab(text: tr(lang, "VISUALS"))],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGeneralTab(context),
          _buildVisualsTab(context, settings, tC, lang),
        ],
      ),
      bottomNavigationBar: const LabFooter(),
    );
  }

  Widget _buildGeneralTab(BuildContext context) {
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

  Widget _buildVisualsTab(BuildContext context,
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
      ],
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
