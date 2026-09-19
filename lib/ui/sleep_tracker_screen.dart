// SLPTRCKR: same tap-on/tap-off + pause/resume mechanic as JRNLR's sleep
// tracker (JRNLR/lib/ui/sleep_screen.dart) - ported, not shared (separate
// app/DB). GO_TO_BED starts a session; WAKE_UP closes it and asks a 1-7
// subjective quality read; PAUSE/RESUME excludes stretches (e.g. woke up
// briefly) from the counted duration.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../database/database.dart';
import '../logic/sleep_stats.dart';
import '../providers/database_provider.dart';
import '../localization/strings.dart';
import 'main_scaffold.dart';
import 'styles.dart';
import 'lab_widgets.dart';

final sleepLogsProvider = StreamProvider<List<SleepLog>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllSleepLogs();
});

/// The still-open session (bed logged, wake not yet logged), or null.
/// Derived from [sleepLogsProvider] instead of a separate query so the
/// screen only watches one stream.
final openSleepSessionProvider = Provider<SleepLog?>((ref) {
  final logs = ref.watch(sleepLogsProvider).valueOrNull ?? [];
  for (final l in logs) {
    if (l.wakeAt == null) return l;
  }
  return null;
});

enum SleepRange { d7, d30, d90, all }

extension on SleepRange {
  DateTime? get cutoff {
    final now = DateTime.now();
    switch (this) {
      case SleepRange.d7:
        return now.subtract(const Duration(days: 7));
      case SleepRange.d30:
        return now.subtract(const Duration(days: 30));
      case SleepRange.d90:
        return now.subtract(const Duration(days: 90));
      case SleepRange.all:
        return null;
    }
  }

  String get label {
    switch (this) {
      case SleepRange.d7:
        return '7D';
      case SleepRange.d30:
        return '30D';
      case SleepRange.d90:
        return '90D';
      case SleepRange.all:
        return 'ALL';
    }
  }
}

String _formatElapsed(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  return '${h}h ${m.toString().padLeft(2, '0')}m';
}

String _formatHours(double hours) {
  final h = hours.floor();
  final m = ((hours - h) * 60).round();
  return '${h}h ${m.toString().padLeft(2, '0')}m';
}

