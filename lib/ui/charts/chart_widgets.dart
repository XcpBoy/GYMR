import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../logic/chart_models.dart';
import '../styles.dart';
import '../../localization/strings.dart';

class LabChartContainer extends StatelessWidget {
  final String title;
  final String? subTitle;
  final Widget child;
  final double height;

  const LabChartContainer({
    super.key,
    required this.title,
    this.subTitle,
    required this.child,
    this.height = 300,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: LabStyles.hairlineBorder(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: LabColors.cyanBorder, width: 0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title.toUpperCase(), style: LabStyles.mono(context, fontWeight: FontWeight.bold, color: LabColors.primary)),
                if (subTitle != null)
                  Text(subTitle!.toUpperCase(), style: LabStyles.mono(context, fontSize: 10, color: LabColors.primary.withValues(alpha: 0.5))),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class SessionLineChart extends StatelessWidget {
  final List<SessionMetric> data;
  final Color color;
  final List<Color>? gradientColors;
  final double Function(SessionMetric) valueMapper;
  final String yAxisLabel;
  final bool showTrendLine;

  const SessionLineChart({
    super.key,
    required this.data,
    required this.color,
    this.gradientColors,
    required this.valueMapper,
    required this.yAxisLabel,
    this.showTrendLine = false,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return _buildEmpty(context);

    final spots = data.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), valueMapper(e.value));
    }).toList();

    List<LineChartBarData> lineBars = [
      LineChartBarData(
        spots: spots,
        isCurved: false,
        color: gradientColors != null ? null : color,
        gradient: gradientColors != null ? LinearGradient(colors: gradientColors!) : null,
        barWidth: 2,
        dotData: const FlDotData(show: true),
        belowBarData: BarAreaData(
          show: true, 
          gradient: gradientColors != null 
            ? LinearGradient(colors: gradientColors!.map((c) => c.withValues(alpha: 0.1)).toList()) 
            : LinearGradient(colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.0)])
        ),
      ),
    ];

    if (showTrendLine && spots.length > 1) {
      final trendSpots = _calculateTrendLine(spots);
      lineBars.add(
        LineChartBarData(
          spots: trendSpots,
          isCurved: false,
          color: Colors.white.withValues(alpha: 0.3),
          barWidth: 1,
          dotData: const FlDotData(show: false),
          dashArray: [5, 5],
        ),
      );
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (value) => const FlLine(color: LabColors.surfaceBright, strokeWidth: 0.5),
          getDrawingVerticalLine: (value) => const FlLine(color: LabColors.surfaceBright, strokeWidth: 0.5),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: data.length > 10 ? (data.length / 5).toDouble() : 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= data.length) return const SizedBox();
                // For long ranges, only show labels at intervals to avoid overlap
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    DateFormat('dd/MM').format(data[index].date),
                    style: LabStyles.mono(context, fontSize: 8, color: LabColors.onSurfaceVariant),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: LabStyles.mono(context, fontSize: 8, color: LabColors.onSurfaceVariant),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: true, border: Border.all(color: LabColors.cyanBorder, width: 0.5)),
        lineBarsData: lineBars,
      ),
    );
  }

  List<FlSpot> _calculateTrendLine(List<FlSpot> spots) {
    int n = spots.length;
    double sumX = 0, sumY = 0, sumXY = 0, sumXX = 0;
    for (var spot in spots) {
      sumX += spot.x;
      sumY += spot.y;
      sumXY += spot.x * spot.y;
      sumXX += spot.x * spot.x;
    }
    double slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX);
    double intercept = (sumY - slope * sumX) / n;
    
    return [
      FlSpot(spots.first.x, slope * spots.first.x + intercept),
      FlSpot(spots.last.x, slope * spots.last.x + intercept),
    ];
  }

  Widget _buildEmpty(BuildContext context) => Center(child: Text("NO_DATA", style: LabStyles.mono(context)));
}

class MuscleDonutChart extends ConsumerWidget {
  final List<MuscleMetric> data;

