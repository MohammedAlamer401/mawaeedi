import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/notifications/notification_service.dart';
import '../appointments/controllers/appointments_controller.dart';
import '../appointments/data/appointment_model.dart';
import '../appointments/data/appointment_repository.dart';
import '../settings/data/settings_repository.dart';

/// مدة سجل «أُرسلت مؤخراً».
const recentRemindersWindow = Duration(days: 7);

/// التذكيرات القادمة: مواعيد مجدولة لها تذكير لم يحن بعد.
final upcomingRemindersProvider = FutureProvider<List<Appointment>>((ref) async {
  ref.watch(appointmentsRevisionProvider);
  final list = await ref.watch(appointmentRepositoryProvider).getPendingReminders(DateTime.now());
  return list..sort((a, b) => a.remindAt!.compareTo(b.remindAt!));
});

/// التذكيرات التي حان وقتها خلال آخر 7 أيام، الأحدث أولاً.
final recentRemindersProvider = FutureProvider<List<Appointment>>((ref) async {
  ref.watch(appointmentsRevisionProvider);
  final now = DateTime.now();
  final list = await ref.watch(appointmentRepositoryProvider).getRemindersBetween(now.subtract(recentRemindersWindow), now);
  return list.reversed.toList();
});

/// عدد التذكيرات التي وصلت منذ آخر فتح لتبويب «الإشعارات» — شارة التبويب.
final unseenRemindersCountProvider = Provider<int>((ref) {
  final enabled = ref.watch(settingsProvider.select((s) => s.notificationsEnabled));
  if (!enabled) return 0;
  final seenAt = ref.watch(settingsProvider.select((s) => s.notificationsSeenAt));
  final recent = ref.watch(recentRemindersProvider).value ?? const <Appointment>[];
  return recent.where((a) => seenAt == null || a.remindAt!.isAfter(seenAt)).length;
});

/// حالة إذن الإشعارات من النظام؛ تُحدَّث عند العودة إلى التطبيق.
final notificationPermissionProvider = FutureProvider<NotificationPermission>((ref) {
  ref.watch(appointmentsRevisionProvider);
  return ref.watch(notificationServiceProvider).permissionStatus();
});

/// هل التذكيرات معطّلة فعلياً (من الإعدادات أو من النظام)؟
final remindersBlockedProvider = Provider<bool>((ref) {
  final enabled = ref.watch(settingsProvider.select((s) => s.notificationsEnabled));
  final permission = ref.watch(notificationPermissionProvider).value;
  return !enabled || permission == NotificationPermission.denied;
});
