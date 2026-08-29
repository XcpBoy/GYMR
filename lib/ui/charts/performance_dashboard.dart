import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' as drift;
import '../../providers/charts_provider.dart';
import '../../providers/database_provider.dart';
import '../../providers/theme_provider.dart';
import '../../database/database.dart';
import '../../logic/chart_models.dart';
import '../../logic/kns_search.dart';
import '../styles.dart';
import 'chart_widgets.dart';
import '../lab_widgets.dart';
import '../data_analyzer_screen.dart';

class PerformanceDashboard extends ConsumerStatefulWidget {
  final ChartTab? initialTab;
  final int? initialExerciseId;
  const PerformanceDashboard({super.key, this.initialTab, this.initialExerciseId});

  @override
  ConsumerState<PerformanceDashboard> createState() => _PerformanceDashboardState();
}

enum ChartTab { session, muscle, movement, oneRm, failure, somatic }

class _PerformanceDashboardState extends ConsumerState<PerformanceDashboard> {
  late ChartTab _selectedTab;
  MuscleMetricType _selectedMuscleMetric = MuscleMetricType.sets;
  MuscleMetricType _selectedExerciseMetric = MuscleMetricType.sets;
  
  // Filters
  DateTimeRange? _globalTimeRange;
  int? _oneRmExId;
  int? _failureExId;

