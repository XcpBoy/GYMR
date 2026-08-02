import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;

import '../providers/database_provider.dart';
import '../database/database.dart';
import '../localization/strings.dart';
import 'styles.dart';
import 'lab_widgets.dart';
import 'main_scaffold.dart';

// Shared across SomaticLogsScreen and _FolderDetailScreen — negative values
// are "anomaly" (pain), positive are "recovery".
Color spectrumColor(int val) {
  if (val < 0) {
    final t = (val + 10) / 10.0;
    return Color.lerp(Colors.redAccent, Colors.grey[600]!, t)!;
  } else if (val == 0) {
    return Colors.grey[600]!;
  } else {
    return Color.lerp(Colors.greenAccent, Colors.blueAccent, val / 10.0)!;
  }
}

Future<Map<int, String>> loadSpectrumLabels(AppDatabase db) async {
  final rows =
      await db.customSelect('SELECT value, label FROM spectrum_references').get();
  return {for (final r in rows) r.data['value'] as int: r.data['label'] as String};
}

// A compact horizontal -10..+10 gauge with a marker at the value, plus the
// resolved label from `spectrum_references` (e.g. "+7 · ENERGIZED").
class SpectrumGauge extends StatelessWidget {
  final int value;
  final String? label;
  final double width;
  final double height;
  final bool showLabel;
  const SpectrumGauge({
    super.key,
    required this.value,
    this.label,
    this.width = 80,
    this.height = 8,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final markerX = ((value + 10) / 20.0).clamp(0.0, 1.0) * width;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: width,
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Colors.redAccent,
                    Colors.grey[700]!,
                    Colors.blueAccent,
                  ]),
                  border: Border.all(color: Colors.white24, width: 0.5),
                ),
              ),
              Positioned(
                left: (markerX - 1).clamp(0, width - 2),
                top: -2,
                bottom: -2,
                child: Container(width: 2, color: Colors.white),
              ),
            ],
          ),
        ),
        if (showLabel) ...[
          const SizedBox(height: 2),
          Text(
            '${value > 0 ? '+' : ''}$value${label != null ? ' · $label' : ''}',
            style: LabStyles.mono(context,
                fontSize: 7, color: spectrumColor(value), fontWeight: FontWeight.bold),
          ),
        ],
      ],
    );
  }
}

class SomaticLogsScreen extends ConsumerStatefulWidget {
  const SomaticLogsScreen({super.key});

  @override
  ConsumerState<SomaticLogsScreen> createState() => _SomaticLogsScreenState();
}

enum _LogSortMode { newestFirst, oldestFirst, highestVal, lowestVal, tagAlpha, tagRevAlpha }

class _SomaticLogsScreenState extends ConsumerState<SomaticLogsScreen> {
  final _folderNameController = TextEditingController();
  final TextEditingController _logSearchC = TextEditingController();
  _LogSortMode _sortMode = _LogSortMode.newestFirst;
  bool _selectMode = false;
  final Set<int> _selectedLogIds = {};

  String get _sortLabel {
    switch (_sortMode) {
      case _LogSortMode.newestFirst: return 'NEW';
      case _LogSortMode.oldestFirst: return 'OLD';
      case _LogSortMode.highestVal: return 'HI';
      case _LogSortMode.lowestVal: return 'LO';
      case _LogSortMode.tagAlpha: return 'A-Z';
      case _LogSortMode.tagRevAlpha: return 'Z-A';
    }
  }

  @override
  void dispose() {
    _folderNameController.dispose();
    _logSearchC.dispose();
    super.dispose();
  }

  Future<void> _createFolder(String name) async {
    final db = ref.read(databaseProvider);
    final now = DateTime.now().millisecondsSinceEpoch;
    final safeName = name.trim().replaceAll("'", "''");
    await db.customStatement(
      "INSERT INTO somatic_folders (name, created_at) VALUES ('$safeName', $now)",
    );
  }

