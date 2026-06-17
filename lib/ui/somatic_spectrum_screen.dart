import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;

import '../providers/database_provider.dart';
import '../database/database.dart';
import 'styles.dart';
import 'lab_widgets.dart';
import 'main_scaffold.dart';

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
  bool _foldersExpanded = false;
  bool _logsExpanded = true;

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

  Color _spectrumColor(int val) {
    if (val < 0) {
      final t = (val + 10) / 10.0;
      return Color.lerp(Colors.redAccent, Colors.grey[600]!, t)!;
    } else if (val == 0) {
      return Colors.grey[600]!;
    } else {
      return Color.lerp(Colors.greenAccent, Colors.blueAccent, val / 10.0)!;
    }
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

  @override
  Widget build(BuildContext context) {
    final db = ref.read(databaseProvider);

    return MainScaffold(
      title: 'SOMATIC_LOGS',
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFolderSection(context, db),
              const SizedBox(height: 24),
              _buildLogsSection(context, db),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFolderSection(BuildContext context, AppDatabase db) {
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

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white10, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => setState(() => _foldersExpanded = !_foldersExpanded),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  color: LabColors.surfaceContainerLow,
                  child: Row(
                    children: [
                      Icon(_foldersExpanded ? Icons.expand_less : Icons.expand_more, size: 14, color: Colors.grey[400]),
                      const SizedBox(width: 8),
                      Text('FOLDERS (${folders.length})', style: LabStyles.mono(context, fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _showCreateFolderDialog(context, db),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(border: Border.all(color: LabColors.primary.withValues(alpha: 0.3), width: 0.5)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add, size: 12, color: LabColors.primary),
                              const SizedBox(width: 4),
                              Text('CREATE', style: LabStyles.mono(context, fontSize: 8, color: LabColors.primary, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_foldersExpanded) ...[
                if (folders.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    child: Center(child: Text('NO_FOLDERS_YET', style: LabStyles.mono(context, fontSize: 8, color: Colors.grey[700]!))),
                  )
                else
                  ...folders.map((row) {
                    final id = row.data['id'] as int;
                    final name = row.data['name'] as String;
                    final count = (row.data['log_count'] as int?) ?? 0;
                    final avg = (row.data['avg_spectrum'] as num?)?.toDouble() ?? 0;
                    final avgInt = avg.round();
                    final color = _spectrumColor(avgInt);

                    return GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => _FolderDetailScreen(folderId: id, folderName: name))),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06), width: 0.5)),
                        ),
                        child: Row(
                          children: [
                            Container(width: 3, height: 28, color: color),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name.toUpperCase(), style: LabStyles.mono(context, fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                                  const SizedBox(height: 2),
                                  Text('$count LOGS · AVG $avgInt', style: LabStyles.mono(context, fontSize: 7, color: Colors.grey[600]!)),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, size: 14, color: Colors.grey[500]),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 14, color: Colors.redAccent),
                              onPressed: () async {
                                await _deleteFolder(id);
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogsSection(BuildContext context, AppDatabase db) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white10, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _logsExpanded = !_logsExpanded),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              color: LabColors.surfaceContainerLow,
              child: Row(
                children: [
                  Icon(_logsExpanded ? Icons.expand_less : Icons.expand_more, size: 14, color: Colors.grey[400]),
                  const SizedBox(width: 8),
                  Text('ALL LOGS', style: LabStyles.mono(context, fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const Spacer(),
                ],
              ),
            ),
          ),
          if (_logsExpanded) ...[
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 32,
                          child: TextField(
                            controller: _logSearchC,
                            style: LabStyles.mono(context, fontSize: 10, color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'SEARCH...',
                              hintStyle: TextStyle(color: Colors.grey[600], fontSize: 9),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              border: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[800]!, width: 0.5)),
                              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[800]!, width: 0.5)),
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
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                            side: BorderSide(color: Colors.white24, width: 0.5),
                          ),
                          onPressed: () => setState(() => _sortMode = _LogSortMode.values[(_sortMode.index + 1) % _LogSortMode.values.length]),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.sort, size: 12, color: Colors.grey[400]),
                            const SizedBox(width: 3),
                            Text(_sortLabel, style: LabStyles.mono(context, fontSize: 8, color: Colors.white70)),
                          ]),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<List<drift.QueryRow>>(
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
                      var logs = snapshot.data ?? [];
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
                          sorted.sort((a, b) => ((a.data['tags'] as String?) ?? '').compareTo((b.data['tags'] as String?) ?? ''));
                          break;
                        case _LogSortMode.tagRevAlpha:
                          sorted.sort((a, b) => ((b.data['tags'] as String?) ?? '').compareTo((a.data['tags'] as String?) ?? ''));
                          break;
                      }
                      return sorted.isEmpty
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(border: Border.all(color: Colors.white10, width: 0.5)),
                            child: Center(child: Text('NO_SOMATIC_LOGS_YET', style: LabStyles.mono(context, fontSize: 8, color: Colors.grey[700]!))),
                          )
                        : Column(children: sorted.map((row) => _buildLogRow(context, row)).toList());
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLogRow(BuildContext context, drift.QueryRow row) {
    final val = row.data['spectrum_value'] as int;
    final desc = row.data['description'] as String;
    final tags = row.data['tags'] as String?;
    final exName = row.data['exercise_name'] as String;
    final color = _spectrumColor(val);

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(border: Border.all(color: Colors.white.withValues(alpha: 0.06), width: 0.5)),
      child: Row(
        children: [
          Container(width: 24, height: 24, decoration: BoxDecoration(border: Border.all(color: color.withValues(alpha: 0.5), width: 0.5), color: color.withValues(alpha: 0.1)),
            child: Center(child: Text('$val', style: LabStyles.mono(context, fontSize: 8, fontWeight: FontWeight.bold, color: color))),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(desc.toUpperCase(), style: LabStyles.mono(context, fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white)),
              Row(children: [
                if (tags != null && tags.isNotEmpty) ...[Text(tags.toUpperCase(), style: LabStyles.mono(context, fontSize: 6, color: Colors.grey[500]!)), const SizedBox(width: 6)],
                Text(exName.toUpperCase(), style: LabStyles.mono(context, fontSize: 6, color: Colors.grey[600]!)),
              ]),
            ]),
          ),
        ],
      ),
    );
  }

  void _showCreateFolderDialog(BuildContext context, AppDatabase db) {
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
              Text('CREATE_FOLDER', style: LabStyles.headline(c, color: Colors.white).copyWith(fontSize: 14)),
              const SizedBox(height: 16),
              LabTextField(controller: _folderNameController, label: 'FOLDER_NAME'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(c), child: Text('CANCEL', style: LabStyles.mono(c, fontSize: 8, color: Colors.grey))),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 120,
                    child: LabButton(
                      label: 'CREATE',
                      color: LabColors.primary,
                      onPressed: () async {
                        if (_folderNameController.text.trim().isNotEmpty) {
                          await _createFolder(_folderNameController.text);
                          Navigator.pop(c);
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
  @override
  Widget build(BuildContext context) {
    final db = ref.read(databaseProvider);

    return MainScaffold(
      title: widget.folderName.toUpperCase(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: FutureBuilder<List<drift.QueryRow>>(
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
              return Center(child: Text('EMPTY_FOLDER', style: LabStyles.mono(context, fontSize: 10, color: Colors.grey[700]!)));
            }
            return Column(
              children: logs.map((row) {
                final val = row.data['spectrum_value'] as int;
                final desc = row.data['description'] as String;
                final tags = row.data['tags'] as String?;
                final exName = row.data['exercise_name'] as String;
                Color sc(int v) {
                  if (v < 0) { final t = (v + 10) / 10.0; return Color.lerp(Colors.redAccent, Colors.grey[600]!, t)!; }
                  else if (v == 0) { return Colors.grey[600]!; }
                  else { return Color.lerp(Colors.greenAccent, Colors.blueAccent, v / 10.0)!; }
                }
                final color = sc(val);
                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(border: Border.all(color: Colors.white10, width: 0.5)),
                  child: Row(
                    children: [
                      Container(width: 24, height: 24, decoration: BoxDecoration(border: Border.all(color: color.withValues(alpha: 0.5), width: 0.5), color: color.withValues(alpha: 0.1)),
                        child: Center(child: Text('$val', style: LabStyles.mono(context, fontSize: 8, fontWeight: FontWeight.bold, color: color))),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(desc.toUpperCase(), style: LabStyles.mono(context, fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                          Row(children: [
                            if (tags != null && tags.isNotEmpty) ...[Text(tags.toUpperCase(), style: LabStyles.mono(context, fontSize: 7, color: Colors.grey[500]!)), const SizedBox(width: 6)],
                            Text(exName.toUpperCase(), style: LabStyles.mono(context, fontSize: 7, color: Colors.grey[600]!)),
                          ]),
                        ]),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}
