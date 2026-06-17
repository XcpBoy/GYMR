import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:convert';

import '../providers/database_provider.dart';
import '../providers/theme_provider.dart';
import 'styles.dart';
import 'lab_widgets.dart';
import 'main_scaffold.dart';

// ══════════════════════════════════════════════════════════════════════════
// MOCK DATA CLASSES (placeholder — replaced by DB schema at end)
// ══════════════════════════════════════════════════════════════════════════

class MockBlock {
  final int id;
  final String name;
  final String? intention;
  MockBlock({required this.id, required this.name, this.intention});
}

class MockKns {
  final int id;
  final int blockId;
  final String name;
  final String? metadata;
  MockKns({required this.id, required this.blockId, required this.name, this.metadata});
}

class MockBlockSet {
  final int id;
  final int knsId;
  final int setNumber;
  final double? repsMin;
  final double? repsMax;
  final double? rpeGoal;
  final double? rirGoal;
  final String? setIntention;
  final String? tag;
  MockBlockSet({
    required this.id, required this.knsId, required this.setNumber,
    this.repsMin, this.repsMax, this.rpeGoal, this.rirGoal, this.setIntention, this.tag,
  });
}

// ══════════════════════════════════════════════════════════════════════════
// MOCK PROVIDERS (temporary — replaced by real DB streams at end)
// ══════════════════════════════════════════════════════════════════════════

final mockBlockProvider = Provider.family<MockBlock?, int>((ref, blockId) {
  return MockBlock(id: blockId, name: 'BLOCK_NAME', intention: 'BLOCK INTENTION');
});

final mockKnsProvider = Provider.family<List<MockKns>, int>((ref, blockId) {
  return [
    MockKns(id: 1, blockId: blockId, name: 'PULL UP', metadata: 'EXT.LOAD'),
    MockKns(id: 2, blockId: blockId, name: 'DIP', metadata: 'EXT.LOAD'),
  ];
});

final mockSetsProvider = Provider.family<List<MockBlockSet>, int>((ref, knsId) {
  return [
    MockBlockSet(id: 1, knsId: knsId, setNumber: 1, repsMin: 5, repsMax: 8, rpeGoal: 8, rirGoal: 1),
    MockBlockSet(id: 2, knsId: knsId, setNumber: 2, repsMin: 5, repsMax: 8, rpeGoal: 9, rirGoal: 0),
  ];
});

// ══════════════════════════════════════════════════════════════════════════
// WORKOUT BLOCKS EDITOR
// ══════════════════════════════════════════════════════════════════════════

class WorkoutBlocksEditor extends ConsumerStatefulWidget {
  final int blockId;
  const WorkoutBlocksEditor({super.key, required this.blockId});

  @override
  ConsumerState<WorkoutBlocksEditor> createState() => _WorkoutBlocksEditorState();
}

