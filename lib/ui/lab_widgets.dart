import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';
import '../database/database.dart';
import '../localization/strings.dart';
import 'styles.dart';
import 'home_screen.dart';
import 'workout_manager.dart';
import 'ledger_screen.dart';
import 'charts/performance_dashboard.dart';

class LabUtilitySelector extends ConsumerStatefulWidget {
  final List<String> selected; // current utilities (up to 4)
  final List<String> suggestions; // all existing tags
  final Map<String, int>? utilityFrequency; // usage count per utility for sorting
  final ValueChanged<List<String>> onChanged;
  final Function(String oldName, String newName) onRename;
  final Function(String name) onDelete;

  const LabUtilitySelector({
    super.key,
    required this.selected,
    required this.suggestions,
    this.utilityFrequency,
    required this.onChanged,
    required this.onRename,
    required this.onDelete,
  });

  @override
  ConsumerState<LabUtilitySelector> createState() => _LabUtilitySelectorState();
}

enum _UtilSortMode { alpha, reverseAlpha, mostUsed, newest }

class _LabUtilitySelectorState extends ConsumerState<LabUtilitySelector> {
  static const int maxUtilities = 4;
  late final TextEditingController _newUtilC;
  _UtilSortMode _sortMode = _UtilSortMode.alpha;

  @override
  void initState() {
    super.initState();
    _newUtilC = TextEditingController();
  }

  @override
  void dispose() {
    _newUtilC.dispose();
    super.dispose();
  }

  List<String> _sortedSuggestions() {
    final list = widget.suggestions.where((t) => !widget.selected.contains(t)).toList();
    switch (_sortMode) {
      case _UtilSortMode.alpha:
        list.sort();
        break;
      case _UtilSortMode.reverseAlpha:
        list.sort((a, b) => b.compareTo(a));
        break;
      case _UtilSortMode.mostUsed:
        if (widget.utilityFrequency != null) {
          list.sort((a, b) => (widget.utilityFrequency![b] ?? 0).compareTo(widget.utilityFrequency![a] ?? 0));
        }
        break;
      case _UtilSortMode.newest:
        // Reverse of suggestions order (last added = newest in DB order)
        break;
    }
    return list;
  }

  void _toggleTag(String tag) {
    final current = List<String>.from(widget.selected);
    if (current.contains(tag)) {
      current.remove(tag);
    } else {
      if (current.length >= maxUtilities) return;
      current.add(tag);
    }
    widget.onChanged(current);
  }

