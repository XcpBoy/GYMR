import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../localization/strings.dart';
import '../providers/database_provider.dart';
import '../services/ovarch_plan_injection_service.dart';
import 'WB.editor.dart';
import 'lab_widgets.dart';
import 'main_scaffold.dart';
import 'styles.dart';
import 'workout_manager.dart';

class OvarchPlanScreen extends ConsumerStatefulWidget {
  const OvarchPlanScreen({super.key});

  @override
  ConsumerState<OvarchPlanScreen> createState() => _OvarchPlanScreenState();
}

class _OvarchPlanScreenState extends ConsumerState<OvarchPlanScreen> {
  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);

    return MainScaffold(
      title: '10 PLAN.GENRL',
      floatingActionButton: FloatingActionButton(
        backgroundColor: LabColors.primary,
        onPressed: () => _showPlanDialog(),
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: StreamBuilder<List<TrainingPlan>>(
        stream: (db.select(db.trainingPlans)
              ..orderBy([
                (t) => drift.OrderingTerm.desc(t.isPinned),
                (t) => drift.OrderingTerm.desc(t.createdAt),
              ]))
            .watch(),
        builder: (context, snapshot) {
          final plans = snapshot.data ?? <TrainingPlan>[];
          if (plans.isEmpty) {
            return _buildEmptyPlans();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: plans.length,
            itemBuilder: (context, index) => _buildPlanCard(plans[index]),
          );
        },
      ),
    );
  }

  Widget _buildEmptyPlans() {
    final lang = ref.watch(languageProvider).value ?? 'en';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open,
                size: 64, color: LabColors.primary.withValues(alpha: 0.2)),
            const SizedBox(height: 20),
            Text('NO_OVARCH_PLANS_YET',
                style: LabStyles.headline(context, color: LabColors.onSurface)
                    .copyWith(fontSize: 16)),
            const SizedBox(height: 12),
            Text(
                tr(lang,
                    'CREATE THE FIRST PLAN AND BUILD WEEK / DAY / WB FOLDERS.'),
                style: LabStyles.mono(context,
                    color: LabColors.onSurface.withValues(alpha: 0.6))),
            const SizedBox(height: 24),
            SizedBox(
              width: 260,
              child: LabButton(
                  label: 'CREATE_PLAN', onPressed: () => _showPlanDialog()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(TrainingPlan plan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: LabColors.surfaceDim,
        border: Border.all(
          color: plan.isPinned ? LabColors.primary : LabColors.cyanBorder,
          width: plan.isPinned ? 1 : 0.5,
        ),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => OvarchPlanDetailScreen(plan: plan))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (plan.isPinned) ...[
                          const Icon(Icons.push_pin,
                              color: LabColors.primary, size: 14),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(plan.name.toUpperCase(),
                              style: LabStyles.headline(context,
                                      color: LabColors.onSurface)
                                  .copyWith(fontSize: 15, letterSpacing: 1)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                        plan.notes?.isNotEmpty == true
                            ? plan.notes!.toUpperCase()
                            : 'NO_OBJECTIVES',
                        style: LabStyles.mono(context,
                            color: LabColors.onSurface.withValues(alpha: 0.55),
                            fontSize: 8),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: LabColors.accent, size: 18),
                onPressed: () => _showPlanDialog(plan: plan),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: LabColors.workoutRed, size: 18),
                onPressed: () => _confirmDeletePlan(plan),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showPlanDialog({TrainingPlan? plan}) async {
    final lang = ref.read(languageProvider).value ?? 'en';
    final nameC = TextEditingController(text: plan?.name ?? '');
    final notesC = TextEditingController(text: plan?.notes ?? '');
    final result = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: LabColors.background,
        title: Text(plan == null ? 'CREATE_PLAN' : 'EDIT_PLAN_METADATA',
            style: LabStyles.headline(context, color: LabColors.primary)
                .copyWith(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LabTextField(controller: nameC, label: 'PLAN_NAME'),
            const SizedBox(height: 12),
            LabTextField(
                controller: notesC, label: 'OBJECTIVES / NOTES', maxLines: 4),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(tr(lang, 'CANCEL'),
                  style: LabStyles.mono(context,
                      color: LabColors.onSurface.withValues(alpha: 0.6)))),
          LabButton(
            label: plan == null ? tr(lang, 'CREATE') : tr(lang, 'SAVE'),
            color: LabColors.primary,
            onPressed: () async {
              final trimmed = nameC.text.trim();
              if (trimmed.isEmpty) return;
              final db = ref.read(databaseProvider);
              if (plan == null) {
                await db
                    .into(db.trainingPlans)
                    .insert(TrainingPlansCompanion.insert(
                      name: trimmed.toUpperCase(),
                      notes: drift.Value(notesC.text.trim()),
                    ));
              } else {
                await (db.update(db.trainingPlans)
                      ..where((t) => t.id.equals(plan.id)))
                    .write(TrainingPlansCompanion(
                  name: drift.Value(trimmed.toUpperCase()),
                  notes: drift.Value(notesC.text.trim()),
                ));
              }
              if (!context.mounted) return;
              Navigator.pop(c, true);
            },
          ),
        ],
      ),
    );

    if (result == true && plan != null && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('PLAN_METADATA_UPDATED')));
    }
  }

  Future<void> _confirmDeletePlan(TrainingPlan plan) async {
    final lang = ref.read(languageProvider).value ?? 'en';
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: LabColors.background,
        title: Text('DELETE_PLAN',
            style: LabStyles.headline(context, color: LabColors.workoutRed)
                .copyWith(fontSize: 16)),
        content: Text(
            tr(lang, 'DELETE "{name}" AND ALL WEEKS / DAYS / DAYBLOCKS?')
                .replaceFirst('{name}', plan.name.toUpperCase()),
            style: LabStyles.mono(context,
                color: LabColors.onSurface.withValues(alpha: 0.7))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(tr(lang, 'CANCEL'),
                  style: LabStyles.mono(context,
                      color: LabColors.onSurface.withValues(alpha: 0.6)))),
          LabButton(
              label: tr(lang, 'DELETE'),
              color: LabColors.workoutRed,
              onPressed: () => Navigator.pop(c, true)),
        ],
      ),
    );
    if (ok == true) {
      final db = ref.read(databaseProvider);
      await (db.delete(db.trainingPlans)..where((t) => t.id.equals(plan.id)))
          .go();
      if (context.mounted) Navigator.pop(context);
    }
  }
}

