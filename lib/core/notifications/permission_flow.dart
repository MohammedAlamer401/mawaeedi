import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/data/settings_repository.dart';
import '../widgets/confirm_dialog.dart';
import 'notification_service.dart';

/// يطلب إذن الإشعارات في الوقت المناسب: أول مرة يحتاج فيها المستخدم تذكيراً.
///
/// يعيد `true` إن كانت الإشعارات مسموحة (أو حالتها غير معروفة).
Future<bool> ensureNotificationPermission(BuildContext context, WidgetRef ref, {bool force = false}) async {
  final service = ref.read(notificationServiceProvider);
  final status = await service.permissionStatus();
  if (status != NotificationPermission.denied) return true;

  final settings = ref.read(settingsProvider);
  if (!settings.permissionPrompted || force) {
    await ref.read(settingsProvider.notifier).markPermissionPrompted();
    if (await service.requestPermission()) return true;
  }
  if (context.mounted) await showPermissionDeniedDialog(context, ref);
  return false;
}

/// رسالة توضح أن التذكيرات لن تعمل حتى تفعيل الإشعارات من إعدادات الهاتف.
Future<void> showPermissionDeniedDialog(BuildContext context, WidgetRef ref) async {
  final open = await showConfirmDialog(
    context,
    title: 'الإشعارات غير مفعّلة',
    message: 'لن تصلك تذكيرات المواعيد حتى تسمح لـ«مواعيدي» بالإشعارات من إعدادات الهاتف.',
    confirmLabel: 'فتح الإعدادات',
    cancelLabel: 'لاحقاً',
  );
  if (open) await ref.read(notificationServiceProvider).openSystemSettings();
}
