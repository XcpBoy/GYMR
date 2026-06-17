import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/theme_provider.dart';
import '../providers/database_provider.dart';
import '../database/database.dart';
import 'styles.dart';
import 'lab_widgets.dart';

class ThemeModdingScreen extends ConsumerStatefulWidget {
  const ThemeModdingScreen({super.key});

  @override
  ConsumerState<ThemeModdingScreen> createState() => _ThemeModdingScreenState();
}

class _ThemeModdingScreenState extends ConsumerState<ThemeModdingScreen> {
  Color _pickerColor = Colors.cyan;

  // State for collapsible sections
  final Map<String, bool> _expandedSections = {
    "wo_header": false,
    "wo_filters": false,
    "wo_tags": false,
    "unilateral": false,
    "eorm": false,
    "muscle": false,
    "pattern": false,
    "movement": false,
    "field": false,
    "wallpaper": false,
    "utility": false,
    "superset": false,
    "dashboard_card": false,
    "footer": false,
    "wo_priority": false,
    "wo_batch": false,
    "injection": false,
    "nexus": false,
  };

  // Search controllers for each section
  final Map<String, TextEditingController> _searchControllers = {
    "wo_header": TextEditingController(),
    "wo_filters": TextEditingController(),
    "wo_tags": TextEditingController(),
    "unilateral": TextEditingController(),
    "eorm": TextEditingController(),
    "muscle": TextEditingController(),
    "pattern": TextEditingController(),
    "movement": TextEditingController(),
    "field": TextEditingController(),
    "wallpaper": TextEditingController(),
    "utility": TextEditingController(),
    "superset": TextEditingController(),
    "dashboard_card": TextEditingController(),
    "footer": TextEditingController(),
    "wo_priority": TextEditingController(),
    "wo_batch": TextEditingController(),
    "injection": TextEditingController(),
    "nexus": TextEditingController(),
  };

