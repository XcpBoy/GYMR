import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:intl/intl.dart';
import '../providers/database_provider.dart';
import '../database/database.dart';
import 'styles.dart';
import 'lab_widgets.dart';
import 'main_scaffold.dart';

class AnthropometricDataScreen extends ConsumerStatefulWidget {
  const AnthropometricDataScreen({super.key});

  @override
  ConsumerState<AnthropometricDataScreen> createState() => _AnthropometricDataScreenState();
}

class _AnthropometricDataScreenState extends ConsumerState<AnthropometricDataScreen> {
  final TextEditingController _labelController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();
  String _selectedUnit = 'cm';
  bool _isFlexed = false;
  bool _isPumped = false; // NEW
  DateTime _selectedDate = DateTime.now();
  int _activeTab = 0; // 0: Weight, 1: Measurements

  // Old rows can predate a column (e.g. created_at was added later with no
  // backfill), leaving a stray NULL that Drift's typed `db.select(...)`
  // decoder can't handle — it throws "Null check operator used on a null
  // value" and kills the WHOLE query, not just that row. Read raw and
  // null-coalesce every field instead, so one bad historical row can't take
  // the rest of the list down with it.
  Stream<List<AnthropometricLog>> _watchLogs(AppDatabase db,
      {required bool weightOnly}) {
    final whereSql = weightOnly ? "label = 'WEIGHT'" : "label != 'WEIGHT'";
    return db.customSelect(
      'SELECT id, date, label, value, unit, is_flexed, is_pumped, created_at '
      'FROM anthropometric_logs WHERE $whereSql ORDER BY date DESC',
      readsFrom: {db.anthropometricLogs},
    ).watch().map((rows) => rows.map((row) {
          final rawDate = row.data['date'] as int?;
          final rawCreatedAt = row.data['created_at'] as int?;
          return AnthropometricLog(
            id: row.data['id'] as int,
            date: rawDate != null
                ? DateTime.fromMillisecondsSinceEpoch(rawDate * 1000)
                : DateTime.now(),
            label: (row.data['label'] as String?) ?? '',
            value: (row.data['value'] as num?)?.toDouble() ?? 0,
            unit: (row.data['unit'] as String?) ?? '',
            isFlexed: (row.data['is_flexed'] as int?) == 1,
            isPumped: (row.data['is_pumped'] as int?) == 1,
            createdAt: rawCreatedAt != null
                ? DateTime.fromMillisecondsSinceEpoch(rawCreatedAt * 1000)
                : DateTime.now(),
          );
        }).toList());
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);

    // We use the same table but filter by 'WEIGHT' label for tab 0
    final logsStream = _watchLogs(db, weightOnly: _activeTab == 0);

