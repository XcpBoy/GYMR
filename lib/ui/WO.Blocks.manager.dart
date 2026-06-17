import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'styles.dart';
import 'lab_widgets.dart';
import 'main_scaffold.dart';
import 'WB.editor.dart';
import '../providers/database_provider.dart';
import '../providers/theme_provider.dart';
import '../database/database.dart';

// ─── MOCK WORKOUT BLOCK (placeholder — will be DB-driven) ────────────

// ─── MOCK WORKOUT BLOCK (placeholder — will be DB-driven) ────────────

class WorkoutBlockEntry {
  final String id;
  final String name;
  final String? folder;
  final DateTime createdAt;
  WorkoutBlockEntry(
      {required this.id, required this.name, this.folder, DateTime? createdAt})
      : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'folder': folder,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory WorkoutBlockEntry.fromJson(Map<String, dynamic> j) =>
      WorkoutBlockEntry(
        id: j['id'] as String,
        name: j['name'] as String,
        folder: j['folder'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(j['createdAt'] as int),
      );
}

final workoutBlockListProvider =
    StateNotifierProvider<WorkoutBlockListNotifier, List<WorkoutBlockEntry>>(
        (ref) {
  return WorkoutBlockListNotifier(ref);
});

class WorkoutBlockListNotifier extends StateNotifier<List<WorkoutBlockEntry>> {
  final Ref _ref;

  WorkoutBlockListNotifier(this._ref) : super([]) {
    _initTable();
  }

  Future<AppDatabase> _db() async => _ref.read(databaseProvider);

