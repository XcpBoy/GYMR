import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:intl/intl.dart';
import 'dart:convert'; // For jsonDecode
import 'dart:async'; // For Timer

import '../providers/database_provider.dart';
import '../providers/theme_provider.dart';
import '../database/database.dart';
import '../logic/calculator.dart';
import '../services/ovarch_plan_injection_service.dart';
import 'styles.dart';
import 'lab_widgets.dart';
import 'main_scaffold.dart';
import 'complex_metadata_screen.dart';
import 'exercise_history_screen.dart';
import 'edit_exercise_screen.dart';

// --- Timer State ---
final currentWorkoutLogProvider = StreamProvider<WorkoutLog?>((ref) {
  final db = ref.watch(databaseProvider);
  final today = DateTime.now();
  return (db.select(db.workoutLogs)
        ..where((t) => t.date.isBetweenValues(
            DateTime(today.year, today.month, today.day),
            DateTime(today.year, today.month, today.day, 23, 59, 59))))
      .watchSingleOrNull();
});

final timerTickProvider = StreamProvider<int>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (x) => x);
});

// --- Timeline State ---
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

final workoutSetsProvider =
    StreamProvider.family<List<drift.TypedResult>, DateTime>((ref, date) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.workoutSets).join([
    drift.innerJoin(db.baseExercises,
        db.baseExercises.id.equalsExp(db.workoutSets.baseExerciseId)),
    drift.innerJoin(
        db.workoutLogs, db.workoutLogs.id.equalsExp(db.workoutSets.logId))
  ])
        ..where(db.workoutLogs.date.isBetweenValues(
            DateTime(date.year, date.month, date.day),
            DateTime(date.year, date.month, date.day, 23, 59, 59)))
        ..orderBy([
          drift.OrderingTerm.asc(db.workoutSets.orderIndex),
          drift.OrderingTerm.asc(db.workoutSets.timestamp)
        ]))
      .watch();
});

final bodyWeightAtDateProvider =
    StreamProvider.family<double, DateTime>((ref, date) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.anthropometricLogs)
        ..where((t) => t.label.equals('WEIGHT'))
        ..where((t) => t.date.isSmallerOrEqualValue(date))
        ..orderBy([(t) => drift.OrderingTerm.desc(t.date)])
        ..limit(1))
      .watchSingleOrNull()
      .map((log) => log?.value ?? 0.0);
});

/// Session number provider — assigns sequential numbers to dates with sets.
/// Only dates that have at least one registered workout set count as sessions.
final sessionNumbersProvider = StreamProvider<Map<String, int>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.workoutSets).join([
    drift.innerJoin(
        db.workoutLogs, db.workoutLogs.id.equalsExp(db.workoutSets.logId))
  ])
        ..orderBy([drift.OrderingTerm.asc(db.workoutLogs.date)]))
      .watch()
      .map((rows) {
    final seen = <String>{};
    final result = <String, int>{};
    int counter = 0;
    for (final row in rows) {
      final date = row.readTable(db.workoutLogs).date;
      final key = DateFormat('yyyy-MM-dd').format(date);
      if (seen.contains(key)) continue;
      seen.add(key);
      counter++;
      result[key] = counter;
    }
    return result;
  });
});

class WorkoutManagerScreen extends ConsumerStatefulWidget {
  final DateTime? initialDate;
  const WorkoutManagerScreen({super.key, this.initialDate});

  @override
  ConsumerState<WorkoutManagerScreen> createState() =>
      _WorkoutManagerScreenState();
}

class _WorkoutManagerScreenState extends ConsumerState<WorkoutManagerScreen> {
  late PageController _pageController;
  static const int _centerPage = 10000;
  bool _isSwiping = false;

  @override
  void initState() {
    super.initState();
    int initialPage = _centerPage;
    if (widget.initialDate != null) {
      initialPage = _centerPage +
          widget.initialDate!
              .difference(DateTime(DateTime.now().year, DateTime.now().month,
                  DateTime.now().day))
              .inDays;
      Future.microtask(() {
        ref.read(selectedDateProvider.notifier).state = widget.initialDate!;
      });
    }
    _pageController = PageController(initialPage: initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: '',
      screenKey: 'WORKOUT',
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.depth == 0) {
            if (notification is ScrollStartNotification)
              setState(() => _isSwiping = true);
            if (notification is ScrollEndNotification)
              setState(() => _isSwiping = false);
          }
          return false;
        },
        child: PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            final newDate =
                DateTime.now().add(Duration(days: index - _centerPage));
            ref.read(selectedDateProvider.notifier).state = newDate;
          },
          itemBuilder: (context, index) {
            final date =
                DateTime.now().add(Duration(days: index - _centerPage));
            return SafeArea(
                child: _WorkoutDayPage(date: date, isScrolling: _isSwiping));
          },
        ),
      ),
      bottomNavigationBar: const LabFooter(),
    );
  }
}

class _WorkoutDayPage extends ConsumerStatefulWidget {
  final DateTime date;
  final bool isScrolling;
  const _WorkoutDayPage({required this.date, required this.isScrolling});

  @override
  ConsumerState<_WorkoutDayPage> createState() => _WorkoutDayPageState();
}

