import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../providers/database_provider.dart';
import '../database/database.dart';
import '../localization/strings.dart';
import 'styles.dart';
import 'lab_widgets.dart';
import 'main_scaffold.dart';
import 'exercise_form_screen.dart';
import 'exercise_history_screen.dart';
import 'kinisi_tree_screen.dart';
import 'kns_tree_alert_screen.dart';

enum _SortMode { alphaAsc, alphaDesc, mostUsed, leastUsed, mostRecent, leastRecent, unusedFirst }

extension _SortModeLabel on _SortMode {
  String get label {
    switch (this) {
      case _SortMode.alphaAsc: return 'A-Z';
      case _SortMode.alphaDesc: return 'Z-A';
      case _SortMode.mostUsed: return 'MOST USED';
      case _SortMode.leastUsed: return 'LEAST USED';
      case _SortMode.mostRecent: return 'MOST RECENT';
      case _SortMode.leastRecent: return 'LEAST RECENT';
      case _SortMode.unusedFirst: return 'NO USE FIRST';
    }
  }
}

class _UsageInfo {
  final int count;
  final int lastUsed;
  const _UsageInfo(this.count, this.lastUsed);
}

bool _isFavorite(BaseExercise e) {
  if (e.complexMetadata == null) return false;
  try {
    final meta = jsonDecode(e.complexMetadata!) as Map<String, dynamic>;
    return meta['favorite'] == true;
  } catch (_) {
    return false;
  }
}

class LedgerScreen extends ConsumerStatefulWidget {
  const LedgerScreen({super.key});

  @override
  ConsumerState<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends ConsumerState<LedgerScreen> with SingleTickerProviderStateMixin {
  String _filterQuery = '';
  final TextEditingController _filterController = TextEditingController();
  _SortMode _listSortMode = _SortMode.alphaAsc;
  Timer? _debounce;
  Future<Map<int, _UsageInfo>>? _usageFuture;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _usageFuture = _loadUsage(ref.read(databaseProvider));
    _tabController = TabController(length: 2, vsync: this);
  }