  Color _tagColor(String tag) {
    final settings = ref.watch(themeSettingsProvider).value ?? {};
    final tc = ref.read(themeControllerProvider);
    return tc.getColor(settings, 'UI_TAG_${tag.replaceAll(' ', '_')}', nameSeed: tag);
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider).value ?? 'en';
    final sorted = _sortedSuggestions();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // New utility text field + sort button row
        Row(
          children: [
            Expanded(
              flex: 3,
              child: SizedBox(
                height: 36,
                child: TextField(
                  controller: _newUtilC,
                  style: LabStyles.mono(context, fontSize: 11, color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'NEW_UTILITY...',
                    hintStyle: TextStyle(color: Colors.grey[600], fontSize: 10),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    border: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24, width: 0.5)),
                    isDense: true,
                  ),
                  onSubmitted: (v) {
                    final trimmed = v.trim().toUpperCase();
                    if (trimmed.isNotEmpty && !widget.selected.contains(trimmed)) {
                      final updated = List<String>.from(widget.selected);
                      if (updated.length < maxUtilities) {
                        updated.add(trimmed);
                        widget.onChanged(updated);
                      }
                    }
                    _newUtilC.clear();
                  },
                ),
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              height: 36,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: LabColors.accent,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                ),
                onPressed: () {
                  final trimmed = _newUtilC.text.trim().toUpperCase();
                  if (trimmed.isNotEmpty && !widget.selected.contains(trimmed)) {
                    final updated = List<String>.from(widget.selected);
                    if (updated.length < maxUtilities) {
                      updated.add(trimmed);
                      widget.onChanged(updated);
                    }
                  }
                  _newUtilC.clear();
                },
                child: Text(tr(lang, 'ADD'), style: LabStyles.mono(context, fontSize: 10, color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 6),
            // Sort mode toggle
            SizedBox(
              height: 36,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                  side: BorderSide(color: Colors.white24, width: 0.5),
                ),
                onPressed: () {
                  setState(() {
                    _sortMode = _UtilSortMode.values[(_sortMode.index + 1) % _UtilSortMode.values.length];
                  });
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sort, size: 12, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(
                      _sortMode == _UtilSortMode.alpha ? 'A-Z' :
                      _sortMode == _UtilSortMode.reverseAlpha ? 'Z-A' :
                      _sortMode == _UtilSortMode.mostUsed ? 'MST' : 'NEW',
                      style: LabStyles.mono(context, fontSize: 9, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text('SELECTED_UTILITIES (${widget.selected.length}/$maxUtilities)',
            style: LabStyles.mono(context, fontSize: 7, color: LabColors.accent)),
        const SizedBox(height: 8),
        if (widget.selected.isNotEmpty) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: widget.selected.map((tag) => _UtilityTagChip(
              tag: tag,
              selected: true,
              borderColor: _tagColor(tag),
              onTap: () => _toggleTag(tag),
              onEdit: () => _showRenameDialog(context, tag, lang),
              onDelete: () => _showDeleteConfirm(context, tag, lang),
            )).toList(),
          ),
          const SizedBox(height: 12),
          Container(height: 0.5, color: Colors.white12),
          const SizedBox(height: 12),
        ],
        if (sorted.isNotEmpty) ...[
          Text('EXISTING_SCHEMA_TAGS', style: LabStyles.mono(context, fontSize: 8, color: Colors.grey)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: sorted
              .take(24)
              .map((tag) => _UtilityTagChip(
                tag: tag,
                selected: false,
                borderColor: _tagColor(tag),
                onTap: () => _toggleTag(tag),
                onEdit: () => _showRenameDialog(context, tag, lang),
                onDelete: () => _showDeleteConfirm(context, tag, lang),
              )).toList(),
          ),
        ],
      ],
    );
  }

  void _showRenameDialog(BuildContext context, String oldName, String lang) {
    final editC = TextEditingController(text: oldName);
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: LabColors.background,
        title: Text('RENAME_UTILITY', style: LabStyles.mono(context, fontSize: 12, color: LabColors.primary)),
        content: LabTextField(controller: editC, label: 'NEW_NAME'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(tr(lang, 'CANCEL'), style: LabStyles.mono(context))),
          TextButton(
            onPressed: () {
              widget.onRename(oldName, editC.text.toUpperCase().trim());
              Navigator.pop(c);
            },
            child: Text(tr(lang, 'UPDATE'), style: LabStyles.mono(context, color: LabColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, String tag, String lang) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: LabColors.background,
        title: Text('DELETE_UTILITY_TAG', style: LabStyles.mono(context, fontSize: 12, color: Colors.redAccent)),
        content: Text(
            tr(lang, 'REMOVING "{tag}" WILL CLEAR IT FROM ALL RECORDS.').replaceFirst('{tag}', tag),
            style: LabStyles.mono(context, fontSize: 10)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(tr(lang, 'CANCEL'), style: LabStyles.mono(context))),
          TextButton(
            onPressed: () {
              widget.onDelete(tag);
              Navigator.pop(c);
            },
            child: Text('DELETE_EVERYWHERE', style: LabStyles.mono(context, color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

class _UtilityTagChip extends StatelessWidget {
  final String tag;
  final bool selected;
  final Color borderColor;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UtilityTagChip({
    required this.tag,
    required this.selected,
    required this.borderColor,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? borderColor.withValues(alpha: 0.2) : Colors.black,
          border: Border.all(
            color: borderColor,
            width: selected ? 1.5 : 0.5,
          ),
          borderRadius: BorderRadius.circular(0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selected ? '\u2713 ' : '+ ',
              style: LabStyles.mono(context, fontSize: 8, color: selected ? borderColor : Colors.grey),
            ),
            Text(tag.toUpperCase(), style: LabStyles.mono(context, fontSize: 9, color: Colors.white)),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onEdit,
              child: Icon(Icons.edit, size: 10, color: borderColor.withValues(alpha: 0.7)),
            ),
            const SizedBox(width: 2),
            GestureDetector(
              onTap: onDelete,
              child: Icon(Icons.close, size: 10, color: Colors.redAccent),
            ),
          ],
        ),
      ),
    );
  }
}

class LabTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? placeholder;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;
  final int maxLines;
  final double fontSize;
  final double labelFontSize;
  final double hintFontSize;

  const LabTextField({
    super.key,
    required this.controller,
    required this.label,
    this.placeholder,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.maxLines = 1,
    this.fontSize = 14,
    this.labelFontSize = 8,
    this.hintFontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: LabStyles.mono(context, fontSize: labelFontSize, color: Colors.grey)),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          validator: validator,
          onChanged: onChanged,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: LabStyles.mono(context, fontSize: fontSize),
          decoration: InputDecoration(
            isDense: true,
            hintText: placeholder?.toUpperCase(),
            hintStyle: LabStyles.mono(context, fontSize: hintFontSize, color: Colors.grey.withValues(alpha: 0.5)),
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[800]!, width: 0.5), borderRadius: BorderRadius.zero),
            focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: LabColors.primary, width: 0.5), borderRadius: BorderRadius.zero),
            fillColor: LabColors.surfaceDim,
            filled: true,
          ),
        ),
      ],
    );
  }
}

