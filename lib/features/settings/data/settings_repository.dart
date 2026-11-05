import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// تفضيلات التطبيق المحفوظة محلياً.
@immutable
class AppSettings {
  const AppSettings({
    this.notificationsEnabled = true,
    this.themeMode = ThemeMode.system,
    this.permissionPrompted = false,
  });

  final bool notificationsEnabled;
  final ThemeMode themeMode;

  /// طُلب إذن الإشعارات من النظام مرة واحدة على الأقل.
  final bool permissionPrompted;

  AppSettings copyWith({bool? notificationsEnabled, ThemeMode? themeMode, bool? permissionPrompted}) => AppSettings(
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        themeMode: themeMode ?? this.themeMode,
        permissionPrompted: permissionPrompted ?? this.permissionPrompted,
      );
}

String themeModeLabel(ThemeMode mode) => switch (mode) {
      ThemeMode.system => 'حسب النظام',
      ThemeMode.light => 'فاتح',
      ThemeMode.dark => 'داكن',
    };

/// تُهيَّأ في `main` عبر `overrideWithValue`.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider must be overridden in main()'),
);

class SettingsController extends Notifier<AppSettings> {
  static const _kNotifications = 'notifications_enabled';
  static const _kTheme = 'theme_mode';
  static const _kPrompted = 'permission_prompted';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  AppSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final theme = prefs.getString(_kTheme);
    return AppSettings(
      notificationsEnabled: prefs.getBool(_kNotifications) ?? true,
      themeMode: ThemeMode.values.firstWhere((m) => m.name == theme, orElse: () => ThemeMode.system),
      permissionPrompted: prefs.getBool(_kPrompted) ?? false,
    );
  }

  Future<void> setNotificationsEnabled(bool value) async {
    await _prefs.setBool(_kNotifications, value);
    state = state.copyWith(notificationsEnabled: value);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setString(_kTheme, mode.name);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> markPermissionPrompted() async {
    await _prefs.setBool(_kPrompted, true);
    state = state.copyWith(permissionPrompted: true);
  }
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(SettingsController.new);
