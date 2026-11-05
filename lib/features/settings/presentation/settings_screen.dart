import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/notifications/permission_flow.dart';
import '../../../core/widgets/app_svg_icon.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../appointments/controllers/appointments_controller.dart';
import '../data/settings_repository.dart';

/// حالة الإذن من النظام ودقة التنبيهات؛ تُحدَّث عند العودة إلى التطبيق.
final notificationSystemStateProvider =
    FutureProvider.autoDispose<(NotificationPermission, bool exact)>((ref) async {
  final service = ref.watch(notificationServiceProvider);
  return (await service.permissionStatus(), await service.canScheduleExact());
});

/// الإعدادات (القسم 4.4).
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  static const version = '1.0.0';

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // بعد الرجوع من إعدادات الهاتف قد يتغير الإذن.
    _lifecycle = AppLifecycleListener(onResume: () => ref.invalidate(notificationSystemStateProvider));
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _toggleNotifications(bool on) async {
    if (on && !await ensureNotificationPermission(context, ref, force: true)) {
      ref.invalidate(notificationSystemStateProvider);
      return;
    }
    await ref.read(settingsProvider.notifier).setNotificationsEnabled(on);
    await ref.read(appointmentsControllerProvider).resyncAll();
    ref.invalidate(notificationSystemStateProvider);
    if (mounted) showAppSnackBar(context, on ? 'تم تفعيل التذكيرات' : 'تم إيقاف كل التذكيرات');
  }

  Future<void> _requestExact() async {
    await ref.read(notificationServiceProvider).requestExactAlarms();
    // يُعاد الحساب عند العودة من شاشة النظام عبر onResume.
  }

  Future<void> _pickTheme(ThemeMode current) async {
    final picked = await showModalBottomSheet<ThemeMode>(
      context: context,
      builder: (context) => SafeArea(
        child: RadioGroup<ThemeMode>(
          groupValue: current,
          onChanged: (value) => Navigator.pop(context, value),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('مظهر التطبيق', style: context.text.cardTitle),
              ),
              for (final mode in [ThemeMode.system, ThemeMode.light, ThemeMode.dark])
                RadioListTile<ThemeMode>(value: mode, title: Text(themeModeLabel(mode))),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
    if (picked != null) await ref.read(settingsProvider.notifier).setThemeMode(picked);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final system = ref.watch(notificationSystemStateProvider).value;
    final denied = system?.$1 == NotificationPermission.denied;
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;
    final p = context.palette;

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          const _SectionTitle('الإشعارات'),
          _Group(children: [
            SwitchListTile(
              secondary: const AppSvgIcon(AppSvgIcons.bell),
              title: const Text('تذكيرات المواعيد'),
              subtitle: Text(settings.notificationsEnabled ? 'تنبيه قبل كل موعد له تذكير' : 'لن تصلك أي تذكيرات'),
              value: settings.notificationsEnabled && !denied,
              onChanged: _toggleNotifications,
            ),
            if (settings.notificationsEnabled && denied)
              ListTile(
                leading: Icon(Icons.warning_amber_rounded, color: p.warning),
                title: Text('الإشعارات ممنوعة من النظام', style: context.text.label.copyWith(color: p.warning)),
                subtitle: const Text('اضغط لفتح إعدادات الهاتف والسماح بها'),
                trailing: const Icon(Icons.chevron_left_rounded),
                onTap: () => ref.read(notificationServiceProvider).openSystemSettings(),
              ),
            if (isAndroid && settings.notificationsEnabled && !denied)
              ListTile(
                leading: const AppSvgIcon(AppSvgIcons.alarm),
                title: const Text('تذكير بدقة الدقيقة'),
                subtitle: Text(
                  system?.$2 ?? true
                      ? 'مفعّل — يصل التذكير في وقته تماماً'
                      : 'قد يتأخر التذكير دقائق لتوفير البطارية. اضغط للسماح بالدقة',
                ),
                trailing: system?.$2 ?? true
                    ? Icon(Icons.check_circle_rounded, color: p.success)
                    : const Icon(Icons.chevron_left_rounded),
                onTap: system?.$2 ?? true ? null : _requestExact,
              ),
          ]),
          const _SectionTitle('المظهر'),
          _Group(children: [
            ListTile(
              leading: const AppSvgIcon(AppSvgIcons.theme),
              title: const Text('مظهر التطبيق'),
              trailing: _Value(themeModeLabel(settings.themeMode)),
              onTap: () => _pickTheme(settings.themeMode),
            ),
          ]),
          const _SectionTitle('عن التطبيق'),
          _Group(children: [
            const ListTile(
              leading: AppSvgIcon(AppSvgIcons.info),
              title: Text('الخصوصية'),
              subtitle: Text('كل مواعيدك محفوظة على هذا الهاتف فقط، ولا تُرسَل لأي جهة.'),
            ),
            ListTile(
              leading: const AppSvgIcon(AppSvgIcons.calendar),
              title: const Text('الإصدار'),
              trailing: Text(SettingsScreen.version, style: context.text.labelMuted),
            ),
          ]),
          const SizedBox(height: 24),
          const Center(child: MawaeediLogo(size: 56)),
          const SizedBox(height: 8),
          Text('مواعيدي — جدولي في متناول يدي', style: context.text.caption, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(8, 20, 8, 8),
      child: Text(text, style: context.text.labelMuted),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final (i, child) in children.indexed) ...[
            if (i > 0) const Divider(indent: 56),
            child,
          ],
        ],
      ),
    );
  }
}

class _Value extends StatelessWidget {
  const _Value(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(text, style: context.text.labelMuted),
        Icon(Icons.chevron_left_rounded, color: context.palette.textSecondary),
      ],
    );
  }
}
