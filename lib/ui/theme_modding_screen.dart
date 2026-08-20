import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/theme_provider.dart';
import '../providers/database_provider.dart';
import '../database/database.dart';
import '../localization/strings.dart';
import 'styles.dart';
import 'lab_widgets.dart';

// A single customizable color (or, for `isValueType` sections, file-path
// value) group shown as one expandable swatch-grid card in the modding
// screen.
class _ThemeSection {
  final String title;
  final String key;
  final List<String> items;
  final Map<String, Color>? defaults;
  final bool isValueType;
  const _ThemeSection(this.title, this.key, this.items,
      {this.defaults, this.isValueType = false});
}

// A top-level grouping of sections, rendered as one tab.
class _ThemeCategory {
  final String title;
  final List<_ThemeSection> sections;
  const _ThemeCategory(this.title, this.sections);
}

class ThemeModdingScreen extends ConsumerStatefulWidget {
  const ThemeModdingScreen({super.key});

  @override
  ConsumerState<ThemeModdingScreen> createState() => _ThemeModdingScreenState();
}

class _ThemeModdingScreenState extends ConsumerState<ThemeModdingScreen>
    with SingleTickerProviderStateMixin {
  static const int _categoryCount = 4;
  static const int _pageSize = 25;

  Color _pickerColor = Colors.cyan;
  // Current page (25 items/page) per section — keeps huge sections like
  // EXERCISE_NAMES (180+ movements) from rendering everything at once.
  final Map<String, int> _sectionPage = {};
  late final TabController _tabController =
      TabController(length: _categoryCount, vsync: this);

  // Single source of truth for every section key (used for expand-state).
  static const List<String> _allSectionKeys = [
    "wo_header",
    "wo_filters",
    "wo_tags",
    "wo_priority",
    "wo_batch",
    "injection",
    "unilateral",
    "eorm",
    "dashboard_card",
    "footer",
    "nexus",
    "wallpaper",
    "utility",
    "superset",
    "muscle",
    "pattern",
    "field",
    "movement",
    "nomenclature",
  ];

  // State for collapsible section cards within a tab.
  final Map<String, bool> _expandedSections = {
    for (final k in _allSectionKeys) k: false,
  };

  // One search box per category tab — filters across every section in that
  // tab at once and auto-expands any section with a match, instead of
  // requiring you to open a section before you can search inside it.
  final List<TextEditingController> _tabSearchControllers =
      List.generate(_categoryCount, (_) => TextEditingController());

  @override
  void dispose() {
    _tabController.dispose();
    for (var c in _tabSearchControllers) {
      c.dispose();
    }
    super.dispose();
  }

  // Resolves a section-key + item into the actual `theme_settings` DB key.
  // Centralizes the prefix quirks so the swatch grid doesn't repeat them.
  String _resolveThemeKey(String prefix, String item) {
    final String effectivePrefix;
    if (prefix == 'utility') {
      // Real consumers (workout_manager.dart, WB.editor.dart,
      // export_service.dart) read PRIORITY_<value>, not UTILITY_<value>.
      effectivePrefix = 'PRIORITY';
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
    } else if ([
      'muscle',
      'pattern',
      'field',
      'movement',
    ].contains(prefix)) {
      // Real consumers (performance_dashboard.dart, timeline_screen.dart,
      // timeline_calendar_screen.dart) read lowercase "<prefix>_<value>".
      effectivePrefix = prefix;
    } else {
      effectivePrefix = prefix.toUpperCase();
    }
    return "${effectivePrefix}_$item";
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider).value ?? 'en';
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
      "TAG_SOMATIC_ANOMALY", // Set card: [ + ] SOMATIC ANOMALY button
      "TAG_SOMATIC_RECOVERY", // Set card: [ + ] SOMATIC RECOVERY button
      "TAG_ADD_SET_NOTES", // Set card: [ + ] ADD SET NOTES toggle
      "TAG_PR_HIGHLIGHT", // Set card: PR label when a set is a personal record
      "TAG_SESSION_TOTAL", // Performance Overview: SESIÓN TOTAL label + value
      "TAG_MODULE_BORDER", // Exercise module: default border (no utility tag)
      "TAG_SETROW_EXPANDED", // Set row: border/glow when expanded
      "TAG_SUMMARY_BORDER", // Tonnage/eORM/VP summary box border
      "TAG_SESSION_NOTES", // Session Notes header + Add Note button
    ];
    final Map<String, Color> woHeaderDefaults = {
      "TAG_SOMATIC_ANOMALY": Colors.redAccent,
      "TAG_SOMATIC_RECOVERY": Colors.greenAccent,
      "TAG_ADD_SET_NOTES": const Color(0xFF2979FF),
      "TAG_PR_HIGHLIGHT": const Color(0xFFE0242F),
      "TAG_SESSION_TOTAL": LabColors.accent,
      "TAG_MODULE_BORDER": LabColors.cyanBorder,
      "TAG_SETROW_EXPANDED": LabColors.primary,
      "TAG_SUMMARY_BORDER": LabColors.cyanBorder,
      "TAG_SESSION_NOTES": LabColors.accent,
    };

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
      "TAG_BANDED",
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
      "DT.PRCSR",
      "DT.PRCSR_BG",
      "NEXUS",
      "NEXUS_BG",
      "DATASET",
      "DATASET_BG",
      "THEME.MDFYR",
      "THEME.MDFYR_BG",
      "PLANNING",
      "PLANNING_BG",
      "DB.EDIT",
      "DB.EDIT_BG",
      "SOMATIC_SPECTRUM",
      "SOMATIC_SPECTRUM_BG",
      "APP.CONFIG",
      "APP.CONFIG_BG",
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
      "DT.PRCSR": LabColors.visualsNeon,
      "DT.PRCSR_BG": LabColors.visualsNeon.withValues(alpha: 0.08),
      "NEXUS": LabColors.nexusPurple,
      "NEXUS_BG": LabColors.nexusPurple.withValues(alpha: 0.08),
      "DATASET": LabColors.datasetGold,
      "DATASET_BG": LabColors.datasetGold.withValues(alpha: 0.08),
      "THEME.MDFYR": LabColors.themeWhite,
      "THEME.MDFYR_BG": LabColors.themeWhite.withValues(alpha: 0.08),
      "PLANNING": LabColors.secondary,
      "PLANNING_BG": LabColors.secondary.withValues(alpha: 0.08),
      "DB.EDIT": LabColors.tertiary,
      "DB.EDIT_BG": LabColors.tertiary.withValues(alpha: 0.08),
      "SOMATIC_SPECTRUM": LabColors.supersetBlockDefault,
      "SOMATIC_SPECTRUM_BG":
          LabColors.supersetBlockDefault.withValues(alpha: 0.08),
      "APP.CONFIG": LabColors.onSurfaceVariant,
      "APP.CONFIG_BG": LabColors.onSurfaceVariant.withValues(alpha: 0.08),
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

    // ── NOMENCLATURE PIECE COLORS (EDIT_EXERCISE / EXERCISE_CREATOR) ──
    final Map<String, Color> nomenclatureDefaults = {
      "BODY_POSITION": Colors.blueAccent,
      "IMPLEMENTS": Colors.orangeAccent,
      "PREFIXES": LabColors.primary,
      "NAME": Colors.white,
      "SUFFIXES": LabColors.primary,
      "ASSISTANCE": Colors.tealAccent,
    };

    final List<String> supersetItems = settings.keys
        .where((k) => k.startsWith("SUPERSET_"))
        .map((k) => k.replaceFirst("SUPERSET_", ""))
        .toList()
      ..sort();

    final List<_ThemeCategory> categories = [
      _ThemeCategory(tr(lang, "WORKOUT"), [
        _ThemeSection(tr(lang, "HEADER & OPTS"), "wo_header", woHeaderUI,
            defaults: woHeaderDefaults),
        _ThemeSection(tr(lang, "TAG FILTERS"), "wo_filters", woFilterUI),
        _ThemeSection(tr(lang, "KNS TAG LABELS"), "wo_tags", woTagUI),
        _ThemeSection(tr(lang, "UTILS"), "wo_priority", woPriorityUI),
        _ThemeSection(tr(lang, "BATCH COLORS"), "wo_batch", woBatchUI),
        _ThemeSection(tr(lang, "INJECTION TYPE COLORS"), "injection", injectionUI,
            defaults: injectionDefaults),
      ]),
      _ThemeCategory(tr(lang, "GLOBAL"), [
        _ThemeSection("UNILATERAL_SIDE_COLORS", "unilateral", unilateralUI),
        _ThemeSection("EORM_HIGHLIGHTS", "eorm", eormUI),
        _ThemeSection("HOME_DASHBOARD_CARDS", "dashboard_card", dashboardItems,
            defaults: dashboardDefaults),
        _ThemeSection("QUICK_SWITCHER_UI", "footer", footerItems,
            defaults: footerDefaults),
        _ThemeSection("NEXUS_EXCHANGE_COLORS", "nexus", nexusUI,
            defaults: nexusDefaults),
      ]),
      _ThemeCategory(tr(lang, "DATA"), [
        _ThemeSection("NOMENCLATURE_COLORS", "nomenclature", kDefaultNamePieceOrder,
            defaults: nomenclatureDefaults),
        _ThemeSection("VISUAL_ATMOSPHERE", "wallpaper", screens,
            isValueType: true),
        _ThemeSection("MOVEMENT_UTILITIES", "utility", utilities),
        _ThemeSection("SUPERSET_BLOCKS", "superset", supersetItems),
        _ThemeSection("MUSCLE_GROUPS", "muscle", muscles),
        _ThemeSection("MOVEMENT_PATTERNS", "pattern", patterns),
        _ThemeSection("FIELD_DISCIPLINES", "field", fields),
      ]),
      _ThemeCategory(tr(lang, "LIBRARY"), [
        _ThemeSection("EXERCISE_NAMES", "movement", exerciseNames),
      ]),
    ];

    return Scaffold(
      backgroundColor: LabColors.background,
      appBar: AppBar(
        backgroundColor: LabColors.background,
        title: Text(tr(lang, "THEME.MDFYR"),
            style: LabStyles.mono(context, fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: LabColors.primary),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: LabColors.primary,
          indicatorWeight: 2,
          labelColor: LabColors.primary,
          unselectedLabelColor: Colors.grey[600],
          labelStyle:
              LabStyles.mono(context, fontSize: 10, fontWeight: FontWeight.bold),
          unselectedLabelStyle: LabStyles.mono(context, fontSize: 10),
          tabs: categories.map((c) => Tab(text: c.title)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          for (int i = 0; i < categories.length; i++)
            _buildCategoryTab(context, categories[i], i, settings, lang),
        ],
      ),
      bottomNavigationBar: const LabFooter(),
    );
  }

  Widget _buildCategoryTab(BuildContext context, _ThemeCategory category,
      int tabIndex, Map<String, ThemeSetting> settings, String lang) {
    final query = _tabSearchControllers[tabIndex].text.toLowerCase();
    final isSearching = query.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildTabSearchField(context, tabIndex, category.title, lang),
        const SizedBox(height: 16),
        for (final section in category.sections)
          Builder(builder: (context) {
            final filtered = isSearching
                ? section.items
                    .where((i) => i.toLowerCase().contains(query))
                    .toList()
                : section.items;
            if (isSearching && filtered.isEmpty) {
              return const SizedBox.shrink();
            }
            final expanded =
                isSearching ? true : (_expandedSections[section.key] ?? false);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildSectionCard(
                  context, section, filtered, expanded, isSearching, settings, lang),
            );
          }),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildTabSearchField(
      BuildContext context, int tabIndex, String categoryTitle, String lang) {
    return Container(
      decoration: BoxDecoration(
        color: LabColors.surfaceContainerLowest,
        border: Border.all(
            color: LabColors.cyanBorder.withValues(alpha: 0.3), width: 0.5),
      ),
      child: TextField(
        controller: _tabSearchControllers[tabIndex],
        style: LabStyles.mono(context, fontSize: 11, color: Colors.white70),
        decoration: InputDecoration(
          hintText: "${tr(lang, 'SEARCH')} $categoryTitle...",
          hintStyle:
              LabStyles.mono(context, fontSize: 11, color: Colors.grey[700]),
          prefixIcon: Icon(Icons.search,
              size: 15, color: LabColors.primary.withValues(alpha: 0.6)),
          isDense: true,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        ),
        onChanged: (v) => setState(() {}),
      ),
    );
  }

  Widget _buildSectionCard(
      BuildContext context,
      _ThemeSection section,
      List<String> filteredItems,
      bool expanded,
      bool forceExpanded,
      Map<String, ThemeSetting> settings,
      String lang) {
    return Container(
      decoration: BoxDecoration(
        color: LabColors.surfaceDim,
        border: Border(
          top: BorderSide(
              color: expanded
                  ? LabColors.primary
                  : LabColors.cyanBorder.withValues(alpha: 0.25),
              width: expanded ? 2 : 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: forceExpanded
                ? null
                : () => setState(
                    () => _expandedSections[section.key] = !expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${section.title} (${filteredItems.length})',
                      style: LabStyles.mono(context,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color:
                              expanded ? LabColors.primary : Colors.grey[400])),
                  if (!forceExpanded)
                    Icon(expanded ? Icons.expand_less : Icons.expand_more,
                        size: 18,
                        color: expanded ? LabColors.primary : Colors.grey),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: section.isValueType
                  ? _buildValueList(
                      context, filteredItems, section.key, settings, lang)
                  : _buildSwatchGrid(
                      context, filteredItems, section.key, settings, lang,
                      defaults: section.defaults),
            ),
        ],
      ),
    );
  }

  Widget _buildSwatchGrid(BuildContext context, List<String> items,
      String prefix, Map<String, ThemeSetting> settings, String lang,
      {Map<String, Color>? defaults}) {
    if (items.isEmpty) {
      if (prefix == 'wo_batch') {
        return Container(
          padding: const EdgeInsets.all(16),
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
                  tr(lang,
                      "NO BATCHES YET — Create workout sets with a batch name in complex_metadata to register colors here."),
                  style: LabStyles.mono(context,
                      fontSize: 9, color: Colors.grey[600]),
                ),
              ),
            ],
          ),
        );
      }
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(tr(lang, "NO_ITEMS"),
              style: LabStyles.mono(context,
                  fontSize: 10, color: Colors.grey[700])),
        ),
      );
    }

    final controller = ref.read(themeControllerProvider);
    final totalPages = (items.length / _pageSize).ceil();
    final currentPage =
        totalPages == 0 ? 0 : (_sectionPage[prefix] ?? 0).clamp(0, totalPages - 1);
    final pageItems = totalPages <= 1
        ? items
        : items.skip(currentPage * _pageSize).take(_pageSize).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 14,
            crossAxisSpacing: 10,
            childAspectRatio: 0.82,
          ),
          itemCount: pageItems.length,
          itemBuilder: (context, index) {
            final item = pageItems[index];
            final key = _resolveThemeKey(prefix, item);
            final color = controller.getColor(settings, key,
                defaultColor: defaults?[item], nameSeed: item);
            final hexStr =
                '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
            final isBg = item.endsWith('_BG');
            final baseItem = isBg ? item.substring(0, item.length - 3) : item;
            final translatedItem = tr(lang, baseItem) + (isBg ? '_BG' : '');
            final label = translatedItem.replaceAll('TAG_', '').toUpperCase();
            return InkWell(
              onTap: () => _showColorPicker(context, key, color, lang),
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: color,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                            width: 0.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: LabStyles.mono(context,
                          fontSize: 9, color: Colors.white)),
                  Text(hexStr,
                      style: LabStyles.mono(context,
                          fontSize: 7, color: Colors.grey[500])),
                ],
              ),
            );
          },
        ),
        if (totalPages > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: currentPage > 0
                    ? () => setState(() => _sectionPage[prefix] = currentPage - 1)
                    : null,
                icon: const Icon(Icons.chevron_left, size: 20),
                color: LabColors.primary,
              ),
              Text('${currentPage + 1} / $totalPages',
                  style:
                      LabStyles.mono(context, fontSize: 10, color: Colors.grey[400])),
              IconButton(
                onPressed: currentPage < totalPages - 1
                    ? () => setState(() => _sectionPage[prefix] = currentPage + 1)
                    : null,
                icon: const Icon(Icons.chevron_right, size: 20),
                color: LabColors.primary,
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildValueList(BuildContext context, List<String> items,
      String prefix, Map<String, ThemeSetting> settings, String lang) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(tr(lang, "NO_ITEMS"),
              style: LabStyles.mono(context,
                  fontSize: 10, color: Colors.grey[700])),
        ),
      );
    }

    final controller = ref.read(themeControllerProvider);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final key = "${prefix.toUpperCase()}_$item";
        final value = controller.getValue(settings, key) ?? "";
        final fileName = value.isNotEmpty
            ? value.split('/').last
            : tr(lang, "EMPTY_REFERENCE");
        return InkWell(
          onTap: () async {
            final result =
                await FilePicker.platform.pickFiles(type: FileType.image);
            if (result != null && result.files.single.path != null) {
              await controller.setValue(key, result.files.single.path!);
            }
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: LabColors.surfaceContainerLowest,
                border: Border.all(
                    color: LabColors.cyanBorder.withValues(alpha: 0.35),
                    width: 0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.image_search,
                      size: 12, color: LabColors.primary.withValues(alpha: 0.6)),
                  const SizedBox(width: 6),
                  Text(item.toUpperCase(),
                      style: LabStyles.mono(context,
                          fontSize: 8, color: Colors.grey[400])),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(fileName,
                        overflow: TextOverflow.ellipsis,
                        style: LabStyles.mono(context,
                            fontSize: 8,
                            color: value.isNotEmpty
                                ? Colors.white70
                                : Colors.grey[600])),
                  ),
                  if (value.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => controller.setValue(key, ""),
                      child: Icon(Icons.close,
                          size: 12,
                          color: Colors.redAccent.withValues(alpha: 0.7)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showColorPicker(
      BuildContext context, String key, Color initialColor, String lang) {
    setState(() => _pickerColor = initialColor);
    showModalBottomSheet(
      context: context,
      backgroundColor: LabColors.surfaceContainerHigh,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) => SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${tr(lang, "COLOR_SELECTOR")} // ${key.toUpperCase()}",
                    style: LabStyles.mono(context,
                        fontSize: 11, color: LabColors.primary)),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 5,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  childAspectRatio: 1.4,
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
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(tr(lang, "RGB_MANUAL_TUNING"),
                        style: LabStyles.mono(context,
                            fontSize: 9, color: Colors.grey)),
                    Container(
                      width: 36,
                      height: 18,
                      decoration: BoxDecoration(
                        color: _pickerColor,
                        border: Border.all(color: Colors.white, width: 0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 30,
                  child: _buildRGBSlider(
                      context, "R", (_pickerColor.r * 255).toInt(), (v) {
                    final newColor = _pickerColor.withValues(red: v / 255.0);
                    setModalState(() => _pickerColor = newColor);
                    ref.read(themeControllerProvider).setColor(key, newColor);
                  }),
                ),
                SizedBox(
                  height: 30,
                  child: _buildRGBSlider(
                      context, "G", (_pickerColor.g * 255).toInt(), (v) {
                    final newColor = _pickerColor.withValues(green: v / 255.0);
                    setModalState(() => _pickerColor = newColor);
                    ref.read(themeControllerProvider).setColor(key, newColor);
                  }),
                ),
                SizedBox(
                  height: 30,
                  child: _buildRGBSlider(
                      context, "B", (_pickerColor.b * 255).toInt(), (v) {
                    final newColor = _pickerColor.withValues(blue: v / 255.0);
                    setModalState(() => _pickerColor = newColor);
                    ref.read(themeControllerProvider).setColor(key, newColor);
                  }),
                ),
                const SizedBox(height: 8),
                Text(tr(lang, "TRANSPARENCY_TUNING"),
                    style: LabStyles.mono(context,
                        fontSize: 9, color: Colors.grey)),
                const SizedBox(height: 4),
                SizedBox(
                  height: 30,
                  child: _buildValueSlider(context, "TRNS%",
                      ((1 - _pickerColor.a) * 100).toInt(), 100, (v) {
                    final newColor =
                        _pickerColor.withValues(alpha: (100 - v) / 100.0);
                    setModalState(() => _pickerColor = newColor);
                    ref.read(themeControllerProvider).setColor(key, newColor);
                  }),
                ),
                const SizedBox(height: 14),
                LabButton(
                    label: tr(lang, "APPLY_CONFIGURATION"),
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