  @override
  void dispose() {
    for (var controller in _searchControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(themeSettingsProvider).value ?? {};
    final exercises = ref.watch(allExercisesProvider).value ?? [];
    final batchNamesAsync = ref.watch(allBatchNamesProvider);
    final List<String> batchNames = batchNamesAsync.value ?? [];

    // Extract and sort raw data
    final List<String> muscles = exercises
        .map((e) => e.primaryMuscleGroup)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();
    final List<String> patterns = exercises
        .map((e) => e.patternType)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();
    final List<String> fields = exercises
        .map((e) => e.field)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();
    final List<String> exerciseNames =
        exercises.map((e) => e.fullName).toSet().toList()..sort();

    // ── WORKOUT SCREEN: HEADER & CONTROLS ──
    final List<String> woHeaderUI = [
      "DATE_DISPLAY", // dd/MM/yy display in header
      "TAG_WORKOUT_OPTS", // WORKOUT OPTS button + sheet title
      "TAG_WO_BLUEPRINT", // Workout Opts slice: Blueprint
      "TAG_WO_PURGE", // Workout Opts slice: Delete All
    ];

    // ── WORKOUT SCREEN: TAG FILTERS (Exercise Picker) ──
    final List<String> woFilterUI = [
      "TAG_FILTER_LOAD",
      "TAG_FILTER_UNILATERAL",
      "TAG_FILTER_ISO",
      "TAG_FILTER_BASE",
      "TAG_FILTER_MUSCLE",
    ];

    // ── WORKOUT SCREEN: KNS CARD TAGS ──
    final List<String> woTagUI = [
      "TAG_LASTRE",
      "TAG_JSTBW",
      "TAG_EXTLOAD",
      "TAG_ISO",
      "TAG_BODYPOSITION",
      "TAG_PRIMARY_MUSCLE",
    ];

    // ── PRIORITY / UTIL COLORS ──
    final List<String> woPriorityUI = [
      "TAG_PRIMARY",
      "TAG_SECONDARY",
      "TAG_ARM_WRSTLN",
      "TAG_TERCIARY",
      "TAG_PRACTICE",
      "TAG_GTG",
      "TAG_PREHAB",
      "TAG_RECOVERY",
      "TAG_BLOOD_FLOW",
      "TAG_REHAB",
      "TAG_PUMP",
      "TAG_COMPLEMENT",
      "TAG_TENDONS",
      "TAG_BODYBUILDING",
    ];

    // ── BATCH SECTION COLORS (dynamic from complex_metadata) ──
    final List<String> woBatchUI = batchNames;

    // ── INJECTION TYPE BUTTON COLORS ──
    final List<String> injectionUI = [
      "INDIVIDUAL_MOVEMENT",
      "WORKOUT_BLOCK",
      "PLAN_DAY",
      "COPY_FROM_SPECIFIC_DAY",
    ];
    final Map<String, Color> injectionDefaults = {
      "INDIVIDUAL_MOVEMENT": LabColors.tertiary,
      "WORKOUT_BLOCK": LabColors.accent,
      "PLAN_DAY": LabColors.primary,
      "COPY_FROM_SPECIFIC_DAY": LabColors.secondary,
    };

    // ── UNILATERAL SIDE COLORS ──
    final List<String> unilateralUI = [
      "UNILATERAL_LEFT",
      "UNILATERAL_RIGHT",
    ];

    // ── EORM HIGHLIGHTING ──
    final List<String> eormUI = [
      "EORM_HIGHLIGHT",
    ];
    final List<String> screens = [
      "HOME",
      "WORKOUT",
      "LEDGER",
      "BLUEPRINT",
      "DATASET",
      "NEXUS",
      "TIMELINE"
    ];

    final List<String> dashboardItems = [
      "CRRNT.WO",
      "CRRNT.WO_BG",
      "KNS.INVTRY",
      "KNS.INVTRY_BG",
      "WO.BLKCS",
      "WO.BLKCS_BG",
      "TIMELINE",
      "TIMELINE_BG",
      "ANTRPMT.DT",
      "ANTRPMT.DT_BG",
      "VSR.STATS",
      "VSR.STATS_BG",
      "NEXUS",
      "NEXUS_BG",
      "DATASET",
      "DATASET_BG",
      "THEME.MDFYR",
      "THEME.MDFYR_BG",
      "PR.LOGIC",
      "PR.LOGIC_BG",
    ];
    final Map<String, Color> dashboardDefaults = {
      "CRRNT.WO": LabColors.workoutRed,
      "CRRNT.WO_BG": LabColors.workoutRed.withValues(alpha: 0.08),
      "KNS.INVTRY": LabColors.inventoryOrange,
      "KNS.INVTRY_BG": LabColors.inventoryOrange.withValues(alpha: 0.08),
      "WO.BLKCS": LabColors.blueprintBlue,
      "WO.BLKCS_BG": LabColors.blueprintBlue.withValues(alpha: 0.08),
      "TIMELINE": LabColors.timelineGrey,
      "TIMELINE_BG": LabColors.timelineGrey.withValues(alpha: 0.08),
      "ANTRPMT.DT": LabColors.biometricYellow,
      "ANTRPMT.DT_BG": LabColors.biometricYellow.withValues(alpha: 0.08),
      "VSR.STATS": LabColors.visualsNeon,
      "VSR.STATS_BG": LabColors.visualsNeon.withValues(alpha: 0.08),
      "NEXUS": LabColors.nexusPurple,
      "NEXUS_BG": LabColors.nexusPurple.withValues(alpha: 0.08),
      "DATASET": LabColors.datasetGold,
      "DATASET_BG": LabColors.datasetGold.withValues(alpha: 0.08),
      "THEME.MDFYR": LabColors.themeWhite,
      "THEME.MDFYR_BG": LabColors.themeWhite.withValues(alpha: 0.08),
      "PR.LOGIC": LabColors.primary,
      "PR.LOGIC_BG": LabColors.primary.withValues(alpha: 0.05),
    };

    final List<String> footerItems = [
      "DSHBRD",
      "WORKOUT",
      "INVENTORY",
      "VISUALS"
    ];
    final Map<String, Color> footerDefaults = {
      "DSHBRD": LabColors.primary,
      "WORKOUT": LabColors.workoutRed,
      "INVENTORY": LabColors.inventoryOrange,
      "VISUALS": LabColors.visualsNeon,
    };

    final List<String> nexusUI = [
      "WO_BLOCKS",
      "KNS_LIBRARY",
      "ROUTINE",
    ];
    final Map<String, Color> nexusDefaults = {
      "WO_BLOCKS": LabColors.biometricYellow,
      "KNS_LIBRARY": LabColors.inventoryOrange,
      "ROUTINE": LabColors.visualsNeon,
    };

    // Extract unique priorities from blueprints and workout sets
    final allBpExs = exercises.isNotEmpty
        ? ref.watch(allBlueprintExercisesProvider).value ?? []
        : [];
    final allSets = exercises.isNotEmpty
        ? ref.watch(allWorkoutSetsProvider).value ?? []
        : [];
    final List<String> utilities = {
      ...allBpExs.map((e) => e.priority).whereType<String>(),
      ...allSets.map((e) => e.priority).whereType<String>(),
    }.toList()
      ..sort();

    final List<String> supersetItems = settings.keys
        .where((k) => k.startsWith("SUPERSET_"))
        .map((k) => k.replaceFirst("SUPERSET_", ""))
        .toList()
      ..sort();

    return Scaffold(
      backgroundColor: LabColors.background,
      appBar: AppBar(
        backgroundColor: LabColors.background,
        title: Text("THEME_MODDING",
            style: LabStyles.mono(context, fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: LabColors.primary),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: LabColors.cyanBorder, height: 0.5),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── CATEGORY: C.WO INTERFACE ───
          _buildCategoryDivider(
              context, "CURRENT WORKOUT INTERFACE", "7 SECTIONS"),
          const SizedBox(height: 12),
          _buildSection(context, "HEADER & OPTS (${woHeaderUI.length})",
              "wo_header", woHeaderUI, settings),
          const SizedBox(height: 6),
          _buildSection(context, "TAG FILTERS (${woFilterUI.length})",
              "wo_filters", woFilterUI, settings),
          const SizedBox(height: 6),
          _buildSection(context, "KNS TAG LABELS (${woTagUI.length})",
              "wo_tags", woTagUI, settings),
          const SizedBox(height: 6),
          _buildSection(context, "UTILS (${woPriorityUI.length})",
              "wo_priority", woPriorityUI, settings),
          const SizedBox(height: 6),
          _buildSection(context, "BATCH COLORS (${woBatchUI.length})",
              "wo_batch", woBatchUI, settings),
          const SizedBox(height: 6),
          _buildSection(
              context,
              "INJECTION TYPE COLORS (${injectionUI.length})",
              "injection",
              injectionUI,
              settings,
              defaults: injectionDefaults),

          const SizedBox(height: 24),
          // ─── CATEGORY: GLOBAL / STRUCTURAL UI ───
          _buildCategoryDivider(
              context, "GLOBAL & STRUCTURAL UI", "5 SECTIONS"),
          const SizedBox(height: 12),
          _buildSection(
              context,
              "UNILATERAL_SIDE_COLORS (${unilateralUI.length})",
              "unilateral",
              unilateralUI,
              settings),
          const SizedBox(height: 6),
          _buildSection(context, "EORM_HIGHLIGHTS (${eormUI.length})", "eorm",
              eormUI, settings),
          const SizedBox(height: 6),
          _buildSection(
              context,
              "HOME_DASHBOARD_CARDS (${dashboardItems.length})",
              "dashboard_card",
              dashboardItems,
              settings,
              defaults: dashboardDefaults),
          const SizedBox(height: 6),
          _buildSection(context, "QUICK_SWITCHER_UI (${footerItems.length})",
              "footer", footerItems, settings,
              defaults: footerDefaults),
          const SizedBox(height: 6),
          _buildSection(context, "NEXUS_EXCHANGE_COLORS (${nexusUI.length})",
              "nexus", nexusUI, settings,
              defaults: nexusDefaults),

          const SizedBox(height: 24),
          // ─── CATEGORY: DATA & BIOMECHANICS ───
          _buildCategoryDivider(context, "DATA & BIOMECHANICS", "5 SECTIONS"),
          const SizedBox(height: 12),
          _buildValueSection(context, "VISUAL_ATMOSPHERE (${screens.length})",
              "wallpaper", screens, settings),
          const SizedBox(height: 6),
          _buildSection(context, "MOVEMENT_UTILITIES (${utilities.length})",
              "utility", utilities, settings),
          const SizedBox(height: 6),
          _buildSection(context, "SUPERSET_BLOCKS (${supersetItems.length})",
              "superset", supersetItems, settings),
          const SizedBox(height: 6),
          _buildSection(context, "MUSCLE_GROUPS (${muscles.length})", "muscle",
              muscles, settings),
          const SizedBox(height: 6),
          _buildSection(context, "MOVEMENT_PATTERNS (${patterns.length})",
              "pattern", patterns, settings),
          const SizedBox(height: 6),
          _buildSection(context, "FIELD_DISCIPLINES (${fields.length})",
              "field", fields, settings),

          const SizedBox(height: 24),
          // ─── CATEGORY: MOVEMENT LIBRARY ───
          _buildCategoryDivider(context, "MOVEMENT LIBRARY", "1 SECTION"),
          const SizedBox(height: 12),
          _buildSection(context, "EXERCISE_NAMES (${exerciseNames.length})",
              "movement", exerciseNames, settings),

          // Bottom padding for nav bar
          const SizedBox(height: 80),
        ],
      ),
      bottomNavigationBar: const LabFooter(),
    );
  }

