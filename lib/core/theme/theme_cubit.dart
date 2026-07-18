import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:team_workspace/core/theme/theme_mode_store.dart';

/// Single source of truth for the app's ThemeMode — MaterialApp.router reads
/// this to pick light/dark/system, and the dashboard's theme menu writes to
/// it. A singleton for the app's lifetime, same as AuthBloc.
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit(this._store) : super(_store.read());

  final ThemeModeStore _store;

  void setThemeMode(ThemeMode mode) {
    if (mode == state) return;
    emit(mode);
    unawaited(_store.write(mode));
  }
}
