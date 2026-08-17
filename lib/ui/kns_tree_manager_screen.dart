import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../providers/database_provider.dart';
import '../database/database.dart';
import '../services/export_service.dart';
import 'styles.dart';
import 'lab_widgets.dart';
import 'main_scaffold.dart';
import 'exercise_form_screen.dart';

// KNST.FIXER and KNST.ALERT live under one screen (reached via KNS.CONFIG /
// DATA in ledger_screen.dart) since they both work off the same relational
// issue set from ExportService.findKnsTreeIssues - FIXER acts on the
// mechanically-safe subset (ONE_SIDED_LINK), ALERT is the full read-only
// list (was the standalone KNS.TREE.ALERT screen before this became a
// two-mode manager).
class KnsTreeManagerScreen extends ConsumerStatefulWidget {
  const KnsTreeManagerScreen({super.key});

  @override
  ConsumerState<KnsTreeManagerScreen> createState() =>
      _KnsTreeManagerScreenState();
}

class _KnsTreeManagerScreenState extends ConsumerState<KnsTreeManagerScreen> {
  bool _onFixer = true;

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'KNS.TREE.MANAGER',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildModeSelector(context),
          ),
          Expanded(
              child: _onFixer
                  ? const _KnstFixerView()
                  : const _KnstAlertView()),
        ],
      ),
    );
  }

  Widget _buildModeSelector(BuildContext context) {
    return Row(
        children: [
      {'label': 'KNST.FIXER', 'sel': _onFixer},
      {'label': 'KNST.ALERT', 'sel': !_onFixer},
    ].map((opt) {
      final sel = opt['sel'] as bool;
      final label = opt['label'] as String;
      return Expanded(
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: InkWell(
                  onTap: () => setState(() => _onFixer = label == 'KNST.FIXER'),
                  child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: sel ? LabColors.accent : Colors.transparent,
                          border: Border.all(color: LabColors.accent, width: 0.5)),
                      child: Text(label,
                          style: LabStyles.mono(context,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: sel ? Colors.black : LabColors.accent))))));
    }).toList());
  }
}

// KNST.FIXER: mechanically-safe fixes only. Currently just AUTO-FIX
// ONESIDED - every issue where an exercise lists a target in
// progressions/regressions/alters but the target is missing the reciprocal
// entry back. There's no ambiguity in that fix (the target name already
// resolves to a real exercise), unlike BROKEN_LINK issues where the target
// doesn't exist at all and a human has to decide whether to create it, fix
// a typo, or drop the link - those stay in KNST.ALERT, not here.
class _KnstFixerView extends ConsumerStatefulWidget {
  const _KnstFixerView();

  @override
  ConsumerState<_KnstFixerView> createState() => _KnstFixerViewState();
}

class _KnstFixerViewState extends ConsumerState<_KnstFixerView> {
  bool _fixing = false;

  // Fixes exactly the ONE_SIDED_LINK issues currently on screen, one
  // targeted add per issue via db.addMissingReciprocal - NOT
  // syncBidirectionalRelations, which is a full add-AND-remove sync built
  // for "this one exercise was just edited, propagate its current state."
  // Looping that over every exercise using each one's pre-batch snapshot
  // was the actual bug behind "the fix button doesn't work": fixing
  // exercise A (adding A's name to B's reciprocal list) then processing B
  // itself with B's now-stale captured metadata made the loop think "A's
  // link isn't in what B declares" and delete it straight back out,
  // undoing the fix it had just made.
  Future<void> _runAutoFixOneSided(List<Map<String, dynamic>> oneSided) async {
    setState(() => _fixing = true);
    final db = ref.read(databaseProvider);
    try {
      for (final issue in oneSided) {
        final target = issue['targetExercise'] as BaseExercise;
        final oppositeCategory = issue['oppositeCategory'] as String;
        final sourceFullName = (issue['exercise'] as BaseExercise).fullName;
        await db.addMissingReciprocal(target.id, oppositeCategory, sourceFullName);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("ONE_SIDED_LINKS_FIXED"),
            backgroundColor: LabColors.primary));
      }
    } finally {
      if (mounted) setState(() => _fixing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercises = ref.watch(allExercisesProvider).value ?? [];
    if (exercises.isEmpty) {
      return Center(
          child: Text('LOADING...',
              style: LabStyles.mono(context, color: Colors.grey)));
    }

    final issues = ExportService.findKnsTreeIssues(exercises);
    final oneSided =
        issues.where((i) => (i['label'] as String).startsWith('ONE_SIDED_LINK')).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: LabColors.surfaceContainerLow,
            border: Border.all(color: LabColors.accent.withValues(alpha: 0.3), width: 0.5),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('AUTO-FIX ONESIDED',
                style: LabStyles.mono(context,
                    fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 6),
            Text(
                oneSided.isEmpty
                    ? 'No one-sided links found.'
                    : '${oneSided.length} one-sided link(s) found - a target exercise is missing the reciprocal entry. Safe to auto-fix: no ambiguity, the target already exists.',
                style: LabStyles.mono(context, fontSize: 9, color: Colors.grey)),
            if (oneSided.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: LabButton(
                  label: _fixing ? 'FIXING...' : 'AUTO-FIX ONESIDED',
                  color: LabColors.accent,
                  onPressed: _fixing
                      ? () {}
                      : () => _runAutoFixOneSided(oneSided),
                ),
              ),
            ],
          ]),
        ),
        const SizedBox(height: 16),
        for (final issue in oneSided) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: LabColors.surfaceContainerLow,
              border: Border.all(color: Colors.grey[800]!, width: 0.5),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text((issue['exercise'] as BaseExercise).fullName,
                  style: LabStyles.mono(context,
                      fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 4),
              Text(issue['label'] as String,
                  style: LabStyles.mono(context, fontSize: 9, color: Colors.orangeAccent)),
            ]),
          ),
        ],
      ],
    );
  }
}

// KNST.ALERT: unchanged from the old standalone KNS.TREE.ALERT screen,
// just relocated here as the read-only sibling of KNST.FIXER. Shows every
// relational issue (BROKEN_LINK and ONE_SIDED_LINK alike) with tap-through
// to edit the flagged exercise.
class _KnstAlertView extends ConsumerWidget {
  const _KnstAlertView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercises = ref.watch(allExercisesProvider).value ?? [];
    if (exercises.isEmpty) {
      return Center(
          child: Text('LOADING...',
              style: LabStyles.mono(context, color: Colors.grey)));
    }
    final issues = ExportService.findKnsTreeIssues(exercises);
    final flaggedCount =
        issues.map((i) => (i['exercise'] as BaseExercise).id).toSet().length;
    final brokenCount = issues
        .where((i) => (i['label'] as String).startsWith('BROKEN_LINK'))
        .length;
    final oneSidedCount = issues.length - brokenCount;

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
              '$brokenCount BROKEN_LINK, $oneSidedCount ONE_SIDED_LINK ACROSS $flaggedCount MOVEMENTS',
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
  }
}