  Widget _buildCategoryDivider(
      BuildContext context, String title, String badge) {
    return Container(
      padding: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
              color: LabColors.primary.withValues(alpha: 0.15), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(width: 3, height: 16, color: LabColors.primary),
          const SizedBox(width: 10),
          Text(title,
              style: LabStyles.mono(context,
                  fontSize: 11,
                  color: LabColors.primary,
                  fontWeight: FontWeight.bold)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: LabColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(badge,
                style: LabStyles.mono(context,
                    fontSize: 8, color: LabColors.primaryDim)),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String key,
      List<String> items, Map<String, ThemeSetting> settings,
      {Map<String, Color>? defaults}) {
    final isExpanded = _expandedSections[key] ?? false;
    final query = _searchControllers[key]!.text.toLowerCase();

    final filteredItems =
        items.where((i) => i.toLowerCase().contains(query)).toList();

    return Column(
      children: [
        _buildCategoryHeader(context, title, key, isExpanded),
        if (isExpanded) ...[
          const SizedBox(height: 8),
          _buildSearchField(context, key),
          const SizedBox(height: 8),
          _buildColorTable(context, filteredItems, key, settings,
              defaults: defaults),
        ],
      ],
    );
  }

  Widget _buildValueSection(BuildContext context, String title, String key,
      List<String> items, Map<String, ThemeSetting> settings) {
    final isExpanded = _expandedSections[key] ?? false;
    final query = _searchControllers[key]!.text.toLowerCase();

    final filteredItems =
        items.where((i) => i.toLowerCase().contains(query)).toList();

    return Column(
      children: [
        _buildCategoryHeader(context, title, key, isExpanded),
        if (isExpanded) ...[
          const SizedBox(height: 8),
          _buildSearchField(context, key),
          const SizedBox(height: 8),
          _buildValueTable(context, filteredItems, key, settings),
        ],
      ],
    );
  }

  Widget _buildSearchField(BuildContext context, String key) {
    return Container(
      decoration: BoxDecoration(
        color: LabColors.surfaceContainerLowest,
        border: Border.all(
            color: LabColors.cyanBorder.withValues(alpha: 0.25), width: 0.5),
        borderRadius: BorderRadius.circular(2),
      ),
      child: TextField(
        controller: _searchControllers[key],
        style: LabStyles.mono(context, fontSize: 10, color: Colors.white70),
        decoration: InputDecoration(
          hintText: "SEARCH / ${key.toUpperCase()}...",
          hintStyle:
              LabStyles.mono(context, fontSize: 10, color: Colors.grey[700]),
          prefixIcon: Icon(Icons.search,
              size: 13, color: LabColors.primary.withValues(alpha: 0.6)),
          isDense: true,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
        onChanged: (v) => setState(() {}),
      ),
    );
  }

  Widget _buildCategoryHeader(
      BuildContext context, String title, String key, bool expanded) {
    return InkWell(
      onTap: () => setState(() => _expandedSections[key] = !expanded),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color:
              expanded ? LabColors.surfaceContainerLow : LabColors.surfaceDim,
          border: Border(
            left: BorderSide(
                color: expanded
                    ? LabColors.primary
                    : LabColors.cyanBorder.withValues(alpha: 0.3),
                width: expanded ? 3 : 1),
            right: BorderSide(
                color: LabColors.cyanBorder
                    .withValues(alpha: expanded ? 0.5 : 0.2),
                width: 0.5),
            top: BorderSide(
                color: LabColors.cyanBorder
                    .withValues(alpha: expanded ? 0.5 : 0.2),
                width: 0.5),
            bottom: BorderSide(
                color: LabColors.cyanBorder
                    .withValues(alpha: expanded ? 0.5 : 0.2),
                width: 0.5),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  expanded ? Icons.chevron_right : Icons.chevron_left,
                  size: 14,
                  color: expanded ? LabColors.primary : Colors.grey,
                ),
                const SizedBox(width: 6),
                Text(title,
                    style: LabStyles.mono(context,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: expanded ? LabColors.primary : Colors.grey)),
              ],
            ),
            Icon(expanded ? Icons.expand_less : Icons.expand_more,
                size: 16, color: expanded ? LabColors.primary : Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildColorTable(BuildContext context, List<String> items,
      String prefix, Map<String, ThemeSetting> settings,
      {Map<String, Color>? defaults}) {
    if (items.isEmpty) {
      if (prefix == 'wo_batch') {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: LabColors.surfaceContainerLowest,
            border: Border.all(
                color: LabColors.cyanBorder.withValues(alpha: 0.15),
                width: 0.5),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline,
                  size: 14, color: LabColors.primary.withValues(alpha: 0.5)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "NO BATCHES YET — Create workout sets with a batch name in complex_metadata to register colors here.",
                  style: LabStyles.mono(context,
                      fontSize: 9, color: Colors.grey[600]),
                ),
              ),
            ],
          ),
        );
      }
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text("NO_ITEMS",
              style: LabStyles.mono(context,
                  fontSize: 10, color: Colors.grey[700])),
        ),
      );
    }

    final controller = ref.read(themeControllerProvider);
    return Table(
      columnWidths: const {0: FlexColumnWidth(3), 1: FlexColumnWidth(1)},
      border: TableBorder.all(
          color: LabColors.cyanBorder.withValues(alpha: 0.15), width: 0.5),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: items.map((item) {
        final String effectivePrefix;
        if (prefix == 'utility') {
          effectivePrefix = 'UTILITY';
        } else if (prefix == 'wo_batch') {
          effectivePrefix = 'UI_TAG_BATCH';
        } else if ([
          'wo_header',
          'wo_filters',
          'wo_tags',
          'wo_priority',
          'unilateral',
          'eorm'
        ].contains(prefix)) {
          effectivePrefix = 'UI';
        } else {
          effectivePrefix = prefix.toUpperCase();
        }
        final key = "${effectivePrefix}_$item";
        final color = controller.getColor(settings, key,
            defaultColor: defaults?[item], nameSeed: item);
        final hexStr =
            '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
        return TableRow(
          decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(
                    color: LabColors.cyanBorder.withValues(alpha: 0.08),
                    width: 0.5)),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(item.replaceAll('TAG_', '').toUpperCase(),
                        style: LabStyles.mono(context, fontSize: 11)),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color:
                          LabColors.surfaceContainerHigh.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(hexStr,
                        style: LabStyles.mono(context,
                            fontSize: 7, color: Colors.grey[500])),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: () => _showColorPicker(context, key, color),
              child: Container(
                height: 36,
                margin: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color,
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15), width: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildValueTable(BuildContext context, List<String> items,
      String prefix, Map<String, ThemeSetting> settings) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text("NO_ITEMS",
              style: LabStyles.mono(context,
                  fontSize: 10, color: Colors.grey[700])),
        ),
      );
    }

    final controller = ref.read(themeControllerProvider);
    return Table(
      columnWidths: const {0: FlexColumnWidth(1), 1: FlexColumnWidth(2)},
      border: TableBorder.all(
          color: LabColors.cyanBorder.withValues(alpha: 0.15), width: 0.5),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: items.map((item) {
        final key = "${prefix.toUpperCase()}_$item";
        final value = controller.getValue(settings, key) ?? "";
        final fileName =
            value.isNotEmpty ? value.split('/').last : "EMPTY_REFERENCE";

        return TableRow(
          decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(
                    color: LabColors.cyanBorder.withValues(alpha: 0.08),
                    width: 0.5)),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Text(item.toUpperCase(),
                  style: LabStyles.mono(context, fontSize: 11)),
            ),
            Padding(
              padding: const EdgeInsets.all(6),
              child: InkWell(
                onTap: () async {
                  final result =
                      await FilePicker.platform.pickFiles(type: FileType.image);
                  if (result != null && result.files.single.path != null) {
                    await controller.setValue(key, result.files.single.path!);
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: LabColors.surfaceContainerLowest,
                    border: Border.all(
                        color: LabColors.cyanBorder.withValues(alpha: 0.4),
                        width: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.image_search,
                          size: 13,
                          color: LabColors.primary.withValues(alpha: 0.6)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          fileName,
                          style: LabStyles.mono(context,
                              fontSize: 8,
                              color: value.isNotEmpty
                                  ? Colors.white70
                                  : Colors.grey[600]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (value.isNotEmpty)
                        GestureDetector(
                          onTap: () => controller.setValue(key, ""),
                          child: Icon(Icons.close,
                              size: 13,
                              color: Colors.redAccent.withValues(alpha: 0.7)),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  void _showColorPicker(BuildContext context, String key, Color initialColor) {
    setState(() => _pickerColor = initialColor);
    showModalBottomSheet(
      context: context,
      backgroundColor: LabColors.surfaceContainerHigh,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.8,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) => SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("COLOR_SELECTOR // ${key.toUpperCase()}",
                    style: LabStyles.mono(context, color: LabColors.primary)),
                const SizedBox(height: 24),
                GridView.count(
                  crossAxisCount: 5,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: NeonPalette.colors
                      .map((c) => InkWell(
                            onTap: () {
                              setModalState(() => _pickerColor = c);
                              ref
                                  .read(themeControllerProvider)
                                  .setColor(key, c);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: c,
                                border: Border.all(
                                    color: _pickerColor == c
                                        ? Colors.white
                                        : Colors.transparent,
                                    width: 2),
                              ),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("RGB_MANUAL_TUNING",
                        style: LabStyles.mono(context,
                            fontSize: 10, color: Colors.grey)),
                    Container(
                      width: 40,
                      height: 20,
                      decoration: BoxDecoration(
                        color: _pickerColor,
                        border: Border.all(color: Colors.white, width: 0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildRGBSlider(context, "R", (_pickerColor.r * 255).toInt(),
                    (v) {
                  final newColor = _pickerColor.withValues(red: v / 255.0);
                  setModalState(() => _pickerColor = newColor);
                  ref.read(themeControllerProvider).setColor(key, newColor);
                }),
                _buildRGBSlider(context, "G", (_pickerColor.g * 255).toInt(),
                    (v) {
                  final newColor = _pickerColor.withValues(green: v / 255.0);
                  setModalState(() => _pickerColor = newColor);
                  ref.read(themeControllerProvider).setColor(key, newColor);
                }),
                _buildRGBSlider(context, "B", (_pickerColor.b * 255).toInt(),
                    (v) {
                  final newColor = _pickerColor.withValues(blue: v / 255.0);
                  setModalState(() => _pickerColor = newColor);
                  ref.read(themeControllerProvider).setColor(key, newColor);
                }),
                const SizedBox(height: 24),
                Text("TRANSPARENCY_TUNING",
                    style: LabStyles.mono(context,
                        fontSize: 10, color: Colors.grey)),
                const SizedBox(height: 16),
                _buildValueSlider(
                    context, "TRNS%", ((1 - _pickerColor.a) * 100).toInt(), 100,
                    (v) {
                  final newColor =
                      _pickerColor.withValues(alpha: (100 - v) / 100.0);
                  setModalState(() => _pickerColor = newColor);
                  ref.read(themeControllerProvider).setColor(key, newColor);
                }),
                const SizedBox(height: 32),
                LabButton(
                    label: "APPLY_CONFIGURATION",
                    onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildValueSlider(BuildContext context, String label, int value,
      double max, Function(double) onChanged) {
    return Row(
      children: [
        SizedBox(
            width: 45,
            child: Text(label,
                style: LabStyles.mono(context,
                    fontSize: 10, color: LabColors.primary))),
        Expanded(
          child: Slider(
            value: value.toDouble().clamp(0, max),
            min: 0,
            max: max,
            activeColor: LabColors.primary,
            inactiveColor: LabColors.surfaceBright,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            value.toString().padLeft(3, '0'),
            style: LabStyles.mono(context, fontSize: 10),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildRGBSlider(BuildContext context, String label, int value,
      Function(double) onChanged) {
    return Row(
      children: [
        SizedBox(
            width: 20,
            child: Text(label,
                style: LabStyles.mono(context, color: LabColors.primary))),
        Expanded(
          child: Slider(
            value: value.toDouble(),
            min: 0,
            max: 255,
            activeColor: LabColors.primary,
            inactiveColor: LabColors.surfaceBright,
            onChanged: onChanged,
          ),
        ),
        Text(value.toString().padLeft(3, '0'),
            style: LabStyles.mono(context, fontSize: 10)),
      ],
    );
  }
}
