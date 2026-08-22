import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';
import '../database/database.dart';
import 'styles.dart';
import 'blueprint_manager.dart';
import 'ledger_screen.dart';
import 'workout_manager.dart';
import 'anthropometric_data_screen.dart';
import 'full_dataset_screen.dart';
import 'data_analyzer_screen.dart';
import 'timeline_screen.dart';
import 'theme_modding_screen.dart';
import 'nexus_screen.dart';
import 'db_inspector_screen.dart';
import 'ovarch_plan_screen.dart';
import 'somatic_spectrum_screen.dart' as somatic;
import 'app_config_screen.dart';
import '../localization/strings.dart';
import '../providers/ui_tokens_provider.dart';

// One entry per hub grid card: stable id (used for order/hidden persistence
// - never renamed even if `label` changes) + how to render/navigate it.
// THEME.MDFYR's hub layout editor reorders/hides these by id via
// hubOrderFromSettings/hubHiddenFromSettings (ui_tokens_provider.dart).
class HubModuleSpec {
  final String id;
  final String label;
  final IconData icon;
  final Color defaultColor;
  final WidgetBuilder screenBuilder;

  const HubModuleSpec({required this.id, required this.label, required this.icon, required this.defaultColor, required this.screenBuilder});
}

final List<HubModuleSpec> kHubModuleSpecs = [
  HubModuleSpec(id: 'CRRNT_WO', label: 'CRRNT.WO', icon: Icons.fitness_center, defaultColor: LabColors.workoutRed, screenBuilder: (c) => const WorkoutManagerScreen()),
  HubModuleSpec(id: 'KNS_INVTRY', label: 'KNS.INVTRY', icon: Icons.receipt_long, defaultColor: LabColors.inventoryOrange, screenBuilder: (c) => const LedgerScreen()),
  HubModuleSpec(id: 'WO_BLCKS', label: 'WO.BLCKS', icon: Icons.view_module_rounded, defaultColor: LabColors.blueprintBlue, screenBuilder: (c) => const BlueprintManagerScreen()),
  HubModuleSpec(id: 'TMNLN', label: 'TMNLN', icon: Icons.schedule, defaultColor: LabColors.timelineGrey, screenBuilder: (c) => const TimelineScreen()),
  HubModuleSpec(id: 'ANTRPMT_DT', label: 'ANTRPMT.DT', icon: Icons.straighten, defaultColor: LabColors.biometricYellow, screenBuilder: (c) => const AnthropometricDataScreen()),
  HubModuleSpec(id: 'DT_PRCSR', label: 'DT.PRCSR', icon: Icons.query_stats, defaultColor: LabColors.visualsNeon, screenBuilder: (c) => const DataAnalyzerScreen()),
];

