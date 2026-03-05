import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../utils/constants.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  void _loadTheme() {
    if (Hive.isBoxOpen(AppConstants.userPrefsBox)) {
      final box = Hive.box(AppConstants.userPrefsBox);
      final savedTheme = box.get(AppConstants.themeKey, defaultValue: 'system') as String;
      state = _fromString(savedTheme);
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    final box = Hive.box(AppConstants.userPrefsBox);
    await box.put(AppConstants.themeKey, _toString(mode));
  }

  ThemeMode _fromString(String s) {
    switch (s) {
      case 'light': return ThemeMode.light;
      case 'dark': return ThemeMode.dark;
      default: return ThemeMode.system;
    }
  }

  String _toString(ThemeMode m) {
    switch (m) {
      case ThemeMode.light: return 'light';
      case ThemeMode.dark: return 'dark';
      case ThemeMode.system: return 'system';
    }
  }
}

final onboardingDoneProvider = StateProvider<bool>((ref) {
  if (Hive.isBoxOpen(AppConstants.userPrefsBox)) {
    final box = Hive.box(AppConstants.userPrefsBox);
    return box.get(AppConstants.onboardingKey, defaultValue: false) as bool;
  }
  return false;
});
