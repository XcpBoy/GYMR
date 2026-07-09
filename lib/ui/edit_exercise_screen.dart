import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../providers/database_provider.dart';
import '../database/database.dart';
import 'styles.dart';
import 'lab_widgets.dart';
import 'main_scaffold.dart';
import 'wb_shared/wb_shared_widgets.dart';
import 'complex_metadata_screen.dart'; // NEW

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
  final List<TextEditingController> _bodyPositionControllers = [];
  final List<bool> _bodyPositionShowInName = [];
  final List<TextEditingController> _prefixControllers = [];
  final List<TextEditingController> _suffixControllers = [];
  List<TextEditingController> _phaseDescriptionControllers = [];
  
  // RELATIONS
  Map<String, dynamic> _complexMetadata = {"regressions": [], "progressions": [], "alters": [], "particular_toggles": []};

  @override
  void initState() {
    super.initState();
    final e = widget.exercise;
    _isUnilateral = e.isUnilateral;
    _nameController = TextEditingController(text: e.name);
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

    final rawImplements = e.implements?.split(',') ?? [];
    for (var i in rawImplements) {
      if (i.isNotEmpty) _implementControllers.add(TextEditingController(text: i));
    }

    if (e.bodyPositions != null && e.bodyPositions!.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(e.bodyPositions!);
        for (var item in decoded) {
           _bodyPositionControllers.add(TextEditingController(text: item['v']));
           _bodyPositionShowInName.add(item['s'] ?? true);
        }
      } catch (_) {
        final rawBodyPositions = e.bodyPositions!.split(',');
        for (var b in rawBodyPositions) {
          if (b.isNotEmpty) {
            _bodyPositionControllers.add(TextEditingController(text: b));
            _bodyPositionShowInName.add(true);
          }
        }
      }
    }

    final rawPrefixes = e.prefixes?.split(',') ?? [];
    for (var p in rawPrefixes) {
      if (p.isNotEmpty) _prefixControllers.add(TextEditingController(text: p));
    }

    final rawSuffixes = e.suffixes?.split(',') ?? [];
    for (var s in rawSuffixes) {
      if (s.isNotEmpty) _suffixControllers.add(TextEditingController(text: s));
    }

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
    for (var c in [..._prefixControllers, ..._suffixControllers, ..._implementControllers, ..._bodyPositionControllers, ..._phaseDescriptionControllers]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _updateExercise() async {
    if (_formKey.currentState!.validate()) {
      final db = ref.read(databaseProvider);
      
      final imps = _implementControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).join(',');
      
      final List<Map<String, dynamic>> posData = [];
      for (int i = 0; i < _bodyPositionControllers.length; i++) {
        final val = _bodyPositionControllers[i].text.trim();
        if (val.isNotEmpty) {
          posData.add({"v": val.toUpperCase(), "s": _bodyPositionShowInName[i]});
        }
      }
      final posJson = posData.isEmpty ? null : jsonEncode(posData);

      final standardPrefixes = _prefixControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).join(',');
      final suffixes = _suffixControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).join(',');
      
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
          implements: drift.Value(imps.isEmpty ? null : imps.toUpperCase()),
          bodyPositions: drift.Value(posJson),
          prefixes: drift.Value(standardPrefixes.isEmpty ? null : standardPrefixes.toUpperCase()),
          suffixes: drift.Value(suffixes.isEmpty ? null : suffixes.toUpperCase()),
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

    _implementControllers.clear();
    if (e.implements != null && e.implements!.isNotEmpty) {
      for (var imp in e.implements!.split(',')) {
        if (imp.isNotEmpty) _implementControllers.add(TextEditingController(text: imp));
      }
    }

    _bodyPositionControllers.clear();
    _bodyPositionShowInName.clear();
    if (e.bodyPositions != null && e.bodyPositions!.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(e.bodyPositions!);
        for (var item in decoded) {
          _bodyPositionControllers.add(TextEditingController(text: item['v']));
          _bodyPositionShowInName.add(item['s'] ?? true);
        }
      } catch (_) {
        for (var pos in e.bodyPositions!.split(',')) {
          if (pos.isNotEmpty) {
            _bodyPositionControllers.add(TextEditingController(text: pos));
            _bodyPositionShowInName.add(true);
          }
        }
      }
    }

    _prefixControllers.clear();
    if (e.prefixes != null && e.prefixes!.isNotEmpty) {
      for (var pre in e.prefixes!.split(',')) {
        if (pre.isNotEmpty) _prefixControllers.add(TextEditingController(text: pre));
      }
    }

    _suffixControllers.clear();
    if (e.suffixes != null && e.suffixes!.isNotEmpty) {
      for (var suf in e.suffixes!.split(',')) {
        if (suf.isNotEmpty) _suffixControllers.add(TextEditingController(text: suf));
      }
    }

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
        if (e.bodyPositions != null) {
          try {
            final List<dynamic> decoded = jsonDecode(e.bodyPositions!);
            found = decoded.map((item) => item['v'].toString()).toList();
          } catch (_) {
            found = e.bodyPositions!.split(',');
          }
        }
      } else if (type == 'implement') {
        found = (e.implements ?? '').split(',');
      } else if (type == 'prefix') {
        found = (e.prefixes ?? '').split(',');
      } else if (type == 'suffix') {
        found = (e.suffixes ?? '').split(',');
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
              _buildSearchableField('BASE NAME (E.G : VERTICAL PULL)', _nameController, 'name'),
              const SizedBox(height: 12),
              LabButton(
                label: 'Copy Existing Movement', 
                onPressed: _showCopyPicker, 
                color: LabColors.tertiary,
                isOutlined: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              const SizedBox(height: 12),
              LabButton(
                label: 'Complex Metadata Input', 
                onPressed: _showComplexMetadataInput, 
                color: LabColors.primary,
                isOutlined: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              const SizedBox(height: 16),
              _buildSearchableField('Field / Discipline', _fieldController, 'field'),
              const SizedBox(height: 16),
              LabTextField(
                controller: _descriptionController, 
                label: 'Technical Description / Notes', 
                maxLines: 3,
                keyboardType: TextInputType.multiline,
              ),
              
              const SizedBox(height: 24),
              _buildSectionTitle('QUALITIES'),
              const SizedBox(height: 16),
              _buildBodyPositionList(),
              const SizedBox(height: 16),
              _buildDynamicList('IMPLEMENTS', _implementControllers, () => setState(() => _implementControllers.add(TextEditingController())), type: 'implement', color: Colors.orangeAccent),
              const SizedBox(height: 16),
              _buildDynamicList('PREFIXES', _prefixControllers, () => setState(() => _prefixControllers.add(TextEditingController())), type: 'prefix'),
              const SizedBox(height: 16),
              _buildDynamicList('SUFFIXES', _suffixControllers, () => setState(() => _suffixControllers.add(TextEditingController())), type: 'suffix'),
              
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
                        label: 'VP MULTIPLIER',
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true))),
              ]),

              const SizedBox(height: 32),
              _buildSectionTitle('TARGETING'),
              const SizedBox(height: 16),
              _buildSearchableField('Primary Muscle', _primaryMuscleController, 'muscle'),
              const SizedBox(height: 16),
              _buildSearchableField('Secondary Muscle', _secondaryMuscleController, 'muscle'),
              
              const SizedBox(height: 32),
              _buildSearchableField('Pattern Type', _patternTypeController, 'pattern'),
              const SizedBox(height: 16),
              _buildSearchableField('Purpose / Intention', _intentionController, 'purpose'),
              
              const SizedBox(height: 32),
              _buildSectionTitle('BIOMECHANICAL_TISSUE'),
              const SizedBox(height: 16),
              _buildSearchableField('Type of Tissue', _tissueTypeController, 'tissueType'),
              const SizedBox(height: 16),
              _buildSearchableField('Name of Tissue', _tissueNameController, 'tissueName'),
              
              const SizedBox(height: 32),
              _buildSectionTitle('PHASES'),
              const SizedBox(height: 16),
              LabTextField(controller: _numPhasesController, label: 'Number of Phases'),
              const SizedBox(height: 16),
              ..._phaseDescriptionControllers.asMap().entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12), 
                child: _buildSearchableField('Phase ${entry.key + 1}', entry.value, 'phase')
              )),

              const SizedBox(height: 40),
              LabButton(label: 'Update Movement', onPressed: _updateExercise, color: LabColors.accent),
              const SizedBox(height: 12),
              LabButton(label: 'Abort', onPressed: () => Navigator.pop(context), isOutlined: true, color: Colors.redAccent),
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
    return Row(children: ['LASTRE', 'EXT.LOAD', 'JST.BW'].map((type) {
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

  Widget _buildBodyPositionList() {
    const color = Colors.blueAccent;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('BODY_POSITION', style: LabStyles.mono(context, color: color.withValues(alpha: 0.7), fontSize: 9)), 
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.manage_search, color: color, size: 18), 
              onPressed: () => _showQualityOverlay(null, 'bodyPosition', onSelect: (v) => setState(() {
                _bodyPositionControllers.add(TextEditingController(text: v));
                _bodyPositionShowInName.add(true);
              }))
            ),
            IconButton(icon: const Icon(Icons.add_circle_outline, color: color, size: 18), onPressed: () => setState(() {
              _bodyPositionControllers.add(TextEditingController());
              _bodyPositionShowInName.add(true); 
            })),
          ],
        )
      ]),
      ..._bodyPositionControllers.asMap().entries.map((entry) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
        Expanded(child: LabTextField(controller: entry.value, label: 'BODY_POSITION #${entry.key + 1}')),
        const SizedBox(width: 8),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Text('NAME', style: LabStyles.mono(context, fontSize: 6, color: _bodyPositionShowInName[entry.key] ? LabColors.primary : Colors.grey)),
          Switch.adaptive(
            value: _bodyPositionShowInName[entry.key], 
            activeColor: LabColors.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: (v) => setState(() => _bodyPositionShowInName[entry.key] = v)
          ),
        ]),
        IconButton(icon: const Icon(Icons.close, color: Colors.redAccent, size: 18), onPressed: () => setState(() {
          _bodyPositionControllers.removeAt(entry.key).dispose();
          _bodyPositionShowInName.removeAt(entry.key);
        }))
      ])))
    ]);
  }

  Widget _buildDynamicList(String title, List<TextEditingController> controllers, VoidCallback onAdd, {required String type, Color color = LabColors.primary}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(title, style: LabStyles.mono(context, color: color.withValues(alpha: 0.7), fontSize: 9)), 
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.manage_search, color: color, size: 18), 
              onPressed: () => _showQualityOverlay(null, type, onSelect: (v) => setState(() {
                controllers.add(TextEditingController(text: v));
              }))
            ),
            IconButton(icon: Icon(Icons.add_circle_outline, color: color, size: 18), onPressed: onAdd),
          ],
        )
      ]),
      ...controllers.asMap().entries.map((entry) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [Expanded(child: LabTextField(controller: entry.value, label: '$title #${entry.key + 1}')), IconButton(icon: const Icon(Icons.close, color: Colors.redAccent, size: 18), onPressed: () => setState(() => controllers.removeAt(entry.key).dispose()))])))
    ]);
  }
}

