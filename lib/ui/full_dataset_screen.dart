import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' hide Column;
import '../providers/database_provider.dart';
import '../database/database.dart';
import 'styles.dart';
import 'main_scaffold.dart';
import 'lab_widgets.dart';
import '../logic/calculator.dart';

enum DatasetCategory { sets, notes, weight, anthropometric }

class FullDatasetScreen extends ConsumerStatefulWidget {
  const FullDatasetScreen({super.key});

  @override
  ConsumerState<FullDatasetScreen> createState() => _FullDatasetScreenState();
}

class _FullDatasetScreenState extends ConsumerState<FullDatasetScreen> {
  DatasetCategory _selectedCategory = DatasetCategory.sets;
  
  // Advanced SETS filters
  DateTimeRange? _timeRange;
  final String _loadTypeFilter = 'ALL';
  bool _onlyPr = false;
  
  // Pagination
  int _limit = 100;

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'FULL_DATASET_EXPLORER',
      screenKey: 'DATASET',
      body: Column(
        children: [
          _buildCategorySelector(),
          if (_selectedCategory == DatasetCategory.sets || _selectedCategory == DatasetCategory.notes) _buildAdvancedFilters(),
          _buildPaginationHeader(),
          Expanded(
            child: _buildDataExplorer(),
          ),
        ],
      ),
      bottomNavigationBar: const LabFooter(),
    );
  }

  Widget _buildPaginationHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      alignment: Alignment.centerRight,
      child: Text(
        'SHOWING_TOP_${_limit}_RECORDS',
        style: LabStyles.mono(context, fontSize: 8, color: Colors.grey[600]!),
      ),
    );
  }

  Widget _buildDataExplorer() {
    final db = ref.watch(databaseProvider);

    switch (_selectedCategory) {
      case DatasetCategory.sets:
        return _buildSetsList(db);
      case DatasetCategory.notes:
        return _buildNotesList(db);
      case DatasetCategory.weight:
        return _buildWeightList(db);
      case DatasetCategory.anthropometric:
        return _buildAnthropometricList(db);
    }
  }

  Widget _buildNotesList(AppDatabase db) {
    var query = db.select(db.workoutSets).join([
      innerJoin(db.baseExercises, db.baseExercises.id.equalsExp(db.workoutSets.baseExerciseId)),
    ])..where(db.workoutSets.notes.isNotNull());

    if (_timeRange != null) {
      query.where(db.workoutSets.timestamp.isBetweenValues(_timeRange!.start, _timeRange!.end));
    }

    query.orderBy([OrderingTerm.desc(db.workoutSets.timestamp)]);
    query.limit(_limit);

    return StreamBuilder<List<TypedResult>>(
      stream: query.watch(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: LabColors.primary));
        final data = snapshot.data!;
        if (data.isEmpty) return _buildNoDataPlaceholder("NO_NOTES_FOUND");

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 100, left: 16, right: 16, top: 8),
          itemCount: data.length,
          itemBuilder: (context, i) {
            final row = data[i];
            final set = row.readTable(db.workoutSets);
            final ex = row.readTable(db.baseExercises);
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: LabColors.surfaceDim,
                border: Border.all(color: LabColors.primary.withValues(alpha: 0.2), width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(ex.fullName, style: LabStyles.mono(context, fontSize: 10, fontWeight: FontWeight.bold, color: LabColors.primary), overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 8),
                      Text(DateFormat('yyyy-MM-dd').format(set.timestamp), style: LabStyles.mono(context, fontSize: 8, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    width: double.infinity,
                    decoration: const BoxDecoration(color: Colors.black, border: Border(left: BorderSide(color: LabColors.primary, width: 1))),
                    child: Text(
                      set.notes ?? "",
                      style: LabStyles.mono(context, fontSize: 11, color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNoDataPlaceholder(String msg) {
    return Center(child: Text(msg, style: LabStyles.mono(context, fontSize: 10, color: Colors.grey)));
  }

  Widget _buildSetsList(AppDatabase db) {
    var query = db.select(db.workoutSets).join([
      innerJoin(db.baseExercises, db.baseExercises.id.equalsExp(db.workoutSets.baseExerciseId)),
      innerJoin(db.workoutLogs, db.workoutLogs.id.equalsExp(db.workoutSets.logId)),
    ]);

    if (_timeRange != null) {
      query.where(db.workoutSets.timestamp.isBetweenValues(_timeRange!.start, _timeRange!.end));
    }
    if (_onlyPr) {
      query.where(db.workoutSets.isPr.equals(true));
    }

    query.orderBy([OrderingTerm.desc(db.workoutSets.timestamp)]);
    query.limit(_limit);

    return StreamBuilder<List<TypedResult>>(
      stream: query.watch(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: LabColors.primary));
        
        final data = snapshot.data!;
        
        // Filter by Load Nature using Technical Metadata
        final filtered = data.where((row) {
          if (_loadTypeFilter == 'ALL') return true;
          final ex = row.readTable(db.baseExercises);
          final details = _detectLoadDetails(ex);
          return details.type == _loadTypeFilter || (details.isIsometric && _loadTypeFilter == 'ISO');
        }).toList();

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 100),
          itemCount: filtered.length,
          itemBuilder: (context, index) => _buildSetCard(filtered[index], db),
        );
      },
    );
  }

  Widget _buildSetCard(TypedResult row, AppDatabase db) {
    final set = row.readTable(db.workoutSets);
    final ex = row.readTable(db.baseExercises);
    final log = row.readTable(db.workoutLogs);
    
    final details = _detectLoadDetails(ex);
    
    return FutureBuilder<double?>(
      future: _getBWAtDate(db, log.date),
      builder: (context, bwSnapshot) {
        final bw = bwSnapshot.data ?? 0.0;
        final isLastre = details.type == 'LASTRE';
        final isJst = details.type == 'JST.BW';
        
        double totalLoad = set.weight;
        if (isLastre) totalLoad = set.weight + bw;
        if (isJst) totalLoad = bw;

        final eORM = WorkoutCalculator.calculateEpley1RM(totalLoad, set.reps);
        final fullName = ex.fullName;
        final fatigue = set.restTimeSeconds != null ? (set.restTimeSeconds! / 10).toStringAsFixed(1) : "-";
        final tech = set.technique?.toString() ?? "-";
        final isRed = (set.trackName ?? "").contains('[RED_PR]');

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isRed ? Colors.redAccent.withValues(alpha: 0.05) : LabColors.surfaceDim,
            border: Border.all(
              color: isRed ? Colors.redAccent : (set.isPr ? LabColors.accent.withValues(alpha: 0.5) : LabColors.cyanBorder.withValues(alpha: 0.1)),
              width: isRed ? 1.0 : 0.5
            ),
            boxShadow: isRed ? [BoxShadow(color: Colors.redAccent.withValues(alpha: 0.1), blurRadius: 4)] : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(DateFormat('yyyy-MM-dd | HH:mm').format(set.timestamp), style: LabStyles.mono(context, fontSize: 8, color: Colors.grey)),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(border: Border.all(color: LabColors.primary, width: 0.5)),
                        child: Text("${details.isIsometric ? 'ISO+' : ''}${details.type}", style: LabStyles.mono(context, fontSize: 7, color: LabColors.primary)),
                      ),
                      if (set.isPr) ...[const SizedBox(width: 8), Icon(Icons.emoji_events, size: 14, color: isRed ? Colors.redAccent : LabColors.accent)],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(fullName, style: LabStyles.headline(context).copyWith(fontSize: 14, color: Colors.white)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildDataField("LOAD", "${set.weight}KG"),
                  _buildDataField("BW", "${bw.toStringAsFixed(1)}KG"),
                  _buildDataField("TOTAL", "${totalLoad.toStringAsFixed(1)}KG", highlight: true),
                  _buildDataField("REPS", "${set.reps.toString().replaceAll(RegExp(r'\.0$'), '')}${details.isIsometric ? 'S' : ''}"),
                ],
              ),
              const Divider(height: 24, color: Colors.white10),
              Row(
                children: [
                  _buildDataField("RPE", "${set.rpe ?? '-'}", flex: 1),
                  _buildDataField("RIR", "${set.rir ?? '-'}", flex: 1),
                  _buildDataField("TECH", tech, flex: 1),
                  _buildDataField("eORM", eORM.toStringAsFixed(1), flex: 1, highlight: isRed),
                ],
              ),
              if (set.notes != null && set.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  width: double.infinity,
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), border: const Border(left: BorderSide(color: LabColors.primary, width: 1))),
                  child: Text(set.notes!, style: LabStyles.mono(context, fontSize: 9, color: Colors.grey[400])),
                ),
              ]
            ],
          ),
        );
      }
    );
  }

  Widget _buildDataField(String label, String value, {bool highlight = false, int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: LabStyles.mono(context, fontSize: 7, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(value, style: LabStyles.mono(context, fontSize: 11, fontWeight: FontWeight.bold, color: highlight ? LabColors.accent : Colors.white)),
        ],
      ),
    );
  }

  Future<double?> _getBWAtDate(AppDatabase db, DateTime date) async {
    final log = await (db.select(db.anthropometricLogs)
          ..where((t) => t.label.equals('WEIGHT'))
          ..where((t) => t.date.isSmallerOrEqualValue(date))
          ..orderBy([(t) => OrderingTerm.desc(t.date)])
          ..limit(1))
        .getSingleOrNull();
    return log?.value;
  }

  _LoadDetails _detectLoadDetails(BaseExercise ex) {
    final intentionText = ex.intention ?? '';
    final metaMatch = RegExp(r'\[NT:(.*)\|ISO:(.*)\]').firstMatch(intentionText);
    if (metaMatch != null) {
      return _LoadDetails(type: metaMatch.group(1) ?? 'EXT.LOAD', isIsometric: metaMatch.group(2) == 'true');
    }
    return _LoadDetails(type: 'EXT.LOAD', isIsometric: intentionText.startsWith('[ISO]'));
  }


  Widget _buildWeightList(AppDatabase db) {
    final query = (db.select(db.anthropometricLogs)
          ..where((t) => t.label.equals('WEIGHT'))
          ..orderBy([(t) => OrderingTerm.desc(t.date)])
          ..limit(_limit));

    return StreamBuilder<List<AnthropometricLog>>(
      stream: query.watch(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, i) {
            final log = snapshot.data![i];
            return ListTile(
              title: Text('${log.value} ${log.unit}', style: LabStyles.mono(context, fontSize: 12, color: LabColors.accent)),
              subtitle: Text(DateFormat('yyyy-MM-dd').format(log.date), style: LabStyles.mono(context, fontSize: 9)),
            );
          },
        );
      },
    );
  }

  Widget _buildAnthropometricList(AppDatabase db) {
    final query = (db.select(db.anthropometricLogs)
          ..where((t) => t.label.isNotValue('WEIGHT'))
          ..orderBy([(t) => OrderingTerm.desc(t.date)])
          ..limit(_limit));

    return StreamBuilder<List<AnthropometricLog>>(
      stream: query.watch(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, i) {
            final log = snapshot.data![i];
            return ListTile(
              title: Text(log.label.toUpperCase(), style: LabStyles.mono(context, fontSize: 10)),
              subtitle: Text(DateFormat('yyyy-MM-dd').format(log.date), style: LabStyles.mono(context, fontSize: 8)),
              trailing: Text('${log.value} ${log.unit}', style: LabStyles.mono(context, fontSize: 10, color: LabColors.primary)),
            );
          },
        );
      },
    );
  }

  Widget _buildAdvancedFilters() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: LabColors.surfaceDim, border: Border.all(color: LabColors.cyanBorder.withValues(alpha: 0.1), width: 0.5)),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final p = await showDateRangePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 1)));
                    if (p != null) setState(() => _timeRange = p);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: LabStyles.hairlineBorder(),
                    child: Text(_timeRange == null ? 'TIME_RANGE: ALL' : '${DateFormat('dd/MM').format(_timeRange!.start)} - ${DateFormat('dd/MM').format(_timeRange!.end)}', style: LabStyles.mono(context, fontSize: 9, color: LabColors.primary)),
                  ),
                ),
              ),
            ],
          ),
          TechnicalQuickTimeFilter(
            currentRange: _timeRange,
            onRangeSelected: (range) => setState(() => _timeRange = range),
            activeColor: LabColors.datasetGold,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildToggle('PR_ONLY', _onlyPr, (v) => setState(() => _onlyPr = v)),
              _buildLimitDropdown(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLimitDropdown() {
    return Row(
      children: [
        Text('LIMIT:', style: LabStyles.mono(context, fontSize: 8, color: Colors.grey)),
        const SizedBox(width: 8),
        DropdownButton<int>(
          value: _limit,
          dropdownColor: LabColors.surfaceContainerHigh,
          underline: const SizedBox(),
          style: LabStyles.mono(context, fontSize: 9, color: LabColors.accent),
          items: [50, 100, 500, 1000].map((l) => DropdownMenuItem(value: l, child: Text(l.toString()))).toList(),
          onChanged: (v) => setState(() => _limit = v ?? 100),
        ),
      ],
    );
  }

  Widget _buildToggle(String label, bool value, Function(bool) onChanged) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(border: Border.all(color: value ? LabColors.primary : Colors.grey[800]!, width: 1), color: value ? LabColors.primary : Colors.transparent)),
          const SizedBox(width: 8),
          Text(label, style: LabStyles.mono(context, fontSize: 8, color: value ? Colors.white : Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Container(
      height: 60,
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: LabColors.cyanBorder, width: 0.5))),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildCategoryTab('SETS', DatasetCategory.sets),
          _buildCategoryTab('NOTES', DatasetCategory.notes),
          _buildCategoryTab('WEIGHT', DatasetCategory.weight),
          _buildCategoryTab('ANTROPMT', DatasetCategory.anthropometric),
        ],
      ),
    );
  }

  Widget _buildCategoryTab(String label, DatasetCategory category) {
    final isActive = _selectedCategory == category;
    return InkWell(
      onTap: () => setState(() => _selectedCategory = category),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isActive ? LabColors.primary : Colors.transparent, width: 2))),
        child: Center(child: Text(label, style: LabStyles.mono(context, fontSize: 10, fontWeight: FontWeight.bold, color: isActive ? LabColors.primary : Colors.grey[600]!).copyWith(letterSpacing: 2))),
      ),
    );
  }
}

class _LoadDetails {
  final String type;
  final bool isIsometric;
  _LoadDetails({required this.type, required this.isIsometric});
}