  const MuscleDonutChart({super.key, required this.data});

  static const List<Color> techPalette = [
    LabColors.primary,
    LabColors.accent,
    LabColors.tertiary,
    Colors.redAccent,
    Colors.purpleAccent,
    Colors.orangeAccent,
    Colors.blueAccent,
    Colors.greenAccent,
    Colors.pinkAccent,
    Colors.tealAccent,
  ];

  static Color getColor(int index) => techPalette[index % techPalette.length];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider).value ?? 'en';
    if (data.isEmpty) return Center(child: Text("NO_DATA", style: LabStyles.mono(context)));

    final total = data.fold<double>(0, (sum, item) => sum + item.value);

    // Group items with <=2% into OTHER
    final threshold = total * 0.02;
    List<MuscleMetric> mainSlices = [];
    double otherValue = 0;
    for (final item in data) {
      if (item.value <= threshold) {
        otherValue += item.value;
      } else {
        mainSlices.add(item);
      }
    }
    if (otherValue > 0) {
      mainSlices.add(MuscleMetric(muscle: tr(lang, 'OTHER'), value: otherValue, color: Colors.white24));
    }

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: mainSlices.asMap().entries.map((e) {
          final metricColor = e.value.color ?? getColor(e.key);
          return PieChartSectionData(
            color: metricColor,
            value: e.value.value,
            title: '${(e.value.value / total * 100).toStringAsFixed(0)}%',
            radius: 50,
            titlePositionPercentageOffset: 1.4,
            titleStyle: LabStyles.mono(context, fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
          );
        }).toList(),
      ),
    );
  }
}

class TechnicalBarChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final Color color;

  const TechnicalBarChart({
    super.key,
    required this.values,
    required this.labels,
    this.color = LabColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return Center(child: Text("NO_DATA", style: LabStyles.mono(context)));

    return BarChart(
      BarChartData(
        barGroups: values.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value,
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.3)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                width: 12,
                borderRadius: BorderRadius.zero,
              ),
            ],          );
        }).toList(),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 120, // Increased to allow "stretching" vertically
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= labels.length) return const SizedBox();
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 0,
                  child: SizedBox(
                    width: 12, // Strict horizontal constraint to prevent overlap
                    child: RotatedBox(
                      quarterTurns: 1, 
                      child: Text(
                        labels[index].toUpperCase(),
                        style: LabStyles.mono(context, fontSize: 8),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: LabStyles.mono(context, fontSize: 8)),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}

/// Grouped R/L EORM bars per day, for LR.ALERT (DATA.NLZR) exercise detail.
class LrAsymmetryChart extends StatelessWidget {
  final List<({DateTime date, double rightEorm, double leftEorm})> data;
  final Color rightColor;
  final Color leftColor;

  const LrAsymmetryChart({
    super.key,
    required this.data,
    required this.rightColor,
    required this.leftColor,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return Center(child: Text("NO_DATA", style: LabStyles.mono(context)));

    return BarChart(
      BarChartData(
        barGroups: data.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barsSpace: 4,
            barRods: [
              BarChartRodData(toY: e.value.rightEorm, color: rightColor, width: 6, borderRadius: BorderRadius.zero),
              BarChartRodData(toY: e.value.leftEorm, color: leftColor, width: 6, borderRadius: BorderRadius.zero),
            ],
          );
        }).toList(),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= data.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    DateFormat('dd/MM').format(data[index].date),
                    style: LabStyles.mono(context, fontSize: 8, color: LabColors.onSurfaceVariant),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (value, meta) =>
                  Text(value.toInt().toString(), style: LabStyles.mono(context, fontSize: 8, color: LabColors.onSurfaceVariant)),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => const FlLine(color: LabColors.surfaceBright, strokeWidth: 0.5),
        ),
        borderData: FlBorderData(show: true, border: Border.all(color: LabColors.cyanBorder, width: 0.5)),
      ),
    );
  }
}

