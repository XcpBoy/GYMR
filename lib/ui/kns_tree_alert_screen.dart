import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../providers/database_provider.dart';
import '../database/database.dart';
import '../services/export_service.dart';
import '../localization/strings.dart';
import 'styles.dart';
import 'main_scaffold.dart';
import 'exercise_form_screen.dart';

class KnsTreeAlertScreen extends ConsumerStatefulWidget {
  const KnsTreeAlertScreen({super.key});

  @override
  ConsumerState<KnsTreeAlertScreen> createState() => _KnsTreeAlertScreenState();
}

class _KnsTreeAlertScreenState extends ConsumerState<KnsTreeAlertScreen> {
  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider).value ?? 'en';
    final db = ref.watch(databaseProvider);

    return MainScaffold(
      title: 'KNS.TREE.ALERT',
      body: StreamBuilder<List<BaseExercise>>(
        stream: db.select(db.baseExercises).watch(),
        builder: (context, snap) {
          final exercises = snap.data ?? [];
          if (exercises.isEmpty) {
            return Center(
                child: Text(tr(lang, 'LOADING...'),
                    style: LabStyles.mono(context, color: Colors.grey)));
          }
          final issues = ExportService.findKnsTreeIssues(exercises);
          final flaggedCount = issues
              .map((i) => (i['exercise'] as BaseExercise).id)
              .toSet()
              .length;

          if (issues.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.greenAccent, size: 40),
                    const SizedBox(height: 12),
                    Text('NO_TREE_ISSUES_FOUND',
                        style: LabStyles.mono(context, color: Colors.grey, fontSize: 11)),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: Colors.redAccent.withValues(alpha: 0.08),
                child: Text(
                    '${issues.length} BROKEN LINKS ACROSS $flaggedCount MOVEMENTS',
                    style: LabStyles.mono(context,
                        fontSize: 10, color: Colors.redAccent, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: issues.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final issue = issues[index];
                    final exercise = issue['exercise'] as BaseExercise;
                    final label = issue['label'] as String;
                    return InkWell(
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (c) => ExerciseFormScreen(exercise: exercise))),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: LabColors.surfaceContainerLow,
                          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3), width: 0.5),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(exercise.fullName,
                                      style: LabStyles.mono(context,
                                          fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                                  const SizedBox(height: 4),
                                  Text(label,
                                      style: LabStyles.mono(context, fontSize: 9, color: Colors.redAccent)),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
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
      ),
    );
  }
}
