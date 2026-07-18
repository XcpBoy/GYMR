// Shared widgets used by both workout_manager.dart (live logging) and
// WB.editor.dart (workout block template editor). Extracted from a
// copy-paste fork: keep changes here in sync across both callers.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'dart:async';

import '../../providers/database_provider.dart';
import '../../providers/theme_provider.dart';
import '../../database/database.dart';
import '../styles.dart';
import '../lab_widgets.dart';

// ─── GENERAL NOTES MODULE ───────────────────────────────────────────
class GeneralNotesModule extends ConsumerStatefulWidget {
  final WorkoutLog log;
  final String cardKey;
  const GeneralNotesModule(
      {super.key, required this.log, required this.cardKey});
  @override
  ConsumerState<GeneralNotesModule> createState() =>
      _GeneralNotesModuleState();
}

class _GeneralNotesModuleState extends ConsumerState<GeneralNotesModule> {
  // Notes are stored as a list; serialized to DB with a delimiter
  static const _noteSeparator = '||NOTE||';
  static const _notesDebounce = Duration(milliseconds: 700);
  List<TextEditingController> _controllers = [];
  List<Timer?> _debounceTimers = [];
  bool _isExpanded = false;

  String _getSleepHeader() {
    final sleepMatch =
        RegExp(r'\[S:[\d.]+\]').firstMatch(widget.log.notes ?? '');
    return sleepMatch != null ? '${sleepMatch.group(0)} ' : '';
  }

  List<String> _parseNotes(String raw) {
    // Strip sleep header
    final clean = raw.replaceAll(RegExp(r'\[S:[\d.]+\]\s*'), '').trim();
    if (clean.isEmpty) return [];
    return clean
        .split(_noteSeparator)
        .map((n) => n.trim())
        .where((n) => n.isNotEmpty)
        .toList();
  }

  Future<void> _persistNotes() async {
    if (!mounted) return;

    final logId = widget.log.id;
    final sleepHeader = _getSleepHeader();
    final texts = _controllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    final joined = texts.join(_noteSeparator);
    final db = ref.read(databaseProvider);
    await (db.update(db.workoutLogs)..where((t) => t.id.equals(logId))).write(
      WorkoutLogsCompanion(notes: drift.Value(sleepHeader + joined)),
    );
  }

  void _scheduleDebounce(int index) {
    _debounceTimers[index]?.cancel();
    _debounceTimers[index] =
        Timer(_notesDebounce, () => unawaited(_persistNotes()));
  }

  void _addNote() {
    setState(() {
      _controllers.add(TextEditingController());
      _debounceTimers.add(null);
    });
  }

  void _deleteNote(int index) {
    _debounceTimers[index]?.cancel();
    _controllers[index].dispose();
    setState(() {
      _controllers.removeAt(index);
      _debounceTimers.removeAt(index);
    });
    _persistNotes();
  }

  @override
  void initState() {
    super.initState();
    final notes = _parseNotes(widget.log.notes ?? '');
    _controllers = <TextEditingController>[
      ...notes.map((n) => TextEditingController(text: n))
    ];
    _debounceTimers = <Timer?>[
      for (var i = 0; i < _controllers.length; i++) null
    ];
  }

