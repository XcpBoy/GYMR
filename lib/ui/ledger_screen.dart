import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../providers/database_provider.dart';
import '../database/database.dart';
import 'styles.dart';
import 'lab_widgets.dart';
import 'main_scaffold.dart';
import 'add_exercise_screen.dart';
import 'edit_exercise_screen.dart';
import 'exercise_history_screen.dart';
import 'kinisi_tree_screen.dart';

enum _SortMode { alpha, mostUsed, recentlyUsed }

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

class _LedgerScreenState extends ConsumerState<LedgerScreen> {
  String _filterQuery = '';
  final TextEditingController _filterController = TextEditingController();
  _SortMode _sortMode = _SortMode.alpha;

  String get _sortLabel {
    switch (_sortMode) {
      case _SortMode.alpha: return 'A-Z';
      case _SortMode.mostUsed: return 'MOST USED';
      case _SortMode.recentlyUsed: return 'RECENT';
    }
  }

  @override
  void dispose() {
    _filterController.dispose();
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

  List<BaseExercise> _sorted(List<BaseExercise> list, Map<int, _UsageInfo> usage) {
    final sorted = List<BaseExercise>.from(list);
    switch (_sortMode) {
      case _SortMode.alpha:
        sorted.sort((a, b) => a.fullName.compareTo(b.fullName));
        break;
      case _SortMode.mostUsed:
        sorted.sort((a, b) =>
            (usage[b.id]?.count ?? 0).compareTo(usage[a.id]?.count ?? 0));
        break;
      case _SortMode.recentlyUsed:
        sorted.sort((a, b) =>
            (usage[b.id]?.lastUsed ?? 0).compareTo(usage[a.id]?.lastUsed ?? 0));
        break;
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(allExercisesProvider);
    final db = ref.read(databaseProvider);

    return MainScaffold(
      title: 'KINISI INVENTORY',
      screenKey: 'LEDGER',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: _buildFilters(context),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: exercisesAsync.when(
              data: (exercises) {
                return FutureBuilder<Map<int, _UsageInfo>>(
                  future: _loadUsage(db),
                  builder: (context, usageSnap) {
                    final usage = usageSnap.data ?? {};

                    var filtered = exercises;
                    if (_filterQuery.isNotEmpty) {
                      final q = _filterQuery.toLowerCase();
                      filtered = exercises.where((e) => _matchesInventorySearch(e, q)).toList();
                    }

                    final favorites = exercises.where(_isFavorite).toList();
                    final unusedCount = exercises.where((e) => !usage.containsKey(e.id)).length;

                    if (filtered.isEmpty) {
                      return ListView(
                        padding: const EdgeInsets.only(left: 16, right: 16, top: 40),
                        children: [
                          _buildStatsHeader(context, exercises.length, unusedCount, favorites.length),
                          const SizedBox(height: 40),
                          _buildEmptyState(),
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
                    final searching = _filterQuery.isNotEmpty;

                    return ListView(
                      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 100),
                      children: [
                        _buildStatsHeader(context, exercises.length, unusedCount, favorites.length),
                        const SizedBox(height: 12),
                        if (!searching && favorites.isNotEmpty) ...[
                          _buildFavoritesSection(context, favorites, usage),
                          const SizedBox(height: 16),
                        ],
                        for (final fieldName in fields)
                          _FieldGroup(
                            name: fieldName,
                            muscles: grouped[fieldName]!,
                            forceExpanded: searching,
                            usage: usage,
                            sorter: (list) => _sorted(list, usage),
                            onToggleFavorite: _toggleFavorite,
                          ),
                      ],
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: LabColors.primary)),
              error: (e, s) => Center(child: Text('ERROR: $e', style: LabStyles.mono(context, color: Colors.redAccent))),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        shape: const RoundedRectangleBorder(side: BorderSide(color: LabColors.accent, width: 0.5)),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddExerciseScreen())),
        child: const Icon(Icons.add, color: LabColors.accent, size: 32),
      ),
      bottomNavigationBar: const LabFooter(),
    );
  }

  Widget _buildStatsHeader(BuildContext context, int total, int unused, int favCount) {
    return Row(
      children: [
        _statChip(context, '$total', 'MOVEMENTS'),
        const SizedBox(width: 16),
        _statChip(context, '$unused', 'UNUSED'),
        const SizedBox(width: 16),
        _statChip(context, '$favCount', 'FAVORITES'),
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

  Widget _buildFavoritesSection(BuildContext context, List<BaseExercise> favorites,
      Map<int, _UsageInfo> usage) {
    final sorted = _sorted(favorites, usage);
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: LabColors.accent.withValues(alpha: 0.4), width: 2)),
        color: LabColors.surfaceContainerLow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(children: [
              Icon(Icons.star, size: 14, color: LabColors.accent),
              const SizedBox(width: 8),
              Text('FAVORITES (${favorites.length})',
                  style: LabStyles.mono(context, fontSize: 10, fontWeight: FontWeight.bold, color: LabColors.accent)),
            ]),
          ),
          ...sorted.map((e) => _ExerciseCard(
                exercise: e,
                usage: usage[e.id],
                isFavorite: true,
                onToggleFavorite: () => _toggleFavorite(e),
              )),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
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

  Widget _buildFilters(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: SizedBox(
            height: 44,
            child: TextField(
              controller: _filterController,
              style: LabStyles.mono(context, fontSize: 12, color: Colors.white),
              decoration: InputDecoration(
                hintText: 'SEARCH_INVENTORY...',
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
              onChanged: (v) => setState(() => _filterQuery = v),
            ),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          height: 44,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              shape: const RoundedRectangleBorder(),
              side: const BorderSide(color: Colors.white24, width: 0.5),
            ),
            onPressed: () => setState(
                () => _sortMode = _SortMode.values[(_sortMode.index + 1) % _SortMode.values.length]),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.sort, size: 13, color: Colors.grey[400]),
              const SizedBox(width: 4),
              Text(_sortLabel, style: LabStyles.mono(context, fontSize: 8, color: Colors.white70)),
            ]),
          ),
        ),
      ],
    );
  }
}

