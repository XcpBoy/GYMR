import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../providers/database_provider.dart';
import '../providers/theme_provider.dart';
import '../database/database.dart';
import 'styles.dart';
import 'lab_widgets.dart';
import 'main_scaffold.dart';
import 'wb_shared/wb_shared_widgets.dart';
import 'complex_metadata_screen.dart'; // NEW
import '../localization/strings.dart';

// Default color per nomenclature piece, used when the user hasn't
// customized it in THEME.MDFYR > DATA > NOMENCLATURE_COLORS.
const Map<String, Color> kNomenclaturePieceDefaults = {
  'BODY_POSITION': Colors.blueAccent,
  'IMPLEMENTS': Colors.orangeAccent,
  'PREFIXES': LabColors.primary,
  'NAME': Colors.white,
  'SUFFIXES': LabColors.primary,
  'ASSISTANCE': Colors.tealAccent,
};

// Single screen for both creating and editing a BaseExercise. `exercise ==
// null` means create mode (INSERT); a non-null exercise means edit mode
// (UPDATE on that row). EDIT_EXERCISE and EXERCISE_CREATOR used to be two
// near-identical files (same fields, same nomenclature-piece logic) that
// had to be edited in lockstep any time either changed - merged into one
// widget so there's a single place to touch.
class ExerciseFormScreen extends ConsumerStatefulWidget {
  final BaseExercise? exercise;
  const ExerciseFormScreen({super.key, this.exercise});

  @override
  ConsumerState<ExerciseFormScreen> createState() => _ExerciseFormScreenState();
}

class _ExerciseFormScreenState extends ConsumerState<ExerciseFormScreen> {
  final _formKey = GlobalKey<FormState>();

  bool get _isEditing => widget.exercise != null;

  late final TextEditingController _nameController;
  late final TextEditingController _primaryMuscleController;
  late final TextEditingController _secondaryMuscleController;
  late final TextEditingController _fieldController;
  late final TextEditingController _intentionController;
  late final TextEditingController _patternTypeController;
  late final TextEditingController _tissueTypeController;
  late final TextEditingController _tissueNameController;
  late final TextEditingController _numPhasesController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _bandTypeController;
  late final TextEditingController _bandTensionController;

  String _loadType = 'EXT.LOAD';
  bool _isIsometric = false;
  bool _isUnilateral = false;
  String _classification = 'COMPOUND';

  final List<TextEditingController> _implementControllers = [];
  final List<bool> _implementShowInName = [];
  final List<TextEditingController> _bodyPositionControllers = [];
  final List<bool> _bodyPositionShowInName = [];
  final List<TextEditingController> _prefixControllers = [];
  final List<bool> _prefixShowInName = [];
  final List<TextEditingController> _suffixControllers = [];
  final List<bool> _suffixShowInName = [];
  final List<TextEditingController> _assistanceControllers = [];
  final List<bool> _assistanceShowInName = [];
  List<String> _nameOrder = List<String>.from(kDefaultNamePieceOrder);
  List<TextEditingController> _phaseDescriptionControllers = [];

  // RELATIONS
  Map<String, dynamic> _complexMetadata = {
    "regressions": [],
    "progressions": [],
    "alters": [],
    "particular_toggles": [],
    "description": ""
  };

  // Parses a nomenclature-piece column (JSON [{"v":...,"s":...}], falling
  // back to legacy comma-text as all-shown) into a controller + show-flag
  // pair, same shape bodyPositions already used before this feature existed
  // for every piece.
  void _loadPieceInto(String? raw, List<TextEditingController> controllers,
      List<bool> showFlags) {
    controllers.clear();
    showFlags.clear();
    if (raw == null || raw.isEmpty) return;
    try {
      final List<dynamic> decoded = jsonDecode(raw);
      for (var item in decoded) {
        controllers.add(_newPieceController(item['v']));
        showFlags.add(item['s'] ?? true);
      }
    } catch (_) {
      for (var v in raw.split(',')) {
        if (v.isNotEmpty) {
          controllers.add(_newPieceController(v));
          showFlags.add(true);
        }
      }
    }
  }

  // Live-updates the NOMENCLATURE_CONTROL preview (which shows the actual
  // entered value, not a placeholder label) as the user types, since typing
  // into a TextEditingController doesn't trigger a rebuild on its own.
  TextEditingController _newPieceController([String? text]) {
    final c = TextEditingController(text: text);
    c.addListener(() {
      if (mounted) setState(() {});
    });
    return c;
  }