  @override
  void dispose() {
    for (var t in _debounceTimers) {
      t?.cancel();
    }
    for (var c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(themeSettingsProvider).value ?? {};
    final notesColor = ref.read(themeControllerProvider).getColor(
        settings, 'UI_TAG_SESSION_NOTES',
        defaultColor: LabColors.accent);
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 24),
      decoration: LabStyles.hairlineBorder(color: notesColor),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row (tappable) ──
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
              color: notesColor.withOpacity(0.06),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: notesColor,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.cardKey,
                        style: LabStyles.mono(context,
                            color: notesColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: _addNote,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        border: Border.all(color: notesColor, width: 0.5),
                        color: notesColor.withOpacity(0.08),
                      ),
                      child: Text(
                        '+ ADD.NOTE',
                        style: LabStyles.mono(context,
                            color: notesColor,
                            fontSize: 9,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_isExpanded) ...[
            // ── Empty state ──
            if (_controllers.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  'NO_NOTES // TAP + ADD.NOTE',
                  style: LabStyles.mono(context,
                      fontSize: 10, color: Colors.grey[700]),
                ),
              ),

            // ── Note blocks ──
            ...List.generate(_controllers.length, (i) {
              return Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[850]!, width: 0.5),
                  color: Colors.white.withOpacity(0.03),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Index tag
                    Container(
                      width: 28,
                      color: LabColors.primary.withOpacity(0.12),
                      alignment: Alignment.topCenter,
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        '${i + 1}',
                        style: LabStyles.mono(context,
                            fontSize: 10,
                            color: LabColors.primary,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    // Text input
                    Expanded(
                      child: TextField(
                        controller: _controllers[i],
                        maxLines: null,
                        style: LabStyles.mono(context, fontSize: 12),
                        decoration: InputDecoration(
                          hintText: 'NOTE_${i + 1}...',
                          hintStyle: LabStyles.mono(context,
                              fontSize: 10, color: Colors.grey[700]),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.fromLTRB(10, 10, 4, 10),
                        ),
                        textInputAction: TextInputAction.newline,
                        keyboardType: TextInputType.multiline,
                        textCapitalization: TextCapitalization.sentences,
                        autocorrect: false,
                        enableSuggestions: false,
                        onChanged: (_) => _scheduleDebounce(i),
                      ),
                    ),
                    // Delete button
                    IconButton(
                      icon: const Icon(Icons.close, size: 14),
                      color: Colors.grey[700],
                      splashRadius: 14,
                      onPressed: () => _deleteNote(i),
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}

// ─── BLUEPRINT SEARCH PICKER ────────────────────────────────────────
class BlueprintSearchPicker extends ConsumerStatefulWidget {
  final List<Blueprint> blueprints;
  final Function(Blueprint) onSelected;
  const BlueprintSearchPicker(
      {super.key, required this.blueprints, required this.onSelected});
  @override
  ConsumerState<BlueprintSearchPicker> createState() =>
      _BlueprintSearchPickerState();
}

class _BlueprintSearchPickerState
    extends ConsumerState<BlueprintSearchPicker> {
  late List<Blueprint> flt;
  final TextEditingController sC = TextEditingController();
  final Map<int, String> sums = {};
  @override
  void initState() {
    super.initState();
    flt = widget.blueprints;
    sC.addListener(() {
      setState(() {
        flt = widget.blueprints
            .where((b) => b.name.toLowerCase().contains(sC.text.toLowerCase()))
            .toList();
      });
    });
    Future.microtask(() => _ld());
  }

  Future<void> _ld() async {
    final db = ref.read(databaseProvider);
    for (var b in widget.blueprints) {
      final rows = await (db.select(db.blueprintExercises).join([
        drift.innerJoin(db.baseExercises,
            db.baseExercises.id.equalsExp(db.blueprintExercises.baseExerciseId))
      ])
            ..where(db.blueprintExercises.blueprintId.equals(b.id)))
          .get();
      final n = rows.map((r) {
        final e = r.readTable(db.baseExercises);
        return e.fullName;
      }).join(' • ');
      if (mounted)
        setState(() {
          sums[b.id] = n.isEmpty ? 'EMPTY' : n;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          children: [
            Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                    color: LabColors.surfaceContainerHigh,
                    border: Border(
                        bottom:
                            BorderSide(color: LabColors.primary, width: 2))),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('SELECT_BLUEPRINT',
                            style: LabStyles.headline(context)
                                .copyWith(fontSize: 18)),
                        IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close, color: Colors.white))
                      ]),
                  const SizedBox(height: 16),
                  LabTextField(controller: sC, label: 'Search...')
                ])),
            Expanded(
                child: ListView.builder(
                    itemCount: flt.length,
                    itemBuilder: (c, i) => LabListTile(
                        title: flt[i].name.toUpperCase(),
                        subtitle: sums[flt[i].id] ?? 'LOADING...',
                        onTap: () {
                          widget.onSelected(flt[i]);
                          Navigator.pop(context);
                        })))
          ],
        ));
  }
}

// ─── EXERCISE SEARCH PICKER ─────────────────────────────────────────
class ExerciseSearchPicker extends ConsumerStatefulWidget {
  final List<BaseExercise> exercises;
  final Function(BaseExercise) onSelected;
  const ExerciseSearchPicker(
      {super.key, required this.exercises, required this.onSelected});
  @override
  ConsumerState<ExerciseSearchPicker> createState() =>
      _ExerciseSearchPickerState();
}

enum _ExerciseSortMode {
  alpha,
  reverseAlpha,
  newestFirst,
  oldestFirst,
  mostUsed,
  leastUsed
}

class _ExerciseSearchPickerState extends ConsumerState<ExerciseSearchPicker> {
  late List<BaseExercise> _all;
  late List<BaseExercise> _filtered;
  final TextEditingController _searchC = TextEditingController();
  _ExerciseSortMode _sortMode = _ExerciseSortMode.alpha;