class _FieldGroup extends StatefulWidget {
  final String name;
  final Map<String, List<BaseExercise>> muscles;
  final bool forceExpanded;
  final Map<int, _UsageInfo> usage;
  final List<BaseExercise> Function(List<BaseExercise>) sorter;
  final Future<void> Function(BaseExercise) onToggleFavorite;
  const _FieldGroup({
    required this.name,
    required this.muscles,
    required this.forceExpanded,
    required this.usage,
    required this.sorter,
    required this.onToggleFavorite,
  });
  @override State<_FieldGroup> createState() => _FieldGroupState();
}

class _FieldGroupState extends State<_FieldGroup> {
  bool _isExpanded = false;
  @override Widget build(BuildContext context) {
    final expanded = _isExpanded || widget.forceExpanded;
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
                    name: m,
                    exercises: widget.muscles[m]!,
                    forceExpanded: widget.forceExpanded,
                    usage: widget.usage,
                    sorter: widget.sorter,
                    onToggleFavorite: widget.onToggleFavorite,
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
  final bool forceExpanded;
  final Map<int, _UsageInfo> usage;
  final List<BaseExercise> Function(List<BaseExercise>) sorter;
  final Future<void> Function(BaseExercise) onToggleFavorite;
  const _MuscleGroup({
    required this.name,
    required this.exercises,
    required this.forceExpanded,
    required this.usage,
    required this.sorter,
    required this.onToggleFavorite,
  });
  @override State<_MuscleGroup> createState() => _MuscleGroupState();
}

class _MuscleGroupState extends State<_MuscleGroup> {
  bool _isExpanded = false;
  @override Widget build(BuildContext context) {
    final expanded = _isExpanded || widget.forceExpanded;
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
                exercise: e,
                usage: widget.usage[e.id],
                isFavorite: _isFavorite(e),
                onToggleFavorite: () => widget.onToggleFavorite(e),
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
  const _ExerciseCard({
    required this.exercise,
    required this.usage,
    required this.isFavorite,
    required this.onToggleFavorite,
  });
  @override ConsumerState<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends ConsumerState<_ExerciseCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
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
                  tooltip: 'FAVORITE',
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
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => EditExerciseScreen(exercise: e))),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.grey, size: 16),
                  tooltip: 'EXTRA_KNS_ACTIONS',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _showExtraActions(context),
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

  void _showExtraActions(BuildContext context) {
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
              _confirmPurgeHistory(context);
            }),
            const SizedBox(height: 8),
            _buildActionTile(context, Icons.delete_forever, 'DELETE_KNS', Colors.redAccent, () {
              Navigator.pop(c);
              _confirmDelete(context);
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

  void _confirmPurgeHistory(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: LabColors.background,
        title: Text('RESET_PERFORMANCE_HISTORY', style: LabStyles.mono(context, color: Colors.amber)),
        content: Text('DELETING_ALL_SETS_LOGS_FOR_THIS_MOVEMENT_ONLY. METADATA_WILL_REMAIN.', style: LabStyles.mono(context, fontSize: 10)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('CANCEL', style: LabStyles.mono(context))),
          TextButton(
            onPressed: () async {
              final db = ref.read(databaseProvider);
              final exerciseId = widget.exercise.id;
              try {
                await (db.delete(db.workoutSets)..where((t) => t.baseExerciseId.equals(exerciseId))).go();
                if (context.mounted) Navigator.pop(context);
              } catch (_) {}
            },
            child: Text('PURGE_HISTORY', style: LabStyles.mono(context, color: Colors.amber)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: LabColors.background,
        title: Text('DELETE_KNS', style: LabStyles.mono(context, color: Colors.redAccent)),
        content: Text('THIS_WILL_DELETE_THE_KNS_AND_ALL_ITS_DATA._THIS_CANNOT_BE_UNDONE.', style: LabStyles.mono(context, fontSize: 10)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('CANCEL', style: LabStyles.mono(context))),
          TextButton(
            onPressed: () async {
              final db = ref.read(databaseProvider);
              final exerciseId = widget.exercise.id;
              Navigator.pop(context); // close dialog immediately
              try {
                // Raw SQL transaction: delete from all related tables in FK-safe order
                await db.customStatement('PRAGMA foreign_keys = OFF');
                await db.customStatement('DELETE FROM progression_edges WHERE from_variant_id IN (SELECT id FROM exercise_variants WHERE base_id = $exerciseId) OR to_variant_id IN (SELECT id FROM exercise_variants WHERE base_id = $exerciseId)');
                await db.customStatement('DELETE FROM exercise_variants WHERE base_id = $exerciseId');
                await db.customStatement('DELETE FROM workout_sets WHERE base_exercise_id = $exerciseId');
                await db.customStatement('DELETE FROM blueprint_exercises WHERE base_exercise_id = $exerciseId');
                await db.customStatement('DELETE FROM base_exercises WHERE id = $exerciseId');
                await db.customStatement('PRAGMA foreign_keys = ON');
                if (context.mounted) ref.invalidate(allExercisesProvider);
              } catch (e) {
                debugPrint("DELETE_KNS error: $e");
                await db.customStatement('PRAGMA foreign_keys = ON');
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