  Future<void> _deleteFolder(int folderId) async {
    final db = ref.read(databaseProvider);
    await db.customStatement('DELETE FROM somatic_folder_logs WHERE folder_id = $folderId');
    await db.customStatement('DELETE FROM somatic_folders WHERE id = $folderId');
  }

  Future<void> _assignLogsToFolder(int folderId, Set<int> logIds) async {
    final db = ref.read(databaseProvider);
    for (final logId in logIds) {
      await db.customStatement(
          'INSERT OR IGNORE INTO somatic_folder_logs (folder_id, log_id) VALUES ($folderId, $logId)');
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.read(databaseProvider);
    final lang = ref.watch(languageProvider).value ?? 'en';

    return MainScaffold(
      title: 'SPECTRO.SOMTCO',
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: FutureBuilder<Map<int, String>>(
          future: loadSpectrumLabels(db),
          builder: (context, labelsSnap) {
            final labels = labelsSnap.data ?? {};
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFoldersRow(context, db, lang),
                  const SizedBox(height: 16),
                  _buildLogsSection(context, db, labels, lang),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFoldersRow(BuildContext context, AppDatabase db, String lang) {
    return FutureBuilder<List<drift.QueryRow>>(
      future: db.customSelect('''
        SELECT f.id, f.name, f.created_at,
               COUNT(sfl.log_id) AS log_count,
               COALESCE(AVG(sl.spectrum_value), 0) AS avg_spectrum
        FROM somatic_folders f
        LEFT JOIN somatic_folder_logs sfl ON sfl.folder_id = f.id
        LEFT JOIN somatic_logs sl ON sl.id = sfl.log_id
        GROUP BY f.id
        ORDER BY f.created_at DESC
      ''').get(),
      builder: (context, snapshot) {
        final folders = snapshot.data ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('${tr(lang, 'FOLDERS')} (${folders.length})',
                    style: LabStyles.mono(context,
                        fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                const Spacer(),
                GestureDetector(
                  onTap: () => _showCreateFolderDialog(context, db, lang),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                        border: Border.all(
                            color: LabColors.primary.withValues(alpha: 0.3), width: 0.5)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 12, color: LabColors.primary),
                        const SizedBox(width: 4),
                        Text(tr(lang, 'CREATE'),
                            style: LabStyles.mono(context,
                                fontSize: 8,
                                color: LabColors.primary,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 76,
              child: folders.isEmpty
                  ? Container(
                      width: double.infinity,
                      alignment: Alignment.centerLeft,
                      child: Text(tr(lang, 'NO_FOLDERS_YET'),
                          style: LabStyles.mono(context,
                              fontSize: 8, color: Colors.grey[700]!)),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: folders.length,
                      itemBuilder: (context, i) {
                        final row = folders[i];
                        final id = row.data['id'] as int;
                        final name = row.data['name'] as String;
                        final count = (row.data['log_count'] as int?) ?? 0;
                        final avg = (row.data['avg_spectrum'] as num?)?.toDouble() ?? 0;
                        final avgInt = avg.round();
                        final color = spectrumColor(avgInt);
                        return GestureDetector(
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (c) =>
                                      _FolderDetailScreen(folderId: id, folderName: name))),
                          onLongPress: () async {
                            final ok = await _confirmDeleteFolder(context, name, lang);
                            if (ok) {
                              await _deleteFolder(id);
                              setState(() {});
                            }
                          },
                          child: Container(
                            width: 130,
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: LabColors.surfaceDim,
                              border: Border(top: BorderSide(color: color, width: 2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(name.toUpperCase(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: LabStyles.mono(context,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white)),
                                Text('$count ${tr(lang, 'LOGS')}',
                                    style: LabStyles.mono(context,
                                        fontSize: 7, color: Colors.grey[600]!)),
                                if (count > 0) SpectrumGauge(value: avgInt, width: 100, height: 6, showLabel: false),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLogsSection(
      BuildContext context, AppDatabase db, Map<int, String> labels, String lang) {
    return FutureBuilder<List<drift.QueryRow>>(
      future: db.customSelect('''
        SELECT sl.id, sl.description, sl.spectrum_value, sl.tags, sl.created_at,
               COALESCE(be.name, 'DELETED') AS exercise_name
        FROM somatic_logs sl
        LEFT JOIN workout_sets ws ON ws.id = sl.set_id
        LEFT JOIN base_exercises be ON be.id = ws.base_exercise_id
        ORDER BY sl.created_at DESC
        LIMIT 200
      ''').get(),
      builder: (context, snapshot) {
        final allLogs = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSpectrumOverview(context, allLogs, lang),
            const SizedBox(height: 16),
            _buildToolbar(context, lang),
            if (_selectMode && _selectedLogIds.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildSelectionBar(context, db, lang),
            ],
            const SizedBox(height: 8),
            _buildFilteredSortedList(context, allLogs, labels, lang),
          ],
        );
      },
    );
  }

  Widget _buildSpectrumOverview(BuildContext context, List<drift.QueryRow> logs, String lang) {
    final counts = <int, int>{for (var v = -10; v <= 10; v++) v: 0};
    var anomalyCount = 0;
    var recoveryCount = 0;
    for (final row in logs) {
      final v = row.data['spectrum_value'] as int;
      counts[v] = (counts[v] ?? 0) + 1;
      if (v < 0) anomalyCount++;
      if (v > 0) recoveryCount++;
    }
    final maxCount = counts.values.fold(0, (a, b) => a > b ? a : b);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: LabColors.surfaceDim, border: Border.all(color: Colors.white10, width: 0.5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr(lang, 'SPECTRUM_OVERVIEW'),
              style: LabStyles.mono(context,
                  fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          SizedBox(
            height: 44,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var v = -10; v <= 10; v++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0.5),
                      child: Container(
                        height: maxCount == 0 ? 2 : (2 + (counts[v]! / maxCount) * 40),
                        color: (counts[v] ?? 0) > 0 ? spectrumColor(v) : Colors.white10,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _statChip(context, tr(lang, 'TOTAL'), '${logs.length}', Colors.white),
              const SizedBox(width: 20),
              _statChip(context, tr(lang, 'ANOMALY'), '$anomalyCount', Colors.redAccent),
              const SizedBox(width: 20),
              _statChip(context, tr(lang, 'RECOVERY'), '$recoveryCount', Colors.blueAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip(BuildContext context, String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: LabStyles.mono(context,
                fontSize: 14, color: color, fontWeight: FontWeight.bold)),
        Text(label, style: LabStyles.mono(context, fontSize: 7, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildToolbar(BuildContext context, String lang) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 32,
            child: TextField(
              controller: _logSearchC,
              style: LabStyles.mono(context, fontSize: 10, color: Colors.white),
              decoration: InputDecoration(
                hintText: tr(lang, 'SEARCH...'),
                hintStyle: TextStyle(color: Colors.grey[600], fontSize: 9),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                border: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[800]!, width: 0.5)),
                enabledBorder:
                    OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[800]!, width: 0.5)),
                isDense: true,
                filled: true,
                fillColor: LabColors.surfaceDim,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          height: 32,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              shape: const RoundedRectangleBorder(),
              side: const BorderSide(color: Colors.white24, width: 0.5),
            ),
            onPressed: () => setState(
                () => _sortMode = _LogSortMode.values[(_sortMode.index + 1) % _LogSortMode.values.length]),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.sort, size: 12, color: Colors.grey[400]),
              const SizedBox(width: 3),
              Text(_sortLabel, style: LabStyles.mono(context, fontSize: 8, color: Colors.white70)),
            ]),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          height: 32,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: _selectMode ? LabColors.primary.withValues(alpha: 0.15) : Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              shape: const RoundedRectangleBorder(),
              side: BorderSide(color: _selectMode ? LabColors.primary : Colors.white24, width: 0.5),
            ),
            onPressed: () => setState(() {
              _selectMode = !_selectMode;
              if (!_selectMode) _selectedLogIds.clear();
            }),
            child: Icon(Icons.checklist,
                size: 14, color: _selectMode ? LabColors.primary : Colors.grey[400]),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionBar(BuildContext context, AppDatabase db, String lang) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
          color: LabColors.primary.withValues(alpha: 0.08),
          border: Border.all(color: LabColors.primary.withValues(alpha: 0.3), width: 0.5)),
      child: Row(
        children: [
          Text('${_selectedLogIds.length} ${tr(lang, 'SELECTED')}',
              style: LabStyles.mono(context,
                  fontSize: 9, color: LabColors.primary, fontWeight: FontWeight.bold)),
          const Spacer(),
          GestureDetector(
            onTap: () => _showAssignToFolderSheet(context, db, lang),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(tr(lang, 'ADD TO FOLDER'),
                    style: LabStyles.mono(context,
                        fontSize: 9, color: LabColors.primary, fontWeight: FontWeight.bold)),
                const SizedBox(width: 2),
                Icon(Icons.chevron_right, size: 14, color: LabColors.primary),
              ],
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () => setState(() {
              _selectMode = false;
              _selectedLogIds.clear();
            }),
            child: Text(tr(lang, 'CANCEL'),
                style: LabStyles.mono(context, fontSize: 9, color: Colors.grey[500])),
          ),
        ],
      ),
    );
  }

  Widget _buildFilteredSortedList(BuildContext context, List<drift.QueryRow> allLogs,
      Map<int, String> labels, String lang) {
    var logs = allLogs;
    final q = _logSearchC.text.toLowerCase();
    if (q.isNotEmpty) {
      logs = logs.where((row) {
        final desc = (row.data['description'] as String).toLowerCase();
        final tags = (row.data['tags'] as String? ?? '').toLowerCase();
        final exName = (row.data['exercise_name'] as String).toLowerCase();
        return desc.contains(q) || tags.contains(q) || exName.contains(q);
      }).toList();
    }
    final sorted = List<drift.QueryRow>.from(logs);
    switch (_sortMode) {
      case _LogSortMode.newestFirst:
        sorted.sort((a, b) => (b.data['created_at'] as int).compareTo(a.data['created_at'] as int));
        break;
      case _LogSortMode.oldestFirst:
        sorted.sort((a, b) => (a.data['created_at'] as int).compareTo(b.data['created_at'] as int));
        break;
      case _LogSortMode.highestVal:
        sorted.sort((a, b) => (b.data['spectrum_value'] as int).compareTo(a.data['spectrum_value'] as int));
        break;
      case _LogSortMode.lowestVal:
        sorted.sort((a, b) => (a.data['spectrum_value'] as int).compareTo(b.data['spectrum_value'] as int));
        break;
      case _LogSortMode.tagAlpha:
        sorted.sort((a, b) =>
            ((a.data['tags'] as String?) ?? '').compareTo((b.data['tags'] as String?) ?? ''));
        break;
      case _LogSortMode.tagRevAlpha:
        sorted.sort((a, b) =>
            ((b.data['tags'] as String?) ?? '').compareTo((a.data['tags'] as String?) ?? ''));
        break;
    }

    if (sorted.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(border: Border.all(color: Colors.white10, width: 0.5)),
        child: Center(
            child: Text(tr(lang, 'NO_SOMATIC_LOGS_YET'),
                style: LabStyles.mono(context, fontSize: 8, color: Colors.grey[700]!))),
      );
    }
    return Column(children: sorted.map((row) => _buildLogRow(context, row, labels)).toList());
  }

  Widget _buildLogRow(BuildContext context, drift.QueryRow row, Map<int, String> labels) {
    final id = row.data['id'] as int;
    final val = row.data['spectrum_value'] as int;
    final desc = row.data['description'] as String;
    final tags = row.data['tags'] as String?;
    final exName = row.data['exercise_name'] as String;
    final selected = _selectedLogIds.contains(id);

    return GestureDetector(
      onLongPress: () => setState(() {
        _selectMode = true;
        _selectedLogIds.add(id);
      }),
      onTap: _selectMode
          ? () => setState(() {
                if (selected) {
                  _selectedLogIds.remove(id);
                } else {
                  _selectedLogIds.add(id);
                }
              })
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected ? LabColors.primary.withValues(alpha: 0.08) : Colors.transparent,
          border: Border.all(
              color: selected ? LabColors.primary : Colors.white.withValues(alpha: 0.06),
              width: selected ? 1 : 0.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (_selectMode) ...[
              Icon(selected ? Icons.check_box : Icons.check_box_outline_blank,
                  size: 18, color: selected ? LabColors.primary : Colors.grey[600]),
              const SizedBox(width: 8),
            ],
            SpectrumGauge(value: val, label: labels[val], width: 64, height: 8),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(desc.toUpperCase(),
                      style: LabStyles.mono(context,
                          fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                  Row(children: [
                    if (tags != null && tags.isNotEmpty) ...[
                      Text(tags.toUpperCase(),
                          style: LabStyles.mono(context, fontSize: 6, color: Colors.grey[500]!)),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(exName.toUpperCase(),
                          overflow: TextOverflow.ellipsis,
                          style: LabStyles.mono(context, fontSize: 6, color: Colors.grey[600]!)),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAssignToFolderSheet(BuildContext context, AppDatabase db, String lang) async {
    final folders = await db
        .customSelect('SELECT id, name FROM somatic_folders ORDER BY created_at DESC')
        .get();
    final selectedIds = Set<int>.from(_selectedLogIds);
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      backgroundColor: LabColors.background,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                  tr(lang, 'ADD {n} LOG(S) TO FOLDER').replaceFirst('{n}', '${selectedIds.length}'),
                  style: LabStyles.headline(c, color: Colors.white).copyWith(fontSize: 14)),
            ),
            if (folders.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(tr(lang, 'NO_FOLDERS_YET — create one below.'),
                    style: LabStyles.mono(c, fontSize: 9, color: Colors.grey[600])),
              ),
            for (final f in folders)
              ListTile(
                title: Text((f.data['name'] as String).toUpperCase(),
                    style: LabStyles.mono(c, fontSize: 11, color: Colors.white)),
                trailing: Icon(Icons.arrow_forward, size: 14, color: LabColors.primary),
                onTap: () async {
                  await _assignLogsToFolder(f.data['id'] as int, selectedIds);
                  if (c.mounted) Navigator.pop(c);
                  setState(() {
                    _selectMode = false;
                    _selectedLogIds.clear();
                  });
                },
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: LabButton(
                  label: tr(lang, '+ NEW FOLDER'),
                  color: LabColors.primary,
                  onPressed: () {
                    Navigator.pop(c);
                    _showCreateFolderDialog(context, db, lang);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmDeleteFolder(BuildContext context, String name, String lang) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: LabColors.background,
        title: Text(tr(lang, 'DELETE FOLDER?'),
            style: LabStyles.headline(c, color: Colors.white).copyWith(fontSize: 14)),
        content: Text(
            tr(lang, 'This removes "{name}" — logs stay, only the grouping is deleted.')
                .replaceFirst('{name}', name.toUpperCase()),
            style: LabStyles.mono(c, fontSize: 10, color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(tr(lang, 'CANCEL'), style: LabStyles.mono(c, color: Colors.grey))),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(tr(lang, 'DELETE'), style: LabStyles.mono(c, color: Colors.redAccent))),
        ],
      ),
    );
    return ok ?? false;
  }

  void _showCreateFolderDialog(BuildContext context, AppDatabase db, String lang) {
    _folderNameController.clear();
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: LabColors.background,
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr(lang, 'CREATE_FOLDER'), style: LabStyles.headline(c, color: Colors.white).copyWith(fontSize: 14)),
              const SizedBox(height: 16),
              LabTextField(controller: _folderNameController, label: tr(lang, 'FOLDER_NAME')),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(c), child: Text(tr(lang, 'CANCEL'), style: LabStyles.mono(c, fontSize: 8, color: Colors.grey))),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 120,
                    child: LabButton(
                      label: tr(lang, 'CREATE'),
                      color: LabColors.primary,
                      onPressed: () async {
                        if (_folderNameController.text.trim().isNotEmpty) {
                          await _createFolder(_folderNameController.text);
                          if (c.mounted) Navigator.pop(c);
                          setState(() {});
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sub-screen showing logs for a specific folder
class _FolderDetailScreen extends ConsumerStatefulWidget {
  final int folderId;
  final String folderName;
  const _FolderDetailScreen({required this.folderId, required this.folderName});

  @override
  ConsumerState<_FolderDetailScreen> createState() => _FolderDetailScreenState();
}

class _FolderDetailScreenState extends ConsumerState<_FolderDetailScreen> {
  Future<void> _removeFromFolder(int logId) async {
    final db = ref.read(databaseProvider);
    await db.customStatement(
        'DELETE FROM somatic_folder_logs WHERE folder_id = ${widget.folderId} AND log_id = $logId');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.read(databaseProvider);
    final lang = ref.watch(languageProvider).value ?? 'en';

    return MainScaffold(
      title: widget.folderName.toUpperCase(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: FutureBuilder<Map<int, String>>(
          future: loadSpectrumLabels(db),
          builder: (context, labelsSnap) {
            final labels = labelsSnap.data ?? {};
            return FutureBuilder<List<drift.QueryRow>>(
              future: db.customSelect('''
                SELECT sl.id, sl.description, sl.spectrum_value, sl.tags, sl.created_at,
                       COALESCE(be.name, 'DELETED') AS exercise_name
                FROM somatic_logs sl
                JOIN somatic_folder_logs sfl ON sfl.log_id = sl.id
                LEFT JOIN workout_sets ws ON ws.id = sl.set_id
                LEFT JOIN base_exercises be ON be.id = ws.base_exercise_id
                WHERE sfl.folder_id = ${widget.folderId}
                ORDER BY sl.created_at DESC
              ''').get(),
              builder: (context, snap) {
                final logs = snap.data ?? [];
                if (logs.isEmpty) {
                  return Center(
                      child: Text(tr(lang, 'EMPTY_FOLDER'),
                          style: LabStyles.mono(context, fontSize: 10, color: Colors.grey[700]!)));
                }
                return Column(
                  children: logs.map((row) {
                    final id = row.data['id'] as int;
                    final val = row.data['spectrum_value'] as int;
                    final desc = row.data['description'] as String;
                    final tags = row.data['tags'] as String?;
                    final exName = row.data['exercise_name'] as String;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(border: Border.all(color: Colors.white10, width: 0.5)),
                      child: Row(
                        children: [
                          SpectrumGauge(value: val, label: labels[val], width: 64, height: 8),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(desc.toUpperCase(),
                                  style: LabStyles.mono(context,
                                      fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                              Row(children: [
                                if (tags != null && tags.isNotEmpty) ...[
                                  Text(tags.toUpperCase(),
                                      style: LabStyles.mono(context, fontSize: 7, color: Colors.grey[500]!)),
                                  const SizedBox(width: 6),
                                ],
                                Expanded(
                                  child: Text(exName.toUpperCase(),
                                      overflow: TextOverflow.ellipsis,
                                      style: LabStyles.mono(context, fontSize: 7, color: Colors.grey[600]!)),
                                ),
                              ]),
                            ]),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, size: 16, color: Colors.grey),
                            tooltip: tr(lang, 'REMOVE FROM FOLDER'),
                            onPressed: () => _removeFromFolder(id),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
