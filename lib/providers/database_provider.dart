import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  try {
    final db = AppDatabase();
    ref.onDispose(() => db.close());
    return db;
  } catch (e) {
    debugPrint("CRITICAL: Error initializing database provider: $e");
    rethrow;
  }
});

final databaseHealthProvider = FutureProvider<bool>((ref) async {
  try {
    final db = ref.watch(databaseProvider);
    // Simple query to verify connection
    await db.customSelect('SELECT 1').getSingle();
    return true;
  } catch (e) {
    debugPrint("Database Health Check Failed: $e");
    return false;
  }
});

final allExercisesProvider = StreamProvider<List<BaseExercise>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.baseExercises).watch();
});

final allBlueprintExercisesProvider = StreamProvider<List<BlueprintExercise>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.blueprintExercises).watch();
});

final allWorkoutSetsProvider = StreamProvider<List<WorkoutSet>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.workoutSets).watch();
});

/// Reads global batch names from batch_definitions table
final allBatchNamesProvider = FutureProvider<List<String>>((ref) async {
  final db = ref.watch(databaseProvider);
  // Ensure table exists (safety net for hot reloads)
  await db.customStatement('''
    CREATE TABLE IF NOT EXISTS batch_definitions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE,
      created_at INTEGER NOT NULL DEFAULT 0
    )
  ''');
  final rows = await db.executor.runSelect('SELECT name FROM batch_definitions ORDER BY name ASC', []);
  return rows.map((r) => r['name'] as String).toList();
});