  void _refreshUsage() {
    if (mounted) {
      // NB: must be a block body, not `() => _usageFuture = ...` — an
      // assignment expression evaluates to the assigned value, so an arrow
      // closure here returns the Future itself, which setState() rejects
      // ("callback argument returned a Future").
      setState(() {
        _usageFuture = _loadUsage(ref.read(databaseProvider));
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _filterController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _toggleFavorite(BaseExercise e) async {
    final db = ref.read(databaseProvider);
    Map<String, dynamic> meta = {};
    if (e.complexMetadata != null) {
      try {
        meta = jsonDecode(e.complexMetadata!) as Map<String, dynamic>;
      } catch (_) {}
    }
    meta['favorite'] = !_isFavorite(e);
    await (db.update(db.baseExercises)..where((t) => t.id.equals(e.id)))
        .write(BaseExercisesCompanion(complexMetadata: drift.Value(jsonEncode(meta))));
    ref.invalidate(allExercisesProvider);
  }

  Future<Map<int, _UsageInfo>> _loadUsage(AppDatabase db) async {
    final rows = await db.customSelect(
        'SELECT base_exercise_id, COUNT(*) cnt, MAX(timestamp) last_ts FROM workout_sets GROUP BY base_exercise_id').get();
    return {
      for (final r in rows)
        r.data['base_exercise_id'] as int:
            _UsageInfo(r.data['cnt'] as int, (r.data['last_ts'] as int?) ?? 0)
    };
  }

  List<BaseExercise> _sortedBy(
      List<BaseExercise> list, Map<int, _UsageInfo> usage, _SortMode mode) {
    final sorted = List<BaseExercise>.from(list);
    switch (mode) {
      case _SortMode.alphaAsc:
        sorted.sort((a, b) => a.fullName.compareTo(b.fullName));
        break;
      case _SortMode.alphaDesc:
        sorted.sort((a, b) => b.fullName.compareTo(a.fullName));
        break;
      case _SortMode.mostUsed:
        sorted.sort((a, b) =>
            (usage[b.id]?.count ?? 0).compareTo(usage[a.id]?.count ?? 0));
        break;
      case _SortMode.leastUsed:
        sorted.sort((a, b) =>
            (usage[a.id]?.count ?? 0).compareTo(usage[b.id]?.count ?? 0));
        break;
      case _SortMode.mostRecent:
        sorted.sort((a, b) =>
            (usage[b.id]?.lastUsed ?? 0).compareTo(usage[a.id]?.lastUsed ?? 0));
        break;
      case _SortMode.leastRecent:
        sorted.sort((a, b) =>
            (usage[a.id]?.lastUsed ?? 0).compareTo(usage[b.id]?.lastUsed ?? 0));
        break;
      case _SortMode.unusedFirst:
        sorted.sort((a, b) {
          final usedA = usage.containsKey(a.id) ? 1 : 0;
          final usedB = usage.containsKey(b.id) ? 1 : 0;
          if (usedA != usedB) return usedA.compareTo(usedB);
          return a.fullName.compareTo(b.fullName);
        });
        break;
    }
    return sorted;
  }

  // Folder-tab sort (favorites + within each muscle group) always stays
  // alphabetical — the sort picker lives only in the LIST tab per user request.
  List<BaseExercise> _sorted(List<BaseExercise> list, Map<int, _UsageInfo> usage) =>
      _sortedBy(list, usage, _SortMode.alphaAsc);

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(allExercisesProvider);
    final lang = ref.watch(languageProvider).value ?? 'en';

    return MainScaffold(
      title: 'KINISI INVENTORY',
      screenKey: 'LEDGER',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: _buildFilters(context, lang),
          ),
          const SizedBox(height: 8),
          TabBar(
            controller: _tabController,
            indicatorColor: LabColors.accent,
            labelColor: LabColors.accent,
            unselectedLabelColor: Colors.grey[500],
            labelStyle: LabStyles.mono(context, fontSize: 11, fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: tr(lang, 'FOLDERS')),
              Tab(text: tr(lang, 'LIST')),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: exercisesAsync.when(
              data: (exercises) {
                return FutureBuilder<Map<int, _UsageInfo>>(
                  future: _usageFuture,
                  builder: (context, usageSnap) {
                    final usage = usageSnap.data ?? {};

                    var filtered = exercises;
                    if (_filterQuery.isNotEmpty) {
                      final q = _filterQuery.toLowerCase();
                      filtered = exercises.where((e) => _matchesInventorySearch(e, q)).toList();
                    }

                    final favorites = exercises.where(_isFavorite).toList();
                    final unusedCount = exercises.where((e) => !usage.containsKey(e.id)).length;

                    return TabBarView(
                      controller: _tabController,
                      children: [
                        _buildFoldersTab(context, exercises, filtered, favorites, usage, unusedCount, lang),
                        _buildListTab(context, exercises, filtered, usage, unusedCount, favorites.length, lang),
                      ],
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: LabColors.primary)),
              error: (e, s) => Center(child: Text('${tr(lang, 'ERROR:')} $e', style: LabStyles.mono(context, color: Colors.redAccent))),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'kns_config_data_fab',
            mini: true,
            backgroundColor: Colors.black,
            shape: const RoundedRectangleBorder(side: BorderSide(color: LabColors.accent, width: 0.5)),
            tooltip: 'KNS.CONFIG / DATA',
            onPressed: () => _showKnsConfigMenu(context),
            child: const Icon(Icons.tune, color: LabColors.accent, size: 20),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'add_exercise_fab',
            backgroundColor: Colors.black,
            shape: const RoundedRectangleBorder(side: BorderSide(color: LabColors.accent, width: 0.5)),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ExerciseFormScreen())),
            child: const Icon(Icons.add, color: LabColors.accent, size: 32),
          ),
        ],
      ),
      bottomNavigationBar: const LabFooter(),
    );
  }

  void _showKnsConfigMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: LabColors.background,
      isScrollControlled: true,
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('KNS.CONFIG / DATA',
                  style: LabStyles.headline(context).copyWith(fontSize: 14)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.account_tree_outlined, color: LabColors.accent),
                title: Text('TREE.ALERT',
                    style: LabStyles.mono(context, fontSize: 12, color: Colors.white)),
                subtitle: Text('Broken progression/regression/alter links',
                    style: LabStyles.mono(context, fontSize: 9, color: Colors.grey)),
                onTap: () {
                  Navigator.pop(c);
                  Navigator.push(context,
                      MaterialPageRoute(builder: (ctx) => const KnsTreeAlertScreen()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFoldersTab(
    BuildContext context,
    List<BaseExercise> exercises,
    List<BaseExercise> filtered,
    List<BaseExercise> favorites,
    Map<int, _UsageInfo> usage,
    int unusedCount,
    String lang,
  ) {
    if (filtered.isEmpty) {
      return ListView(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 40),
        children: [
          _buildStatsHeader(context, exercises.length, unusedCount, favorites.length, lang),
          const SizedBox(height: 40),
          _buildEmptyState(lang),
        ],
      );
    }

    final Map<String, Map<String, List<BaseExercise>>> grouped = {};
    for (var e in filtered) {
      final field = (e.field == null || e.field!.isEmpty) ? 'NOFIELD' : e.field!.toUpperCase();
      final muscle = e.primaryMuscleGroup ?? 'UNKNOWN';
      grouped.putIfAbsent(field, () => {});
      grouped[field]!.putIfAbsent(muscle, () => []).add(e);
    }
    final fields = grouped.keys.toList()..sort();

    return ListView(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 100),
      children: [
        _buildStatsHeader(context, exercises.length, unusedCount, favorites.length, lang),
        const SizedBox(height: 12),
        if (favorites.isNotEmpty) ...[
          _FavoritesSection(
            favorites: _sorted(favorites, usage),
            usage: usage,
            onToggleFavorite: _toggleFavorite,
            onDataChanged: _refreshUsage,
            lang: lang,
          ),
          const SizedBox(height: 16),
        ],
        for (final fieldName in fields)
          _FieldGroup(
            key: ValueKey('field_$fieldName'),
            name: fieldName,
            muscles: grouped[fieldName]!,
            usage: usage,
            sorter: (list) => _sorted(list, usage),
            onToggleFavorite: _toggleFavorite,
            onDataChanged: _refreshUsage,
          ),
      ],
    );
  }

  Widget _buildListTab(
    BuildContext context,
    List<BaseExercise> exercises,
    List<BaseExercise> filtered,
    Map<int, _UsageInfo> usage,
    int unusedCount,
    int favCount,
    String lang,
  ) {
    final sortedList = _sortedBy(filtered, usage, _listSortMode);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(child: _buildStatsHeader(context, exercises.length, unusedCount, favCount, lang)),
              _buildSortPicker(context, lang),
            ],
          ),
        ),
        const Divider(height: 1, color: LabColors.cyanBorder, thickness: 0.2),
        Expanded(
          child: sortedList.isEmpty
              ? _buildEmptyState(lang)
              : ListView.builder(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 14, bottom: 100),
                  itemCount: sortedList.length,
                  itemBuilder: (context, i) {
                    final e = sortedList[i];
                    return _ExerciseCard(
                      key: ValueKey('ex_list_${e.id}'),
                      exercise: e,
                      usage: usage[e.id],
                      isFavorite: _isFavorite(e),
                      onToggleFavorite: () => _toggleFavorite(e),
                      onDataChanged: _refreshUsage,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSortPicker(BuildContext context, String lang) {
    return PopupMenuButton<_SortMode>(
      color: LabColors.surfaceContainerHigh,
      initialValue: _listSortMode,
      onSelected: (mode) => setState(() => _listSortMode = mode),
      itemBuilder: (context) => _SortMode.values
          .map((m) => PopupMenuItem(
                value: m,
                child: Text(tr(lang, m.label), style: LabStyles.mono(context, fontSize: 11)),
              ))
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(color: Colors.white24, width: 0.5),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.sort, size: 13, color: Colors.grey[400]),
          const SizedBox(width: 4),
          Text(tr(lang, _listSortMode.label), style: LabStyles.mono(context, fontSize: 8, color: Colors.white70)),
        ]),
      ),
    );
  }

  Widget _buildStatsHeader(BuildContext context, int total, int unused, int favCount, String lang) {
    return Row(
      children: [
        _statChip(context, '$total', tr(lang, 'MOVEMENTS')),
        const SizedBox(width: 16),
        _statChip(context, '$unused', tr(lang, 'UNUSED')),
        const SizedBox(width: 16),
        _statChip(context, '$favCount', tr(lang, 'FAVORITES')),
      ],
    );
  }

  Widget _statChip(BuildContext context, String value, String label) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(value, style: LabStyles.mono(context, fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(width: 4),
        Text(label, style: LabStyles.mono(context, fontSize: 8, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildEmptyState(String lang) {
    return Center(child: Text("NO_MOVEMENTS_FOUND", style: LabStyles.mono(context, color: Colors.grey)));
  }

  bool _matchesInventorySearch(BaseExercise e, String q) {
    return [
      e.fullName,
      e.name,
      e.prefixes,
      e.suffixes,
      e.implements,
      e.bodyPositions,
      e.primaryMuscleGroup,
      e.secondaryMuscleGroup,
      e.patternType,
      e.intention,
      e.tissueType,
      e.field,
    ].any((value) => (value ?? '').toLowerCase().contains(q));
  }

  Widget _buildFilters(BuildContext context, String lang) {
    return SizedBox(
      height: 44,
      child: TextField(
        controller: _filterController,
        style: LabStyles.mono(context, fontSize: 12, color: Colors.white),
        decoration: InputDecoration(
          hintText: tr(lang, 'SEARCH INVENTORY...'),
          hintStyle: LabStyles.mono(context, fontSize: 10, color: Colors.grey[600]),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: Colors.grey[800]!, width: 0.5)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: Colors.grey[800]!, width: 0.5)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: const BorderSide(color: LabColors.primary, width: 0.5)),
          isDense: true,
          filled: true,
          fillColor: LabColors.surfaceDim,
        ),
        onChanged: (v) {
          _debounce?.cancel();
          _debounce = Timer(const Duration(milliseconds: 220), () {
            if (mounted) setState(() => _filterQuery = v);
          });
        },
      ),
    );
  }
}

