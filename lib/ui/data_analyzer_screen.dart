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

/// Segmented ANALYZER/VIEWER toggle shared by [DataAnalyzerScreen] (DATA.NLZR)
/// and [PerformanceDashboard] (DATA.VWR) so both read as one module (DT.PRCSR)
/// instead of two unrelated screens. Uses pushReplacement so switching swaps
/// the view instead of piling up the back stack - same pattern as
/// TimelineViewSwitcher in timeline_screen.dart.
class DataProcessorViewSwitcher extends StatelessWidget {
  final bool isViewerActive;
  final VoidCallback onSwitch;

  const DataProcessorViewSwitcher({super.key, required this.isViewerActive, required this.onSwitch});

  @override
  Widget build(BuildContext context) {
    Widget segment(String label, bool active) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? LabColors.primary.withValues(alpha: 0.12) : Colors.transparent,
        ),
        child: Text(
          label,
          style: LabStyles.mono(
            context,
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: active ? LabColors.primary : Colors.grey[600],
          ),
        ),
      );
    }

    return Container(
      decoration: LabStyles.hairlineBorder(color: LabColors.cyanBorder.withValues(alpha: 0.4)),
      child: InkWell(
        onTap: onSwitch,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            segment('NLZR', !isViewerActive),
            segment('VWR', isViewerActive),
          ],
        ),
      ),
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Align(
              alignment: Alignment.centerRight,
              child: DataProcessorViewSwitcher(
                isViewerActive: false,
                onSwitch: () {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const PerformanceDashboard()));
                },
              ),
            ),
          ),
          Expanded(child: _LrAlertSection()),
        ],
      ),
      bottomNavigationBar: const LabFooter(),
    );
  }
}

class _LrAlertSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider).value ?? 'en';
    final overview = ref.watch(lrAsymmetryOverviewProvider);
    final threshold = ref.watch(lrAlertThresholdProvider).value ?? 10.0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('L/R ASYMMETRY', style: LabStyles.mono(context, fontWeight: FontWeight.bold, color: LabColors.primary)),
        const SizedBox(height: 4),
        Text(
          '${tr(lang, "THRESHOLD")}: ${threshold.toStringAsFixed(0)}% · ${_lrWindowLabel(lang)}',
          style: LabStyles.mono(context, fontSize: 9, color: Colors.grey),
        ),
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

  String _lrWindowLabel(String lang) => '14D';
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