Future<int?> _askQualityFeel(BuildContext context, String lang) {
  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: LabColors.surfaceDim,
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr(lang, 'HOW_WAS_YOUR_SLEEP'),
                style: LabStyles.headline(context).copyWith(fontSize: 16)),
            const SizedBox(height: 4),
            Text('1 = ${tr(lang, 'VERY_BAD')} · 7 = ${tr(lang, 'EXCELLENT')}',
                style: LabStyles.mono(context,
                    fontSize: 10, color: Colors.grey)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(7, (i) {
                final v = i + 1;
                return InkWell(
                  onTap: () => Navigator.pop(context, v),
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        border: Border.all(
                            color: LabColors.sleepIndigo.withValues(alpha: 0.5))),
                    child: Text('$v',
                        style: LabStyles.mono(context,
                            fontSize: 15, color: Colors.white)),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: Text(tr(lang, 'SKIP'),
                    style: LabStyles.mono(context,
                        fontSize: 12, color: Colors.grey)),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class SleepTrackerScreen extends ConsumerStatefulWidget {
  const SleepTrackerScreen({super.key});

  @override
  ConsumerState<SleepTrackerScreen> createState() =>
      _SleepTrackerScreenState();
}

class _SleepTrackerScreenState extends ConsumerState<SleepTrackerScreen> {
  Timer? _ticker;
  SleepRange _range = SleepRange.d30;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _startSession() async {
    await ref.read(databaseProvider).startSleepSession();
  }

  Future<void> _finishSession(SleepLog open) async {
    final lang = ref.read(languageProvider).value ?? 'en';
    if (!mounted) return;
    final quality = await _askQualityFeel(context, lang);
    await ref
        .read(databaseProvider)
        .finishSleepSession(open.id, qualityFeel: quality);
  }

  Future<void> _togglePause(SleepLog open) async {
    final db = ref.read(databaseProvider);
    if (open.pausedAt == null) {
      await db.pauseSleepSession(open.id);
    } else {
      await db.resumeSleepSession(open.id);
    }
  }

  void _editLog(SleepLog log) {
    showModalBottomSheet(
      context: context,
      backgroundColor: LabColors.surfaceDim,
      isScrollControlled: true,
      builder: (c) => _EditSleepLogSheet(log: log),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider).value ?? 'en';
    final logsAsync = ref.watch(sleepLogsProvider);
    final open = ref.watch(openSleepSessionProvider);

    return MainScaffold(
      title: '08 SLPTRCKR',
      body: logsAsync.when(
        data: (logs) {
          final completed = logs.where((l) => l.wakeAt != null).toList();
          final cutoff = _range.cutoff;
          final inRange = cutoff == null
              ? completed
              : completed.where((l) => !l.bedAt.isBefore(cutoff)).toList();
          final points = hoursByDay(inRange);
          final hours = points.map((p) => p.hours).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SessionCard(
                open: open,
                onTap: () {
                  if (open == null) {
                    _startSession();
                  } else {
                    _finishSession(open);
                  }
                },
                onTogglePause: open == null ? null : () => _togglePause(open),
                lang: lang,
              ),
              if (completed.isNotEmpty) ...[
                const SizedBox(height: 20),
                _buildRangeSelector(),
                if (hours.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(children: [
                    _StatBox(label: tr(lang, 'AVERAGE'), value: _formatHours(mean(hours))),
                    const SizedBox(width: 8),
                    _StatBox(label: tr(lang, 'MEDIAN'), value: _formatHours(median(hours))),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    _StatBox(label: tr(lang, 'STD_DEV'), value: '${stdDev(hours).toStringAsFixed(1)}h'),
                    const SizedBox(width: 8),
                    _StatBox(label: tr(lang, 'NIGHTS'), value: '${hours.length}'),
                  ]),
                ] else ...[
                  const SizedBox(height: 12),
                  Text(tr(lang, 'NO_RECORDS_IN_RANGE'),
                      style: LabStyles.mono(context, fontSize: 11, color: Colors.grey)),
                ],
                const SizedBox(height: 24),
                Text(tr(lang, 'RECORDS'),
                    style: LabStyles.mono(context, fontSize: 10, color: LabColors.sleepIndigo)),
                const SizedBox(height: 8),
                ...logs.map((l) => _LogTile(
                      log: l,
                      onTap: () => _editLog(l),
                      onDelete: () =>
                          ref.read(databaseProvider).deleteSleepLog(l.id),
                    )),
              ] else ...[
                const SizedBox(height: 40),
                Center(
                  child: Text(tr(lang, 'NO_SLEEP_RECORDS_YET'),
                      style: LabStyles.mono(context, fontSize: 12, color: Colors.grey)),
                ),
              ],
            ],
          );
        },
        loading: () => const Center(
            child: CircularProgressIndicator(color: LabColors.sleepIndigo)),
        error: (e, _) => Center(
            child: Text('ERROR: $e',
                style: LabStyles.mono(context, color: Colors.redAccent))),
      ),
    );
  }

  Widget _buildRangeSelector() {
    return Row(
      children: SleepRange.values.map((r) {
        final sel = _range == r;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: InkWell(
              onTap: () => setState(() => _range = r),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: sel ? LabColors.sleepIndigo : Colors.transparent,
                  border: Border.all(color: LabColors.sleepIndigo, width: 0.5),
                ),
                child: Text(r.label,
                    style: LabStyles.mono(context,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: sel ? Colors.black : LabColors.sleepIndigo)),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final SleepLog? open;
  final VoidCallback onTap;
  final VoidCallback? onTogglePause;
  final String lang;

  const _SessionCard(
      {required this.open,
      required this.onTap,
      required this.lang,
      this.onTogglePause});

  @override
  Widget build(BuildContext context) {
    final inBed = open != null;
    final paused = open?.pausedAt != null;
    final color = LabColors.sleepIndigo;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
      ),
      child: Column(
        children: [
          Icon(inBed ? Icons.wb_twilight : Icons.bedtime_outlined,
              size: 36, color: color),
          const SizedBox(height: 12),
          if (inBed) ...[
            Text(
              _formatElapsed(activeElapsed(
                  start: open!.bedAt,
                  pausedSeconds: open!.pausedSeconds,
                  pausedAt: open!.pausedAt)),
              style: LabStyles.mono(context, fontSize: 24, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              paused
                  ? tr(lang, 'PAUSED')
                  : '${tr(lang, 'IN_BED_SINCE')} ${DateFormat('HH:mm').format(open!.bedAt)}',
              style: LabStyles.mono(context, fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: LabButton(
                  label: tr(lang, 'WAKE_UP'),
                  onPressed: onTap,
                  color: color,
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: onTogglePause,
                icon: Icon(paused ? Icons.play_arrow : Icons.pause, size: 18),
                label: Text(tr(lang, paused ? 'RESUME' : 'PAUSE')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: color,
                  side: BorderSide(color: color.withValues(alpha: 0.6)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ]),
          ] else ...[
            const SizedBox(height: 4),
            LabButton(
              label: tr(lang, 'GO_TO_BED'),
              onPressed: onTap,
              color: color,
            ),
          ],
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey[800]!, width: 0.5)),
        child: Column(children: [
          Text(value, style: LabStyles.headline(context).copyWith(fontSize: 15)),
          const SizedBox(height: 2),
          Text(label, style: LabStyles.mono(context, fontSize: 8, color: Colors.grey)),
        ]),
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  final SleepLog log;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  static final _dateFmt = DateFormat('d MMM, HH:mm');

  const _LogTile(
      {required this.log, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final hours = hoursInBed(log);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Expanded(
          child: InkWell(
            onTap: onTap,
            child: Text(
              hours != null
                  ? '${_dateFmt.format(log.bedAt)} → ${_formatHours(hours)}'
                      '${log.qualityFeel != null ? ' · ${log.qualityFeel}/7' : ''}'
                  : '${_dateFmt.format(log.bedAt)} — IN_PROGRESS',
              style: LabStyles.mono(context, fontSize: 11, color: Colors.white),
            ),
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: onDelete,
          icon: const Icon(Icons.close, size: 14, color: Colors.grey),
        ),
      ]),
    );
  }
}

class _EditSleepLogSheet extends ConsumerStatefulWidget {
  final SleepLog log;
  const _EditSleepLogSheet({required this.log});

  @override
  ConsumerState<_EditSleepLogSheet> createState() =>
      _EditSleepLogSheetState();
}

class _EditSleepLogSheetState extends ConsumerState<_EditSleepLogSheet> {
  late DateTime _bedAt;
  DateTime? _wakeAt;
  int? _quality;
  static final _dateTimeFmt = DateFormat('d MMM yyyy · HH:mm');

  @override
  void initState() {
    super.initState();
    _bedAt = widget.log.bedAt;
    _wakeAt = widget.log.wakeAt;
    _quality = widget.log.qualityFeel;
  }

  Future<DateTime?> _pickDateTime(DateTime base) async {
    final date = await showDatePicker(
        context: context,
        initialDate: base,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100));
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(base));
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _save() async {
    await ref.read(databaseProvider).updateSleepLog(
          widget.log.id,
          bedAt: _bedAt,
          wakeAt: _wakeAt,
          qualityFeel: _quality,
        );
    if (mounted) Navigator.pop(context);
  }

  Widget _fieldTile(
      {required IconData icon,
      required String label,
      required String value,
      required VoidCallback onTap,
      Widget? trailing}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey[800]!, width: 0.5)),
        child: Row(children: [
          Icon(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: LabStyles.mono(context, fontSize: 9, color: Colors.grey)),
              Text(value, style: LabStyles.mono(context, fontSize: 12, color: Colors.white)),
            ]),
          ),
          if (trailing != null) trailing,
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider).value ?? 'en';
    return Padding(
      padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr(lang, 'EDIT_RECORD'), style: LabStyles.headline(context).copyWith(fontSize: 16)),
            const SizedBox(height: 16),
            _fieldTile(
              icon: Icons.bedtime_outlined,
              label: tr(lang, 'BED_TIME'),
              value: _dateTimeFmt.format(_bedAt),
              onTap: () async {
                final picked = await _pickDateTime(_bedAt);
                if (picked != null) setState(() => _bedAt = picked);
              },
            ),
            const SizedBox(height: 8),
            _fieldTile(
              icon: Icons.wb_twilight,
              label: tr(lang, 'WAKE_TIME'),
              value: _wakeAt == null
                  ? tr(lang, 'IN_PROGRESS')
                  : _dateTimeFmt.format(_wakeAt!),
              onTap: () async {
                final picked = await _pickDateTime(_wakeAt ?? _bedAt);
                if (picked != null) setState(() => _wakeAt = picked);
              },
              trailing: _wakeAt != null
                  ? IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => setState(() => _wakeAt = null),
                      icon: const Icon(Icons.clear, size: 16))
                  : null,
            ),
            const SizedBox(height: 16),
            Text('FEEL (1-7)', style: LabStyles.mono(context, fontSize: 9, color: Colors.grey)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(7, (i) {
                final v = i + 1;
                final selected = _quality == v;
                return InkWell(
                  onTap: () => setState(() => _quality = selected ? null : v),
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? LabColors.sleepIndigo.withValues(alpha: 0.15) : null,
                      border: Border.all(
                          color: selected
                              ? LabColors.sleepIndigo
                              : LabColors.sleepIndigo.withValues(alpha: 0.3),
                          width: selected ? 1 : 0.5),
                    ),
                    child: Text('$v', style: LabStyles.mono(context, fontSize: 13, color: Colors.white)),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            LabButton(label: tr(lang, 'SAVE_CHANGES'), onPressed: _save, color: LabColors.sleepIndigo),
          ],
        ),
      ),
    );
  }
}