class _FavoritesSection extends StatefulWidget {
  final List<BaseExercise> favorites;
  final Map<int, _UsageInfo> usage;
  final Future<void> Function(BaseExercise) onToggleFavorite;
  final VoidCallback onDataChanged;
  // Optional: this widget has no ref access, so the caller (which does)
  // threads the current lang through. Defaults to 'en' for other call sites.
  final String lang;
  const _FavoritesSection({
    required this.favorites,
    required this.usage,
    required this.onToggleFavorite,
    required this.onDataChanged,
    this.lang = 'en',
  });
  @override State<_FavoritesSection> createState() => _FavoritesSectionState();
}

class _FavoritesSectionState extends State<_FavoritesSection> {
  bool _isExpanded = false;
  @override Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: LabColors.accent.withValues(alpha: 0.4), width: 2)),
        color: LabColors.surfaceContainerLow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(children: [
                Icon(Icons.star, size: 14, color: LabColors.accent),
                const SizedBox(width: 8),
                Text('${tr(widget.lang, 'FAVORITES')} (${widget.favorites.length})',
                    style: LabStyles.mono(context, fontSize: 10, fontWeight: FontWeight.bold, color: LabColors.accent)),
                const Spacer(),
                Icon(_isExpanded ? Icons.expand_less : Icons.expand_more, size: 16, color: LabColors.accent),
              ]),
            ),
          ),
          if (_isExpanded)
            ...widget.favorites.map((e) => _ExerciseCard(
                  key: ValueKey('ex_fav_${e.id}'),
                  exercise: e,
                  usage: widget.usage[e.id],
                  isFavorite: true,
                  onToggleFavorite: () => widget.onToggleFavorite(e),
                  onDataChanged: widget.onDataChanged,
                )),
        ],
      ),
    );
  }
}