class OvarchPlanDetailScreen extends ConsumerStatefulWidget {
  final TrainingPlan plan;
  const OvarchPlanDetailScreen({super.key, required this.plan});

  @override
  ConsumerState<OvarchPlanDetailScreen> createState() =>
      _OvarchPlanDetailScreenState();
}

class _OvarchPlanDetailScreenState
    extends ConsumerState<OvarchPlanDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);

    return MainScaffold(
      title: widget.plan.name.toUpperCase(),
      actions: [
        IconButton(
            icon: const Icon(Icons.edit, color: LabColors.accent),
            onPressed: () => _showPlanDialog()),
        IconButton(
            icon: const Icon(Icons.delete_outline, color: LabColors.workoutRed),
            onPressed: () => _confirmDeletePlan()),
      ],
      floatingActionButton: FloatingActionButton(
        backgroundColor: LabColors.primary,
        onPressed: _addWeek,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: StreamBuilder<List<PlanWeek>>(
        stream: (db.select(db.planWeeks)
              ..where((t) => t.planId.equals(widget.plan.id))
              ..orderBy([(t) => drift.OrderingTerm.asc(t.weekNumber)]))
            .watch(),
        builder: (context, snapshot) {
          final weeks = snapshot.data ?? <PlanWeek>[];
          if (weeks.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('NO_WEEKS_IN_THIS_PLAN',
                        style: LabStyles.mono(context,
                            color: LabColors.onSurface.withValues(alpha: 0.6))),
                    const SizedBox(height: 16),
                    SizedBox(
                        width: 240,
                        child:
                            LabButton(label: 'ADD_WEEK', onPressed: _addWeek)),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: weeks.length,
            itemBuilder: (context, index) => _buildWeekCard(weeks[index]),
          );
        },
      ),
    );
  }

  Widget _buildWeekCard(PlanWeek week) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: LabStyles.hairlineBorder(color: LabColors.cyanBorder),
      child: InkWell(
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    OvarchWeekDetailScreen(plan: widget.plan, week: week))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('WEEK_${week.weekNumber.toString().padLeft(2, '0')}',
                  style: LabStyles.mono(context,
                      color: LabColors.primary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                  week.purpose?.isNotEmpty == true
                      ? week.purpose!.toUpperCase()
                      : 'ADD_WEEK_PURPOSE...',
                  style: LabStyles.mono(context,
                      color: LabColors.onSurface.withValues(alpha: 0.65))),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addWeek() async {
    final db = ref.read(databaseProvider);
    final weeks = await (db.select(db.planWeeks)
          ..where((t) => t.planId.equals(widget.plan.id)))
        .get();
    final nextWeek = weeks.isEmpty
        ? 1
        : weeks.map((w) => w.weekNumber).reduce((a, b) => a > b ? a : b) + 1;
    await db.into(db.planWeeks).insert(PlanWeeksCompanion.insert(
          planId: widget.plan.id,
          weekNumber: nextWeek,
        ));
  }

  Future<void> _showPlanDialog() async {
    final lang = ref.read(languageProvider).value ?? 'en';
    final nameC = TextEditingController(text: widget.plan.name);
    final notesC = TextEditingController(text: widget.plan.notes ?? '');
    final result = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: LabColors.background,
        title: Text('EDIT_PLAN_METADATA',
            style: LabStyles.headline(context, color: LabColors.primary)
                .copyWith(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LabTextField(controller: nameC, label: 'PLAN_NAME'),
            const SizedBox(height: 12),
            LabTextField(
                controller: notesC, label: 'OBJECTIVES / NOTES', maxLines: 4),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(tr(lang, 'CANCEL'),
                  style: LabStyles.mono(context,
                      color: LabColors.onSurface.withValues(alpha: 0.6)))),
          LabButton(
              label: tr(lang, 'SAVE'),
              color: LabColors.primary,
              onPressed: () async {
                if (nameC.text.trim().isEmpty) return;
                final db = ref.read(databaseProvider);
                await (db.update(db.trainingPlans)
                      ..where((t) => t.id.equals(widget.plan.id)))
                    .write(TrainingPlansCompanion(
                  name: drift.Value(nameC.text.trim().toUpperCase()),
                  notes: drift.Value(notesC.text.trim()),
                ));
                if (context.mounted) Navigator.pop(c, true);
              }),
        ],
      ),
    );
    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('PLAN_METADATA_UPDATED')));
    }
  }

  Future<void> _confirmDeletePlan() async {
    final lang = ref.read(languageProvider).value ?? 'en';
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: LabColors.background,
        title: Text('DELETE_PLAN',
            style: LabStyles.headline(context, color: LabColors.workoutRed)
                .copyWith(fontSize: 16)),
        content: Text(
            tr(lang, 'DELETE "{name}" AND EVERYTHING INSIDE IT?')
                .replaceFirst('{name}', widget.plan.name.toUpperCase()),
            style: LabStyles.mono(context,
                color: LabColors.onSurface.withValues(alpha: 0.7))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(tr(lang, 'CANCEL'),
                  style: LabStyles.mono(context,
                      color: LabColors.onSurface.withValues(alpha: 0.6)))),
          LabButton(
              label: tr(lang, 'DELETE'),
              color: LabColors.workoutRed,
              onPressed: () => Navigator.pop(c, true)),
        ],
      ),
    );
    if (ok == true) {
      final db = ref.read(databaseProvider);
      await (db.delete(db.trainingPlans)
            ..where((t) => t.id.equals(widget.plan.id)))
          .go();
      if (context.mounted) Navigator.pop(context);
    }
  }
}

