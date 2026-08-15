import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../providers/database_provider.dart';
import '../database/database.dart';
import '../localization/strings.dart';
import 'styles.dart';
import 'main_scaffold.dart';
import 'exercise_form_screen.dart';

// One flagged problem for one exercise: either an incomplete field or a
// broken relational link (progressions/regressions/alters pointing at a
// name that doesn't exist, or missing the reciprocal entry on the other
// side).
class _Issue {
  final BaseExercise exercise;
  final String label;
  const _Issue(this.exercise, this.label);
}

class KnsStandardizationScreen extends ConsumerStatefulWidget {
  const KnsStandardizationScreen({super.key});

  @override
  ConsumerState<KnsStandardizationScreen> createState() =>
      _KnsStandardizationScreenState();
}

class _KnsStandardizationScreenState
    extends ConsumerState<KnsStandardizationScreen> {
  static const Map<String, String> _reciprocal = {
    "progressions": "regressions",
    "regressions": "progressions",
    "alters": "alters",
  };

  List<_Issue> _findIssues(List<BaseExercise> exercises) {
    final byName = {for (final e in exercises) e.fullName: e};
    final issues = <_Issue>[];

    for (final e in exercises) {
      // ── Incomplete fields ──
      if ((e.primaryMuscleGroup ?? '').trim().isEmpty) {
        issues.add(_Issue(e, 'MISSING_PRIMARY_MUSCLE'));
      }
      if ((e.field ?? '').trim().isEmpty) {
        issues.add(_Issue(e, 'MISSING_FIELD'));
      }
      if ((e.patternType ?? '').trim().isEmpty) {
        issues.add(_Issue(e, 'MISSING_PATTERN_TYPE'));
      }
      final intentionText = e.intention ?? '';
      final hasLoadNature =
          RegExp(r'\[NT:(.*)\|ISO:(.*)\]').hasMatch(intentionText);
      if (!hasLoadNature) {
        issues.add(_Issue(e, 'MISSING_LOAD_NATURE'));
      }

      // ── Relational integrity ──
      final meta = e.parsedComplexMetadata;
      for (final category in _reciprocal.keys) {
        final targets = List<String>.from(meta[category] ?? []);
        for (final targetName in targets) {
          final target = byName[targetName];
          if (target == null) {
            issues.add(_Issue(
                e, 'BROKEN_LINK ($category -> "$targetName" NOT_FOUND)'));
            continue;
          }
          final oppositeCategory = _reciprocal[category]!;
          final targetMeta = target.parsedComplexMetadata;
          final reciprocalList =
              List<String>.from(targetMeta[oppositeCategory] ?? []);
          if (!reciprocalList.contains(e.fullName)) {
            issues.add(_Issue(e,
                'ONE_SIDED_LINK ($category -> "${target.fullName}" missing reciprocal $oppositeCategory)'));
          }
        }
      }
    }

    issues.sort((a, b) => a.exercise.fullName.compareTo(b.exercise.fullName));
    return issues;
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider).value ?? 'en';
    final db = ref.watch(databaseProvider);

    return MainScaffold(
      title: 'KNS.BACKLOG',
      body: StreamBuilder<List<BaseExercise>>(
        stream: db.select(db.baseExercises).watch(),
        builder: (context, snap) {
          final exercises = snap.data ?? [];
          if (exercises.isEmpty) {
            return Center(
                child: Text(tr(lang, 'LOADING...'),
                    style: LabStyles.mono(context, color: Colors.grey)));
          }
          final issues = _findIssues(exercises);
          final flaggedCount = issues.map((i) => i.exercise.id).toSet().length;

          if (issues.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.greenAccent, size: 40),
                    const SizedBox(height: 12),
                    Text('NO_ISSUES_FOUND',
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
                    '${issues.length} ISSUES ACROSS $flaggedCount MOVEMENTS',
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
                    return InkWell(
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (c) => ExerciseFormScreen(exercise: issue.exercise))),
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
                                  Text(issue.exercise.fullName,
                                      style: LabStyles.mono(context,
                                          fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                                  const SizedBox(height: 4),
                                  Text(issue.label,
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
