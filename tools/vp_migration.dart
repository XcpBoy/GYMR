// One-time migration: set vpMultiplier=1 for all existing exercises
// Run: dart run tools/vp_migration.dart
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:beyond_performance/database/database.dart';

void main() async {
  final db = Database();
  
  final exercises = await db.select(db.baseExercises).get();
  int updated = 0;
  
  for (final ex in exercises) {
    Map<String, dynamic> meta = {};
    if (ex.complexMetadata != null && ex.complexMetadata!.isNotEmpty) {
      try { meta = jsonDecode(ex.complexMetadata!); } catch (_) {}
    }
    
    if (!meta.containsKey('vpMultiplier')) {
      meta['vpMultiplier'] = 1.0;
      await (db.update(db.baseExercises)..where((t) => t.id.equals(ex.id)))
          .write(BaseExercisesCompanion(
            complexMetadata: Value(jsonEncode(meta)),
          ));
      updated++;
    }
  }
  
  print('Migration complete: $updated / ${exercises.length} exercises updated');
  await db.close();
}