class _WorkoutDayPageState extends ConsumerState<_WorkoutDayPage> {
  late ScrollController _scrollController;
  final Set<String> _expandedUtils = {};

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isScrolling) {
      return Center(
          child: Text(
              DateFormat('EEEE, MMM d, yyyy').format(widget.date).toUpperCase(),
              style: LabStyles.mono(context, color: Colors.grey[800])));
    }

    final db = ref.watch(databaseProvider);
    final workoutAsync = ref.watch(workoutSetsProvider(widget.date));
    final isToday = DateFormat('yyyy-MM-dd').format(widget.date) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());
    final bw = ref.watch(bodyWeightAtDateProvider(widget.date)).value ?? 0.0;
    final settings = ref.watch(themeSettingsProvider).value ?? {};
    final tC = ref.read(themeControllerProvider);

    return Stack(children: [
      SingleChildScrollView(
          controller: _scrollController,
          padding:
              const EdgeInsets.only(top: 40, left: 16, right: 16, bottom: 150),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildHeader(context, widget.date, ref, workoutAsync.value ?? []),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () =>
                  _showWorkoutOptsSheet(context, ref, workoutAsync.value ?? []),
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tC
                      .getColor(settings, 'UI_TAG_WORKOUT_OPTS',
                          nameSeed: 'WORKOUT_OPTS')
                      .withValues(alpha: 0.12),
                  border: Border.all(
                      color: tC.getColor(settings, 'UI_TAG_WORKOUT_OPTS',
                          nameSeed: 'WORKOUT_OPTS'),
                      width: 0.5),
                ),
                child: Text(
                  'WORKOUT OPTS',
                  style: LabStyles.mono(context,
                      fontSize: 9,
                      color: tC.getColor(settings, 'UI_TAG_WORKOUT_OPTS',
                          nameSeed: 'WORKOUT_OPTS'),
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (isToday) ...[
              workoutAsync.when(
                data: (results) => results.isNotEmpty
                    ? Column(
                        children: [
                          const SizedBox(height: 24),
                        ],
                      )
                    : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (e, s) => const SizedBox.shrink(),
              ),
            ],
            workoutAsync.when(
              data: (results) {
                if (results.isEmpty) return _buildEmptyState(context);

                final Map<int, List<drift.TypedResult>> groupedByEx = {};
                final List<int> exerciseIdsInOrder = [];
                WorkoutLog? currentLog;

                for (var row in results) {
                  final exId = row.readTable(db.baseExercises).id;
                  currentLog ??= row.readTable(db.workoutLogs);
                  if (!groupedByEx.containsKey(exId)) {
                    groupedByEx[exId] = [];
                    exerciseIdsInOrder.add(exId);
                  }
                  groupedByEx[exId]!.add(row);
                }

                // --- ROBUST SUPERSET GROUPING LOGIC ---
                final List<List<int>> supersetGroups = [];
                final Set<int> processed = {};

                for (var exId in exerciseIdsInOrder) {
                  if (processed.contains(exId)) continue;

                  final firstSet =
                      groupedByEx[exId]!.first.readTable(db.workoutSets);
                  if (firstSet.supersetGroupId != null) {
                    final String gId = firstSet.supersetGroupId!;
                    final List<int> group = [];
                    for (var id in exerciseIdsInOrder) {
                      if (groupedByEx[id]!
                              .first
                              .readTable(db.workoutSets)
                              .supersetGroupId ==
                          gId) {
                        group.add(id);
                        processed.add(id);
                      }
                    }
                    supersetGroups.add(group);
                  } else {
                    supersetGroups.add([exId]);
                    processed.add(exId);
                  }
                }

                // --- BUILD INTERLEAVED LIST (batches + unbatched in orderIndex order) ---
                // Walk supersetGroups sequentially: when a batch is encountered, start a section;
                // when an unbatched group appears, close any open batch and render solo.
                final List<Object> interleavedItems = [];
                String? currentBatchName;
                List<List<int>> currentBatchGroups = [];

                for (final group in supersetGroups) {
                  final firstSet =
                      groupedByEx[group.first]!.first.readTable(db.workoutSets);
                  String? batchName;
                  if (firstSet.complexMetadata != null) {
                    try {
                      final meta = jsonDecode(firstSet.complexMetadata!);
                      if (meta['batch'] != null) {
                        final b = meta['batch'].toString();
                        if (b.isNotEmpty) batchName = b;
                      }
                    } catch (_) {}
                  }

                  if (batchName != null) {
                    if (currentBatchName != batchName) {
                      // Flush previous batch section
                      if (currentBatchName != null) {
                        interleavedItems.add(MapEntry(currentBatchName!,
                            List<List<int>>.from(currentBatchGroups)));
                        currentBatchGroups.clear();
                      }
                      currentBatchName = batchName;
                    }
                    currentBatchGroups.add(group);
                  } else {
                    // Flush any open batch section
                    if (currentBatchName != null) {
                      interleavedItems.add(MapEntry(currentBatchName!,
                          List<List<int>>.from(currentBatchGroups)));
                      currentBatchName = null;
                      currentBatchGroups.clear();
                    }
                    interleavedItems.add(group);
                  }
                }
                // Flush final batch
                if (currentBatchName != null) {
                  interleavedItems.add(MapEntry(currentBatchName!,
                      List<List<int>>.from(currentBatchGroups)));
                }

                // Build all widgets in order, one flatIdx for the entire list
                final List<Widget> mainWidgets = [];
                int flatIdx = 0;
                int globalSetCounter = 0;
                for (final item in interleavedItems) {
                  if (item is List<int>) {
                    // ── Unbatched group ──
                    final group = item;
                    final firstExId = group.first;
                    final firstSet =
                        groupedByEx[firstExId]!.first.readTable(db.workoutSets);
                    final isSuperset = firstSet.supersetGroupId != null;
                    final supersetName = firstSet.supersetName;
                    Color groupColor = Colors.transparent;
                    if (isSuperset && supersetName != null) {
                      groupColor = tC.getColor(
                          settings, "SUPERSET_$supersetName",
                          nameSeed: supersetName);
                    }
                    mainWidgets.add(_buildGroupWidget(group,
                        groupIdx: flatIdx,
                        groupColor: groupColor,
                        isSuperset: isSuperset,
                        supersetName: supersetName,
                        groupedByEx: groupedByEx,
                        db: db,
                        bw: bw,
                        globalSetStart: globalSetCounter));
                    // Update counter for next group: count all sets in this group's exercises
                    for (final exId in group) {
                      globalSetCounter += groupedByEx[exId]!.length;
                    }
                    flatIdx++;
                  } else if (item is MapEntry<String, List<List<int>>>) {
                    // ── Batch section ──
                    final batchName = item.key;
                    final groups = item.value;
                    final isExpanded =
                        _expandedUtils.contains('batch_$batchName');

                    final batchGroupWidgets = groups.map((group) {
                      final firstExId = group.first;
                      final firstSet = groupedByEx[firstExId]!
                          .first
                          .readTable(db.workoutSets);
                      final isSuperset = firstSet.supersetGroupId != null;
                      final supersetName = firstSet.supersetName;
                      Color groupColor = Colors.transparent;
                      if (isSuperset && supersetName != null) {
                        groupColor = tC.getColor(
                            settings, "SUPERSET_$supersetName",
                            nameSeed: supersetName);
                      }
                      final w = _buildGroupWidget(group,
                          groupIdx: flatIdx++,
                          groupColor: groupColor,
                          isSuperset: isSuperset,
                          supersetName: supersetName,
                          groupedByEx: groupedByEx,
                          db: db,
                          bw: bw,
                          globalSetStart: globalSetCounter);
                      for (final exId in group) {
                        globalSetCounter += groupedByEx[exId]!.length;
                      }
                      return w;
                    }).toList();

                    mainWidgets.add(
                      Container(
                        key: ValueKey('batch_$batchName'),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () => setState(() {
                                if (isExpanded) {
                                  _expandedUtils.remove('batch_$batchName');
                                } else {
                                  _expandedUtils.add('batch_$batchName');
                                }
                              }),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: tC
                                      .getColor(
                                          settings, 'UI_TAG_BATCH_$batchName',
                                          nameSeed: batchName)
                                      .withValues(alpha: 0.1),
                                  border: Border(
                                      left: BorderSide(
                                          color: tC.getColor(settings,
                                              'UI_TAG_BATCH_$batchName',
                                              nameSeed: batchName),
                                          width: 3)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.drag_indicator,
                                        size: 14, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text(isExpanded ? '[ − ]' : '[ + ]',
                                        style: LabStyles.mono(context,
                                            fontSize: 10,
                                            color: Colors.grey[400])),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(batchName.toUpperCase(),
                                          style: LabStyles.mono(context,
                                              fontSize: 11,
                                              color: tC.getColor(settings,
                                                  'UI_TAG_BATCH_$batchName',
                                                  nameSeed: batchName),
                                              fontWeight: FontWeight.bold)),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                      child: Text('${groups.length} KNS',
                                          style: LabStyles.mono(context,
                                              fontSize: 8,
                                              color: Colors.grey[500])),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (isExpanded) ...[
                              const SizedBox(height: 8),
                              ReorderableListView(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                onReorder: (oldIdx, newIdx) async {
                                  if (newIdx > oldIdx) newIdx--;
                                  final reordered =
                                      List<List<int>>.from(groups);
                                  final moved = reordered.removeAt(oldIdx);
                                  reordered.insert(newIdx, moved);
                                  // Recalculate full order from interleavedItems with this batch reordered
                                  final List<int> orderIds = [];
                                  for (final oi in interleavedItems) {
                                    if (oi is List<int>) {
                                      orderIds.addAll(oi);
                                    } else if (oi
                                        is MapEntry<String, List<List<int>>>) {
                                      final bg = (oi.key == batchName)
                                          ? reordered
                                          : oi.value;
                                      for (final g in bg) {
                                        orderIds.addAll(g);
                                      }
                                    }
                                  }
                                  await db.transaction(() async {
                                    for (int i = 0; i < orderIds.length; i++) {
                                      final exId = orderIds[i];
                                      final setIds = groupedByEx[exId]!
                                          .map((r) =>
                                              r.readTable(db.workoutSets).id)
                                          .toList();
                                      await (db.update(db.workoutSets)
                                            ..where((t) => t.id.isIn(setIds)))
                                          .write(WorkoutSetsCompanion(
                                              orderIndex: drift.Value(i)));
                                    }
                                  });
                                },
                                children: batchGroupWidgets,
                              ),
                              const SizedBox(height: 8),
                            ],
                          ],
                        ),
                      ),
                    );
                  }
                }

                return Column(
                  children: [
                    ReorderableListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      onReorder: (oldIdx, newIdx) async {
                        if (newIdx > oldIdx) newIdx--;
                        final reorderedList =
                            List<Object>.from(interleavedItems);
                        final moved = reorderedList.removeAt(oldIdx);
                        reorderedList.insert(newIdx, moved);
                        // Calculate flat orderIndex for ALL sets
                        final List<int> orderIds = [];
                        for (final oi in reorderedList) {
                          if (oi is List<int>) {
                            orderIds.addAll(oi);
                          } else if (oi is MapEntry<String, List<List<int>>>) {
                            for (final g in oi.value) {
                              orderIds.addAll(g);
                            }
                          }
                        }
                        await db.transaction(() async {
                          for (int i = 0; i < orderIds.length; i++) {
                            final exId = orderIds[i];
                            final setIds = groupedByEx[exId]!
                                .map((r) => r.readTable(db.workoutSets).id)
                                .toList();
                            await (db.update(db.workoutSets)
                                  ..where((t) => t.id.isIn(setIds)))
                                .write(WorkoutSetsCompanion(
                                    orderIndex: drift.Value(i)));
                          }
                        });
                      },
                      children: mainWidgets,
                    ),
                    if (currentLog != null) ...[
                      _GeneralNotesModule(
                          key: const ValueKey('general_notes'),
                          log: currentLog),
                    ],
                  ],
                );
              },
              loading: () => const Center(
                  child: Padding(
                padding: EdgeInsets.only(top: 100),
                child: CircularProgressIndicator(color: LabColors.primary),
              )),
              error: (e, s) => Center(
                  child: Padding(
                padding: const EdgeInsets.only(top: 100),
                child: Text("ERR: $e",
                    style: LabStyles.mono(context, color: Colors.redAccent)),
              )),
            ),
          ])),
      Positioned(
          bottom: 24,
          right: 24,
          child: FloatingActionButton(
              backgroundColor: LabColors.primary,
              onPressed: () => _showExercisePicker(context, ref, widget.date),
              child: const Icon(Icons.add, color: Colors.black, size: 32))),
    ]);
  }

  Widget _buildHeader(BuildContext context, DateTime date, WidgetRef ref,
      List<drift.TypedResult> results) {
    final isToday = DateFormat('yyyy-MM-dd').format(date) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());
    final settings = ref.watch(themeSettingsProvider).value ?? {};
    final tC = ref.read(themeControllerProvider);
    final dateColor =
        tC.getColor(settings, 'UI_DATE_DISPLAY', defaultColor: Colors.white);
    final sessionNums = ref.watch(sessionNumbersProvider).value ?? {};
    final seshNum = sessionNums[DateFormat('yyyy-MM-dd').format(date)];
    final db = ref.read(databaseProvider);

    // Metrics
    final totalSets = results.length;
    final knsCount = results
        .map((r) => r.readTable(db.workoutSets).baseExerciseId)
        .toSet()
        .length;
    final prCount =
        results.where((r) => r.readTable(db.workoutSets).isPr).length;
    final utilSet = results
        .map((r) => r.readTable(db.workoutSets).priority ?? '')
        .where((p) => p.isNotEmpty)
        .toSet()
        .toList();
    final utilOrder = [
      'PRIMARY',
      'SECONDARY',
      'ARM WRSTLN',
      'TERCIARY',
      'PRACTICE',
      'GTG',
      'PUMP',
      'COMPLEMENT',
      'PREHAB',
      'RECOVERY',
      'BLOOD FLOW',
      'REHAB',
      'TENDONS',
      'BODYBUILDING'
    ];
    utilSet.sort((a, b) {
      final ai = utilOrder.indexOf(a);
      final bi = utilOrder.indexOf(b);
      if (ai == -1 && bi == -1) return a.compareTo(b);
      if (ai == -1) return 1;
      if (bi == -1) return -1;
      return ai.compareTo(bi);
    });

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
            height: 2,
            width: 24,
            color: isToday ? LabColors.primary : Colors.orangeAccent),
        const SizedBox(height: 4),
        Text(DateFormat('dd/MM/yy').format(date),
            style: LabStyles.mono(context, fontSize: 11, color: dateColor)),
        const SizedBox(height: 4),
        Text(
          isToday
              ? 'CURRENT WORKOUT'
              : (seshNum != null
                  ? 'SESH #$seshNum'
                  : DateFormat('EEEE, MMM d, yyyy').format(date).toUpperCase()),
          style: LabStyles.headline(context).copyWith(
              fontSize: 22,
              color: tC.getColor(settings, 'UI_SESH_NUMBER',
                  defaultColor: dateColor),
              letterSpacing: -0.5),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white12, width: 0.5),
          ),
          child: Row(
            children: [
              Text('$totalSets SETS',
                  style: LabStyles.mono(context,
                      fontSize: 9,
                      color: Colors.white70,
                      fontWeight: FontWeight.bold)),
              Container(
                  width: 1,
                  height: 12,
                  color: Colors.white12,
                  margin: const EdgeInsets.symmetric(horizontal: 8)),
              Text('$knsCount KNS',
                  style: LabStyles.mono(context,
                      fontSize: 9,
                      color: Colors.cyanAccent,
                      fontWeight: FontWeight.bold)),
              Container(
                  width: 1,
                  height: 12,
                  color: Colors.white12,
                  margin: const EdgeInsets.symmetric(horizontal: 8)),
              Text('$prCount PRs',
                  style: LabStyles.mono(context,
                      fontSize: 9,
                      color: LabColors.accent,
                      fontWeight: FontWeight.bold)),
              if (utilSet.isNotEmpty) ...[
                Container(
                    width: 1,
                    height: 12,
                    color: Colors.white12,
                    margin: const EdgeInsets.symmetric(horizontal: 8)),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: utilSet
                          .map((u) => Container(
                                margin: const EdgeInsets.only(right: 4),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: tC
                                      .getColor(settings,
                                          'UI_TAG_${u.replaceAll(' ', '_')}',
                                          nameSeed: u)
                                      .withValues(alpha: 0.15),
                                  border: Border.all(
                                      color: tC
                                          .getColor(settings,
                                              'UI_TAG_${u.replaceAll(' ', '_')}',
                                              nameSeed: u)
                                          .withValues(alpha: 0.5),
                                      width: 0.5),
                                ),
                                child: Text(u,
                                    style: LabStyles.mono(context,
                                        fontSize: 7, color: Colors.white)),
                              ))
                          .toList(),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGroupWidget(List<int> group,
      {required int groupIdx,
      required Color groupColor,
      required bool isSuperset,
      String? supersetName,
      required Map<int, List<drift.TypedResult>> groupedByEx,
      required AppDatabase db,
      required double bw,
      int globalSetStart = 0,
      bool showDragHandle = true}) {
    final firstExId = group.first;
    int runningGlobal = globalSetStart;
    return Container(
      key: ValueKey('gw_${firstExId}_$groupIdx'),
      margin: const EdgeInsets.only(bottom: 1),
      decoration: isSuperset
          ? BoxDecoration(
              border: Border.all(
                  color: groupColor.withValues(alpha: 0.8), width: 1.5),
              color: groupColor.withValues(alpha: 0.05),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isSuperset)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              color: groupColor.withValues(alpha: 0.8),
              child: Text(supersetName!.toUpperCase(),
                  style: LabStyles.mono(context,
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
          ...group.map((exId) {
            final exSets = groupedByEx[exId]!.length;
            final ex = groupedByEx[exId]!.first.readTable(db.baseExercises);
            final exIntention = ex.intention ?? '';
            final exMetaMatch =
                RegExp(r'\[NT:(.*)\|ISO:(.*)\]').firstMatch(exIntention);
            String exLoadType = 'EXT.LOAD';
            bool exIsIso = exIntention.startsWith('[ISO]');
            bool exIsJst = false;
            if (exMetaMatch != null) {
              exLoadType = exMetaMatch.group(1) ?? 'EXT.LOAD';
              exIsIso = exMetaMatch.group(2) == 'true';
              exIsJst = exLoadType == 'JST.BW';
            } else if (['LASTRE', 'EXT.LOAD', 'JST.BW'].contains(ex.field)) {
              exLoadType = ex.field!;
              exIsJst = exLoadType == 'JST.BW';
            }
            final mod = _ExerciseModule(
              key: ValueKey('ex_${firstExId}_$exId'),
              exercise: ex,
              results: groupedByEx[exId]!,
              date: widget.date,
              bodyWeight: bw,
              index: groupIdx,
              globalSetStart: runningGlobal,
              scrollController: _scrollController,
              moduleIsIso: exIsIso,
              moduleIsJst: exIsJst,
              moduleLoadType: exLoadType,
              showDragHandle: showDragHandle,
            );
            runningGlobal += exSets;
            return mod;
          }),
        ],
      ),
    );
  }

  // ─── WORKOUT OPTS ─────────────────────────────────────────────
  void _showWorkoutOptsSheet(
      BuildContext context, WidgetRef ref, List<drift.TypedResult> results) {
    showModalBottomSheet(
      context: context,
      backgroundColor: LabColors.background,
      isScrollControlled: true,
      builder: (ctx) => _WorkoutOptsSheet(
        date: widget.date,
        results: results,
        onMakeBlueprint: () {
          Navigator.pop(ctx);
          _createBlueprintFromCurrentDay(context, ref, results);
        },
        onDeleteAll: () {
          Navigator.pop(ctx);
          _deleteAllSets(context, ref, results);
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // WORKOUT OPTS BOTTOM SHEET — modular slice architecture
  // ═══════════════════════════════════════════════════════════════
  // To add a new option: add a _WorkoutOptsSlice entry in the
  // slices list inside _WorkoutOptsSheetState.build().
  // Each slice is self-contained (label, icon, color, action).
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSessionTimer(BuildContext context, WidgetRef ref) {
    return const _EditableSessionTimer();
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
        child: Padding(
            padding: const EdgeInsets.only(top: 100),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.inbox, size: 48, color: Colors.grey[800]),
              const SizedBox(height: 16),
              Text('NO_MOVEMENTS_LOGGED_FOR_THIS_PERIOD',
                  style: LabStyles.mono(context,
                      color: Colors.grey[600]!, fontSize: 10))
            ])));
  }

  void _showExercisePicker(
      BuildContext context, WidgetRef ref, DateTime date) async {
    final settings = ref.read(themeSettingsProvider).value ?? {};
    final tC = ref.read(themeControllerProvider);
    showModalBottomSheet(
        context: context,
        backgroundColor: LabColors.background,
        isScrollControlled: true,
        builder: (context) => Container(
            padding: const EdgeInsets.all(24),
            height: MediaQuery.of(context).size.height * 0.45,
            child: SingleChildScrollView(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('INJECTION TYPE',
                      style:
                          LabStyles.headline(context, color: LabColors.primary)
                              .copyWith(fontSize: 18, letterSpacing: 2)),
                  const SizedBox(height: 24),
                  LabButton(
                      label: 'Individual Movement',
                      color: tC.getColor(
                          settings, 'INJECTION_INDIVIDUAL_MOVEMENT',
                          defaultColor: LabColors.tertiary,
                          nameSeed: 'INDIVIDUAL_MOVEMENT'),
                      onPressed: () async {
                        print(
                            '[CWO_INJECTION] button=Individual Movement pressed date=${date.toIso8601String()}');
                        Navigator.pop(context);
                        final db = ref.read(databaseProvider);
                        final all = await db.select(db.baseExercises).get();
                        if (context.mounted)
                          showModalBottomSheet(
                              context: context,
                              backgroundColor: LabColors.background,
                              isScrollControlled: true,
                              builder: (c) => ExerciseSearchPicker(
                                  exercises: all,
                                  onSelected: (e) =>
                                      _addExerciseToDate(ref, date, e)));
                      }),
                  const SizedBox(height: 12),
                  LabButton(
                      label: 'Workout Block',
                      color: tC.getColor(settings, 'INJECTION_WORKOUT_BLOCK',
                          defaultColor: LabColors.accent,
                          nameSeed: 'WORKOUT_BLOCK'),
                      onPressed: () async {
                        print(
                            '[CWO_INJECTION] button=Workout Block pressed date=${date.toIso8601String()}');
                        Navigator.pop(context);
                        if (context.mounted) _showWbPicker(ref, date);
                      }),
                  const SizedBox(height: 12),
                  LabButton(
                      label: 'Plan Day',
                      color: tC.getColor(settings, 'INJECTION_PLAN_DAY',
                          defaultColor: LabColors.primary,
                          nameSeed: 'PLAN_DAY'),
                      onPressed: () async {
                        print(
                            '[CWO_INJECTION] button=Plan Day pressed date=${date.toIso8601String()}');
                        print(
                            '[CWO_INJECTION] closing injection type sheet before Plan Day picker');
                        Navigator.pop(context);
                        if (mounted) {
                          print(
                              '[CWO_INJECTION] reopening Plan Day picker with State.context');
                          _showPlanDayPicker(this.context, ref, date);
                        } else {
                          print('[CWO_INJECTION] State not mounted after pop');
                        }
                      }),
                  const SizedBox(height: 12),
                  LabButton(
                      label: 'Copy From Specific Day',
                      color: tC.getColor(
                          settings, 'INJECTION_COPY_FROM_SPECIFIC_DAY',
                          defaultColor: LabColors.secondary,
                          nameSeed: 'COPY_FROM_SPECIFIC_DAY'),
                      onPressed: () {
                        print(
                            '[CWO_INJECTION] button=Copy From Specific Day pressed date=${date.toIso8601String()}');
                        _copyFromSpecificDay(context, ref, date);
                      }),
                ]))));
  }

  Future<void> _showPlanDayPicker(
      BuildContext context, WidgetRef ref, DateTime date) async {
    print('[CWO_PLAN_DAY] START picker date=${date.toIso8601String()}');
    final db = ref.read(databaseProvider);
    final planDays = await OvarchPlanInjectionService.planDaysWithBlocks(db);
    print(
        '[CWO_PLAN_DAY] planDaysWithBlocks returned count=${planDays.length}');
    if (!context.mounted) {
      print('[CWO_PLAN_DAY] STOP context not mounted after planDaysWithBlocks');
      return;
    }

    if (planDays.isEmpty) {
      print('[CWO_PLAN_DAY] NO_PLAN_DAYS_WITH_WBS');
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('NO_PLAN_DAYS_WITH_WBS')));
      return;
    }

    final dayIdByLabel = <String, int>{};
    final values = planDays.map((d) {
      final planName = d['planName'] as String;
      final weekNumber = (d['weekNumber'] as num).toInt();
      final dayNumber = (d['dayNumber'] as num).toInt();
      final dayLabel = d['dayLabel'] as String?;
      final blockCount = (d['blockCount'] as num).toInt();
      final dayId = (d['dayId'] as num).toInt();
      final label = dayLabel?.isNotEmpty == true ? dayLabel! : 'DAY_$dayNumber';
      final value =
          '$planName / WEEK_${weekNumber.toString().padLeft(2, '0')} / $label // $blockCount WB';
      dayIdByLabel[value] = dayId;
      print(
          '[CWO_PLAN_DAY] picker option value="$value" mappedDayId=$dayId planId=${d['planId']} weekId=${d['weekId']}');
      return value;
    }).toList();

    print('[CWO_PLAN_DAY] opening QualitySearchPicker values=${values.length}');
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: LabColors.background,
      isScrollControlled: true,
      builder: (c) => QualitySearchPicker(
        title: 'SELECT_PLAN_DAY',
        values: values,
        onSelected: (value) => Navigator.pop(c, value),
      ),
    );
    if (picked == null) {
      print('[CWO_PLAN_DAY] picker returned null / user cancelled');
      return;
    }
    if (!context.mounted) {
      print(
          '[CWO_PLAN_DAY] STOP context not mounted after picker picked=$picked');
      return;
    }

    print('[CWO_PLAN_DAY] picked="$picked"');
    final dayId = dayIdByLabel[picked];
    if (dayId == null) {
      print(
          '[CWO_PLAN_DAY] INVALID_PLAN_DAY_SELECTION picked="$picked" mapSize=${dayIdByLabel.length}');
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('INVALID_PLAN_DAY_SELECTION')));
      return;
    }
    print('[CWO_PLAN_DAY] selected dayId=$dayId');

    final blocks = await (db.select(db.planDayBlocks)
          ..where((t) => t.dayId.equals(dayId))
          ..orderBy([
            (t) => drift.OrderingTerm.asc(t.orderIndex),
            (t) => drift.OrderingTerm.asc(t.id)
          ]))
        .get();
    print(
        '[CWO_PLAN_DAY] db.planDayBlocks query returned count=${blocks.length}');
    for (final b in blocks) {
      print(
          '[CWO_PLAN_DAY] planDayBlock id=${b.id} dayId=${b.dayId} blockId=${b.blockId} order=${b.orderIndex} notes=${b.notes}');
    }
    if (!context.mounted) {
      print(
          '[CWO_PLAN_DAY] STOP context not mounted after planDayBlocks query');
      return;
    }

    if (blocks.isEmpty) {
      print('[CWO_PLAN_DAY] DAY_HAS_NO_WBS dayId=$dayId');
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('DAY_HAS_NO_WBS')));
      return;
    }

    try {
      print(
          '[CWO_PLAN_DAY] calling injectPlanDay dayId=$dayId blocks=${blocks.length}');
      final result =
          await OvarchPlanInjectionService.injectPlanDay(db, date, blocks);
      if (context.mounted) {
        final injected = result['injected'] ?? 0;
        final skipped = result['skipped'] ?? 0;
        print(
            '[CWO_PLAN_DAY] injectPlanDay result injected=$injected skipped=$skipped');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text('PLAN_DAY_INJECTED: $injected WB / SKIPPED: $skipped')));
      } else {
        print('[CWO_PLAN_DAY] STOP context not mounted before snackbar');
      }
    } catch (e, stackTrace) {
      print('[CWO_PLAN_DAY] injectPlanDay threw error=$e');
      print(stackTrace);
      if (context.mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _copyFromSpecificDay(
      BuildContext context, WidgetRef ref, DateTime targetDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: targetDate.subtract(const Duration(days: 1)),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
              primary: LabColors.primary,
              onPrimary: Colors.black,
              surface: LabColors.background,
              onSurface: Colors.white),
          textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: LabColors.primary)),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      final db = ref.read(databaseProvider);
      final sourceStart = DateTime(picked.year, picked.month, picked.day);
      final sourceEnd =
          DateTime(picked.year, picked.month, picked.day, 23, 59, 59);

      final sourceSets = await (db.select(db.workoutSets).join([
        drift.innerJoin(
            db.workoutLogs, db.workoutLogs.id.equalsExp(db.workoutSets.logId))
      ])
            ..where(db.workoutLogs.date.isBetweenValues(sourceStart, sourceEnd))
            ..orderBy([
              drift.OrderingTerm.asc(db.workoutSets.orderIndex),
              drift.OrderingTerm.asc(db.workoutSets.timestamp)
            ]))
          .get();

      if (sourceSets.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("NO_DATA_FOUND_FOR_SELECTED_DATE")));
        return;
      }

      final targetStart =
          DateTime(targetDate.year, targetDate.month, targetDate.day);
      final targetEnd = DateTime(
          targetDate.year, targetDate.month, targetDate.day, 23, 59, 59);
      final logs = await (db.select(db.workoutLogs)
            ..where((t) => t.date.isBetweenValues(targetStart, targetEnd)))
          .get();
      int logId = logs.isEmpty
          ? await db
              .into(db.workoutLogs)
              .insert(WorkoutLogsCompanion.insert(date: targetDate))
          : logs.first.id;

      // Find current max orderIndex in target day
      final existingTargetSets = await (db.select(db.workoutSets).join([
        drift.innerJoin(
            db.workoutLogs, db.workoutLogs.id.equalsExp(db.workoutSets.logId))
      ])
            ..where(
                db.workoutLogs.date.isBetweenValues(targetStart, targetEnd)))
          .get();

      int currentMaxOrder = -1;
      for (var row in existingTargetSets) {
        final s = row.readTable(db.workoutSets);
        if (s.orderIndex > currentMaxOrder) currentMaxOrder = s.orderIndex;
      }

      await db.transaction(() async {
        int lastSourceOrder = -1;
        int targetOrderOffset = currentMaxOrder;

        for (var row in sourceSets) {
          final s = row.readTable(db.workoutSets);
          if (s.orderIndex != lastSourceOrder) {
            targetOrderOffset++;
            lastSourceOrder = s.orderIndex;
          }

          await db.into(db.workoutSets).insert(WorkoutSetsCompanion.insert(
                logId: logId,
                baseExerciseId: s.baseExerciseId,
                weight: s.weight,
                reps: s.reps,
                orderIndex: drift.Value(targetOrderOffset),
                priority: drift.Value(s.priority),
                complexMetadata: drift.Value(s.complexMetadata),
                timestamp: drift.Value(targetDate
                    .add(Duration(milliseconds: sourceSets.indexOf(row)))),
              ));
        }
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("SESSION_CLONED_SUCCESSFULLY")));
      }
    }
  }

  Future<void> _injectBlueprint(WidgetRef ref, DateTime d, Blueprint b) async {
    final db = ref.read(databaseProvider);
    try {
      final todayStart = DateTime(d.year, d.month, d.day);
      final todayEnd = DateTime(d.year, d.month, d.day, 23, 59, 59);

      final exs = await (db.select(db.blueprintExercises)
            ..where((t) => t.blueprintId.equals(b.id))
            ..orderBy([(t) => drift.OrderingTerm(expression: t.orderIndex)]))
          .get();
      if (exs.isEmpty) return;
      final logs = await (db.select(db.workoutLogs)
            ..where((t) => t.date.isBetweenValues(todayStart, todayEnd)))
          .get();
      int logId = logs.isEmpty
          ? await db
              .into(db.workoutLogs)
              .insert(WorkoutLogsCompanion.insert(date: d))
          : logs.first.id;

      // Find current max orderIndex
      final allSetsToday = await (db.select(db.workoutSets).join([
        drift.innerJoin(
            db.workoutLogs, db.workoutLogs.id.equalsExp(db.workoutSets.logId))
      ])
            ..where(db.workoutLogs.date.isBetweenValues(todayStart, todayEnd)))
          .get();

      int currentMaxOrder = -1;
      for (var row in allSetsToday) {
        final s = row.readTable(db.workoutSets);
        if (s.orderIndex > currentMaxOrder) currentMaxOrder = s.orderIndex;
      }

      for (var be in exs) {
        currentMaxOrder++;
        int sc = 1;
        if (be.targetSetsReps != null) {
          final pts = be.targetSetsReps!.toLowerCase().split('x');
          if (pts.isNotEmpty) sc = int.tryParse(pts[0].trim()) ?? 1;
        }

        // Find exercise to get default toggles
        final exerciseRows = await (db.select(db.baseExercises)
              ..where((t) => t.id.equals(be.baseExerciseId)))
            .get();
        String? initialMetadata;
        if (exerciseRows.isNotEmpty) {
          final Map<String, dynamic> exerciseMeta =
              exerciseRows.first.parsedComplexMetadata;
          final List<dynamic> rawToggles =
              exerciseMeta["particular_toggles"] ?? [];
          final Map<String, bool> defaultToggles = {};
          for (var t in rawToggles) {
            if (t is Map && t["default"] == true) {
              defaultToggles[t["name"] as String] = true;
            }
          }
          if (defaultToggles.isNotEmpty)
            initialMetadata = jsonEncode(defaultToggles);
        }

        for (int i = 0; i < sc; i++) {
          await db.into(db.workoutSets).insert(WorkoutSetsCompanion.insert(
              logId: logId,
              baseExerciseId: be.baseExerciseId,
              weight: 0,
              reps: 0,
              orderIndex: drift.Value(currentMaxOrder),
              priority: drift.Value(be.priority),
              complexMetadata: drift.Value(initialMetadata),
              supersetGroupId: drift.Value(be.supersetGroupId),
              supersetName: drift.Value(be.supersetName),
              timestamp: drift.Value(DateTime(
                      d.year,
                      d.month,
                      d.day,
                      DateTime.now().hour,
                      DateTime.now().minute,
                      DateTime.now().second)
                  .add(Duration(milliseconds: i)))));
        }
      }
    } catch (e) {
      debugPrint('$e');
    }
  }

  // ─── WORKOUT BLOCK INJECTION ─────────────────────────────────
  void _showWbPicker(WidgetRef ref, DateTime date) async {
    final db = ref.read(databaseProvider);
    // Read WB list from the store
    final wbRows =
        await db.customSelect('SELECT data FROM wb_store WHERE id = 1').get();
    if (wbRows.isEmpty) {
      if (context.mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('NO_WBS_CREATED')));
      return;
    }
    final raw = wbRows.first.data['data'] as String;
    final wbList = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    if (!context.mounted) return;

    // Build a picker from WB names
    final names = wbList.map((j) => j['name'] as String).toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: LabColors.background,
      isScrollControlled: true,
      builder: (c) => QualitySearchPicker(
        title: 'SELECT WORKOUT BLOCK',
        values: names,
        onSelected: (wbName) {
          debugPrint('[INJECT_WB] onSelected called: $wbName');
          final wbData = wbList.firstWhere((j) => j['name'] == wbName);
          debugPrint('[INJECT_WB] wbData found: id=${wbData['id']}');
          Navigator.pop(c);
          Future.microtask(() {
            if (!context.mounted) return;
            debugPrint('[INJECT_WB] calling _injectWorkoutBlock directly');
            _injectWorkoutBlock(ref, date, wbData,
                options: const _InjectOptions(usePload: false, allSets: true));
          });
        },
      ),
    );
  }

  Future<void> _showInjectConfig(BuildContext context, WidgetRef ref,
      DateTime date, Map<String, dynamic> wbData) async {
    bool usePload = false;
    bool allSets = true;
    final result = await showDialog<_InjectOptions>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setDState) => AlertDialog(
          backgroundColor: LabColors.background,
          title: Text('INJECT WB',
              style: LabStyles.mono(context,
                  fontSize: 14, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${wbData['name']}',
                  style: LabStyles.headline(context)
                      .copyWith(fontSize: 16, color: LabColors.primary)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[700]!, width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('LOAD OPTIONS',
                        style: LabStyles.mono(context,
                            fontSize: 10,
                            color: Colors.grey[400],
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => setDState(() => usePload = !usePload),
                      child: Row(
                        children: [
                          Icon(
                              usePload
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank,
                              color: LabColors.primary,
                              size: 20),
                          const SizedBox(width: 8),
                          Text('USE P.LOAD AS LOAD',
                              style: LabStyles.mono(context,
                                  fontSize: 10, color: Colors.white)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => setDState(() => allSets = !allSets),
                      child: Row(
                        children: [
                          Icon(
                              allSets
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank,
                              color: LabColors.primary,
                              size: 20),
                          const SizedBox(width: 8),
                          Text('INJECT ALL SETS',
                              style: LabStyles.mono(context,
                                  fontSize: 10, color: Colors.white)),
                        ],
                      ),
                    ),
                    if (!allSets)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 28),
                        child: Text('(SINGLE DEFAULT SET ONLY)',
                            style: LabStyles.mono(context,
                                fontSize: 8, color: Colors.grey[500])),
                      ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(c),
                child: Text('CANCEL',
                    style: LabStyles.mono(context, color: Colors.grey))),
            TextButton(
                onPressed: () => Navigator.pop(
                    c, _InjectOptions(usePload: usePload, allSets: allSets)),
                child: Text('INJECT',
                    style: LabStyles.mono(context, color: LabColors.primary))),
          ],
        ),
      ),
    );
    if (result != null && context.mounted) {
      _injectWorkoutBlock(ref, date, wbData, options: result);
    }
  }

  Future<void> _injectWorkoutBlock(
      WidgetRef ref, DateTime d, Map<String, dynamic> wbData,
      {_InjectOptions? options}) async {
    final usePload = options?.usePload ?? false;
    final allSets = options?.allSets ?? true;
    final db = ref.read(databaseProvider);
    debugPrint(
        '[INJECT] START block=${wbData['name']} usePload=$usePload allSets=$allSets');
    try {
      final todayStart = DateTime(d.year, d.month, d.day);
      final todayEnd = DateTime(d.year, d.month, d.day, 23, 59, 59);
      final logs = await (db.select(db.workoutLogs)
            ..where((t) => t.date.isBetweenValues(todayStart, todayEnd)))
          .get();
      int logId = logs.isEmpty
          ? await db
              .into(db.workoutLogs)
              .insert(WorkoutLogsCompanion.insert(date: d))
          : logs.first.id;
      debugPrint('[INJECT] logId=$logId logsFound=${logs.length}');

      // Find current max orderIndex
      final allSetsToday = await (db.select(db.workoutSets).join([
        drift.innerJoin(
            db.workoutLogs, db.workoutLogs.id.equalsExp(db.workoutSets.logId))
      ])
            ..where(db.workoutLogs.date.isBetweenValues(todayStart, todayEnd)))
          .get();
      int currentMaxOrder = -1;
      for (var row in allSetsToday) {
        final s = row.readTable(db.workoutSets);
        if (s.orderIndex > currentMaxOrder) currentMaxOrder = s.orderIndex;
      }
      debugPrint(
          '[INJECT] currentMaxOrder=$currentMaxOrder setsToday=${allSetsToday.length}');

      // WB data fields
      final String wbName = wbData['name'] ?? 'WB';
      final String? wbIntention = wbData['intention'];

      // Read KNS for this WB from real workout_block_kns table
      final blockId =
          int.tryParse(wbData['id'].toString().replaceAll('wb_', '')) ?? 0;
      debugPrint('[INJECT] blockId=$blockId');
      final knsRows = await db
          .customSelect(
              'SELECT id, base_exercise_id, order_index, utilities, batch_name FROM workout_block_kns WHERE block_id = $blockId ORDER BY order_index ASC')
          .get();
      debugPrint('[INJECT] knsRows=${knsRows.length}');
      if (knsRows.isEmpty) {
        debugPrint('[INJECT] NO KNS FOUND');
        if (context.mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('WB_HAS_NO_KNS')));
        return;
      }

      // Inject each KNS as an exercise
      for (final knsRow in knsRows) {
        final int baseExId = knsRow.data['base_exercise_id'] as int;
        final List<String> utilities = () {
          final raw = knsRow.data['utilities'] as String?;
          if (raw == null) return <String>[];
          try {
            return (jsonDecode(raw) as List).cast<String>();
          } catch (_) {
            return <String>[];
          }
        }();
        final String? batchName = knsRow.data['batch_name'] as String?;
        final knsId = knsRow.data['id'] as int;
        debugPrint(
            '[INJECT] KNS knsId=$knsId baseExId=$baseExId utilities=$utilities batch=$batchName');

        // Read sets from real workout_block_sets table
        final setRows = await db
            .customSelect(
                'SELECT id, set_number, reps_min, reps_max, pload, side FROM workout_block_sets WHERE kns_id = $knsId ORDER BY set_number ASC')
            .get();
        debugPrint('[INJECT] KNS setsRead=${setRows.length}');

        // Check if exercise is unilateral
        final ex = await (db.select(db.baseExercises)
              ..where((t) => t.id.equals(baseExId)))
            .getSingleOrNull();
        final bool isUnilateral = ex?.isUnilateral ?? false;
        debugPrint('[INJECT] isUnilateral=$isUnilateral exName=${ex?.name}');

        // Build base complexMetadata from utilities + batch
        final Map<String, dynamic> meta = {};
        if (utilities.isNotEmpty) meta['utilities'] = utilities;
        if (batchName != null && batchName.isNotEmpty)
          meta['batch'] = batchName;
        meta['injectedFromBlock'] = blockId; // Track which WB was injected

        // Determine which sets to inject
        final List<Map<String, dynamic>> setsToInject;
        if (setRows.isEmpty || !allSets) {
          setsToInject = [<String, dynamic>{}];
          debugPrint('[INJECT] setsToInject: 1 default (empty)');
        } else {
          setsToInject = setRows
              .map((sRow) => <String, dynamic>{
                    'pload': (sRow.data['pload'] as num?)?.toDouble(),
                    'maxReps': (sRow.data['reps_max'] as num?)?.toDouble(),
                    'side': sRow.data['side'] as String?,
                  })
              .toList();
          debugPrint('[INJECT] setsToInject: ${setsToInject.length} sets');
        }

        for (final rs in setsToInject) {
          final setData = rs as Map<String, dynamic>;
          final pload = setData['pload'];
          final maxReps = setData['maxReps'];
          final setSide = setData['side'] as String?;

          final double weight = usePload && pload != null
              ? (pload is num
                  ? pload.toDouble()
                  : double.tryParse(pload.toString()) ?? 0)
              : 0;
          final double reps = maxReps != null
              ? (maxReps is num
                  ? maxReps.toDouble()
                  : double.tryParse(maxReps.toString()) ?? 0)
              : 0;
          debugPrint(
              '[INJECT] SET pload=$pload maxReps=$maxReps side=$setSide weight=$weight reps=$reps isUni=$isUnilateral');

          if (isUnilateral) {
            // Create RIGHT + LEFT pair
            for (final side in ['RIGHT', 'LEFT']) {
              currentMaxOrder++;
              final setMeta = Map<String, dynamic>.from(meta);
              setMeta['side'] = side;
              await db.into(db.workoutSets).insert(WorkoutSetsCompanion.insert(
                    logId: logId,
                    baseExerciseId: baseExId,
                    weight: weight,
                    reps: reps,
                    orderIndex: drift.Value(currentMaxOrder),
                    priority: drift.Value(
                        utilities.isNotEmpty ? utilities.first : null),
                    complexMetadata: drift.Value(jsonEncode(setMeta)),
                    timestamp: drift.Value(DateTime(
                            d.year,
                            d.month,
                            d.day,
                            DateTime.now().hour,
                            DateTime.now().minute,
                            DateTime.now().second)
                        .add(Duration(milliseconds: currentMaxOrder))),
                  ));
            }
          } else {
            // Single set
            currentMaxOrder++;
            final setMeta = Map<String, dynamic>.from(meta);
            if (setSide != null) setMeta['side'] = setSide;
            await db.into(db.workoutSets).insert(WorkoutSetsCompanion.insert(
                  logId: logId,
                  baseExerciseId: baseExId,
                  weight: weight,
                  reps: reps,
                  orderIndex: drift.Value(currentMaxOrder),
                  priority: drift.Value(
                      utilities.isNotEmpty ? utilities.first : null),
                  complexMetadata: drift.Value(
                      setMeta.isNotEmpty ? jsonEncode(setMeta) : null),
                  timestamp: drift.Value(DateTime(
                          d.year,
                          d.month,
                          d.day,
                          DateTime.now().hour,
                          DateTime.now().minute,
                          DateTime.now().second)
                      .add(Duration(milliseconds: currentMaxOrder))),
                ));
          }
        }
      }
      if (context.mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('INJECTED: $wbName')));
    } catch (e) {
      debugPrint('[INJECT_WB] $e');
    }
  }

  Future<void> _addExerciseToDate(
      WidgetRef ref, DateTime d, BaseExercise e) async {
    final db = ref.read(databaseProvider);
    try {
      final todayStart = DateTime(d.year, d.month, d.day);
      final todayEnd = DateTime(d.year, d.month, d.day, 23, 59, 59);

      final logs = await (db.select(db.workoutLogs)
            ..where((t) => t.date.isBetweenValues(todayStart, todayEnd)))
          .get();
      int logId = logs.isEmpty
          ? await db
              .into(db.workoutLogs)
              .insert(WorkoutLogsCompanion.insert(date: d))
          : logs.first.id;

      // Find max orderIndex for today
      final allSetsToday = await (db.select(db.workoutSets).join([
        drift.innerJoin(
            db.workoutLogs, db.workoutLogs.id.equalsExp(db.workoutSets.logId))
      ])
            ..where(db.workoutLogs.date.isBetweenValues(todayStart, todayEnd)))
          .get();

      int maxOrder = -1;
      for (var row in allSetsToday) {
        final s = row.readTable(db.workoutSets);
        if (s.orderIndex > maxOrder) maxOrder = s.orderIndex;
      }
      final nextOrder = maxOrder + 1;

      // Initialize complexMetadata with default toggles
      final Map<String, dynamic> exerciseMeta = e.parsedComplexMetadata;
      final List<dynamic> rawToggles = exerciseMeta["particular_toggles"] ?? [];
      final Map<String, bool> defaultToggles = {};
      for (var t in rawToggles) {
        if (t is Map && t["default"] == true) {
          defaultToggles[t["name"] as String] = true;
        }
      }
      final String? initialMetadata =
          defaultToggles.isEmpty ? null : jsonEncode(defaultToggles);

      // PNDEV 40: Skip generic set for unilateral — insert paired RIGHT/LEFT instead
      if (e.isUnilateral) {
        final rightMeta = <String, dynamic>{};
        if (initialMetadata != null) {
          try {
            rightMeta
                .addAll(jsonDecode(initialMetadata) as Map<String, dynamic>);
          } catch (_) {}
        }
        rightMeta["side"] = "RIGHT";
        await db.into(db.workoutSets).insert(WorkoutSetsCompanion.insert(
              logId: logId,
              baseExerciseId: e.id,
              weight: 0,
              reps: 0,
              orderIndex: drift.Value(nextOrder),
              complexMetadata: drift.Value(jsonEncode(rightMeta)),
              timestamp: drift.Value(DateTime(
                  d.year,
                  d.month,
                  d.day,
                  DateTime.now().hour,
                  DateTime.now().minute,
                  DateTime.now().second)),
            ));

        final leftMeta = <String, dynamic>{};
        if (initialMetadata != null) {
          try {
            leftMeta
                .addAll(jsonDecode(initialMetadata) as Map<String, dynamic>);
          } catch (_) {}
        }
        leftMeta["side"] = "LEFT";
        await db.into(db.workoutSets).insert(WorkoutSetsCompanion.insert(
              logId: logId,
              baseExerciseId: e.id,
              weight: 0,
              reps: 0,
              orderIndex: drift.Value(nextOrder),
              complexMetadata: drift.Value(jsonEncode(leftMeta)),
              timestamp: drift.Value(DateTime(
                      d.year,
                      d.month,
                      d.day,
                      DateTime.now().hour,
                      DateTime.now().minute,
                      DateTime.now().second)
                  .add(const Duration(milliseconds: 1))),
            ));
      } else {
        await db.into(db.workoutSets).insert(WorkoutSetsCompanion.insert(
            logId: logId,
            baseExerciseId: e.id,
            weight: 0,
            reps: 0,
            orderIndex: drift.Value(nextOrder),
            complexMetadata: drift.Value(initialMetadata),
            timestamp: drift.Value(DateTime(
                d.year,
                d.month,
                d.day,
                DateTime.now().hour,
                DateTime.now().minute,
                DateTime.now().second))));
      }
    } catch (e) {
      debugPrint('$e');
    }
  }

  void _deleteAllSets(
      BuildContext context, WidgetRef ref, List<drift.TypedResult> results) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: LabColors.background,
        title: Text('CRITICAL_PURGE',
            style: LabStyles.mono(context,
                color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: Text('DELETE ALL LOGGED SETS FOR THIS SESSION?',
            style: LabStyles.mono(context, fontSize: 12)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c),
              child: Text('ABORT', style: LabStyles.mono(context))),
          TextButton(
            onPressed: () async {
              final db = ref.read(databaseProvider);
              final ids =
                  results.map((r) => r.readTable(db.workoutSets).id).toList();
              await (db.delete(db.workoutSets)..where((t) => t.id.isIn(ids)))
                  .go();
              if (context.mounted) Navigator.pop(c);
            },
            child: Text('PURGE_ALL',
                style: LabStyles.mono(context, color: Colors.redAccent)),
          )
        ],
      ),
    );
  }

  void _createBlueprintFromCurrentDay(BuildContext context, WidgetRef ref,
      List<drift.TypedResult> results) async {
    final nameC = TextEditingController();
    final db = ref.read(databaseProvider);

    final Map<int, int> exerciseSetCounts = {};
    final List<int> exerciseOrder = [];

    for (var row in results) {
      final exId = row.readTable(db.baseExercises).id;
      if (!exerciseSetCounts.containsKey(exId)) {
        exerciseSetCounts[exId] = 0;
        exerciseOrder.add(exId);
      }
      exerciseSetCounts[exId] = exerciseSetCounts[exId]! + 1;
    }

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          backgroundColor: LabColors.background,
          title: Text('GENERATE_BLUEPRINT',
              style: LabStyles.headline(context).copyWith(fontSize: 16)),
          content: LabTextField(
              controller: nameC,
              label: 'BLUEPRINT_NAME',
              placeholder: 'NAME_YOUR_TEMPLATE...'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(c),
                child: Text('ABORT', style: LabStyles.mono(context))),
            TextButton(
              onPressed: () async {
                if (nameC.text.isEmpty) return;
                final bpId = await db
                    .into(db.blueprints)
                    .insert(BlueprintsCompanion.insert(
                      name: nameC.text.toUpperCase(),
                      intention: "GENERATED_FROM_SESSION",
                    ));
                for (int i = 0; i < exerciseOrder.length; i++) {
                  final exId = exerciseOrder[i];
                  await db
                      .into(db.blueprintExercises)
                      .insert(BlueprintExercisesCompanion.insert(
                        blueprintId: bpId,
                        baseExerciseId: exId,
                        targetSetsReps:
                            drift.Value("${exerciseSetCounts[exId]} SETS"),
                        orderIndex: i,
                      ));
                }
                if (context.mounted) {
                  Navigator.pop(c);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('BLUEPRINT_CREATED_SUCCESSFULLY')));
                }
              },
              child: Text('GENERATE',
                  style: LabStyles.mono(context, color: LabColors.accent)),
            )
          ],
        ),
      );
    }
  }
}