  Future<void> _initTable() async {
    final db = await _db();
    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS wb_store (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        data TEXT NOT NULL
      )
    ''');
    try {
      await db.customStatement(
          'ALTER TABLE workout_blocks ADD COLUMN deleted_at INTEGER');
    } catch (_) {}
    await _load();
  }

  Future<void> _load() async {
    try {
      final db = await _db();
      final rows =
          await db.customSelect('SELECT data FROM wb_store WHERE id = 1').get();
      if (rows.isNotEmpty) {
        final raw = rows.first.data['data'] as String;
        final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
        state = list.map((j) => WorkoutBlockEntry.fromJson(j)).toList();
      }
    } catch (e) {
      debugPrint('[WB_LOAD] error: $e');
    }
  }

  Future<void> _save() async {
    try {
      final db = await _db();
      final data = jsonEncode(state.map((b) => b.toJson()).toList());
      await db.customStatement(
        'INSERT OR REPLACE INTO wb_store (id, data) VALUES (1, ?)',
        [data],
      );
      for (final b in state) {
        final blockId = int.tryParse(b.id.replaceAll('wb_', '')) ?? 0;
        if (blockId == 0) continue;
        await db.customStatement(
          'INSERT OR IGNORE INTO workout_blocks (id, name, created_at, deleted_at) VALUES (?, ?, ?, 0)',
          [blockId, b.name.toUpperCase(), b.createdAt.millisecondsSinceEpoch],
        );
        await db.customStatement(
          'UPDATE workout_blocks SET name = ?, created_at = ?, deleted_at = 0 WHERE id = ?',
          [b.name.toUpperCase(), b.createdAt.millisecondsSinceEpoch, blockId],
        );
      }
    } catch (e) {
      debugPrint('[WB_SAVE] error: $e');
    }
  }

  Future<void> add(String name, {String? folder}) async {
    final id = 'wb_${DateTime.now().millisecondsSinceEpoch}';
    state = [
      ...state,
      WorkoutBlockEntry(id: id, name: name.toUpperCase(), folder: folder)
    ];
    await _save();
  }

  Future<void> rename(String id, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    state = state
        .map((b) => b.id == id
            ? WorkoutBlockEntry(
                id: b.id,
                name: trimmed.toUpperCase(),
                folder: b.folder,
                createdAt: b.createdAt)
            : b)
        .toList();
    await _save();
  }

  Future<void> remove(String id) async {
    final db = await _db();
    final blockId = int.tryParse(id.replaceAll('wb_', '')) ?? 0;
    if (blockId != 0) {
      final deletedAt = DateTime.now().millisecondsSinceEpoch;
      await db.customStatement(
          'UPDATE workout_blocks SET deleted_at = ? WHERE id = ?',
          [deletedAt, blockId]);
      await db.customStatement(
          'DELETE FROM wb_kns_store WHERE block_id = ?', [blockId]);
    }
    state = state.where((b) => b.id != id).toList();
    await _save();
  }

  Future<void> removeAll() async {
    final db = await _db();
    final deletedAt = DateTime.now().millisecondsSinceEpoch;
    for (final b in state) {
      final blockId = int.tryParse(b.id.replaceAll('wb_', '')) ?? 0;
      if (blockId != 0) {
        await db.customStatement(
            'UPDATE workout_blocks SET deleted_at = ? WHERE id = ?',
            [deletedAt, blockId]);
        await db.customStatement(
            'DELETE FROM wb_kns_store WHERE block_id = ?', [blockId]);
      }
    }
    state = [];
    await _save();
  }

  Future<void> removePastAggressively() async {
    final db = await _db();
    final activeIds = <int>{};
    for (final b in state) {
      final blockId = int.tryParse(b.id.replaceAll('wb_', '')) ?? 0;
      if (blockId != 0) activeIds.add(blockId);
    }

    final allIds = <int>{};
    try {
      final realRows =
          await db.customSelect('SELECT id FROM workout_blocks').get();
      for (final row in realRows) {
        final id = row.data['id'] as int?;
        if (id != null && id > 0) allIds.add(id);
      }
    } catch (_) {}
    try {
      final legacyRows =
          await db.customSelect('SELECT data FROM wb_store WHERE id = 1').get();
      if (legacyRows.isNotEmpty) {
        final list =
            (jsonDecode(legacyRows.first.data['data'] as String) as List)
                .cast<Map<String, dynamic>>();
        for (final item in list) {
          final id = int.tryParse(item['id'].toString().replaceAll('wb_', ''));
          if (id != null && id > 0) allIds.add(id);
        }
      }
    } catch (_) {}

    final staleIds = allIds.difference(activeIds);
    final staleWhere = staleIds.isEmpty
        ? '0 = 1'
        : 'id IN (${staleIds.map((id) => '$id').join(',')})';
    try {
      await db.customStatement(
          'DELETE FROM plan_day_blocks WHERE block_id IN ($staleWhere)');
    } catch (_) {}
    try {
      await db.customStatement(
          'DELETE FROM workout_block_sets WHERE kns_id IN (SELECT id FROM workout_block_kns WHERE block_id IN ($staleWhere))');
    } catch (_) {}
    try {
      await db.customStatement(
          'DELETE FROM workout_block_kns WHERE block_id IN ($staleWhere)');
    } catch (_) {}
    try {
      await db.customStatement(
          'DELETE FROM wb_kns_store WHERE block_id IN ($staleWhere)');
    } catch (_) {}
    try {
      await db.customStatement(
          'DELETE FROM workout_blocks WHERE id IN ($staleWhere)');
    } catch (_) {}
    state = state.where((b) {
      final blockId = int.tryParse(b.id.replaceAll('wb_', '')) ?? 0;
      return !staleIds.contains(blockId);
    }).toList();
    await _save();
  }

  Future<void> setFolder(String id, String? folder) async {
    state = state
        .map((b) => b.id == id
            ? WorkoutBlockEntry(
                id: b.id, name: b.name, folder: folder, createdAt: b.createdAt)
            : b)
        .toList();
    await _save();
  }
}

// ─── WO.BLCKS.MANAGER SCREEN ────────────────────────────────────────

class WorkoutBlocksManagerScreen extends ConsumerStatefulWidget {
  const WorkoutBlocksManagerScreen({super.key});

  @override
  ConsumerState<WorkoutBlocksManagerScreen> createState() =>
      _WorkoutBlocksManagerScreenState();
}

class _WorkoutBlocksManagerScreenState
    extends ConsumerState<WorkoutBlocksManagerScreen> {
  String _sortMode = 'newest'; // newest, alpha, folder
  final Set<String> _expandedFolders = {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final blocks = ref.watch(workoutBlockListProvider);
    final sorted = _sortedList(blocks);
    final settings = ref.watch(themeSettingsProvider).value ?? {};
    final tC = ref.read(themeControllerProvider);
    final counterColor = tC.getColor(settings, 'UI_TAG_WO_BLOCKS_COUNTER',
        defaultColor: Colors.grey[500], nameSeed: 'WO_BLOCKS_COUNTER');
    final folderColor = tC.getColor(settings, 'UI_TAG_WO_BLOCKS_FOLDER',
        defaultColor: LabColors.cyanBorder, nameSeed: 'WO_BLOCKS_FOLDER');

    // Group by folder
    final Map<String?, List<WorkoutBlockEntry>> grouped = {};
    for (final b in sorted) {
      grouped.putIfAbsent(b.folder, () => []);
      grouped[b.folder]!.add(b);
    }
    final folderKeys = grouped.keys.toList();
    // Sort: null (no folder) first, then alphabetical
    folderKeys.sort((a, b) {
      if (a == null && b == null) return 0;
      if (a == null) return -1;
      if (b == null) return 1;
      return a.compareTo(b);
    });

    return MainScaffold(
      title: 'WO.BLCKS',
      screenKey: 'BLUEPRINT',
      floatingActionButton: FloatingActionButton(
        backgroundColor: LabColors.primary,
        onPressed: () => _showCreateDialog(context),
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: Column(
        children: [
          // Sort bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                const Spacer(),
                Text('${blocks.length} WB',
                    style: LabStyles.mono(context,
                        fontSize: 8, color: counterColor)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // WB list grouped by folder
          Expanded(
            child: blocks.isEmpty
                ? Center(
                    child: Text('NO_BLOCKS',
                        style: LabStyles.mono(context,
                            fontSize: 12, color: counterColor)))
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: folderKeys.map((folder) {
                      final items = grouped[folder]!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (folder != null) ...[
                            GestureDetector(
                              onTap: () => setState(() {
                                if (_expandedFolders.contains(folder)) {
                                  _expandedFolders.remove(folder);
                                } else {
                                  _expandedFolders.add(folder);
                                }
                              }),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 6, horizontal: 8),
                                margin: const EdgeInsets.only(bottom: 4),
                                decoration: BoxDecoration(
                                  border: Border(
                                      left: BorderSide(
                                          color: folderColor.withValues(
                                              alpha: 0.55),
                                          width: 2)),
                                  color: folderColor.withValues(alpha: 0.06),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                        _expandedFolders.contains(folder)
                                            ? '[ − ]'
                                            : '[ + ]',
                                        style: LabStyles.mono(context,
                                            fontSize: 9,
                                            color: Colors.grey[400])),
                                    const SizedBox(width: 6),
                                    Text(folder.toUpperCase(),
                                        style: LabStyles.mono(context,
                                            fontSize: 10,
                                            color: folderColor,
                                            fontWeight: FontWeight.bold)),
                                    const Spacer(),
                                    Text('${items.length}',
                                        style: LabStyles.mono(context,
                                            fontSize: 8, color: counterColor)),
                                  ],
                                ),
                              ),
                            ),
                            if (!_expandedFolders.contains(folder)) ...[
                              const SizedBox(height: 8),
                              // Don't show items when folder collapsed
                            ] else
                              ...items.map((b) => _BlockCard(block: b)),
                          ] else
                            ...items.map((b) => _BlockCard(block: b)),
                        ],
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  List<WorkoutBlockEntry> _sortedList(List<WorkoutBlockEntry> blocks) {
    final sorted = List<WorkoutBlockEntry>.from(blocks);
    switch (_sortMode) {
      case 'newest':
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'alpha':
        sorted.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'folder':
        sorted.sort((a, b) {
          final fa = a.folder ?? '';
          final fb = b.folder ?? '';
          if (fa != fb) return fa.compareTo(fb);
          return a.name.compareTo(b.name);
        });
        break;
    }
    return sorted;
  }

  Widget _sortChip(String label, String mode) {
    final active = _sortMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _sortMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: active
              ? LabColors.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          border: Border.all(
              color: active ? LabColors.primary : Colors.white24, width: 0.5),
        ),
        child: Text(label,
            style: LabStyles.mono(context,
                fontSize: 8,
                color: active ? LabColors.primary : Colors.grey,
                fontWeight: active ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }

  void _confirmDeleteAll(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: LabColors.background,
        title: Text('DELETE ALL BLOCKS',
            style: LabStyles.mono(context,
                fontSize: 12,
                color: Colors.redAccent,
                fontWeight: FontWeight.bold)),
        content: Text('Delete every workout block from WO.BLCKS?',
            style: LabStyles.mono(context, fontSize: 10)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text('CANCEL', style: LabStyles.mono(context))),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text('DELETE ALL',
                  style: LabStyles.mono(context, color: Colors.redAccent))),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(workoutBlockListProvider.notifier).removeAll();
    }
  }

  void _confirmDeletePast(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: LabColors.background,
        title: Text('DEL PAST',
            style: LabStyles.mono(context,
                fontSize: 12,
                color: Colors.orange,
                fontWeight: FontWeight.bold)),
        content: Text(
            'Aggressively delete stale WBs that are not currently visible in WO.BLCKS. If the current WO.BLCKS list is empty, this deletes all possible WBs.',
            style: LabStyles.mono(context, fontSize: 10)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text('CANCEL', style: LabStyles.mono(context))),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text('DELETE PAST',
                  style: LabStyles.mono(context, color: Colors.orange))),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(workoutBlockListProvider.notifier)
          .removePastAggressively();
    }
  }

  void _showCreateDialog(BuildContext context) {
    final nameC = TextEditingController();
    final folderC = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: LabColors.background,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('CREATE WB', style: LabStyles.headline(ctx)),
            const SizedBox(height: 24),
            LabTextField(controller: nameC, label: 'BLOCK NAME'),
            const SizedBox(height: 16),
            LabTextField(controller: folderC, label: 'FOLDER (OPTIONAL)'),
            const SizedBox(height: 24),
            LabButton(
                label: 'Create Block',
                onPressed: () async {
                  if (nameC.text.trim().isNotEmpty) {
                    await ref.read(workoutBlockListProvider.notifier).add(
                          nameC.text.trim(),
                          folder: folderC.text.trim().isNotEmpty
                              ? folderC.text.trim().toUpperCase()
                              : null,
                        );
                    Navigator.pop(ctx);
                  }
                }),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─── BLOCK CARD ──────────────────────────────────────────────────────

class _BlockCard extends ConsumerWidget {
  final WorkoutBlockEntry block;
  const _BlockCard({required this.block});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(themeSettingsProvider).value ?? {};
    final tC = ref.read(themeControllerProvider);
    final cardColor = tC.getColor(settings, 'UI_TAG_WO_BLOCKS_CARD',
        defaultColor: LabColors.cyanBorder, nameSeed: 'WO_BLOCKS_CARD');
    final folderColor = tC.getColor(settings, 'UI_TAG_WO_BLOCKS_FOLDER',
        defaultColor: LabColors.cyanBorder, nameSeed: 'WO_BLOCKS_FOLDER');
    final editColor = tC.getColor(settings, 'UI_TAG_WO_BLOCKS_EDIT',
        defaultColor: LabColors.primary, nameSeed: 'WO_BLOCKS_EDIT');
    final deleteColor = tC.getColor(settings, 'UI_TAG_WO_BLOCKS_DELETE',
        defaultColor: Colors.redAccent, nameSeed: 'WO_BLOCKS_DELETE');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border:
            Border.all(color: cardColor.withValues(alpha: 0.38), width: 0.75),
        color: cardColor.withValues(alpha: 0.035),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => WorkoutBlocksEditor(
                      blockName: block.name,
                      blockId:
                          int.tryParse(block.id.replaceAll('wb_', '')) ?? 0)));
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(block.name.toUpperCase(),
                        style: LabStyles.mono(context,
                            fontWeight: FontWeight.bold, fontSize: 11)),
                    if (block.folder != null)
                      Text(block.folder!,
                          style: LabStyles.mono(context,
                              fontSize: 8, color: folderColor)),
                  ],
                ),
              ),
              // Tag/folder button
              IconButton(
                icon: Icon(Icons.edit, size: 16, color: editColor),
                tooltip: 'RENAME WB',
                onPressed: () => _showRenameDialog(context, ref),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.label_outline,
                    size: 16,
                    color:
                        block.folder != null ? folderColor : Colors.grey[600]),
                tooltip: 'SET FOLDER',
                onPressed: () => _showFolderDialog(context, ref),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              // Delete button
              IconButton(
                icon: Icon(Icons.delete_outline,
                    size: 16, color: deleteColor.withValues(alpha: 0.75)),
                tooltip: 'DELETE WB',
                onPressed: () => _confirmDelete(context, ref),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref) {
    final nameC = TextEditingController(text: block.name);
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: LabColors.background,
        title: Text('RENAME WB',
            style: LabStyles.mono(context,
                fontSize: 12, color: LabColors.primary)),
        content: LabTextField(controller: nameC, label: 'BLOCK NAME'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c),
              child: Text('CANCEL', style: LabStyles.mono(context))),
          TextButton(
            onPressed: () async {
              final newName = nameC.text.trim();
              if (newName.isEmpty) {
                Navigator.pop(c);
                return;
              }
              await ref
                  .read(workoutBlockListProvider.notifier)
                  .rename(block.id, newName);
              if (context.mounted) Navigator.pop(c);
            },
            child: Text('SAVE',
                style: LabStyles.mono(context, color: LabColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showFolderDialog(BuildContext context, WidgetRef ref) {
    final folderC = TextEditingController(text: block.folder ?? '');
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: LabColors.background,
        title: Text('SET FOLDER',
            style: LabStyles.mono(context,
                fontSize: 12, color: LabColors.primary)),
        content: LabTextField(controller: folderC, label: 'FOLDER NAME'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c),
              child: Text('CANCEL', style: LabStyles.mono(context))),
          TextButton(
              onPressed: () async {
                await ref.read(workoutBlockListProvider.notifier).setFolder(
                    block.id,
                    folderC.text.trim().isNotEmpty
                        ? folderC.text.trim().toUpperCase()
                        : null);
                if (context.mounted) Navigator.pop(c);
              },
              child: Text('SET',
                  style: LabStyles.mono(context, color: LabColors.primary))),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: LabColors.background,
        title: Text('DELETE WB',
            style:
                LabStyles.mono(context, fontSize: 12, color: Colors.redAccent)),
        content: Text('Remove "${block.name}"?',
            style: LabStyles.mono(context, fontSize: 10)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text('CANCEL', style: LabStyles.mono(context))),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text('DELETE',
                  style: LabStyles.mono(context, color: Colors.redAccent))),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(workoutBlockListProvider.notifier).remove(block.id);
    }
  }
}
