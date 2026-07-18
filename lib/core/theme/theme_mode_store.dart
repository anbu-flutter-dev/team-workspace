import 'package:flutter/material.dart';
import 'package:hive_ce/hive_ce.dart';

/// Persists the user's chosen ThemeMode so it survives app restarts.
class ThemeModeStore {
  ThemeModeStore(this._box);

  final Box<dynamic> _box;

  static const String _key = 'theme_mode';

  ThemeMode read() {
    final stored = _box.get(_key);
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == stored,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> write(ThemeMode mode) => _box.put(_key, mode.name);
}