class _WorkoutBlocksEditorState extends ConsumerState<WorkoutBlocksEditor> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final block = ref.watch(mockBlockProvider(widget.blockId));
    final knsEntries = ref.watch(mockKnsProvider(widget.blockId));

    return MainScaffold(
      title: block?.name.toUpperCase() ?? 'WB EDITOR',
      screenKey: 'WB_EDITOR',
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Block-level metadata button
            Row(
              children: [
                GestureDetector(
                  onTap: () => _showBlockMetaModal(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white24, width: 0.5),
                    ),
                    child: Text('[ BLOCK META ]', style: LabStyles.mono(context, fontSize: 8, color: Colors.grey[400])),
                  ),
                ),
                const SizedBox(width: 8),
                if (block?.intention != null)
                  Text(block!.intention!, style: LabStyles.mono(context, fontSize: 8, color: Colors.grey[500])),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: knsEntries.length,
                itemBuilder: (context, index) {
                  final kns = knsEntries[index];
                  return _KnsCard(
                    key: ValueKey('kns_${kns.id}'),
                    kns: kns,
                    index: index,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBlockMetaModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: LabColors.background,
      isScrollControlled: true,
      builder: (c) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('BLOCK METADATA', style: LabStyles.headline(context).copyWith(fontSize: 16)),
            const SizedBox(height: 24),
            Text('Progression method, tags, etc.', style: LabStyles.mono(context, fontSize: 10, color: Colors.grey)),
            const SizedBox(height: 24),
            LabButton(label: 'CLOSE', onPressed: () => Navigator.pop(c)),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// KNS CARD (based on C.WO's _ExerciseModule)
// ══════════════════════════════════════════════════════════════════════════

class _KnsCard extends ConsumerStatefulWidget {
  final MockKns kns;
  final int index;

  const _KnsCard({super.key, required this.kns, required this.index});

  @override
  ConsumerState<_KnsCard> createState() => _KnsCardState();
}

class _KnsCardState extends ConsumerState<_KnsCard> {
  @override
  Widget build(BuildContext context) {
    final kns = widget.kns;
    final settings = ref.watch(themeSettingsProvider).value ?? {};
    final tC = ref.read(themeControllerProvider);
    final sets = ref.watch(mockSetsProvider(kns.id));

    // Theme colors
    final uiTagExtload = tC.getColor(settings, 'UI_TAG_EXTLOAD', nameSeed: 'EXTLOAD');
    final uiTagPrimaryMuscle = tC.getColor(settings, 'UI_TAG_PRIMARY_MUSCLE', nameSeed: 'PRIMARY_MUSCLE');
    final uiTagBodyposition = tC.getColor(settings, 'UI_TAG_BODYPOSITION', nameSeed: 'BODYPOSITION');

    // KNS metadata button (second level)
    Widget knsMetaButton = GestureDetector(
      onTap: () => _showKnsMetaModal(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white24, width: 0.5),
        ),
        child: Text('[ KNS META ]', style: LabStyles.mono(context, fontSize: 7, color: Colors.grey[500])),
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: LabColors.surfaceDim,
        border: Border.all(color: LabColors.cyanBorder.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header row: KNS name + metadata button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // KNS name
                        Text(kns.name.toUpperCase(), style: LabStyles.headline(context).copyWith(fontSize: 18, color: Colors.white)),
                        const SizedBox(height: 6),
                        // Tags row
                        Wrap(spacing: 6, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                          if (kns.metadata != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(border: Border.all(color: uiTagExtload, width: 0.5)),
                              child: Text(kns.metadata!, style: LabStyles.mono(context, color: uiTagExtload, fontSize: 8, fontWeight: FontWeight.bold)),
                            ),
                          knsMetaButton,
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Sets — ALWAYS visible (no collapse)
              _buildSetList(sets),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildSetList(List<MockBlockSet> sets) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (sets.isNotEmpty) ...[
          // Column headers — C.WO style
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(color: LabColors.surfaceContainerHigh.withValues(alpha: 0.5)),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(flex: 1, child: Text('SET', textAlign: TextAlign.center, style: LabStyles.mono(context, fontSize: 8, color: Colors.grey))),
                  _colDivider(),
                  Expanded(flex: 2, child: Text('MIN', textAlign: TextAlign.center, style: LabStyles.mono(context, fontSize: 8, color: Colors.grey))),
                  _colDivider(),
                  Expanded(flex: 2, child: Text('MAX', textAlign: TextAlign.center, style: LabStyles.mono(context, fontSize: 8, color: Colors.grey))),
                  _colDivider(),
                  Expanded(flex: 2, child: Text('RPE', textAlign: TextAlign.center, style: LabStyles.mono(context, fontSize: 8, color: Colors.grey))),
                  _colDivider(),
                  Expanded(flex: 2, child: Text('RIR', textAlign: TextAlign.center, style: LabStyles.mono(context, fontSize: 8, color: Colors.grey))),
                  _colDivider(),
                  Expanded(flex: 3, child: Text('TAG', textAlign: TextAlign.center, style: LabStyles.mono(context, fontSize: 8, color: Colors.grey))),
                  _colDivider(),
                  Expanded(flex: 2, child: Text('CODE', textAlign: TextAlign.center, style: LabStyles.mono(context, fontSize: 8, color: Colors.grey))),
                  _colDivider(),
                  Expanded(flex: 2, child: Text('X', textAlign: TextAlign.center, style: LabStyles.mono(context, fontSize: 8, color: Colors.grey))),
                ],
              ),
            ),
          ),
          // Set rows
          ...sets.asMap().entries.map((entry) => _SetRow(
            key: ValueKey('s_${entry.value.id}'),
            set: entry.value,
            index: entry.key,
          )),
        ],
        const SizedBox(height: 12),
        // ADD SET button
        SizedBox(
          width: double.infinity,
          child: TextButton(
            style: TextButton.styleFrom(
              backgroundColor: LabColors.surfaceContainerHigh.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
              side: BorderSide(color: Colors.white12, width: 0.5),
            ),
            onPressed: () {},
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 14, color: LabColors.primary),
                const SizedBox(width: 6),
                Text('ADD SET', style: LabStyles.mono(context, fontSize: 10, color: LabColors.primary)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _colDivider() {
    return Container(width: 0.5, color: Colors.white12);
  }

  void _showKnsMetaModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: LabColors.background,
      isScrollControlled: true,
      builder: (c) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('KNS METADATA', style: LabStyles.headline(context).copyWith(fontSize: 16)),
            const SizedBox(height: 24),
            Text('Tags, superset group, etc.', style: LabStyles.mono(context, fontSize: 10, color: Colors.grey)),
            const SizedBox(height: 24),
            LabButton(label: 'CLOSE', onPressed: () => Navigator.pop(c)),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// SET ROW (based on C.WO's _WorkoutSetInstanceState grid)
// ══════════════════════════════════════════════════════════════════════════

class _SetRow extends ConsumerStatefulWidget {
  final MockBlockSet set;
  final int index;

  const _SetRow({super.key, required this.set, required this.index});

  @override
  ConsumerState<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends ConsumerState<_SetRow> {
  late TextEditingController _minC;
  late TextEditingController _maxC;
  late TextEditingController _rpeC;
  late TextEditingController _rirC;
  late TextEditingController _intentionC;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _minC = TextEditingController(text: widget.set.repsMin?.toString() ?? '');
    _maxC = TextEditingController(text: widget.set.repsMax?.toString() ?? '');
    _rpeC = TextEditingController(text: widget.set.rpeGoal?.toString() ?? '');
    _rirC = TextEditingController(text: widget.set.rirGoal?.toString() ?? '');
    _intentionC = TextEditingController(text: widget.set.setIntention ?? '');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _minC.dispose();
    _maxC.dispose();
    _rpeC.dispose();
    _rirC.dispose();
    _intentionC.dispose();
    super.dispose();
  }

  void _onChanged() {
    // Placeholder — will persist to DB when schema is wired
  }

  Column _buildGridCell(String label, TextEditingController controller, {int flex = 2}) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 1),
          color: LabColors.surfaceContainerHigh,
          child: Text(label, textAlign: TextAlign.center, style: LabStyles.mono(context, fontSize: 7, color: Colors.grey)),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: LabStyles.mono(context, fontSize: 12, color: Colors.white),
            decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
            onChanged: (_) => _onChanged(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: widget.set.tag != null
          ? Border(left: BorderSide(color: Colors.cyan.withValues(alpha: 0.4), width: 2))
          : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Grid row: set# | MIN | MAX | RPE | RIR | TAG | code | X
          IntrinsicHeight(
            child: Row(
              children: [
                // Set #
                Expanded(
                  flex: 1,
                  child: Container(
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.white12, width: 0.5))),
                    child: Text('${widget.index + 1}', style: LabStyles.mono(context, fontSize: 12, color: Colors.grey[400])),
                  ),
                ),
                // MIN
                Expanded(flex: 2, child: _buildGridCell('MIN', _minC)),
                _colDivider(),
                // MAX
                Expanded(flex: 2, child: _buildGridCell('MAX', _maxC)),
                _colDivider(),
                // RPE
                Expanded(flex: 2, child: _buildGridCell('RPE', _rpeC)),
                _colDivider(),
                // RIR
                Expanded(flex: 2, child: _buildGridCell('RIR', _rirC)),
                _colDivider(),
                // TAG (frame/type button)
                Expanded(
                  flex: 3,
                  child: GestureDetector(
                    onTap: () => _showTagMenu(),
                    child: Container(
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.white12, width: 0.5))),
                      child: Text('[ TAG ]', style: LabStyles.mono(context, fontSize: 8, color: Colors.grey[500])),
                    ),
                  ),
                ),
                _colDivider(),
                // CODE (set-level metadata button — 3rd level)
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: () => _showSetMetaModal(),
                    child: Container(
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.white12, width: 0.5))),
                      child: Icon(Icons.code, size: 14, color: Colors.grey[600]),
                    ),
                  ),
                ),
                _colDivider(),
                // X (delete)
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: () => _confirmDelete(),
                    child: Container(
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.white12, width: 0.5))),
                      child: Icon(Icons.close, size: 14, color: Colors.redAccent.withValues(alpha: 0.6)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // SET INTENTION line
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(left: 8, right: 8, bottom: 4),
            decoration: BoxDecoration(
              color: LabColors.surfaceDim,
              border: Border(left: BorderSide(color: LabColors.primary.withValues(alpha: 0.5), width: 2)),
            ),
            child: TextField(
              controller: _intentionC,
              style: LabStyles.mono(context, fontSize: 9, color: Colors.grey[400]),
              decoration: InputDecoration(
                hintText: 'SET INTENTION...',
                hintStyle: TextStyle(color: Colors.grey[700], fontSize: 8),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
              ),
              onChanged: (_) => _onChanged(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _colDivider() {
    return Container(width: 0.5, color: Colors.white12);
  }

  void _showTagMenu() {
    // TODO: tag frame / type selector
  }

  void _showSetMetaModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: LabColors.background,
      isScrollControlled: true,
      builder: (c) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SET METADATA', style: LabStyles.headline(context).copyWith(fontSize: 16)),
            const SizedBox(height: 24),
            Text('Tag frame, top set / backoff, etc.', style: LabStyles.mono(context, fontSize: 10, color: Colors.grey)),
            const SizedBox(height: 24),
            LabButton(label: 'CLOSE', onPressed: () => Navigator.pop(c)),
          ],
        ),
      ),
    );
  }

  void _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: LabColors.background,
        title: Text('DELETE SET', style: LabStyles.mono(context, fontSize: 12, color: Colors.redAccent)),
        content: Text('Remove set ${widget.index + 1}?', style: LabStyles.mono(context, fontSize: 10)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text('CANCEL', style: LabStyles.mono(context))),
          TextButton(onPressed: () => Navigator.pop(c, true), child: Text('DELETE', style: LabStyles.mono(context, color: Colors.redAccent))),
        ],
      ),
    );
  }
}