class OvarchWeekDetailScreen extends ConsumerStatefulWidget {
  final TrainingPlan plan;
  final PlanWeek week;
  const OvarchWeekDetailScreen(
      {super.key, required this.plan, required this.week});

  @override
  ConsumerState<OvarchWeekDetailScreen> createState() =>
      _OvarchWeekDetailScreenState();
}

class _OvarchWeekDetailScreenState
    extends ConsumerState<OvarchWeekDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);

    return MainScaffold(
      title: 'WEEK_${widget.week.weekNumber.toString().padLeft(2, '0')}',
      actions: [
        IconButton(
            icon: const Icon(Icons.edit_note, color: LabColors.accent),
            onPressed: () => _showPurposeDialog()),
        IconButton(
            icon: const Icon(Icons.delete_outline, color: LabColors.workoutRed),
            onPressed: () => _confirmDeleteWeek()),
      ],
      floatingActionButton: FloatingActionButton(
        backgroundColor: LabColors.primary,
        onPressed: _addDay,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: StreamBuilder<List<PlanDay>>(
        stream: (db.select(db.planDays)
              ..where((t) => t.weekId.equals(widget.week.id))
              ..orderBy([(t) => drift.OrderingTerm.asc(t.dayNumber)]))
            .watch(),
        builder: (context, snapshot) {
          final days = snapshot.data ?? <PlanDay>[];
          if (days.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('NO_DAYS_IN_THIS_WEEK',
                        style: LabStyles.mono(context,
                            color: LabColors.onSurface.withValues(alpha: 0.6))),
                    const SizedBox(height: 16),
                    SizedBox(
                        width: 220,
                        child: LabButton(label: 'ADD_DAY', onPressed: _addDay)),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: days.length,
            itemBuilder: (context, index) => _buildDayCard(days[index]),
          );
        },
      ),
    );
  }

  Widget _buildDayCard(PlanDay day) {
    final lang = ref.watch(languageProvider).value ?? 'en';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: LabStyles.hairlineBorder(color: LabColors.cyanBorder),
      child: InkWell(
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => OvarchDayDetailScreen(
                    plan: widget.plan, week: widget.week, day: day))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: LabColors.primary.withValues(alpha: 0.08),
                    border: Border.all(color: LabColors.primary, width: 0.5)),
                child: Text('D${day.dayNumber}',
                    style: LabStyles.mono(context,
                        color: LabColors.primary, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        day.label?.isNotEmpty == true
                            ? day.label!.toUpperCase()
                            : 'DAY_${day.dayNumber}',
                        style: LabStyles.headline(context,
                                color: LabColors.onSurface)
                            .copyWith(fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(tr(lang, 'TAP TO MANAGE DAYBLOCKS'),
                        style: LabStyles.mono(context,
                            color: LabColors.onSurface.withValues(alpha: 0.55),
                            fontSize: 8)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: LabColors.primary),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addDay() async {
    final db = ref.read(databaseProvider);
    final days = await (db.select(db.planDays)
          ..where((t) => t.weekId.equals(widget.week.id)))
        .get();
    final nextDay = days.isEmpty
        ? 1
        : days.map((d) => d.dayNumber).reduce((a, b) => a > b ? a : b) + 1;
    await db.into(db.planDays).insert(PlanDaysCompanion.insert(
          weekId: widget.week.id,
          dayNumber: nextDay,
          label: drift.Value('DAY_$nextDay'),
        ));
  }

  Future<void> _showPurposeDialog() async {
    final lang = ref.read(languageProvider).value ?? 'en';
    final c = TextEditingController(text: widget.week.purpose ?? '');
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LabColors.background,
        title: Text('WEEK_PURPOSE',
            style: LabStyles.headline(context, color: LabColors.primary)
                .copyWith(fontSize: 16)),
        content:
            LabTextField(controller: c, label: 'TECHNICAL_GOAL', maxLines: 4),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr(lang, 'CANCEL'),
                  style: LabStyles.mono(context,
                      color: LabColors.onSurface.withValues(alpha: 0.6)))),
          LabButton(
              label: tr(lang, 'SAVE'),
              color: LabColors.primary,
              onPressed: () async {
                final db = ref.read(databaseProvider);
                await (db.update(db.planWeeks)
                      ..where((t) => t.id.equals(widget.week.id)))
                    .write(PlanWeeksCompanion(
                        purpose: drift.Value(c.text.trim())));
                if (context.mounted) Navigator.pop(ctx, true);
              }),
        ],
      ),
    );
    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('WEEK_PURPOSE_UPDATED')));
    }
  }

  Future<void> _confirmDeleteWeek() async {
    final lang = ref.read(languageProvider).value ?? 'en';
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: LabColors.background,
        title: Text('DELETE_WEEK',
            style: LabStyles.headline(context, color: LabColors.workoutRed)
                .copyWith(fontSize: 16)),
        content: Text(
            tr(lang, 'DELETE THIS WEEK AND ALL DAYS / DAYBLOCKS INSIDE IT?'),
            style: LabStyles.mono(context,
                color: LabColors.onSurface.withValues(alpha: 0.7))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(tr(lang, 'CANCEL'),
                  style: LabStyles.mono(context,
                      color: LabColors.onSurface.withValues(alpha: 0.6)))),
          LabButton(
              label: tr(lang, 'DELETE'),
              color: LabColors.workoutRed,
              onPressed: () => Navigator.pop(c, true)),
        ],
      ),
    );
    if (ok == true) {
      final db = ref.read(databaseProvider);
      await (db.delete(db.planWeeks)..where((t) => t.id.equals(widget.week.id)))
          .go();
      if (context.mounted) Navigator.pop(context);
    }
  }
}