class _GeneralNotesModule extends ConsumerStatefulWidget {
  final WorkoutLog log;
  const _GeneralNotesModule({super.key, required this.log});
  @override
  ConsumerState<_GeneralNotesModule> createState() =>
      _GeneralNotesModuleState();
}

class _GeneralNotesModuleState extends ConsumerState<_GeneralNotesModule> {
  // Notes are stored as a list; serialized to DB with a delimiter
  static const _noteSeparator = '||NOTE||';
  List<TextEditingController> _controllers = [];
  List<Timer?> _debounceTimers = [];
  bool _isExpanded = false;

  String _getSleepHeader() {
    final sleepMatch =
        RegExp(r'\[S:[\d.]+\]').firstMatch(widget.log.notes ?? '');
    return sleepMatch != null ? '${sleepMatch.group(0)} ' : '';
  }

  List<String> _parseNotes(String raw) {
    // Strip sleep header
    final clean = raw.replaceAll(RegExp(r'\[S:[\d.]+\]\s*'), '').trim();
    if (clean.isEmpty) return [];
    return clean
        .split(_noteSeparator)
        .map((n) => n.trim())
        .where((n) => n.isNotEmpty)
        .toList();
  }

  Future<void> _persistNotes() async {
    final texts = _controllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    final joined = texts.join(_noteSeparator);
    final db = ref.read(databaseProvider);
    await (db.update(db.workoutLogs)..where((t) => t.id.equals(widget.log.id)))
        .write(
      WorkoutLogsCompanion(notes: drift.Value(_getSleepHeader() + joined)),
    );
  }

  void _scheduleDebounce(int index) {
    _debounceTimers[index]?.cancel();
    _debounceTimers[index] =
        Timer(const Duration(milliseconds: 500), _persistNotes);
  }

  void _addNote() {
    setState(() {
      _controllers.add(TextEditingController());
      _debounceTimers.add(null);
    });
  }

  void _deleteNote(int index) {
    _debounceTimers[index]?.cancel();
    _controllers[index].dispose();
    setState(() {
      _controllers.removeAt(index);
      _debounceTimers.removeAt(index);
    });
    _persistNotes();
  }

  @override
  void initState() {
    super.initState();
    final notes = _parseNotes(widget.log.notes ?? '');
    _controllers = <TextEditingController>[
      ...notes.map((n) => TextEditingController(text: n))
    ];
    _debounceTimers = <Timer?>[
      for (var i = 0; i < _controllers.length; i++) null
    ];
  }

  @override
  void dispose() {
    for (var t in _debounceTimers) {
      t?.cancel();
    }
    for (var c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 24),
      decoration: LabStyles.hairlineBorder(color: LabColors.primary),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row (tappable) ──
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
              color: LabColors.primary.withOpacity(0.06),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: LabColors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'SESSION_GENERAL_NOTES',
                        style: LabStyles.mono(context,
                            color: LabColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: _addNote,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: LabColors.primary, width: 0.5),
                        color: LabColors.primary.withOpacity(0.08),
                      ),
                      child: Text(
                        '+ ADD.NOTE',
                        style: LabStyles.mono(context,
                            color: LabColors.primary,
                            fontSize: 9,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_isExpanded) ...[
            // ── Empty state ──
            if (_controllers.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  'NO_NOTES // TAP + ADD.NOTE',
                  style: LabStyles.mono(context,
                      fontSize: 10, color: Colors.grey[700]),
                ),
              ),

            // ── Note blocks ──
            ...List.generate(_controllers.length, (i) {
              return Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[850]!, width: 0.5),
                  color: Colors.white.withOpacity(0.03),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Index tag
                    Container(
                      width: 28,
                      color: LabColors.primary.withOpacity(0.12),
                      alignment: Alignment.topCenter,
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        '${i + 1}',
                        style: LabStyles.mono(context,
                            fontSize: 10,
                            color: LabColors.primary,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    // Text input
                    Expanded(
                      child: TextField(
                        controller: _controllers[i],
                        maxLines: null,
                        style: LabStyles.mono(context, fontSize: 12),
                        decoration: InputDecoration(
                          hintText: 'NOTE_${i + 1}...',
                          hintStyle: LabStyles.mono(context,
                              fontSize: 10, color: Colors.grey[700]),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.fromLTRB(10, 10, 4, 10),
                        ),
                        onChanged: (_) => _scheduleDebounce(i),
                      ),
                    ),
                    // Delete button
                    IconButton(
                      icon: const Icon(Icons.close, size: 14),
                      color: Colors.grey[700],
                      splashRadius: 14,
                      onPressed: () => _deleteNote(i),
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}

class _BlueprintSearchPicker extends ConsumerStatefulWidget {
  final List<Blueprint> blueprints;
  final Function(Blueprint) onSelected;
  const _BlueprintSearchPicker(
      {required this.blueprints, required this.onSelected});
  @override
  ConsumerState<_BlueprintSearchPicker> createState() =>
      _BlueprintSearchPickerState();
}

class _BlueprintSearchPickerState
    extends ConsumerState<_BlueprintSearchPicker> {
  late List<Blueprint> flt;
  final TextEditingController sC = TextEditingController();
  final Map<int, String> sums = {};
  @override
  void initState() {
    super.initState();
    flt = widget.blueprints;
    sC.addListener(() {
      setState(() {
        flt = widget.blueprints
            .where((b) => b.name.toLowerCase().contains(sC.text.toLowerCase()))
            .toList();
      });
    });
    Future.microtask(() => _ld());
  }

  Future<void> _ld() async {
    final db = ref.read(databaseProvider);
    for (var b in widget.blueprints) {
      final rows = await (db.select(db.blueprintExercises).join([
        drift.innerJoin(db.baseExercises,
            db.baseExercises.id.equalsExp(db.blueprintExercises.baseExerciseId))
      ])
            ..where(db.blueprintExercises.blueprintId.equals(b.id)))
          .get();
      final n = rows.map((r) {
        final e = r.readTable(db.baseExercises);
        return e.fullName;
      }).join(' • ');
      if (mounted)
        setState(() {
          sums[b.id] = n.isEmpty ? 'EMPTY' : n;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          children: [
            Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                    color: LabColors.surfaceContainerHigh,
                    border: Border(
                        bottom:
                            BorderSide(color: LabColors.primary, width: 2))),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('SELECT_BLUEPRINT',
                            style: LabStyles.headline(context)
                                .copyWith(fontSize: 18)),
                        IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close, color: Colors.white))
                      ]),
                  const SizedBox(height: 16),
                  LabTextField(controller: sC, label: 'Search...')
                ])),
            Expanded(
                child: ListView.builder(
                    itemCount: flt.length,
                    itemBuilder: (c, i) => LabListTile(
                        title: flt[i].name.toUpperCase(),
                        subtitle: sums[flt[i].id] ?? 'LOADING...',
                        onTap: () {
                          widget.onSelected(flt[i]);
                          Navigator.pop(context);
                        })))
          ],
        ));
  }
}

class ExerciseSearchPicker extends ConsumerStatefulWidget {
  final List<BaseExercise> exercises;
  final Function(BaseExercise) onSelected;
  const ExerciseSearchPicker(
      {required this.exercises, required this.onSelected});
  @override
  ConsumerState<ExerciseSearchPicker> createState() =>
      _ExerciseSearchPickerState();
}

enum _ExerciseSortMode {
  alpha,
  reverseAlpha,
  newestFirst,
  oldestFirst,
  mostUsed,
  leastUsed
}

class _ExerciseSearchPickerState extends ConsumerState<ExerciseSearchPicker> {
  late List<BaseExercise> _all;
  late List<BaseExercise> _filtered;
  final TextEditingController _searchC = TextEditingController();
  _ExerciseSortMode _sortMode = _ExerciseSortMode.alpha;

  // Filter state
  String? _fLoad;
  bool? _fIso; // replaced _fClass (C/I) with isometric toggle
  bool? _fUni;
  String? _fBase;
  String? _fMuscle;
  String? _fImpl;

  // Unique values for filter sheets
  late Set<String> _loadValues;
  late Set<String> _baseValues;
  late Set<String> _muscleValues;
  late Set<String> _implValues;

  String get _sortLabel {
    switch (_sortMode) {
      case _ExerciseSortMode.alpha:
        return 'A-Z';
      case _ExerciseSortMode.reverseAlpha:
        return 'Z-A';
      case _ExerciseSortMode.newestFirst:
        return 'NEW';
      case _ExerciseSortMode.oldestFirst:
        return 'OLD';
      case _ExerciseSortMode.mostUsed:
        return 'MST';
      case _ExerciseSortMode.leastUsed:
        return 'LST';
    }
  }

  // Controllers for BASE and MUSCLE text-input filters
  final TextEditingController _baseC = TextEditingController();
  final TextEditingController _muscleC = TextEditingController();

  bool get _hasActiveFilters =>
      _fLoad != null ||
      _fIso != null ||
      _fUni != null ||
      _fBase != null ||
      _fMuscle != null ||
      _fImpl != null;

  @override
  void initState() {
    super.initState();
    _all = widget.exercises;
    _filtered = _all;
    _searchC.addListener(_applyFilters);
    _baseC.addListener(_onBaseChanged);
    _muscleC.addListener(_onMuscleChanged);
    _extractFilterValues();
  }

  void _onBaseChanged() {
    final q = _baseC.text.toLowerCase();
    if (q.isEmpty) {
      if (_fBase != null) {
        setState(() => _fBase = null);
        _applyFilters();
      }
      return;
    }
    final match = _baseValues.firstWhere(
      (v) => v.toLowerCase() == q,
      orElse: () => '',
    );
    if (match.isNotEmpty && _fBase != match) {
      setState(() => _fBase = match);
      _applyFilters();
    }
  }

  void _onMuscleChanged() {
    final q = _muscleC.text.toLowerCase();
    if (q.isEmpty) {
      if (_fMuscle != null) {
        setState(() => _fMuscle = null);
        _applyFilters();
      }
      return;
    }
    final match = _muscleValues.firstWhere(
      (v) => v.toLowerCase() == q,
      orElse: () => '',
    );
    if (match.isNotEmpty && _fMuscle != match) {
      setState(() => _fMuscle = match);
      _applyFilters();
    }
  }

  void _extractFilterValues() {
    _loadValues = {};
    _baseValues = {};
    _muscleValues = {};
    _implValues = {};
    for (final e in _all) {
      final intent = e.intention ?? '';
      final m = RegExp(r'\[NT:(.*?)\|ISO:(.*?)\]').firstMatch(intent);
      if (m != null) {
        _loadValues.add(m.group(1) ?? '');
      } else if (['LASTRE', 'EXT.LOAD', 'JST.BW'].contains(e.field)) {
        if (e.field != null) _loadValues.add(e.field!);
      }
      if (e.name.isNotEmpty) _baseValues.add(e.name);
      if (e.primaryMuscleGroup != null && e.primaryMuscleGroup!.isNotEmpty) {
        _muscleValues.add(e.primaryMuscleGroup!);
      }
      if (e.secondaryMuscleGroup != null &&
          e.secondaryMuscleGroup!.isNotEmpty) {
        _muscleValues.add(e.secondaryMuscleGroup!);
      }
      if (e.implements != null && e.implements!.isNotEmpty)
        _implValues.add(e.implements!);
    }
  }

  // ── Isometric detection ──
  bool _isIsometric(BaseExercise e) {
    final intent = e.intention ?? '';
    // Check [NT:...|ISO:true] pattern
    final m = RegExp(r'\[NT:(.*?)\|ISO:(.*?)\]').firstMatch(intent);
    if (m != null) return m.group(2) == 'true';
    // Check if intention starts with [ISO]
    if (intent.startsWith('[ISO]')) return true;
    // Check complexMetadata for isometric flag
    final meta = e.parsedComplexMetadata;
    if (meta['isIsometric'] == true) return true;
    return false;
  }

  void _applyFilters() {
    final q = _searchC.text.toLowerCase();
    setState(() {
      _filtered = _all.where((e) {
        // 1. Text search across ALL fields
        if (q.isNotEmpty) {
          final sb = StringBuffer()
            ..write(e.fullName.toLowerCase())
            ..write(' ')
            ..write(e.name.toLowerCase())
            ..write(' ')
            ..write((e.prefixes ?? '').toLowerCase())
            ..write(' ')
            ..write((e.suffixes ?? '').toLowerCase())
            ..write(' ')
            ..write((e.implements ?? '').toLowerCase())
            ..write(' ')
            ..write((e.bodyPositions ?? '').toLowerCase())
            ..write(' ')
            ..write((e.intention ?? '').toLowerCase())
            ..write(' ')
            ..write((e.patternType ?? '').toLowerCase())
            ..write(' ')
            ..write((e.tissueType ?? '').toLowerCase())
            ..write(' ')
            ..write((e.tissueName ?? '').toLowerCase())
            ..write(' ')
            ..write((e.primaryMuscleGroup ?? '').toLowerCase())
            ..write(' ')
            ..write((e.secondaryMuscleGroup ?? '').toLowerCase())
            ..write(' ')
            ..write((e.field ?? '').toLowerCase());
          if (!sb.toString().contains(q)) return false;
        }
        // 2. Load type filter
        if (_fLoad != null) {
          final intent = e.intention ?? '';
          final m = RegExp(r'\[NT:(.*?)\|ISO:(.*?)\]').firstMatch(intent);
          final lt = m != null ? (m.group(1) ?? '') : (e.field ?? '');
          if (lt != _fLoad) return false;
        }
        // 3. Isometric filter (replaces C/I)
        if (_fIso != null) {
          if (_isIsometric(e) != _fIso) return false;
        }
        // 4. Unilateral filter
        if (_fUni != null) {
          if (e.isUnilateral != _fUni) return false;
        }
        // 5. Base name filter (text input)
        if (_fBase != null) {
          if (e.name != _fBase) return false;
        }
        // 6. Muscle filter (text input)
        if (_fMuscle != null) {
          if (e.primaryMuscleGroup != _fMuscle &&
              e.secondaryMuscleGroup != _fMuscle) return false;
        }
        // 7. Implement filter
        if (_fImpl != null) {
          if ((e.implements ?? '') != _fImpl) return false;
        }
        return true;
      }).toList();
      // Apply sort mode
      switch (_sortMode) {
        case _ExerciseSortMode.alpha:
          _filtered.sort((a, b) => a.name.compareTo(b.name));
          break;
        case _ExerciseSortMode.reverseAlpha:
          _filtered.sort((a, b) => b.name.compareTo(a.name));
          break;
        case _ExerciseSortMode.newestFirst:
          _filtered.sort((a, b) => b.id.compareTo(a.id));
          break;
        case _ExerciseSortMode.oldestFirst:
          _filtered.sort((a, b) => a.id.compareTo(b.id));
          break;
        case _ExerciseSortMode.mostUsed:
          _filtered.sort((a, b) => b.id.compareTo(a.id));
          break;
        case _ExerciseSortMode.leastUsed:
          _filtered.sort((a, b) => a.id.compareTo(b.id));
          break;
      }
    });
  }

  String _loadTypeOf(BaseExercise e) {
    final m = RegExp(r'\[NT:(.*?)\|ISO:(.*?)\]').firstMatch(e.intention ?? '');
    if (m != null) return m.group(1) ?? 'EXT.LOAD';
    if (['LASTRE', 'EXT.LOAD', 'JST.BW'].contains(e.field)) return e.field!;
    return 'EXT.LOAD';
  }

  String? _classOf(BaseExercise e) => e.parsedComplexMetadata['classification'];

  String _buildSubtitle(BaseExercise e) {
    final lt = _loadTypeOf(e);
    final cls = _classOf(e);
    final parts = <String>[];
    if (e.primaryMuscleGroup != null && e.primaryMuscleGroup!.isNotEmpty) {
      parts.add(e.primaryMuscleGroup!.toUpperCase());
    }
    parts.add('[$lt]');
    if (cls != null && cls.isNotEmpty) parts.add(cls);
    if (e.isUnilateral) parts.add('[UNI]');
    if (e.field != null && e.field!.isNotEmpty)
      parts.add(e.field!.toUpperCase());
    return parts.join('  •  ');
  }

  // ── Theme-aware color helpers ──
  Color _themeColor(String key, String nameSeed) {
    final settings = ref.watch(themeSettingsProvider).value ?? {};
    return ref
        .read(themeControllerProvider)
        .getColor(settings, key, nameSeed: nameSeed);
  }

  Color _filterChipColor(String tag, String? activeValue) {
    // Each filter chip gets its color from UI_TAG_ theme keys
    return _themeColor('UI_TAG_${tag.toUpperCase()}', tag);
  }

  Color _baseColor(String baseName) {
    // Looks up MOVEMENT_$baseName from THEME.MDYFR
    return _themeColor('MOVEMENT_$baseName', baseName);
  }

  Color _muscleColor(String muscleName) {
    // Looks up MUSCLE_$muscleName from THEME.MDYFR
    return _themeColor('MUSCLE_$muscleName', muscleName);
  }