class _FieldGroup extends StatefulWidget {
  final String name;
  final Map<String, List<BaseExercise>> muscles;
  final Map<int, _UsageInfo> usage;
  final List<BaseExercise> Function(List<BaseExercise>) sorter;
  final Future<void> Function(BaseExercise) onToggleFavorite;
  final VoidCallback onDataChanged;
  const _FieldGroup({
    super.key,
    required this.name,
    required this.muscles,
    required this.usage,
    required this.sorter,
    required this.onToggleFavorite,
    required this.onDataChanged,
  });
  @override State<_FieldGroup> createState() => _FieldGroupState();
}

class _FieldGroupState extends State<_FieldGroup> {
  bool _isExpanded = false;
  @override Widget build(BuildContext context) {
    final expanded = _isExpanded;
    final totalCount = widget.muscles.values.fold(0, (sum, list) => sum + list.length);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: expanded ? LabColors.surfaceContainerLow : Colors.black,
        border: Border.all(color: expanded ? LabColors.primary : LabColors.cyanBorder.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Column(
        children: [
          ListTile(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            dense: true, visualDensity: VisualDensity.compact,
            leading: Icon(Icons.folder_open, color: expanded ? LabColors.primary : Colors.grey, size: 18),
            title: Text(widget.name, style: LabStyles.mono(context, fontWeight: FontWeight.bold, fontSize: 12, color: expanded ? LabColors.primary : Colors.white)),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              Text("$totalCount", style: LabStyles.mono(context, fontSize: 10, color: Colors.grey)),
              const SizedBox(width: 8),
              Icon(expanded ? Icons.expand_less : Icons.expand_more, size: 16, color: Colors.grey),
            ]),
          ),
          if (expanded) ...[
            const Divider(height: 1, color: LabColors.cyanBorder, thickness: 0.2),
            ...() {
              final muscleNames = widget.muscles.keys.toList()..sort();
              return muscleNames.map((m) => _MuscleGroup(
                    key: ValueKey('muscle_${widget.name}_$m'),
                    name: m,
                    exercises: widget.muscles[m]!,
                    usage: widget.usage,
                    sorter: widget.sorter,
                    onToggleFavorite: widget.onToggleFavorite,
                    onDataChanged: widget.onDataChanged,
                  ));
            }(),
          ],
        ],
      ),
    );
  }
}