class MainHubScreen extends ConsumerWidget {
  const MainHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(themeSettingsProvider).value ?? {};
    final tC = ref.read(themeControllerProvider);
    final lang = ref.watch(languageProvider).value ?? 'en';

    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCoreModulesGrid(context, settings, tC, lang),
          const SizedBox(height: 12),
          _buildNexusModule(context, settings, tC, lang),
          const SizedBox(height: 12),
          _buildDatasetModule(context, settings, tC, lang),
          const SizedBox(height: 12),
          _buildThemeModule(context, settings, tC, lang),
          const SizedBox(height: 12),
          _buildPlanningModule(context, settings, tC, lang),
          const SizedBox(height: 12),
          _buildDBInspectorModule(context, settings, tC, lang),
          const SizedBox(height: 12),
          _buildSomaticLogsModule(context, settings, tC, lang),
          const SizedBox(height: 12),
          _buildAppConfigModule(context, settings, tC, lang),
          /* _buildPRLogicModule(context, settings, tC), — BACKGROUNDED */
        ],
      ),
    );
  }

  Widget _buildPlanningModule(BuildContext context, Map<String, ThemeSetting> settings, ThemeController tC, String lang) {
    final color = tC.getColor(settings, "DASHBOARD_CARD_PLANNING", defaultColor: LabColors.primary);
    final bgColor = tC.getColor(settings, "DASHBOARD_CARD_PLANNING_BG", defaultColor: color.withValues(alpha: 0.08));

    return Material(
      color: bgColor,
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const OvarchPlanScreen()));
        },
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Icon(Icons.event_note, color: color, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('OVERARCHING_PROGRAM_PLN', style: LabStyles.mono(context, fontSize: 8, color: color.withValues(alpha: 0.7))),
                    Text(tr(lang, '10 OVARCH PLAN'), style: LabStyles.headline(context, color: Colors.white).copyWith(fontSize: 16, letterSpacing: 2)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDBInspectorModule(BuildContext context, Map<String, ThemeSetting> settings, ThemeController tC, String lang) {
    final color = tC.getColor(settings, "DASHBOARD_CARD_DB.EDIT", defaultColor: LabColors.accent);
    final bgColor = tC.getColor(settings, "DASHBOARD_CARD_DB.EDIT_BG", defaultColor: color.withValues(alpha: 0.08));

    return Material(
      color: bgColor,
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const DBInspectorScreen()));
        },
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Icon(Icons.table_chart_outlined, color: color, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('DATABASE_EDIT_INSPECT', style: LabStyles.mono(context, fontSize: 8, color: color.withValues(alpha: 0.7))),
                    Text('11 ${tr(lang, 'DB.EDIT')}', style: LabStyles.headline(context, color: Colors.white).copyWith(fontSize: 16, letterSpacing: 2)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSomaticLogsModule(BuildContext context, Map<String, ThemeSetting> settings, ThemeController tC, String lang) {
    final color = tC.getColor(settings, "DASHBOARD_CARD_SOMATIC_SPECTRUM", defaultColor: LabColors.tertiary.withValues(alpha: 0.8));
    final bgColor = tC.getColor(settings, "DASHBOARD_CARD_SOMATIC_SPECTRUM_BG", defaultColor: color.withValues(alpha: 0.08));

    return Material(
      color: bgColor,
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const somatic.SomaticLogsScreen()));
        },
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Icon(Icons.healing, color: color, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('SPECTRUM_FOLDERS_LOGS', style: LabStyles.mono(context, fontSize: 8, color: color.withValues(alpha: 0.7))),
                    Text('12 ${tr(lang, 'SOMATIC_SPECTRUM')}', style: LabStyles.headline(context, color: Colors.white).copyWith(fontSize: 16, letterSpacing: 2)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }

  /* BACKGROUNDED — PR.LOGIC not in use
  Widget _buildPRLogicModule(BuildContext context, Map<String, ThemeSetting> settings, ThemeController tC) {
    final color = tC.getColor(settings, "DASHBOARD_CARD_PR.LOGIC", defaultColor: LabColors.accent);
    final bgColor = tC.getColor(settings, "DASHBOARD_CARD_PR.LOGIC_BG", defaultColor: color.withValues(alpha: 0.08));
    return Material(
      color: bgColor,
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const PRLogicScreen()));
        },
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Icon(Icons.query_stats, color: color, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('PERFORMANCE_ALGORITHM_DATA', style: LabStyles.mono(context, fontSize: 8, color: color.withValues(alpha: 0.7))),
                    Text('11 PR.LOGIC', style: LabStyles.headline(context, color: Colors.white).copyWith(fontSize: 16, letterSpacing: 2)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
  */

  Widget _buildCoreModulesGrid(BuildContext context, Map<String, ThemeSetting> settings, ThemeController tC, String lang) {
    final specs = kHubModuleSpecs;
    final order = hubOrderFromSettings(settings, specs.map((s) => s.id).toList());
    final hidden = hubHiddenFromSettings(settings);
    final visible = order.map((id) => specs.firstWhere((s) => s.id == id)).where((s) => !hidden.contains(s.id)).toList();

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: [
        for (int i = 0; i < visible.length; i++)
          _buildModuleButton(
            context,
            (i + 1).toString().padLeft(2, '0'),
            visible[i].label,
            visible[i].icon,
            settings,
            tC,
            lang,
            defaultColor: visible[i].defaultColor,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: visible[i].screenBuilder)),
          ),
      ],
    );
  }

  Widget _buildModuleButton(BuildContext context, String index, String label, IconData icon, Map<String, ThemeSetting> settings, ThemeController tC, String lang, {Color? defaultColor, VoidCallback? onTap}) {
    final aliases = label == 'WO.BLCKS'
        ? ["DASHBOARD_CARD_WO.BLKCS", "DASHBOARD_CARD_SESSION.BP"]
        : label == 'TMNLN'
            ? ["DASHBOARD_CARD_TIMELINE"]
            : label == 'DT.PRCSR'
                ? ["DASHBOARD_CARD_VSR.STATS"]
                : <String>[];
    final bgAliases = label == 'WO.BLCKS'
        ? ["DASHBOARD_CARD_WO.BLKCS_BG", "DASHBOARD_CARD_SESSION.BP_BG"]
        : label == 'TMNLN'
            ? ["DASHBOARD_CARD_TIMELINE_BG"]
            : label == 'DT.PRCSR'
                ? ["DASHBOARD_CARD_VSR.STATS_BG"]
                : <String>[];
    final color = tC.getColor(settings, "DASHBOARD_CARD_$label", defaultColor: defaultColor, aliases: aliases);
    final bgColor = tC.getColor(settings, "DASHBOARD_CARD_${label}_BG", defaultColor: (defaultColor ?? LabColors.surfaceContainerLow).withValues(alpha: 0.08), aliases: bgAliases);

    return Material(
      color: bgColor,
      child: InkWell(
        onTap: onTap ?? () {},
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: color, size: 26),
                    const SizedBox(height: 8),
                    Text(
                      tr(lang, label).toUpperCase(),
                      style: LabStyles.headline(context, color: Colors.white).copyWith(fontSize: 11, letterSpacing: 1),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                index,
                style: LabStyles.mono(context, 
                  fontSize: 28, 
                  fontWeight: FontWeight.bold, 
                  color: color.withValues(alpha: 0.8)
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNexusModule(BuildContext context, Map<String, ThemeSetting> settings, ThemeController tC, String lang) {
    final color = tC.getColor(settings, "DASHBOARD_CARD_NEXUS", defaultColor: LabColors.nexusPurple);
    final bgColor = tC.getColor(settings, "DASHBOARD_CARD_NEXUS_BG", defaultColor: color.withValues(alpha: 0.08));

    return Material(
      color: bgColor,
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const NexusScreen()));
        },
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Icon(Icons.hub, color: color, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(tr(lang, 'IMPORT & EXPORT DATA'), style: LabStyles.mono(context, fontSize: 8, color: color.withValues(alpha: 0.7))),
                    Text('07 NEXUS', style: LabStyles.headline(context, color: Colors.white).copyWith(fontSize: 16, letterSpacing: 2)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatasetModule(BuildContext context, Map<String, ThemeSetting> settings, ThemeController tC, String lang) {
    final color = tC.getColor(settings, "DASHBOARD_CARD_DATASET", defaultColor: LabColors.datasetGold);
    final bgColor = tC.getColor(settings, "DASHBOARD_CARD_DATASET_BG", defaultColor: color.withValues(alpha: 0.08));

    return Material(
      color: bgColor,
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const FullDatasetScreen()));
        },
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Icon(Icons.storage, color: color, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(tr(lang, 'RAW_DATA_VIEW_ONLY'), style: LabStyles.mono(context, fontSize: 8, color: color.withValues(alpha: 0.7))),
                    Text('08 DATASET', style: LabStyles.headline(context, color: Colors.white).copyWith(fontSize: 16, letterSpacing: 2)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeModule(BuildContext context, Map<String, ThemeSetting> settings, ThemeController tC, String lang) {
    final color = tC.getColor(settings, "DASHBOARD_CARD_THEME.MDFYR", defaultColor: LabColors.themeWhite);
    final bgColor = tC.getColor(settings, "DASHBOARD_CARD_THEME.MDFYR_BG", defaultColor: color.withValues(alpha: 0.08));

    return Material(
      color: bgColor,
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const ThemeModdingScreen()));
        },
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Icon(Icons.palette, color: color, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(tr(lang, 'VISUAL_INTERFACE_CUSTOMIZATION'), style: LabStyles.mono(context, fontSize: 8, color: color.withValues(alpha: 0.7))),
                    Text('09 ${tr(lang, 'THEME.MDFYR')}', style: LabStyles.headline(context, color: Colors.white).copyWith(fontSize: 16, letterSpacing: 2)),
                  ],
                ),
              ),
              Icon(Icons.settings, color: color.withValues(alpha: 0.5), size: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppConfigModule(BuildContext context, Map<String, ThemeSetting> settings, ThemeController tC, String lang) {
    final color = tC.getColor(settings, "DASHBOARD_CARD_APP.CONFIG", defaultColor: LabColors.onSurfaceVariant);
    final bgColor = tC.getColor(settings, "DASHBOARD_CARD_APP.CONFIG_BG", defaultColor: color.withValues(alpha: 0.08));

    return Material(
      color: bgColor,
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AppConfigScreen()));
        },
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Icon(Icons.tune, color: color, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(tr(lang, 'APP_WIDE_SETTINGS'), style: LabStyles.mono(context, fontSize: 8, color: color.withValues(alpha: 0.7))),
                    Text(tr(lang, 'APP.CONFIG'), style: LabStyles.headline(context, color: Colors.white).copyWith(fontSize: 16, letterSpacing: 2)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color.withValues(alpha: 0.5), size: 24),
            ],
          ),
        ),
      ),
    );
  }
}

