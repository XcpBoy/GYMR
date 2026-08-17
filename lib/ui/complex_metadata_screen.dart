import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/database_provider.dart';
import '../database/database.dart';
import 'styles.dart';
import 'lab_widgets.dart';
import 'main_scaffold.dart';
import '../localization/strings.dart';

class ComplexMetadataScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> initialMetadata;
  final String exerciseName;

  const ComplexMetadataScreen({
    super.key, 
    required this.initialMetadata,
    required this.exerciseName,
  });

  @override
  ConsumerState<ComplexMetadataScreen> createState() => _ComplexMetadataScreenState();
}

class _ComplexMetadataScreenState extends ConsumerState<ComplexMetadataScreen> {
  late Map<String, dynamic> _metadata;
  
  @override
  void initState() {
    super.initState();
    // Deep copy to avoid mutation of initial
    // Handle legacy String list or new Map list for toggles
    final rawToggles = widget.initialMetadata["particular_toggles"] ?? [];
    final List<Map<String, dynamic>> processedToggles = [];
    
    for (var item in rawToggles) {
      if (item is String) {
        processedToggles.add({"name": item.toUpperCase(), "default": false});
      } else if (item is Map) {
        processedToggles.add({
          "name": (item["name"] as String).toUpperCase(),
          "default": item["default"] ?? false,
        });
      }
    }

    _metadata = {
      "regressions": List<String>.from(widget.initialMetadata["regressions"] ?? []),
      "progressions": List<String>.from(widget.initialMetadata["progressions"] ?? []),
      "alters": List<String>.from(widget.initialMetadata["alters"] ?? []),
      "particular_toggles": processedToggles,
    };
  }

  void _addRelation(String category, String value) {
    if (value == widget.exerciseName) return; // Cant relate to self
    final list = _metadata[category] as List<String>;
    if (!list.contains(value)) {
      setState(() {
        list.add(value);
      });
    }
  }

  void _removeRelation(String category, int index) {
    setState(() {
      (_metadata[category] as List<String>).removeAt(index);
    });
  }

  void _addToggle(String name) {
    final list = _metadata["particular_toggles"] as List<Map<String, dynamic>>;
    final upperName = name.toUpperCase().trim();
    if (upperName.isNotEmpty && !list.any((t) => t["name"] == upperName)) {
      setState(() {
        list.add({"name": upperName, "default": false});
      });
    }
  }

  void _toggleDefault(int index) {
    setState(() {
      final list = _metadata["particular_toggles"] as List<Map<String, dynamic>>;
      list[index]["default"] = !(list[index]["default"] as bool);
    });
  }