  String? _encodePieceList(
      List<TextEditingController> controllers, List<bool> showFlags) {
    final List<Map<String, dynamic>> data = [];
    for (int i = 0; i < controllers.length; i++) {
      final val = controllers[i].text.trim();
      if (val.isNotEmpty) data.add({"v": val.toUpperCase(), "s": showFlags[i]});
    }
    return data.isEmpty ? null : jsonEncode(data);
  }

  List<String> _extractPieceValues(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded.map((item) => item['v'].toString()).toList();
    } catch (_) {
      return raw.split(',');
    }
  }

  drift.Value<String?> _toValue(String text) {
    final trimmed = text.trim();
    return drift.Value(trimmed.isEmpty ? null : trimmed);
  }

  @override
  void initState() {
    super.initState();
    final e = widget.exercise;
    _isUnilateral = e?.isUnilateral ?? false;
    _nameController = _newPieceController(e?.name);
    _primaryMuscleController = TextEditingController(text: e?.primaryMuscleGroup);
    _secondaryMuscleController = TextEditingController(text: e?.secondaryMuscleGroup);
    _fieldController = TextEditingController(text: e?.field);
    _patternTypeController = TextEditingController(text: e?.patternType);
    _tissueTypeController = TextEditingController(text: e?.tissueType);
    _tissueNameController = TextEditingController(text: e?.tissueName);
    if (e != null) {
      _complexMetadata = Map<String, dynamic>.from(e.parsedComplexMetadata);
    }
    _classification = _complexMetadata["classification"] ?? "COMPOUND";

    final intentionText = e?.intention ?? '';
    final metaMatch = RegExp(r'\[NT:(.*)\|ISO:(.*)\]').firstMatch(intentionText);
    if (metaMatch != null) {
      _loadType = metaMatch.group(1) ?? 'EXT.LOAD';
      _isIsometric = metaMatch.group(2) == 'true';
      _intentionController = TextEditingController(text: intentionText.replaceFirst(RegExp(r'\[.*\]'), '').trim());
    } else {
      _intentionController = TextEditingController(text: intentionText);
    }

    _numPhasesController = TextEditingController(text: (e?.numPhases ?? 1).toString());
    _descriptionController = TextEditingController(text: e?.parsedComplexMetadata["description"] ?? "");
    _bandTypeController = TextEditingController(text: e?.parsedComplexMetadata["bandType"] ?? "");
    _bandTensionController = TextEditingController(text: e?.parsedComplexMetadata["bandTension"] ?? "");

    _loadPieceInto(e?.bodyPositions, _bodyPositionControllers, _bodyPositionShowInName);
    _loadPieceInto(e?.implements, _implementControllers, _implementShowInName);
    _loadPieceInto(e?.prefixes, _prefixControllers, _prefixShowInName);
    _loadPieceInto(e?.suffixes, _suffixControllers, _suffixShowInName);
    _loadPieceInto(e?.assistanceTypes, _assistanceControllers, _assistanceShowInName);
    _nameOrder = e != null ? List<String>.from(e.nameOrderResolved) : [];

    if (e != null) {
      try {
        if (e.phaseDescriptions != null) {
          final Map<String, dynamic> metadata = jsonDecode(e.phaseDescriptions!);
          final phases = metadata["phases"] as Map<String, dynamic>? ?? {};
          for (int i = 0; i < (e.numPhases ?? 1); i++) {
            _phaseDescriptionControllers.add(TextEditingController(text: phases[(i + 1).toString()] ?? ''));
          }
        }
      } catch (_) {
        _phaseDescriptionControllers = List.generate(e.numPhases ?? 1, (index) => TextEditingController());
      }
    } else {
      _phaseDescriptionControllers = [TextEditingController()];
    }

    _numPhasesController.addListener(_updatePhaseControllers);
  }

  // Keeps _phaseDescriptionControllers in sync as "Number of Phases" is
  // typed, so the matching count of phase-description fields appears
  // immediately instead of only after a save/reload round-trip.
  void _updatePhaseControllers() {
    final count = int.tryParse(_numPhasesController.text) ?? 0;
    if (count < 0) return;
    if (_phaseDescriptionControllers.length != count) {
      setState(() {
        if (_phaseDescriptionControllers.length < count) {
          for (int i = _phaseDescriptionControllers.length; i < count; i++) {
            _phaseDescriptionControllers.add(TextEditingController());
          }
        } else {
          while (_phaseDescriptionControllers.length > count) {
            _phaseDescriptionControllers.removeLast().dispose();
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose(); _primaryMuscleController.dispose(); _secondaryMuscleController.dispose();
    _fieldController.dispose(); _intentionController.dispose(); _patternTypeController.dispose();
    _tissueTypeController.dispose(); _tissueNameController.dispose(); _numPhasesController.dispose();
    _descriptionController.dispose();
    _bandTypeController.dispose(); _bandTensionController.dispose();
    for (var c in [..._prefixControllers, ..._suffixControllers, ..._implementControllers, ..._bodyPositionControllers, ..._assistanceControllers, ..._phaseDescriptionControllers]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _saveExercise() async {
    if (!_formKey.currentState!.validate()) return;
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("BASE_NAME_REQUIRED")));
      return;
    }

    final db = ref.read(databaseProvider);
    final posJson = _encodePieceList(_bodyPositionControllers, _bodyPositionShowInName);
    final impJson = _encodePieceList(_implementControllers, _implementShowInName);
    final preJson = _encodePieceList(_prefixControllers, _prefixShowInName);
    final sufJson = _encodePieceList(_suffixControllers, _suffixShowInName);
    final assistJson = _encodePieceList(_assistanceControllers, _assistanceShowInName);
    final nameOrderJson = jsonEncode(_reconcileNameOrder(_nameOrder, _liveNameTokens()));

    final Map<String, dynamic> phaseMetadata = {
      "phases": {},
      "graph": {"progresiones": [], "regresiones": [], "nivelados": []}
    };
    for (int i = 0; i < _phaseDescriptionControllers.length; i++) {
      final desc = _phaseDescriptionControllers[i].text.trim();
      if (desc.isNotEmpty) phaseMetadata["phases"][(i + 1).toString()] = desc;
    }

    final purposeText = _intentionController.text.trim();
    final finalIntention = "[NT:$_loadType|ISO:$_isIsometric] $purposeText";

    final complexMetadataJson = jsonEncode({
      ..._complexMetadata,
      "classification": _classification,
      "description": _descriptionController.text.trim(),
      if (_loadType == 'BANDED') "bandType": _bandTypeController.text.trim(),
      if (_loadType == 'BANDED') "bandTension": _bandTensionController.text.trim(),
    });

    try {
      if (_isEditing) {
        await (db.update(db.baseExercises)..where((t) => t.id.equals(widget.exercise!.id))).write(
          BaseExercisesCompanion(
            name: drift.Value(_nameController.text.trim().toUpperCase()),
            primaryMuscleGroup: drift.Value(_primaryMuscleController.text.trim().toUpperCase()),
            secondaryMuscleGroup: drift.Value(_secondaryMuscleController.text.trim().toUpperCase()),
            field: drift.Value(_fieldController.text.trim().toUpperCase()),
            intention: drift.Value(finalIntention),
            patternType: drift.Value(_patternTypeController.text.trim().toUpperCase()),
            tissueType: drift.Value(_tissueTypeController.text.trim().toUpperCase()),
            tissueName: drift.Value(_tissueNameController.text.trim().toUpperCase()),
            implements: drift.Value(impJson),
            bodyPositions: drift.Value(posJson),
            prefixes: drift.Value(preJson),
            suffixes: drift.Value(sufJson),
            assistanceTypes: drift.Value(assistJson),
            nameOrder: drift.Value(nameOrderJson),
            numPhases: drift.Value(int.tryParse(_numPhasesController.text) ?? 1),
            phaseDescriptions: drift.Value(jsonEncode(phaseMetadata)),
            complexMetadata: drift.Value(complexMetadataJson),
            isUnilateral: drift.Value(_isUnilateral),
          ),
        );
        await db.syncBidirectionalRelations(widget.exercise!.id, _complexMetadata);
      } else {
        final maxOrder = await (db.select(db.baseExercises)
              ..orderBy([(t) => drift.OrderingTerm(expression: t.orderIndex, mode: drift.OrderingMode.desc)]))
            .get()
            .then((r) => r.isEmpty ? 0 : (r.first.orderIndex + 1));

        final insertedId = await db.into(db.baseExercises).insert(
          BaseExercisesCompanion.insert(
            name: _nameController.text.trim().toUpperCase(),
            primaryMuscleGroup: _toValue(_primaryMuscleController.text.toUpperCase()),
            secondaryMuscleGroup: _toValue(_secondaryMuscleController.text.toUpperCase()),
            field: _toValue(_fieldController.text.trim().toUpperCase()),
            tissueType: _toValue(_tissueTypeController.text.toUpperCase()),
            tissueName: _toValue(_tissueNameController.text.trim().toUpperCase()),
            intention: drift.Value(finalIntention),
            patternType: _toValue(_patternTypeController.text.toUpperCase()),
            implements: drift.Value(impJson),
            bodyPositions: drift.Value(posJson),
            prefixes: drift.Value(preJson),
            suffixes: drift.Value(sufJson),
            assistanceTypes: drift.Value(assistJson),
            nameOrder: drift.Value(nameOrderJson),
            numPhases: drift.Value(int.tryParse(_numPhasesController.text) ?? 1),
            phaseDescriptions: drift.Value(jsonEncode(phaseMetadata)),
            complexMetadata: drift.Value(complexMetadataJson),
            isUnilateral: drift.Value(_isUnilateral),
            orderIndex: drift.Value(maxOrder),
          ),
        );
        await db.syncBidirectionalRelations(insertedId, _complexMetadata);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("Save Failed: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("SAVE_FAILED: $e")));
      }
    }
  }

  void _showCopyPicker() async {
    final db = ref.read(databaseProvider);
    final all = await db.select(db.baseExercises).get();
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: LabColors.background,
      isScrollControlled: true,
      builder: (c) => ExerciseSearchPicker(
        exercises: all,
        onSelected: (e) => setState(() => _applyCopy(e)),
      ),
    );
  }

  void _applyCopy(BaseExercise e) {
    _nameController.text = e.name;
    _primaryMuscleController.text = e.primaryMuscleGroup ?? '';
    _secondaryMuscleController.text = e.secondaryMuscleGroup ?? '';
    _fieldController.text = e.field ?? '';
    _tissueTypeController.text = e.tissueType ?? '';
    _tissueNameController.text = e.tissueName ?? '';
    _patternTypeController.text = e.patternType ?? '';
    _numPhasesController.text = (e.numPhases ?? 1).toString();
    _complexMetadata = jsonDecode(jsonEncode(e.parsedComplexMetadata));
    _classification = _complexMetadata["classification"] ?? "COMPOUND";
    _isUnilateral = e.isUnilateral;

    final intentionText = e.intention ?? '';
    final metaMatch = RegExp(r'\[NT:(.*)\|ISO:(.*)\]').firstMatch(intentionText);
    if (metaMatch != null) {
      _loadType = metaMatch.group(1) ?? 'EXT.LOAD';
      _isIsometric = metaMatch.group(2) == 'true';
      _intentionController.text = intentionText.replaceFirst(RegExp(r'\[.*\]'), '').trim();
    } else {
      _intentionController.text = intentionText;
    }

    _loadPieceInto(e.bodyPositions, _bodyPositionControllers, _bodyPositionShowInName);
    _loadPieceInto(e.implements, _implementControllers, _implementShowInName);
    _loadPieceInto(e.prefixes, _prefixControllers, _prefixShowInName);
    _loadPieceInto(e.suffixes, _suffixControllers, _suffixShowInName);
    _loadPieceInto(e.assistanceTypes, _assistanceControllers, _assistanceShowInName);
    _nameOrder = List<String>.from(e.nameOrderResolved);

    _phaseDescriptionControllers.clear();
    if (e.phaseDescriptions != null) {
      try {
        final Map<String, dynamic> metadata = jsonDecode(e.phaseDescriptions!);
        final phases = metadata["phases"] as Map<String, dynamic>? ?? {};
        final phaseCount = e.numPhases ?? 1;
        for (int i = 0; i < phaseCount; i++) {
          _phaseDescriptionControllers.add(TextEditingController(text: phases[(i + 1).toString()] ?? ''));
        }
      } catch (_) {
        _phaseDescriptionControllers = List.generate(e.numPhases ?? 1, (index) => TextEditingController());
      }
    } else {
      _phaseDescriptionControllers = List.generate(e.numPhases ?? 1, (index) => TextEditingController());
    }
  }

  void _showQualityOverlay(TextEditingController? controller, String type, {Function(String)? onSelect}) async {
    final db = ref.read(databaseProvider);
    final exercises = await db.select(db.baseExercises).get();

    Set<String> values = {};
    for (var e in exercises) {
      List<String> found = [];
      if (type == 'field') {
        found = [e.field ?? ''];
      } else if (type == 'muscle') {
        found = [e.primaryMuscleGroup ?? '', e.secondaryMuscleGroup ?? ''];
      } else if (type == 'pattern') {
        found = [e.patternType ?? ''];
      } else if (type == 'bodyPosition') {
        found = _extractPieceValues(e.bodyPositions);
      } else if (type == 'implement') {
        found = _extractPieceValues(e.implements);
      } else if (type == 'prefix') {
        found = _extractPieceValues(e.prefixes);
      } else if (type == 'suffix') {
        found = _extractPieceValues(e.suffixes);
      } else if (type == 'assistance') {
        found = _extractPieceValues(e.assistanceTypes);
      } else if (type == 'tissueType') {
        found = [e.tissueType ?? ''];
      } else if (type == 'tissueName') {
        found = [e.tissueName ?? ''];
      } else if (type == 'name') {
        found = [e.name];
      } else if (type == 'purpose') {
        final intentionText = e.intention ?? '';
        final stripped = intentionText.replaceFirst(RegExp(r'\[.*\]'), '').trim();
        found = [stripped];
      } else if (type == 'phase') {
        if (e.phaseDescriptions != null) {
          try {
            final Map<String, dynamic> meta = jsonDecode(e.phaseDescriptions!);
            final phases = meta["phases"] as Map<String, dynamic>? ?? {};
            found = phases.values.map((v) => v.toString()).toList();
          } catch (_) {}
        }
      }

      for (var v in found) {
        if (v.trim().isNotEmpty) values.add(v.trim());
      }
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: LabColors.background,
      isScrollControlled: true,
      builder: (c) => QualitySearchPicker(
        title: "EXISTING_QUALITIES",
        values: values.toList()..sort(),
        onSelected: (v) {
          if (onSelect != null) {
            onSelect(v);
          } else if (controller != null) {
            setState(() => controller.text = v);
          }
        },
      ),
    );
  }

  void _showComplexMetadataInput() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (c) => ComplexMetadataScreen(
          initialMetadata: _complexMetadata,
          exerciseName: _nameController.text,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _complexMetadata = result as Map<String, dynamic>;
      });
    }
  }

  Widget _buildSearchableField(String label, TextEditingController controller, String type) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: LabTextField(controller: controller, label: label)),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.manage_search, color: LabColors.primary),
          onPressed: () => _showQualityOverlay(controller, type),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider).value ?? 'en';
    final settings = ref.watch(themeSettingsProvider).value ?? <String, ThemeSetting>{};
    final tC = ref.read(themeControllerProvider);
    final showSecondaryMuscle = tC.getBool(settings, 'APPCFG_SHOW_SECONDARY_MUSCLE', defaultValue: true);
    final showPatternType = tC.getBool(settings, 'APPCFG_SHOW_PATTERN_TYPE', defaultValue: true);
    final showPurpose = tC.getBool(settings, 'APPCFG_SHOW_PURPOSE', defaultValue: true);
    final showTissueType = tC.getBool(settings, 'APPCFG_SHOW_TISSUE_TYPE', defaultValue: true);
    final showTissueName = tC.getBool(settings, 'APPCFG_SHOW_TISSUE_NAME', defaultValue: true);
    final showPhases = tC.getBool(settings, 'APPCFG_SHOW_PHASES', defaultValue: true);
    return MainScaffold(
      title: _isEditing ? 'EDIT_EXERCISE' : 'EXERCISE_CREATOR',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('CORE_IDENTIFICATION'),
              const SizedBox(height: 16),
              _buildSearchableField(tr(lang, 'BASE NAME (E.G : VERTICAL PULL)'), _nameController, 'name'),
              const SizedBox(height: 12),
              LabButton(
                label: tr(lang, 'Copy Existing Movement'),
                onPressed: _showCopyPicker,
                color: LabColors.tertiary,
                isOutlined: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              const SizedBox(height: 12),
              LabButton(
                label: tr(lang, 'Complex Metadata Input'),
                onPressed: _showComplexMetadataInput,
                color: LabColors.primary,
                isOutlined: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              const SizedBox(height: 16),
              _buildSearchableField(tr(lang, 'Field / Discipline'), _fieldController, 'field'),
              const SizedBox(height: 16),
              LabTextField(
                controller: _descriptionController,
                label: tr(lang, 'Technical Description / Notes'),
                maxLines: 3,
                keyboardType: TextInputType.multiline,
              ),

              const SizedBox(height: 24),
              _buildSectionTitle('QUALITIES'),
              const SizedBox(height: 16),
              _buildToggleableList('BODY_POSITION', _bodyPositionControllers, _bodyPositionShowInName,
                  () => setState(() { _bodyPositionControllers.add(_newPieceController()); _bodyPositionShowInName.add(true); }),
                  type: 'bodyPosition', color: Colors.blueAccent),
              const SizedBox(height: 16),
              _buildToggleableList('IMPLEMENTS', _implementControllers, _implementShowInName,
                  () => setState(() { _implementControllers.add(_newPieceController()); _implementShowInName.add(true); }),
                  type: 'implement', color: Colors.orangeAccent),
              const SizedBox(height: 16),
              _buildToggleableList('PREFIXES', _prefixControllers, _prefixShowInName,
                  () => setState(() { _prefixControllers.add(_newPieceController()); _prefixShowInName.add(true); }),
                  type: 'prefix', color: LabColors.primary),
              const SizedBox(height: 16),
              _buildToggleableList('SUFFIXES', _suffixControllers, _suffixShowInName,
                  () => setState(() { _suffixControllers.add(_newPieceController()); _suffixShowInName.add(true); }),
                  type: 'suffix', color: LabColors.primary),
              const SizedBox(height: 16),
              _buildToggleableList('ASSISTANCE_TYPE', _assistanceControllers, _assistanceShowInName,
                  () => setState(() { _assistanceControllers.add(_newPieceController()); _assistanceShowInName.add(true); }),
                  type: 'assistance', color: Colors.tealAccent),

              const SizedBox(height: 32),
              _buildSectionTitle('NOMENCLATURE_CONTROL'),
              const SizedBox(height: 16),
              _buildNomenclatureControl(settings, tC),

              const SizedBox(height: 32),
              _buildSectionTitle('LOAD_METRICS'),
              const SizedBox(height: 16),
              _buildClassificationSelector(),
              const SizedBox(height: 16),
              _buildLoadTypeSelector(),
              const SizedBox(height: 16),
              _buildIsometricToggle(),
              const SizedBox(height: 8),
              _buildUnilateralToggle(),

              const SizedBox(height: 32),
              _buildSectionTitle('TARGETING'),
              const SizedBox(height: 16),
              _buildSearchableField(tr(lang, 'Primary Muscle'), _primaryMuscleController, 'muscle'),
              if (showSecondaryMuscle) ...[
                const SizedBox(height: 16),
                _buildSearchableField(tr(lang, 'Secondary Muscle'), _secondaryMuscleController, 'muscle'),
              ],

              if (showPatternType || showPurpose) ...[
                const SizedBox(height: 32),
                if (showPatternType) _buildSearchableField(tr(lang, 'Pattern Type'), _patternTypeController, 'pattern'),
                if (showPatternType && showPurpose) const SizedBox(height: 16),
                if (showPurpose) _buildSearchableField(tr(lang, 'Purpose / Intention'), _intentionController, 'purpose'),
              ],

              if (showTissueType || showTissueName) ...[
                const SizedBox(height: 32),
                _buildSectionTitle('BIOMECHANICAL_TISSUE'),
                const SizedBox(height: 16),
                if (showTissueType) _buildSearchableField(tr(lang, 'Type of Tissue'), _tissueTypeController, 'tissueType'),
                if (showTissueType && showTissueName) const SizedBox(height: 16),
                if (showTissueName) _buildSearchableField(tr(lang, 'Name of Tissue'), _tissueNameController, 'tissueName'),
              ],

              if (showPhases) ...[
                const SizedBox(height: 32),
                _buildSectionTitle('PHASES'),
                const SizedBox(height: 16),
                LabTextField(controller: _numPhasesController, label: tr(lang, 'Number of Phases')),
                const SizedBox(height: 16),
                ..._phaseDescriptionControllers.asMap().entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildSearchableField('${tr(lang, 'Phase')} ${entry.key + 1}', entry.value, 'phase')
                )),
              ],

              const SizedBox(height: 40),
              LabButton(
                label: tr(lang, _isEditing ? 'Update Movement' : 'Add Movement'),
                onPressed: _saveExercise,
                color: LabColors.accent,
              ),
              if (_isEditing) ...[
                const SizedBox(height: 12),
                LabButton(label: tr(lang, 'Abort'), onPressed: () => Navigator.pop(context), isOutlined: true, color: Colors.redAccent),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(children: [Container(width: 4, height: 24, color: LabColors.accent), const SizedBox(width: 8), Text(title, style: LabStyles.mono(context, color: LabColors.onSurface, fontWeight: FontWeight.bold).copyWith(fontSize: 14))]);
  }

  static const List<String> _loadTypes = ['LASTRE', 'EXT.LOAD', 'JST.BW', 'BANDED', 'UNMOVABLE'];

  Widget _buildLoadTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('NAT.LOAD', style: LabStyles.mono(context, color: LabColors.primary.withValues(alpha: 0.7), fontSize: 9)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _loadTypes.map((type) {
            final sel = _loadType == type;
            return InkWell(
              onTap: () => setState(() => _loadType = type),
              child: Container(
                constraints: const BoxConstraints(minWidth: 92),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: sel ? LabColors.primary : Colors.transparent,
                  border: Border.all(color: LabColors.primary, width: 0.5),
                ),
                child: Text(type,
                    style: LabStyles.mono(context,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: sel ? Colors.black : LabColors.primary)),
              ),
            );
          }).toList(),
        ),
        if (_loadType == 'BANDED') ...[
          const SizedBox(height: 16),
          _buildBandConfigFields(),
        ],
      ],
    );
  }

  Widget _buildBandConfigFields() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LabColors.surfaceDim,
        border: Border.all(color: LabColors.primary.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('BAND_CONFIG', style: LabStyles.mono(context, fontSize: 8, color: Colors.grey)),
          const SizedBox(height: 8),
          LabTextField(controller: _bandTypeController, label: 'BAND_TYPE (E.G: LOOP, TUBE)'),
          const SizedBox(height: 12),
          LabTextField(controller: _bandTensionController, label: 'TENSION_NOTES (E.G: LIGHT/MEDIUM/HEAVY)'),
        ],
      ),
    );
  }

  Widget _buildIsometricToggle() {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('ISOMETRIC_MODE', style: LabStyles.mono(context, fontSize: 12)), Switch.adaptive(value: _isIsometric, activeColor: LabColors.primary, onChanged: (v) => setState(() => _isIsometric = v))]);
  }

  Widget _buildUnilateralToggle() {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('UNILATERAL', style: LabStyles.mono(context, fontSize: 12)), Switch.adaptive(value: _isUnilateral, activeColor: LabColors.primary, onChanged: (v) => setState(() => _isUnilateral = v))]);
  }

  Widget _buildClassificationSelector() {
    return Row(children: ['COMPOUND', 'ISOLATION'].map((type) {
      final sel = _classification == type;
      return Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: InkWell(onTap: () => setState(() => _classification = type), child: Container(padding: const EdgeInsets.symmetric(vertical: 12), alignment: Alignment.center, decoration: BoxDecoration(color: sel ? LabColors.accent : Colors.transparent, border: Border.all(color: LabColors.accent, width: 0.5)), child: Text(type, style: LabStyles.mono(context, fontSize: 10, fontWeight: FontWeight.bold, color: sel ? Colors.black : LabColors.accent))))));
    }).toList());
  }

  // Generalized version of the old body-position-only list: an "add via
  // search" + "add blank" header, and a per-item NAME switch that controls
  // whether that piece is included when fullName is assembled (see
  // BaseExercise.fullName in database.dart). Used for BODY_POSITION,
  // IMPLEMENTS, PREFIXES, SUFFIXES and ASSISTANCE_TYPE alike.
  Widget _buildToggleableList(String title, List<TextEditingController> controllers,
      List<bool> showInName, VoidCallback onAdd,
      {required String type, Color color = LabColors.primary}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(title, style: LabStyles.mono(context, color: color.withValues(alpha: 0.7), fontSize: 9)),
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.manage_search, color: color, size: 18),
              onPressed: () => _showQualityOverlay(null, type, onSelect: (v) => setState(() {
                controllers.add(_newPieceController(v));
                showInName.add(true);
              }))
            ),
            IconButton(icon: Icon(Icons.add_circle_outline, color: color, size: 18), onPressed: onAdd),
          ],
        )
      ]),
      ...controllers.asMap().entries.map((entry) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
        Expanded(child: LabTextField(controller: entry.value, label: '$title #${entry.key + 1}')),
        const SizedBox(width: 8),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Text('NAME', style: LabStyles.mono(context, fontSize: 6, color: showInName[entry.key] ? LabColors.primary : Colors.grey)),
          Switch.adaptive(
            value: showInName[entry.key],
            activeColor: LabColors.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: (v) => setState(() => showInName[entry.key] = v)
          ),
        ]),
        IconButton(icon: const Icon(Icons.close, color: Colors.redAccent, size: 18), onPressed: () => setState(() {
          controllers.removeAt(entry.key).dispose();
          showInName.removeAt(entry.key);
        }))
      ])))
    ]);
  }

  // Every individual string across every piece gets its own reorder token
  // "<PIECE>::<indexWithinThatPiece'sControllerList>" - mirrors
  // BaseExerciseExtension._liveNameTokens in database.dart exactly, but
  // reads live controller/switch state instead of saved JSON, since this
  // runs while the user is still editing.
  List<String> _liveNameTokens() {
    final tokens = <String>[];
    void addTokens(String piece, List<TextEditingController> ctrls, List<bool> show) {
      for (int i = 0; i < ctrls.length; i++) {
        if (i < show.length && show[i] && ctrls[i].text.trim().isNotEmpty) {
          tokens.add('$piece::$i');
        }
      }
    }
    for (final piece in kDefaultNamePieceOrder) {
      switch (piece) {
        case 'NAME':
          if (_nameController.text.trim().isNotEmpty) tokens.add('NAME::0');
          break;
        case 'BODY_POSITION':
          addTokens('BODY_POSITION', _bodyPositionControllers, _bodyPositionShowInName);
          break;
        case 'IMPLEMENTS':
          addTokens('IMPLEMENTS', _implementControllers, _implementShowInName);
          break;
        case 'PREFIXES':
          addTokens('PREFIXES', _prefixControllers, _prefixShowInName);
          break;
        case 'SUFFIXES':
          addTokens('SUFFIXES', _suffixControllers, _suffixShowInName);
          break;
        case 'ASSISTANCE':
          addTokens('ASSISTANCE', _assistanceControllers, _assistanceShowInName);
          break;
      }
    }
    return tokens;
  }

  // Reconciles a stored token order against the current live token set:
  // stale tokens (removed/toggled off since saved) are dropped, new tokens
  // (added since) are appended in default order. Mirrors
  // BaseExerciseExtension.nameOrderResolved.
  List<String> _reconcileNameOrder(List<String> stored, List<String> live) {
    final liveSet = live.toSet();
    final storedSet = stored.toSet();
    final result = <String>[];
    for (final t in stored) {
      if (liveSet.contains(t)) result.add(t);
    }
    for (final t in live) {
      if (!storedSet.contains(t)) result.add(t);
    }
    return result;
  }

  String _tokenPiece(String token) => token.split('::')[0];
  int _tokenIndex(String token) => int.parse(token.split('::')[1]);

  String _tokenText(String token) {
    final piece = _tokenPiece(token);
    final idx = _tokenIndex(token);
    List<TextEditingController>? ctrls;
    switch (piece) {
      case 'NAME':
        return _nameController.text.trim();
      case 'BODY_POSITION':
        ctrls = _bodyPositionControllers;
        break;
      case 'IMPLEMENTS':
        ctrls = _implementControllers;
        break;
      case 'PREFIXES':
        ctrls = _prefixControllers;
        break;
      case 'SUFFIXES':
        ctrls = _suffixControllers;
        break;
      case 'ASSISTANCE':
        ctrls = _assistanceControllers;
        break;
    }
    if (ctrls == null || idx >= ctrls.length) return '';
    return ctrls[idx].text.trim();
  }

  Widget _buildNomenclatureControl(Map<String, ThemeSetting> settings, ThemeController tC) {
    final order = _reconcileNameOrder(_nameOrder, _liveNameTokens());
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('DRAG_TO_REORDER_NAME_STRINGS', style: LabStyles.mono(context, fontSize: 7, color: Colors.grey[600])),
        IconButton(
          icon: Icon(Icons.restart_alt, color: Colors.grey[400], size: 18),
          tooltip: 'RESET_DEFAULT_ORDER',
          onPressed: () => setState(() => _nameOrder = []),
        ),
      ]),
      const SizedBox(height: 4),
      if (order.isEmpty)
        Text('NOTHING_TO_REORDER_YET', style: LabStyles.mono(context, fontSize: 8, color: Colors.grey[700])),
      ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        buildDefaultDragHandles: false,
        itemCount: order.length,
        itemBuilder: (context, index) {
          final token = order[index];
          final piece = _tokenPiece(token);
          final color = tC.getColor(settings, 'NOMENCLATURE_$piece',
              defaultColor: kNomenclaturePieceDefaults[piece] ?? LabColors.primary,
              nameSeed: piece);
          return Container(
            key: ValueKey('nameorder_$token'),
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              border: Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
            ),
            child: Row(children: [
              Text('${index + 1}.', style: LabStyles.mono(context, fontSize: 10, color: color, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(_tokenText(token).toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: LabStyles.mono(context, fontSize: 10, color: color, fontWeight: FontWeight.bold)),
              ),
              ReorderableDragStartListener(index: index, child: Icon(Icons.drag_handle, color: color.withValues(alpha: 0.6), size: 18)),
            ]),
          );
        },
        onReorder: (oldIndex, newIndex) => setState(() {
          final dragged = order[oldIndex];
          if (newIndex > oldIndex) newIndex--;
          final reordered = List<String>.from(order);
          reordered.removeAt(oldIndex);
          reordered.insert(newIndex, dragged);
          _nameOrder = reordered;
        }),
      ),
    ]);
  }
}