  // Somatic specific
  DateTime? _selectedReportDate;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab ?? ChartTab.session;
    if (widget.initialExerciseId != null) {
      _oneRmExId = widget.initialExerciseId;
      _failureExId = widget.initialExerciseId;
    }
    // Performance optimization: Default to last 30 days
    _globalTimeRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 30)),
      end: DateTime.now().add(const Duration(days: 1)),
    );
  }

  String _getUnitLabel(MuscleMetricType type) {
    switch (type) {
      case MuscleMetricType.tonnage: return "KG";
      case MuscleMetricType.sets: return "SETS";
      case MuscleMetricType.reps: return "REPS";
      case MuscleMetricType.workouts: return "WOs";
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionData = ref.watch(sessionsMetricsProvider(_globalTimeRange));
    final muscleData = ref.watch(muscleMetricsProvider((_selectedMuscleMetric, _globalTimeRange)));
    final movementData = ref.watch(exerciseMetricsProvider((_selectedExerciseMetric, _globalTimeRange)));
    final phaseData = ref.watch(phaseFailureProvider((_failureExId, _globalTimeRange)));
    final discomfortData = ref.watch(discomfortMetricsProvider(_globalTimeRange));
    final exercises = ref.watch(allExercisesProvider);
    final discomfortDetails = ref.watch(discomfortDetailsProvider(_selectedReportDate));

    return Scaffold(
      backgroundColor: LabColors.background,
      appBar: AppBar(
        backgroundColor: LabColors.background,
        title: Text("GRFCL.NLYZR", style: LabStyles.mono(context, fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: LabColors.primary),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _buildTabSelector(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildGlobalTimeFilter(),
            TechnicalQuickTimeFilter(
              currentRange: _globalTimeRange,
              onRangeSelected: (range) => setState(() => _globalTimeRange = range),
              activeColor: LabColors.visualsNeon,
            ),
            const SizedBox(height: 16),
            _buildActiveChart(
              sessionData: sessionData,
              muscleData: muscleData,
              movementData: movementData,
              phaseData: phaseData,
              discomfortData: discomfortData,
              exercises: exercises,
              discomfortDetails: discomfortDetails,
            ),
            const SizedBox(height: 100), // Space for footer
          ],
        ),
      ),
      floatingActionButton: const DataProcessorSwitcherFab(isViewerActive: true),
      bottomNavigationBar: const LabFooter(),
    );
  }

  Widget _buildGlobalTimeFilter() {
    return InkWell(
      onTap: () async {
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 1)),
          initialDateRange: _globalTimeRange,
          builder: (context, child) => Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(primary: LabColors.primary, onPrimary: Colors.black, surface: LabColors.background),
            ),
            child: child!,
          ),
        );
        if (picked != null) setState(() => _globalTimeRange = picked);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: LabStyles.hairlineBorder(context, color: LabColors.primary),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today, color: LabColors.primary, size: 14),
                const SizedBox(width: 12),
                Text(_globalTimeRange == null ? "GLOBAL_TIME_RANGE: ALL_TIME" : "RANGE: ${DateFormat('dd/MM/yy').format(_globalTimeRange!.start)} - ${DateFormat('dd/MM/yy').format(_globalTimeRange!.end)}", 
                  style: LabStyles.mono(context, fontSize: 10, color: LabColors.primary)),
              ],
            ),
            if (_globalTimeRange != null)
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close, color: Colors.redAccent, size: 14),
                onPressed: () => setState(() => _globalTimeRange = null),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: LabColors.cyanBorder, width: 0.5)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: ChartTab.values.map((tab) {
          final isSelected = _selectedTab == tab;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => setState(() => _selectedTab = tab),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? LabColors.primary : Colors.transparent,
                  border: Border.all(color: LabColors.primary, width: 0.5),
                ),
                child: Text(
                  tab.name.toUpperCase(),
                  style: LabStyles.mono(context, 
                    fontSize: 10, 
                    color: isSelected ? LabColors.background : LabColors.primary,
                    fontWeight: FontWeight.bold
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActiveChart({
    required AsyncValue<List<SessionMetric>> sessionData,
    required AsyncValue<List<MuscleMetric>> muscleData,
    required AsyncValue<List<MuscleMetric>> movementData,
    required AsyncValue<List<PhaseMetric>> phaseData,
    required AsyncValue<List<DiscomfortMetric>> discomfortData,
    required AsyncValue<List<BaseExercise>> exercises,
    required AsyncValue<List<drift.QueryRow>> discomfortDetails,
  }) {
    final settings = ref.watch(themeSettingsProvider).value ?? {};
    final controller = ref.read(themeControllerProvider);

    switch (_selectedTab) {
      case ChartTab.session:
        return sessionData.when(
          data: (data) => Column(
            children: [
              LabChartContainer(
                title: "01.VOL_TONNAGE",
                child: SessionLineChart(data: data, color: LabColors.primary, valueMapper: (m) => m.volume, yAxisLabel: "KG"),
              ),
              LabChartContainer(
                title: "02.NUMBER_OF_SETS",
                child: SessionLineChart(data: data, color: LabColors.accent, valueMapper: (m) => m.sets.toDouble(), yAxisLabel: "SETS"),
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Text("ERR: $e"),
        );

      case ChartTab.muscle:
        return Column(
          children: [
            _buildMetricSelector(_selectedMuscleMetric, (val) => setState(() => _selectedMuscleMetric = val)),
            const SizedBox(height: 12),
            muscleData.when(
              data: (data) {
                final coloredData = data.map((m) => MuscleMetric(
                  muscle: m.muscle,
                  value: m.value,
                  color: controller.getColor(settings, "muscle_${m.muscle}", nameSeed: m.muscle),
                )).toList();
                return Column(
                  children: [
                    LabChartContainer(
                      title: "03.MUSCLE_PROPORTION",
                      subTitle: _selectedMuscleMetric.name,
                      child: MuscleDonutChart(data: coloredData),
                    ),
                    const SizedBox(height: 16),
                    _buildLegend(coloredData, _selectedMuscleMetric),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => const Text("ERR"),
            ),
          ],
        );

      case ChartTab.movement:
        return Column(
          children: [
            _buildMetricSelector(_selectedExerciseMetric, (val) => setState(() => _selectedExerciseMetric = val)),
            const SizedBox(height: 12),
            movementData.when(
              data: (data) {
                final coloredData = data.map((m) => MuscleMetric(
                  muscle: m.muscle,
                  value: m.value,
                  color: controller.getColor(settings, "movement_${m.muscle}", nameSeed: m.muscle),
                )).toList();
                return Column(
                  children: [
                    LabChartContainer(
                      title: "04.MOVEMENT_PROPORTION",
                      subTitle: _selectedExerciseMetric.name,
                      child: MuscleDonutChart(data: coloredData),
                    ),
                    const SizedBox(height: 16),
                    _buildLegend(coloredData, _selectedExerciseMetric),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => const Text("ERR"),
            ),
          ],
        );

      case ChartTab.oneRm:
        return Column(
          children: [
            _buildSearchableSelector(exercises, _oneRmExId, (val) => setState(() => _oneRmExId = val)),
            const SizedBox(height: 16),
            LabChartContainer(
              title: "05.1RM_ESTIMATION",
              child: _oneRmExId == null 
                ? Center(child: Text("SELECT_EXERCISE", style: LabStyles.mono(context)))
                : ref.watch(oneRmProgressionProvider((_oneRmExId!, _globalTimeRange))).when(
                    data: (data) => SessionLineChart(
                      data: data.map((e) => SessionMetric(date: e.date, volume: e.oneRm, sets: 0, reps: 0)).toList(),
                      color: Colors.amber,
                      gradientColors: const [Colors.amber, Colors.redAccent],
                      valueMapper: (m) => m.volume,
                      yAxisLabel: "KG",
                      showTrendLine: true,
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, s) => const Text("ERR"),
                  ),
            ),
          ],
        );

      case ChartTab.failure:
        return Column(
          children: [
            _buildSearchableSelector(exercises, _failureExId, (val) => setState(() => _failureExId = val), allowAll: false),
            const SizedBox(height: 16),
            if (_failureExId == null)
              Center(child: Padding(padding: const EdgeInsets.all(32), child: Text("SELECT_EXERCISE_TO_VIEW_FAILURE_PHASES", style: LabStyles.mono(context, color: Colors.grey, fontSize: 10))))
            else
              phaseData.when(
                data: (data) {
                  final cleanedData = data.asMap().entries.map((entry) {
                    final e = entry.value;
                    String name = e.phaseName ?? "PHASE ${e.phase}";
                    
                    // Aggressive cleaning: remove JSON symbols and index numbers
                    name = name.replaceAll(RegExp(r'[{}""\[\]:]'), ' ').trim();
                    name = name.replaceFirst(RegExp(r'^\d+\s*'), '').trim();
                    
                    return MuscleMetric(
                      muscle: name.toUpperCase(), 
                      value: e.count.toDouble(),
                      color: MuscleDonutChart.getColor(entry.key),
                    );
                  }).toList();

                  if (cleanedData.isEmpty) {
                    return Center(child: Padding(padding: const EdgeInsets.all(32), child: Text("NO_FAILURE_DATA", style: LabStyles.mono(context, color: Colors.grey))));
                  }

                  return Column(
                    children: [
                      LabChartContainer(
                        title: "07.FAILURE_PHASE",
                        child: MuscleDonutChart(data: cleanedData),
                      ),
                      const SizedBox(height: 16),
                      _buildLegend(cleanedData, null, customUnit: "TIMES"),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Text("ERR: $e"),
              ),
          ],
        );

      case ChartTab.somatic:
        return Column(
          children: [
            const SizedBox(height: 16),
            discomfortData.when(
              data: (data) => LabChartContainer(
                title: "08.SOMATIC_REPORTS",
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: data.length > 5 ? data.length * 60.0 : MediaQuery.of(context).size.width - 64,
                    child: TechnicalBarChart(
                      values: data.map((e) => e.count.toDouble()).toList(),
                      labels: data.map((e) => e.tag).toList(),
                      color: Colors.redAccent,
                    ),
                  ),
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => const Text("ERR"),
            ),
            const SizedBox(height: 16),
            _buildDailyReportReview(discomfortDetails),
          ],
        );
    }
  }

  Widget _buildSearchableSelector(AsyncValue<List<BaseExercise>> exercises, int? currentId, Function(int?) onChanged, {bool allowAll = false}) {
    return exercises.when(
      data: (list) {
        final current = currentId == null ? (allowAll ? "ALL_MOVEMENTS" : "SELECT_EXERCISE") : list.firstWhere((e) => e.id == currentId).fullName;
        return InkWell(
          onTap: () => _showExerciseSearch(context, list, onChanged, allowAll),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(border: Border.all(color: LabColors.primary.withValues(alpha: 0.3), width: 0.5)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(current, style: LabStyles.mono(context, fontSize: 10, color: currentId == null ? Colors.grey : Colors.white))),
                const Icon(Icons.search, color: LabColors.primary, size: 16),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox(),
      error: (e, s) => const SizedBox(),
    );
  }

  void _showExerciseSearch(BuildContext context, List<BaseExercise> list, Function(int?) onSelect, bool allowAll) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: LabColors.background,
      builder: (context) {
        return _ExerciseSearchModal(list: list, onSelect: onSelect, allowAll: allowAll);
      }
    );
  }

  Widget _buildDailyReportReview(AsyncValue<List<drift.QueryRow>> details) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedReportDate ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
              builder: (context, child) => Theme(
                data: ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(primary: LabColors.accent, onPrimary: Colors.black, surface: LabColors.background),
                ),
                child: child!,
              ),
            );
            if (picked != null) setState(() => _selectedReportDate = picked);
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: LabStyles.hairlineBorder(context, color: LabColors.accent),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_selectedReportDate == null ? "REVIEW_DAILY_REPORTS" : "REPORTS_FOR: ${DateFormat('dd/MM/yyyy').format(_selectedReportDate!)}", 
                  style: LabStyles.mono(context, fontSize: 10, color: LabColors.accent)),
                const Icon(Icons.history_edu, color: LabColors.accent, size: 16),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_selectedReportDate != null)
          details.when(
            data: (rows) {
              if (rows.isEmpty) return Center(child: Padding(padding: const EdgeInsets.all(16), child: Text("NO_REPORTS_FOUND", style: LabStyles.mono(context, color: Colors.grey, fontSize: 10))));
              return Column(
                children: rows.map((row) {
                  final description = row.data['description'] as String? ?? '';
                  final exerciseName = row.data['exercise_name'] as String? ?? '';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: LabColors.surfaceContainerLow,
                      border: Border(left: BorderSide(color: Colors.redAccent, width: 2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(exerciseName.toUpperCase(), style: LabStyles.mono(context, fontSize: 10, fontWeight: FontWeight.bold, color: LabColors.primary)),
                        const SizedBox(height: 4),
                        Text(description, style: LabStyles.mono(context, fontSize: 11)),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Text("ERR: $e"),
          ),
      ],
    );
  }

  Widget _buildMetricSelector(MuscleMetricType current, Function(MuscleMetricType) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: MuscleMetricType.values.map((type) {
        final isSelected = current == type;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: InkWell(
            onTap: () => onChanged(type),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? LabColors.primary : Colors.transparent,
                border: Border.all(color: LabColors.primary, width: 0.5),
              ),
              child: Text(type.name.toUpperCase(), style: LabStyles.mono(context, fontSize: 8, color: isSelected ? LabColors.background : LabColors.primary)),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLegend(List<MuscleMetric> data, MuscleMetricType? type, {String? customUnit}) {
    return Column(
      children: data.asMap().entries.map((e) {
        final color = e.value.color;
        return Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: LabColors.surfaceContainerLow,
            border: Border(left: BorderSide(color: color, width: 3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(e.value.muscle.toUpperCase(), style: LabStyles.mono(context, fontWeight: FontWeight.bold, fontSize: 10))),
              Text("${e.value.value.toStringAsFixed(0)} ${customUnit ?? _getUnitLabel(type!)}", style: LabStyles.mono(context, color: color, fontSize: 10)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ExerciseSearchModal extends StatefulWidget {
  final List<BaseExercise> list;
  final Function(int?) onSelect;
  final bool allowAll;

  const _ExerciseSearchModal({required this.list, required this.onSelect, required this.allowAll});

  @override
  State<_ExerciseSearchModal> createState() => _ExerciseSearchModalState();
}

class _ExerciseSearchModalState extends State<_ExerciseSearchModal> {
  final TextEditingController _controller = TextEditingController();
  late List<BaseExercise> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = widget.list;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: LabTextField(
              controller: _controller, 
              label: "FILTER_MOVEMENTS", 
              onChanged: (v) {
                setState(() {
                  _filtered = widget.list
                      .where((e) => matchesKnsQuery(v, fullName: e.fullName, shorthand: e.shorthand))
                      .toList();
                });
              }
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                if (widget.allowAll)
                  ListTile(
                    title: Text("ALL_MOVEMENTS", style: LabStyles.mono(context, color: LabColors.primary, fontSize: 11)),
                    onTap: () { widget.onSelect(null); Navigator.pop(context); },
                  ),
                ..._filtered.map((e) => ListTile(
                  title: Text(e.fullName, style: LabStyles.mono(context, fontSize: 11)),
                  onTap: () { widget.onSelect(e.id); Navigator.pop(context); },
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

