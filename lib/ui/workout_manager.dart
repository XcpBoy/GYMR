import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:intl/intl.dart';
import 'dart:convert'; // For jsonDecode
import 'dart:async'; // For Timer
import 'dart:math'; // For log (VP calculation)

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
import 'wb_shared/wb_shared_widgets.dart';

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
  // One row per LOG (grouped), not per SET — the previous version joined
  // and streamed every individual set just to extract distinct dates,
  // which meant editing any single set anywhere in the app's history
  // re-scanned and re-looped over the entire workout_sets table.
  final query = db.selectOnly(db.workoutLogs)
    ..addColumns([db.workoutLogs.date])
    ..join([
      drift.innerJoin(
          db.workoutSets, db.workoutSets.logId.equalsExp(db.workoutLogs.id))
    ])
    ..groupBy([db.workoutLogs.id])
    ..orderBy([drift.OrderingTerm.asc(db.workoutLogs.date)]);
  return query.watch().map((rows) {
    final seen = <String>{};
    final result = <String, int>{};
    int counter = 0;
    for (final row in rows) {
      final date = row.read(db.workoutLogs.date)!;
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
  final Set<String> _expandedExerciseKeys = {};
  final Set<String> _collapsedExerciseKeys = {};
  bool _maintainExtended = false;
  double _injectionProgress = 0.0;
  String _injectionStatus = '';
  Timer? _injectionProgressTimer;
  DateTime? _injectionStartedAt;
  OverlayEntry? _injectionOverlayEntry;
  bool _isInjectionFinishing = false;

  // Memoized VP overview future — without this, the inline FutureBuilder in
  // build() would create a brand-new Future (re-running the DB query +
  // regex/sort work in _buildVpOverview) on every rebuild, not just when the
  // underlying results actually change.
  List<drift.TypedResult>? _vpOverviewInput;
  Future<Widget>? _vpOverviewFuture;

  Future<Widget> _getVpOverviewFuture(
      BuildContext context, List<drift.TypedResult>? results) {
    if (!identical(results, _vpOverviewInput) || _vpOverviewFuture == null) {
      _vpOverviewInput = results;
      _vpOverviewFuture = _buildVpOverview(context, ref, results);
    }
    return _vpOverviewFuture!;
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _injectionProgressTimer?.cancel();
    _injectionOverlayEntry?.remove();
    _injectionOverlayEntry = null;
    super.dispose();
  }

  void expandBatch(String batchName) {
    if (!mounted) return;
    setState(() {
      _expandedUtils.add('batch_$batchName');
    });
  }

  void setExerciseExpanded(String exerciseKey, bool expanded) {
    if (!mounted) return;
    setState(() {
      if (expanded) {
        _collapsedExerciseKeys.remove(exerciseKey);
        _expandedExerciseKeys.add(exerciseKey);
      } else {
        _collapsedExerciseKeys.add(exerciseKey);
        _expandedExerciseKeys.remove(exerciseKey);
      }
    });
  }

  void toggleMaintainExtended() {
    if (!mounted) return;
    setState(() {
      _maintainExtended = !_maintainExtended;
      _collapsedExerciseKeys.clear();
    });
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
    final workoutOptsColor =
        tC.getColor(settings, 'UI_TAG_WORKOUT_OPTS', nameSeed: 'WORKOUT_OPTS');

    final currentLogForNotes = workoutAsync.value?.isEmpty == true
        ? null
        : workoutAsync.value?.first
            .readTable(ref.read(databaseProvider).workoutLogs);
    final generalNotesSliver = currentLogForNotes == null
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GeneralNotesModule(
                key: const ValueKey('general_notes'),
                log: currentLogForNotes,
                cardKey: 'SESSION_GENERAL_NOTES'),
          );

    return Stack(children: [
      CustomScrollView(controller: _scrollController, slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
        SliverToBoxAdapter(
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildHeader(
                    context, widget.date, ref, workoutAsync.value ?? []))),
        SliverToBoxAdapter(
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GestureDetector(
                  onTap: () => _showWorkoutOptsSheet(
                      context, ref, workoutAsync.value ?? []),
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: workoutOptsColor.withValues(alpha: 0.12),
                      border: Border.all(color: workoutOptsColor, width: 0.5),
                    ),
                    child: Text(
                      'WORKOUT OPTS',
                      style: LabStyles.mono(context,
                          fontSize: 9,
                          color: workoutOptsColor,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ))),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),
        workoutAsync.when(
          data: (results) {
            if (results.isEmpty) {
              return SliverToBoxAdapter(child: _buildEmptyState(context));
            }

            final Map<int, List<drift.TypedResult>> groupedByEx = {};
            final List<int> exerciseIdsInOrder = [];

            for (var row in results) {
              final exId = row.readTable(db.baseExercises).id;
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
            // A batch stays anchored at its first visible position. If another KNS
            // assigned to the same batch appears later in orderIndex, append it to
            // the existing batch section instead of creating a duplicate bottom header.
            final List<Object> interleavedItems = [];
            final Map<String, MapEntry<String, List<List<int>>>> batchSections =
                {};

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
                final existing = batchSections[batchName];
                if (existing == null) {
                  final groups = <List<int>>[group];
                  final entry =
                      MapEntry<String, List<List<int>>>(batchName, groups);
                  interleavedItems.add(entry);
                  batchSections[batchName] = entry;
                } else {
                  existing.value.add(group);
                }
              } else {
                interleavedItems.add(group);
              }
            }

            final List<int> flatIndices = [];
            final List<int> globalSetStarts = [];
            int flatIdx = 0;
            int globalSetCounter = 0;
            for (final item in interleavedItems) {
              flatIndices.add(flatIdx);
              globalSetStarts.add(globalSetCounter);
              flatIdx++;
              if (item is List<int>) {
                globalSetCounter += _countSetsInGroup(groupedByEx, item);
              } else if (item is MapEntry<String, List<List<int>>>) {
                for (final group in item.value) {
                  globalSetCounter += _countSetsInGroup(groupedByEx, group);
                }
              }
            }

            return SliverPadding(
              padding: EdgeInsets.zero,
              sliver: SliverReorderableList(
                itemCount: interleavedItems.length,
                itemBuilder: (context, index) {
                  final item = interleavedItems[index];
                  if (item is List<int>) {
                    return _buildGroupWidget(
                      item,
                      groupIdx: flatIndices[index],
                      groupColor: _groupColorFor(
                          context, settings, tC, groupedByEx, db, item),
                      isSuperset: _isSupersetFor(groupedByEx, db, item),
                      supersetName: _supersetNameFor(groupedByEx, db, item),
                      groupedByEx: groupedByEx,
                      db: db,
                      bw: bw,
                      globalSetStart: globalSetStarts[index],
                    );
                  }

                  if (item is MapEntry<String, List<List<int>>>) {
                    return _buildBatchSection(
                      context: context,
                      batchName: item.key,
                      groups: item.value,
                      flatIdx: flatIndices[index],
                      globalSetStart: globalSetStarts[index],
                      groupedByEx: groupedByEx,
                      db: db,
                      bw: bw,
                      settings: settings,
                      tC: tC,
                      interleavedItems: interleavedItems,
                    );
                  }

                  return const SizedBox.shrink();
                },
                onReorder: (oldIdx, newIdx) async {
                  if (newIdx > oldIdx) newIdx--;
                  final reorderedList = List<Object>.from(interleavedItems);
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
                          .write(
                              WorkoutSetsCompanion(orderIndex: drift.Value(i)));
                    }
                  });
                },
              ),
            );
          },
          loading: () => const SliverFillRemaining(
              child: Padding(
            padding: EdgeInsets.only(top: 100),
            child: CircularProgressIndicator(color: LabColors.primary),
          )),
          error: (e, s) => SliverFillRemaining(
              child: Padding(
            padding: const EdgeInsets.only(top: 100),
            child: Text("ERR: $e",
                style: LabStyles.mono(context, color: Colors.redAccent)),
          )),
        ),
        SliverToBoxAdapter(child: generalNotesSliver),
        SliverToBoxAdapter(
            child: FutureBuilder<Widget>(
                future: _getVpOverviewFuture(context, workoutAsync.value),
                builder: (ctx, snap) =>
                    snap.connectionState == ConnectionState.done
                        ? (snap.data ?? const SizedBox.shrink())
                        : const SizedBox.shrink())),
        const SliverToBoxAdapter(child: SizedBox(height: 150)),
      ]),
      Positioned(
          bottom: 24,
          right: 24,
          child: FloatingActionButton(
              backgroundColor: LabColors.primary,
              onPressed: () => _showExercisePicker(context, ref, widget.date),
              child: const Icon(Icons.add, color: Colors.black, size: 32))),
    ]);
  }

  void _showInjectionOverlay() {
    if (_injectionOverlayEntry != null) return;
    _injectionOverlayEntry = OverlayEntry(
      builder: (overlayContext) => Positioned(
        top: MediaQuery.of(overlayContext).padding.top + 8,
        left: 12,
        right: 12,
        child: IgnorePointer(
          child: _buildInjectionProgressBar(overlayContext),
        ),
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(_injectionOverlayEntry!);
  }

  Widget _buildInjectionProgressBar(BuildContext context) {
    final percent = (_injectionProgress * 100).round().clamp(0, 100);
    return Container(
      margin: const EdgeInsets.only(top: 14, bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LabColors.background,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: LabColors.primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              _injectionStatus.isEmpty
                  ? 'INJECTING...'
                  : _injectionStatus.toUpperCase(),
              style: LabStyles.mono(context,
                  fontSize: 10,
                  color: LabColors.primary,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('$percent%',
              style: LabStyles.mono(context,
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.zero,
            child: LinearProgressIndicator(
              value: _injectionProgress,
              minHeight: 10,
              backgroundColor: Colors.grey[900],
              valueColor: AlwaysStoppedAnimation<Color>(LabColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _startInjectionProgress(String label) {
    debugPrint('[INJECTION_PROGRESS] START $label');
    _injectionProgressTimer?.cancel();
    _injectionOverlayEntry?.remove();
    _isInjectionFinishing = false;
    setState(() {
      _injectionProgress = 0.04;
      _injectionStatus = label;
      _injectionStartedAt = DateTime.now();
    });
    _showInjectionOverlay();
    _injectionProgressTimer =
        Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted) {
        _injectionProgressTimer?.cancel();
        return;
      }
      setState(() {
        _injectionProgress = (_injectionProgress + 0.02).clamp(0.0, 0.95);
      });
    });
  }

  void _setInjectionProgress(double progress, String label) {
    if (!mounted) return;
    setState(() {
      _injectionProgress = progress.clamp(0.0, 1.0);
      _injectionStatus = label;
    });
  }

  void _finishInjectionProgress() {
    if (_isInjectionFinishing) return;
    _isInjectionFinishing = true;
    debugPrint('[INJECTION_PROGRESS] FINISH');
    _injectionProgressTimer?.cancel();
    _injectionProgressTimer = null;
    final elapsed = _injectionStartedAt == null
        ? const Duration(seconds: 3)
        : DateTime.now().difference(_injectionStartedAt!);
    final remaining = const Duration(milliseconds: 2200) - elapsed;
    final delay = remaining.isNegative ? Duration.zero : remaining;
    Future.delayed(delay, () {
      if (!mounted) return;
      setState(() {
        _injectionProgress = 1.0;
        _injectionStatus = 'INJECTION COMPLETE';
      });
      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        setState(() {
          _injectionProgress = 0.0;
          _injectionStatus = '';
          _injectionStartedAt = null;
          _injectionOverlayEntry?.remove();
          _injectionOverlayEntry = null;
          _isInjectionFinishing = false;
        });
      });
    });
  }

  Future<Widget> _buildVpOverview(BuildContext context, WidgetRef ref,
      List<drift.TypedResult>? results) async {
    if (results == null || results.isEmpty) return const SizedBox.shrink();

    final db = ref.read(databaseProvider);
    final bw = ref.read(bodyWeightAtDateProvider(widget.date)).value ?? 0.0;
    final Map<int, ({String name, double totalVp})> vpByEx = {};
    double sessionVp = 0;

    // Group sets by baseExerciseId and compute VP from persisted weight/reps
    final setsByEx = <int, List<WorkoutSet>>{};
    for (var row in results) {
      final s = row.readTable(db.workoutSets);
      setsByEx.putIfAbsent(s.baseExerciseId, () => []).add(s);
    }

    // Resolve exercise names and metadata
    final exIds = setsByEx.keys.toList();
    if (exIds.isEmpty) return const SizedBox.shrink();
    final exRows = exIds.isNotEmpty
        ? await (db.select(db.baseExercises)
              ..where((t) => t.id.isIn(exIds)))
            .get()
        : <BaseExercise>[];
    final exMap = {for (var e in exRows) e.id: e};

    for (final id in exIds) {
      final ex = exMap[id];
      if (ex == null) continue;
      final m = (ex.parsedComplexMetadata["vpMultiplier"] as num?)?.toDouble() ?? 1.0;
      final loadType = RegExp(r'\[NT:(\w+)\]').firstMatch(ex.intention ?? '')?.group(1) ?? 'EXT.LOAD';
      final isJst = loadType == 'JST.BW';
      final isL = loadType == 'LASTRE';

      final sets = setsByEx[id]!
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

      double knsVp = 0;
      for (int i = 0; i < sets.length; i++) {
        final s = sets[i];
        final w = isJst ? bw : (isL ? s.weight + bw : s.weight);
        final reps = s.reps;
        final tonnage = w * reps;
        if (tonnage <= 0) continue;
        final ordinal = i + 1;
        knsVp += tonnage * (1 + m * log(ordinal + 1));
      }
      if (knsVp > 0) {
        vpByEx[id] = (name: ex.fullName, totalVp: knsVp);
        sessionVp += knsVp;
      }
    }

    final sorted = vpByEx.entries.toList()
      ..sort((a, b) => b.value.totalVp.compareTo(a.value.totalVp));

    // ref.read, not watch — this runs inside an async function after an
    // await, past the point where `watch` is valid to call.
    final settings = ref.read(themeSettingsProvider).value ?? {};
    final sessionTotalColor = ref.read(themeControllerProvider).getColor(
        settings, 'UI_TAG_SESSION_TOTAL',
        defaultColor: LabColors.accent);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[700]!, width: 0.5),
          color: LabColors.surfaceDim,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            color: LabColors.surfaceContainerLow,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('PERFORMANCE OVERVIEW',
                      style: LabStyles.mono(context,
                          fontSize: 10,
                          color: LabColors.accent,
                          fontWeight: FontWeight.bold)),
                  Text('${sessionVp.toStringAsFixed(0)} VP',
                      style: LabStyles.mono(context,
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                ]),
          ),
          const Divider(height: 1, color: Colors.grey),
          // KNS rows
          ...sorted.map((entry) => Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(entry.value.name,
                            style: LabStyles.mono(context,
                                fontSize: 9,
                                color: Colors.grey[300],
                                fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis),
                      ),
                      Text('${entry.value.totalVp.toStringAsFixed(0)} VP',
                          style: LabStyles.mono(context,
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ]),
              )),
          const Divider(height: 1, color: Colors.grey),
          // Total
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('SESIÓN TOTAL',
                      style: LabStyles.mono(context,
                          fontSize: 10,
                          color: sessionTotalColor,
                          fontWeight: FontWeight.bold)),
                  Text('${sessionVp.toStringAsFixed(0)} VP',
                      style: LabStyles.mono(context,
                          fontSize: 10,
                          color: sessionTotalColor,
                          fontWeight: FontWeight.bold)),
                ]),
          ),
        ]),
      ),
    );
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

  int _countSetsInGroup(
      Map<int, List<drift.TypedResult>> groupedByEx, List<int> group) {
    return group.fold<int>(0, (sum, exId) => sum + groupedByEx[exId]!.length);
  }

  bool _isSupersetFor(Map<int, List<drift.TypedResult>> groupedByEx,
      AppDatabase db, List<int> group) {
    return groupedByEx[group.first]!
            .first
            .readTable(db.workoutSets)
            .supersetGroupId !=
        null;
  }

  String? _supersetNameFor(Map<int, List<drift.TypedResult>> groupedByEx,
      AppDatabase db, List<int> group) {
    return groupedByEx[group.first]!
        .first
        .readTable(db.workoutSets)
        .supersetName;
  }

  Color _groupColorFor(
      BuildContext context,
      Map<String, ThemeSetting> settings,
      ThemeController tC,
      Map<int, List<drift.TypedResult>> groupedByEx,
      AppDatabase db,
      List<int> group) {
    if (!_isSupersetFor(groupedByEx, db, group)) return Colors.transparent;
    final supersetName = _supersetNameFor(groupedByEx, db, group);
    if (supersetName == null) return Colors.transparent;
    return tC.getColor(settings, "SUPERSET_$supersetName",
        nameSeed: supersetName);
  }

  Widget _buildBatchSection({
    required BuildContext context,
    required String batchName,
    required List<List<int>> groups,
    required int flatIdx,
    required int globalSetStart,
    required Map<int, List<drift.TypedResult>> groupedByEx,
    required AppDatabase db,
    required double bw,
    required Map<String, ThemeSetting> settings,
    required ThemeController tC,
    required List<Object> interleavedItems,
  }) {
    final isExpanded = _expandedUtils.contains('batch_$batchName');
    final groupStarts = <int>[];
    int runningGlobal = globalSetStart;
    for (final group in groups) {
      groupStarts.add(runningGlobal);
      runningGlobal += _countSetsInGroup(groupedByEx, group);
    }

    return Container(
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: tC
                    .getColor(settings, 'UI_TAG_BATCH_$batchName',
                        nameSeed: batchName)
                    .withValues(alpha: 0.1),
                border: Border(
                    left: BorderSide(
                        color: tC.getColor(settings, 'UI_TAG_BATCH_$batchName',
                            nameSeed: batchName),
                        width: 3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.drag_indicator,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(isExpanded ? '[ − ]' : '[ + ]',
                      style: LabStyles.mono(context,
                          fontSize: 10, color: Colors.grey[400])),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(batchName.toUpperCase(),
                        style: LabStyles.mono(context,
                            fontSize: 11,
                            color: tC.getColor(
                                settings, 'UI_TAG_BATCH_$batchName',
                                nameSeed: batchName),
                            fontWeight: FontWeight.bold)),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.zero,
                    ),
                    child: Text('${groups.length} KNS',
                        style: LabStyles.mono(context,
                            fontSize: 8, color: Colors.grey[500])),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const SizedBox(height: 8),
            ReorderableListView.builder(
              key: ValueKey('batch_list_$batchName'),
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: groups.length,
              itemBuilder: (context, batchIdx) => _buildGroupWidget(
                groups[batchIdx],
                groupIdx: flatIdx + batchIdx,
                groupColor: _groupColorFor(
                    context, settings, tC, groupedByEx, db, groups[batchIdx]),
                isSuperset: _isSupersetFor(groupedByEx, db, groups[batchIdx]),
                supersetName:
                    _supersetNameFor(groupedByEx, db, groups[batchIdx]),
                groupedByEx: groupedByEx,
                db: db,
                bw: bw,
                globalSetStart: groupStarts[batchIdx],
              ),
              onReorder: (oldIdx, newIdx) async {
                if (newIdx > oldIdx) newIdx--;
                final reordered = List<List<int>>.from(groups);
                final moved = reordered.removeAt(oldIdx);
                reordered.insert(newIdx, moved);
                // Recalculate full order from interleavedItems with this batch reordered
                final List<int> orderIds = [];
                for (final oi in interleavedItems) {
                  if (oi is List<int>) {
                    orderIds.addAll(oi);
                  } else if (oi is MapEntry<String, List<List<int>>>) {
                    final bg = (oi.key == batchName) ? reordered : oi.value;
                    for (final g in bg) {
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
                        .write(
                            WorkoutSetsCompanion(orderIndex: drift.Value(i)));
                  }
                });
              },
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
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
            final exerciseKey = 'ex_${firstExId}_$exId';
            final mod = _ExerciseModule(
              key: ValueKey(exerciseKey),
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
              expanded: _maintainExtended
                  ? !_collapsedExerciseKeys.contains(exerciseKey)
                  : _expandedExerciseKeys.contains(exerciseKey),
              onToggleExpanded: (expanded) =>
                  setExerciseExpanded(exerciseKey, expanded),
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
        maintainExtended: _maintainExtended,
        onToggleMaintainExtended: toggleMaintainExtended,
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
    return EditableSessionTimer(
        logProvider: currentWorkoutLogProvider,
        tickProvider: timerTickProvider);
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
                        Future.microtask(() {
                          if (!mounted) return;
                          final db = ref.read(databaseProvider);
                          unawaited(
                              db.select(db.baseExercises).get().then((all) {
                            if (!mounted) return;
                            showModalBottomSheet(
                                context: this.context,
                                backgroundColor: LabColors.background,
                                isScrollControlled: true,
                                builder: (c) => ExerciseSearchPicker(
                                    exercises: all,
                                    onSelected: (e) =>
                                        _addExerciseToDate(ref, date, e)));
                          }));
                        });
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
                        Future.microtask(() {
                          if (!mounted) return;
                          _showWbPicker(ref, date);
                        });
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
    if (!mounted) {
      print('[CWO_PLAN_DAY] STOP state not mounted after planDaysWithBlocks');
      return;
    }

    if (planDays.isEmpty) {
      print('[CWO_PLAN_DAY] NO_PLAN_DAYS_WITH_WBS');
      ScaffoldMessenger.of(this.context)
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
      context: this.context,
      backgroundColor: LabColors.background,
      isScrollControlled: true,
      builder: (c) => QualitySearchPicker(
        title: 'SELECT_PLAN_DAY',
        values: values,
        closeOnSelect: false,
        onSelected: (value) => Navigator.pop(c, value),
      ),
    );
    if (picked == null) {
      print('[CWO_PLAN_DAY] picker returned null / user cancelled');
      return;
    }
    if (!mounted) {
      print(
          '[CWO_PLAN_DAY] STOP state not mounted after picker picked=$picked');
      return;
    }

    print('[CWO_PLAN_DAY] picked="$picked"');
    final dayId = dayIdByLabel[picked];
    if (dayId == null) {
      print(
          '[CWO_PLAN_DAY] INVALID_PLAN_DAY_SELECTION picked="$picked" mapSize=${dayIdByLabel.length}');
      ScaffoldMessenger.of(this.context).showSnackBar(
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
    if (!mounted) {
      print('[CWO_PLAN_DAY] STOP state not mounted after planDayBlocks query');
      return;
    }

    if (blocks.isEmpty) {
      print('[CWO_PLAN_DAY] DAY_HAS_NO_WBS dayId=$dayId');
      ScaffoldMessenger.of(this.context)
          .showSnackBar(const SnackBar(content: Text('DAY_HAS_NO_WBS')));
      return;
    }

    _startInjectionProgress('PLAN DAY INJECTION');
    final options =
        await _showPlanDayInjectConfig(this.context, ref, date, blocks);
    if (options == null) {
      _finishInjectionProgress();
      return;
    }
    try {
      print(
          '[CWO_PLAN_DAY] calling injectPlanDay dayId=$dayId blocks=${blocks.length}');
      final result = await OvarchPlanInjectionService.injectPlanDay(
        db,
        date,
        blocks,
        options: options.toServiceOptions(),
        onProgress: (completed, total, label) async {
          if (!mounted || total <= 0) return;
          _setInjectionProgress(completed / total, label);
        },
      );
      _finishInjectionProgress();
      if (mounted) {
        final injected = result['injected'] ?? 0;
        final skipped = result['skipped'] ?? 0;
        print(
            '[CWO_PLAN_DAY] injectPlanDay result injected=$injected skipped=$skipped');
        ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(
            content:
                Text('PLAN_DAY_INJECTED: $injected WB / SKIPPED: $skipped')));
      } else {
        print('[CWO_PLAN_DAY] STOP state not mounted before snackbar');
      }
    } catch (e, stackTrace) {
      _finishInjectionProgress();
      print('[CWO_PLAN_DAY] injectPlanDay threw error=$e');
      print(stackTrace);
      if (mounted)
        ScaffoldMessenger.of(this.context)
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
  Future<void> _showWbPicker(WidgetRef ref, DateTime date) async {
    final db = ref.read(databaseProvider);
    final wbList = await OvarchPlanInjectionService.activeWorkoutBlocks(db);
    if (wbList.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(this.context)
            .showSnackBar(const SnackBar(content: Text('NO_WBS_CREATED')));
      }
      return;
    }

    final labelToWb = <String, Map<String, dynamic>>{};
    final labels = wbList.map((item) {
      final id = (item['id'] as num).toInt();
      final name = (item['name'] as String).trim();
      final label = '$name // ID $id';
      labelToWb[label] = item;
      print('[INJECT_WB] picker option label="$label" mappedId=$id');
      return label;
    }).toList();

    final picked = await showModalBottomSheet<String>(
      context: this.context,
      backgroundColor: LabColors.background,
      isScrollControlled: true,
      builder: (c) => QualitySearchPicker(
        title: 'SELECT WORKOUT BLOCK',
        values: labels,
        closeOnSelect: false,
        onSelected: (wbName) => Navigator.pop(c, wbName),
      ),
    );
    if (picked == null || !mounted) return;

    final selectedWb = labelToWb[picked];
    if (selectedWb == null) {
      ScaffoldMessenger.of(this.context).showSnackBar(
          const SnackBar(content: Text('INVALID_WORKOUT_BLOCK_SELECTION')));
      return;
    }

    final requestedBlockId = (selectedWb['id'] as num).toInt();
    final wbData = await OvarchPlanInjectionService.workoutBlockById(
            db, requestedBlockId) ??
        selectedWb;
    if (!mounted) return;

    final resolvedBlockId = (wbData['id'] as num).toInt();
    final knsRows = await db
        .customSelect(
            'SELECT id FROM workout_block_kns WHERE block_id = $resolvedBlockId')
        .get();
    if (!mounted) return;
    final knsIds = knsRows
        .map((row) => (row.data['id'] as num).toInt())
        .toList(growable: false);
    if (knsIds.isEmpty) {
      ScaffoldMessenger.of(this.context)
          .showSnackBar(const SnackBar(content: Text('WB_HAS_NO_KNS')));
      return;
    }

    _showInjectConfig(this.context, ref, date, wbData, knsIds: knsIds);
  }

  Future<_InjectOptions?> _showPlanDayInjectConfig(BuildContext context,
      WidgetRef ref, DateTime date, List<PlanDayBlock> blocks) async {
    final labels = blocks.map((b) => 'WB ${b.blockId}').join(' + ');
    bool injectPload = false;
    bool maxReps = true;
    bool minReps = false;
    bool rpe = false;
    bool allSets = true;
    return showDialog<_InjectOptions>(
        context: context,
        builder: (c) {
          return StatefulBuilder(
            builder: (c, setState) {
              void rebuild() => setState(() {});
              return AlertDialog(
                backgroundColor: LabColors.background,
                title: Text('PLAN DAY INJECT OPTIONS',
                    style: LabStyles.mono(context,
                        fontSize: 14, fontWeight: FontWeight.bold)),
                content: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(labels,
                          style: LabStyles.headline(context).copyWith(
                              fontSize: 14, color: LabColors.primary)),
                      const SizedBox(height: 12),
                      _planOptionRow(
                        context: context,
                        label: 'P.LOAD -> LOAD',
                        value: injectPload,
                        onTap: (_) {
                          debugPrint('[PLAN_DAY_CHECK] PLOAD ${!injectPload}');
                          injectPload = !injectPload;
                          rebuild();
                        },
                      ),
                      _planOptionRow(
                        context: context,
                        label: 'MAX REPS -> REPS',
                        value: maxReps,
                        onTap: (_) {
                          debugPrint('[PLAN_DAY_CHECK] MAX_REPS ${!maxReps}');
                          maxReps = !maxReps;
                          rebuild();
                        },
                      ),
                      _planOptionRow(
                        context: context,
                        label: 'MIN REPS -> REPS',
                        value: minReps,
                        onTap: (_) {
                          debugPrint('[PLAN_DAY_CHECK] MIN_REPS ${!minReps}');
                          minReps = !minReps;
                          rebuild();
                        },
                      ),
                      _planOptionRow(
                        context: context,
                        label: 'RPE -> RPE',
                        value: rpe,
                        onTap: (_) {
                          debugPrint('[PLAN_DAY_CHECK] RPE ${!rpe}');
                          rpe = !rpe;
                          rebuild();
                        },
                      ),
                      _planOptionRow(
                        context: context,
                        label: 'INJECT ALL SETS',
                        value: allSets,
                        onTap: (_) {
                          debugPrint('[PLAN_DAY_CHECK] ALL_SETS ${!allSets}');
                          allSets = !allSets;
                          rebuild();
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c),
                      child: Text('CANCEL',
                          style: LabStyles.mono(context, color: Colors.grey))),
                  TextButton(
                      onPressed: () => Navigator.pop(
                          c,
                          _InjectOptions(
                            injectPloadAsLoad: injectPload,
                            injectMaxRepsAsReps: maxReps,
                            injectMinRepsAsReps: minReps,
                            injectRpeAsRpe: rpe,
                            applyToAll: true,
                            allSets: allSets,
                          )),
                      child: Text('INJECT',
                          style: LabStyles.mono(context,
                              color: LabColors.primary))),
                ],
              );
            },
          );
        });
  }

  Widget _planOptionRow({
    required BuildContext context,
    required String label,
    required bool value,
    required void Function(bool?) onTap,
  }) {
    return InkWell(
      onTap: () => onTap(!value),
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: onTap,
            activeColor: LabColors.primary,
            checkColor: Colors.black,
          ),
          const SizedBox(width: 8),
          Text(label,
              style:
                  LabStyles.mono(context, fontSize: 10, color: Colors.white)),
        ],
      ),
    );
  }

  Future<void> _showInjectConfig(BuildContext context, WidgetRef ref,
      DateTime date, Map<String, dynamic> wbData,
      {List<int> knsIds = const <int>[]}) async {
    _startInjectionProgress('WB INJECTION');
    final result = await showDialog<_InjectOptions>(
      context: context,
      builder: (c) => _WbInjectConfigDialog(
        wbData: wbData,
        knsIds: knsIds,
        onInject: (options) => Navigator.pop(c, options),
        onCancel: () => Navigator.pop(c),
      ),
    );
    if (result == null) {
      _finishInjectionProgress();
      return;
    }
    if (context.mounted) {
      _injectWorkoutBlock(ref, date, wbData, options: result);
    } else {
      _finishInjectionProgress();
    }
  }

  Future<void> _injectWorkoutBlock(
      WidgetRef ref, DateTime d, Map<String, dynamic> wbData,
      {_InjectOptions? options}) async {
    final injectOptions = options ?? const _InjectOptions();
    final db = ref.read(databaseProvider);
    debugPrint(
        '[INJECT] START block=${wbData['name']} usePload=${injectOptions.injectPloadAsLoad} maxReps=${injectOptions.injectMaxRepsAsReps} minReps=${injectOptions.injectMinRepsAsReps} rpe=${injectOptions.injectRpeAsRpe} allSets=${injectOptions.allSets} applyAll=${injectOptions.applyToAll}');
    try {
      await OvarchPlanInjectionService.injectWorkoutBlock(
        db,
        d,
        wbData,
        options: injectOptions.toServiceOptions(),
        onKnsProgress: (completed, total, label) async {
          if (!mounted || total <= 0) return;
          _setInjectionProgress(completed / total, label);
        },
      );
      _finishInjectionProgress();
      if (mounted) {
        ScaffoldMessenger.of(this.context).showSnackBar(
            SnackBar(content: Text('INJECTED: ${wbData['name']}')));
      }
    } catch (e, stackTrace) {
      _finishInjectionProgress();
      debugPrint('[INJECT_WB] $e');
      debugPrint('[INJECT_WB] STACK $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(this.context)
            .showSnackBar(SnackBar(content: Text('WB_INJECT_ERROR: $e')));
      }
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
            style: LabStyles.mono(c,
                color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: Text('DELETE ALL LOGGED SETS FOR THIS SESSION?',
            style: LabStyles.mono(c, fontSize: 12)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c),
              child: Text('ABORT', style: LabStyles.mono(c))),
          TextButton(
            onPressed: () async {
              final db = ref.read(databaseProvider);
              final ids =
                  results.map((r) => r.readTable(db.workoutSets).id).toList();
              await (db.delete(db.workoutSets)..where((t) => t.id.isIn(ids)))
                  .go();
              if (c.mounted) Navigator.pop(c);
            },
            child: Text('PURGE_ALL',
                style: LabStyles.mono(c, color: Colors.redAccent)),
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
              style: LabStyles.headline(c).copyWith(fontSize: 16)),
          content: LabTextField(
              controller: nameC,
              label: 'BLUEPRINT_NAME',
              placeholder: 'NAME_YOUR_TEMPLATE...'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(c),
                child: Text('ABORT', style: LabStyles.mono(c))),
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
                  style: LabStyles.mono(c, color: LabColors.accent)),
            )
          ],
        ),
      );
    }
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
  final bool expanded;
  final ValueChanged<bool> onToggleExpanded;
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
      required this.expanded,
      required this.onToggleExpanded,
      this.showDragHandle = true});
  @override
  ConsumerState<_ExerciseModule> createState() => _ExerciseModuleState();
}