class _MuscleGroup extends StatefulWidget {
  final String name;
  final List<BaseExercise> exercises;
  final Map<int, _UsageInfo> usage;
  final List<BaseExercise> Function(List<BaseExercise>) sorter;
  final Future<void> Function(BaseExercise) onToggleFavorite;
  final VoidCallback onDataChanged;
  const _MuscleGroup({
    super.key,
    required this.name,
    required this.exercises,
    required this.usage,
    required this.sorter,
    required this.onToggleFavorite,
    required this.onDataChanged,
  });
  @override State<_MuscleGroup> createState() => _MuscleGroupState();
}

class _MuscleGroupState extends State<_MuscleGroup> {
  bool _isExpanded = false;
  @override Widget build(BuildContext context) {
    final expanded = _isExpanded;
    final sorted = widget.sorter(widget.exercises);
    return Column(children: [
      InkWell(
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: expanded ? Colors.white.withValues(alpha: 0.05) : Colors.transparent,
          child: Row(children: [
            Icon(Icons.layers, size: 14, color: expanded ? LabColors.accent : Colors.grey),
            const SizedBox(width: 12),
            Text(widget.name.toUpperCase(), style: LabStyles.mono(context, fontSize: 10, color: expanded ? LabColors.accent : Colors.grey[400])),
            const Spacer(),
            Text("${widget.exercises.length}", style: LabStyles.mono(context, fontSize: 9, color: Colors.grey)),
            const SizedBox(width: 8),
            Icon(expanded ? Icons.remove : Icons.add, size: 12, color: Colors.grey),
          ]),
        ),
      ),
      if (expanded)
        Column(
          children: sorted.map((e) => _ExerciseCard(
                key: ValueKey('ex_${e.id}'),
                exercise: e,
                usage: widget.usage[e.id],
                isFavorite: _isFavorite(e),
                onToggleFavorite: () => widget.onToggleFavorite(e),
                onDataChanged: widget.onDataChanged,
              )).toList(),
        ),
    ]);
  }
}

