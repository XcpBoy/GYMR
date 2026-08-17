import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/theme_provider.dart';
import '../providers/charts_provider.dart';
import '../logic/chart_models.dart';
import '../database/database.dart';
import 'styles.dart';
import 'main_scaffold.dart';
import 'workout_manager.dart';
import '../localization/strings.dart';

class TimelineCalendarScreen extends ConsumerStatefulWidget {
  const TimelineCalendarScreen({super.key});

  @override
  ConsumerState<TimelineCalendarScreen> createState() => _TimelineCalendarScreenState();
}

class _TimelineCalendarScreenState extends ConsumerState<TimelineCalendarScreen> {
  final ScrollController _scrollController = ScrollController();
  final DateTime _today = DateTime.now();
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(_today.year, _today.month, 1);
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider).value ?? 'en';
    return MainScaffold(
      title: tr(lang, 'TIMELINE_CALENDAR'),
      screenKey: 'TIMELINE_CAL',
      body: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: 24, // Show 2 years for now, can be infinite later
        itemBuilder: (context, index) {
          final monthDate = DateTime(_currentMonth.year, _currentMonth.month - index, 1);
          return _MonthCalendarGrid(monthDate: monthDate);
        },
      ),
    );
  }
}

class _MonthCalendarGrid extends ConsumerWidget {
  final DateTime monthDate;
  const _MonthCalendarGrid({required this.monthDate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider).value ?? 'en';
    final timelineData = ref.watch(timelineProvider(monthDate));
    final themeSettings = ref.watch(themeSettingsProvider).value ?? {};
    final themeController = ref.read(themeControllerProvider);

    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white10, width: 0.5),
        color: Colors.black,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: LabColors.surfaceContainerHigh,
            width: double.infinity,
            child: Text(
              DateFormat('MMMM yyyy').format(monthDate).toUpperCase(),
              style: LabStyles.mono(context, fontWeight: FontWeight.bold, color: LabColors.primary),
            ),
          ),
          const SizedBox(height: 8),
          _buildDaysHeader(context, lang),
          timelineData.when(
            data: (weeks) => _buildGrid(context, weeks, themeSettings, themeController, lang),
            loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
            error: (e, s) => Text("ERR: $e"),
          ),
        ],
      ),
    );
  }

  Widget _buildDaysHeader(BuildContext context, String lang) {
    final days = [
      tr(lang, 'MON'),
      tr(lang, 'TUE'),
      tr(lang, 'WED'),
      tr(lang, 'THU'),
      tr(lang, 'FRI'),
      tr(lang, 'SAT'),
      tr(lang, 'SUN'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: days.map((d) => Expanded(
          child: Text(d, textAlign: TextAlign.center, style: LabStyles.mono(context, fontSize: 8, color: Colors.grey))
        )).toList(),
      ),
    );
  }

  Widget _buildGrid(BuildContext context, List<TimelineWeek> weeks, Map<String, ThemeSetting> settings, ThemeController controller, String lang) {
    // Generate actual grid based on month calendar logic
    final firstDayOfMonth = DateTime(monthDate.year, monthDate.month, 1);
    final lastDayOfMonth = DateTime(monthDate.year, monthDate.month + 1, 0);
    
    // We need to find which weekday the first day is (1 = Mon, 7 = Sun)
    final firstWeekday = firstDayOfMonth.weekday;
    
    final List<DateTime?> allDays = [];
    // Add empty slots for previous month
    for (int i = 1; i < firstWeekday; i++) {
      allDays.add(null);
    }
    // Add current month days
    for (int i = 1; i <= lastDayOfMonth.day; i++) {
      allDays.add(DateTime(monthDate.year, monthDate.month, i));
    }

    // Flat list of TimelineDays for easy lookup
    final Map<String, TimelineDay> dayMap = {};
    for (var w in weeks) {
      for (var d in w.days) {
        dayMap["${d.date.year}-${d.date.month}-${d.date.day}"] = d;
      }
    }

    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          childAspectRatio: 0.8,
        ),
        itemCount: allDays.length,
        itemBuilder: (context, index) {
          final dayDate = allDays[index];
          if (dayDate == null) return const SizedBox();
          
          final dayData = dayMap["${dayDate.year}-${dayDate.month}-${dayDate.day}"];
          return _CalendarDayCell(date: dayDate, data: dayData, settings: settings, controller: controller, lang: lang);
        },
      ),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  final DateTime date;
  final TimelineDay? data;
  final Map<String, ThemeSetting> settings;
  final ThemeController controller;
  final String lang;

  const _CalendarDayCell({required this.date, this.data, required this.settings, required this.controller, required this.lang});

  @override
  Widget build(BuildContext context) {
    final isToday = date.year == DateTime.now().year && date.month == DateTime.now().month && date.day == DateTime.now().day;

    return InkWell(
      onTap: data != null ? () => _showDaySummary(context, data!) : null,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(
            color: isToday ? LabColors.primary : (data != null ? Colors.white10 : Colors.transparent),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(2.0),
              child: Text(
                date.day.toString(), 
                style: LabStyles.mono(context, fontSize: 8, color: data != null ? Colors.white : Colors.grey[800]),
              ),
            ),
            const Spacer(),
            if (data != null)
              Padding(
                padding: const EdgeInsets.all(2.0),
                child: Wrap(
                  spacing: 2,
                  runSpacing: 2,
                  children: data!.patterns.map((p) {
                    final color = controller.getColor(settings, "pattern_$p", nameSeed: p);
                    return Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: color,
                        border: Border.all(color: Colors.black, width: 0.5),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showDaySummary(BuildContext context, TimelineDay data) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: LabColors.background,
        shape: const RoundedRectangleBorder(side: BorderSide(color: LabColors.primary, width: 0.5)),
        title: Row(
          children: [
            const Icon(Icons.analytics, color: LabColors.primary, size: 18),
            const SizedBox(width: 8),
            Text(formatLocalizedDate(lang, date, withYear: false), style: LabStyles.mono(context, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr(lang, "KNS_SUMMARY:"), style: LabStyles.mono(context, fontSize: 10, color: LabColors.primary)),
                const SizedBox(height: 12),
                ...data.exercises.map((ex) {
                  final pattern = data.exercisePatterns[ex] ?? "NONE";
                  final color = controller.getColor(settings, "pattern_$pattern", nameSeed: pattern);
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            border: Border.all(color: Colors.black, width: 0.5),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(ex.toUpperCase(), style: LabStyles.mono(context, fontSize: 10)),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(tr(lang, "TOTAL_VOLUME:"), style: LabStyles.mono(context, fontSize: 8, color: Colors.grey)),
                    Text("${data.totalVolume.toStringAsFixed(0)} KG", style: LabStyles.mono(context, fontSize: 8, fontWeight: FontWeight.bold, color: LabColors.accent)),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(c);
              Navigator.push(context, MaterialPageRoute(builder: (c) => WorkoutManagerScreen(initialDate: date)));
            },
            child: Text(tr(lang, "GOTO_SESSION"), style: LabStyles.mono(context, color: LabColors.primary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text(tr(lang, "CLOSE"), style: LabStyles.mono(context, color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}
