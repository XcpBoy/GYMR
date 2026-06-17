import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../database/database.dart';

// ══════════════════════════════════════════════════════════════════════
// MOCK DATA STRUCTURES (will be replaced by DB tables at schema step)
// ══════════════════════════════════════════════════════════════════════

class WbBlock {
  final int id;
  final String name;
  final String? intention;
  final Map<String, dynamic> metadata; // progression method, tags, etc.
  WbBlock({required this.id, required this.name, this.intention, Map<String, dynamic>? metadata})
      : metadata = metadata ?? {};
}

class WbKns {
  final int id;
  final int blockId;
  final int baseExerciseId; // FK → base_exercises (for exercise picker)
  final String exerciseName; // denormalized for display
  final int orderIndex;
  final String? supersetGroupId;
  final String? supersetName;
  final Map<String, dynamic> metadata; // per-KNS tags
  WbKns({
    required this.id, required this.blockId, required this.baseExerciseId,
    required this.exerciseName, required this.orderIndex,
    this.supersetGroupId, this.supersetName, Map<String, dynamic>? metadata,
  }) : metadata = metadata ?? {};
}

class WbSet {
  final int id;
  final int knsId;
  final int setNumber;
  final double? repsMin;
  final double? repsMax;
  final double? rpeGoal;
  final double? rirGoal;
  final String? setIntention;
  final Map<String, dynamic> metadata; // tag: top_set/backoff, type: main_lift/assistance/weakness
  WbSet({
    required this.id, required this.knsId, required this.setNumber,
    this.repsMin, this.repsMax, this.rpeGoal, this.rirGoal,
    this.setIntention, Map<String, dynamic>? metadata,
  }) : metadata = metadata ?? {};
}

// ══════════════════════════════════════════════════════════════════════
// MOCK PROVIDERS
// ══════════════════════════════════════════════════════════════════════

/// Returns all WBs.
final wbBlocksProvider = Provider<List<WbBlock>>((ref) {
  return [
    WbBlock(id: 1, name: 'VICTORIANO PROG', intention: 'STRENGTH FOCUS',
        metadata: {'method': 'LINEAR', 'weeks': 4}),
    WbBlock(id: 2, name: 'PUSH EMPHASIS', intention: 'HYPERTROPHY'),
  ];
});

/// Returns KNS entries for a given block.
final wbKnsListProvider = Provider.family<List<WbKns>, int>((ref, blockId) {
  return [
    WbKns(id: 1, blockId: blockId, baseExerciseId: 1, exerciseName: 'PULL UP',
        orderIndex: 0, metadata: {'tempo': '3-1-1'}),
    WbKns(id: 2, blockId: blockId, baseExerciseId: 2, exerciseName: 'DIP',
        orderIndex: 1),
  ];
});

/// Returns sets for a given KNS entry.
final wbSetsProvider = Provider.family<List<WbSet>, int>((ref, knsId) {
  return [
    WbSet(id: 1, knsId: knsId, setNumber: 1, repsMin: 5, repsMax: 8, rpeGoal: 8, rirGoal: 1,
        setIntention: 'EXPLOSIVE', metadata: {'tag': 'top_set'}),
    WbSet(id: 2, knsId: knsId, setNumber: 2, repsMin: 5, repsMax: 8, rpeGoal: 9, rirGoal: 0,
        setIntention: 'BACKOFF', metadata: {'tag': 'backoff'}),
  ];
});