  // Filter state
  String? _fLoad;
  bool? _fIso; // replaced _fClass (C/I) with isometric toggle
  bool? _fUni;
  String? _fBase;
  String? _fMuscle;
  String? _fImpl;

  // Unique values for filter sheets
  late Set<String> _loadValues;
  late Set<String> _baseValues;
  late Set<String> _muscleValues;
  late Set<String> _implValues;

  String get _sortLabel {
    switch (_sortMode) {
      case _ExerciseSortMode.alpha:
        return 'A-Z';
      case _ExerciseSortMode.reverseAlpha:
        return 'Z-A';
      case _ExerciseSortMode.newestFirst:
        return 'NEW';
      case _ExerciseSortMode.oldestFirst:
        return 'OLD';
      case _ExerciseSortMode.mostUsed:
        return 'MST';
      case _ExerciseSortMode.leastUsed:
        return 'LST';
    }
  }

  // Controllers for BASE and MUSCLE text-input filters
  final TextEditingController _baseC = TextEditingController();
  final TextEditingController _muscleC = TextEditingController();

  bool get _hasActiveFilters =>
      _fLoad != null ||
      _fIso != null ||
      _fUni != null ||
      _fBase != null ||
      _fMuscle != null ||
      _fImpl != null;

  @override
  void initState() {
    super.initState();
    _all = widget.exercises;
    _filtered = _all;
    _searchC.addListener(_applyFilters);
    _baseC.addListener(_onBaseChanged);
    _muscleC.addListener(_onMuscleChanged);
    _extractFilterValues();
  }

  void _onBaseChanged() {
    final q = _baseC.text.toLowerCase();
    if (q.isEmpty) {
      if (_fBase != null) {
        setState(() => _fBase = null);
        _applyFilters();
      }
      return;
    }
    final match = _baseValues.firstWhere(
      (v) => v.toLowerCase() == q,
      orElse: () => '',
    );
    if (match.isNotEmpty && _fBase != match) {
      setState(() => _fBase = match);
      _applyFilters();
    }
  }

  void _onMuscleChanged() {
    final q = _muscleC.text.toLowerCase();
    if (q.isEmpty) {
      if (_fMuscle != null) {
        setState(() => _fMuscle = null);
        _applyFilters();
      }
      return;
    }
    final match = _muscleValues.firstWhere(
      (v) => v.toLowerCase() == q,
      orElse: () => '',
    );
    if (match.isNotEmpty && _fMuscle != match) {
      setState(() => _fMuscle = match);
      _applyFilters();
    }
  }

  void _extractFilterValues() {
    _loadValues = {};
    _baseValues = {};
    _muscleValues = {};
    _implValues = {};
    for (final e in _all) {
      final intent = e.intention ?? '';
      final m = RegExp(r'\[NT:(.*?)\|ISO:(.*?)\]').firstMatch(intent);
      if (m != null) {
        _loadValues.add(m.group(1) ?? '');
      } else if (['LASTRE', 'EXT.LOAD', 'JST.BW'].contains(e.field)) {
        if (e.field != null) _loadValues.add(e.field!);
      }
      if (e.name.isNotEmpty) _baseValues.add(e.name);
      if (e.primaryMuscleGroup != null && e.primaryMuscleGroup!.isNotEmpty) {
        _muscleValues.add(e.primaryMuscleGroup!);
      }
      if (e.secondaryMuscleGroup != null &&
          e.secondaryMuscleGroup!.isNotEmpty) {
        _muscleValues.add(e.secondaryMuscleGroup!);
      }
      if (e.implements != null && e.implements!.isNotEmpty)
        _implValues.add(e.implements!);
    }
  }

  // ── Isometric detection ──
  bool _isIsometric(BaseExercise e) {
    final intent = e.intention ?? '';
    // Check [NT:...|ISO:true] pattern
    final m = RegExp(r'\[NT:(.*?)\|ISO:(.*?)\]').firstMatch(intent);
    if (m != null) return m.group(2) == 'true';
    // Check if intention starts with [ISO]
    if (intent.startsWith('[ISO]')) return true;
    // Check complexMetadata for isometric flag
    final meta = e.parsedComplexMetadata;
    if (meta['isIsometric'] == true) return true;
    return false;
  }

