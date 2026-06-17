import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'WO.Blocks.manager.dart';

class BlueprintManagerScreen extends ConsumerStatefulWidget {
  const BlueprintManagerScreen({super.key});

  @override
  ConsumerState<BlueprintManagerScreen> createState() => _BlueprintManagerScreenState();
}

class _BlueprintManagerScreenState extends ConsumerState<BlueprintManagerScreen> {
  @override
  Widget build(BuildContext context) {
    return const WorkoutBlocksManagerScreen();
  }
}
