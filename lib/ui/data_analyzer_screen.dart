import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/charts_provider.dart';
import '../providers/theme_provider.dart';
import '../database/database.dart';
import '../logic/lr_asymmetry.dart';
import 'styles.dart';
import 'lab_widgets.dart';
import 'main_scaffold.dart';
import 'charts/chart_widgets.dart';
import 'charts/performance_dashboard.dart';
import '../localization/strings.dart';

/// Small floating chooser shared by [DataAnalyzerScreen] (DATA.NLZR) and
/// [PerformanceDashboard] (DATA.VWR) so both read as one module (DT.PRCSR)
/// instead of two unrelated screens, without eating a full header row like
/// the first version of this switcher did. Tap opens a 2-item picker; the
/// active view is checked. Uses pushReplacement so switching swaps the view
/// instead of piling up the back stack - same idea as TimelineViewSwitcher
/// in timeline_screen.dart, just as a FAB instead of an inline segmented bar.
class DataProcessorSwitcherFab extends StatelessWidget {
  final bool isViewerActive;

  const DataProcessorSwitcherFab({super.key, required this.isViewerActive});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'dt_prcsr_switcher',
      backgroundColor: LabColors.surfaceContainerHigh,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: LabColors.cyanBorder.withValues(alpha: 0.5), width: 0.5),
      ),
      onPressed: () => _showChooser(context),
      child: const Icon(Icons.swap_horiz, color: LabColors.primary),
    );
  }

  void _showChooser(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: LabColors.background,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _option(context, c, icon: Icons.query_stats, label: 'DATA.NLZR', active: !isViewerActive, onTap: () {
              if (isViewerActive) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DataAnalyzerScreen()));
              }
            }),
            _option(context, c, icon: Icons.analytics, label: 'DATA.VWR', active: isViewerActive, onTap: () {
              if (!isViewerActive) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PerformanceDashboard()));
              }
            }),
          ],
        ),
      ),
    );
  }

  Widget _option(BuildContext context, BuildContext sheetContext,
      {required IconData icon, required String label, required bool active, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: active ? LabColors.primary : Colors.grey),
      title: Text(label, style: LabStyles.mono(context, fontWeight: FontWeight.bold, color: active ? LabColors.primary : Colors.white)),
      trailing: active ? const Icon(Icons.check, color: LabColors.primary, size: 16) : null,
      onTap: () {
        Navigator.pop(sheetContext);
        onTap();
      },
    );
  }
}

/// DATA.NLZR - analytical module of DT.PRCSR. Currently just LR.ALERT
/// (left/right strength asymmetry); more analyses land here over time
/// without needing a new hub card each time.
class DataAnalyzerScreen extends ConsumerWidget {
  const DataAnalyzerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider).value ?? 'en';

    return MainScaffold(
      title: tr(lang, 'DATA.NLZR'),
      screenKey: 'DATA_NLZR',
      body: const _LrAlertSection(),
      floatingActionButton: const DataProcessorSwitcherFab(isViewerActive: false),
      bottomNavigationBar: const LabFooter(),
    );
  }
}

class _LrAlertSection extends ConsumerStatefulWidget {
  const _LrAlertSection();

  @override
  ConsumerState<_LrAlertSection> createState() => _LrAlertSectionState();
}

