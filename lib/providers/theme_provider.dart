import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../database/database.dart';
import 'database_provider.dart';

final themeSettingsProvider = StreamProvider<Map<String, ThemeSetting>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.themeSettings).watch().map((rows) {
    return {for (var row in rows) row.key: row};
  });
});

final wallpaperProvider = StreamProvider.family<String?, String>((ref, screenKey) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.themeSettings)..where((t) => t.key.equals('WALLPAPER_$screenKey')))
      .watchSingleOrNull()
      .map((row) => row?.value);
});

Color _parseHex(String? hex) {
  if (hex == null || hex.isEmpty) return Colors.transparent;
  final buffer = StringBuffer();
  if (hex.length == 6 || hex.length == 7) buffer.write('ff');
  buffer.write(hex.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}

class ThemeController {
  final AppDatabase db;
  ThemeController(this.db);

  Future<void> setColor(String key, Color color) async {
    final hex = '#${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
    await db.into(db.themeSettings).insertOnConflictUpdate(ThemeSettingsCompanion(
      key: Value(key),
      colorHex: Value(hex),
    ));
  }

  Future<void> setValue(String key, String value) async {
    await db.into(db.themeSettings).insertOnConflictUpdate(ThemeSettingsCompanion(
      key: Value(key),
      value: Value(value),
    ));
  }

  Future<void> setBool(String key, bool value) => setValue(key, value ? '1' : '0');

  bool getBool(Map<String, ThemeSetting> settings, String key,
      {bool defaultValue = true}) {
    final v = settings[key]?.value;
    if (v == null) return defaultValue;
    return v == '1' || v.toLowerCase() == 'true';
  }

  // Clears every customized color (rows with a colorHex set), leaving
  // value-only rows (wallpaper paths, app-config toggles) untouched.
  Future<void> resetAllColors() =>
      (db.delete(db.themeSettings)..where((t) => t.colorHex.isNotNull())).go();

  Color getColor(Map<String, ThemeSetting> settings, String key, {Color? defaultColor, String? nameSeed, Iterable<String> aliases = const []}) {
    if (settings.containsKey(key)) {
      final hex = settings[key]!.colorHex;
      if (hex != null) return _parseHex(hex);
    }

    for (final alias in aliases) {
      if (settings.containsKey(alias)) {
        final hex = settings[alias]!.colorHex;
        if (hex != null) return _parseHex(hex);
      }
    }
    
    if (defaultColor != null) return defaultColor;

    // Fallback: Generate deterministic color from nameSeed
    final seed = nameSeed ?? key;
    final hash = seed.hashCode;
    return Color((hash & 0xFFFFFF) | 0xFF000000);
  }

  String? getValue(Map<String, ThemeSetting> settings, String key) {
    return settings[key]?.value;
  }
}

final themeControllerProvider = Provider((ref) => ThemeController(ref.watch(databaseProvider)));
