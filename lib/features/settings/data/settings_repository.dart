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
    this.displayName,
    this.notificationsSeenAt,
    this.previousSeenAt,
  });

  final bool notificationsEnabled;
  final ThemeMode themeMode;

  /// طُلب إذن الإشعارات من النظام مرة واحدة على الأقل.
  final bool permissionPrompted;

  /// الاسم الظاهر في التحية وبطاقة «حسابي».
  final String? displayName;

  /// آخر مرة فُتح فيها تبويب «الإشعارات» — لحساب شارة غير المقروء.
  final DateTime? notificationsSeenAt;

  /// قيمة [notificationsSeenAt] قبل آخر فتح للتبويب (في الذاكرة فقط)،
  /// حتى تبقى نقطة «جديد» ظاهرة على ما وصل منذ الزيارة السابقة.
  final DateTime? previousSeenAt;

  String? get firstName {
    final name = displayName?.trim();
    if (name == null || name.isEmpty) return null;
    return name.split(RegExp(r'\s+')).first;
  }

  AppSettings copyWith({
    bool? notificationsEnabled,
    ThemeMode? themeMode,
    bool? permissionPrompted,
    String? Function()? displayName,
    DateTime? notificationsSeenAt,
    DateTime? Function()? previousSeenAt,
  }) =>
      AppSettings(
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        themeMode: themeMode ?? this.themeMode,
        permissionPrompted: permissionPrompted ?? this.permissionPrompted,
        displayName: displayName == null ? this.displayName : displayName(),
        notificationsSeenAt: notificationsSeenAt ?? this.notificationsSeenAt,
        previousSeenAt: previousSeenAt == null ? this.previousSeenAt : previousSeenAt(),
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
  static const _kName = 'display_name';
  static const _kSeen = 'notifications_seen_at';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  AppSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final theme = prefs.getString(_kTheme);
    return AppSettings(
      notificationsEnabled: prefs.getBool(_kNotifications) ?? true,
      themeMode: ThemeMode.values.firstWhere((m) => m.name == theme, orElse: () => ThemeMode.system),
      permissionPrompted: prefs.getBool(_kPrompted) ?? false,
      displayName: prefs.getString(_kName),
      notificationsSeenAt: DateTime.tryParse(prefs.getString(_kSeen) ?? ''),
      previousSeenAt: DateTime.tryParse(prefs.getString(_kSeen) ?? ''),
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

  Future<void> setDisplayName(String name) async {
    final value = name.trim();
    if (value.isEmpty) {
      await _prefs.remove(_kName);
    } else {
      await _prefs.setString(_kName, value);
    }
    state = state.copyWith(displayName: () => value.isEmpty ? null : value);
  }

  Future<void> markNotificationsSeen() async {
    final now = DateTime.now();
    await _prefs.setString(_kSeen, now.toIso8601String());
    final previous = state.notificationsSeenAt;
    state = state.copyWith(notificationsSeenAt: now, previousSeenAt: () => previous);
  }

  Future<void> markPermissionPrompted() async {
    await _prefs.setBool(_kPrompted, true);
    state = state.copyWith(permissionPrompted: true);
  }
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(SettingsController.new);