  void _applyFilters() {
    final q = _searchC.text.toLowerCase();
    setState(() {
      _filtered = _all.where((e) {
        // 1. Text search across ALL fields
        if (q.isNotEmpty) {
          final sb = StringBuffer()
            ..write(e.fullName.toLowerCase())
            ..write(' ')
            ..write(e.name.toLowerCase())
            ..write(' ')
            ..write((e.prefixes ?? '').toLowerCase())
            ..write(' ')
            ..write((e.suffixes ?? '').toLowerCase())
            ..write(' ')
            ..write((e.implements ?? '').toLowerCase())
            ..write(' ')
            ..write((e.bodyPositions ?? '').toLowerCase())
            ..write(' ')
            ..write((e.intention ?? '').toLowerCase())
            ..write(' ')
            ..write((e.patternType ?? '').toLowerCase())
            ..write(' ')
            ..write((e.tissueType ?? '').toLowerCase())
            ..write(' ')
            ..write((e.tissueName ?? '').toLowerCase())
            ..write(' ')
            ..write((e.primaryMuscleGroup ?? '').toLowerCase())
            ..write(' ')
            ..write((e.secondaryMuscleGroup ?? '').toLowerCase())
            ..write(' ')
            ..write((e.field ?? '').toLowerCase());
          if (!sb.toString().contains(q)) return false;
        }
        // 2. Load type filter
        if (_fLoad != null) {
          final intent = e.intention ?? '';
          final m = RegExp(r'\[NT:(.*?)\|ISO:(.*?)\]').firstMatch(intent);
          final lt = m != null ? (m.group(1) ?? '') : (e.field ?? '');
          if (lt != _fLoad) return false;
        }
        // 3. Isometric filter (replaces C/I)
        if (_fIso != null) {
          if (_isIsometric(e) != _fIso) return false;
        }
        // 4. Unilateral filter
        if (_fUni != null) {
          if (e.isUnilateral != _fUni) return false;
        }
        // 5. Base name filter (text input)
        if (_fBase != null) {
          if (e.name != _fBase) return false;
        }
        // 6. Muscle filter (text input)
        if (_fMuscle != null) {
          if (e.primaryMuscleGroup != _fMuscle &&
              e.secondaryMuscleGroup != _fMuscle) return false;
        }
        // 7. Implement filter
        if (_fImpl != null) {
          if ((e.implements ?? '') != _fImpl) return false;
        }
        return true;
      }).toList();
      // Apply sort mode
      switch (_sortMode) {
        case _ExerciseSortMode.alpha:
          _filtered.sort((a, b) => a.name.compareTo(b.name));
          break;
        case _ExerciseSortMode.reverseAlpha:
          _filtered.sort((a, b) => b.name.compareTo(a.name));
          break;
        case _ExerciseSortMode.newestFirst:
          _filtered.sort((a, b) => b.id.compareTo(a.id));
          break;
        case _ExerciseSortMode.oldestFirst:
          _filtered.sort((a, b) => a.id.compareTo(b.id));
          break;
        case _ExerciseSortMode.mostUsed:
          _filtered.sort((a, b) => b.id.compareTo(a.id));
          break;
        case _ExerciseSortMode.leastUsed:
          _filtered.sort((a, b) => a.id.compareTo(b.id));
          break;
      }
    });
  }

  String _loadTypeOf(BaseExercise e) {
    final m = RegExp(r'\[NT:(.*?)\|ISO:(.*?)\]').firstMatch(e.intention ?? '');
    if (m != null) return m.group(1) ?? 'EXT.LOAD';
    if (['LASTRE', 'EXT.LOAD', 'JST.BW'].contains(e.field)) return e.field!;
    return 'EXT.LOAD';
  }

  String? _classOf(BaseExercise e) => e.parsedComplexMetadata['classification'];

  String _buildSubtitle(BaseExercise e) {
    final lt = _loadTypeOf(e);
    final cls = _classOf(e);
    final parts = <String>[];
    if (e.primaryMuscleGroup != null && e.primaryMuscleGroup!.isNotEmpty) {
      parts.add(e.primaryMuscleGroup!.toUpperCase());
    }
    parts.add('[$lt]');
    if (cls != null && cls.isNotEmpty) parts.add(cls);
    if (e.isUnilateral) parts.add('[UNI]');
    if (e.field != null && e.field!.isNotEmpty)
      parts.add(e.field!.toUpperCase());
    return parts.join('  •  ');
  }

  // ── Theme-aware color helpers ──
  Color _themeColor(String key, String nameSeed) {
    final settings = ref.watch(themeSettingsProvider).value ?? {};
    return ref
        .read(themeControllerProvider)
        .getColor(settings, key, nameSeed: nameSeed);
  }

