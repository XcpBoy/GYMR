import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/charts_provider.dart';
import '../providers/theme_provider.dart';
import '../logic/chart_models.dart';
import 'styles.dart';
import 'workout_manager.dart';
import 'lab_widgets.dart';
import 'main_scaffold.dart';
import '../database/database.dart';
import 'timeline_calendar_screen.dart';
import '../localization/strings.dart';

class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key});

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _onlyPr = false;
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider).value ?? 'en';
    final selectedMonth = ref.watch(selectedMonthProvider);
    final timelineData = ref.watch(timelineProvider(selectedMonth));
    final themeSettings = ref.watch(themeSettingsProvider).value ?? {};
    final themeController = ref.read(themeControllerProvider);

    return MainScaffold(
      title: tr(lang, 'CHRONO_HISTORY'),
      screenKey: 'TIMELINE',
      body: Column(
        children: [
          _buildMonthNavigator(context, selectedMonth),
          _buildFilters(context, lang),
          Expanded(
            child: timelineData.when(
              data: (weeks) {
                final displayWeeks = weeks
                    .map((week) {
                      final filteredDays = week.days.where((day) {
                        final matchesQuery = _searchQuery.isEmpty ||
                            day.exercises.any((e) => e.toLowerCase().contains(_searchQuery.toLowerCase())) ||
                            day.fields.any((f) => f.toLowerCase().contains(_searchQuery.toLowerCase()));
                        final matchesPr = !_onlyPr || day.hasPr;
                        return matchesQuery && matchesPr;
                      }).toList();
                      return TimelineWeek(year: week.year, weekNumber: week.weekNumber, days: filteredDays);
                    })
                    .where((week) => week.days.isNotEmpty)
                    .toList();

                if (displayWeeks.isEmpty) return _buildEmptyState(context, lang);
                
                return ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  itemCount: displayWeeks.length,
                  itemBuilder: (context, index) => _buildWeekColumn(context, displayWeeks[index], themeSettings, themeController),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: LabColors.primary)),
              error: (e, s) => Center(child: Text("ERR: $e", style: LabStyles.mono(context))),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const LabFooter(),
    );
  }

  Widget _buildFilters(BuildContext context, String lang) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: LabTextField(
              controller: _searchController,
              label: tr(lang, 'FILTER_BY_MOVE_OR_FIELD'),
              onChanged: (v) {
                _searchDebounce?.cancel();
                _searchDebounce = Timer(const Duration(milliseconds: 300), () {
                  if (mounted) setState(() => _searchQuery = v);
                });
              },
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              Text(tr(lang, 'PR_ONLY'), style: LabStyles.mono(context, fontSize: 7, color: Colors.grey)),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => setState(() => _onlyPr = !_onlyPr),
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: _onlyPr ? LabColors.accent.withValues(alpha: 0.1) : Colors.black,
                    border: Border.all(color: _onlyPr ? LabColors.accent : Colors.grey[800]!, width: 0.5),
                  ),
                  child: Icon(Icons.emoji_events, size: 16, color: _onlyPr ? LabColors.accent : Colors.grey[700]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthNavigator(BuildContext context, DateTime selectedMonth) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 40),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: LabColors.primary, size: 20),
                onPressed: () {
                  ref.read(selectedMonthProvider.notifier).state =
                      DateTime(selectedMonth.year, selectedMonth.month - 1, 1);
                },
              ),
              Text(
                DateFormat('MMMM yyyy').format(selectedMonth).toUpperCase(),
                style: LabStyles.mono(context, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: LabColors.primary, size: 20),
                onPressed: () {
                  ref.read(selectedMonthProvider.notifier).state =
                      DateTime(selectedMonth.year, selectedMonth.month + 1, 1);
                },
              ),
            ],
          ),
          TimelineViewSwitcher(
            isMonthView: false,
            onSwitch: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const TimelineCalendarScreen()));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String lang) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today, size: 48, color: Colors.grey[800]),
          const SizedBox(height: 16),
          Text(tr(lang, "NO_DATA_FOR_THIS_PERIOD"), style: LabStyles.mono(context, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildWeekColumn(BuildContext context, TimelineWeek week, Map<String, ThemeSetting> settings, ThemeController controller) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 24),
      decoration: BoxDecoration(
        border: Border.all(color: LabColors.cyanBorder.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: LabColors.cyanBorder, width: 0.5)),
              color: LabColors.surfaceContainerLow,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("WEEK_${week.weekNumber.toString().padLeft(2, '0')}", style: LabStyles.mono(context, fontWeight: FontWeight.bold, color: LabColors.primary)),
                Text("${week.year}", style: LabStyles.mono(context, fontSize: 10, color: LabColors.primary.withValues(alpha: 0.5))),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: week.days.length,
              itemBuilder: (context, dIndex) => _buildDayCard(context, week.days[dIndex], settings, controller),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCard(BuildContext context, TimelineDay day, Map<String, ThemeSetting> settings, ThemeController controller) {
    final dayName = DateFormat('EEE.dd').format(day.date).toUpperCase();
    
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (c) => WorkoutManagerScreen(initialDate: day.date)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: LabStyles.hairlineBorder(context, color: day.hasPr ? LabColors.accent.withValues(alpha: 0.3) : LabColors.primary.withValues(alpha: 0.2)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(dayName, style: LabStyles.mono(context, fontWeight: FontWeight.bold, color: day.hasPr ? LabColors.accent : Colors.white)),
                if (day.hasPr) const Icon(Icons.emoji_events, size: 14, color: LabColors.accent),
                Text("${day.totalVolume.toStringAsFixed(0)} KG", style: LabStyles.mono(context, fontSize: 10, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            // Color-coded Patterns
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: day.patterns.map((p) {
                final color = controller.getColor(settings, "pattern_$p", nameSeed: p);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    border: Border.all(color: color.withValues(alpha: 0.5), width: 0.5),
                  ),
                  child: Text(p.toUpperCase(), style: LabStyles.mono(context, fontSize: 8, color: color, fontWeight: FontWeight.bold)),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            // Fields
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: day.fields.map((f) {
                final color = controller.getColor(settings, "field_$f", nameSeed: f);
                return Text(
                  "#${f.toUpperCase()}", 
                  style: LabStyles.mono(context, fontSize: 7, color: color.withValues(alpha: 0.7))
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: day.exercises.map((ex) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  border: Border.all(color: LabColors.onSurface.withValues(alpha: 0.1), width: 0.5),
                ),
                child: Text(
                  ex.toUpperCase(),
                  style: LabStyles.mono(context, fontSize: 7, color: LabColors.onSurface.withValues(alpha: 0.6)),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Segmented WEEK/MONTH toggle shared by [TimelineScreen] and
/// [TimelineCalendarScreen] so both views read as one feature instead of
/// a hidden sub-page reachable only by a tiny icon. Uses
/// pushReplacement so switching swaps the view instead of piling up the
/// back stack.
class TimelineViewSwitcher extends StatelessWidget {
  final bool isMonthView;
  final VoidCallback onSwitch;

  const TimelineViewSwitcher({super.key, required this.isMonthView, required this.onSwitch});

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
      decoration: LabStyles.hairlineBorder(context, color: LabColors.cyanBorder.withValues(alpha: 0.4)),
      child: InkWell(
        onTap: onSwitch,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            segment('WEEK', !isMonthView),
            segment('MONTH', isMonthView),
          ],
        ),
      ),
    );
  }
}

