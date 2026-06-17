import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import '../providers/theme_provider.dart';
import 'styles.dart';
import 'lab_widgets.dart';
import 'workout_manager.dart';
import 'ledger_screen.dart';
import 'blueprint_manager.dart';
import 'anthropometric_data_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(themeSettingsProvider).value ?? <String, ThemeSetting>{};
    final themeController = ref.read(themeControllerProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 32),
          _buildStatsGrid(context, settings, themeController),
          const SizedBox(height: 32),
          _buildActionSection(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: LabColors.cyanBorder, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'THE_LABORATORY',
                  overflow: TextOverflow.ellipsis,
                  style: LabStyles.headline(context, color: LabColors.primaryFixed)
                      .copyWith(letterSpacing: -1, fontSize: 20),
                ),
                Text(
                  'CENTRAL_PROCESSING_UNIT',
                  style: LabStyles.mono(context, color: Colors.grey[700]!, fontSize: 8),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'SYSTEM_STATUS',
                style: LabStyles.mono(context, color: Colors.grey[500]!, fontSize: 8),
              ),
              Text(
                'OPERATIONAL',
                style: LabStyles.mono(context, color: LabColors.tertiary, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, Map<String, ThemeSetting> settings, ThemeController controller) {
    return GridView.count(
      crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        _buildModuleCard(
          context,
          'CRRNT.WO',
          Icons.fitness_center,
          controller.getColor(settings, "DASHBOARD_CARD_CRRNT.WO", defaultColor: LabColors.primary),
          settings,
          controller,
          () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => WorkoutManagerScreen()));
          },
        ),
        _buildModuleCard(
          context,
          'KNS.INVTRY',
          Icons.inventory_2,
          controller.getColor(settings, "DASHBOARD_CARD_KNS.INVTRY", defaultColor: LabColors.primary),
          settings,
          controller,
          () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const LedgerScreen()));
          },
        ),
        _buildModuleCard(
          context,
          'WO.BLCKS',
           Icons.view_module_rounded,
           controller.getColor(settings, "DASHBOARD_CARD_WO.BLKCS", defaultColor: LabColors.blueprintBlue, aliases: ["DASHBOARD_CARD_SESSION.BP"]),
          settings,
          controller,
          () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const BlueprintManagerScreen()));
          },
        ),
        _buildModuleCard(
          context,
          'VSR.STATS',
          Icons.analytics,
          controller.getColor(settings, "DASHBOARD_CARD_VSR.STATS", defaultColor: Colors.grey[800]!),
          settings,
          controller,
          () {},
        ),
        _buildModuleCard(
          context,
          'ANTRPMT.DT',
          Icons.straighten,
          controller.getColor(settings, "DASHBOARD_CARD_ANTRPMT.DT", defaultColor: LabColors.accent),
          settings,
          controller,
          () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const AnthropometricDataScreen()));
          },
        ),
        _buildModuleCard(
          context,
          'SYS.LOGS',
          Icons.terminal,
          controller.getColor(settings, "DASHBOARD_CARD_SYS.LOGS", defaultColor: Colors.grey[800]!),
          settings,
          controller,
          () {},
        ),
      ],
    );
  }

  Widget _buildModuleCard(BuildContext context, String label, IconData icon, Color color, Map<String, ThemeSetting> settings, ThemeController controller, VoidCallback onTap) {
    final bgAliases = label == 'WO.BLCKS' ? ["DASHBOARD_CARD_WO.BLKCS_BG", "DASHBOARD_CARD_SESSION.BP_BG"] : <String>[];
    final bgColor = controller.getColor(settings, "DASHBOARD_CARD_${label}_BG", defaultColor: LabColors.surfaceContainerLow, aliases: bgAliases);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: color.withValues(alpha: 0.1),
        highlightColor: color.withValues(alpha: 0.05),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, size: 18, color: color),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: LabStyles.mono(context, color: color, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Container(height: 2, width: 20, color: color.withValues(alpha: 0.5)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 4, height: 24, color: LabColors.primary),
            const SizedBox(width: 8),
            Text(
              'QUICK_ACCESS_PROTOCOLS',
              style: LabStyles.headline(context, color: LabColors.onSurface)
                  .copyWith(fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 16),
        LabButton(
          label: 'INITIALIZE_ACTIVE_SESSION',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => WorkoutManagerScreen()),
            );
          },
          color: LabColors.primary,
        ),
      ],
    );
  }
}