class _LrAlertSectionState extends ConsumerState<_LrAlertSection> {
  // Default ALL history, all unilateral KNS - matches the plan's window
  // default (10%) but the user asked for a full-history default instead of
  // a fixed 14-day one, with a quick filter to narrow it if wanted.
  DateTimeRange? _timeRange;
  double? _customThreshold;

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider).value ?? 'en';
    final overview = ref.watch(lrAsymmetryOverviewProvider(_timeRange));
    final configuredThreshold = ref.watch(lrAlertThresholdProvider).value ?? 10.0;
    final threshold = _customThreshold ?? configuredThreshold;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        Text('L/R ASYMMETRY', style: LabStyles.mono(context, fontWeight: FontWeight.bold, color: LabColors.primary)),
        const SizedBox(height: 8),
        TechnicalQuickTimeFilter(
          currentRange: _timeRange,
          onRangeSelected: (range) => setState(() => _timeRange = range),
          activeColor: LabColors.visualsNeon,
        ),
        const SizedBox(height: 12),
        _buildThresholdFilter(context, lang, threshold),
        const SizedBox(height: 12),
        overview.when(
          data: (rows) {
            if (rows.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Text(tr(lang, 'NO_DATA_FOR_THIS_PERIOD'), style: LabStyles.mono(context, color: Colors.grey)),
                ),
              );
            }
            return Column(
              children: rows.map((r) => _AsymmetryRow(exercise: r.$1, result: r.$2, threshold: threshold)).toList(),
            );
          },
          loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: LabColors.primary))),
          error: (e, s) => Text("ERR: $e", style: LabStyles.mono(context)),
        ),
      ],
    );
  }

  Widget _buildThresholdFilter(BuildContext context, String lang, double threshold) {
    return Row(
      children: [
        Text('${tr(lang, "THRESHOLD")}:', style: LabStyles.mono(context, fontSize: 9, color: Colors.grey)),
        const SizedBox(width: 8),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: LabColors.visualsNeon,
              inactiveTrackColor: LabColors.surfaceBright,
              thumbColor: LabColors.visualsNeon,
              overlayColor: LabColors.visualsNeon.withValues(alpha: 0.2),
              trackHeight: 2,
            ),
            child: Slider(
              value: threshold.clamp(0, 100),
              min: 0,
              max: 100,
              divisions: 100,
              onChanged: (v) => setState(() => _customThreshold = v),
            ),
          ),
        ),
        SizedBox(
          width: 40,
          child: Text('${threshold.toStringAsFixed(0)}%',
              textAlign: TextAlign.right, style: LabStyles.mono(context, fontSize: 10, fontWeight: FontWeight.bold, color: LabColors.visualsNeon)),
        ),
        if (_customThreshold != null)
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.close, color: Colors.grey, size: 14),
            tooltip: 'RESET',
            onPressed: () => setState(() => _customThreshold = null),
          ),
      ],
    );
  }
}

class _AsymmetryRow extends ConsumerWidget {
  final BaseExercise exercise;
  final LrAsymmetryResult result;
  final double threshold;

  const _AsymmetryRow({required this.exercise, required this.result, required this.threshold});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAlert = result.asymmetryPct > threshold;
    const alertColor = Colors.orangeAccent;

    return InkWell(
      onTap: () => _showDetail(context, ref),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: LabStyles.hairlineBorder(
          color: isAlert ? alertColor.withValues(alpha: 0.6) : LabColors.primary.withValues(alpha: 0.2),
        ),
        child: Row(
          children: [
            if (isAlert) ...[
              const Icon(Icons.warning_amber, size: 16, color: alertColor),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(exercise.fullName.toUpperCase(), style: LabStyles.mono(context, fontWeight: FontWeight.bold, fontSize: 11)),
                  const SizedBox(height: 2),
                  Text(
                    'WEAK: ${result.weakSide}',
                    style: LabStyles.mono(context, fontSize: 8, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Text(
              '${result.asymmetryPct.toStringAsFixed(1)}%',
              style: LabStyles.mono(context, fontWeight: FontWeight.bold, fontSize: 14, color: isAlert ? alertColor : LabColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: LabColors.background,
      builder: (c) => _AsymmetryDetailSheet(exercise: exercise, result: result),
    );
  }
}

class _AsymmetryDetailSheet extends ConsumerWidget {
  final BaseExercise exercise;
  final LrAsymmetryResult result;

  const _AsymmetryDetailSheet({required this.exercise, required this.result});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(themeSettingsProvider).value ?? {};
    final tC = ref.read(themeControllerProvider);
    final rightColor = tC.getColor(settings, "UI_UNILATERAL_RIGHT", nameSeed: "RIGHT");
    final leftColor = tC.getColor(settings, "UI_UNILATERAL_LEFT", nameSeed: "LEFT");
    final series = ref.watch(lrAsymmetryTimeSeriesProvider((exercise.id, null)));

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 16, left: 16, right: 16),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(exercise.fullName.toUpperCase(), style: LabStyles.mono(context, fontWeight: FontWeight.bold, fontSize: 13, color: LabColors.primary)),
            const SizedBox(height: 4),
            Row(
              children: [
                _legendDot(context, rightColor, 'R: ${result.avgRightEorm.toStringAsFixed(1)}KG'),
                const SizedBox(width: 16),
                _legendDot(context, leftColor, 'L: ${result.avgLeftEorm.toStringAsFixed(1)}KG'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 260,
              child: series.when(
                data: (data) => LrAsymmetryChart(data: data, rightColor: rightColor, leftColor: leftColor),
                loading: () => const Center(child: CircularProgressIndicator(color: LabColors.primary)),
                error: (e, s) => Text("ERR: $e", style: LabStyles.mono(context)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(BuildContext context, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, color: color),
        const SizedBox(width: 6),
        Text(label, style: LabStyles.mono(context, fontSize: 10, color: color)),
      ],
    );
  }
}
