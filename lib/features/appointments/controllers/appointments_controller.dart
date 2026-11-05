import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting/date_formatter.dart';
import '../../../core/notifications/notification_service.dart';
import '../../settings/data/settings_repository.dart';
import '../data/appointment_model.dart';
import '../data/appointment_repository.dart';

/// تبويبات شاشة «كل المواعيد» (القسم 4.3).
enum AppointmentTab {
  today('اليوم'),
  upcoming('القادمة'),
  past('السابقة'),
  completed('المكتملة');

  const AppointmentTab(this.label);

  final String label;
}

/// يزداد بعد كل تعديل على المواعيد فتُعاد قراءة كل القوائم.
class AppointmentsRevision extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final appointmentsRevisionProvider = NotifierProvider<AppointmentsRevision, int>(AppointmentsRevision.new);

final appointmentsByTabProvider = FutureProvider.family<List<Appointment>, AppointmentTab>((ref, tab) {
  ref.watch(appointmentsRevisionProvider);
  final repo = ref.watch(appointmentRepositoryProvider);
  return switch (tab) {
    AppointmentTab.today => repo.getAppointmentsForDay(DateFormatter.today()),
    AppointmentTab.upcoming => repo.getUpcomingAppointments(),
    AppointmentTab.past => repo.getPastAppointments(),
    AppointmentTab.completed => repo.getCompletedAppointments(),
  };
});

/// أقرب المواعيد القادمة للشاشة الرئيسية.
final upcomingPreviewProvider = FutureProvider<List<Appointment>>((ref) {
  ref.watch(appointmentsRevisionProvider);
  return ref.watch(appointmentRepositoryProvider).getUpcomingAppointments(limit: 3);
});

/// نتيجة الحفظ: هل جُدول تذكير فعلاً، أم تعذّر بسبب الإذن.
enum ReminderOutcome { none, scheduled, disabledInSettings, permissionDenied }

/// ينسّق قاعدة البيانات مع الإشعارات في كل عملية (القاعدة 4 في القسم 11).
class AppointmentsController {
  AppointmentsController(this._ref);

  final Ref _ref;

  AppointmentRepository get _repo => _ref.read(appointmentRepositoryProvider);
  NotificationService get _notifications => _ref.read(notificationServiceProvider);
  bool get _remindersOn => _ref.read(settingsProvider).notificationsEnabled;

  void _refresh() => _ref.read(appointmentsRevisionProvider.notifier).bump();

  /// يضيف موعداً جديداً أو يحدّث موجوداً ثم يعيد جدولة إشعاره.
  Future<(Appointment, ReminderOutcome)> save(Appointment draft) async {
    final now = DateTime.now();
    final Appointment saved;
    if (draft.id == null) {
      saved = await _repo.insertAppointment(draft.copyWith(createdAt: now, updatedAt: now));
    } else {
      saved = draft.copyWith(updatedAt: now, notificationId: () => draft.notificationId ?? draft.id);
      await _repo.updateAppointment(saved);
    }
    final outcome = await _syncReminder(saved);
    _refresh();
    return (saved, outcome);
  }

  Future<ReminderOutcome> _syncReminder(Appointment a) async {
    final id = a.notificationId ?? a.id!;
    if (!a.hasReminder || a.isCompleted) {
      await _notifications.cancel(id);
      return ReminderOutcome.none;
    }
    if (!_remindersOn) {
      await _notifications.cancel(id);
      return ReminderOutcome.disabledInSettings;
    }
    await _notifications.schedule(a);
    final permission = await _notifications.permissionStatus();
    return permission == NotificationPermission.denied ? ReminderOutcome.permissionDenied : ReminderOutcome.scheduled;
  }

  Future<void> delete(Appointment a) async {
    await _notifications.cancel(a.notificationId ?? a.id!);
    await _repo.deleteAppointment(a.id!);
    _refresh();
  }

  /// الإكمال يلغي التذكير، والتراجع عنه يعيد جدولته إن كان وقته لم يفت.
  Future<void> setCompleted(Appointment a, bool completed) async {
    await _repo.markAppointmentCompleted(a.id!, completed: completed);
    final updated = a.copyWith(
      status: completed ? AppointmentStatus.completed : AppointmentStatus.scheduled,
    );
    await _syncReminder(updated);
    _refresh();
  }

  /// يعيد بناء كل الإشعارات المجدولة من قاعدة البيانات — عند التشغيل
  /// وبعد تغيير إعداد الإشعارات (القاعدة 5).
  Future<void> resyncAll() async {
    await _notifications.cancelAll();
    if (!_remindersOn) return;
    for (final a in await _repo.getPendingReminders(DateTime.now())) {
      await _notifications.schedule(a);
    }
  }
}

final appointmentsControllerProvider = Provider<AppointmentsController>(AppointmentsController.new);
