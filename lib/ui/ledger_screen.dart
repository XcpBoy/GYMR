import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/database_provider.dart';
import '../database/database.dart';
import 'styles.dart';
import 'lab_widgets.dart';
import 'main_scaffold.dart';
import 'add_exercise_screen.dart';
import 'edit_exercise_screen.dart';
import 'exercise_history_screen.dart';
import 'kinisi_tree_screen.dart';

class LedgerScreen extends ConsumerStatefulWidget {
  const LedgerScreen({super.key});

  @override
  ConsumerState<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends ConsumerState<LedgerScreen> {
  String _filterQuery = '';
  final TextEditingController _filterController = TextEditingController();

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(allExercisesProvider);

    return MainScaffold(
      title: 'KINISI INVENTORY', 
      screenKey: 'LEDGER',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildFilters(context),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: exercisesAsync.when(
              data: (exercises) {
                // Apply client-side filters
                var filtered = exercises;
                if (_filterQuery.isNotEmpty) {
                  final q = _filterQuery.toLowerCase();
                  filtered = exercises
                      .where((e) => _matchesInventorySearch(e, q))
                      .toList();
                }
                
                if (filtered.isEmpty) return _buildEmptyState();
                
                final Map<String, Map<String, List<BaseExercise>>> grouped = {};
                for (var e in filtered) {
                  final field = (e.field == null || e.field!.isEmpty) ? 'NOFIELD' : e.field!.toUpperCase();
                  final muscle = e.primaryMuscleGroup ?? 'UNKNOWN';
                  grouped.putIfAbsent(field, () => {});
                  grouped[field]!.putIfAbsent(muscle, () => []).add(e);
                }
                
                final fields = grouped.keys.toList()..sort();
                
                return ListView.builder(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 100),
                  itemCount: fields.length,
                  itemBuilder: (context, index) {
                    final fieldName = fields[index];
                    return _FieldGroup(name: fieldName, muscles: grouped[fieldName]!);
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
    return Column(
      children: [
        LabTextField(
          controller: _filterController,
          label: 'SEARCH_INVENTORY',
          onChanged: (v) => setState(() => _filterQuery = v),
        ),
      ],
    );
  }
}

class _FieldGroup extends StatefulWidget {
  final String name;
  final Map<String, List<BaseExercise>> muscles;
  const _FieldGroup({required this.name, required this.muscles});
  @override State<_FieldGroup> createState() => _FieldGroupState();
}

class _FieldGroupState extends State<_FieldGroup> {
  bool _isExpanded = false;
  @override Widget build(BuildContext context) {
    final totalCount = widget.muscles.values.fold(0, (sum, list) => sum + list.length);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _isExpanded ? LabColors.surfaceContainerLow : Colors.black,
        border: Border.all(color: _isExpanded ? LabColors.primary : LabColors.cyanBorder.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Column(
        children: [
          ListTile(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            dense: true, visualDensity: VisualDensity.compact,
            leading: Icon(Icons.folder_open, color: _isExpanded ? LabColors.primary : Colors.grey, size: 18),
            title: Text(widget.name, style: LabStyles.mono(context, fontWeight: FontWeight.bold, fontSize: 12, color: _isExpanded ? LabColors.primary : Colors.white)),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              Text("$totalCount", style: LabStyles.mono(context, fontSize: 10, color: Colors.grey)),
              const SizedBox(width: 8),
              Icon(_isExpanded ? Icons.expand_less : Icons.expand_more, size: 16, color: Colors.grey),
            ]),
          ),
          if (_isExpanded) ...[
            const Divider(height: 1, color: LabColors.cyanBorder, thickness: 0.2),
            ...() {
              final muscleNames = widget.muscles.keys.toList()..sort();
              return muscleNames.map((m) => _MuscleGroup(name: m, exercises: widget.muscles[m]!));
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
  const _MuscleGroup({required this.name, required this.exercises});
  @override State<_MuscleGroup> createState() => _MuscleGroupState();
}

class _MuscleGroupState extends State<_MuscleGroup> {
  bool _isExpanded = false;
  @override Widget build(BuildContext context) {
    return Column(children: [
      InkWell(
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: _isExpanded ? Colors.white.withValues(alpha: 0.05) : Colors.transparent,
          child: Row(children: [
            Icon(Icons.layers, size: 14, color: _isExpanded ? LabColors.accent : Colors.grey),
            const SizedBox(width: 12),
            Text(widget.name.toUpperCase(), style: LabStyles.mono(context, fontSize: 10, color: _isExpanded ? LabColors.accent : Colors.grey[400])),
            const Spacer(),
            Text("${widget.exercises.length}", style: LabStyles.mono(context, fontSize: 9, color: Colors.grey)),
            const SizedBox(width: 8),
            Icon(_isExpanded ? Icons.remove : Icons.add, size: 12, color: Colors.grey),
          ]),
        ),
      ),
      if (_isExpanded) Column(children: widget.exercises.map((e) => _ExerciseCard(exercise: e)).toList()),
    ]);
  }
}

class _ExerciseCard extends ConsumerStatefulWidget {
  final BaseExercise exercise;
  const _ExerciseCard({required this.exercise});
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
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _isExpanded = !_isExpanded),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.fullName, style: LabStyles.mono(context, fontWeight: FontWeight.bold, fontSize: 12)),
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

