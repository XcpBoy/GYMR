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

class EditExerciseScreen extends ConsumerStatefulWidget {
  final BaseExercise exercise;
  const EditExerciseScreen({super.key, required this.exercise});

  @override
  ConsumerState<EditExerciseScreen> createState() => _EditExerciseScreenState();
}

class _EditExerciseScreenState extends ConsumerState<EditExerciseScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _primaryMuscleController;
  late TextEditingController _secondaryMuscleController;
  late TextEditingController _fieldController;
  late TextEditingController _intentionController;
  late TextEditingController _patternTypeController;
  late TextEditingController _tissueTypeController;
  late TextEditingController _tissueNameController;
  late TextEditingController _numPhasesController;
  late TextEditingController _descriptionController;
  late TextEditingController _vpMultiplierController;

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
  
  // RELATIONS
  Map<String, dynamic> _complexMetadata = {"regressions": [], "progressions": [], "alters": [], "particular_toggles": []};

  @override
  void initState() {
    super.initState();
    final e = widget.exercise;
    _isUnilateral = e.isUnilateral;
    _nameController = _newPieceController(e.name);
    _primaryMuscleController = TextEditingController(text: e.primaryMuscleGroup);
    _secondaryMuscleController = TextEditingController(text: e.secondaryMuscleGroup);
    _fieldController = TextEditingController(text: e.field);
    _patternTypeController = TextEditingController(text: e.patternType);
    _tissueTypeController = TextEditingController(text: e.tissueType);
    _tissueNameController = TextEditingController(text: e.tissueName);
    _complexMetadata = Map<String, dynamic>.from(e.parsedComplexMetadata);
    _classification = _complexMetadata["classification"] ?? "COMPOUND";
    
    final intentionText = e.intention ?? '';
    final metaMatch = RegExp(r'\[NT:(.*)\|ISO:(.*)\]').firstMatch(intentionText);
    if (metaMatch != null) {
      _loadType = metaMatch.group(1) ?? 'EXT.LOAD';
      _isIsometric = metaMatch.group(2) == 'true';
      _intentionController = TextEditingController(text: intentionText.replaceFirst(RegExp(r'\[.*\]'), '').trim());
    } else {
      _intentionController = TextEditingController(text: intentionText);
    }

    _numPhasesController = TextEditingController(text: (e.numPhases ?? 1).toString());
    _descriptionController = TextEditingController(text: e.parsedComplexMetadata["description"] ?? "");
    _vpMultiplierController = TextEditingController(
        text: (e.parsedComplexMetadata["vpMultiplier"] as num?)?.toString() ?? "1.0");

    _loadPieceInto(e.bodyPositions, _bodyPositionControllers, _bodyPositionShowInName);
    _loadPieceInto(e.implements, _implementControllers, _implementShowInName);
    _loadPieceInto(e.prefixes, _prefixControllers, _prefixShowInName);
    _loadPieceInto(e.suffixes, _suffixControllers, _suffixShowInName);
    _loadPieceInto(e.assistanceTypes, _assistanceControllers, _assistanceShowInName);
    _nameOrder = List<String>.from(e.nameOrderResolved);

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
  }

  @override
  void dispose() {
    _nameController.dispose(); _primaryMuscleController.dispose(); _secondaryMuscleController.dispose();
    _fieldController.dispose(); _intentionController.dispose(); _patternTypeController.dispose();
    _tissueTypeController.dispose(); _tissueNameController.dispose(); _numPhasesController.dispose();
    _vpMultiplierController.dispose();
    for (var c in [..._prefixControllers, ..._suffixControllers, ..._implementControllers, ..._bodyPositionControllers, ..._assistanceControllers, ..._phaseDescriptionControllers]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _updateExercise() async {
    if (_formKey.currentState!.validate()) {
      final db = ref.read(databaseProvider);
      
      final posJson = _encodePieceList(_bodyPositionControllers, _bodyPositionShowInName);
      final impJson = _encodePieceList(_implementControllers, _implementShowInName);
      final preJson = _encodePieceList(_prefixControllers, _prefixShowInName);
      final sufJson = _encodePieceList(_suffixControllers, _suffixShowInName);
      final assistJson = _encodePieceList(_assistanceControllers, _assistanceShowInName);

      final Map<String, dynamic> metadata = {
        "phases": {},
        "graph": {"progresiones": [], "regresiones": [], "nivelados": []}
      };
      for (int i = 0; i < _phaseDescriptionControllers.length; i++) {
        final desc = _phaseDescriptionControllers[i].text.trim();
        if (desc.isNotEmpty) metadata["phases"][(i + 1).toString()] = desc;
      }

      final finalIntention = "[NT:$_loadType|ISO:$_isIsometric] ${_intentionController.text.trim()}";

      await (db.update(db.baseExercises)..where((t) => t.id.equals(widget.exercise.id))).write(
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
          nameOrder: drift.Value(jsonEncode(_nameOrder)),
          numPhases: drift.Value(int.tryParse(_numPhasesController.text) ?? 1),
          phaseDescriptions: drift.Value(jsonEncode(metadata)),
          complexMetadata: drift.Value(jsonEncode({..._complexMetadata, "classification": _classification, "description": _descriptionController.text.trim(), "vpMultiplier": double.tryParse(_vpMultiplierController.text) ?? 1.0})),
          isUnilateral: drift.Value(_isUnilateral),
        ),
      );

      await db.syncBidirectionalRelations(widget.exercise.id, _complexMetadata);

      if (mounted) Navigator.pop(context);
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
      }
      else if (type == 'phase') {
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
    return MainScaffold(
      title: 'EDIT_EXERCISE',
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
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                    child: LabTextField(
                        controller: _vpMultiplierController,
                        label: tr(lang, 'VP MULTIPLIER'),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true))),
              ]),

              const SizedBox(height: 32),
              _buildSectionTitle('TARGETING'),
              const SizedBox(height: 16),
              _buildSearchableField(tr(lang, 'Primary Muscle'), _primaryMuscleController, 'muscle'),
              const SizedBox(height: 16),
              _buildSearchableField(tr(lang, 'Secondary Muscle'), _secondaryMuscleController, 'muscle'),

              const SizedBox(height: 32),
              _buildSearchableField(tr(lang, 'Pattern Type'), _patternTypeController, 'pattern'),
              const SizedBox(height: 16),
              _buildSearchableField(tr(lang, 'Purpose / Intention'), _intentionController, 'purpose'),

              const SizedBox(height: 32),
              _buildSectionTitle('BIOMECHANICAL_TISSUE'),
              const SizedBox(height: 16),
              _buildSearchableField(tr(lang, 'Type of Tissue'), _tissueTypeController, 'tissueType'),
              const SizedBox(height: 16),
              _buildSearchableField(tr(lang, 'Name of Tissue'), _tissueNameController, 'tissueName'),

              const SizedBox(height: 32),
              _buildSectionTitle('PHASES'),
              const SizedBox(height: 16),
              LabTextField(controller: _numPhasesController, label: tr(lang, 'Number of Phases')),
              const SizedBox(height: 16),
              ..._phaseDescriptionControllers.asMap().entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildSearchableField('${tr(lang, 'Phase')} ${entry.key + 1}', entry.value, 'phase')
              )),

              const SizedBox(height: 40),
              LabButton(label: tr(lang, 'Update Movement'), onPressed: _updateExercise, color: LabColors.accent),
              const SizedBox(height: 12),
              LabButton(label: tr(lang, 'Abort'), onPressed: () => Navigator.pop(context), isOutlined: true, color: Colors.redAccent),
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

  Widget _buildLoadTypeSelector() {
    return Row(children: ['LASTRE', 'EXT.LOAD', 'JST.BW', 'UNMOVABLE'].map((type) {
      final sel = _loadType == type;
      return Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: InkWell(onTap: () => setState(() => _loadType = type), child: Container(padding: const EdgeInsets.symmetric(vertical: 12), alignment: Alignment.center, decoration: BoxDecoration(color: sel ? LabColors.primary : Colors.transparent, border: Border.all(color: LabColors.primary, width: 0.5)), child: Text(type, style: LabStyles.mono(context, fontSize: 10, fontWeight: FontWeight.bold, color: sel ? Colors.black : LabColors.primary))))));
    }).toList());
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

  // Lets the user drag-reorder the pieces fullName assembles from, per
  // exercise. Defaults to kDefaultNamePieceOrder (see database.dart) until
  // touched.
  // Individual "shown in name" item values in [controllers] (one entry per
  // item, NOT joined into a single string - a piece can hold an arbitrary
  // number of strings, e.g. BODY_POSITION "HIGH" + "WIDE GRIP", and each
  // should render as its own line).
  List<String> _activePieceValues(List<TextEditingController> controllers, List<bool> showFlags) {
    final parts = <String>[];
    for (int i = 0; i < controllers.length; i++) {
      if (i < showFlags.length && showFlags[i]) {
        final t = controllers[i].text.trim();
        if (t.isNotEmpty) parts.add(t);
      }
    }
    return parts;
  }

  List<String> _pieceDisplayValues(String key) {
    switch (key) {
      case 'NAME':
        final t = _nameController.text.trim();
        return t.isEmpty ? const [] : [t];
      case 'BODY_POSITION':
        return _activePieceValues(_bodyPositionControllers, _bodyPositionShowInName);
      case 'IMPLEMENTS':
        return _activePieceValues(_implementControllers, _implementShowInName);
      case 'PREFIXES':
        return _activePieceValues(_prefixControllers, _prefixShowInName);
      case 'SUFFIXES':
        return _activePieceValues(_suffixControllers, _suffixShowInName);
      case 'ASSISTANCE':
        return _activePieceValues(_assistanceControllers, _assistanceShowInName);
      default:
        return const [];
    }
  }

  Widget _buildNomenclatureControl(Map<String, ThemeSetting> settings, ThemeController tC) {
    // Only pieces that actually have something to show in the assembled
    // name are worth reordering - an empty piece has nothing to move.
    final visiblePieces = _nameOrder.where((k) => _pieceDisplayValues(k).isNotEmpty).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('DRAG_TO_REORDER_NAME_PIECES', style: LabStyles.mono(context, fontSize: 7, color: Colors.grey[600])),
        IconButton(
          icon: Icon(Icons.restart_alt, color: Colors.grey[400], size: 18),
          tooltip: 'RESET_DEFAULT_ORDER',
          onPressed: () => setState(() => _nameOrder = List<String>.from(kDefaultNamePieceOrder)),
        ),
      ]),
      const SizedBox(height: 4),
      if (visiblePieces.isEmpty)
        Text('NOTHING_TO_REORDER_YET', style: LabStyles.mono(context, fontSize: 8, color: Colors.grey[700])),
      ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        buildDefaultDragHandles: false,
        itemCount: visiblePieces.length,
        itemBuilder: (context, index) {
          final piece = visiblePieces[index];
          final color = tC.getColor(settings, 'NOMENCLATURE_$piece',
              defaultColor: kNomenclaturePieceDefaults[piece] ?? LabColors.primary,
              nameSeed: piece);
          return Container(
            key: ValueKey('nameorder_$piece'),
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              border: Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${index + 1}.', style: LabStyles.mono(context, fontSize: 10, color: color, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: _pieceDisplayValues(piece)
                      .map((v) => Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(v.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: LabStyles.mono(context, fontSize: 10, color: color, fontWeight: FontWeight.bold)),
                          ))
                      .toList(),
                ),
              ),
              ReorderableDragStartListener(index: index, child: Icon(Icons.drag_handle, color: color.withValues(alpha: 0.6), size: 18)),
            ]),
          );
        },
        onReorder: (oldIndex, newIndex) => setState(() {
          final draggedKey = visiblePieces[oldIndex];
          if (newIndex > oldIndex) newIndex--;
          _nameOrder.remove(draggedKey);
          final remainingVisible = _nameOrder.where((k) => _pieceDisplayValues(k).isNotEmpty).toList();
          if (newIndex >= remainingVisible.length) {
            _nameOrder.add(draggedKey);
          } else {
            final anchorKey = remainingVisible[newIndex];
            _nameOrder.insert(_nameOrder.indexOf(anchorKey), draggedKey);
          }
        }),
      ),
    ]);
  }
}