class OvarchDayDetailScreen extends ConsumerStatefulWidget {
  final TrainingPlan plan;
  final PlanWeek week;
  final PlanDay day;
  const OvarchDayDetailScreen(
      {super.key, required this.plan, required this.week, required this.day});

  @override
  ConsumerState<OvarchDayDetailScreen> createState() =>
      _OvarchDayDetailScreenState();
}

class _OvarchDayDetailScreenState extends ConsumerState<OvarchDayDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);
    final lang = ref.watch(languageProvider).value ?? 'en';

    return MainScaffold(
      title: 'DAY_${widget.day.dayNumber}',
      actions: [
        IconButton(
            icon: const Icon(Icons.edit_note, color: LabColors.accent),
            onPressed: () => _showDayLabelDialog()),
        IconButton(
            icon: const Icon(Icons.bolt, color: LabColors.primary),
            onPressed: () => _injectDayToCurrentWorkout()),
        IconButton(
            icon: const Icon(Icons.delete_outline, color: LabColors.workoutRed),
            onPressed: () => _confirmDeleteDay()),
      ],
      floatingActionButton: FloatingActionButton(
        backgroundColor: LabColors.primary,
        onPressed: () => _showAddBlockPicker(),
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: StreamBuilder<List<drift.TypedResult>>(
        stream: (db.select(db.planDayBlocks).join([
          drift.innerJoin(db.workoutBlocks,
              db.workoutBlocks.id.equalsExp(db.planDayBlocks.blockId)),
        ])
              ..where(db.planDayBlocks.dayId.equals(widget.day.id))
              ..orderBy([
                drift.OrderingTerm.asc(db.planDayBlocks.orderIndex),
                drift.OrderingTerm.asc(db.planDayBlocks.id)
              ]))
            .watch(),
        builder: (context, snapshot) {
          final rows = snapshot.data ?? <drift.TypedResult>[];
          if (rows.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('NO_DAYBLOCKS_IN_THIS_DAY',
                        style: LabStyles.mono(context,
                            color: LabColors.onSurface.withValues(alpha: 0.6))),
                    const SizedBox(height: 12),
                    Text(
                        tr(lang,
                            'ADD LIVE REFERENCES TO WORKOUT BLOCKS. WB CHANGES REFLECT HERE AUTOMATICALLY.'),
                        style: LabStyles.mono(context,
                            color: LabColors.onSurface.withValues(alpha: 0.45),
                            fontSize: 9)),
                    const SizedBox(height: 20),
                    SizedBox(
                        width: 260,
                        child: LabButton(
                            label: 'ADD_WORKOUT_BLOCK',
                            onPressed: () => _showAddBlockPicker())),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rows.length,
            itemBuilder: (context, index) => _buildDayBlockCard(rows[index]),
          );
        },
      ),
    );
  }

  Widget _buildDayBlockCard(drift.TypedResult row) {
    final lang = ref.watch(languageProvider).value ?? 'en';
    final db = ref.read(databaseProvider);
    final dayBlock = row.readTable(db.planDayBlocks);
    final block = row.readTable(db.workoutBlocks);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: LabStyles.hairlineBorder(color: LabColors.cyanBorder),
      child: InkWell(
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => WorkoutBlocksEditor(
                    blockName: block.name, blockId: block.id))),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: LabColors.accent.withValues(alpha: 0.08),
                        border:
                            Border.all(color: LabColors.accent, width: 0.5)),
                    child: Text('#${dayBlock.orderIndex + 1}',
                        style: LabStyles.mono(context,
                            color: LabColors.accent,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(block.name.toUpperCase(),
                            style: LabStyles.headline(context,
                                    color: LabColors.onSurface)
                                .copyWith(fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(
                            block.intention?.isNotEmpty == true
                                ? block.intention!.toUpperCase()
                                : tr(lang, 'LIVE WB REFERENCE'),
                            style: LabStyles.mono(context,
                                color:
                                    LabColors.onSurface.withValues(alpha: 0.5),
                                fontSize: 8)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_upward,
                        color: LabColors.primary, size: 18),
                    onPressed: () => _moveBlock(dayBlock, -1),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_downward,
                        color: LabColors.primary, size: 18),
                    onPressed: () => _moveBlock(dayBlock, 1),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              if (dayBlock.notes?.isNotEmpty == true) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: LabColors.surfaceContainer.withValues(alpha: 0.45),
                      border:
                          Border.all(color: LabColors.cyanBorder, width: 0.5)),
                  child: Text(dayBlock.notes!.toUpperCase(),
                      style: LabStyles.mono(context,
                          color: LabColors.onSurface.withValues(alpha: 0.75),
                          fontSize: 8),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                      child: LabButton(
                          label: 'EDIT_BLOCK_NOTES',
                          fontSize: 9,
                          height: 34,
                          onPressed: () => _showBlockNotesDialog(dayBlock))),
                  const SizedBox(width: 8),
                  Expanded(
                      child: LabButton(
                          label: 'REMOVE_REF',
                          color: LabColors.workoutRed,
                          fontSize: 9,
                          height: 34,
                          onPressed: () => _removeBlock(dayBlock))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddBlockPicker() async {
    final db = ref.read(databaseProvider);
    final blocks = await OvarchPlanInjectionService.activeWorkoutBlocks(db);
    if (!context.mounted) return;
    if (blocks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('NO_ACTIVE_WORKOUT_BLOCKS')));
      return;
    }

    final blockIdByValue = <String, int>{};
    final activeBlockIds = blocks.map((b) => (b['id'] as num).toInt()).toSet();
    print(
        '[OVARCH_PICKER_OPEN] blocks=${activeBlockIds.length} ids=${activeBlockIds.join(",")}');
    final values = blocks.map((b) {
      final blockId = (b['id'] as num).toInt();
      final visible = '${b['name']} // $blockId';
      blockIdByValue[visible] = blockId;
      return visible;
    }).toList();
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: LabColors.background,
      isScrollControlled: true,
      builder: (c) => QualitySearchPicker(
          title: 'SELECT_WORKOUT_BLOCK',
          values: values,
          onSelected: (value) => Navigator.pop(c, value)),
    );
    if (picked == null || !context.mounted) return;
    final blockId = blockIdByValue[picked];
    print(
        '[OVARCH_PICKER_SELECTED] picked=$picked blockId=$blockId active=${blockId != null && activeBlockIds.contains(blockId)}');
    if (blockId == null || !activeBlockIds.contains(blockId)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('BLOCK_IS_DELETED_OR_INACTIVE')));
      return;
    }

    final current = await (db.select(db.planDayBlocks)
          ..where((t) => t.dayId.equals(widget.day.id)))
        .get();
    if (!context.mounted) return;
    print(
        '[OVARCH_INSERT_DAYBLOCK] dayId=${widget.day.id} blockId=$blockId order=${current.length}');
    await db.customStatement('''
      INSERT INTO plan_day_blocks (day_id, plan_day_id, block_id, workout_block_id, order_index)
      VALUES (?, ?, ?, ?, ?)
    ''', [widget.day.id, widget.day.id, blockId, blockId, current.length]);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WORKOUT_BLOCK_ADDED_TO_DAY')));
    }
  }

  Future<void> _showBlockNotesDialog(PlanDayBlock dayBlock) async {
    final lang = ref.read(languageProvider).value ?? 'en';
    final c = TextEditingController(text: dayBlock.notes ?? '');
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LabColors.background,
        title: Text('DAYBLOCK_NOTES',
            style: LabStyles.headline(context, color: LabColors.primary)
                .copyWith(fontSize: 16)),
        content: LabTextField(
            controller: c, label: 'NOTES_FOR_THIS_DAYBLOCK', maxLines: 5),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr(lang, 'CANCEL'),
                  style: LabStyles.mono(context,
                      color: LabColors.onSurface.withValues(alpha: 0.6)))),
          LabButton(
              label: tr(lang, 'SAVE'),
              color: LabColors.primary,
              onPressed: () async {
                final db = ref.read(databaseProvider);
                await (db.update(db.planDayBlocks)
                      ..where((t) => t.id.equals(dayBlock.id)))
                    .write(PlanDayBlocksCompanion(
                        notes: drift.Value(c.text.trim())));
                if (context.mounted) Navigator.pop(ctx, true);
              }),
        ],
      ),
    );
    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('DAYBLOCK_NOTES_UPDATED')));
    }
  }

  Future<void> _moveBlock(PlanDayBlock dayBlock, int delta) async {
    final db = ref.read(databaseProvider);
    final current = await (db.select(db.planDayBlocks)
          ..where((t) => t.id.equals(dayBlock.id)))
        .getSingle();
    final targetOrder = current.orderIndex + delta;
    if (targetOrder < 0) return;

    final all = await (db.select(db.planDayBlocks)
          ..where((t) => t.dayId.equals(widget.day.id)))
        .get();
    final maxOrder =
        all.map((b) => b.orderIndex).fold<int>(0, (a, b) => a > b ? a : b);
    if (targetOrder > maxOrder) return;

    final other = all
        .where((b) => b.orderIndex == targetOrder && b.id != dayBlock.id)
        .toList();
    if (other.isEmpty) return;

    await db.transaction(() async {
      await (db.update(db.planDayBlocks)
            ..where((t) => t.id.equals(other.first.id)))
          .write(PlanDayBlocksCompanion(
              orderIndex: drift.Value(current.orderIndex)));
      await (db.update(db.planDayBlocks)..where((t) => t.id.equals(current.id)))
          .write(PlanDayBlocksCompanion(orderIndex: drift.Value(targetOrder)));
    });
  }

  Future<void> _removeBlock(PlanDayBlock dayBlock) async {
    final lang = ref.read(languageProvider).value ?? 'en';
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: LabColors.background,
        title: Text('REMOVE_DAYBLOCK_REFERENCE',
            style: LabStyles.headline(context, color: LabColors.workoutRed)
                .copyWith(fontSize: 16)),
        content: Text(
            tr(lang,
                'REMOVE THIS LIVE WB REFERENCE FROM THE DAY? THE WORKOUT BLOCK ITSELF STAYS INTACT.'),
            style: LabStyles.mono(context,
                color: LabColors.onSurface.withValues(alpha: 0.7))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(tr(lang, 'CANCEL'),
                  style: LabStyles.mono(context,
                      color: LabColors.onSurface.withValues(alpha: 0.6)))),
          LabButton(
              label: tr(lang, 'REMOVE'),
              color: LabColors.workoutRed,
              onPressed: () => Navigator.pop(c, true)),
        ],
      ),
    );
    if (ok == true) {
      final db = ref.read(databaseProvider);
      await (db.delete(db.planDayBlocks)
            ..where((t) => t.id.equals(dayBlock.id)))
          .go();
    }
  }

  Future<void> _injectDayToCurrentWorkout() async {
    print('[PLAN_SCREEN_INJECT] START dayId=${widget.day.id}');
    final db = ref.read(databaseProvider);
    final blocks = await (db.select(db.planDayBlocks)
          ..where((t) => t.dayId.equals(widget.day.id))
          ..orderBy([(t) => drift.OrderingTerm.asc(t.orderIndex)]))
        .get();
    print(
        '[PLAN_SCREEN_INJECT] planDayBlocks query returned count=${blocks.length}');
    for (final b in blocks) {
      print(
          '[PLAN_SCREEN_INJECT] block id=${b.id} dayId=${b.dayId} blockId=${b.blockId} order=${b.orderIndex}');
    }
    if (blocks.isEmpty) {
      print('[PLAN_SCREEN_INJECT] DAY_HAS_NO_WBS dayId=${widget.day.id}');
      if (context.mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('DAY_HAS_NO_WBS')));
      return;
    }

    try {
      print(
          '[PLAN_SCREEN_INJECT] calling injectPlanDay blocks=${blocks.length}');
      final result = await OvarchPlanInjectionService.injectPlanDay(
          db, DateTime.now(), blocks);
      print('[PLAN_SCREEN_INJECT] injectPlanDay result=$result');
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('PLAN_DAY_INJECTED')));
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => WorkoutManagerScreen()));
      }
    } catch (e, stackTrace) {
      print('[PLAN_SCREEN_INJECT] injectPlanDay threw error=$e');
      print(stackTrace);
      if (context.mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _showDayLabelDialog() async {
    final lang = ref.read(languageProvider).value ?? 'en';
    final c = TextEditingController(text: widget.day.label ?? '');
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LabColors.background,
        title: Text('DAY_LABEL',
            style: LabStyles.headline(context, color: LabColors.primary)
                .copyWith(fontSize: 16)),
        content: LabTextField(controller: c, label: 'E.G: PUSH_A', maxLines: 2),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr(lang, 'CANCEL'),
                  style: LabStyles.mono(context,
                      color: LabColors.onSurface.withValues(alpha: 0.6)))),
          LabButton(
              label: tr(lang, 'SAVE'),
              color: LabColors.primary,
              onPressed: () async {
                final db = ref.read(databaseProvider);
                await (db.update(db.planDays)
                      ..where((t) => t.id.equals(widget.day.id)))
                    .write(
                        PlanDaysCompanion(label: drift.Value(c.text.trim())));
                if (context.mounted) Navigator.pop(ctx, true);
              }),
        ],
      ),
    );
    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('DAY_LABEL_UPDATED')));
    }
  }

  Future<void> _confirmDeleteDay() async {
    final lang = ref.read(languageProvider).value ?? 'en';
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: LabColors.background,
        title: Text('DELETE_DAY',
            style: LabStyles.headline(context, color: LabColors.workoutRed)
                .copyWith(fontSize: 16)),
        content: Text(tr(lang, 'DELETE THIS DAY AND ALL DAYBLOCK REFERENCES?'),
            style: LabStyles.mono(context,
                color: LabColors.onSurface.withValues(alpha: 0.7))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(tr(lang, 'CANCEL'),
                  style: LabStyles.mono(context,
                      color: LabColors.onSurface.withValues(alpha: 0.6)))),
          LabButton(
              label: tr(lang, 'DELETE'),
              color: LabColors.workoutRed,
              onPressed: () => Navigator.pop(c, true)),
        ],
      ),
    );
    if (ok == true) {
      final db = ref.read(databaseProvider);
      await (db.delete(db.planDays)..where((t) => t.id.equals(widget.day.id)))
          .go();
      if (context.mounted) Navigator.pop(context);
    }
  }
}