  void _removeToggle(int index) {
    setState(() {
      (_metadata["particular_toggles"] as List<Map<String, dynamic>>).removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider).value ?? 'en';
    return MainScaffold(
      title: 'COMPLEX_METADATA_INPUT',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("MODULAR_PERFORMANCE", style: LabStyles.mono(context, color: LabColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            
            _ExpandableMetadataCard(
              title: "TOGGLES",
              subtitle: "EXERCISE_SPECIFIC_PARAMETERS",
              color: Colors.cyanAccent,
              icon: Icons.toggle_on,
              initiallyExpanded: true,
              onAdd: () => _showToggleCreator(),
              content: _buildToggleGrid(),
            ),
            const SizedBox(height: 32),

            _buildRelationHeader("EVOLUTIONARY_PATH"),
            const SizedBox(height: 16),
            
            _ExpandableMetadataCard(
              title: "REGRESSIONS",
              subtitle: "LOWER_TIER_MOVEMENTS",
              color: Colors.redAccent,
              icon: Icons.keyboard_double_arrow_down,
              onAdd: () => _showExercisePicker("regressions"),
              content: _buildRelationList("regressions", Colors.redAccent),
            ),
            const SizedBox(height: 16),
            
            _ExpandableMetadataCard(
              title: "PROGRESSIONS",
              subtitle: "HIGHER_TIER_MOVEMENTS",
              color: Colors.greenAccent,
              icon: Icons.keyboard_double_arrow_up,
              onAdd: () => _showExercisePicker("progressions"),
              content: _buildRelationList("progressions", Colors.greenAccent),
            ),
            const SizedBox(height: 16),
            
            _ExpandableMetadataCard(
              title: "ALTERNATIVES",
              subtitle: "LATERAL_VARIATIONS",
              color: LabColors.accent,
              icon: Icons.sync,
              onAdd: () => _showExercisePicker("alters"),
              content: _buildRelationList("alters", LabColors.accent),
            ),
            
            const SizedBox(height: 48),
            LabButton(
              label: tr(lang, "Commit Metadata"),
              onPressed: () => Navigator.pop(context, _metadata),
              color: LabColors.primary,
            ),
            const SizedBox(height: 12),
            LabButton(
              label: tr(lang, "Abort changes"),
              onPressed: () => Navigator.pop(context),
              isOutlined: true,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRelationHeader(String text) {
    return Row(
      children: [
        Container(width: 4, height: 12, color: LabColors.accent),
        const SizedBox(width: 8),
        Text(text, style: LabStyles.mono(context, fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildToggleGrid() {
    final list = _metadata["particular_toggles"] as List<Map<String, dynamic>>;
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text("EMPTY_TOGGLE_LIST", style: LabStyles.mono(context, fontSize: 8, color: Colors.grey[700])),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double itemWidth = (constraints.maxWidth - 8) / 2;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: list.asMap().entries.map((entry) {
            final index = entry.key;
            final toggle = entry.value;
            final bool isDefault = toggle["default"] ?? false;
            
            return Container(
              width: itemWidth,
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(color: Colors.white10, width: 0.5),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start, // Allow expansion
                children: [
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: Checkbox(
                      value: isDefault,
                      onChanged: (_) => _toggleDefault(index),
                      activeColor: Colors.cyanAccent,
                      checkColor: Colors.black,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      side: const BorderSide(color: Colors.white24, width: 0.5),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        toggle["name"].toString().toUpperCase(),
                        style: LabStyles.mono(context, fontSize: 8, color: isDefault ? Colors.cyanAccent : Colors.white70),
                        softWrap: true, // Expand slice for long text
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => _removeToggle(index),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: const Icon(Icons.close, size: 12, color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildRelationList(String key, Color color) {
    final list = _metadata[key] as List<String>;
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text("EMPTY_METADATA_NODE", style: LabStyles.mono(context, fontSize: 8, color: Colors.grey[700])),
        ),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: list.asMap().entries.map((entry) => _buildRelationChip(key, entry.key, entry.value, color)).toList(),
    );
  }

  Widget _buildRelationChip(String category, int index, String name, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(name.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: LabStyles.mono(context, fontSize: 9, color: color)),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => _removeRelation(category, index),
            child: Icon(Icons.close, size: 12, color: color),
          ),
        ],
      ),
    );
  }

  void _showToggleCreator() {
    final lang = ref.read(languageProvider).value ?? 'en';
    final TextEditingController tC = TextEditingController();
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: LabColors.background,
        title: Text("NEW_TOGGLE", style: LabStyles.headline(context).copyWith(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(child: LabTextField(controller: tC, label: tr(lang, "Toggle Name (e.g. CHALK)"))),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.manage_search, color: LabColors.primary),
                  onPressed: () {
                    Navigator.pop(c);
                    _showTogglePicker();
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(tr(lang, "CANCEL"), style: LabStyles.mono(context))),
          TextButton(
            onPressed: () {
              _addToggle(tC.text);
              Navigator.pop(c);
            },
            child: Text(tr(lang, "ADD"), style: LabStyles.mono(context, color: LabColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showTogglePicker() async {
    final db = ref.read(databaseProvider);
    final allExercises = await db.select(db.baseExercises).get();
    
    final Set<String> existingToggles = {};
    for (var ex in allExercises) {
      final meta = ex.parsedComplexMetadata;
      final toggles = List<String>.from(meta["particular_toggles"] ?? []);
      existingToggles.addAll(toggles.map((e) => e.toUpperCase()));
    }

    if (!mounted) return;
    final lang = ref.read(languageProvider).value ?? 'en';

    showModalBottomSheet(
      context: context,
      backgroundColor: LabColors.background,
      isScrollControlled: true,
      builder: (c) => _InternalTogglePicker(
        values: existingToggles.toList()..sort(),
        onSelected: (name) => _addToggle(name),
        lang: lang,
      ),
    );
  }

  void _showExercisePicker(String category) async {
    final db = ref.read(databaseProvider);
    final all = await db.select(db.baseExercises).get();

    if (!mounted) return;
    final lang = ref.read(languageProvider).value ?? 'en';

    showModalBottomSheet(
      context: context,
      backgroundColor: LabColors.background,
      isScrollControlled: true,
      builder: (c) => _InternalExercisePicker(
        exercises: all,
        onSelected: (name) => _addRelation(category, name),
        lang: lang,
      ),
    );
  }
}

class _ExpandableMetadataCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final VoidCallback onAdd;
  final Widget content;
  final bool initiallyExpanded;

  const _ExpandableMetadataCard({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.onAdd,
    required this.content,
    this.initiallyExpanded = false,
  });

  @override
  State<_ExpandableMetadataCard> createState() => _ExpandableMetadataCardState();
}

class _ExpandableMetadataCardState extends State<_ExpandableMetadataCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _isExpanded ? widget.color.withValues(alpha: 0.05) : Colors.black,
        border: Border.all(color: _isExpanded ? widget.color : Colors.white10, width: 0.5),
      ),
      child: Column(
        children: [
          ListTile(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            dense: true,
            leading: Icon(widget.icon, color: _isExpanded ? widget.color : Colors.grey, size: 18),
            title: Text(widget.title, style: LabStyles.mono(context, fontSize: 12, fontWeight: FontWeight.bold, color: _isExpanded ? widget.color : Colors.white)),
            subtitle: Text(widget.subtitle, style: LabStyles.mono(context, fontSize: 7, color: Colors.grey)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.add, color: widget.color, size: 16),
                  onPressed: widget.onAdd,
                ),
                Icon(_isExpanded ? Icons.expand_less : Icons.expand_more, size: 16, color: Colors.grey),
              ],
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 8),
              child: widget.content,
            ),
        ],
      ),
    );
  }
}

class _InternalExercisePicker extends StatefulWidget {
  final List<BaseExercise> exercises;
  final Function(String) onSelected;
  final String lang;

  const _InternalExercisePicker({required this.exercises, required this.onSelected, required this.lang});

  @override
  State<_InternalExercisePicker> createState() => _InternalExercisePickerState();
}

class _InternalExercisePickerState extends State<_InternalExercisePicker> {
  late List<BaseExercise> flt;
  final TextEditingController sC = TextEditingController();

  @override
  void initState() {
    super.initState();
    flt = widget.exercises;
    sC.addListener(() {
      setState(() {
        flt = widget.exercises.where((e) =>
          e.fullName.toLowerCase().contains(sC.text.toLowerCase())
        ).toList();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: LabColors.surfaceContainerHigh,
              border: Border(bottom: BorderSide(color: LabColors.primary, width: 2))
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('SELECT_RELATION', style: LabStyles.headline(context).copyWith(fontSize: 18)),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white))
                  ]
                ),
                const SizedBox(height: 16),
                LabTextField(controller: sC, label: tr(widget.lang, 'Search exercise name...'))
              ]
            )
          ),
          Expanded(
            child: ListView.builder(
              itemCount: flt.length,
              itemBuilder: (c, i) => LabListTile(
                title: flt[i].fullName,
                subtitle: flt[i].primaryMuscleGroup ?? 'GENERAL',
                onTap: () {
                  widget.onSelected(flt[i].fullName);
                  Navigator.pop(context);
                }
              )
            )
          )
        ]
      )
    );
  }
}

class _InternalTogglePicker extends StatefulWidget {
  final List<String> values;
  final Function(String) onSelected;
  final String lang;

  const _InternalTogglePicker({required this.values, required this.onSelected, required this.lang});

  @override
  State<_InternalTogglePicker> createState() => _InternalTogglePickerState();
}

class _InternalTogglePickerState extends State<_InternalTogglePicker> {
  late List<String> flt;
  final TextEditingController sC = TextEditingController();

  @override
  void initState() {
    super.initState();
    flt = widget.values;
    sC.addListener(() {
      setState(() {
        flt = widget.values.where((v) =>
          v.toLowerCase().contains(sC.text.toLowerCase())
        ).toList();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: LabColors.surfaceContainerHigh,
              border: Border(bottom: BorderSide(color: LabColors.primary, width: 2))
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('SELECT_EXISTING_TOGGLE', style: LabStyles.headline(context).copyWith(fontSize: 18)),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white))
                  ]
                ),
                const SizedBox(height: 16),
                LabTextField(controller: sC, label: tr(widget.lang, 'Search toggle name...'))
              ]
            )
          ),
          Expanded(
            child: ListView.builder(
              itemCount: flt.length,
              itemBuilder: (c, i) => ListTile(
                title: Text(flt[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: LabStyles.mono(context, fontSize: 12)),
                onTap: () {
                  widget.onSelected(flt[i]);
                  Navigator.pop(context);
                }
              )
            )
          )
        ]
      )
    );
  }
}