class _ExerciseCard extends ConsumerStatefulWidget {
  final BaseExercise exercise;
  final _UsageInfo? usage;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onDataChanged;
  const _ExerciseCard({
    super.key,
    required this.exercise,
    required this.usage,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onDataChanged,
  });
  @override ConsumerState<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends ConsumerState<_ExerciseCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider).value ?? 'en';
    final e = widget.exercise;
    final pattern = (e.patternType ?? '').toUpperCase();

    // Technical Metadata
    final intentionText = e.intention ?? '';
    final metaMatch = RegExp(r'\[NT:(.*)\|ISO:(.*)\]').firstMatch(intentionText);
    String loadType = 'EXT.LOAD';
    bool isIsometric = intentionText.startsWith('[ISO]');
    if (metaMatch != null) {
      loadType = metaMatch.group(1) ?? 'EXT.LOAD';
      isIsometric = metaMatch.group(2) == 'true';
    } else if (['LASTRE', 'EXT.LOAD', 'JST.BW'].contains(e.field)) {
      loadType = e.field!;
    }
    final discipline = (e.field == loadType) ? 'N/A' : (e.field ?? 'N/A');

    return Container(
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: LabColors.cyanBorder, width: 0.5), bottom: BorderSide(color: LabColors.cyanBorder, width: 0.1)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _isExpanded = !_isExpanded),
                    child: Container(
                      // `alignment` makes a Container expand to fill the
                      // space its parent (Expanded, here) offers, then
                      // aligns its child within that full box — this is
                      // what actually centers short names vertically;
                      // relying on Row/Column's own sizing wasn't enough
                      // because the Column always shrink-wraps to content.
                      alignment: Alignment.centerLeft,
                      child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Flexible(child: Text(e.fullName, style: LabStyles.mono(context, fontWeight: FontWeight.bold, fontSize: 12))),
                          if (widget.usage == null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              color: Colors.grey[850],
                              child: Text('UNUSED', style: LabStyles.mono(context, fontSize: 6, color: Colors.grey[500])),
                            ),
                          ],
                        ]),
                        if (e.bodyPositionTags.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 4,
                            runSpacing: 2,
                            children: e.bodyPositionTags.map((tag) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent.withValues(alpha: 0.1),
                                border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3), width: 0.5),
                              ),
                              child: Text(tag.toUpperCase(), style: LabStyles.mono(context, fontSize: 7, color: Colors.blueAccent)),
                            )).toList(),
                          ),
                        ],
                        const SizedBox(height: 2),
                        Text(pattern, style: LabStyles.mono(context, fontSize: 8, color: LabColors.primary.withValues(alpha: 0.7))),
                      ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(widget.isFavorite ? Icons.star : Icons.star_border,
                      color: widget.isFavorite ? LabColors.accent : Colors.grey, size: 16),
                  tooltip: tr(lang, 'FAVORITE'),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: widget.onToggleFavorite,
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.hub, color: Colors.greenAccent, size: 16),
                  tooltip: 'SKILL_TREE',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => KinisiTreeScreen(exercise: e))),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.edit, color: LabColors.primary, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => ExerciseFormScreen(exercise: e))),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.grey, size: 16),
                  tooltip: 'EXTRA_KNS_ACTIONS',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _showExtraActions(context, lang),
                ),
              ],
            ),
          ),
          if (_isExpanded) ...[
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.black,
              child: Column(
                children: [
                  _buildRow('MUSCLE', e.primaryMuscleGroup ?? 'N/A', 'FIELD', discipline),
                  const SizedBox(height: 6),
                  _buildRow('TISSUE', e.tissueType ?? 'N/A', 'INTENTION', intentionText.replaceFirst(RegExp(r'\[.*\]'), '').trim()),
                  const SizedBox(height: 6),
                  _buildRow('LOAD', loadType, 'TYPE', isIsometric ? 'ISOMETRIC' : 'DYNAMIC'),
                  if (widget.usage != null) ...[
                    const SizedBox(height: 6),
                    _buildRow('LOGGED_SETS', '${widget.usage!.count}', 'LAST_USED',
                        widget.usage!.lastUsed == 0
                            ? 'N/A'
                            : DateTime.fromMillisecondsSinceEpoch(widget.usage!.lastUsed)
                                .toString()
                                .split(' ')
                                .first),
                  ],
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }

  void _showExtraActions(BuildContext context, String lang) {
    showModalBottomSheet(
      context: context,
      backgroundColor: LabColors.background,
      builder: (c) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('EXTRA_KNS_ACTIONS', style: LabStyles.headline(context).copyWith(fontSize: 16)),
            const SizedBox(height: 24),
            _buildActionTile(context, Icons.history, 'VIEW_HISTORY', Colors.amber, () {
              Navigator.pop(c);
              Navigator.push(context, MaterialPageRoute(builder: (c) => ExerciseHistoryScreen(exercise: widget.exercise)));
            }),
            const SizedBox(height: 8),
            _buildActionTile(context, Icons.cleaning_services, 'PURGE_HISTORY', Colors.orangeAccent, () {
              Navigator.pop(c);
              _confirmPurgeHistory(context, lang);
            }),
            const SizedBox(height: 8),
            _buildActionTile(context, Icons.delete_forever, 'DELETE_KNS', Colors.redAccent, () {
              Navigator.pop(c);
              _confirmDelete(context, lang);
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 12),
            Text(label, style: LabStyles.mono(context, color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _confirmPurgeHistory(BuildContext context, String lang) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: LabColors.background,
        title: Text('RESET_PERFORMANCE_HISTORY', style: LabStyles.mono(context, color: Colors.amber)),
        content: Text('DELETING_ALL_SETS_LOGS_FOR_THIS_MOVEMENT_ONLY. METADATA_WILL_REMAIN.', style: LabStyles.mono(context, fontSize: 10)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(tr(lang, 'CANCEL'), style: LabStyles.mono(context))),
          TextButton(
            onPressed: () async {
              final db = ref.read(databaseProvider);
              final exerciseId = widget.exercise.id;
              try {
                await (db.delete(db.workoutSets)..where((t) => t.baseExerciseId.equals(exerciseId))).go();
                widget.onDataChanged();
                if (context.mounted) Navigator.pop(context);
              } catch (_) {}
            },
            child: Text('PURGE_HISTORY', style: LabStyles.mono(context, color: Colors.amber)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String lang) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: LabColors.background,
        title: Text('DELETE_KNS', style: LabStyles.mono(context, color: Colors.redAccent)),
        content: Text('THIS_WILL_DELETE_THE_KNS_AND_ALL_ITS_DATA._THIS_CANNOT_BE_UNDONE.', style: LabStyles.mono(context, fontSize: 10)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(tr(lang, 'CANCEL'), style: LabStyles.mono(context))),
          TextButton(
            onPressed: () async {
              final db = ref.read(databaseProvider);
              final exerciseId = widget.exercise.id;
              Navigator.pop(context); // close dialog immediately
              debugPrint('[DELETE_KNS] start exerciseId=$exerciseId (${widget.exercise.fullName})');
              try {
                // Raw SQL transaction: delete from all related tables in FK-safe order
                debugPrint('[DELETE_KNS] PRAGMA foreign_keys = OFF');
                await db.customStatement('PRAGMA foreign_keys = OFF');
                debugPrint('[DELETE_KNS] DELETE FROM progression_edges ...');
                await db.customStatement('DELETE FROM progression_edges WHERE from_variant_id IN (SELECT id FROM exercise_variants WHERE base_id = $exerciseId) OR to_variant_id IN (SELECT id FROM exercise_variants WHERE base_id = $exerciseId)');
                debugPrint('[DELETE_KNS] DELETE FROM exercise_variants ...');
                await db.customStatement('DELETE FROM exercise_variants WHERE base_id = $exerciseId');
                debugPrint('[DELETE_KNS] DELETE FROM workout_sets ...');
                await db.customStatement('DELETE FROM workout_sets WHERE base_exercise_id = $exerciseId');
                debugPrint('[DELETE_KNS] DELETE FROM blueprint_exercises ...');
                await db.customStatement('DELETE FROM blueprint_exercises WHERE base_exercise_id = $exerciseId');
                debugPrint('[DELETE_KNS] DELETE FROM base_exercises ...');
                await db.customStatement('DELETE FROM base_exercises WHERE id = $exerciseId');
                debugPrint('[DELETE_KNS] PRAGMA foreign_keys = ON');
                await db.customStatement('PRAGMA foreign_keys = ON');
                widget.onDataChanged();
                // Note: this is the dialog's context, which is already
                // unmounted by the time we get here (popped above, before
                // the awaits) — gating on context.mounted here always
                // evaluated false, so the list never refreshed. Use the
                // State's own `mounted` instead.
                ref.invalidate(allExercisesProvider);
                debugPrint('[DELETE_KNS] success exerciseId=$exerciseId');
              } catch (e, st) {
                debugPrint('[DELETE_KNS] ERROR exerciseId=$exerciseId: $e');
                debugPrint('[DELETE_KNS] STACKTRACE:\n$st');
                await db.customStatement('PRAGMA foreign_keys = ON');
                if (mounted) {
                  ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(
                    content: Text('DELETE_ERROR: $e', style: LabStyles.mono(this.context)),
                    backgroundColor: Colors.redAccent,
                  ));
                }
              }
            },
            child: Text('CONFIRM_PURGE', style: LabStyles.mono(context, color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String l1, String v1, String l2, String v2) {
    return Row(children: [
      Expanded(child: _buildData(l1, v1)),
      const SizedBox(width: 8),
      Expanded(child: _buildData(l2, v2)),
    ]);
  }

  Widget _buildData(String label, String value) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: LabStyles.mono(context, fontSize: 6, color: Colors.grey)),
      Text(value.toUpperCase(), style: LabStyles.mono(context, fontSize: 9, color: Colors.white)),
    ]);
  }
}
