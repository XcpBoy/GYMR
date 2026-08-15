import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;

import '../providers/database_provider.dart';
import 'styles.dart';
import 'main_scaffold.dart';

class FolderExplorerScreen extends ConsumerStatefulWidget {
  const FolderExplorerScreen({super.key});

  @override
  ConsumerState<FolderExplorerScreen> createState() => _FolderExplorerScreenState();
}

class _FolderExplorerScreenState extends ConsumerState<FolderExplorerScreen> {
  final Set<int> _expandedFolders = {};

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

  String _formatDate(int ts) {
    if (ts <= 0) return '--';
    final dt = DateTime.fromMillisecondsSinceEpoch(ts);
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.read(databaseProvider);

    return MainScaffold(
      title: 'FOLDER_EXPLORER',
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: FutureBuilder<List<drift.QueryRow>>(
          future: db.customSelect('''
            SELECT f.id AS folder_id, f.name AS folder_name, f.created_at AS folder_created,
                   sl.id AS log_id, sl.description, sl.spectrum_value, sl.tags, sl.created_at AS log_created,
                   COALESCE(be.name, 'DELETED') AS exercise_name
            FROM somatic_folders f
            LEFT JOIN somatic_folder_logs sfl ON sfl.folder_id = f.id
            LEFT JOIN somatic_logs sl ON sl.id = sfl.log_id
            LEFT JOIN workout_sets ws ON ws.id = sl.set_id
            LEFT JOIN base_exercises be ON be.id = ws.base_exercise_id
            ORDER BY f.created_at DESC, sl.created_at DESC
          ''').get(),
          builder: (context, snapshot) {
            final rows = snapshot.data ?? [];

            // Group rows by folder
            final Map<int, Map<String, dynamic>> folderMap = {};
            for (var row in rows) {
              final fId = row.data['folder_id'] as int;
              final fName = row.data['folder_name'] as String;
              final fCreated = row.data['folder_created'] as int;

              if (!folderMap.containsKey(fId)) {
                folderMap[fId] = {
                  'id': fId,
                  'name': fName,
                  'created': fCreated,
                  'logs': <Map<String, dynamic>>[],
                };
              }

              final logId = row.data['log_id'] as int?;
              if (logId != null) {
                (folderMap[fId]!['logs'] as List<Map<String, dynamic>>).add({
                  'id': logId,
                  'description': row.data['description'] as String,
                  'spectrum_value': row.data['spectrum_value'] as int,
                  'tags': row.data['tags'] as String?,
                  'created': row.data['log_created'] as int,
                  'exercise_name': row.data['exercise_name'] as String,
                });
              }
            }

            final folders = folderMap.values.toList();

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (folders.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(48),
                      decoration: BoxDecoration(border: Border.all(color: Colors.white10, width: 0.5)),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.folder, size: 48, color: Colors.grey[800]!),
                            const SizedBox(height: 16),
                            Text('NO_FOLDERS_YET', style: LabStyles.mono(context, fontSize: 10, color: Colors.grey[800]!)),
                            const SizedBox(height: 8),
                            Text('CREATE_FOLDERS_FROM_SOMATIC_SPECTRUM', style: LabStyles.mono(context, fontSize: 7, color: Colors.grey[800]!)),
                          ],
                        ),
                      ),
                    )
                  else
                    ...folders.map((folder) {
                      final fId = folder['id'] as int;
                      final fName = folder['name'] as String;
                      final logs = folder['logs'] as List<Map<String, dynamic>>;
                      final isExpanded = _expandedFolders.contains(fId);

                      // Compute avg spectrum for folder indicator
                      double avg = 0;
                      if (logs.isNotEmpty) {
                        avg = logs.map((l) => (l['spectrum_value'] as int).toDouble()).reduce((a, b) => a + b) / logs.length;
                      }
                      final avgInt = avg.round();
                      final folderColor = logs.isEmpty ? Colors.grey[600]! : _spectrumColor(avgInt);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: folderColor.withValues(alpha: 0.3), width: 0.5),
                        ),
                        child: Column(
                          children: [
                            // Folder header (tappable to expand)
                            InkWell(
                              onTap: () {
                                setState(() {
                                  if (isExpanded) {
                                    _expandedFolders.remove(fId);
                                  } else {
                                    _expandedFolders.add(fId);
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                color: folderColor.withValues(alpha: 0.05),
                                child: Row(
                                  children: [
                                    Container(width: 4, height: 32, color: folderColor),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(fName.toUpperCase(), style: LabStyles.mono(context, fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Text('${logs.length} ENTRIES', style: LabStyles.mono(context, fontSize: 7, color: Colors.grey[600]!)),
                                              const SizedBox(width: 12),
                                              if (logs.isNotEmpty)
                                                Text('AVG: $avgInt', style: LabStyles.mono(context, fontSize: 7, color: folderColor, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      isExpanded ? Icons.expand_less : Icons.expand_more,
                                      color: folderColor.withValues(alpha: 0.6),
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Expanded log list
                            if (isExpanded)
                              Container(
                                decoration: BoxDecoration(
                                  border: Border(top: BorderSide(color: folderColor.withValues(alpha: 0.15), width: 0.5)),
                                ),
                                child: logs.isEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Center(child: Text('FOLDER_EMPTY', style: LabStyles.mono(context, fontSize: 8, color: Colors.grey[800]!))),
                                    )
                                  : Column(
                                      children: logs.map((log) {
                                        final val = log['spectrum_value'] as int;
                                        final desc = log['description'] as String;
                                        final tags = log['tags'] as String?;
                                        final ts = log['created'] as int;
                                        final exName = log['exercise_name'] as String;
                                        final color = _spectrumColor(val);

                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                          decoration: BoxDecoration(
                                            border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.03), width: 0.5)),
                                          ),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Spectrum value badge
                                              Container(
                                                width: 28, height: 28,
                                                decoration: BoxDecoration(
                                                  border: Border.all(color: color.withValues(alpha: 0.5), width: 0.5),
                                                  color: color.withValues(alpha: 0.1),
                                                ),
                                                child: Center(child: Text('$val', style: LabStyles.mono(context, fontSize: 9, fontWeight: FontWeight.bold, color: color))),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    // Description
                                                    Text(desc.toUpperCase(), style: LabStyles.mono(context, fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                                                    const SizedBox(height: 3),
                                                    // Tags + Exercise
                                                    Row(
                                                      children: [
                                                        if (tags != null && tags.isNotEmpty) ...[
                                                          Text(tags.toUpperCase(), style: LabStyles.mono(context, fontSize: 7, color: Colors.grey[500]!)),
                                                          const SizedBox(width: 8),
                                                        ],
                                                        Text(exName.toUpperCase(), style: LabStyles.mono(context, fontSize: 7, color: Colors.grey[600]!)),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 2),
                                                    // Date
                                                    Text(_formatDate(ts), style: LabStyles.mono(context, fontSize: 7, color: Colors.grey[700]!)),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                              ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
