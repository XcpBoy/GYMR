// Pure Dart matching for KNS.SHORTHAND: a user-defined search alias (e.g.
// "WMU" for "WEIGHTED MUSCLE UPS") stored in complexMetadata (see
// BaseExercise.shorthand in database.dart). Every exercise searcher in the
// app should match on shorthand in addition to whatever fields it already
// searches, using this single function so the matching rule (substring,
// case-insensitive) can't drift between the ~4 different search
// implementations.

/// True if [query] (already expected lowercase or not - normalized here)
/// matches [fullName] or [shorthand] as a case-insensitive substring.
/// [shorthand] may be null/empty (no alias set).
bool matchesKnsQuery(String query, {required String fullName, String? shorthand}) {
  if (query.isEmpty) return true;
  final q = query.toLowerCase();
  if (fullName.toLowerCase().contains(q)) return true;
  if (shorthand != null && shorthand.isNotEmpty && shorthand.toLowerCase().contains(q)) return true;
  return false;
}
