// Shared load-type detection + effective-load math, used by every place
// that computes a set's actual load: the .md/PDF/Excel exporters,
// workout_manager's live displays, WB.editor's exercise tags, and the
// LR.ALERT charts. Before this file existed, this exact regex+branch logic
// was independently copy-pasted in all four places, with silently
// diverging fallback lists (export_service.dart's was missing BANDED and
// UNMOVABLE; workout_manager.dart's was missing UNMOVABLE; only
// WB.editor.dart's had all four) - one shared implementation means a
// load-type fix only ever has to happen once, in one place.
//
// Assistance/Bands overhaul (schema v34): a band used to be its own
// parallel "load type" (BANDED) alongside LASTRE/EXT.LOAD/JST.BW/
// UNMOVABLE, but never had distinct math anywhere - every totalLoad
// switch across the app silently treated it exactly like EXT.LOAD. It's
// now folded into a single signed `resistanceModifier` that ANY load type
// can carry: negative subtracts (an assisted machine or band reduces
// effective load), positive adds (a band providing accommodating
// resistance increases it). detectLoadType no longer recognizes 'BANDED'
// at all - existing BANDED exercises were migrated to EXT.LOAD with the
// modifier's label defaulted to "BAND" (see database.dart's v34
// migration).

const List<String> kKnownLoadTypes = ['LASTRE', 'EXT.LOAD', 'JST.BW', 'UNMOVABLE'];

final RegExp _ntIsoRegex = RegExp(r'\[NT:(.*)\|ISO:(.*)\]');

class LoadDetails {
  final String type;
  final bool isIsometric;
  const LoadDetails({required this.type, required this.isIsometric});
}

// `intention` is the exercise's own free-text field, which (post-v?)
// carries the `[NT:<type>|ISO:<bool>]` bracket the exercise form writes.
// `tissueName`/`field` are the pre-bracket legacy fallback, checked in
// that order (tissueName first) to match every prior copy of this logic.
LoadDetails detectLoadDetails({
  String? intention,
  String? tissueName,
  String? field,
}) {
  final intentionText = intention ?? '';
  final metaMatch = _ntIsoRegex.firstMatch(intentionText);
  if (metaMatch != null) {
    return LoadDetails(
      type: metaMatch.group(1) ?? 'EXT.LOAD',
      isIsometric: metaMatch.group(2) == 'true',
    );
  }

  String type = 'EXT.LOAD';
  if (kKnownLoadTypes.contains(tissueName)) {
    type = tissueName!;
  } else if (kKnownLoadTypes.contains(field)) {
    type = field!;
  }
  return LoadDetails(type: type, isIsometric: intentionText.startsWith('[ISO]'));
}

// Combines a set's raw typed weight with bodyweight (per load type) and a
// signed resistance modifier (negative = assisted, positive = added band
// resistance). Never returns a negative total. This is the ONE place every
// caller in the app should route through for "what did this set actually
// lift" - do not reimplement the per-load-type branching elsewhere.
double computeEffectiveLoad({
  required String loadType,
  required double rawWeight,
  required double bodyweight,
  double? resistanceModifier,
}) {
  final modifier = resistanceModifier ?? 0.0;
  double total;
  switch (loadType) {
    case 'JST.BW':
      total = bodyweight + modifier;
      break;
    case 'LASTRE':
    case 'UNMOVABLE':
      total = rawWeight + bodyweight + modifier;
      break;
    case 'EXT.LOAD':
    default:
      total = rawWeight + modifier;
      break;
  }
  return total < 0 ? 0.0 : total;
}