  Color _filterChipColor(String tag, String? activeValue) {
    // Each filter chip gets its color from UI_TAG_ theme keys
    return _themeColor('UI_TAG_${tag.toUpperCase()}', tag);
  }

  Color _baseColor(String baseName) {
    // Looks up MOVEMENT_$baseName from THEME.MDYFR
    return _themeColor('MOVEMENT_$baseName', baseName);
  }

  Color _muscleColor(String muscleName) {
    // Looks up MUSCLE_$muscleName from THEME.MDYFR
    return _themeColor('MUSCLE_$muscleName', muscleName);
  }

  void _showFilterSheet(String title, Set<String> values, String? current,
      ValueChanged<String?> onSelect) {
    final sorted = values.toList()..sort();
    showModalBottomSheet(
      context: context,
      backgroundColor: LabColors.background,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(title,
                style: LabStyles.headline(ctx).copyWith(fontSize: 14)),
          ),
          const Divider(
              height: 0.5, color: LabColors.cyanBorder, thickness: 0.2),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                ListTile(
                  title: Text('CLEAR',
                      style: LabStyles.mono(ctx,
                          fontSize: 11, color: Colors.redAccent)),
                  onTap: () {
                    onSelect(null);
                    Navigator.pop(ctx);
                  },
                ),
                ...sorted.map((v) => ListTile(
                      title: Text(v,
                          style: LabStyles.mono(ctx,
                              fontSize: 11,
                              color: current == v ? LabColors.primary : null)),
                      trailing: current == v
                          ? const Icon(Icons.check,
                              color: LabColors.primary, size: 14)
                          : null,
                      onTap: () {
                        onSelect(v);
                        Navigator.pop(ctx);
                      },
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _clearAllFilters() {
    setState(() {
      _fLoad = null;
      _fIso = null;
      _fUni = null;
      _fBase = null;
      _fMuscle = null;
      _fImpl = null;
      _baseC.clear();
      _muscleC.clear();
    });
    _applyFilters();
  }

  // ── Filter chip widget (theme-colored, white text) ──
  Widget _filterChip(String label, String? value, VoidCallback onTap) {
    final isActive = value != null;
    final themeColor = _filterChipColor(label, value);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        margin: const EdgeInsets.only(right: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive
              ? themeColor.withValues(alpha: 0.15)
              : Colors.transparent,
          border: Border.all(
            color: isActive
                ? themeColor
                : LabColors.cyanBorder.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Text(
          isActive
              ? '$label:${value!.toUpperCase()}'
              : '${label.toUpperCase()}:ALL',
          textAlign: TextAlign.center,
          style: LabStyles.mono(context, fontSize: 8, color: Colors.white),
        ),
      ),
    );
  }

  Widget _triStateChip({
    required String label,
    required bool? value,
    required ValueChanged<bool?> onTap,
  }) {
    String text;
    final yesColor = _filterChipColor(label, 'YES');
    if (value == null) {
      text = '${label.toUpperCase()}:ALL';
    } else if (value == true) {
      text = '${label.toUpperCase()}:YES';
    } else {
      text = '${label.toUpperCase()}:NO';
    }
    return GestureDetector(
      onTap: () {
        if (value == null) {
          onTap(true);
        } else if (value == true) {
          onTap(false);
        } else {
          onTap(null);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        margin: const EdgeInsets.only(right: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: value != null
              ? yesColor.withValues(alpha: 0.15)
              : Colors.transparent,
          border: Border.all(
            color: value != null
                ? yesColor
                : LabColors.cyanBorder.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Text(text,
            textAlign: TextAlign.center,
            style: LabStyles.mono(context, fontSize: 8, color: Colors.white)),
      ),
    );
  }

  // ── Text-input filter field (BASE / MUSCLE) ──
  Widget _textFilterField({
    required String label,
    required TextEditingController controller,
    required Set<String> suggestions,
    required String? currentValue,
    required Color activeColor,
    required VoidCallback onClear,
  }) {
    final isActive = currentValue != null;
    // Autocomplete options
    final options = suggestions
        .where((s) => s.toLowerCase().contains(controller.text.toLowerCase()))
        .toList()
      ..sort();

    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        child: Autocomplete<String>(
          optionsBuilder: (TextEditingValue tev) {
            if (tev.text.isEmpty) return suggestions.toList()..sort();
            return suggestions
                .where((s) => s.toLowerCase().contains(tev.text.toLowerCase()))
                .toList()
              ..sort();
          },
          displayStringForOption: (o) => o,
          onSelected: (selection) {
            controller.text = selection;
          },
          fieldViewBuilder: (ctx, tc, fn, onSubmitted) {
            // Keep our controller in sync
            if (controller.text != tc.text && !tc.selection.isValid) {
              tc.text = controller.text;
            }
            return Container(
              height: 36,
              decoration: BoxDecoration(
                color: isActive
                    ? activeColor.withValues(alpha: 0.08)
                    : LabColors.surfaceDim,
                border: Border.all(
                  color: isActive
                      ? activeColor
                      : LabColors.cyanBorder.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: tc,
                      focusNode: fn,
                      style: LabStyles.mono(context,
                          fontSize: 9, color: Colors.white),
                      decoration: InputDecoration(
                        hintText: label.toUpperCase(),
                        hintStyle: LabStyles.mono(context,
                            fontSize: 9, color: Colors.grey[700]),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  if (isActive)
                    GestureDetector(
                      onTap: () {
                        tc.clear();
                        controller.clear();
                        onClear();
                      },
                      child: const Icon(Icons.close,
                          color: Colors.redAccent, size: 14),
                    ),
                ],
              ),
            );
          },
          optionsViewBuilder: (ctx, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                color: LabColors.surfaceContainerHigh,
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxHeight: 180, maxWidth: 300),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (_, i) {
                      final opt = options.elementAt(i);
                      return ListTile(
                        dense: true,
                        title: Text(opt,
                            style: LabStyles.mono(ctx,
                                fontSize: 10, color: Colors.white)),
                        onTap: () => onSelected(opt),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    // Active colors for BASE/MUSCLE text fields
    final activeBaseColor =
        _fBase != null ? _baseColor(_fBase!) : LabColors.primary;
    final activeMuscleColor =
        _fMuscle != null ? _muscleColor(_fMuscle!) : LabColors.primary;

    return Container(
      height: h * 0.92,
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        children: [
          // ── Header ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: LabColors.surfaceContainerHigh,
              border: Border(
                  bottom: BorderSide(color: LabColors.primary, width: 2)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('INJECT_MOVEMENT',
                        style:
                            LabStyles.headline(context).copyWith(fontSize: 18)),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Search bar + sort button
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: SizedBox(
                        height: 36,
                        child: TextField(
                          controller: _searchC,
                          style: LabStyles.mono(context,
                              fontSize: 12, color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'SEARCH...',
                            hintStyle: TextStyle(
                                color: Colors.grey[600], fontSize: 11),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Colors.grey[800]!, width: 0.5)),
                            enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Colors.grey[800]!, width: 0.5)),
                            focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: LabColors.primary, width: 0.5)),
                            fillColor: LabColors.surfaceDim,
                            filled: true,
                            isDense: true,
                          ),
                          onChanged: (_) => _applyFilters(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      height: 36,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(0)),
                          side: BorderSide(color: Colors.white24, width: 0.5),
                        ),
                        onPressed: () {
                          setState(() {
                            _sortMode = _ExerciseSortMode.values[
                                (_sortMode.index + 1) %
                                    _ExerciseSortMode.values.length];
                            _applyFilters();
                          });
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.sort, size: 14, color: Colors.grey[400]),
                            const SizedBox(width: 4),
                            Text(
                              _sortLabel,
                              style: LabStyles.mono(context,
                                  fontSize: 9, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Filter row: LOAD, ISO, UNI, IMPL
                Row(
                  children: [
                    Expanded(
                        child: _filterChip('LOAD', _fLoad, () {
                      _showFilterSheet(
                          'FILTER BY LOAD TYPE', _loadValues, _fLoad, (v) {
                        setState(() => _fLoad = v);
                        _applyFilters();
                      });
                    })),
                    Expanded(
                        child: _triStateChip(
                      label: 'ISO',
                      value: _fIso,
                      onTap: (v) {
                        setState(() => _fIso = v);
                        _applyFilters();
                      },
                    )),
                    Expanded(
                        child: _triStateChip(
                      label: 'UNI',
                      value: _fUni,
                      onTap: (v) {
                        setState(() => _fUni = v);
                        _applyFilters();
                      },
                    )),
                    Expanded(
                        child: _filterChip('IMPL', _fImpl, () {
                      _showFilterSheet('FILTER BY IMPL', _implValues, _fImpl,
                          (v) {
                        setState(() => _fImpl = v);
                        _applyFilters();
                      });
                    })),
                  ],
                ),
                const SizedBox(height: 8),
                // Row 2: BASE and MUSCLE as wide text-input fields
                Row(
                  children: [
                    _textFilterField(
                      label: 'BASE',
                      controller: _baseC,
                      suggestions: _baseValues,
                      currentValue: _fBase,
                      activeColor: activeBaseColor,
                      onClear: () {
                        setState(() => _fBase = null);
                        _applyFilters();
                      },
                    ),
                    _textFilterField(
                      label: 'MUSCLE',
                      controller: _muscleC,
                      suggestions: _muscleValues,
                      currentValue: _fMuscle,
                      activeColor: activeMuscleColor,
                      onClear: () {
                        setState(() => _fMuscle = null);
                        _applyFilters();
                      },
                    ),
                  ],
                ),
                if (_hasActiveFilters) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: _clearAllFilters,
                      child: Text(
                        'CLEAR ALL FILTERS',
                        style: LabStyles.mono(context,
                            fontSize: 8,
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // ── Results counter bar ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: LabColors.surfaceContainerHigh.withValues(alpha: 0.5),
              border: const Border(
                  bottom: BorderSide(color: LabColors.cyanBorder, width: 0.2)),
            ),
            child: Row(
              children: [
                Text(
                  'RESULTS: ${_filtered.length}',
                  style: LabStyles.mono(context,
                      fontSize: 9,
                      color: LabColors.primary,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 16),
                Text(
                  'TOTAL: ${_all.length}',
                  style:
                      LabStyles.mono(context, fontSize: 9, color: Colors.white),
                ),
              ],
            ),
          ),
          // ── Results list ──
          Expanded(
            child: ListView.builder(
              itemCount: _filtered.length,
              itemBuilder: (_, i) {
                final e = _filtered[i];
                return LabListTile(
                  title: e.fullName,
                  subtitle: _buildSubtitle(e),
                  onTap: () {
                    widget.onSelected(e);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchC.dispose();
    _baseC.dispose();
    _muscleC.dispose();
    super.dispose();
  }
}

// ─── QUICK ACTION BUTTON ────────────────────────────────────────────
class QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double fontSize;

  const QuickActionButton(
      {super.key,
      required this.label,
      required this.icon,
      required this.color,
      required this.onTap,
      this.fontSize = 7});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
            color: color.withValues(alpha: 0.05)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(height: 2),
            Text(label,
                style:
                    LabStyles.mono(context, fontSize: fontSize, color: color),
                textAlign: TextAlign.center,
                maxLines: 1),
          ],
        ),
      ),
    );
  }
}

// ─── UNILATERAL PAIR FRAME + SIDE LABEL ─────────────────────────────
class UnilateralPairFrame extends ConsumerWidget {
  final Widget rightSet;
  final Widget leftSet;
  final int index;
  const UnilateralPairFrame(
      {super.key,
      required this.rightSet,
      required this.leftSet,
      required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(themeSettingsProvider).value ?? {};
    final tC = ref.read(themeControllerProvider);
    final rightColor =
        tC.getColor(settings, "UI_UNILATERAL_RIGHT", nameSeed: "RIGHT");
    final leftColor =
        tC.getColor(settings, "UI_UNILATERAL_LEFT", nameSeed: "LEFT");

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        border: Border.all(
            color: LabColors.primary.withValues(alpha: 0.15), width: 1),
      ),
      child: Column(
        children: [
          SideLabel(label: "RIGHT_SIDE", color: rightColor),
          rightSet,
          const Divider(height: 16, color: Colors.white10, thickness: 0.5),
          SideLabel(label: "LEFT_SIDE", color: leftColor),
          leftSet,
        ],
      ),
    );
  }
}

class SideLabel extends StatelessWidget {
  final String label;
  final Color color;
  const SideLabel({super.key, required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, left: 4),
      child: Row(
        children: [
          Container(width: 2, height: 10, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: LabStyles.mono(context,
                  fontSize: 7,
                  color: color.withValues(alpha: 0.8),
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ─── EDITABLE SESSION TIMER ──────────────────────────────────────────
// Callers pass their own log/tick providers: workout_manager.dart wires a
// real DB-backed "today's session" stream, WB.editor.dart wires a stub
// (there's no live session while editing a block template). Keeping the
// providers as constructor params preserves that difference exactly
// instead of forcing one behavior on both screens.
class EditableSessionTimer extends ConsumerStatefulWidget {
  final StreamProvider<WorkoutLog?> logProvider;
  final StreamProvider<int> tickProvider;
  const EditableSessionTimer(
      {super.key, required this.logProvider, required this.tickProvider});
  @override
  ConsumerState<EditableSessionTimer> createState() =>
      _EditableSessionTimerState();
}

class _EditableSessionTimerState extends ConsumerState<EditableSessionTimer> {
  late TextEditingController _controller;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateFromLog(WorkoutLog? log) {
    if (_isEditing) return;

    final isRunning = log?.workoutStartTime != null;
    final accumulated = log?.accumulatedSeconds ?? 0;
    final startTime = log?.workoutStartTime;

    final totalSeconds = isRunning
        ? accumulated + DateTime.now().difference(startTime!).inSeconds
        : accumulated;

    final h = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');

    final newText = "$h:$m:$s";
    if (_controller.text != newText) {
      _controller.text = newText;
    }
  }

  Future<void> _saveManualTime(WorkoutLog log) async {
    final parts = _controller.text.split(':');
    int totalSeconds = 0;
    try {
      if (parts.length == 3) {
        totalSeconds = (int.parse(parts[0]) * 3600) +
            (int.parse(parts[1]) * 60) +
            int.parse(parts[2]);
      } else if (parts.length == 2) {
        totalSeconds = (int.parse(parts[0]) * 60) + int.parse(parts[1]);
      } else if (parts.length == 1) {
        totalSeconds = int.parse(parts[0]);
      }

      final db = ref.read(databaseProvider);
      await (db.update(db.workoutLogs)..where((t) => t.id.equals(log.id)))
          .write(WorkoutLogsCompanion(
        accumulatedSeconds: drift.Value(totalSeconds),
        durationMinutes: drift.Value(totalSeconds ~/ 60),
      ));
    } catch (e) {
      debugPrint("Error parsing timer: $e");
    }
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    final logAsync = ref.watch(widget.logProvider);
    ref.listen(widget.tickProvider, (_, __) {
      _updateFromLog(logAsync.value);
    });

    return logAsync.when(
      data: (log) {
        _updateFromLog(log);
        final isRunning = log?.workoutStartTime != null;
        final accumulated = log?.accumulatedSeconds ?? 0;
        final startTime = log?.workoutStartTime;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: LabColors.surfaceContainerLow,
            border: Border.all(
                color: LabColors.primary.withValues(alpha: 0.3), width: 0.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.timer,
                      color: isRunning ? LabColors.primary : Colors.grey,
                      size: 16),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 100,
                    child: TextField(
                      controller: _controller,
                      enabled: !isRunning,
                      onTap: () => setState(() => _isEditing = true),
                      onSubmitted: (_) =>
                          log != null ? _saveManualTime(log) : null,
                      onChanged: (_) => _isEditing = true,
                      style: LabStyles.mono(context,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isRunning ? Colors.white : Colors.grey),
                      decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Flexible(
                child: LabButton(
                  label: isRunning
                      ? "STOP_SESSION"
                      : (accumulated == 0 ? "START_SESSION" : "RESUME"),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  onPressed: () async {
                    final db = ref.read(databaseProvider);
                    if (!isRunning) {
                      if (log == null) {
                        await db
                            .into(db.workoutLogs)
                            .insert(WorkoutLogsCompanion.insert(
                              date: DateTime.now(),
                              workoutStartTime: drift.Value(DateTime.now()),
                            ));
                      } else {
                        await (db.update(db.workoutLogs)
                              ..where((t) => t.id.equals(log.id)))
                            .write(WorkoutLogsCompanion(
                                workoutStartTime: drift.Value(DateTime.now())));
                      }
                    } else {
                      final sessionElapsed =
                          DateTime.now().difference(startTime!).inSeconds;
                      final newAccumulated = accumulated + sessionElapsed;
                      await (db.update(db.workoutLogs)
                            ..where((t) => t.id.equals(log!.id)))
                          .write(WorkoutLogsCompanion(
                        workoutStartTime: const drift.Value(null),
                        accumulatedSeconds: drift.Value(newAccumulated),
                        durationMinutes: drift.Value(newAccumulated ~/ 60),
                      ));
                    }
                  },
                  color: isRunning ? Colors.redAccent : LabColors.primary,
                  isOutlined: true,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Container(
          height: 60,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(color: LabColors.primary)),
      error: (e, s) => Text('TIMER_ERROR: $e',
          style:
              LabStyles.mono(context, color: Colors.redAccent, fontSize: 10)),
    );
  }
}

// ─── WORKOUT OPTS SLICE (data holder for opts-sheet buttons) ────────
class WorkoutOptsSlice {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const WorkoutOptsSlice({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