  void _showFilterSheet(String title, Set<String> values, String? current,
      ValueChanged<String?> onSelect) {
    final sorted = values.toList()..sort();
    showModalBottomSheet(
      context: context,
      backgroundColor: LabColors.background,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(title,
                style: LabStyles.headline(ctx).copyWith(fontSize: 14)),
          ),
          const Divider(
              height: 0.5, color: LabColors.cyanBorder, thickness: 0.2),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                ListTile(
                  title: Text('CLEAR',
                      style: LabStyles.mono(ctx,
                          fontSize: 11, color: Colors.redAccent)),
                  onTap: () {
                    onSelect(null);
                    Navigator.pop(ctx);
                  },
                ),
                ...sorted.map((v) => ListTile(
                      title: Text(v,
                          style: LabStyles.mono(ctx,
                              fontSize: 11,
                              color: current == v ? LabColors.primary : null)),
                      trailing: current == v
                          ? const Icon(Icons.check,
                              color: LabColors.primary, size: 14)
                          : null,
                      onTap: () {
                        onSelect(v);
                        Navigator.pop(ctx);
                      },
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _clearAllFilters() {
    setState(() {
      _fLoad = null;
      _fIso = null;
      _fUni = null;
      _fBase = null;
      _fMuscle = null;
      _fImpl = null;
      _baseC.clear();
      _muscleC.clear();
    });
    _applyFilters();
  }

  // ── Filter chip widget (theme-colored, white text) ──
  Widget _filterChip(String label, String? value, VoidCallback onTap) {
    final isActive = value != null;
    final themeColor = _filterChipColor(label, value);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        margin: const EdgeInsets.only(right: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive
              ? themeColor.withValues(alpha: 0.15)
              : Colors.transparent,
          border: Border.all(
            color: isActive
                ? themeColor
                : LabColors.cyanBorder.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Text(
          isActive
              ? '$label:${value!.toUpperCase()}'
              : '${label.toUpperCase()}:ALL',
          textAlign: TextAlign.center,
          style: LabStyles.mono(context, fontSize: 8, color: Colors.white),
        ),
      ),
    );
  }

  Widget _triStateChip({
    required String label,
    required bool? value,
    required ValueChanged<bool?> onTap,
  }) {
    String text;
    final yesColor = _filterChipColor(label, 'YES');
    if (value == null) {
      text = '${label.toUpperCase()}:ALL';
    } else if (value == true) {
      text = '${label.toUpperCase()}:YES';
    } else {
      text = '${label.toUpperCase()}:NO';
    }
    return GestureDetector(
      onTap: () {
        if (value == null) {
          onTap(true);
        } else if (value == true) {
          onTap(false);
        } else {
          onTap(null);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        margin: const EdgeInsets.only(right: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: value != null
              ? yesColor.withValues(alpha: 0.15)
              : Colors.transparent,
          border: Border.all(
            color: value != null
                ? yesColor
                : LabColors.cyanBorder.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Text(text,
            textAlign: TextAlign.center,
            style: LabStyles.mono(context, fontSize: 8, color: Colors.white)),
      ),
    );
  }

  // ── Text-input filter field (BASE / MUSCLE) ──
  Widget _textFilterField({
    required String label,
    required TextEditingController controller,
    required Set<String> suggestions,
    required String? currentValue,
    required Color activeColor,
    required VoidCallback onClear,
  }) {
    final isActive = currentValue != null;
    // Autocomplete options
    final options = suggestions
        .where((s) => s.toLowerCase().contains(controller.text.toLowerCase()))
        .toList()
      ..sort();

    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        child: Autocomplete<String>(
          optionsBuilder: (TextEditingValue tev) {
            if (tev.text.isEmpty) return suggestions.toList()..sort();
            return suggestions
                .where((s) => s.toLowerCase().contains(tev.text.toLowerCase()))
                .toList()
              ..sort();
          },
          displayStringForOption: (o) => o,
          onSelected: (selection) {
            controller.text = selection;
          },
          fieldViewBuilder: (ctx, tc, fn, onSubmitted) {
            // Keep our controller in sync
            if (controller.text != tc.text && !tc.selection.isValid) {
              tc.text = controller.text;
            }
            return Container(
              height: 36,
              decoration: BoxDecoration(
                color: isActive
                    ? activeColor.withValues(alpha: 0.08)
                    : LabColors.surfaceDim,
                border: Border.all(
                  color: isActive
                      ? activeColor
                      : LabColors.cyanBorder.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: tc,
                      focusNode: fn,
                      style: LabStyles.mono(context,
                          fontSize: 9, color: Colors.white),
                      decoration: InputDecoration(
                        hintText: label.toUpperCase(),
                        hintStyle: LabStyles.mono(context,
                            fontSize: 9, color: Colors.grey[700]),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  if (isActive)
                    GestureDetector(
                      onTap: () {
                        tc.clear();
                        controller.clear();
                        onClear();
                      },
                      child: const Icon(Icons.close,
                          color: Colors.redAccent, size: 14),
                    ),
                ],
              ),
            );
          },
          optionsViewBuilder: (ctx, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                color: LabColors.surfaceContainerHigh,
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxHeight: 180, maxWidth: 300),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (_, i) {
                      final opt = options.elementAt(i);
                      return ListTile(
                        dense: true,
                        title: Text(opt,
                            style: LabStyles.mono(ctx,
                                fontSize: 10, color: Colors.white)),
                        onTap: () => onSelected(opt),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    // Active colors for BASE/MUSCLE text fields
    final activeBaseColor =
        _fBase != null ? _baseColor(_fBase!) : LabColors.primary;
    final activeMuscleColor =
        _fMuscle != null ? _muscleColor(_fMuscle!) : LabColors.primary;

    return Container(
      height: h * 0.92,
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        children: [
          // ── Header ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: LabColors.surfaceContainerHigh,
              border: Border(
                  bottom: BorderSide(color: LabColors.primary, width: 2)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('INJECT_MOVEMENT',
                        style:
                            LabStyles.headline(context).copyWith(fontSize: 18)),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Search bar + sort button
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: SizedBox(
                        height: 36,
                        child: TextField(
                          controller: _searchC,
                          style: LabStyles.mono(context,
                              fontSize: 12, color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'SEARCH...',
                            hintStyle: TextStyle(
                                color: Colors.grey[600], fontSize: 11),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Colors.grey[800]!, width: 0.5)),
                            enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Colors.grey[800]!, width: 0.5)),
                            focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: LabColors.primary, width: 0.5)),
                            fillColor: LabColors.surfaceDim,
                            filled: true,
                            isDense: true,
                          ),
                          onChanged: (_) => _applyFilters(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      height: 36,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(0)),
                          side: BorderSide(color: Colors.white24, width: 0.5),
                        ),
                        onPressed: () {
                          setState(() {
                            _sortMode = _ExerciseSortMode.values[
                                (_sortMode.index + 1) %
                                    _ExerciseSortMode.values.length];
                            _applyFilters();
                          });
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.sort, size: 14, color: Colors.grey[400]),
                            const SizedBox(width: 4),
                            Text(
                              _sortLabel,
                              style: LabStyles.mono(context,
                                  fontSize: 9, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Filter row: LOAD, ISO, UNI, IMPL
                Row(
                  children: [
                    Expanded(
                        child: _filterChip('LOAD', _fLoad, () {
                      _showFilterSheet(
                          'FILTER BY LOAD TYPE', _loadValues, _fLoad, (v) {
                        setState(() => _fLoad = v);
                        _applyFilters();
                      });
                    })),
                    Expanded(
                        child: _triStateChip(
                      label: 'ISO',
                      value: _fIso,
                      onTap: (v) {
                        setState(() => _fIso = v);
                        _applyFilters();
                      },
                    )),
                    Expanded(
                        child: _triStateChip(
                      label: 'UNI',
                      value: _fUni,
                      onTap: (v) {
                        setState(() => _fUni = v);
                        _applyFilters();
                      },
                    )),
                    Expanded(
                        child: _filterChip('IMPL', _fImpl, () {
                      _showFilterSheet('FILTER BY IMPL', _implValues, _fImpl,
                          (v) {
                        setState(() => _fImpl = v);
                        _applyFilters();
                      });
                    })),
                  ],
                ),
                const SizedBox(height: 8),
                // Row 2: BASE and MUSCLE as wide text-input fields
                Row(
                  children: [
                    _textFilterField(
                      label: 'BASE',
                      controller: _baseC,
                      suggestions: _baseValues,
                      currentValue: _fBase,
                      activeColor: activeBaseColor,
                      onClear: () {
                        setState(() => _fBase = null);
                        _applyFilters();
                      },
                    ),
                    _textFilterField(
                      label: 'MUSCLE',
                      controller: _muscleC,
                      suggestions: _muscleValues,
                      currentValue: _fMuscle,
                      activeColor: activeMuscleColor,
                      onClear: () {
                        setState(() => _fMuscle = null);
                        _applyFilters();
                      },
                    ),
                  ],
                ),
                if (_hasActiveFilters) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: _clearAllFilters,
                      child: Text(
                        'CLEAR ALL FILTERS',
                        style: LabStyles.mono(context,
                            fontSize: 8,
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // ── Results counter bar ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: LabColors.surfaceContainerHigh.withValues(alpha: 0.5),
              border: const Border(
                  bottom: BorderSide(color: LabColors.cyanBorder, width: 0.2)),
            ),
            child: Row(
              children: [
                Text(
                  'RESULTS: ${_filtered.length}',
                  style: LabStyles.mono(context,
                      fontSize: 9,
                      color: LabColors.primary,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 16),
                Text(
                  'TOTAL: ${_all.length}',
                  style:
                      LabStyles.mono(context, fontSize: 9, color: Colors.white),
                ),
              ],
            ),
          ),
          // ── Results list ──
          Expanded(
            child: ListView.builder(
              itemCount: _filtered.length,
              itemBuilder: (_, i) {
                final e = _filtered[i];
                return LabListTile(
                  title: e.fullName,
                  subtitle: _buildSubtitle(e),
                  onTap: () {
                    widget.onSelected(e);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchC.dispose();
    _baseC.dispose();
    _muscleC.dispose();
    super.dispose();
  }
}

class _GroupedSetSlot {
  const _GroupedSetSlot({
    required this.index,
    required this.globalIndex,
    required this.set,
    required this.log,
    this.side,
    this.leftSet,
    this.leftLog,
    this.leftIndex,
    this.leftGlobalIndex,
  });

  final int index;
  final int globalIndex;
  final dynamic set;
  final dynamic log;
  final String? side;
  final dynamic leftSet;
  final dynamic leftLog;
  final int? leftIndex;
  final int? leftGlobalIndex;

  bool get isPair => leftSet != null;
}

class _ExerciseModule extends ConsumerStatefulWidget {
  final BaseExercise exercise;
  final List<drift.TypedResult> results;
  final DateTime date;
  final double bodyWeight;
  final int index;
  final int globalSetStart;
  final ScrollController scrollController;
  final bool showDragHandle;
  final bool moduleIsIso;
  final bool moduleIsJst;
  final String moduleLoadType;
  const _ExerciseModule(
      {super.key,
      required this.exercise,
      required this.results,
      required this.date,
      required this.bodyWeight,
      required this.index,
      required this.globalSetStart,
      required this.scrollController,
      required this.moduleIsIso,
      required this.moduleIsJst,
      required this.moduleLoadType,
      this.showDragHandle = true});
  @override
  ConsumerState<_ExerciseModule> createState() => _ExerciseModuleState();
}

class _ExerciseModuleState extends ConsumerState<_ExerciseModule> {
  bool _isExpanded = false;
  List<_GroupedSetSlot> _groupedSetSlots = const [];

  @override
  void initState() {
    super.initState();
    _refreshGroupedSetSlots();
  }

  @override
  void didUpdateWidget(covariant _ExerciseModule oldWidget) {
    super.didUpdateWidget(oldWidget);
    _refreshGroupedSetSlots();
  }

  void _refreshGroupedSetSlots() {
    _groupedSetSlots = _buildGroupedSetSlots();
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.exercise;
    String loadType = widget.moduleLoadType;
    bool isIso = widget.moduleIsIso;

    final settings = ref.watch(themeSettingsProvider).value ?? {};
    final tC = ref.read(themeControllerProvider);
    final firstSet =
        widget.results.first.readTable(ref.read(databaseProvider).workoutSets);
    // Read utilities from complex_metadata (priority field fallback)
    List<String> utilities = [];
    if (firstSet.complexMetadata != null) {
      try {
        final meta = jsonDecode(firstSet.complexMetadata!);
        utilities = List<String>.from(meta['utilities'] ?? []);
      } catch (_) {}
    }
    if (utilities.isEmpty &&
        firstSet.priority != null &&
        firstSet.priority!.isNotEmpty) {
      utilities = [firstSet.priority!];
    }
    final bool hasUtility = utilities.isNotEmpty;
    final utilityColor = hasUtility
        ? tC.getColor(settings, "PRIORITY_${utilities.first}",
            nameSeed: utilities.first)
        : Colors.transparent;

    // Resolve tag colors from theme
    final uiTagLastre =
        tC.getColor(settings, "UI_TAG_LASTRE", nameSeed: "LASTRE");
    final uiTagJstbw = tC.getColor(settings, "UI_TAG_JSTBW", nameSeed: "JSTBW");
    final uiTagExtload =
        tC.getColor(settings, "UI_TAG_EXTLOAD", nameSeed: "EXTLOAD");
    final uiTagIso = tC.getColor(settings, "UI_TAG_ISO", nameSeed: "ISO");
    final uiTagBodyposition =
        tC.getColor(settings, "UI_TAG_BODYPOSITION", nameSeed: "BODYPOSITION");
    final uiTagPrimaryMuscle = tC.getColor(settings, "UI_TAG_PRIMARY_MUSCLE",
        nameSeed: "PRIMARY_MUSCLE");

    Color typeColor;
    switch (loadType) {
      case 'LASTRE':
        typeColor = uiTagLastre;
        break;
      case 'JST.BW':
        typeColor = uiTagJstbw;
        break;
      case 'EXT.LOAD':
        typeColor = uiTagExtload;
        break;
      default:
        typeColor = LabColors.primary;
    }
    final isoColor = uiTagIso;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: LabColors.surfaceDim,
        border: Border.all(
            color: hasUtility
                ? utilityColor
                : LabColors.cyanBorder
                    .withValues(alpha: _isExpanded ? 0.5 : 0.2),
            width: hasUtility ? 1.5 : 0.5),
        boxShadow: hasUtility
            ? [
                BoxShadow(
                    color: utilityColor.withValues(alpha: 0.1), blurRadius: 10)
              ]
            : null,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // [UTIL] row — OUTSIDE InkWell to avoid gesture conflict
                    GestureDetector(
                      onTap: () => _showUtilityEditDialog(context),
                      child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ...utilities.take(4).map((u) {
                                  final chipColor = tC.getColor(
                                      settings, "PRIORITY_$u",
                                      nameSeed: u);
                                  return Container(
                                    margin: const EdgeInsets.only(right: 3),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: chipColor.withValues(alpha: 0.2),
                                      border: Border.all(
                                          color: chipColor, width: 0.5),
                                    ),
                                    child: Text(
                                      u.toUpperCase(),
                                      style: LabStyles.mono(context,
                                          color: chipColor,
                                          fontSize: 7,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  );
                                }),
                                if (!hasUtility)
                                  Text('[ UTIL ]',
                                      style: LabStyles.mono(context,
                                          color: Colors.grey[600]!,
                                          fontSize: 8)),
                              ],
                            ),
                            if (isIso)
                              Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 1),
                                  margin: const EdgeInsets.only(right: 4),
                                  decoration: BoxDecoration(
                                      border: Border.all(
                                          color: isoColor, width: 0.5)),
                                  child: Text('ISO',
                                      style: LabStyles.mono(context,
                                          color: isoColor,
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold))),
                            Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                    border: Border.all(
                                        color: typeColor, width: 0.5)),
                                child: Text(loadType,
                                    style: LabStyles.mono(context,
                                        color: typeColor,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold))),
                          ]),
                    ),
                    const SizedBox(height: 6),
                    // Exercise name + tags — the expand/collapse area
                    InkWell(
                      onTap: () => setState(() => _isExpanded = !_isExpanded),
                      onLongPress: () => _showComplexModsModal(context),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Builder(builder: (c) {
                            return Text(e.fullName,
                                style: LabStyles.headline(context).copyWith(
                                    fontSize: 18, color: Colors.white));
                          }),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (e.primaryMuscleGroup != null)
                                Text(e.primaryMuscleGroup!.toUpperCase(),
                                    style: LabStyles.mono(context,
                                        color: uiTagPrimaryMuscle,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold)),
                              ...e.bodyPositionTags.map((tag) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: uiTagBodyposition.withValues(
                                          alpha: 0.1),
                                      border: Border.all(
                                          color: uiTagBodyposition.withValues(
                                              alpha: 0.3),
                                          width: 0.5),
                                    ),
                                    child: Text(tag.toUpperCase(),
                                        style: LabStyles.mono(context,
                                            fontSize: 7,
                                            color: uiTagBodyposition)),
                                  )),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Row(mainAxisSize: MainAxisSize.min, children: [
                if (widget.showDragHandle)
                  ReorderableDragStartListener(
                    index: widget.index,
                    child: const Padding(
                      padding: EdgeInsets.only(
                          left: 32, right: 6, top: 2, bottom: 2),
                      child: Icon(Icons.drag_handle,
                          color: LabColors.primary, size: 20),
                    ),
                  ),
                IconButton(
                    icon: const Icon(Icons.history,
                        color: LabColors.primary, size: 20),
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (c) => ExerciseHistoryScreen(
                                exercise: widget.exercise)))),
              ]),
            ],
          ),
        ),
        if (_isExpanded) ...[
          const Divider(height: 1, color: LabColors.cyanBorder, thickness: 0.2),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _groupedSetSlots.length,
                  onReorder: (oldIdx, newIdx) async {
                    if (newIdx > oldIdx) newIdx--;
                    final moved = _groupedSetSlots.removeAt(oldIdx);
                    _groupedSetSlots.insert(newIdx, moved);
                    setState(() {});

                    final db = ref.read(databaseProvider);
                    for (int i = 0; i < _groupedSetSlots.length; i++) {
                      await (db.update(db.workoutSets)
                            ..where(
                                (t) => t.id.equals(_groupedSetSlots[i].set.id)))
                          .write(
                              WorkoutSetsCompanion(orderIndex: drift.Value(i)));
                    }
                    _refreshGroupedSetSlots();
                  },
                  itemBuilder: (context, index) =>
                      _buildGroupedSetSlot(_groupedSetSlots[index], index),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                        child: LabButton(
                            label: 'Add Set',
                            onPressed: () => _addNewSet(context),
                            isOutlined: true,
                            color: Colors.white)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ]),
    );
  }

  void _showComplexModsModal(BuildContext context) {
    final bool isLinked = widget.results.first
            .readTable(ref.read(databaseProvider).workoutSets)
            .supersetGroupId !=
        null;

    showModalBottomSheet(
      context: context,
      backgroundColor: LabColors.background,
      builder: (c) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('COMPLEX_C.WO_MODS',
                style: LabStyles.headline(context).copyWith(fontSize: 16)),
            const SizedBox(height: 24),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _buildModCard(context, 'SUPERSET', Icons.link,
                    LabColors.primary, () => _handleCreateSuperset(context)),
                if (isLinked)
                  _buildModCard(context, 'BREAK_LINK', Icons.link_off,
                      Colors.orangeAccent, () => _handleBreakSuperset(context)),
                _buildModCard(context, 'EDIT MOVEMENT', Icons.settings,
                    LabColors.accent, () => _navigateToEdit(context)),
                _buildModCard(context, 'PURGE', Icons.delete_forever,
                    Colors.redAccent, () => _confirmPurge(context)),
                _buildModCard(context, 'MOVE TO TOP', Icons.arrow_upward,
                    Colors.white, () => _moveExerciseToExtreme(true)),
                _buildModCard(context, 'MOVE TO BOTTOM', Icons.arrow_downward,
                    Colors.white, () => _moveExerciseToExtreme(false)),
                _buildModCard(context, 'ASSIGN BATCH', Icons.folder,
                    Colors.tealAccent, () => _showBatchPopup(context)),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _moveExerciseToExtreme(bool toTop) async {
    final db = ref.read(databaseProvider);
    final start =
        DateTime(widget.date.year, widget.date.month, widget.date.day);
    final end = DateTime(
        widget.date.year, widget.date.month, widget.date.day, 23, 59, 59);

    final allSetsDay = await (db.select(db.workoutSets).join([
      drift.innerJoin(
          db.workoutLogs, db.workoutLogs.id.equalsExp(db.workoutSets.logId))
    ])
          ..where(db.workoutLogs.date.isBetweenValues(start, end))
          ..orderBy([
            drift.OrderingTerm.asc(db.workoutSets.orderIndex),
            drift.OrderingTerm.asc(db.workoutSets.timestamp)
          ]))
        .get();

    if (allSetsDay.isEmpty) return;

    final targetExId = widget.exercise.id;
    final List<int> exOrder = [];
    final Map<int, List<int>> setsByEx = {};

    for (var row in allSetsDay) {
      final s = row.readTable(db.workoutSets);
      if (!exOrder.contains(s.baseExerciseId)) exOrder.add(s.baseExerciseId);
      setsByEx.putIfAbsent(s.baseExerciseId, () => []).add(s.id);
    }

    exOrder.remove(targetExId);
    if (toTop) {
      exOrder.insert(0, targetExId);
    } else {
      exOrder.add(targetExId);
    }

    await db.transaction(() async {
      for (int i = 0; i < exOrder.length; i++) {
        final sets = setsByEx[exOrder[i]]!;
        await (db.update(db.workoutSets)..where((t) => t.id.isIn(sets)))
            .write(WorkoutSetsCompanion(orderIndex: drift.Value(i)));
      }
    });
  }

  Future<void> _showBatchPopup(BuildContext context) async {
    final db = ref.read(databaseProvider);
    // Ensure table exists (safety net for hot reloads)
    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS batch_definitions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        created_at INTEGER NOT NULL DEFAULT 0
      )
    ''');
    // Read ALL global batch names from batch_definitions table
    final rows = await db.executor
        .runSelect('SELECT name FROM batch_definitions ORDER BY name ASC', []);
    final batchList = rows.map((r) => r['name'] as String).toList();
    final nameC = TextEditingController();

    // Show dialog on top of mods modal (don't pop it)
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: LabColors.background,
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ASSIGN_BATCH',
                    style: LabStyles.headline(context).copyWith(fontSize: 16)),
                const SizedBox(height: 16),
                TextField(
                  controller: nameC,
                  style: LabStyles.mono(context,
                      fontSize: 12, color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'BATCH_NAME',
                    hintStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
                    border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24)),
                  ),
                ),
                if (batchList.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('EXISTING_BATCHES:',
                      style: LabStyles.mono(context,
                          fontSize: 9, color: Colors.grey[500])),
                  const SizedBox(height: 8),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                    childAspectRatio: 3.5,
                    children: batchList
                        .map((name) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 2, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                border: Border.all(
                                    color: Colors.white12, width: 0.5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        nameC.text = name.toUpperCase();
                                        nameC.selection =
                                            TextSelection.fromPosition(
                                          TextPosition(
                                              offset: nameC.text.length),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 6),
                                        child: Text(name.toUpperCase(),
                                            style: LabStyles.mono(context,
                                                fontSize: 10,
                                                color: Colors.tealAccent),
                                            overflow: TextOverflow.ellipsis),
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () async {
                                      await _renameBatch(db, name, c);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 3, vertical: 6),
                                      child: Icon(Icons.edit,
                                          size: 11, color: Colors.amber),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () async {
                                      await _deleteBatch(db, name, c);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 3, vertical: 6),
                                      child: Icon(Icons.delete,
                                          size: 11, color: Colors.redAccent),
                                    ),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: LabButton(
                    label: 'ASSIGN',
                    color: Colors.tealAccent,
                    onPressed: () async {
                      final name = nameC.text.trim();
                      if (name.isNotEmpty) {
                        await _assignBatch(db, name.toUpperCase());
                        if (c.mounted) Navigator.pop(c);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _assignBatch(AppDatabase db, String batchName) async {
    // 1) Ensure table exists (safety net for hot reloads)
    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS batch_definitions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        created_at INTEGER NOT NULL DEFAULT 0
      )
    ''');
    // 2) Ensure the batch exists globally in batch_definitions
    await db.customStatement(
        "INSERT OR IGNORE INTO batch_definitions (name, created_at) "
        "VALUES ('${batchName.replaceAll("'", "''")}', ${DateTime.now().millisecondsSinceEpoch})");
    // 2) Assign to selected sets (complex_metadata)
    final setIds =
        widget.results.map((r) => r.readTable(db.workoutSets).id).toList();
    for (final sid in setIds) {
      final row = await (db.select(db.workoutSets)
            ..where((t) => t.id.equals(sid)))
          .getSingle();
      Map<String, dynamic> meta = {};
      if (row.complexMetadata != null) {
        try {
          meta = jsonDecode(row.complexMetadata!);
        } catch (_) {}
      }
      meta['batch'] = batchName;
      await (db.update(db.workoutSets)..where((t) => t.id.equals(sid))).write(
          WorkoutSetsCompanion(complexMetadata: drift.Value(jsonEncode(meta))));
    }
    // 3) Invalidate batch names provider so THEME.MDFYR updates
    if (context.mounted) ref.invalidate(allBatchNamesProvider);
  }

  Future<void> _renameBatch(
      AppDatabase db, String oldName, BuildContext dialogContext) async {
    final newNameC = TextEditingController(text: oldName);
    final result = await showDialog<String>(
      context: dialogContext,
      builder: (c2) => AlertDialog(
        backgroundColor: LabColors.background,
        title: Text('RENAME_BATCH',
            style: LabStyles.headline(c2).copyWith(fontSize: 14)),
        content: TextField(
          controller: newNameC,
          style: LabStyles.mono(c2, fontSize: 12, color: Colors.white),
          decoration: InputDecoration(
            hintText: 'NEW_NAME',
            hintStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
            border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white24)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c2, null),
            child: Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(c2, newNameC.text.trim().toUpperCase()),
            child: Text('RENAME', style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty || result == oldName) return;
    final safeOld = oldName.replaceAll("'", "''");
    final safeNew = result.replaceAll("'", "''");
    // Ensure table + rename in batch_definitions
    await db.customStatement(
        "INSERT OR IGNORE INTO batch_definitions (name, created_at) VALUES ('$safeNew', ${DateTime.now().millisecondsSinceEpoch})");
    await db.customStatement(
        "DELETE FROM batch_definitions WHERE name = '$safeOld'");
    // Update all workout_sets complex_metadata that reference the old name
    final affected = await db.executor.runSelect(
        "SELECT id, complex_metadata FROM workout_sets WHERE complex_metadata LIKE '%\"batch\":\"$safeOld\"%'",
        []);
    for (final row in affected) {
      final sid = row['id'] as int;
      final cm = row['complex_metadata'] as String?;
      if (cm == null) continue;
      try {
        final meta = jsonDecode(cm) as Map<String, dynamic>;
        if (meta['batch'] == oldName) {
          meta['batch'] = result;
          await (db.update(db.workoutSets)..where((t) => t.id.equals(sid)))
              .write(WorkoutSetsCompanion(
                  complexMetadata: drift.Value(jsonEncode(meta))));
        }
      } catch (_) {}
    }
    if (context.mounted) ref.invalidate(allBatchNamesProvider);
  }

  Future<void> _deleteBatch(
      AppDatabase db, String batchName, BuildContext dialogContext) async {
    final confirmed = await showDialog<bool>(
      context: dialogContext,
      builder: (c2) => AlertDialog(
        backgroundColor: LabColors.background,
        title: Text('DELETE_BATCH',
            style: LabStyles.headline(c2).copyWith(fontSize: 14)),
        content: Text(
            'Delete batch "${batchName.toUpperCase()}"?\nThis will remove it from all sets.',
            style: LabStyles.mono(c2, fontSize: 11, color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c2, false),
            child: Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c2, true),
            child: Text('DELETE', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final safeName = batchName.replaceAll("'", "''");
    // Remove from batch_definitions
    await db.customStatement(
        "DELETE FROM batch_definitions WHERE name = '$safeName'");
    // Clear 'batch' key from all workout_sets complex_metadata
    final affected = await db.executor.runSelect(
        "SELECT id, complex_metadata FROM workout_sets WHERE complex_metadata LIKE '%\"batch\":\"$safeName\"%'",
        []);
    for (final row in affected) {
      final sid = row['id'] as int;
      final cm = row['complex_metadata'] as String?;
      if (cm == null) continue;
      try {
        final meta = jsonDecode(cm) as Map<String, dynamic>;
        if (meta['batch'] == batchName) {
          meta.remove('batch');
          await (db.update(db.workoutSets)..where((t) => t.id.equals(sid)))
              .write(WorkoutSetsCompanion(
                  complexMetadata: drift.Value(jsonEncode(meta))));
        }
      } catch (_) {}
    }
    if (context.mounted) ref.invalidate(allBatchNamesProvider);
  }

  Widget _buildModCard(BuildContext context, String label, IconData icon,
      Color color, VoidCallback onTap) {
    return Material(
      color: LabColors.surfaceContainerHigh,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          onTap();
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(label,
                style: LabStyles.mono(context,
                    fontSize: 8, color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _navigateToEdit(BuildContext context) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (c) => EditExerciseScreen(exercise: widget.exercise)));
  }

  void _handleBreakSuperset(BuildContext context) async {
    final db = ref.read(databaseProvider);
    final firstSet = widget.results.first.readTable(db.workoutSets);
    final gId = firstSet.supersetGroupId;
    if (gId == null) return;

    await (db.update(db.workoutSets)
          ..where((t) => t.supersetGroupId.equals(gId)))
        .write(const WorkoutSetsCompanion(
            supersetGroupId: drift.Value(null),
            supersetName: drift.Value(null)));

    if (context.mounted)
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("SUPERSET_DISSOLVED")));
  }

  void _handleCreateSuperset(BuildContext context) async {
    final db = ref.read(databaseProvider);
    final start =
        DateTime(widget.date.year, widget.date.month, widget.date.day);
    final end = DateTime(
        widget.date.year, widget.date.month, widget.date.day, 23, 59, 59);

    final daySets = await (db.select(db.workoutSets).join([
      drift.innerJoin(db.baseExercises,
          db.baseExercises.id.equalsExp(db.workoutSets.baseExerciseId)),
      drift.innerJoin(
          db.workoutLogs, db.workoutLogs.id.equalsExp(db.workoutSets.logId))
    ])
          ..where(db.workoutLogs.date.isBetweenValues(start, end)))
        .get();

    final Map<int, List<drift.TypedResult>> grouped = {};
    for (var row in daySets) {
      final exId = row.readTable(db.baseExercises).id;
      grouped.putIfAbsent(exId, () => []).add(row);
    }

    final others =
        grouped.entries.where((e) => e.key != widget.exercise.id).toList();
    final Set<int> selectedIds = {};
    final nameC = TextEditingController();

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: LabColors.background,
      builder: (c) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('FORGE_SUPERSET_IN_VIVO',
                  style: LabStyles.headline(context).copyWith(fontSize: 16)),
              const SizedBox(height: 24),
              LabTextField(
                  controller: nameC,
                  label: 'SUPERSET_NAME',
                  placeholder: 'e.g. AGONIST_STATIC'),
              const SizedBox(height: 16),
              Text('SELECT MOVEMENTS TO LINK:',
                  style:
                      LabStyles.mono(context, fontSize: 8, color: Colors.grey)),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: LabStyles.hairlineBorder(),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: others.length,
                  itemBuilder: (context, i) {
                    final ex =
                        others[i].value.first.readTable(db.baseExercises);
                    final firstS =
                        others[i].value.first.readTable(db.workoutSets);
                    final bool isLinked = firstS.supersetGroupId != null;

                    return CheckboxListTile(
                      title: Text(ex.fullName,
                          style: LabStyles.mono(context, fontSize: 10)),
                      value: selectedIds.contains(ex.id),
                      subtitle: isLinked
                          ? Text('ALREADY LINKED: ${firstS.supersetName}',
                              style: LabStyles.mono(context,
                                  fontSize: 7, color: Colors.orangeAccent))
                          : null,
                      onChanged: (val) {
                        setModalState(() {
                          if (val == true) {
                            selectedIds.add(ex.id);
                          } else {
                            selectedIds.remove(ex.id);
                          }
                        });
                      },
                      activeColor: LabColors.primary,
                      checkColor: Colors.black,
                      selected: selectedIds.contains(ex.id),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              LabButton(
                  label: 'Forge Link',
                  onPressed: () async {
                    final String sName = nameC.text.toUpperCase().trim();
                    if (sName.isEmpty || selectedIds.isEmpty) return;

                    final String gId =
                        DateTime.now().millisecondsSinceEpoch.toString();

                    await db.transaction(() async {
                      // Update target sets
                      final targetSets = widget.results
                          .map((r) => r.readTable(db.workoutSets).id)
                          .toList();
                      await (db.update(db.workoutSets)
                            ..where((t) => t.id.isIn(targetSets)))
                          .write(WorkoutSetsCompanion(
                              supersetGroupId: drift.Value(gId),
                              supersetName: drift.Value(sName)));

                      // Update selected others
                      for (int exId in selectedIds) {
                        final otherSets = grouped[exId]!
                            .map((r) => r.readTable(db.workoutSets).id)
                            .toList();
                        await (db.update(db.workoutSets)
                              ..where((t) => t.id.isIn(otherSets)))
                            .write(WorkoutSetsCompanion(
                                supersetGroupId: drift.Value(gId),
                                supersetName: drift.Value(sName)));
                      }
                    });

                    if (context.mounted) Navigator.pop(context);
                  }),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showUtilityEditDialog(BuildContext context) async {
    final db = ref.read(databaseProvider);
    final allSets = await db.select(db.workoutSets).get();
    final Set<String> existingUtilities = {};
    final Map<String, int> utilFrequency = {};
    for (final set in allSets) {
      if (set.priority != null && set.priority!.isNotEmpty) {
        existingUtilities.add(set.priority!);
        utilFrequency[set.priority!] = (utilFrequency[set.priority!] ?? 0) + 1;
      }
      if (set.complexMetadata != null) {
        try {
          final meta = jsonDecode(set.complexMetadata!);
          final utils = meta['utilities'] as List? ?? [];
          for (final u in utils.cast<String>()) {
            existingUtilities.add(u);
            utilFrequency[u] = (utilFrequency[u] ?? 0) + 1;
          }
        } catch (_) {}
      }
    }
    final existingList = existingUtilities.toList()..sort();
    if (!context.mounted) return;

    final firstSet = widget.results.first.readTable(db.workoutSets);
    List<String> currentUtilities = [];
    if (firstSet.complexMetadata != null) {
      try {
        final meta = jsonDecode(firstSet.complexMetadata!);
        currentUtilities = List<String>.from(meta['utilities'] ?? []);
      } catch (_) {}
    }
    if (currentUtilities.isEmpty &&
        firstSet.priority != null &&
        firstSet.priority!.isNotEmpty) {
      currentUtilities = [firstSet.priority!];
    }

    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: LabColors.background,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Padding(
            padding: const EdgeInsets.only(left: 24, right: 24, top: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('EDIT_MOVEMENT_UTILITY',
                    style: LabStyles.headline(context).copyWith(fontSize: 16)),
                const SizedBox(height: 24),
                Flexible(
                  child: SingleChildScrollView(
                    child: LabUtilitySelector(
                      selected: currentUtilities,
                      suggestions: existingList,
                      utilityFrequency: utilFrequency,
                      onChanged: (updated) =>
                          setDialogState(() => currentUtilities = updated),
                      onRename: (oldN, newN) =>
                          _propagatePriorityChange(oldN, newN),
                      onDelete: (name) => _propagatePriorityChange(name, null),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                LabButton(
                    label: 'Apply Utility',
                    onPressed: () async {
                      final sets = widget.results
                          .map((r) => r.readTable(db.workoutSets).id)
                          .toList();
                      for (final setId in sets) {
                        final rows = await (db.select(db.workoutSets)
                              ..where((t) => t.id.equals(setId)))
                            .get();
                        if (rows.isEmpty) continue;
                        final rowSet = rows.first;
                        Map<String, dynamic> meta = {};
                        if (rowSet.complexMetadata != null) {
                          try {
                            meta = jsonDecode(rowSet.complexMetadata!);
                          } catch (_) {}
                        }
                        if (currentUtilities.isEmpty) {
                          meta.remove('utilities');
                        } else {
                          meta['utilities'] = currentUtilities;
                        }
                        await (db.update(db.workoutSets)
                              ..where((t) => t.id.equals(setId)))
                            .write(WorkoutSetsCompanion(
                          complexMetadata: drift.Value(
                              meta.isNotEmpty ? jsonEncode(meta) : null),
                          priority: drift.Value(currentUtilities.isNotEmpty
                              ? currentUtilities.first
                              : null),
                        ));
                      }
                      if (context.mounted) Navigator.pop(context);
                    }),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _propagatePriorityChange(String oldName, String? newName) async {
    final db = ref.read(databaseProvider);
    await db.transaction(() async {
      // Update Workout Logs
      await (db.update(db.workoutSets)
            ..where((t) => t.priority.equals(oldName)))
          .write(WorkoutSetsCompanion(priority: drift.Value(newName)));
    });
  }

  List<_GroupedSetSlot> _buildGroupedSetSlots() {
    final db = ref.read(databaseProvider);
    final List<_GroupedSetSlot> items = [];
    final sets = widget.results.asMap().entries.toList();

    int i = 0;
    while (i < sets.length) {
      final entry = sets[i];
      final s = entry.value.readTable(db.workoutSets);
      final l = entry.value.readTable(db.workoutLogs);

      Map<String, dynamic> meta = {};
      try {
        if (s.complexMetadata != null) meta = jsonDecode(s.complexMetadata!);
      } catch (_) {}

      // Check if it's the start of a unilateral pair
      if (widget.exercise.isUnilateral &&
          meta["side"] == "RIGHT" &&
          (i + 1) < sets.length) {
        final nextEntry = sets[i + 1];
        final ns = nextEntry.value.readTable(db.workoutSets);
        final nl = nextEntry.value.readTable(db.workoutLogs);
        Map<String, dynamic> nMeta = {};
        try {
          if (ns.complexMetadata != null)
            nMeta = jsonDecode(ns.complexMetadata!);
        } catch (_) {}

        if (nMeta["side"] == "LEFT") {
          items.add(_GroupedSetSlot(
            index: i,
            globalIndex: widget.globalSetStart + i + 1,
            set: s,
            log: l,
            side: "RIGHT",
            leftSet: ns,
            leftLog: nl,
            leftIndex: i + 1,
            leftGlobalIndex: widget.globalSetStart + i + 2,
          ));
          i += 2;
          continue;
        }
      }

      // Single set (standard or fallback)
      items.add(_GroupedSetSlot(
        index: i,
        globalIndex: widget.globalSetStart + i + 1,
        set: s,
        log: l,
      ));
      i++;
    }
    return items;
  }

  Widget _buildGroupedSetSlot(_GroupedSetSlot slot, int slotIndex) {
    if (slot.isPair) {
      return _UnilateralPairFrame(
        key: ValueKey('pair_${slot.set.id}_${slot.leftSet.id}'),
        rightSet: _WorkoutSetInstance(
          key: ValueKey('set_${slot.set.id}'),
          set: slot.set,
          log: slot.log,
          exercise: widget.exercise,
          index: slot.index,
          globalIndex: slot.globalIndex,
          bodyWeight: widget.bodyWeight,
          isIso: widget.moduleIsIso,
          isJst: widget.moduleIsJst,
          loadType: widget.moduleLoadType,
          side: slot.side,
        ),
        leftSet: _WorkoutSetInstance(
          key: ValueKey('set_${slot.leftSet.id}'),
          set: slot.leftSet,
          log: slot.leftLog,
          exercise: widget.exercise,
          index: slot.leftIndex!,
          globalIndex: slot.leftGlobalIndex!,
          bodyWeight: widget.bodyWeight,
          isIso: widget.moduleIsIso,
          isJst: widget.moduleIsJst,
          loadType: widget.moduleLoadType,
          side: "LEFT",
        ),
        index: slotIndex + 1,
      );
    }

    return _WorkoutSetInstance(
      key: ValueKey('set_${slot.set.id}'),
      set: slot.set,
      log: slot.log,
      exercise: widget.exercise,
      index: slot.index,
      globalIndex: slot.globalIndex,
      bodyWeight: widget.bodyWeight,
      isIso: widget.moduleIsIso,
      isJst: widget.moduleIsJst,
      loadType: widget.moduleLoadType,
    );
  }

  // Remove old _buildExerciseReorderControls and _moveExercise
  Future<void> _addNewSet(BuildContext c) async {
    final db = ref.read(databaseProvider);
    final fS = widget.results.first.readTable(db.workoutSets);

    if (widget.exercise.isUnilateral) {
      // Add two coupled sets
      final timestamp = DateTime.now();
      await db.into(db.workoutSets).insert(WorkoutSetsCompanion.insert(
            logId: fS.logId,
            baseExerciseId: widget.exercise.id,
            weight: fS.weight,
            reps: fS.reps,
            timestamp: drift.Value(timestamp),
            complexMetadata: drift.Value(jsonEncode({"side": "RIGHT"})),
            priority: drift.Value(fS.priority),
            orderIndex: drift.Value(fS.orderIndex),
          ));
      await db.into(db.workoutSets).insert(WorkoutSetsCompanion.insert(
            logId: fS.logId,
            baseExerciseId: widget.exercise.id,
            weight: fS.weight,
            reps: fS.reps,
            timestamp:
                drift.Value(timestamp.add(const Duration(milliseconds: 1))),
            complexMetadata: drift.Value(jsonEncode({"side": "LEFT"})),
            priority: drift.Value(fS.priority),
            orderIndex: drift.Value(fS.orderIndex),
          ));
    } else {
      await db.into(db.workoutSets).insert(WorkoutSetsCompanion.insert(
            logId: fS.logId,
            baseExerciseId: widget.exercise.id,
            weight: fS.weight,
            reps: fS.reps,
            timestamp: drift.Value(DateTime.now()),
            priority: drift.Value(fS.priority),
            complexMetadata: drift.Value(fS.complexMetadata),
            orderIndex: drift.Value(fS.orderIndex),
          ));
    }
  }

  void _confirmPurge(BuildContext c) {
    showDialog(
        context: c,
        builder: (c) => AlertDialog(
                backgroundColor: LabColors.background,
                title: Text('PURGE_MODULE',
                    style: LabStyles.mono(context,
                        color: Colors.redAccent, fontWeight: FontWeight.bold)),
                content: Text('DELETE ALL SETS?',
                    style: LabStyles.mono(context, fontSize: 12)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c),
                      child: Text('ABORT', style: LabStyles.mono(context))),
                  TextButton(
                      onPressed: () async {
                        final db = ref.read(databaseProvider);
                        final ids = widget.results
                            .map((r) => r.readTable(db.workoutSets).id)
                            .toList();
                        await (db.delete(db.workoutSets)
                              ..where((t) => t.id.isIn(ids)))
                            .go();
                        if (context.mounted) Navigator.pop(c);
                      },
                      child: Text('PURGE',
                          style:
                              LabStyles.mono(context, color: Colors.redAccent)))
                ]));
  }

  Future<void> _copyPreviousWorkoutData() async {
    final db = ref.read(databaseProvider);
    final today =
        DateTime(widget.date.year, widget.date.month, widget.date.day);

    // 1. Find the most recent date before today for this exercise
    final previousSessionRows = await (db.select(db.workoutSets).join([
      drift.innerJoin(
          db.workoutLogs, db.workoutLogs.id.equalsExp(db.workoutSets.logId))
    ])
          ..where(db.workoutSets.baseExerciseId.equals(widget.exercise.id) &
              db.workoutLogs.date.isSmallerThanValue(today))
          ..orderBy([
            drift.OrderingTerm.desc(db.workoutLogs.date),
            drift.OrderingTerm.asc(db.workoutSets.orderIndex),
            drift.OrderingTerm.asc(db.workoutSets.timestamp)
          ]))
        .get();

    if (previousSessionRows.isEmpty) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("NO_PREVIOUS_SESSION_FOUND")));
      return;
    }

    // Group previous sets by their date to get ONLY the most recent one
    final lastDate = previousSessionRows.first.readTable(db.workoutLogs).date;
    final lastSets = previousSessionRows
        .where((r) => r.readTable(db.workoutLogs).date == lastDate)
        .toList();

    // 2. Map current sets
    final currentSets =
        widget.results.map((r) => r.readTable(db.workoutSets)).toList();

    // 3. Update today's sets with previous values
    await db.transaction(() async {
      for (int i = 0; i < currentSets.length; i++) {
        if (i < lastSets.length) {
          final prevSet = lastSets[i].readTable(db.workoutSets);
          await (db.update(db.workoutSets)
                ..where((t) => t.id.equals(currentSets[i].id)))
              .write(WorkoutSetsCompanion(
            weight: drift.Value(prevSet.weight),
            reps: drift.Value(prevSet.reps),
          ));
        }
      }
    });

    if (mounted)
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("PREVIOUS_DATA_COPIED")));
  }
}

class _WorkoutSetInstance extends ConsumerStatefulWidget {
  final WorkoutSet set;
  final WorkoutLog log;
  final BaseExercise exercise;
  final int index;
  final int globalIndex;
  final double bodyWeight;
  final String? side;
  final bool isIso;
  final bool isJst;
  final String loadType;
  const _WorkoutSetInstance(
      {super.key,
      required this.set,
      required this.log,
      required this.exercise,
      required this.index,
      required this.globalIndex,
      required this.bodyWeight,
      required this.isIso,
      required this.isJst,
      required this.loadType,
      this.side});
  @override
  ConsumerState<_WorkoutSetInstance> createState() =>
      _WorkoutSetInstanceState();
}

class _WorkoutSetInstanceState extends ConsumerState<_WorkoutSetInstance> {
  late TextEditingController _lC,
      _rC,
      _tC,
      _rsC,
      _rpeC,
      _rirC,
      _fC,
      _techC,
      _commentC;
  Timer? _db;
  Timer? _prDb;
  bool _exp = false;
  bool _showComment = false;
  bool _isIso = false;

  Stopwatch? _restStopwatch;
  Timer? _tickTimer;

  String _formatInputValue(double value) {
    if (value.isFinite && value == value.truncateToDouble()) {
      return value.truncate().toString();
    }
    return value.toString();
  }

  @override
  void initState() {
    super.initState();
    _lC = TextEditingController(text: _formatInputValue(widget.set.weight));
    _rC = TextEditingController(text: _formatInputValue(widget.set.reps));
    _tC = TextEditingController(
        text: (widget.set.trackName ?? '').replaceAll('[RED_PR]', '').trim());
    _rsC = TextEditingController(
        text: _formatInputValue(widget.set.restTimeSeconds?.toDouble() ?? 0));
    _rpeC = TextEditingController(text: widget.set.rpe?.toString() ?? '');
    _rirC = TextEditingController(text: widget.set.rir?.toString() ?? '');
    _fC = TextEditingController(
        text: widget.set.restTimeSeconds != null
            ? _formatInputValue(widget.set.restTimeSeconds! / 10)
            : '');
    _techC =
        TextEditingController(text: widget.set.technique?.toString() ?? '');
    _commentC = TextEditingController(text: widget.set.notes);

    if (widget.isJst) {
      _lC.text = _formatInputValue(widget.bodyWeight);
    }
    // Isometric detection for conditional UI
    _isIso = widget.isIso;
  }

  @override
  void dispose() {
    _db?.cancel();
    _prDb?.cancel();
    _tickTimer?.cancel();
    _lC.dispose();
    _rC.dispose();
    _tC.dispose();
    _rsC.dispose();
    _rpeC.dispose();
    _rirC.dispose();
    _fC.dispose();
    _techC.dispose();
    _commentC.dispose();
    super.dispose();
  }

  void _onChanged() {
    _db?.cancel();
    _prDb?.cancel();

    _db = Timer(const Duration(milliseconds: 100), () async {
      await _saveCurrentSetRaw();
    });

    _prDb = Timer(const Duration(milliseconds: 1200), () async {
      await _recalculatePrsAndEorm();
    });
  }

  Future<void> _saveCurrentSetRaw() async {
    if (!mounted) return;

    final db = ref.read(databaseProvider);
    final w = double.tryParse(_lC.text) ?? 0;
    final r = double.tryParse(_rC.text) ?? 0;
    final rpe = double.tryParse(_rpeC.text);
    final rir = double.tryParse(_rirC.text);
    final f = double.tryParse(_fC.text) ?? 1;
    final te = int.tryParse(_techC.text);
    final isJst = widget.isJst;
    final actualWeight = isJst ? widget.bodyWeight : w;
    final rest = int.tryParse(_rsC.text) ?? (f * 10).toInt();
    final track = _tC.text.trim().replaceFirst('[RED_PR]', '').trim();
    final notes = _commentC.text.trim();

    await (db.update(db.workoutSets)..where((t) => t.id.equals(widget.set.id)))
        .write(WorkoutSetsCompanion(
      weight: drift.Value(actualWeight),
      reps: drift.Value(r),
      rpe: drift.Value(rpe),
      rir: drift.Value(rir),
      restTimeSeconds: drift.Value(rest),
      technique: drift.Value(te ?? 1),
      trackName: drift.Value(track.isEmpty ? null : track),
      notes: drift.Value(notes.isEmpty ? null : notes),
    ));
  }

  Future<void> _recalculatePrsAndEorm() async {
    if (!mounted) return;

    final db = ref.read(databaseProvider);
    final w = double.tryParse(_lC.text) ?? 0;
    final r = double.tryParse(_rC.text) ?? 0;
    final rpe = double.tryParse(_rpeC.text);
    final rir = double.tryParse(_rirC.text);
    final f = double.tryParse(_fC.text) ?? 1;
    final te = int.tryParse(_techC.text);

    final isL = widget.loadType == 'LASTRE';
    final isJst = widget.isJst;

    final today = DateTime(widget.set.timestamp.year,
        widget.set.timestamp.month, widget.set.timestamp.day);
    final actualWeight = isJst ? widget.bodyWeight : w;

    final histBefore = await (db.select(db.workoutSets).join([
      drift.innerJoin(
          db.workoutLogs, db.workoutLogs.id.equalsExp(db.workoutSets.logId))
    ])
          ..where(db.workoutSets.baseExerciseId.equals(widget.exercise.id) &
              db.workoutSets.timestamp.isSmallerThanValue(today)))
        .get();

    // PNDEV 39: Build per-side history max values
    // Key: side string (null for non-unilateral), value: max value
    final Map<String?, double> maxlHistM = {},
        maxeHistM = {},
        maxefHistM = {},
        maxerHistM = {},
        maxerecHistM = {},
        maxetHistM = {};
    final Map<String?, Map<double, double>> w2rHistM = {};

    String? sideOf(WorkoutSet s) {
      if (!widget.exercise.isUnilateral) return null;
      try {
        final m = jsonDecode(s.complexMetadata ?? '{}');
        return m['side'] as String?;
      } catch (_) {
        return null;
      }
    }

    for (var row in histBefore) {
      final s = row.readTable(db.workoutSets);
      final l = row.readTable(db.workoutLogs);
      final sideKey = sideOf(s);
      final hL = s.weight + (isL ? widget.bodyWeight : 0);
      final hE = hL * (1 + (s.reps / 30));

      maxlHistM[sideKey] =
          (maxlHistM[sideKey] ?? 0) < hL ? hL : (maxlHistM[sideKey] ?? 0);
      maxeHistM[sideKey] =
          (maxeHistM[sideKey] ?? 0) < hE ? hE : (maxeHistM[sideKey] ?? 0);

      w2rHistM.putIfAbsent(sideKey, () => {});
      final w2r = w2rHistM[sideKey]!;
      w2r[hL] = (w2r[hL] ?? 0) > s.reps ? w2r[hL]! : s.reps;

      final hF = s.restTimeSeconds != null ? s.restTimeSeconds! / 10.0 : 1.0;
      final hEf = hE / (hF + 1.0);
      if (hEf > (maxefHistM[sideKey] ?? 0)) maxefHistM[sideKey] = hEf;
      final hEr = hE * (1.1 - (0.1 * (s.rpe ?? 10)));
      if (hEr > (maxerHistM[sideKey] ?? 0)) maxerHistM[sideKey] = hEr;
      final sM = RegExp(r'\[S:([\d.]+)\]').firstMatch(l.notes ?? '');
      final sV = double.tryParse(sM?.group(1) ?? '8') ?? 8;
      final hErc = hE * (1.1 - (0.1 * sV));
      if (hErc > (maxerecHistM[sideKey] ?? 0)) maxerecHistM[sideKey] = hErc;
      final hEt = hE * (s.technique ?? 1);
      if (hEt > (maxetHistM[sideKey] ?? 0)) maxetHistM[sideKey] = hEt;
    }

    // 2. Get all sets TODAY to find session winner
    final nextDay = today.add(const Duration(days: 1));
    final todaySets = await (db.select(db.workoutSets)
          ..where((t) =>
              t.baseExerciseId.equals(widget.exercise.id) &
              t.timestamp.isBetweenValues(today, nextDay))
          ..orderBy([(t) => drift.OrderingTerm.asc(t.timestamp)]))
        .get();

    // PNDEV 39: Per-side session best
    int? bestSetIdToday;
    double currentMaxEToday = 0;
    final Map<String?, double> maxeSessM = {};
    final Map<String?, int?> bestSetIdM = {};

    for (var s in todaySets) {
      final sideKey = sideOf(s);
      double sw = (s.id == widget.set.id) ? actualWeight : s.weight;
      double sr = (s.id == widget.set.id) ? r : s.reps;
      final sTL = sw + (isL ? widget.bodyWeight : 0);
      final sE = sTL * (1 + (sr / 30));
      if (sE > (maxeSessM[sideKey] ?? 0)) {
        maxeSessM[sideKey] = sE;
        bestSetIdM[sideKey] = s.id;
      }
      // Also track overall best for RED_PR (cross-side still gets one RED)
      if (sE > currentMaxEToday) {
        currentMaxEToday = sE;
        bestSetIdToday = s.id;
      }
    }

    // 3. Update ALL sets today — per-side PR comparison
    final Map<String?, double> maxlSessM = {},
        maxefSessM = {},
        maxerSessM = {},
        maxetSessM = {};
    final Map<String?, Map<double, double>> w2rSessM = {};

    for (var s in todaySets) {
      final sideKey = sideOf(s);
      double sw = s.weight;
      double sr = s.reps;
      double? srpe = s.rpe;
      double? sRir = s.rir;
      int sRest = s.restTimeSeconds ?? 120;
      int ste = s.technique ?? 1;
      String sNotes = s.notes ?? "";
      String sTrack = (s.trackName ?? "").replaceFirst('[RED_PR]', '').trim();

      if (s.id == widget.set.id) {
        sw = actualWeight;
        sr = r;
        srpe = rpe;
        sRir = rir;
        ste = te ?? 1;
        sNotes = _commentC.text.trim();
        sRest = int.tryParse(_rsC.text) ?? (f * 10).toInt();
        sTrack = _tC.text.trim().replaceFirst('[RED_PR]', '').trim();
      }

      final sTL = sw + (isL ? widget.bodyWeight : 0);
      final sE = sTL * (1 + (sr / 30));
      final sF = sRest / 10.0;
      final sEf = sE / (sF + 1.0);
      final sEr = sE * (1.1 - (0.1 * (srpe ?? 10)));
      final sEt = sE * ste;

      // Use side-specific history/session max values
      final hp = maxlHistM[sideKey] ?? 0;
      final he = maxeHistM[sideKey] ?? 0;
      final hef = maxefHistM[sideKey] ?? 0;
      final her = maxerHistM[sideKey] ?? 0;
      final het = maxetHistM[sideKey] ?? 0;
      final w2rH = (w2rHistM[sideKey] ?? {})[sTL] ?? 0;

      final sp = maxlSessM[sideKey] ?? 0;
      final se = maxeSessM[sideKey] ?? 0;
      final sef = maxefSessM[sideKey] ?? 0;
      final ser = maxerSessM[sideKey] ?? 0;
      final setc = maxetSessM[sideKey] ?? 0;
      final w2rS = (w2rSessM[sideKey] ?? {})[sTL] ?? 0;

      // Smart PR Logic: Must beat same-side history AND same-side session best
      bool sIsPr = ((sTL > hp && sTL > sp) && sTL > 0) ||
          ((sr > w2rH && sr > w2rS) && sTL > 0) ||
          ((sE > he && sE > se) && sE > 0) ||
          ((sEf > hef && sEf > sef) && sEf > 0) ||
          ((sEr > her && sEr > ser) && sEr > 0) ||
          ((sEt > het && sEt > setc) && sEt > 0);

      // Update Session Running Bests (per-side)
      if (sTL > (maxlSessM[sideKey] ?? 0)) maxlSessM[sideKey] = sTL;
      if (sE > (maxeSessM[sideKey] ?? 0)) maxeSessM[sideKey] = sE;
      if (sEf > (maxefSessM[sideKey] ?? 0)) maxefSessM[sideKey] = sEf;
      if (sEr > (maxerSessM[sideKey] ?? 0)) maxerSessM[sideKey] = sEr;
      if (sEt > (maxetSessM[sideKey] ?? 0)) maxetSessM[sideKey] = sEt;
      w2rSessM.putIfAbsent(sideKey, () => {});
      final w2rSm = w2rSessM[sideKey]!;
      w2rSm[sTL] = (w2rSm[sTL] ?? 0) > sr ? w2rSm[sTL]! : sr;

      // RED_PR: overall session best (cross-side, one per day)
      bool sIsRed = (s.id == bestSetIdToday) &&
          (sE > (maxeHistM[sideKey] ?? 0)) &&
          (sE > 0);
      if (sIsRed) sTrack = "[RED_PR] $sTrack";

      await (db.update(db.workoutSets)..where((t) => t.id.equals(s.id))).write(
          WorkoutSetsCompanion(
              weight: drift.Value(sw),
              reps: drift.Value(sr),
              rpe: drift.Value(srpe),
              rir: drift.Value(sRir),
              restTimeSeconds: drift.Value(sRest),
              technique: drift.Value(ste),
              trackName: drift.Value(sTrack.isEmpty ? null : sTrack),
              notes: drift.Value(sNotes.isEmpty ? null : sNotes),
              isPr: drift.Value(sIsPr)));
    }
  }

  void _showTrackSearchOverlay() async {
    final db = ref.read(databaseProvider);
    final sets = await db.select(db.workoutSets).get();

    final Set<String> tracks = {};
    for (var s in sets) {
      if (s.trackName != null && s.trackName!.isNotEmpty) {
        final clean = s.trackName!.replaceFirst('[RED_PR] ', '').trim();
        if (clean.isNotEmpty) tracks.add(clean);
      }
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: LabColors.background,
      isScrollControlled: true,
      builder: (c) => QualitySearchPicker(
        title: "SELECT_TRACK",
        values: tracks.toList()..sort(),
        onSelected: (v) {
          setState(() {
            _tC.text = v;
          });
          _onChanged();
        },
      ),
    );
  }

  void _toggleRestTimer() {
    if (_restStopwatch == null || !_restStopwatch!.isRunning) {
      _restStopwatch = Stopwatch()..start();
      _tickTimer =
          Timer.periodic(const Duration(seconds: 1), (t) => setState(() {}));
    } else {
      _restStopwatch!.stop();
      _tickTimer?.cancel();
      _rsC.text = _restStopwatch!.elapsed.inSeconds.toString();
      _restStopwatch = null;
      _onChanged();
    }
    setState(() {});
  }

  void _showComplexSetModsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: LabColors.background,
      isScrollControlled: true,
      builder: (c) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('COMPLEX_SET_MODS',
                  style: LabStyles.headline(context).copyWith(fontSize: 16)),
              const SizedBox(height: 24),
              // --- ACOUSTIC SECTION (IN MODAL) ---
              _buildModalAcousticCard(context, setModalState),
              const SizedBox(height: 16),
              // --- REST TIMER SECTION (IN MODAL) ---
              Row(
                children: [
                  Expanded(
                      child: _buildModalGridInput(context, 'REST_SAVED', _rsC)),
                  const SizedBox(width: 8),
                  _buildModalRestTimerBox(context, setModalState, flex: 1),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 140,
                    child: _buildModalGridInput(context, 'FATIGUE_FACTOR', _fC),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // --- ACTION SECTION ---
              _buildModCard(context, 'PURGE_SET', Icons.delete_forever,
                  Colors.redAccent, () => _confirmDel(context)),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModalRestTimerBox(
      BuildContext context, StateSetter setModalState,
      {int flex = 1}) {
    final isRunning = _restStopwatch?.isRunning ?? false;
    final elapsed = _restStopwatch?.elapsed.inSeconds ?? 0;
    return Expanded(
        flex: flex,
        child: InkWell(
            onTap: () {
              setModalState(() => _toggleRestTimer());
            },
            child: Container(
                height: 64,
                decoration: BoxDecoration(
                    color: isRunning
                        ? LabColors.primary.withValues(alpha: 0.1)
                        : LabColors.surfaceContainerHigh,
                    border: Border.all(
                        color:
                            isRunning ? LabColors.primary : Colors.grey[800]!,
                        width: 0.5)),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('REST_TIMER',
                          style: LabStyles.mono(context,
                              fontSize: 7,
                              color:
                                  isRunning ? LabColors.primary : Colors.grey)),
                      const SizedBox(height: 4),
                      Text(isRunning ? "${elapsed}S" : "START",
                          style: LabStyles.mono(context,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color:
                                  isRunning ? Colors.white : LabColors.primary))
                    ]))));
  }

  Widget _buildModalGridInput(
      BuildContext context, String l, TextEditingController c) {
    return Container(
        decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[800]!, width: 0.5)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4),
              color: LabColors.surfaceContainerHigh,
              child: Text(l,
                  textAlign: TextAlign.center,
                  style: LabStyles.mono(context,
                      fontSize: 8, color: Colors.grey))),
          Container(
              height: 44,
              alignment: Alignment.center,
              child: TextField(
                  controller: c,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: LabStyles.mono(context,
                      fontSize: 20, color: Colors.white),
                  decoration: const InputDecoration(
                      border: InputBorder.none, isDense: true),
                  onChanged: (_) => _onChanged()))
        ]));
  }

  Widget _buildModalAcousticCard(
      BuildContext context, StateSetter setModalState) {
    final db = ref.read(databaseProvider);
    return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: LabColors.surfaceContainerLow,
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.1), width: 0.5)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('ACOUSTIC',
                style:
                    LabStyles.mono(context, fontSize: 8, color: Colors.grey)),
            Row(
                children: List.generate(7, (i) {
              final lvl = i + 1;
              final lit = (widget.set.hypeLevel ?? 0) >= lvl;
              return GestureDetector(
                  onTap: () async {
                    await db.update(db.workoutSets).replace(
                        widget.set.copyWith(hypeLevel: drift.Value(lvl)));
                    setModalState(() {});
                  },
                  child: Container(
                      width: 14,
                      height: 14,
                      margin: const EdgeInsets.only(left: 4),
                      decoration: BoxDecoration(
                          color: lit ? LabColors.primary : Colors.transparent,
                          border: Border.all(
                              color:
                                  lit ? LabColors.primary : Colors.grey[800]!,
                              width: 0.5))));
            }))
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: TextField(
                    controller: _tC,
                    style: LabStyles.mono(context,
                        fontSize: 10, color: Colors.white),
                    decoration: InputDecoration(
                        hintText: 'TRACK_NAME',
                        hintStyle: LabStyles.mono(context,
                            fontSize: 8, color: Colors.grey[700]!),
                        isDense: true,
                        prefixIcon: const Icon(Icons.music_note,
                            size: 14, color: Colors.grey),
                        enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey[800]!))),
                    onChanged: (_) => _onChanged())),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.manage_search,
                  color: LabColors.primary, size: 18),
              onPressed: () {
                _showTrackSearchOverlay();
                setModalState(() {});
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            ),
            const SizedBox(width: 12),
            GestureDetector(
                onTap: () async {
                  await db.update(db.workoutSets).replace(
                      widget.set.copyWith(isPrSong: !widget.set.isPrSong));
                  setModalState(() {});
                },
                child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: widget.set.isPrSong
                            ? LabColors.accent.withValues(alpha: 0.1)
                            : Colors.transparent,
                        border: Border.all(
                            color: widget.set.isPrSong
                                ? LabColors.accent
                                : Colors.grey[800]!,
                            width: 0.5)),
                    child: Icon(
                        widget.set.isPrSong
                            ? Icons.music_note
                            : Icons.music_note_outlined,
                        color: widget.set.isPrSong
                            ? LabColors.accent
                            : Colors.grey[600],
                        size: 16))),
          ])
        ]));
  }

  Widget _buildModCard(BuildContext context, String label, IconData icon,
      Color color, VoidCallback onTap) {
    return Material(
      color: LabColors.surfaceContainerHigh,
      child: InkWell(
        onTap: () {
          onTap();
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(label,
                style: LabStyles.mono(context,
                    fontSize: 8, color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Future<void> _moveSetToExtreme(bool toTop) async {
    final db = ref.read(databaseProvider);
    final today = DateTime(widget.set.timestamp.year,
        widget.set.timestamp.month, widget.set.timestamp.day);
    final nextDay = today.add(const Duration(days: 1));
    final sets = await (db.select(db.workoutSets)
          ..where((t) =>
              t.baseExerciseId.equals(widget.exercise.id) &
              t.timestamp.isBetweenValues(today, nextDay))
          ..orderBy([
            (t) => drift.OrderingTerm.asc(t.orderIndex),
            (t) => drift.OrderingTerm.asc(t.timestamp)
          ]))
        .get();

    final currentIndex = sets.indexWhere((s) => s.id == widget.set.id);
    if (currentIndex == -1) return;

    final List<int> ids = sets.map((s) => s.id).toList();
    final targetId = ids.removeAt(currentIndex);
    if (toTop) {
      ids.insert(0, targetId);
    } else {
      ids.add(targetId);
    }

    await db.transaction(() async {
      for (int i = 0; i < ids.length; i++) {
        await (db.update(db.workoutSets)..where((t) => t.id.equals(ids[i])))
            .write(WorkoutSetsCompanion(orderIndex: drift.Value(i)));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final intentionText = widget.exercise.intention ?? '';
    final metaMatch =
        RegExp(r'\[NT:(.*)\|ISO:(.*)\]').firstMatch(intentionText);
    final isL =
        (metaMatch?.group(1) == 'LASTRE') || widget.exercise.field == 'LASTRE';
    final isJst =
        (metaMatch?.group(1) == 'JST.BW') || widget.exercise.field == 'JST.BW';
    final isIso = (metaMatch?.group(2) == 'true') ||
        (widget.exercise.intention ?? '').contains('[ISO]');
    final w = isJst ? widget.bodyWeight : (double.tryParse(_lC.text) ?? 0);
    final tL = w + (isL ? widget.bodyWeight : 0);
    final isRed = (widget.set.trackName ?? '').contains('[RED_PR]');

    final settings = ref.watch(themeSettingsProvider).value ?? {};
    final tC = ref.read(themeControllerProvider);
    final completedColor = tC.getColor(settings, 'UI_TAG_SET_COMPLETED',
        defaultColor: Colors.greenAccent);
    Color? sideColor;
    if (widget.side == "RIGHT") {
      sideColor =
          tC.getColor(settings, "UI_UNILATERAL_RIGHT", nameSeed: "RIGHT");
    } else if (widget.side == "LEFT") {
      sideColor = tC.getColor(settings, "UI_UNILATERAL_LEFT", nameSeed: "LEFT");
    }

    return Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                decoration: BoxDecoration(
                    border: Border.all(
                        color: isRed
                            ? Colors.redAccent
                            : (_exp
                                ? LabColors.primary.withValues(alpha: 0.4)
                                : Colors.grey[800]!),
                        width: isRed ? 2 : 0.5),
                    color: isRed
                        ? Colors.redAccent.withValues(alpha: 0.08)
                        : (_exp
                            ? LabColors.surfaceContainerLow
                            : Colors.transparent),
                    boxShadow: isRed
                        ? [
                            BoxShadow(
                                color:
                                    Colors.redAccent.withValues(alpha: 0.275),
                                blurRadius: 14)
                          ]
                        : (_exp
                            ? [
                                BoxShadow(
                                    color: LabColors.primary
                                        .withValues(alpha: 0.05),
                                    blurRadius: 6)
                              ]
                            : null)),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSetNumberWithCheckbox(completedColor,
                          (widget.index + 1).toString().padLeft(2, '0'),
                          flex: 15, sideColor: sideColor),
                      _buildGridInput(
                          isJst ? 'BODYWEIGHT' : (isL ? 'ADDED' : 'LOAD'), _lC,
                          flex: 27, enabled: !isJst),
                      _buildGridInput(isIso ? 'SECS' : 'REPS', _rC, flex: 30),
                      _buildPRBox(flex: 25, isRed: isRed),
                      _buildCompletedCheck(completedColor),
                    ],
                  ),
                ),
              ),
              if (_showComment)
                Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: LabColors.surfaceDim,
                        border: Border(
                            left: const BorderSide(
                                color: LabColors.primary, width: 1),
                            bottom: BorderSide(
                                color: Colors.grey[900]!, width: 0.5),
                            right: BorderSide(
                                color: Colors.grey[900]!, width: 0.5))),
                    child: TextField(
                        controller: _commentC,
                        maxLines: null,
                        style: LabStyles.mono(context,
                            fontSize: 10, color: Colors.white),
                        decoration: InputDecoration(
                            hintText: 'WRITE_SESSION_INTEL...',
                            hintStyle: LabStyles.mono(context,
                                fontSize: 8, color: Colors.grey[700]!),
                            border: InputBorder.none,
                            isDense: true),
                        onChanged: (_) => _onChanged())),
              if (_exp) ...[
                const SizedBox(height: 12),
                Row(children: [
                  _buildSummaryBox(
                      'TONNAGE',
                      (tL * (double.tryParse(_rC.text) ?? 0))
                          .toStringAsFixed(1)),
                  const SizedBox(width: 4),
                  _buildSummaryBox(
                      'eORM',
                      WorkoutCalculator.calculateEpley1RM(
                              tL, double.tryParse(_rC.text) ?? 0)
                          .toStringAsFixed(1)),
                ]),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[700]!, width: 0.5),
                    color: LabColors.surfaceContainerLow,
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        _buildGridInput('RPE', _rpeC, flex: 1, noBorder: true),
                        if (!_isIso) ...[
                          Container(width: 0.5, color: Colors.grey[700]),
                          _buildGridInput('RIR', _rirC,
                              flex: 1, noBorder: true),
                        ],
                        Container(width: 0.5, color: Colors.grey[700]),
                        _buildGridInput('TECH', _techC,
                            flex: 1, noBorder: true),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildSomaticCard(),
                const SizedBox(height: 8),
                _buildNotesToggleCard(),
                const SizedBox(height: 12),
                _buildFailurePhaseCard(),
                _buildComplexSetModsButton(),
                const SizedBox(height: 12),
                _buildParticularTogglesCard(),
                const SizedBox(height: 20),
              ]
            ])));
  }

  Widget _buildParticularTogglesCard() {
    final Map<String, dynamic> exerciseMeta =
        widget.exercise.parsedComplexMetadata;
    final List<dynamic> rawToggles = exerciseMeta["particular_toggles"] ?? [];

    if (rawToggles.isEmpty) return const SizedBox.shrink();

    // Map new format or legacy string format to just names for the UI list
    final List<String> availableToggles = rawToggles
        .map((t) => (t is Map) ? (t["name"] as String) : (t.toString()))
        .toList();

    Map<String, dynamic> setMeta = {};
    if (widget.set.complexMetadata != null &&
        widget.set.complexMetadata!.isNotEmpty) {
      try {
        setMeta = jsonDecode(widget.set.complexMetadata!);
      } catch (_) {}
    }
    final Map<String, bool> states = {
      for (var t in availableToggles) t: (setMeta[t] == true)
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LabColors.surfaceContainerLow,
        border: Border.all(
            color: Colors.cyanAccent.withValues(alpha: 0.1), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TOGGLES',
              style: LabStyles.mono(context, fontSize: 8, color: Colors.grey)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: availableToggles.map((t) {
              final active = states[t] ?? false;
              return GestureDetector(
                onTap: () => _toggleParticularValue(t, !active),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: active
                        ? Colors.cyanAccent.withValues(alpha: 0.2)
                        : Colors.black,
                    border: Border.all(
                        color: active ? Colors.cyanAccent : Colors.grey[800]!,
                        width: 0.5),
                  ),
                  child: Text(
                    t,
                    style: LabStyles.mono(context,
                        fontSize: 8,
                        color: active ? Colors.cyanAccent : Colors.grey[400]!),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleParticularValue(String key, bool value) async {
    Map<String, dynamic> setMeta = {};
    if (widget.set.complexMetadata != null &&
        widget.set.complexMetadata!.isNotEmpty) {
      try {
        setMeta = jsonDecode(widget.set.complexMetadata!);
      } catch (_) {}
    }
    setMeta[key] = value;
    final db = ref.read(databaseProvider);
    await (db.update(db.workoutSets)..where((t) => t.id.equals(widget.set.id)))
        .write(WorkoutSetsCompanion(
            complexMetadata: drift.Value(jsonEncode(setMeta))));
  }

  Widget _buildRestTimerBox({int flex = 1}) {
    final isRunning = _restStopwatch?.isRunning ?? false;
    final elapsed = _restStopwatch?.elapsed.inSeconds ?? 0;
    return Expanded(
        flex: flex,
        child: InkWell(
            onTap: _toggleRestTimer,
            child: Container(
                height: 64,
                decoration: BoxDecoration(
                    color: isRunning
                        ? LabColors.primary.withValues(alpha: 0.1)
                        : LabColors.surfaceContainerHigh,
                    border: Border.all(
                        color:
                            isRunning ? LabColors.primary : Colors.grey[800]!,
                        width: 0.5)),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('REST_TIMER',
                          style: LabStyles.mono(context,
                              fontSize: 7,
                              color:
                                  isRunning ? LabColors.primary : Colors.grey)),
                      const SizedBox(height: 4),
                      Text(isRunning ? "${elapsed}S" : "START",
                          style: LabStyles.mono(context,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color:
                                  isRunning ? Colors.white : LabColors.primary))
                    ]))));
  }

  Widget _buildNotesToggleCard() {
    final hasNotes = widget.set.notes?.isNotEmpty ?? false;
    return InkWell(
        onTap: () => setState(() => _showComment = !_showComment),
        child: Container(
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                border:
                    Border.all(color: LabColors.primary.withValues(alpha: 0.5)),
                color: _showComment
                    ? LabColors.primary.withValues(alpha: 0.05)
                    : Colors.transparent),
            child: Text(
                hasNotes ? '[ ! ] EDIT SET NOTES' : '[ + ] ADD SET NOTES',
                textAlign: TextAlign.center,
                style: LabStyles.mono(context,
                    fontSize: 8, color: LabColors.primary))));
  }

  Widget _buildSetNumberWithCheckbox(Color completedColor, String value,
      {int flex = 2, Color? sideColor}) {
    final globalNum = widget.globalIndex;
    return Expanded(
      flex: flex,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            border:
                Border(right: BorderSide(color: Colors.grey[800]!, width: 0.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // TOP: Global set number (session-wide)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 4),
                color: LabColors.surfaceContainerHigh,
                alignment: Alignment.center,
                child: Text(
                  "#$globalNum",
                  style:
                      LabStyles.mono(context, fontSize: 8, color: Colors.grey),
                ),
              ),
              // BOTTOM: Intra-card Set Number (tap to expand/collapse)
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _exp = !_exp),
                  child: Container(
                    alignment: Alignment.center,
                    child: Text(
                      value,
                      style: LabStyles.mono(context,
                          fontSize: 18,
                          color: sideColor ?? Colors.white,
                          fontWeight: sideColor != null
                              ? FontWeight.bold
                              : FontWeight.normal),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedCheck(Color completedColor) {
    final done = widget.set.isCompleted;
    return Padding(
      padding: const EdgeInsets.all(4.8),
      child: SizedBox(
        width: 32,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _setCompleted(!done),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: done
                  ? completedColor.withValues(alpha: 0.18)
                  : Colors.transparent,
              border: Border(
                  left: BorderSide(color: Colors.grey[800]!, width: 0.5)),
            ),
            child: done
                ? Icon(Icons.check, size: 18, color: completedColor)
                : const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }

  void _setCompleted(bool completed) {
    if (!mounted) return;
    setState(() {});

    final db = ref.read(databaseProvider);
    unawaited((db.update(db.workoutSets)
          ..where((t) => t.id.equals(widget.set.id)))
        .write(WorkoutSetsCompanion(isCompleted: drift.Value(completed))));
  }

  Widget _buildReorderColumn() {
    return Container(
      width: 32,
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: Colors.grey[800]!, width: 0.5)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildReorderArrow(Icons.arrow_drop_up, -1),
          _buildReorderArrow(Icons.arrow_drop_down, 1),
        ],
      ),
    );
  }

  Widget _buildReorderArrow(IconData icon, int offset) {
    return Expanded(
      child: InkWell(
        onTap: () => _moveSet(offset),
        child: Icon(icon,
            size: 16, color: LabColors.primary.withValues(alpha: 0.5)),
      ),
    );
  }

  Future<void> _moveSet(int direction) async {
    final db = ref.read(databaseProvider);
    final today = DateTime(widget.set.timestamp.year,
        widget.set.timestamp.month, widget.set.timestamp.day);
    final nextDay = today.add(const Duration(days: 1));
    final sets = await (db.select(db.workoutSets)
          ..where((t) =>
              t.baseExerciseId.equals(widget.exercise.id) &
              t.timestamp.isBetweenValues(today, nextDay))
          ..orderBy([
            (t) => drift.OrderingTerm.asc(t.orderIndex),
            (t) => drift.OrderingTerm.asc(t.timestamp)
          ]))
        .get();

    final currentIndex = sets.indexWhere((s) => s.id == widget.set.id);
    if (currentIndex == -1) return;
    final targetIndex = currentIndex + direction;
    if (targetIndex < 0 || targetIndex >= sets.length) return;

    final currentSet = sets[currentIndex];
    final otherSet = sets[targetIndex];

    int currentOrder =
        currentSet.orderIndex == 0 ? currentIndex : currentSet.orderIndex;
    int otherOrder =
        otherSet.orderIndex == 0 ? targetIndex : otherSet.orderIndex;
    if (currentOrder == otherOrder) {
      currentOrder = currentIndex;
      otherOrder = targetIndex;
    }

    await (db.update(db.workoutSets)..where((t) => t.id.equals(currentSet.id)))
        .write(WorkoutSetsCompanion(orderIndex: drift.Value(otherOrder)));
    await (db.update(db.workoutSets)..where((t) => t.id.equals(otherSet.id)))
        .write(WorkoutSetsCompanion(orderIndex: drift.Value(currentOrder)));
  }

  Widget _buildPRBox({int flex = 1, bool isRed = false}) {
    final hasPr = widget.set.isPr;
    final settings = ref.watch(themeSettingsProvider).value ?? {};
    final highlightColor = ref
        .read(themeControllerProvider)
        .getColor(settings, 'UI_EORM_HIGHLIGHT', nameSeed: 'EORM_HIGHLIGHT');
    const completedColor = Colors.greenAccent;

    return Expanded(
        flex: flex,
        child: Container(
            decoration: BoxDecoration(
                border: Border(
                    right: BorderSide(color: Colors.grey[800]!, width: 0.5))),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // TOP: PR label
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 4),
                color: isRed
                    ? highlightColor.withValues(alpha: 0.2)
                    : (hasPr
                        ? Colors.white.withValues(alpha: 0.05)
                        : LabColors.surfaceContainerHigh),
                child: Text('PR',
                    textAlign: TextAlign.center,
                    style: LabStyles.mono(context,
                        fontSize: 8,
                        color: isRed
                            ? Colors.white
                            : (hasPr ? LabColors.accent : Colors.grey))),
              ),
              // BOTTOM: Trophy / empty
              Container(
                  height: 44,
                  alignment: Alignment.center,
                  child: hasPr
                      ? (isRed
                          ? Icon(Icons.emoji_events,
                              color: highlightColor, size: 24)
                          : ShaderMask(
                              shaderCallback: (bounds) =>
                                  const LinearGradient(colors: [
                                    Colors.red,
                                    Colors.orange,
                                    Colors.yellow,
                                    Colors.green,
                                    Colors.blue,
                                    Colors.purple
                                  ]).createShader(bounds),
                              child: const Icon(Icons.emoji_events,
                                  color: Colors.white, size: 20)))
                      : const SizedBox())
            ])));
  }

  Widget _buildSummaryBox(String l, String v) {
    return Expanded(
        child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            decoration: BoxDecoration(
                color: LabColors.surfaceDim,
                border: Border.all(
                    color: LabColors.cyanBorder.withValues(alpha: 0.1),
                    width: 0.5)),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l,
                      style: LabStyles.mono(context,
                          fontSize: 7, color: Colors.grey)),
                  Text(v,
                      style: LabStyles.mono(context,
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold))
                ])));
  }

  Widget _buildGridInput(String l, TextEditingController c,
      {int flex = 1, bool enabled = true, bool noBorder = false}) {
    return Expanded(
        flex: flex,
        child: Container(
            decoration: BoxDecoration(
                border: noBorder
                    ? null
                    : Border(
                        right:
                            BorderSide(color: Colors.grey[800]!, width: 0.5))),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  color: LabColors.surfaceContainerHigh,
                  child: Text(l,
                      textAlign: TextAlign.center,
                      style: LabStyles.mono(context,
                          fontSize: 8, color: Colors.grey))),
              Container(
                  height: 44,
                  alignment: Alignment.center,
                  child: TextField(
                      controller: c,
                      enabled: enabled,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: LabStyles.mono(context,
                          fontSize: 20,
                          color: enabled ? Colors.white : Colors.grey),
                      decoration: const InputDecoration(
                          border: InputBorder.none, isDense: true),
                      onChanged: (_) => _onChanged()))
            ])));
  }

  void _confirmDel(BuildContext c) {
    showDialog(
        context: c,
        builder: (c) => AlertDialog(
                backgroundColor: LabColors.background,
                title: Text('PURGE_SET',
                    style: LabStyles.mono(context, color: Colors.redAccent)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c),
                      child: const Text('ABORT')),
                  TextButton(
                      onPressed: () async {
                        await (ref
                                .read(databaseProvider)
                                .delete(ref.read(databaseProvider).workoutSets)
                              ..where((t) => t.id.equals(widget.set.id)))
                            .go();
                        Navigator.pop(c);
                      },
                      child: const Text('PURGE'))
                ]));
  }

  Widget _buildFailurePhaseCard() {
    Map<String, dynamic> phs = {};
    if (widget.exercise.phaseDescriptions != null) {
      try {
        final Map<String, dynamic> meta =
            jsonDecode(widget.exercise.phaseDescriptions!);
        phs = meta["phases"] as Map<String, dynamic>? ?? {};
      } catch (_) {}
    }
    final cnt = widget.exercise.numPhases ?? (phs.isEmpty ? 1 : phs.length);
    return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: LabColors.surfaceContainerLow,
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.1), width: 0.5)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('FAILURE PHASE',
              style: LabStyles.mono(context, fontSize: 8, color: Colors.grey)),
          const SizedBox(height: 12),
          GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisExtent: 40,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8),
              itemCount: cnt,
              itemBuilder: (c, i) {
                final pI = i + 1;
                final sel = widget.set.failurePhase == pI;
                final name = (phs[pI.toString()] ?? 'PHASE_$pI')
                    .toString()
                    .toUpperCase();
                return GestureDetector(
                    onTap: () async {
                      await (ref
                              .read(databaseProvider)
                              .update(ref.read(databaseProvider).workoutSets)
                            ..where((t) => t.id.equals(widget.set.id)))
                          .write(WorkoutSetsCompanion(
                              failurePhase: drift.Value(pI)));
                    },
                    child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                            color: sel
                                ? LabColors.primary.withValues(alpha: 0.2)
                                : Colors.black,
                            border: Border.all(
                                color:
                                    sel ? LabColors.primary : Colors.grey[800]!,
                                width: 0.5)),
                        child: Center(
                            child: Text(name,
                                style: LabStyles.mono(context,
                                    fontSize: 8,
                                    color: sel
                                        ? LabColors.primary
                                        : Colors.grey[400]!)))));
              })
        ]));
  }

  Widget _buildComplexSetModsButton() {
    return Container(
        width: double.infinity,
        decoration: BoxDecoration(
            border: Border.all(
                color: Colors.cyanAccent.withValues(alpha: 0.15), width: 0.5)),
        child: Material(
            color: Colors.black,
            child: InkWell(
                onTap: () => _showComplexSetModsModal(context),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.tune,
                            size: 14, color: LabColors.primary),
                        const SizedBox(width: 8),
                        Text('COMPLEX_SET_MODS',
                            style: LabStyles.mono(context,
                                fontSize: 10, color: LabColors.primary)),
                      ]),
                ))));
  }

  Widget _buildAcousticCard() {
    final db = ref.read(databaseProvider);
    return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: LabColors.surfaceContainerLow,
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.1), width: 0.5)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('ACOUSTIC',
                style:
                    LabStyles.mono(context, fontSize: 8, color: Colors.grey)),
            Row(
                children: List.generate(7, (i) {
              final lvl = i + 1;
              final lit = (widget.set.hypeLevel ?? 0) >= lvl;
              return GestureDetector(
                  onTap: () async {
                    await db.update(db.workoutSets).replace(
                        widget.set.copyWith(hypeLevel: drift.Value(lvl)));
                  },
                  child: Container(
                      width: 14,
                      height: 14,
                      margin: const EdgeInsets.only(left: 4),
                      decoration: BoxDecoration(
                          color: lit ? LabColors.primary : Colors.transparent,
                          border: Border.all(
                              color:
                                  lit ? LabColors.primary : Colors.grey[800]!,
                              width: 0.5))));
            }))
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: TextField(
                    controller: _tC,
                    style: LabStyles.mono(context,
                        fontSize: 10, color: Colors.white),
                    decoration: InputDecoration(
                        hintText: 'TRACK_NAME',
                        hintStyle: LabStyles.mono(context,
                            fontSize: 8, color: Colors.grey[700]!),
                        isDense: true,
                        prefixIcon: const Icon(Icons.music_note,
                            size: 14, color: Colors.grey),
                        enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey[800]!))),
                    onChanged: (_) => _onChanged())),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.manage_search,
                  color: LabColors.primary, size: 18),
              onPressed: _showTrackSearchOverlay,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            ),
            const SizedBox(width: 12),
            GestureDetector(
                onTap: () async {
                  await db.update(db.workoutSets).replace(
                      widget.set.copyWith(isPrSong: !widget.set.isPrSong));
                },
                child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: widget.set.isPrSong
                            ? LabColors.accent.withValues(alpha: 0.1)
                            : Colors.transparent,
                        border: Border.all(
                            color: widget.set.isPrSong
                                ? LabColors.accent
                                : Colors.grey[800]!,
                            width: 0.5)),
                    child: Icon(
                        widget.set.isPrSong
                            ? Icons.music_note
                            : Icons.music_note_outlined,
                        color: widget.set.isPrSong
                            ? LabColors.accent
                            : Colors.grey[600],
                        size: 16))),
          ])
        ]));
  }

  Widget _buildSomaticCard() {
    final db = ref.read(databaseProvider);
    return FutureBuilder<List<drift.QueryRow>>(
        future: db
            .customSelect(
                "SELECT id, description, spectrum_value, tags FROM somatic_logs WHERE set_id = ${widget.set.id} ORDER BY created_at DESC")
            .get(),
        builder: (context, snapshot) {
          final allLogs = snapshot.data ?? [];
          final anomalies = allLogs
              .where((r) => (r.data['spectrum_value'] as int) < 0)
              .toList();
          final recoveries = allLogs
              .where((r) => (r.data['spectrum_value'] as int) > 0)
              .toList();

          return Row(
            children: [
              Expanded(
                child: anomalies.isEmpty
                    ? InkWell(
                        onTap: () => _showDiscomfortOverlay(context, false),
                        child: Container(
                          height: 52,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              border: Border.all(
                                  color:
                                      Colors.redAccent.withValues(alpha: 0.5))),
                          child: Text('[ + ] SOMATIC ANOMALY',
                              textAlign: TextAlign.center,
                              style: LabStyles.mono(context,
                                  fontSize: 7.68, color: Colors.redAccent)),
                        ),
                      )
                    : InkWell(
                        onTap: () => _showDiscomfortOverlay(context, false),
                        child: Container(
                          height: 52,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.1),
                              border: Border.all(
                                  color: Colors.redAccent, width: 1)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                  child: Text(
                                      'SOMATIC_ANOMALIES: ${anomalies.length}',
                                      style: LabStyles.mono(context,
                                          fontSize: 6.72,
                                          color: Colors.redAccent,
                                          fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis)),
                              Text('EDIT',
                                  style: LabStyles.mono(context,
                                      fontSize: 6.72,
                                      color: Colors.white70,
                                      decoration: TextDecoration.underline)),
                            ],
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: recoveries.isEmpty
                    ? InkWell(
                        onTap: () => _showDiscomfortOverlay(context, true),
                        child: Container(
                          height: 52,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              border: Border.all(
                                  color: Colors.greenAccent
                                      .withValues(alpha: 0.5))),
                          child: Text('[ + ] SOMATIC RECOVERY',
                              textAlign: TextAlign.center,
                              style: LabStyles.mono(context,
                                  fontSize: 7.68, color: Colors.greenAccent)),
                        ),
                      )
                    : InkWell(
                        onTap: () => _showDiscomfortOverlay(context, true),
                        child: Container(
                          height: 52,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                              color: Colors.greenAccent.withValues(alpha: 0.1),
                              border: Border.all(
                                  color: Colors.greenAccent, width: 1)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                  child: Text(
                                      'SOMATIC_RECOVERIES: ${recoveries.length}',
                                      style: LabStyles.mono(context,
                                          fontSize: 6.72,
                                          color: Colors.greenAccent,
                                          fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis)),
                              Text('EDIT',
                                  style: LabStyles.mono(context,
                                      fontSize: 6.72,
                                      color: Colors.white70,
                                      decoration: TextDecoration.underline)),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          );
        });
  }

  void _showDiscomfortOverlay(BuildContext context, bool isRecovery) {
    final db = ref.read(databaseProvider);
    final dC = TextEditingController();
    final tC = TextEditingController();
    int selectedIntensity = 5;
    int? editingLogId;
    int? _selectedFolderId;

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (c) => StatefulBuilder(
            builder: (context, setModalState) => Container(
                height: MediaQuery.of(context).size.height * 0.85,
                decoration: BoxDecoration(
                    color: LabColors.background,
                    border: Border(
                        top: BorderSide(
                            color: isRecovery
                                ? Colors.greenAccent
                                : Colors.redAccent,
                            width: 2))),
                padding: const EdgeInsets.all(24),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              editingLogId != null
                                  ? 'EDIT'
                                  : (isRecovery
                                      ? 'SOMATIC_RECOVERY_REGISTRATION'
                                      : 'SOMATIC_ANOMALY_REGISTRATION'),
                              style: LabStyles.headline(context,
                                      color: isRecovery
                                          ? Colors.greenAccent
                                          : Colors.redAccent)
                                  .copyWith(fontSize: 16.8),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (editingLogId != null)
                            TextButton(
                              onPressed: () => setModalState(() {
                                editingLogId = null;
                                dC.clear();
                                tC.clear();
                                selectedIntensity = 5;
                              }),
                              child: Text("CANCEL_EDIT",
                                  style: LabStyles.mono(context,
                                      fontSize: 9.6,
                                      color: Colors.orangeAccent)),
                            ),
                          IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close,
                                  color: Colors.grey, size: 20)),
                        ],
                      ),
                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Text(
                              isRecovery
                                  ? 'SPECTRUM_VALUE'
                                  : 'INTENSITY_LEVEL (1-10)',
                              style: LabStyles.mono(context,
                                  fontSize: 9.6,
                                  color: isRecovery
                                      ? Colors.greenAccent
                                      : Colors.grey)),
                          const Spacer(),
                          GestureDetector(
                            onTap: () =>
                                _showSpectrumReferencePopup(context, db),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                  border: Border.all(
                                      color: isRecovery
                                          ? Colors.greenAccent
                                              .withValues(alpha: 0.3)
                                          : Colors.redAccent
                                              .withValues(alpha: 0.3),
                                      width: 0.5)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.info_outline,
                                      size: 10,
                                      color: isRecovery
                                          ? Colors.greenAccent
                                          : Colors.redAccent),
                                  const SizedBox(width: 4),
                                  Text('REF',
                                      style: LabStyles.mono(context,
                                          fontSize: 8.4,
                                          color: isRecovery
                                              ? Colors.greenAccent
                                              : Colors.redAccent)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(10, (i) {
                            final val = i + 1;
                            final isSelected = selectedIntensity >= val;
                            return GestureDetector(
                                onTap: () => setModalState(
                                    () => selectedIntensity = val),
                                child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                        color: isSelected
                                            ? (isRecovery
                                                ? Colors.greenAccent
                                                : Colors.redAccent)
                                            : Colors.transparent,
                                        border: Border.all(
                                            color: isRecovery
                                                ? Colors.greenAccent
                                                : Colors.redAccent,
                                            width: 0.5)),
                                    child: Center(
                                        child: Text("$val",
                                            style: LabStyles.mono(context,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: isSelected
                                                    ? Colors.black
                                                    : Colors.white)))));
                          })),
                      const SizedBox(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                              child: LabTextField(
                                  controller: dC,
                                  label: 'DESCRIPTION',
                                  fontSize: 16.8,
                                  labelFontSize: 9.6,
                                  hintFontSize: 14.4)),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 48,
                            height: 42,
                            child: _QuickActionButton(
                              label: "SEARCH",
                              icon: Icons.search,
                              color: LabColors.accent,
                              fontSize: 8.4,
                              onTap: () async {
                                final rows = await db.executor.runSelect(
                                  "SELECT DISTINCT description FROM somatic_logs WHERE description IS NOT NULL AND description != ''",
                                  [],
                                );
                                final descs = rows
                                    .map((r) => r['description'] as String)
                                    .toList()
                                  ..sort();
                                if (!context.mounted) return;
                                showModalBottomSheet(
                                  context: context,
                                  backgroundColor: LabColors.background,
                                  isScrollControlled: true,
                                  builder: (c) => QualitySearchPicker(
                                    title: "SELECT_DESCRIPTION",
                                    values: descs,
                                    onSelected: (val) =>
                                        setModalState(() => dC.text = val),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                              child: LabTextField(
                                  controller: tC,
                                  label: 'TAGS (COMMA_SEPARATED)',
                                  fontSize: 16.8,
                                  labelFontSize: 9.6,
                                  hintFontSize: 14.4)),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 48,
                            height: 42,
                            child: _QuickActionButton(
                              label: "SEARCH",
                              icon: Icons.tag,
                              color: Colors.purpleAccent,
                              fontSize: 8.4,
                              onTap: () async {
                                final rows = await db.executor.runSelect(
                                  "SELECT DISTINCT tags FROM somatic_logs WHERE tags IS NOT NULL AND tags != ''",
                                  [],
                                );
                                final tagNames = rows
                                    .expand((r) => ((r['tags'] ?? '') as String)
                                        .split(RegExp(r',\s*'))
                                        .where((t) => t.trim().isNotEmpty))
                                    .map((t) => t.trim())
                                    .toSet()
                                    .toList()
                                  ..sort();
                                if (!context.mounted) return;
                                showModalBottomSheet(
                                  context: context,
                                  backgroundColor: LabColors.background,
                                  isScrollControlled: true,
                                  builder: (c) => QualitySearchPicker(
                                    title: "SELECT_TAG",
                                    values: tagNames,
                                    onSelected: (val) {
                                      setModalState(() {
                                        final current = tC.text
                                            .split(RegExp(r',\s*'))
                                            .where((t) => t.trim().isNotEmpty)
                                            .toList();
                                        if (!current.contains(val)) {
                                          current.add(val);
                                          tC.text = current.join(", ");
                                        }
                                      });
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      // Folder picker
                      Row(
                        children: [
                          Expanded(
                            child: FutureBuilder<List<drift.QueryRow>>(
                              future: db
                                  .customSelect(
                                      'SELECT id, name FROM somatic_folders ORDER BY name')
                                  .get(),
                              builder: (c, snap) {
                                final folders = snap.data ?? [];
                                return DropdownButtonFormField<int>(
                                  value: _selectedFolderId,
                                  dropdownColor: LabColors.background,
                                  style: LabStyles.mono(c,
                                      fontSize: 12, color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: 'FOLDER (OPTIONAL)',
                                    labelStyle: LabStyles.mono(c,
                                        fontSize: 9.6, color: Colors.grey),
                                    border: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Colors.white12, width: 0.5)),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    isDense: true,
                                  ),
                                  items: folders
                                      .map((r) => DropdownMenuItem(
                                            value: r.data['id'] as int,
                                            child: Text(
                                                (r.data['name'] as String)
                                                    .toUpperCase(),
                                                style: LabStyles.mono(c,
                                                    fontSize: 10.8,
                                                    color: Colors.white)),
                                          ))
                                      .toList(),
                                  onChanged: (v) => setModalState(
                                      () => _selectedFolderId = v),
                                );
                              },
                            ),
                          ),
                          if (_selectedFolderId != null)
                            IconButton(
                              icon: const Icon(Icons.close,
                                  size: 14, color: Colors.grey),
                              onPressed: () =>
                                  setModalState(() => _selectedFolderId = null),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 16),

                      Expanded(
                        child: StreamBuilder<List<drift.QueryRow>>(
                          stream: db
                              .customSelect(
                                "SELECT id, set_id, description, spectrum_value, tags, created_at FROM somatic_logs WHERE set_id = ${widget.set.id} AND spectrum_value ${isRecovery ? '> 0' : '< 0'} ORDER BY created_at DESC",
                              )
                              .watch(),
                          builder: (context, snapshot) {
                            final rows = snapshot.data ?? [];
                            if (rows.isEmpty)
                              return Center(
                                  child: Text(
                                      isRecovery
                                          ? "NO_RECOVERY_LOGS_YET"
                                          : "NO_ANOMALIES_REGISTERED_YET",
                                      style: LabStyles.mono(context,
                                          fontSize: 9.6,
                                          color: Colors.grey[800]!)));
                            return ListView.builder(
                              itemCount: rows.length,
                              itemBuilder: (context, index) {
                                final row = rows[index];
                                final logId = row.data['id'] as int;
                                final logDescription =
                                    row.data['description'] as String;
                                final logSpectrum =
                                    row.data['spectrum_value'] as int;
                                final logTags =
                                    (row.data['tags'] as String?) ?? '';
                                final isRecovery = logSpectrum > 0;
                                final isEditingThis = editingLogId == logId;
                                return InkWell(
                                  onTap: () async {
                                    setModalState(() {
                                      editingLogId = logId;
                                      dC.text = logDescription;
                                      selectedIntensity = isRecovery
                                          ? logSpectrum
                                          : logSpectrum.abs();
                                      tC.text = logTags;
                                    });
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                        color: isEditingThis
                                            ? (isRecovery
                                                    ? Colors.greenAccent
                                                    : Colors.redAccent)
                                                .withValues(alpha: 0.1)
                                            : Colors.white
                                                .withValues(alpha: 0.05),
                                        border: Border.all(
                                            color: isEditingThis
                                                ? (isRecovery
                                                    ? Colors.greenAccent
                                                    : Colors.redAccent)
                                                : Colors.white10,
                                            width: 0.5)),
                                    child: Row(
                                      children: [
                                        Container(
                                            width: 3,
                                            height: 20,
                                            color: isRecovery
                                                ? Colors.greenAccent
                                                : Colors.redAccent),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(logDescription.toUpperCase(),
                                                  style: LabStyles.mono(context,
                                                      fontSize: 10.8,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: isEditingThis
                                                          ? (isRecovery
                                                              ? Colors
                                                                  .greenAccent
                                                              : Colors
                                                                  .redAccent)
                                                          : Colors.white)),
                                              Text("SPECTRUM: $logSpectrum",
                                                  style: LabStyles.mono(context,
                                                      fontSize: 9.6,
                                                      color: Colors.grey)),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline,
                                              color: Colors.redAccent,
                                              size: 16),
                                          onPressed: () async {
                                            await db.customStatement(
                                                'DELETE FROM somatic_logs WHERE id = $logId');
                                            if (editingLogId == logId) {
                                              setModalState(() {
                                                editingLogId = null;
                                                dC.clear();
                                                tC.clear();
                                                selectedIntensity = 5;
                                              });
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 16),
                      LabButton(
                          label: editingLogId != null
                              ? (isRecovery ? 'UPDATE_RECOVERY' : 'UPDATE')
                              : (isRecovery
                                  ? 'REGISTER_RECOVERY'
                                  : 'REGISTER_ANOMALY'),
                          color: isRecovery
                              ? Colors.greenAccent
                              : Colors.redAccent,
                          fontSize: 14.4,
                          onPressed: () async {
                            if (dC.text.trim().isEmpty) return;

                            final now = DateTime.now().millisecondsSinceEpoch;
                            final spectrumVal = isRecovery
                                ? selectedIntensity
                                : -selectedIntensity;
                            final tagsStr = tC.text.trim();

                            if (editingLogId != null) {
                              await db.customStatement(
                                "UPDATE somatic_logs SET description = '${dC.text.replaceAll("'", "''")}', spectrum_value = $spectrumVal, tags = '${tagsStr.replaceAll("'", "''")}' WHERE id = ${editingLogId!}",
                              );
                            } else {
                              await db.customStatement(
                                "INSERT INTO somatic_logs (set_id, description, spectrum_value, tags, created_at) VALUES (${widget.set.id}, '${dC.text.replaceAll("'", "''")}', $spectrumVal, '${tagsStr.replaceAll("'", "''")}', $now)",
                              );
                              if (_selectedFolderId != null) {
                                final idRows = await db.executor.runSelect(
                                    'SELECT last_insert_rowid() AS id', []);
                                if (idRows.isNotEmpty) {
                                  final newLogId = idRows.first['id'] as int;
                                  await db.customStatement(
                                    "INSERT OR IGNORE INTO somatic_folder_logs (folder_id, log_id) VALUES ($_selectedFolderId, $newLogId)",
                                  );
                                }
                              }
                            }

                            setModalState(() {
                              editingLogId = null;
                              dC.clear();
                              tC.clear();
                              selectedIntensity = 5;
                            });
                          }),
                      const SizedBox(height: 8),
                      LabButton(
                          label: 'CLOSE',
                          isOutlined: true,
                          color: Colors.grey,
                          fontSize: 14.4,
                          onPressed: () => Navigator.pop(context)),
                    ]))));
  }

  Future<void> _showSpectrumReferencePopup(
      BuildContext context, AppDatabase db) async {
    final refs = await db
        .customSelect(
            'SELECT value, label, description FROM spectrum_references ORDER BY value')
        .get();
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: LabColors.background,
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('SPECTRUM_REFERENCES',
                      style: LabStyles.headline(c, color: Colors.white)
                          .copyWith(fontSize: 16.8)),
                  const Spacer(),
                  IconButton(
                      onPressed: () => Navigator.pop(c),
                      icon: const Icon(Icons.close,
                          color: Colors.grey, size: 18)),
                ],
              ),
              const Divider(color: Colors.white10),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  itemCount: refs.length,
                  separatorBuilder: (_, __) =>
                      const Divider(color: Colors.white10, height: 1),
                  itemBuilder: (c, i) {
                    final row = refs[i];
                    final val = row.data['value'] as int;
                    final label = row.data['label'] as String;
                    final desc = row.data['description'] as String;
                    Color vColor;
                    if (val < 0) {
                      final t = (val + 10) / 10.0;
                      vColor =
                          Color.lerp(Colors.redAccent, Colors.grey[600]!, t)!;
                    } else if (val == 0) {
                      vColor = Colors.grey[600]!;
                    } else {
                      vColor = Color.lerp(
                          Colors.greenAccent, Colors.blueAccent, val / 10.0)!;
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: vColor.withValues(alpha: 0.5),
                                  width: 0.5),
                              color: vColor.withValues(alpha: 0.1),
                            ),
                            child: Center(
                                child: Text('$val',
                                    style: LabStyles.mono(c,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: vColor))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(label,
                                    style: LabStyles.mono(c,
                                        fontSize: 10.8,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white)),
                                Text(desc,
                                    style: LabStyles.mono(c,
                                        fontSize: 9.6,
                                        color: Colors.grey[400]!)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double fontSize;

  const _QuickActionButton(
      {required this.label,
      required this.icon,
      required this.color,
      required this.onTap,
      this.fontSize = 7});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
            color: color.withValues(alpha: 0.05)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(height: 2),
            Text(label,
                style:
                    LabStyles.mono(context, fontSize: fontSize, color: color),
                textAlign: TextAlign.center,
                maxLines: 1),
          ],
        ),
      ),
    );
  }
}

class _UnilateralPairFrame extends ConsumerWidget {
  final Widget rightSet;
  final Widget leftSet;
  final int index;
  const _UnilateralPairFrame(
      {super.key,
      required this.rightSet,
      required this.leftSet,
      required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(themeSettingsProvider).value ?? {};
    final tC = ref.read(themeControllerProvider);
    final rightColor =
        tC.getColor(settings, "UI_UNILATERAL_RIGHT", nameSeed: "RIGHT");
    final leftColor =
        tC.getColor(settings, "UI_UNILATERAL_LEFT", nameSeed: "LEFT");

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        border: Border.all(
            color: LabColors.primary.withValues(alpha: 0.15), width: 1),
      ),
      child: Column(
        children: [
          _SideLabel(label: "RIGHT_SIDE", color: rightColor),
          rightSet,
          const Divider(height: 16, color: Colors.white10, thickness: 0.5),
          _SideLabel(label: "LEFT_SIDE", color: leftColor),
          leftSet,
        ],
      ),
    );
  }
}

class _SideLabel extends StatelessWidget {
  final String label;
  final Color color;
  const _SideLabel({required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, left: 4),
      child: Row(
        children: [
          Container(width: 2, height: 10, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: LabStyles.mono(context,
                  fontSize: 7,
                  color: color.withValues(alpha: 0.8),
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _EditableSessionTimer extends ConsumerStatefulWidget {
  const _EditableSessionTimer();
  @override
  ConsumerState<_EditableSessionTimer> createState() =>
      _EditableSessionTimerState();
}

class _EditableSessionTimerState extends ConsumerState<_EditableSessionTimer> {
  late TextEditingController _controller;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateFromLog(WorkoutLog? log) {
    if (_isEditing) return;

    final isRunning = log?.workoutStartTime != null;
    final accumulated = log?.accumulatedSeconds ?? 0;
    final startTime = log?.workoutStartTime;

    final totalSeconds = isRunning
        ? accumulated + DateTime.now().difference(startTime!).inSeconds
        : accumulated;

    final h = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');

    final newText = "$h:$m:$s";
    if (_controller.text != newText) {
      _controller.text = newText;
    }
  }

  Future<void> _saveManualTime(WorkoutLog log) async {
    final parts = _controller.text.split(':');
    int totalSeconds = 0;
    try {
      if (parts.length == 3) {
        totalSeconds = (int.parse(parts[0]) * 3600) +
            (int.parse(parts[1]) * 60) +
            int.parse(parts[2]);
      } else if (parts.length == 2) {
        totalSeconds = (int.parse(parts[0]) * 60) + int.parse(parts[1]);
      } else if (parts.length == 1) {
        totalSeconds = int.parse(parts[0]);
      }

      final db = ref.read(databaseProvider);
      await (db.update(db.workoutLogs)..where((t) => t.id.equals(log.id)))
          .write(WorkoutLogsCompanion(
        accumulatedSeconds: drift.Value(totalSeconds),
        durationMinutes: drift.Value(totalSeconds ~/ 60),
      ));
    } catch (e) {
      debugPrint("Error parsing timer: $e");
    }
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    final logAsync = ref.watch(currentWorkoutLogProvider);
    ref.listen(timerTickProvider, (_, __) {
      _updateFromLog(logAsync.value);
    });

    return logAsync.when(
      data: (log) {
        _updateFromLog(log);
        final isRunning = log?.workoutStartTime != null;
        final accumulated = log?.accumulatedSeconds ?? 0;
        final startTime = log?.workoutStartTime;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: LabColors.surfaceContainerLow,
            border: Border.all(
                color: LabColors.primary.withValues(alpha: 0.3), width: 0.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.timer,
                      color: isRunning ? LabColors.primary : Colors.grey,
                      size: 16),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 100,
                    child: TextField(
                      controller: _controller,
                      enabled: !isRunning,
                      onTap: () => setState(() => _isEditing = true),
                      onSubmitted: (_) =>
                          log != null ? _saveManualTime(log) : null,
                      onChanged: (_) => _isEditing = true,
                      style: LabStyles.mono(context,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isRunning ? Colors.white : Colors.grey),
                      decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Flexible(
                child: LabButton(
                  label: isRunning
                      ? "STOP_SESSION"
                      : (accumulated == 0 ? "START_SESSION" : "RESUME"),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  onPressed: () async {
                    final db = ref.read(databaseProvider);
                    if (!isRunning) {
                      if (log == null) {
                        await db
                            .into(db.workoutLogs)
                            .insert(WorkoutLogsCompanion.insert(
                              date: DateTime.now(),
                              workoutStartTime: drift.Value(DateTime.now()),
                            ));
                      } else {
                        await (db.update(db.workoutLogs)
                              ..where((t) => t.id.equals(log.id)))
                            .write(WorkoutLogsCompanion(
                                workoutStartTime: drift.Value(DateTime.now())));
                      }
                    } else {
                      final sessionElapsed =
                          DateTime.now().difference(startTime!).inSeconds;
                      final newAccumulated = accumulated + sessionElapsed;
                      await (db.update(db.workoutLogs)
                            ..where((t) => t.id.equals(log!.id)))
                          .write(WorkoutLogsCompanion(
                        workoutStartTime: const drift.Value(null),
                        accumulatedSeconds: drift.Value(newAccumulated),
                        durationMinutes: drift.Value(newAccumulated ~/ 60),
                      ));
                    }
                  },
                  color: isRunning ? Colors.redAccent : LabColors.primary,
                  isOutlined: true,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Container(
          height: 60,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(color: LabColors.primary)),
      error: (e, s) => Text('TIMER_ERROR: $e',
          style:
              LabStyles.mono(context, color: Colors.redAccent, fontSize: 10)),
    );
  }
}

// WORKOUT OPTS BOTTOM SHEET — modular slice architecture
// ═══════════════════════════════════════════════════════════════
// To add a new option: add a _WorkoutOptsSlice entry in the
// slices list inside _WorkoutOptsSheetState.build().
// Each slice is self-contained (label, icon, color, action).
// ═══════════════════════════════════════════════════════════════

class _WorkoutOptsSheet extends ConsumerStatefulWidget {
  final DateTime date;
  final List<drift.TypedResult> results;
  final VoidCallback onMakeBlueprint;
  final VoidCallback onDeleteAll;

  const _WorkoutOptsSheet({
    required this.date,
    required this.results,
    required this.onMakeBlueprint,
    required this.onDeleteAll,
  });

  @override
  ConsumerState<_WorkoutOptsSheet> createState() => _WorkoutOptsSheetState();
}

class _WorkoutOptsSheetState extends ConsumerState<_WorkoutOptsSheet> {
  Color _tc(String key, String nameSeed) {
    final settings = ref.watch(themeSettingsProvider).value ?? {};
    return ref
        .read(themeControllerProvider)
        .getColor(settings, key, nameSeed: nameSeed);
  }

  void _showWbProjections(BuildContext context, WidgetRef ref) async {
    final db = ref.read(databaseProvider);
    final wbList = await OvarchPlanInjectionService.activeWorkoutBlocks(db);
    if (wbList.isEmpty || !context.mounted) {
      if (context.mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('NO_WBS')));
      return;
    }

    // Find which blocks were injected into this c.wo date via complexMetadata.
    final selectedDate = widget.date;
    final todayStart =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final todayEnd = DateTime(
        selectedDate.year, selectedDate.month, selectedDate.day, 23, 59, 59);
    final injectedBlockIds = <int>{};
    try {
      final injectedSets = await db
          .customSelect(
              "SELECT DISTINCT json_extract(ws.complex_metadata, '\$.injectedFromBlock') as block_id "
              "FROM workout_sets ws "
              "JOIN workout_logs wl ON wl.id = ws.log_id "
              "WHERE wl.date >= ${todayStart.millisecondsSinceEpoch} AND wl.date <= ${todayEnd.millisecondsSinceEpoch} "
              "AND ws.complex_metadata LIKE '%injectedFromBlock%'")
          .get();
      for (final row in injectedSets) {
        final rawBid = row.data['block_id'];
        final bid =
            rawBid is int ? rawBid : int.tryParse(rawBid?.toString() ?? '');
        if (bid != null) injectedBlockIds.add(bid);
      }
    } catch (_) {}

    if (injectedBlockIds.isEmpty) {
      if (context.mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('NO_INJECTED_WBS')));
      return;
    }

    // For each injected WB, load its KNS data from real tables.
    final List<Map<String, dynamic>> projections = [];
    for (final wb in wbList) {
      final blockId =
          int.tryParse(wb['id'].toString().replaceAll('wb_', '')) ?? 0;
      if (!injectedBlockIds.contains(blockId)) continue;

      // Read from real workout_block_kns + workout_block_sets tables
      final knsDbRows = await db
          .customSelect(
              'SELECT id, base_exercise_id, order_index, utilities, batch_name FROM workout_block_kns WHERE block_id = $blockId ORDER BY order_index ASC')
          .get();
      List<Map<String, dynamic>> knsList = [];
      for (final knsRow in knsDbRows) {
        final knsId = knsRow.data['id'] as int;
        final baseExId = knsRow.data['base_exercise_id'] as int;

        // Resolve exercise name
        String exName = '';
        final ex = await (db.select(db.baseExercises)
              ..where((t) => t.id.equals(baseExId)))
            .getSingleOrNull();
        if (ex != null) exName = ex.name;

        // Read sets
        final setRows = await db
            .customSelect(
                'SELECT id, set_number, reps_min, reps_max, pload, rpe, rir, set_intention, side FROM workout_block_sets WHERE kns_id = $knsId ORDER BY set_number ASC')
            .get();

        knsList.add({
          'exerciseName': exName,
          'sets': setRows
              .map((sRow) => {
                    'setNumber': sRow.data['set_number'],
                    'pload': (sRow.data['pload'] as num?)?.toDouble(),
                    'minReps': (sRow.data['reps_min'] as num?)?.toDouble(),
                    'maxReps': (sRow.data['reps_max'] as num?)?.toDouble(),
                    'rpe': (sRow.data['rpe'] as num?)?.toDouble(),
                    'rir': (sRow.data['rir'] as num?)?.toDouble(),
                    'intention': sRow.data['set_intention'] as String?,
                    'side': sRow.data['side'] as String?,
                  })
              .toList(),
        });
      }
      projections.add({
        'wb': wb,
        'kns': knsList,
        'description': null,
        'injectedToday': true,
      });
    }

    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: LabColors.background,
      isScrollControlled: true,
      builder: (c) => Container(
        padding: const EdgeInsets.all(24),
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(c).size.height * 0.85),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('WB PROJECTIONS',
                style: LabStyles.headline(context, color: LabColors.accent)
                    .copyWith(fontSize: 16)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                shrinkWrap: true,
                children: projections.map((p) {
                  final wb = p['wb'] as Map<String, dynamic>;
                  final kns = (p['kns'] as List).cast<Map<String, dynamic>>();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white12, width: 0.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // WB header
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          color: LabColors.surfaceContainerHigh,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(wb['name'].toString().toUpperCase(),
                                  style: LabStyles.headline(context).copyWith(
                                      fontSize: 14, color: Colors.white)),
                              if (p['injectedToday'] == true)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text('INJECTED TODAY',
                                      style: LabStyles.mono(context,
                                          fontSize: 8,
                                          color: LabColors.primary,
                                          fontWeight: FontWeight.bold)),
                                ),
                              if (p['description'] != null &&
                                  (p['description'] as String).isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(p['description'] as String,
                                      style: LabStyles.mono(context,
                                          fontSize: 8,
                                          color: Colors.grey[400])),
                                ),
                            ],
                          ),
                        ),
                        if (kns.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text('NO KNS',
                                style: LabStyles.mono(context,
                                    fontSize: 8, color: Colors.grey)),
                          )
                        else
                          ...kns.map((k) => Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border(
                                      top: BorderSide(
                                          color: Colors.white12, width: 0.5)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Exercise name
                                    Text(
                                        k['exerciseName']
                                            .toString()
                                            .toUpperCase(),
                                        style: LabStyles.mono(context,
                                            fontSize: 13,
                                            color: Colors.cyanAccent,
                                            fontWeight: FontWeight.bold)),
                                    // KNS purpose (user-written, not exercise metadata)
                                    if (k['intention'] != null &&
                                        (k['intention'] as String).isNotEmpty &&
                                        !(k['intention'] as String)
                                            .startsWith('[NT:'))
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                            'PURPOSE: ${k['intention']}',
                                            style: LabStyles.mono(context,
                                                fontSize: 10,
                                                color: Colors.amber)),
                                      ),
                                    const SizedBox(height: 8),
                                    // Per-set details
                                    ...(() {
                                      final sets = (k['sets'] as List?) ?? [];
                                      if (sets.isEmpty) {
                                        return [
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 4),
                                            child: Text('SET 1: (NO DATA)',
                                                style: LabStyles.mono(context,
                                                    fontSize: 10,
                                                    color: Colors.grey[600])),
                                          ),
                                        ];
                                      }
                                      return sets.asMap().entries.map((entry) {
                                        final s =
                                            entry.value as Map<String, dynamic>;
                                        final setNum =
                                            s['setNumber'] ?? (entry.key + 1);
                                        final pload = s['pload'];
                                        final minR = s['minReps'];
                                        final maxR = s['maxReps'];
                                        final rpe = s['rpe'];
                                        final rir = s['rir'];
                                        final setIntention = s['intention'];

                                        return Container(
                                          margin:
                                              const EdgeInsets.only(bottom: 8),
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                color: Colors.grey[800]!,
                                                width: 0.5),
                                            color: Colors.black
                                                .withValues(alpha: 0.3),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // SET header row
                                              Row(
                                                children: [
                                                  Text('SET $setNum',
                                                      style: LabStyles.mono(
                                                          context,
                                                          fontSize: 11,
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                  if (setIntention != null &&
                                                      (setIntention as String)
                                                          .isNotEmpty) ...[
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 6,
                                                          vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: Colors
                                                            .greenAccent
                                                            .withValues(
                                                                alpha: 0.15),
                                                        border: Border.all(
                                                            color: Colors
                                                                .greenAccent
                                                                .withValues(
                                                                    alpha: 0.5),
                                                            width: 0.5),
                                                      ),
                                                      child: Text(
                                                          '${setIntention}',
                                                          style: LabStyles.mono(
                                                              context,
                                                              fontSize: 9,
                                                              color: Colors
                                                                  .greenAccent,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold)),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              // P.LOAD
                                              if (pload != null)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          bottom: 4),
                                                  child: Text(
                                                      'P.LOAD: ${pload}',
                                                      style: LabStyles.mono(
                                                          context,
                                                          fontSize: 10,
                                                          color: Colors.white)),
                                                ),
                                              // REP RANGE row
                                              Row(
                                                children: [
                                                  Text('REP RANGE:',
                                                      style: LabStyles.mono(
                                                          context,
                                                          fontSize: 10,
                                                          color: Colors
                                                              .grey[400])),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                      'MIN (${minR?.toString() ?? '—'})',
                                                      style: LabStyles.mono(
                                                          context,
                                                          fontSize: 11,
                                                          color:
                                                              Colors.white70)),
                                                  const SizedBox(width: 8),
                                                  Text('-',
                                                      style: LabStyles.mono(
                                                          context,
                                                          fontSize: 11,
                                                          color: Colors
                                                              .grey[500])),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                      'MAX (${maxR?.toString() ?? '—'})',
                                                      style: LabStyles.mono(
                                                          context,
                                                          fontSize: 11,
                                                          color:
                                                              Colors.white70)),
                                                ],
                                              ),
                                              // RPE / RIR
                                              if (rpe != null || rir != null)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 4),
                                                  child: Text(
                                                      '${rpe != null ? "RPE: $rpe" : ""}${rpe != null && rir != null ? "  |  " : ""}${rir != null ? "RIR: $rir" : ""}',
                                                      style: LabStyles.mono(
                                                          context,
                                                          fontSize: 9,
                                                          color: Colors
                                                              .grey[400])),
                                                ),
                                            ],
                                          ),
                                        );
                                      }).toList();
                                    })(),
                                  ],
                                ),
                              )),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            LabButton(label: 'CLOSE', onPressed: () => Navigator.pop(c)),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // -- Define slices here -------------------------------------------
    // Add / remove / reorder slices freely. Each slice is modular.
    final slices = <_WorkoutOptsSlice>[
      _WorkoutOptsSlice(
        label: 'MAKE BLUEPRINT\nFROM CURRENT',
        icon: Icons.layers,
        color: _tc('UI_TAG_WO_BLUEPRINT', 'WO_BLUEPRINT'),
        onTap: widget.onMakeBlueprint,
      ),
      _WorkoutOptsSlice(
        label: 'DELETE\nALL SETS',
        icon: Icons.delete_forever,
        color: _tc('UI_TAG_WO_PURGE', 'WO_PURGE'),
        onTap: widget.onDeleteAll,
      ),
      _WorkoutOptsSlice(
        label: 'VIEW WB\nPROJECTIONS',
        icon: Icons.analytics,
        color: LabColors.accent,
        onTap: () => _showWbProjections(context, ref),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('WORKOUT OPTS',
                  style: LabStyles.headline(context,
                          color: _tc('UI_TAG_WORKOUT_OPTS', 'WORKOUT_OPTS'))
                      .copyWith(fontSize: 16, letterSpacing: 2)),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: slices.map((s) => _buildSlice(context, s)).toList(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSlice(BuildContext context, _WorkoutOptsSlice slice) {
    return GestureDetector(
      onTap: slice.onTap,
      child: Container(
        width: (MediaQuery.of(context).size.width - 60) / 2,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: slice.color.withValues(alpha: 0.08),
          border:
              Border.all(color: slice.color.withValues(alpha: 0.4), width: 0.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(slice.icon, color: slice.color, size: 28),
            const SizedBox(height: 10),
            Text(
              slice.label,
              textAlign: TextAlign.center,
              style: LabStyles.mono(context,
                  fontSize: 8,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutOptsSlice {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _WorkoutOptsSlice({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _InjectOptions {
  final bool usePload;
  final bool allSets;
  const _InjectOptions({required this.usePload, required this.allSets});
}

class _WbInjectConfigDialog extends StatefulWidget {
  final Map<String, dynamic> wbData;
  final Function(bool usePload, bool allSets) onInject;
  final VoidCallback onCancel;
  const _WbInjectConfigDialog(
      {super.key,
      required this.wbData,
      required this.onInject,
      required this.onCancel});
  @override
  State<_WbInjectConfigDialog> createState() => _WbInjectConfigDialogState();
}

class _WbInjectConfigDialogState extends State<_WbInjectConfigDialog> {
  bool _usePload = false;
  bool _allSets = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: LabColors.background,
      title: Text('INJECT WB',
          style: LabStyles.mono(context,
              fontSize: 14, fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${widget.wbData['name']}',
              style: LabStyles.headline(context)
                  .copyWith(fontSize: 16, color: LabColors.primary)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[700]!, width: 0.5)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('LOAD OPTIONS',
                    style: LabStyles.mono(context,
                        fontSize: 10,
                        color: Colors.grey[400],
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => setState(() => _usePload = !_usePload),
                  child: Row(children: [
                    Icon(
                        _usePload
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                        color: LabColors.primary,
                        size: 20),
                    const SizedBox(width: 8),
                    Text('USE P.LOAD AS LOAD',
                        style: LabStyles.mono(context,
                            fontSize: 10, color: Colors.white)),
                  ]),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => setState(() => _allSets = !_allSets),
                  child: Row(children: [
                    Icon(
                        _allSets
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                        color: LabColors.primary,
                        size: 20),
                    const SizedBox(width: 8),
                    Text('INJECT ALL SETS',
                        style: LabStyles.mono(context,
                            fontSize: 10, color: Colors.white)),
                  ]),
                ),
                if (!_allSets)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 28),
                    child: Text('(SINGLE DEFAULT SET ONLY)',
                        style: LabStyles.mono(context,
                            fontSize: 8, color: Colors.grey[500])),
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: widget.onCancel,
            child: Text('CANCEL',
                style: LabStyles.mono(context, color: Colors.grey))),
        TextButton(
            onPressed: () => widget.onInject(_usePload, _allSets),
            child: Text('INJECT',
                style: LabStyles.mono(context, color: LabColors.primary))),
      ],
    );
  }
}