class TechnicalQuickTimeFilter extends StatelessWidget {
  final DateTimeRange? currentRange;
  final Function(DateTimeRange?) onRangeSelected;
  final Color activeColor;

  const TechnicalQuickTimeFilter({
    super.key,
    required this.currentRange,
    required this.onRangeSelected,
    this.activeColor = LabColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      margin: const EdgeInsets.only(top: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildQuickButton(context, '2W', 14),
          _buildQuickButton(context, '1M', 30),
          _buildQuickButton(context, '3M', 90),
          _buildQuickButton(context, '6M', 180),
          _buildQuickButton(context, '1Y', 365),
          _buildQuickButton(context, 'ALL', null),
        ],
      ),
    );
  }

  Widget _buildQuickButton(BuildContext context, String label, int? days) {
    bool isActive = false;
    if (days == null) {
      isActive = currentRange == null;
    } else if (currentRange != null) {
      final diff = DateTime.now().difference(currentRange!.start).inDays;
      // Precision check with 2-day margin for month variations
      isActive = (diff >= days - 2 && diff <= days + 2);
    }

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () {
          if (days == null) {
            onRangeSelected(null);
          } else {
            onRangeSelected(DateTimeRange(
              start: DateTime.now().subtract(Duration(days: days)),
              end: DateTime.now().add(const Duration(days: 1)),
            ));
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? activeColor.withValues(alpha: 0.1) : Colors.transparent,
            border: Border.all(color: isActive ? activeColor : Colors.grey[800]!, width: 0.5),
          ),
          child: Text(label, style: LabStyles.mono(context, fontSize: 8, color: isActive ? activeColor : Colors.grey, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
        ),
      ),
    );
  }
}

class LabListTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  const LabListTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: LabColors.cyanBorder.withValues(alpha: 0.3), width: 0.5),
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(title.toUpperCase(), style: LabStyles.mono(context, fontWeight: FontWeight.bold, fontSize: 12)),
        subtitle: Text(subtitle.toUpperCase(), style: LabStyles.mono(context, fontSize: 9, color: Colors.grey)),
        trailing: trailing ?? const Icon(Icons.chevron_right, color: LabColors.primary, size: 16),
      ),
    );
  }
}

class NeonPalette {
  static const List<Color> colors = [
    // Row 1: Warm Spectrum
    Color(0xFFFF3131), Color(0xFFFF5E00), Color(0xFFFFD700), Color(0xFFFFFF00), Color(0xFFCCFF00),
    // Row 2: Green & Teal
    Color(0xFF39FF14), Color(0xFF00FA9A), Color(0xFF00FFEF), Color(0xFF00FFFF), Color(0xFF40E0D0),
    // Row 3: Blues
    Color(0xFF00BFFF), Color(0xFF007BFF), Color(0xFF7B68EE), Color(0xFF8A2BE2), Color(0xFF4B0082),
    // Row 4: Purples & Pinks
    Color(0xFFDA70D6), Color(0xFFEE82EE), Color(0xFFFF00FF), Color(0xFFFF007F), Color(0xFFF4A460),
    // Row 5: Lab Neutral / Technical
    Color(0xFFFFFFFF), Color(0xFFE0E0E0), Color(0xFF9E9E9E), Color(0xFF616161), Color(0xFF212121),
  ];
}

