import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/database_provider.dart';
import '../database/database.dart';
import 'styles.dart';
import 'lab_widgets.dart';
import 'main_scaffold.dart';
import '../localization/strings.dart';

class KinisiTreeScreen extends ConsumerStatefulWidget {
  final BaseExercise exercise;
  const KinisiTreeScreen({super.key, required this.exercise});

  @override
  ConsumerState<KinisiTreeScreen> createState() => _KinisiTreeScreenState();
}

class _KinisiTreeScreenState extends ConsumerState<KinisiTreeScreen> {
  final TransformationController _transformationController = TransformationController();
  
  Map<String, BaseExercise> _exerciseCache = {};
  int _levelsUp = 1;
  int _levelsDown = 1;
  bool _isLoading = true;

  // For connection drawing
  final GlobalKey _canvasKey = GlobalKey();
  final Map<String, GlobalKey> _nodeKeys = {};

  @override
  void initState() {
    super.initState();
    _loadGraph();
  }

  Future<void> _loadGraph() async {
    setState(() => _isLoading = true);
    final db = ref.read(databaseProvider);
    final all = await db.select(db.baseExercises).get();
    
    _exerciseCache = { for (var e in all) e.fullName: e };
    
    setState(() => _isLoading = false);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerView();
    });
  }

  void _centerView() {
    if (!mounted) return;
    final size = MediaQuery.of(context).size;
    final double centerX = (size.width / 2) - 2500;
    final double centerY = (size.height / 2) - 2500;
    
    setState(() {
      _transformationController.value = Matrix4.identity()..translate(centerX, centerY);
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider).value ?? 'en';
    if (_isLoading) {
      return const MainScaffold(title: 'KINISI_TREE', body: Center(child: CircularProgressIndicator(color: LabColors.primary)));
    }

    return MainScaffold(
      title: 'KINISI_TREE',
      body: Stack(
        children: [
          InteractiveViewer(
            transformationController: _transformationController,
            constrained: false,
            boundaryMargin: const EdgeInsets.all(5000),
            minScale: 0.05,
            maxScale: 2.0,
            child: Container(
              key: _canvasKey,
              width: 5000,
              height: 5000,
              color: Colors.black,
              child: Stack(
                children: [
                  Positioned.fill(child: CustomPaint(painter: _GridPainter())),
                  
                  // CONNECTIONS LAYER
                  Positioned.fill(
                    child: _ConnectionsLayer(
                      rootName: widget.exercise.fullName,
                      exerciseCache: _exerciseCache,
                      levelsUp: _levelsUp,
                      levelsDown: _levelsDown,
                      nodeKeys: _nodeKeys,
                      canvasKey: _canvasKey,
                    ),
                  ),

                  // NODES LAYER
                  Center(
                    child: _buildGraphLayout(),
                  ),
                ],
              ),
            ),
          ),
          _buildControls(lang),
        ],
      ),
    );
  }

  Widget _buildControls(String lang) {
    return Positioned(
      bottom: 24, right: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildExpander(tr(lang, "UP: PROGRESSIONS"), () => setState(() => _levelsUp++), Colors.greenAccent),
          const SizedBox(height: 8),
          _buildExpander(tr(lang, "DOWN: REGRESSIONS"), () => setState(() => _levelsDown++), Colors.redAccent),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: "recenter_btn",
            backgroundColor: Colors.black,
            elevation: 4,
            shape: const RoundedRectangleBorder(side: BorderSide(color: LabColors.primary, width: 0.5)),
            onPressed: _centerView,
            child: const Icon(Icons.filter_center_focus, color: LabColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildExpander(String label, VoidCallback onTap, Color color) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.9),
            border: Border.all(color: color, width: 0.5),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 4)],
          ),
          child: Text(label, style: LabStyles.mono(context, fontSize: 10, color: color, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildGraphLayout() {
    final List<String> alters = List<String>.from(widget.exercise.parsedComplexMetadata["alters"] ?? []);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // PROGRESSIONS (UP)
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildRecursiveLayer(widget.exercise.fullName, "progressions", _levelsUp, true),
            if (alters.isNotEmpty) ...alters.map((name) => Padding(
              padding: const EdgeInsets.only(left: 40),
              child: _buildRecursiveLayer(name, "progressions", _levelsUp, true),
            )),
          ],
        ),
        const SizedBox(height: 60),
        
        // ROOT & ALTERS
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildNode(widget.exercise, isRoot: true),
            ..._buildAlters(widget.exercise),
          ],
        ),
        const SizedBox(height: 60),
        
        // REGRESSIONS (DOWN)
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRecursiveLayer(widget.exercise.fullName, "regressions", _levelsDown, false),
            if (alters.isNotEmpty) ...alters.map((name) => Padding(
              padding: const EdgeInsets.only(left: 40),
              child: _buildRecursiveLayer(name, "regressions", _levelsDown, false),
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildRecursiveLayer(String exerciseName, String key, int levels, bool isUp) {
    if (levels <= 0) return const SizedBox();
    
    final ex = _exerciseCache[exerciseName];
    if (ex == null) return const SizedBox();

    final List<String> childrenNames = List<String>.from(ex.parsedComplexMetadata[key] ?? []);
    if (childrenNames.isEmpty) return const SizedBox();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isUp) ...[
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: childrenNames.map((name) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildRecursiveLayer(name, key, levels - 1, isUp),
            )).toList(),
          ),
          if (levels > 1) const SizedBox(height: 60),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: childrenNames.map((name) {
              final childEx = _exerciseCache[name];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: childEx != null
                    ? _buildNode(childEx, color: Colors.greenAccent)
                    : _buildBrokenNode(name),
              );
            }).toList(),
          ),
        ] else ...[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: childrenNames.map((name) {
              final childEx = _exerciseCache[name];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: childEx != null
                    ? _buildNode(childEx, color: Colors.redAccent)
                    : _buildBrokenNode(name),
              );
            }).toList(),
          ),
          if (levels > 1) const SizedBox(height: 60),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: childrenNames.map((name) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildRecursiveLayer(name, key, levels - 1, isUp),
            )).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildNode(BaseExercise ex, {bool isRoot = false, Color color = LabColors.primary}) {
    final key = _nodeKeys.putIfAbsent(ex.fullName, () => GlobalKey());
    return _SkillTreeNode(
      key: key,
      exercise: ex,
      isRoot: isRoot,
      color: color,
      onToggle: () {
        // Recalculate connections when node size changes (expansion)
        setState(() {});
      },
    );
  }

  List<Widget> _buildAlters(BaseExercise base) {
    final List<String> alters = List<String>.from(base.parsedComplexMetadata["alters"] ?? []);
    return alters.map((name) {
      final ex = _exerciseCache[name];
      return Padding(
        padding: const EdgeInsets.only(left: 40),
        child: ex != null
            ? _buildNode(ex, color: LabColors.accent)
            : _buildBrokenNode(name),
      );
    }).toList();
  }

  // A progressions/regressions/alters entry pointing at a name that isn't
  // in _exerciseCache (BROKEN_LINK, same check KNST.ALERT runs) used to
  // just render nothing - indistinguishable from "this movement genuinely
  // has no more progressions". Flag it visibly instead so a dangling link
  // is obvious right where it's dangling, not just in a separate screen.
  Widget _buildBrokenNode(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.08),
        border: Border.all(color: Colors.redAccent, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.link_off, color: Colors.redAccent, size: 14),
          const SizedBox(width: 6),
          Text(name.toUpperCase(),
              style: LabStyles.mono(context,
                  fontSize: 9, color: Colors.redAccent, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _ConnectionsLayer extends StatelessWidget {
  final String rootName;
  final Map<String, BaseExercise> exerciseCache;
  final int levelsUp;
  final int levelsDown;
  final Map<String, GlobalKey> nodeKeys;
  final GlobalKey canvasKey;

  const _ConnectionsLayer({
    required this.rootName,
    required this.exerciseCache,
    required this.levelsUp,
    required this.levelsDown,
    required this.nodeKeys,
    required this.canvasKey,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BezierThreadPainter(
        rootName: rootName,
        exerciseCache: exerciseCache,
        levelsUp: levelsUp,
        levelsDown: levelsDown,
        nodeKeys: nodeKeys,
        canvasKey: canvasKey,
      ),
    );
  }
}

class _BezierThreadPainter extends CustomPainter {
  final String rootName;
  final Map<String, BaseExercise> exerciseCache;
  final int levelsUp;
  final int levelsDown;
  final Map<String, GlobalKey> nodeKeys;
  final GlobalKey canvasKey;

  _BezierThreadPainter({
    required this.rootName,
    required this.exerciseCache,
    required this.levelsUp,
    required this.levelsDown,
    required this.nodeKeys,
    required this.canvasKey,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawConnections(canvas, rootName, "progressions", levelsUp, Colors.greenAccent);
    _drawConnections(canvas, rootName, "regressions", levelsDown, Colors.redAccent);
    _drawAlters(canvas, rootName);

    // Draw connections for alters
    final ex = exerciseCache[rootName];
    if (ex != null) {
      final List<String> alters = List<String>.from(ex.parsedComplexMetadata["alters"] ?? []);
      for (var alterName in alters) {
        _drawConnections(canvas, alterName, "progressions", levelsUp, Colors.greenAccent);
        _drawConnections(canvas, alterName, "regressions", levelsDown, Colors.redAccent);
      }
    }
  }

  void _drawConnections(Canvas canvas, String parentName, String key, int levels, Color color) {
    if (levels <= 0) return;
    
    final parentKey = nodeKeys[parentName];
    if (parentKey == null || parentKey.currentContext == null) return;
    
    final parentBox = parentKey.currentContext!.findRenderObject() as RenderBox;
    final canvasBox = canvasKey.currentContext!.findRenderObject() as RenderBox;
    final parentPos = parentBox.localToGlobal(Offset.zero, ancestor: canvasBox);
    final parentCenter = Offset(parentPos.dx + parentBox.size.width / 2, parentPos.dy + (key == "progressions" ? 0 : parentBox.size.height));

    final ex = exerciseCache[parentName];
    if (ex == null) return;
    final List<String> children = List<String>.from(ex.parsedComplexMetadata[key] ?? []);

    final paint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (var childName in children) {
      final childKey = nodeKeys[childName];
      if (childKey == null || childKey.currentContext == null) continue;

      final childBox = childKey.currentContext!.findRenderObject() as RenderBox;
      final childPos = childBox.localToGlobal(Offset.zero, ancestor: canvasBox);
      final childCenter = Offset(childPos.dx + childBox.size.width / 2, childPos.dy + (key == "progressions" ? childBox.size.height : 0));

      final path = Path();
      path.moveTo(parentCenter.dx, parentCenter.dy);
      
      // Control points for Bézier curve
      final double verticalDist = (childCenter.dy - parentCenter.dy).abs();
      final double cpOffset = verticalDist * 0.5;
      
      path.cubicTo(
        parentCenter.dx, parentCenter.dy + (key == "progressions" ? -cpOffset : cpOffset),
        childCenter.dx, childCenter.dy + (key == "progressions" ? cpOffset : -cpOffset),
        childCenter.dx, childCenter.dy,
      );

      canvas.drawPath(path, paint);
      
      // Recursive call for next level
      _drawConnections(canvas, childName, key, levels - 1, color);
    }
  }

  void _drawAlters(Canvas canvas, String rootName) {
    final parentKey = nodeKeys[rootName];
    if (parentKey == null || parentKey.currentContext == null) return;
    
    final parentBox = parentKey.currentContext!.findRenderObject() as RenderBox;
    final canvasBox = canvasKey.currentContext!.findRenderObject() as RenderBox;
    final parentPos = parentBox.localToGlobal(Offset.zero, ancestor: canvasBox);
    final parentCenter = Offset(parentPos.dx + parentBox.size.width, parentPos.dy + parentBox.size.height / 2);

    final ex = exerciseCache[rootName];
    if (ex == null) return;
    final List<String> alters = List<String>.from(ex.parsedComplexMetadata["alters"] ?? []);

    final paint = Paint()
      ..color = LabColors.accent.withValues(alpha: 0.3)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (var alterName in alters) {
      final alterKey = nodeKeys[alterName];
      if (alterKey == null || alterKey.currentContext == null) continue;

      final alterBox = alterKey.currentContext!.findRenderObject() as RenderBox;
      final alterPos = alterBox.localToGlobal(Offset.zero, ancestor: canvasBox);
      final alterCenter = Offset(alterPos.dx, alterPos.dy + alterBox.size.height / 2);

      final path = Path();
      path.moveTo(parentCenter.dx, parentCenter.dy);
      
      final double horizontalDist = (alterCenter.dx - parentCenter.dx).abs();
      final double cpOffset = horizontalDist * 0.5;
      
      path.cubicTo(
        parentCenter.dx + cpOffset, parentCenter.dy,
        alterCenter.dx - cpOffset, alterCenter.dy,
        alterCenter.dx, alterCenter.dy,
      );

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _SkillTreeNode extends StatefulWidget {
  final BaseExercise exercise;
  final bool isRoot;
  final Color color;
  final VoidCallback onToggle;

  const _SkillTreeNode({
    super.key,
    required this.exercise, 
    this.isRoot = false, 
    this.color = LabColors.primary,
    required this.onToggle,
  });

  @override
  State<_SkillTreeNode> createState() => _SkillTreeNodeState();
}

class _SkillTreeNodeState extends State<_SkillTreeNode> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() => _expanded = !_expanded);
        // Delay to allow animation to start or finish before recalculating lines
        Future.delayed(const Duration(milliseconds: 50), widget.onToggle);
        Future.delayed(const Duration(milliseconds: 300), widget.onToggle);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.fastOutSlowIn,
        width: 220,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: LabColors.surfaceDim,
          border: Border.all(
            color: widget.isRoot ? LabColors.accent : widget.color.withValues(alpha: _expanded ? 1.0 : 0.4), 
            width: widget.isRoot ? 2.0 : 0.8
          ),
          boxShadow: [
            if (_expanded || widget.isRoot)
              BoxShadow(color: widget.color.withValues(alpha: 0.15), blurRadius: 12, spreadRadius: 1)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.isRoot)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                color: LabColors.accent.withValues(alpha: 0.2),
                child: Text("ORIGIN_NODE", style: LabStyles.mono(context, fontSize: 7, color: LabColors.accent, fontWeight: FontWeight.bold)),
              ),
            Text(
              widget.exercise.fullName, 
              style: LabStyles.headline(context).copyWith(
                fontSize: 14, 
                color: widget.isRoot ? LabColors.accent : Colors.white,
                letterSpacing: 0.5
              ),
            ),
            if (_expanded) ...[
              const SizedBox(height: 16),
              _buildMetric("MUSCLE", widget.exercise.primaryMuscleGroup ?? "N/A"),
              _buildMetric("PATTERN", widget.exercise.patternType ?? "N/A"),
              _buildMetric("FIELD", widget.exercise.field ?? "N/A"),
              _buildMetric("TISSUE", widget.exercise.tissueType ?? "N/A"),
              const Divider(height: 24, color: Colors.white10),
              Text(
                widget.exercise.intention?.replaceFirst(RegExp(r'\[.*\]'), '').trim() ?? "NO_TECHNICAL_DESCRIPTION",
                style: LabStyles.mono(context, fontSize: 8, color: Colors.grey[400]),
              ),
              const SizedBox(height: 16),
              if (!widget.isRoot)
                LabButton(
                  label: "FOCUS_ON_NODE",
                  color: widget.color,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context, 
                      MaterialPageRoute(builder: (c) => KinisiTreeScreen(exercise: widget.exercise))
                    );
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(String l, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l, style: LabStyles.mono(context, fontSize: 7, color: Colors.grey)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(v.toUpperCase(), 
              style: LabStyles.mono(context, fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 1.0;

    const double spacing = 100.0;
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

