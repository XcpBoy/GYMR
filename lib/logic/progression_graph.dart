import 'package:drift/drift.dart';
import '../database/database.dart';

class ProgressionGraph {
  final AppDatabase db;

  ProgressionGraph(this.db);

  /// Returns all variants that are direct successors of the given [variantId].
  Future<List<ExerciseVariant>> getSuccessors(int variantId) async {
    final query = db.select(db.progressionEdges).join([
      innerJoin(db.exerciseVariants, db.exerciseVariants.id.equalsExp(db.progressionEdges.toVariantId))
    ]);
    
    query.where(
      db.progressionEdges.fromVariantId.equals(variantId) & 
      db.progressionEdges.type.equals(ProgressionType.successor.index)
    );

    final result = await query.get();
    return result.map((row) => row.readTable(db.exerciseVariants)).toList();
  }

  /// Returns all variants that are predecessors of the given [variantId].
  Future<List<ExerciseVariant>> getPredecessors(int variantId) async {
    final query = db.select(db.progressionEdges).join([
      innerJoin(db.exerciseVariants, db.exerciseVariants.id.equalsExp(db.progressionEdges.fromVariantId))
    ]);

    query.where(
      db.progressionEdges.toVariantId.equals(variantId) & 
      db.progressionEdges.type.equals(ProgressionType.predecessor.index)
    );

    final result = await query.get();
    return result.map((row) => row.readTable(db.exerciseVariants)).toList();
  }

  /// Returns "Equal" progressions (alternatives with similar difficulty).
  Future<List<ExerciseVariant>> getEqualVariants(int variantId) async {
    // Check both directions for "equal" relationships
    final query = db.select(db.progressionEdges).join([
      innerJoin(db.exerciseVariants, db.exerciseVariants.id.equalsExp(db.progressionEdges.toVariantId))
    ]);

    query.where(
      (db.progressionEdges.fromVariantId.equals(variantId) | db.progressionEdges.toVariantId.equals(variantId)) & 
      db.progressionEdges.type.equals(ProgressionType.equal.index)
    );

    final result = await query.get();
    return result.map((row) => row.readTable(db.exerciseVariants)).toList();
  }
}
