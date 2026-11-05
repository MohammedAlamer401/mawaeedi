import 'package:flutter_test/flutter_test.dart';
import 'package:mawaeedi/core/notifications/notification_service.dart';
import 'package:mawaeedi/features/appointments/controllers/appointments_controller.dart';
import 'package:mawaeedi/features/appointments/data/appointment_model.dart';
import 'package:mawaeedi/features/notifications/notifications_providers.dart';
import 'package:mawaeedi/features/settings/data/settings_repository.dart';

import 'helpers/test_app.dart';

/// معايير القبول في القسم 13: التذكير يُجدول، والتعديل لا يكرره، والحذف والإكمال يلغيانه.
void main() {
  late TestApp app;
  late AppointmentsController controller;

  setUp(() async {
    app = await TestApp.create();
    controller = app.container.read(appointmentsControllerProvider);
  });

  tearDown(() => app.dispose());

  Appointment draft(DateTime startAt, {int? reminder = 15}) {
    final now = DateTime.now();
    return Appointment(title: 'اختبار', startAt: startAt, reminderMinutes: reminder, createdAt: now, updatedAt: now);
  }

  test('الحفظ يجدول التذكير بمعرّف الموعد', () async {
    final (saved, outcome) = await controller.save(draft(DateTime.now().add(const Duration(hours: 2))));
    expect(outcome, ReminderOutcome.scheduled);
    expect(app.notifications.scheduled.keys, [saved.id]);
  });

  test('التعديل يستبدل الإشعار ولا يكرره', () async {
    final (saved, _) = await controller.save(draft(DateTime.now().add(const Duration(hours: 2))));
    final later = DateTime.now().add(const Duration(hours: 5));
    await controller.save(saved.copyWith(startAt: later, reminderMinutes: () => 30));
    expect(app.notifications.scheduled.length, 1);
    expect(app.notifications.scheduled[saved.id]!.remindAt, later.subtract(const Duration(minutes: 30)));
  });

  test('بدون تذكير لا يُنشأ إشعار', () async {
    final (_, outcome) = await controller.save(draft(DateTime.now().add(const Duration(hours: 2)), reminder: null));
    expect(outcome, ReminderOutcome.none);
    expect(app.notifications.scheduled, isEmpty);
  });

  test('الحذف والإكمال يلغيان الإشعار، والتراجع يعيده', () async {
    final (a, _) = await controller.save(draft(DateTime.now().add(const Duration(hours: 2))));
    final (b, _) = await controller.save(draft(DateTime.now().add(const Duration(hours: 3))));

    await controller.delete(a);
    expect(app.notifications.scheduled.containsKey(a.id), isFalse);
    expect(app.repo.items.any((x) => x.id == a.id), isFalse);

    await controller.setCompleted(b, true);
    expect(app.notifications.scheduled, isEmpty);
    await controller.setCompleted(b, false);
    expect(app.notifications.scheduled.keys, [b.id]);
  });

  test('رفض الإذن يُبلَّغ، وإيقاف التذكيرات يلغي الكل', () async {
    app.notifications.permission = NotificationPermission.denied;
    final (_, outcome) = await controller.save(draft(DateTime.now().add(const Duration(hours: 2))));
    expect(outcome, ReminderOutcome.permissionDenied);

    app.notifications.permission = NotificationPermission.granted;
    await app.container.read(settingsProvider.notifier).setNotificationsEnabled(false);
    await controller.resyncAll();
    expect(app.notifications.scheduled, isEmpty);
    expect(app.container.read(remindersBlockedProvider), isTrue);
  });

  test('شارة الإشعارات تعدّ ما وصل منذ آخر فتح', () async {
    final now = DateTime.now();
    app.repo
      ..add('وصل', now.add(const Duration(minutes: 5)), reminder: 10)
      ..add('لم يصل', now.add(const Duration(hours: 3)), reminder: 10);
    await app.container.read(recentRemindersProvider.future);
    expect(app.container.read(unseenRemindersCountProvider), 1);

    await app.container.read(settingsProvider.notifier).markNotificationsSeen();
    expect(app.container.read(unseenRemindersCountProvider), 0);
  });
}