    return MainScaffold(
      title: 'ANTHROPOMETRIC DATA',
      body: Column(
        children: [
          _buildTabSelector(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildInputSection(context),
                const SizedBox(height: 32),
                Text('HISTORICAL_METRICS_FEED', style: LabStyles.mono(context, color: LabColors.primary, fontSize: 10)),
                const SizedBox(height: 16),
                StreamBuilder<List<AnthropometricLog>>(
                  stream: logsStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      debugPrint('[ANTRPMT_DT] query error: ${snapshot.error}');
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'QUERY_ERROR:\n${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: LabStyles.mono(context,
                                color: Colors.redAccent, fontSize: 10),
                          ),
                        ),
                      );
                    }
                    if (!snapshot.hasData) {
                      return Center(
                          child: Text('LOADING...',
                              style: LabStyles.mono(context,
                                  color: Colors.grey)));
                    }
                    final logs = snapshot.data!;
                    if (logs.isEmpty) return Center(child: Text('NO_METRICS_FOUND', style: LabStyles.mono(context, color: Colors.grey)));
                    return Column(
                      children: logs.map((log) => _buildMetricCard(context, log)).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const LabFooter(),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      height: 50,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: LabColors.cyanBorder, width: 0.5)),
      ),
      child: Row(
        children: [
          _buildTabItem('01. BODY_WEIGHT', 0),
          _buildTabItem('02. MEASUREMENTS', 1),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, int index) {
    final isActive = _activeTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() {
          _activeTab = index;
          _selectedUnit = index == 0 ? 'kg' : 'cm';
        }),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? LabColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            style: LabStyles.mono(context, 
              fontSize: 10, 
              fontWeight: FontWeight.bold,
              color: isActive ? LabColors.primary : Colors.grey
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputSection(BuildContext context) {
    final isWeightTab = _activeTab == 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: LabStyles.hairlineBorder(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isWeightTab ? 'NEW_WEIGHT_LOG' : 'NEW_METRIC_INJECTION', style: LabStyles.mono(context, color: LabColors.accent, fontSize: 10)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                      builder: (context, child) => Theme(
                        data: ThemeData.dark().copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: LabColors.primary,
                            onPrimary: Colors.black,
                            surface: LabColors.background,
                            onSurface: Colors.white,
                          ), dialogTheme: const DialogThemeData(backgroundColor: LabColors.background),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) setState(() => _selectedDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    decoration: BoxDecoration(border: Border.all(color: LabColors.primary, width: 0.5)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(DateFormat('dd / MMM / yyyy').format(_selectedDate).toUpperCase(), style: LabStyles.mono(context, fontSize: 12)),
                        const Icon(Icons.calendar_today, size: 16, color: LabColors.primary),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (!isWeightTab) ...[
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: LabTextField(
                    controller: _labelController,
                    label: 'METRIC_LABEL (e.g. BICEP, CHEST)',
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _showLabelPicker,
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        border: Border.all(color: LabColors.primary, width: 0.5)),
                    child: const Icon(Icons.list, size: 18, color: LabColors.primary),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: LabTextField(controller: _valueController, label: 'VALUE', keyboardType: TextInputType.number)),
              const SizedBox(width: 12),
              _buildUnitToggle(),
            ],
          ),
          if (!isWeightTab) ...[
            const SizedBox(height: 12),
            _buildExtraToggles(),
          ],
          const SizedBox(height: 24),
          LabButton(
            label: isWeightTab ? 'Save Weight' : 'Inject Metric',
            onPressed: _saveMetric,
            color: LabColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildUnitToggle() {
    // Removed '%' option
    final units = _activeTab == 0 ? ['kg', 'lb'] : ['cm', 'in'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('UNIT', style: LabStyles.mono(context, fontSize: 8, color: Colors.grey)),
        const SizedBox(height: 4),
        Row(
          children: units.map((u) => InkWell(
            onTap: () => setState(() => _selectedUnit = u),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _selectedUnit == u ? LabColors.primary : Colors.transparent,
                border: Border.all(color: LabColors.primary, width: 0.5),
              ),
              child: Text(u.toUpperCase(), style: LabStyles.mono(context, fontSize: 10, color: _selectedUnit == u ? Colors.black : LabColors.primary)),
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildExtraToggles() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('FLEXED_STATE_ACTIVE', style: LabStyles.mono(context, fontSize: 10)),
            Switch.adaptive(
              value: _isFlexed,
              activeColor: LabColors.primary,
              onChanged: (v) => setState(() => _isFlexed = v),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('PUMPED_ESTATE_ACTIVE', style: LabStyles.mono(context, fontSize: 10)),
            Switch.adaptive(
              value: _isPumped,
              activeColor: LabColors.accent,
              onChanged: (v) => setState(() => _isPumped = v),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _showLabelPicker() async {
    final db = ref.read(databaseProvider);
    final rows = await db.customSelect(
            "SELECT DISTINCT label FROM anthropometric_logs WHERE label != 'WEIGHT' ORDER BY label ASC")
        .get();
    final labels = rows.map((r) => r.data['label'] as String).toList();
    if (!context.mounted) return;
    if (labels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('NO_PREVIOUS_METRICS_YET')));
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: LabColors.background,
      isScrollControlled: true,
      builder: (c) => QualitySearchPicker(
        title: 'SELECT_METRIC_LABEL',
        values: labels,
        onSelected: (val) => setState(() => _labelController.text = val),
      ),
    );
  }

  Widget _buildMetricCard(BuildContext context, AnthropometricLog log) {
    final isWeight = _activeTab == 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border(left: BorderSide(color: log.unit == 'kg' ? LabColors.accent : LabColors.primary, width: 2), bottom: BorderSide(color: Colors.grey[900]!, width: 0.5))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isWeight ? 'BODY_WEIGHT' : log.label.toUpperCase(), style: LabStyles.mono(context, fontWeight: FontWeight.bold, fontSize: 12)),
              Text(DateFormat('dd/MM/yy').format(log.date), style: LabStyles.mono(context, fontSize: 8, color: Colors.grey)),
            ],
          ),
          Row(
            children: [
              if (!isWeight && log.isFlexed) Container(margin: const EdgeInsets.only(right: 4), padding: const EdgeInsets.symmetric(horizontal: 4), color: Colors.redAccent.withValues(alpha: 0.2), child: Text('FLEX', style: LabStyles.mono(context, fontSize: 8, color: Colors.redAccent))),
              if (!isWeight && log.isPumped) Container(margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(horizontal: 4), color: LabColors.accent.withValues(alpha: 0.2), child: Text('PUMP', style: LabStyles.mono(context, fontSize: 8, color: LabColors.accent))),
              Text('${log.value}', style: LabStyles.mono(context, fontSize: 18, fontWeight: FontWeight.bold, color: LabColors.primary)),
              const SizedBox(width: 4),
              Text(log.unit.toUpperCase(), style: LabStyles.mono(context, fontSize: 10, color: Colors.grey)),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent, size: 16),
                onPressed: () async {
                  final db = ref.read(databaseProvider);
                  await (db.delete(db.anthropometricLogs)..where((t) => t.id.equals(log.id))).go();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _saveMetric() async {
    if (_valueController.text.isEmpty) return;
    if (_activeTab == 1 && _labelController.text.isEmpty) return;

    final db = ref.read(databaseProvider);
    final value = double.tryParse(_valueController.text) ?? 0;

    await db.into(db.anthropometricLogs).insert(AnthropometricLogsCompanion.insert(
      date: _selectedDate,
      label: _activeTab == 0
          ? 'WEIGHT'
          : _labelController.text.trim().toUpperCase(),
      value: value,
      unit: _selectedUnit,
      isFlexed: drift.Value(_activeTab == 0 ? false : _isFlexed),
      isPumped: drift.Value(_activeTab == 0 ? false : _isPumped),
    ));

    _labelController.clear();
    _valueController.clear();
    FocusScope.of(context).unfocus();
  }
}