class _ExerciseModuleState extends ConsumerState<_ExerciseModule> {
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
    final db = ref.read(databaseProvider);
    final firstSet = widget.results.first.readTable(db.workoutSets);
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
    final useOriginalFace = tC.getBool(
        settings, 'APPCFG_KNS_FACE_LAYOUT_ORIGINAL',
        defaultValue: false);
    final setsCount = widget.results.length;
    final prCount = widget.results
        .where((r) => r.readTable(db.workoutSets).isPr)
        .length;

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
    final moduleBorderColor = tC.getColor(settings, 'UI_TAG_MODULE_BORDER',
        defaultColor: LabColors.cyanBorder);

    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 16),
      decoration: BoxDecoration(
        color: LabColors.background,
        border: Border(
          top: BorderSide(
              color: hasUtility ? utilityColor : moduleBorderColor,
              width: hasUtility ? 2 : 1.5),
        ),
        boxShadow: hasUtility
            ? [
                BoxShadow(
                    color: utilityColor.withValues(alpha: 0.1), blurRadius: 10)
              ]
            : null,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        useOriginalFace
            ? _buildFaceHeaderOriginal(context, e, loadType, isIso, hasUtility,
                utilities, tC, settings, typeColor, isoColor,
                uiTagBodyposition, uiTagPrimaryMuscle)
            : _buildFaceHeaderNew(context, e, loadType, isIso, hasUtility,
                utilities, tC, settings, typeColor, isoColor,
                uiTagBodyposition, setsCount, prCount),
        if (widget.expanded) ...[
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

  // Current KNS card face: metadata chips + history/drag handle on the top
  // row (with set/PR counters filling the gap), name + body-position tags
  // below, no primary muscle. Toggleable from APP.CONFIG > VISUALS > C.WO.
  Widget _buildFaceHeaderNew(
      BuildContext context,
      BaseExercise e,
      String loadType,
      bool isIso,
      bool hasUtility,
      List<String> utilities,
      ThemeController tC,
      Map<String, ThemeSetting> settings,
      Color typeColor,
      Color isoColor,
      Color uiTagBodyposition,
      int setsCount,
      int prCount) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Natural-width chip row — NOT wrapped in Expanded/Flexible so
              // it never gets squeezed into wrapping onto a second line.
              Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // [UTIL] chips — OUTSIDE InkWell to avoid gesture
                    // conflict with the ISO/NAT.LOAD badges below.
                    GestureDetector(
                      onTap: () => _showUtilityEditDialog(context),
                      child: Row(
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
                                border:
                                    Border.all(color: chipColor, width: 0.5),
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
                                    color: Colors.grey[600]!, fontSize: 8)),
                        ],
                      ),
                    ),
                    // ISO/NAT.LOAD badges — purely informational, no
                    // gesture.
                    if (isIso)
                      Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                              border:
                                  Border.all(color: isoColor, width: 0.5)),
                          child: Text('ISO',
                              style: LabStyles.mono(context,
                                  color: isoColor,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold))),
                    Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                            border: Border.all(color: typeColor, width: 0.5)),
                        child: Text(loadType,
                            style: LabStyles.mono(context,
                                color: typeColor,
                                fontSize: 8,
                                fontWeight: FontWeight.bold))),
                  ]),
              const SizedBox(width: 12),
              // Set/PR counters — bold and colored so they read as content,
              // not filler, while taking up the leftover space in this row.
              Expanded(
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$setsCount',
                          style: LabStyles.mono(context,
                              fontSize: 14,
                              color: LabColors.accent,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(width: 3),
                      Text('SETS',
                          style: LabStyles.mono(context,
                              fontSize: 9, color: Colors.grey[400])),
                      const SizedBox(width: 20),
                      Text('$prCount',
                          style: LabStyles.mono(context,
                              fontSize: 14,
                              color: prCount > 0
                                  ? Colors.redAccent
                                  : Colors.grey[600],
                              fontWeight: FontWeight.bold)),
                      const SizedBox(width: 3),
                      Text('PR',
                          style: LabStyles.mono(context,
                              fontSize: 9, color: Colors.grey[400])),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                      icon: const Icon(Icons.history,
                          color: LabColors.primary, size: 20),
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (c) => ExerciseHistoryScreen(
                                  exercise: widget.exercise)))),
                  if (widget.showDragHandle) ...[
                    const SizedBox(width: 8),
                    ReorderableDragStartListener(
                      index: widget.index,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 2),
                        child: Icon(Icons.drag_handle,
                            color: LabColors.primary, size: 20),
                      ),
                    ),
                  ],
                ]),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Exercise name + tags — the expand/collapse area
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => widget.onToggleExpanded(!widget.expanded),
              onLongPress: () => _showComplexModsModal(context),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.fullName,
                      style: LabStyles.headline(context)
                          .copyWith(fontSize: 18, color: Colors.white)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ...e.bodyPositionTags.map((tag) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: uiTagBodyposition.withValues(alpha: 0.1),
                              border: Border.all(
                                  color:
                                      uiTagBodyposition.withValues(alpha: 0.3),
                                  width: 0.5),
                            ),
                            child: Text(tag.toUpperCase(),
                                style: LabStyles.mono(context,
                                    fontSize: 7, color: uiTagBodyposition)),
                          )),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Pre-overhaul KNS card face: single combined gesture zone over
  // UTIL/ISO/NAT.LOAD, primary muscle shown next to body-position tags,
  // history/drag handle beside the exercise name. Kept for users who prefer
  // the original layout (APP.CONFIG > VISUALS > C.WO).
  Widget _buildFaceHeaderOriginal(
      BuildContext context,
      BaseExercise e,
      String loadType,
      bool isIso,
      bool hasUtility,
      List<String> utilities,
      ThemeController tC,
      Map<String, ThemeSetting> settings,
      Color typeColor,
      Color isoColor,
      Color uiTagBodyposition,
      Color uiTagPrimaryMuscle) {
    return Padding(
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
                                  border:
                                      Border.all(color: chipColor, width: 0.5),
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
                                      color: Colors.grey[600]!, fontSize: 8)),
                          ],
                        ),
                        if (isIso)
                          Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 1),
                              margin: const EdgeInsets.only(right: 4),
                              decoration: BoxDecoration(
                                  border:
                                      Border.all(color: isoColor, width: 0.5)),
                              child: Text('ISO',
                                  style: LabStyles.mono(context,
                                      color: isoColor,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold))),
                        Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                                border:
                                    Border.all(color: typeColor, width: 0.5)),
                            child: Text(loadType,
                                style: LabStyles.mono(context,
                                    color: typeColor,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold))),
                      ]),
                ),
                const SizedBox(height: 6),
                // Exercise name + tags — the expand/collapse area
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => widget.onToggleExpanded(!widget.expanded),
                    onLongPress: () => _showComplexModsModal(context),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.fullName,
                            style: LabStyles.headline(context)
                                .copyWith(fontSize: 18, color: Colors.white)),
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
                ),
              ],
            ),
          ),
          Row(mainAxisSize: MainAxisSize.min, children: [
            if (widget.showDragHandle)
              ReorderableDragStartListener(
                index: widget.index,
                child: const Padding(
                  padding:
                      EdgeInsets.only(left: 32, right: 6, top: 2, bottom: 2),
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
            Text('KNS.CARD_MODS',
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
                    style: LabStyles.headline(c).copyWith(fontSize: 16)),
                const SizedBox(height: 16),
                TextField(
                  controller: nameC,
                  style: LabStyles.mono(c,
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
                      style: LabStyles.mono(c,
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
                                            style: LabStyles.mono(c,
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
    final parent = context.findAncestorStateOfType<_WorkoutDayPageState>();
    parent?.expandBatch(batchName);
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
      return UnilateralPairFrame(
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
                    style: LabStyles.mono(c,
                        color: Colors.redAccent, fontWeight: FontWeight.bold)),
                content: Text('DELETE ALL SETS?',
                    style: LabStyles.mono(c, fontSize: 12)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c),
                      child: Text('ABORT', style: LabStyles.mono(c))),
                  TextButton(
                      onPressed: () async {
                        final db = ref.read(databaseProvider);
                        final ids = widget.results
                            .map((r) => r.readTable(db.workoutSets).id)
                            .toList();
                        await (db.delete(db.workoutSets)
                              ..where((t) => t.id.isIn(ids)))
                            .go();
                        if (c.mounted) Navigator.pop(c);
                      },
                      child: Text('PURGE',
                          style: LabStyles.mono(c, color: Colors.redAccent)))
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
      _rpeC,
      _rirC,
      _techC,
      _commentC;
  Timer? _db;
  Timer? _prDb;
  bool _exp = false;
  bool _showComment = false;
  bool _isIso = false;
  bool _hasVpPr = false;
  double _vpValue = 0;
  double _vpMultiplier = 1.0;
  Timer? _vpTimer;
  Future<List<drift.QueryRow>>? _somaticLogsFuture;

  String _formatInputValue(double value) {
    if (value.isFinite && value == value.truncateToDouble()) {
      return value.truncate().toString();
    }
    return value.toString();
  }

  double _computeVp() {
    final isJst = widget.isJst;
    final isL = widget.loadType == 'LASTRE';
    final w = isJst ? widget.bodyWeight : (double.tryParse(_lC.text) ?? 0);
    final tL = w + (isL ? widget.bodyWeight : 0);
    final reps = double.tryParse(_rC.text) ?? 0;
    final tonnage = tL * reps;
    final setOrdinal = widget.index + 1;
    return tonnage * (1 + _vpMultiplier * log(setOrdinal + 1));
  }

  @override
  void initState() {
    super.initState();
    _lC = TextEditingController(text: _formatInputValue(widget.set.weight));
    _rC = TextEditingController(text: _formatInputValue(widget.set.reps));
    _rpeC = TextEditingController(text: widget.set.rpe?.toString() ?? '');
    _rirC = TextEditingController(text: widget.set.rir?.toString() ?? '');
    _techC =
        TextEditingController(text: widget.set.technique?.toString() ?? '');
    _commentC = TextEditingController(text: widget.set.notes);

    if (widget.isJst) {
      _lC.text = _formatInputValue(widget.bodyWeight);
    }
    // Isometric detection for conditional UI
    _isIso = widget.isIso;
    // VP initialisation
    _vpMultiplier =
        (widget.exercise.parsedComplexMetadata["vpMultiplier"] as num?)?.toDouble() ?? 1.0;
    if (widget.set.complexMetadata != null &&
        widget.set.complexMetadata!.isNotEmpty) {
      try {
        final meta = jsonDecode(widget.set.complexMetadata!);
        _vpValue = (meta['vp'] as num?)?.toDouble() ?? 0;
      } catch (_) {}
    }
    if (_vpValue == 0) _vpValue = _computeVp();
  }

  @override
  void dispose() {
    _db?.cancel();
    _prDb?.cancel();
    _vpTimer?.cancel();
    _lC.dispose();
    _rC.dispose();
    _rpeC.dispose();
    _rirC.dispose();
    _techC.dispose();
    _commentC.dispose();
    super.dispose();
  }

  void _onChanged({bool includePr = true, int rawDelayMs = 100}) {
    _db?.cancel();
    _prDb?.cancel();
    _vpTimer?.cancel();

    _db = Timer(Duration(milliseconds: rawDelayMs), () async {
      await _saveCurrentSetRaw();
      if (!includePr || !mounted) return;
      _prDb = Timer(const Duration(milliseconds: 1200), () async {
        await _recalculatePrsAndEorm();
      });
    });

    // VP: 20s debounce — no recalcula mientras editas
    _vpTimer = Timer(const Duration(seconds: 10), () async {
      if (!mounted) return;
      _vpValue = _computeVp();
      final db = ref.read(databaseProvider);
      Map<String, dynamic> existingMeta = {};
      if (widget.set.complexMetadata != null &&
          widget.set.complexMetadata!.isNotEmpty) {
        try {
          existingMeta = jsonDecode(widget.set.complexMetadata!);
        } catch (_) {}
      }
      existingMeta["vp"] = _vpValue;
      await (db.update(db.workoutSets)
            ..where((t) => t.id.equals(widget.set.id)))
          .write(WorkoutSetsCompanion(
        complexMetadata: drift.Value(jsonEncode(existingMeta)),
      ));
      if (mounted) setState(() {});
    });
  }

  Future<void> _saveCurrentSetRaw() async {
    if (!mounted) return;

    final db = ref.read(databaseProvider);
    final w = double.tryParse(_lC.text) ?? 0;
    final r = double.tryParse(_rC.text) ?? 0;
    final rpe = double.tryParse(_rpeC.text);
    final rir = double.tryParse(_rirC.text);
    final te = int.tryParse(_techC.text);
    final isJst = widget.isJst;

    final actualWeight = isJst ? widget.bodyWeight : w;
    final rest = widget.set.restTimeSeconds ?? 120;
    final track = (widget.set.trackName ?? '').replaceFirst('[RED_PR]', '').trim();
    final notes = _commentC.text.trim();

    await (db.update(db.workoutSets)..where((t) => t.id.equals(widget.set.id)))
        .write(WorkoutSetsCompanion(
      weight: drift.Value(actualWeight),
      reps: drift.Value(r),
      rpe: drift.Value(rpe),
      rir: drift.Value(rir),
      restTimeSeconds: drift.Value(rest),
      technique: drift.Value(te),
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
    double maxHistoricalVp = 0;

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
      // VP PR detection — merged with histBefore loop
      if (s.complexMetadata != null && s.complexMetadata!.isNotEmpty) {
        try {
          final meta = jsonDecode(s.complexMetadata!);
          final histVp = (meta['vp'] as num?)?.toDouble() ?? 0;
          if (histVp > maxHistoricalVp) maxHistoricalVp = histVp;
        } catch (_) {}
      }
    }
    _hasVpPr = _computeVp() > maxHistoricalVp;

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
      int? steStore = s.technique;
      int ste = steStore ?? 1; // neutral multiplier for the score formula only
      String sNotes = s.notes ?? "";
      String sTrack = (s.trackName ?? "").replaceFirst('[RED_PR]', '').trim();

      if (s.id == widget.set.id) {
        sw = actualWeight;
        sr = r;
        srpe = rpe;
        sRir = rir;
        steStore = te;
        ste = te ?? 1;
        sNotes = _commentC.text.trim();
        sRest = widget.set.restTimeSeconds ?? 120;
        sTrack = (widget.set.trackName ?? '').replaceFirst('[RED_PR]', '').trim();
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
              technique: drift.Value(steStore),
              trackName: drift.Value(sTrack.isEmpty ? null : sTrack),
              notes: drift.Value(sNotes.isEmpty ? null : sNotes),
              isPr: drift.Value(sIsPr)));
    }
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
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  enableSuggestions: false,
                  onChanged: (_) => _onChanged()))
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
    final isL = widget.loadType == 'LASTRE';
    final isJst = widget.isJst;
    final isIso = widget.isIso;
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
    final setRowExpandedColor = tC.getColor(settings, 'UI_TAG_SETROW_EXPANDED',
        defaultColor: LabColors.primary);
    final showFailurePhase =
        tC.getBool(settings, 'APPCFG_SHOW_FAILURE_PHASE', defaultValue: true);
    final showKnsToggles =
        tC.getBool(settings, 'APPCFG_SHOW_KNS_TOGGLES', defaultValue: true);
    final summaryBorderColor = tC.getColor(settings, 'UI_TAG_SUMMARY_BORDER',
        defaultColor: LabColors.cyanBorder);

    return Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            decoration: BoxDecoration(
                border: Border.all(
                    color: isRed
                        ? Colors.redAccent
                        : (_exp
                            ? setRowExpandedColor.withValues(alpha: 0.4)
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
                            color: Colors.redAccent.withValues(alpha: 0.275),
                            blurRadius: 14)
                      ]
                    : (_exp
                        ? [
                            BoxShadow(
                                color: setRowExpandedColor.withValues(
                                    alpha: 0.05),
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
                        bottom:
                            BorderSide(color: Colors.grey[900]!, width: 0.5),
                        right:
                            BorderSide(color: Colors.grey[900]!, width: 0.5))),
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
                    textInputAction: TextInputAction.newline,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    autocorrect: false,
                    enableSuggestions: false,
                    onChanged: (_) =>
                        _onChanged(includePr: false, rawDelayMs: 300))),
          if (_exp) ...[
            const SizedBox(height: 12),
            Row(children: [
              _buildSummaryBox(
                  'TONNAGE',
                  (tL * (double.tryParse(_rC.text) ?? 0)).toStringAsFixed(1),
                  summaryBorderColor),
              const SizedBox(width: 4),
              _buildSummaryBox(
                  'eORM',
                  WorkoutCalculator.calculateEpley1RM(
                          tL, double.tryParse(_rC.text) ?? 0)
                      .toStringAsFixed(1),
                  summaryBorderColor),
              const SizedBox(width: 4),
              _buildSummaryBox(
                  'VP', _vpValue.toStringAsFixed(1), summaryBorderColor),
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
                      _buildGridInput('RIR', _rirC, flex: 1, noBorder: true),
                    ],
                    Container(width: 0.5, color: Colors.grey[700]),
                    _buildGridInput('TECH', _techC, flex: 1, noBorder: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildSomaticCard(),
            const SizedBox(height: 8),
            _buildNotesToggleCard(),
            const SizedBox(height: 12),
            if (showFailurePhase) _buildFailurePhaseCard(),
            _buildComplexSetModsButton(),
            const SizedBox(height: 12),
            if (showKnsToggles) _buildParticularTogglesCard(),
            const SizedBox(height: 20),
          ]
        ]));
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

  Widget _buildNotesToggleCard() {
    final hasNotes = widget.set.notes?.isNotEmpty ?? false;
    final settings = ref.watch(themeSettingsProvider).value ?? {};
    final notesColor = ref.read(themeControllerProvider).getColor(
        settings, 'UI_TAG_ADD_SET_NOTES',
        defaultColor: const Color(0xFF2979FF));
    return InkWell(
        onTap: () => setState(() => _showComment = !_showComment),
        child: Container(
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                border: Border.all(color: notesColor.withValues(alpha: 0.5)),
                color: _showComment
                    ? notesColor.withValues(alpha: 0.05)
                    : Colors.transparent),
            child: Text(
                hasNotes ? '[ ! ] EDIT SET NOTES' : '[ + ] ADD SET NOTES',
                textAlign: TextAlign.center,
                style: LabStyles.mono(context, fontSize: 8, color: notesColor))));
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
    final prColor = ref.read(themeControllerProvider).getColor(
        settings, 'UI_TAG_PR_HIGHLIGHT',
        defaultColor: const Color(0xFFE0242F));
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
                    : (hasPr || _hasVpPr
                        ? prColor.withValues(alpha: 0.12)
                        : LabColors.surfaceContainerHigh),
                child: Text('PR',
                    textAlign: TextAlign.center,
                    style: LabStyles.mono(context,
                        fontSize: 8,
                        color: isRed
                            ? Colors.white
                            : (hasPr || _hasVpPr ? prColor : Colors.grey))),
              ),
              // BOTTOM: Trophy / V! / both
              Container(
                  height: 44,
                  alignment: Alignment.center,
                  child: (hasPr || _hasVpPr)
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (hasPr)
                              isRed
                                  ? Icon(Icons.emoji_events,
                                      color: highlightColor, size: 20)
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
                                          color: Colors.white, size: 18)),
                            if (_hasVpPr) ...[
                              if (hasPr) const SizedBox(width: 4),
                              Text('V!',
                                  style: LabStyles.mono(context,
                                      fontSize: 14,
                                      color: Colors.cyanAccent,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ],
                        )
                      : const SizedBox())
            ])));
  }

  Widget _buildSummaryBox(String l, String v, Color borderColor) {
    return Expanded(
        child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            decoration: BoxDecoration(
                color: LabColors.surfaceDim,
                border: Border.all(
                    color: borderColor.withValues(alpha: 0.1), width: 0.5)),
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
        child: Material(
            color: Colors.transparent,
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
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      enableSuggestions: false,
                      onChanged: (_) => _onChanged()))
            ]))));
  }

  void _confirmDel(BuildContext c) {
    showDialog(
        context: c,
        builder: (c) => AlertDialog(
                backgroundColor: LabColors.background,
                title: Text('PURGE_SET',
                    style: LabStyles.mono(c, color: Colors.redAccent)),
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

  Widget _buildSomaticCard() {
    final db = ref.read(databaseProvider);
    final settings = ref.watch(themeSettingsProvider).value ?? {};
    final tC = ref.read(themeControllerProvider);
    final anomalyColor = tC.getColor(settings, 'UI_TAG_SOMATIC_ANOMALY',
        defaultColor: Colors.redAccent);
    final recoveryColor = tC.getColor(settings, 'UI_TAG_SOMATIC_RECOVERY',
        defaultColor: Colors.greenAccent);
    // Memoized so unrelated rebuilds of this widget don't re-run the query;
    // explicitly invalidated (set back to null) wherever somatic_logs is
    // mutated below.
    return FutureBuilder<List<drift.QueryRow>>(
        future: _somaticLogsFuture ??= db
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
                                  color: anomalyColor.withValues(alpha: 0.5))),
                          child: Text('[ + ] SOMATIC ANOMALY',
                              textAlign: TextAlign.center,
                              style: LabStyles.mono(context,
                                  fontSize: 7.68, color: anomalyColor)),
                        ),
                      )
                    : InkWell(
                        onTap: () => _showDiscomfortOverlay(context, false),
                        child: Container(
                          height: 52,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                              color: anomalyColor.withValues(alpha: 0.1),
                              border: Border.all(color: anomalyColor, width: 1)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                  child: Text(
                                      'SOMATIC_ANOMALIES: ${anomalies.length}',
                                      style: LabStyles.mono(context,
                                          fontSize: 6.72,
                                          color: anomalyColor,
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
                                  color: recoveryColor.withValues(alpha: 0.5))),
                          child: Text('[ + ] SOMATIC RECOVERY',
                              textAlign: TextAlign.center,
                              style: LabStyles.mono(context,
                                  fontSize: 7.68, color: recoveryColor)),
                        ),
                      )
                    : InkWell(
                        onTap: () => _showDiscomfortOverlay(context, true),
                        child: Container(
                          height: 52,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                              color: recoveryColor.withValues(alpha: 0.1),
                              border:
                                  Border.all(color: recoveryColor, width: 1)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                  child: Text(
                                      'SOMATIC_RECOVERIES: ${recoveries.length}',
                                      style: LabStyles.mono(context,
                                          fontSize: 6.72,
                                          color: recoveryColor,
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
    // Declared outside the StatefulBuilder so it survives setModalState
    // rebuilds (typing in dC/tC) instead of re-querying folders every time.
    Future<List<drift.QueryRow>>? foldersFuture;

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
                            child: QuickActionButton(
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
                            child: QuickActionButton(
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
                              future: foldersFuture ??= db
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
                                            if (mounted) {
                                              setState(() => _somaticLogsFuture = null);
                                            }
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

                            if (mounted) {
                              setState(() => _somaticLogsFuture = null);
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
  final bool maintainExtended;
  final VoidCallback onToggleMaintainExtended;

  const _WorkoutOptsSheet({
    required this.date,
    required this.results,
    required this.onMakeBlueprint,
    required this.onDeleteAll,
    required this.maintainExtended,
    required this.onToggleMaintainExtended,
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
    // Resolve the day's log ids through Drift's typed DateTime comparison
    // (not a raw millisecondsSinceEpoch literal against wl.date — Drift
    // stores DateTimeColumn as unix seconds, so that comparison never
    // matched anything).
    final selectedDate = widget.date;
    final todayStart =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final todayEnd = DateTime(
        selectedDate.year, selectedDate.month, selectedDate.day, 23, 59, 59);
    final logsToday = await (db.select(db.workoutLogs)
          ..where((t) => t.date.isBetweenValues(todayStart, todayEnd)))
        .get();
    final injectedBlockIds = <int>{};
    if (logsToday.isNotEmpty) {
      try {
        final logIds = logsToday.map((l) => l.id).join(',');
        final injectedSets = await db
            .customSelect(
                "SELECT DISTINCT json_extract(ws.complex_metadata, '\$.injectedFromBlock') as block_id "
                "FROM workout_sets ws "
                "WHERE ws.log_id IN ($logIds) "
                "AND ws.complex_metadata LIKE '%injectedFromBlock%'")
            .get();
        for (final row in injectedSets) {
          final rawBid = row.data['block_id'];
          final bid =
              rawBid is int ? rawBid : int.tryParse(rawBid?.toString() ?? '');
          if (bid != null) injectedBlockIds.add(bid);
        }
      } catch (_) {}
    }

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
    final slices = <WorkoutOptsSlice>[
      WorkoutOptsSlice(
        label: 'MAKE BLUEPRINT FROM CURRENT',
        icon: Icons.layers,
        color: _tc('UI_TAG_WO_BLUEPRINT', 'WO_BLUEPRINT'),
        onTap: widget.onMakeBlueprint,
      ),
      WorkoutOptsSlice(
        label: 'DELETE ALL SETS',
        icon: Icons.delete_forever,
        color: _tc('UI_TAG_WO_PURGE', 'WO_PURGE'),
        onTap: widget.onDeleteAll,
      ),
      WorkoutOptsSlice(
        label: widget.maintainExtended
            ? 'MAINTAIN EXTENDED ON'
            : 'MAINTAIN EXTENDED',
        icon: widget.maintainExtended ? Icons.visibility : Icons.visibility_off,
        color: widget.maintainExtended
            ? LabColors.primary
            : _tc('UI_TAG_WORKOUT_OPTS', 'WORKOUT_OPTS'),
        onTap: widget.onToggleMaintainExtended,
      ),
      WorkoutOptsSlice(
        label: 'VIEW WB PROJECTIONS',
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

  Widget _buildSlice(BuildContext context, WorkoutOptsSlice slice) {
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

class _KnsInjectOptions {
  bool injectPloadAsLoad;
  bool injectMaxRepsAsReps;
  bool injectMinRepsAsReps;
  bool injectRpeAsRpe;

  _KnsInjectOptions({
    this.injectPloadAsLoad = false,
    this.injectMaxRepsAsReps = true,
    this.injectMinRepsAsReps = false,
    this.injectRpeAsRpe = false,
  });
}

class _InjectOptions {
  final bool injectPloadAsLoad;
  final bool injectMaxRepsAsReps;
  final bool injectMinRepsAsReps;
  final bool injectRpeAsRpe;
  final bool applyToAll;
  final bool allSets;
  final Map<int, _KnsInjectOptions> knsOptions;

  const _InjectOptions({
    this.injectPloadAsLoad = false,
    this.injectMaxRepsAsReps = true,
    this.injectMinRepsAsReps = false,
    this.injectRpeAsRpe = false,
    this.applyToAll = true,
    this.allSets = true,
    this.knsOptions = const <int, _KnsInjectOptions>{},
  });

  WbInjectionOptions toServiceOptions() {
    final serviceKnsOptions = <int, WbKnsInjectionOptions>{
      for (final entry in knsOptions.entries)
        entry.key: WbKnsInjectionOptions(
          injectPloadAsLoad: entry.value.injectPloadAsLoad,
          injectMaxRepsAsReps: entry.value.injectMaxRepsAsReps,
          injectMinRepsAsReps: entry.value.injectMinRepsAsReps,
          injectRpeAsRpe: entry.value.injectRpeAsRpe,
        ),
    };
    return WbInjectionOptions(
      injectPloadAsLoad: injectPloadAsLoad,
      injectMaxRepsAsReps: injectMaxRepsAsReps,
      injectMinRepsAsReps: injectMinRepsAsReps,
      injectRpeAsRpe: injectRpeAsRpe,
      applyToAll: applyToAll,
      allSets: allSets,
      knsOptions: serviceKnsOptions,
    );
  }
}

class _WbInjectConfigDialog extends StatefulWidget {
  final Map<String, dynamic> wbData;
  final List<int> knsIds;
  final Function(_InjectOptions options) onInject;
  final VoidCallback onCancel;
  const _WbInjectConfigDialog({
    super.key,
    required this.wbData,
    required this.knsIds,
    required this.onInject,
    required this.onCancel,
  });
  @override
  State<_WbInjectConfigDialog> createState() => _WbInjectConfigDialogState();
}

class _WbInjectConfigDialogState extends State<_WbInjectConfigDialog> {
  bool _applyToAll = true;
  bool _injectPloadAsLoad = false;
  bool _injectMaxRepsAsReps = true;
  bool _injectMinRepsAsReps = false;
  bool _injectRpeAsRpe = false;
  bool _allSets = true;
  late Map<int, _KnsInjectOptions> _knsOptions;

  @override
  void initState() {
    super.initState();
    _knsOptions = {
      for (final id in widget.knsIds) id: _KnsInjectOptions(),
    };
  }

  void _syncKnsFromGlobal() {
    setState(() {
      _knsOptions = {
        for (final id in widget.knsIds)
          id: _KnsInjectOptions(
            injectPloadAsLoad: _injectPloadAsLoad,
            injectMaxRepsAsReps: _injectMaxRepsAsReps,
            injectMinRepsAsReps: _injectMinRepsAsReps,
            injectRpeAsRpe: _injectRpeAsRpe,
          ),
      };
    });
  }

  void _setKnsOption(int knsId, void Function(_KnsInjectOptions) update) {
    setState(() {
      final current = _knsOptions[knsId] ?? _KnsInjectOptions();
      final next = _KnsInjectOptions(
        injectPloadAsLoad: current.injectPloadAsLoad,
        injectMaxRepsAsReps: current.injectMaxRepsAsReps,
        injectMinRepsAsReps: current.injectMinRepsAsReps,
        injectRpeAsRpe: current.injectRpeAsRpe,
      );
      update(next);
      _knsOptions[knsId] = next;
    });
  }

  Widget _optionRow({
    required String label,
    required bool value,
    required void Function(bool?) onTap,
    bool disabled = false,
    bool compareWithGlobal = false,
  }) {
    final effectiveValue = compareWithGlobal && _applyToAll
        ? value == _globalValueFor(label)
        : value;
    return CheckboxListTile(
      value: effectiveValue,
      onChanged: disabled ? null : onTap,
      title: Text(label,
          style: LabStyles.mono(context, fontSize: 10, color: Colors.white)),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      activeColor: LabColors.primary,
      checkColor: Colors.black,
    );
  }

  bool _globalValueFor(String label) {
    switch (label) {
      case 'P.LOAD -> LOAD':
        return _injectPloadAsLoad;
      case 'MAX REPS -> REPS':
        return _injectMaxRepsAsReps;
      case 'MIN REPS -> REPS':
        return _injectMinRepsAsReps;
      case 'RPE -> RPE':
        return _injectRpeAsRpe;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: LabColors.background,
      title: Text('INJECT WB OPTIONS',
          style: LabStyles.mono(context,
              fontSize: 14, fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.62,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${widget.wbData['name']}',
                  style: LabStyles.headline(context)
                      .copyWith(fontSize: 16, color: LabColors.primary)),
              const SizedBox(height: 12),
              _chipRow(),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    border: Border.all(
                        color: LabColors.primary.withValues(alpha: 0.55),
                        width: 0.5)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('GLOBAL KNS/SET OPTIONS',
                        style: LabStyles.mono(context,
                            fontSize: 10,
                            color: LabColors.primary,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _optionRow(
                      label: 'P.LOAD -> LOAD',
                      value: _injectPloadAsLoad,
                      onTap: (_) => setState(
                          () => _injectPloadAsLoad = !_injectPloadAsLoad),
                      disabled: !_applyToAll,
                    ),
                    _optionRow(
                      label: 'MAX REPS -> REPS',
                      value: _injectMaxRepsAsReps,
                      onTap: (_) => setState(
                          () => _injectMaxRepsAsReps = !_injectMaxRepsAsReps),
                      disabled: !_applyToAll,
                    ),
                    _optionRow(
                      label: 'MIN REPS -> REPS',
                      value: _injectMinRepsAsReps,
                      onTap: (_) => setState(
                          () => _injectMinRepsAsReps = !_injectMinRepsAsReps),
                      disabled: !_applyToAll,
                    ),
                    _optionRow(
                      label: 'RPE -> RPE',
                      value: _injectRpeAsRpe,
                      onTap: (_) =>
                          setState(() => _injectRpeAsRpe = !_injectRpeAsRpe),
                      disabled: !_applyToAll,
                    ),
                    const SizedBox(height: 8),
                    _optionRow(
                      label: 'INJECT ALL SETS',
                      value: _allSets,
                      onTap: (_) => setState(() => _allSets = !_allSets),
                    ),
                  ],
                ),
              ),
              if (!_applyToAll) ..._perKnsSections(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: widget.onCancel,
            child: Text('CANCEL',
                style: LabStyles.mono(context, color: Colors.grey))),
        TextButton(
            onPressed: () => widget.onInject(_InjectOptions(
                  injectPloadAsLoad: _injectPloadAsLoad,
                  injectMaxRepsAsReps: _injectMaxRepsAsReps,
                  injectMinRepsAsReps: _injectMinRepsAsReps,
                  injectRpeAsRpe: _injectRpeAsRpe,
                  applyToAll: _applyToAll,
                  allSets: _allSets,
                  knsOptions: _knsOptions,
                )),
            child: Text('INJECT',
                style: LabStyles.mono(context, color: LabColors.primary))),
      ],
    );
  }

  Widget _chipRow() {
    final applyColor = _applyToAll ? LabColors.primary : Colors.grey[800]!;
    final perColor = _applyToAll ? Colors.grey[800]! : LabColors.primary;
    return Row(
      children: [
        _scopeChip(
          label: 'APPLY TO ALL KNS/SETS',
          active: _applyToAll,
          color: applyColor,
          onTap: () {
            setState(() {
              _applyToAll = true;
              _knsOptions = {
                for (final id in widget.knsIds)
                  id: _KnsInjectOptions(
                    injectPloadAsLoad: _injectPloadAsLoad,
                    injectMaxRepsAsReps: _injectMaxRepsAsReps,
                    injectMinRepsAsReps: _injectMinRepsAsReps,
                    injectRpeAsRpe: _injectRpeAsRpe,
                  ),
              };
            });
          },
        ),
        const SizedBox(width: 8),
        _scopeChip(
          label: 'EACH KNS',
          active: !_applyToAll,
          color: perColor,
          onTap: () {
            setState(() => _applyToAll = false);
            if (_knsOptions.isEmpty) _syncKnsFromGlobal();
          },
        ),
      ],
    );
  }

  Widget _scopeChip({
    required String label,
    required bool active,
    required Color color,
    required void Function() onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.zero,
          border: Border.all(
              color: active
                  ? LabColors.primary.withValues(alpha: 0.8)
                  : Colors.grey[800]!,
              width: 0.5),
        ),
        child: Text(label,
            style: LabStyles.mono(context,
                fontSize: 8, color: active ? Colors.black : Colors.white)),
      ),
    );
  }

  List<Widget> _perKnsSections() {
    final sections = <Widget>[];
    for (final id in widget.knsIds) {
      final opts = _knsOptions[id] ?? _KnsInjectOptions();
      sections.add(const SizedBox(height: 12));
      sections.add(Text('KNS #$id',
          style: LabStyles.mono(context,
              fontSize: 10,
              color: LabColors.primary,
              fontWeight: FontWeight.bold)));
      sections.add(Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[800]!, width: 0.5)),
        child: Column(
          children: [
            _optionRow(
              label: 'P.LOAD -> LOAD',
              value: opts.injectPloadAsLoad,
              compareWithGlobal: true,
              onTap: (_) => _setKnsOption(
                  id, (o) => o.injectPloadAsLoad = !o.injectPloadAsLoad),
            ),
            _optionRow(
              label: 'MAX REPS -> REPS',
              value: opts.injectMaxRepsAsReps,
              compareWithGlobal: true,
              onTap: (_) => _setKnsOption(
                  id, (o) => o.injectMaxRepsAsReps = !o.injectMaxRepsAsReps),
            ),
            _optionRow(
              label: 'MIN REPS -> REPS',
              value: opts.injectMinRepsAsReps,
              compareWithGlobal: true,
              onTap: (_) => _setKnsOption(
                  id, (o) => o.injectMinRepsAsReps = !o.injectMinRepsAsReps),
            ),
            _optionRow(
              label: 'RPE -> RPE',
              value: opts.injectRpeAsRpe,
              compareWithGlobal: true,
              onTap: (_) => _setKnsOption(
                  id, (o) => o.injectRpeAsRpe = !o.injectRpeAsRpe),
            ),
          ],
        ),
      ));
    }
    return sections;
  }
}
