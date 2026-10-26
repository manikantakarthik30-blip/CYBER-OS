import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/storage/storage_providers.dart';

class SettingsState {
  final bool enableSecretScanner;
  final bool enableMCPScanner;
  final bool enableDependencyScanner;
  final bool enableAIFirewall;
  final bool enableRateLimiting;
  final String exportFormat; // 'JSON' or 'Markdown'

  SettingsState({
    this.enableSecretScanner = true,
    this.enableMCPScanner = true,
    this.enableDependencyScanner = true,
    this.enableAIFirewall = true,
    this.enableRateLimiting = true,
    this.exportFormat = 'JSON',
  });

  SettingsState copyWith({
    bool? enableSecretScanner,
    bool? enableMCPScanner,
    bool? enableDependencyScanner,
    bool? enableAIFirewall,
    bool? enableRateLimiting,
    String? exportFormat,
  }) {
    return SettingsState(
      enableSecretScanner: enableSecretScanner ?? this.enableSecretScanner,
      enableMCPScanner: enableMCPScanner ?? this.enableMCPScanner,
      enableDependencyScanner: enableDependencyScanner ?? this.enableDependencyScanner,
      enableAIFirewall: enableAIFirewall ?? this.enableAIFirewall,
      enableRateLimiting: enableRateLimiting ?? this.enableRateLimiting,
      exportFormat: exportFormat ?? this.exportFormat,
    );
  }

  Map<String, dynamic> toJson() => {
    'enableSecretScanner': enableSecretScanner,
    'enableMCPScanner': enableMCPScanner,
    'enableDependencyScanner': enableDependencyScanner,
    'enableAIFirewall': enableAIFirewall,
    'enableRateLimiting': enableRateLimiting,
    'exportFormat': exportFormat,
  };

  factory SettingsState.fromJson(Map<String, dynamic> json) => SettingsState(
    enableSecretScanner: (json['enableSecretScanner'] as bool?) ?? true,
    enableMCPScanner: (json['enableMCPScanner'] as bool?) ?? true,
    enableDependencyScanner: (json['enableDependencyScanner'] as bool?) ?? true,
    enableAIFirewall: (json['enableAIFirewall'] as bool?) ?? true,
    enableRateLimiting: (json['enableRateLimiting'] as bool?) ?? true,
    exportFormat: (json['exportFormat'] as String?) ?? 'JSON',
  );
}

final settingsControllerProvider = StateNotifierProvider<SettingsController, SettingsState>((ref) {
  SharedPreferences? prefs;
  try {
    prefs = ref.watch(sharedPreferencesProvider);
  } catch (_) {
    // If not overridden (e.g. In unit tests), proceed without persistence
  }
  return SettingsController(prefs);
});

class SettingsController extends StateNotifier<SettingsState> {
  static const String storageKey = 'cyber_os_settings';
  final SharedPreferences? _prefs;

  SettingsController([this._prefs]) : super(_initialState(_prefs));

  static SettingsState _initialState(SharedPreferences? prefs) {
    if (prefs != null) {
      final raw = prefs.getString(storageKey);
      if (raw != null && raw.isNotEmpty) {
        try {
          final decoded = json.decode(raw) as Map<String, dynamic>;
          return SettingsState.fromJson(decoded);
        } catch (_) {}
      }
    }
    return SettingsState();
  }

  void _persist() {
    if (_prefs != null) {
      _prefs.setString(storageKey, json.encode(state.toJson()));
    }
  }

  void toggleSecretScanner(bool val) {
    state = state.copyWith(enableSecretScanner: val);
    _persist();
  }

  void toggleMCPScanner(bool val) {
    state = state.copyWith(enableMCPScanner: val);
    _persist();
  }

  void toggleDependencyScanner(bool val) {
    state = state.copyWith(enableDependencyScanner: val);
    _persist();
  }

  void toggleAIFirewall(bool val) {
    state = state.copyWith(enableAIFirewall: val);
    _persist();
  }

  void toggleRateLimiting(bool val) {
    state = state.copyWith(enableRateLimiting: val);
    _persist();
  }

  void setExportFormat(String val) {
    state = state.copyWith(exportFormat: val);
    _persist();
  }
}