class QualitySearchPicker extends StatefulWidget {
  final String title;
  final List<String> values;
  final Function(String) onSelected;
  final bool closeOnSelect;
  // Optional: this widget is plain (no ref access), so callers that have a
  // WidgetRef can pass the current lang through to get the "Filter..."
  // hint translated. Defaults to 'en' so existing call sites keep compiling.
  final String lang;
  const QualitySearchPicker({
    super.key,
    required this.title,
    required this.values,
    required this.onSelected,
    this.closeOnSelect = true,
    this.lang = 'en',
  });
  @override State<QualitySearchPicker> createState() => _QualitySearchPickerState();
}

class _QualitySearchPickerState extends State<QualitySearchPicker> {
  late List<String> flt;
  final TextEditingController sC = TextEditingController();
  @override void initState() {
    super.initState();
    flt = widget.values;
    sC.addListener(() {
      setState(() {
        flt = widget.values.where((v) => v.toLowerCase().contains(sC.text.toLowerCase())).toList();
      });
    });
  }
  @override Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
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
                    Text(widget.title, style: LabStyles.headline(context).copyWith(fontSize: 18)),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white))
                  ]
                ),
                const SizedBox(height: 16),
                LabTextField(controller: sC, label: tr(widget.lang, 'Filter...'))
              ]
            )
          ),
          Expanded(
            child: ListView.builder(
              itemCount: flt.length,
              itemBuilder: (c, i) => ListTile(
                title: Text(flt[i].toUpperCase(), style: LabStyles.mono(context, fontSize: 12)),
                onTap: () {
                  widget.onSelected(flt[i]);
                  if (widget.closeOnSelect) Navigator.pop(context);
                }
              )
            )
          )
        ]
      )
    );
  }
}



class LabButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color color;
  final bool isOutlined;
  final EdgeInsets? padding;
  final double fontSize;
  final double? height;

  const LabButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = LabColors.primary,
    this.isOutlined = false,
    this.padding,
    this.fontSize = 12,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        height: height,
        padding: height != null ? null : (padding ?? const EdgeInsets.symmetric(vertical: 14)),
        alignment: height != null ? Alignment.center : null,
        decoration: BoxDecoration(
          color: isOutlined ? Colors.transparent : color.withValues(alpha: 0.1),
          border: Border.all(color: color, width: 0.5),
        ),
        child: Text(
          label.toUpperCase(),
          textAlign: TextAlign.center,
          style: LabStyles.mono(context, color: color, fontWeight: FontWeight.bold, fontSize: fontSize),
        ),
      ),
    ),
    );
  }
}

class LabFooter extends ConsumerWidget {
  const LabFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(themeSettingsProvider).value ?? {};
    final controller = ref.read(themeControllerProvider);

    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: LabColors.background,
        border: Border(top: BorderSide(color: LabColors.cyanBorder, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildFooterButton(
            context,
            Icons.dashboard,
            "DSHBRD",
            controller.getColor(settings, "FOOTER_DSHBRD", defaultColor: LabColors.primary),
            () => Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (c) => const HomeScreen()), (r) => false),
          ),
          _buildFooterButton(
            context,
            Icons.fitness_center,
            "WORKOUT",
            controller.getColor(settings, "FOOTER_WORKOUT", defaultColor: LabColors.workoutRed),
            () => Navigator.of(context).push(MaterialPageRoute(builder: (c) => WorkoutManagerScreen())),
          ),
          _buildFooterButton(
            context,
            Icons.receipt_long,
            "INVENTORY",
            controller.getColor(settings, "FOOTER_INVENTORY", defaultColor: LabColors.inventoryOrange),
            () => Navigator.of(context).push(MaterialPageRoute(builder: (c) => const LedgerScreen())),
          ),
          _buildFooterButton(
            context,
            Icons.analytics,
            "VISUALS",
            controller.getColor(settings, "FOOTER_VISUALS", defaultColor: LabColors.visualsNeon),
            () => Navigator.of(context).push(MaterialPageRoute(builder: (c) => const PerformanceDashboard())),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterButton(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(label, style: LabStyles.mono(context, fontSize: 8, color: color)),
        ],
      ),
    );
  }
}

