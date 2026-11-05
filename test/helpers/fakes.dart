import 'package:mawaeedi/core/formatting/date_formatter.dart';
import 'package:mawaeedi/core/notifications/notification_service.dart';
import 'package:mawaeedi/features/appointments/data/appointment_model.dart';
import 'package:mawaeedi/features/appointments/data/appointment_repository.dart';

/// مستودع في الذاكرة لاختبارات الواجهة (sqflite لا يعمل داخل fake async).
class FakeAppointmentRepository implements AppointmentRepository {
  final _items = <Appointment>[];
  var _nextId = 1;

  List<Appointment> get items => List.unmodifiable(_items);

  Appointment add(String title, DateTime startAt, {int? reminder = 15, bool completed = false, String? notes}) {
    final id = _nextId++;
    final a = Appointment(
      id: id,
      notificationId: id,
      title: title,
      notes: notes,
      startAt: startAt,
      reminderMinutes: reminder,
      status: completed ? AppointmentStatus.completed : AppointmentStatus.scheduled,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    _items.add(a);
    return a;
  }

  List<Appointment> _sorted(Iterable<Appointment> list, {bool desc = false}) =>
      list.toList()..sort((a, b) => desc ? b.startAt.compareTo(a.startAt) : a.startAt.compareTo(b.startAt));

  @override
  Future<Appointment> insertAppointment(Appointment a) async {
    final id = _nextId++;
    final saved = a.copyWith(id: id, notificationId: () => id);
    _items.add(saved);
    return saved;
  }

  @override
  Future<Appointment?> getAppointment(int id) async => _items.where((a) => a.id == id).firstOrNull;

  @override
  Future<List<Appointment>> getAppointmentsForDay(DateTime day) async =>
      _sorted(_items.where((a) => DateFormatter.isSameDay(a.startAt, day)));

  @override
  Future<List<Appointment>> getUpcomingAppointments({DateTime? from, int? limit}) async {
    final start = from ?? DateFormatter.today().add(const Duration(days: 1));
    final list = _sorted(_items.where((a) => !a.isCompleted && !a.startAt.isBefore(start)));
    return limit == null ? list : list.take(limit).toList();
  }

  @override
  Future<List<Appointment>> getPastAppointments() async =>
      _sorted(_items.where((a) => !a.isCompleted && a.startAt.isBefore(DateFormatter.today())), desc: true);

  @override
  Future<List<Appointment>> getCompletedAppointments() async => _sorted(_items.where((a) => a.isCompleted), desc: true);

  @override
  Future<List<Appointment>> getPendingReminders(DateTime now) async =>
      _items.where((a) => !a.isCompleted && a.hasReminder && a.startAt.isAfter(now) && a.remindAt!.isAfter(now)).toList();

  @override
  Future<List<Appointment>> getRemindersBetween(DateTime from, DateTime to) async => _items
      .where((a) => a.hasReminder && !a.remindAt!.isBefore(from) && a.remindAt!.isBefore(to))
      .toList()
    ..sort((a, b) => a.remindAt!.compareTo(b.remindAt!));

  @override
  Future<void> updateAppointment(Appointment a) async {
    final i = _items.indexWhere((x) => x.id == a.id);
    if (i >= 0) _items[i] = a;
  }

  @override
  Future<void> deleteAppointment(int id) async => _items.removeWhere((a) => a.id == id);

  @override
  Future<void> markAppointmentCompleted(int id, {bool completed = true}) async {
    final i = _items.indexWhere((x) => x.id == id);
    if (i >= 0) {
      _items[i] = _items[i].copyWith(status: completed ? AppointmentStatus.completed : AppointmentStatus.scheduled);
    }
  }
}

/// خدمة إشعارات وهمية تسجّل ما جُدول وأُلغي.
class FakeNotificationService extends NotificationService {
  FakeNotificationService({this.permission = NotificationPermission.granted});

  NotificationPermission permission;
  final scheduled = <int, Appointment>{};
  final cancelled = <int>[];

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => permission == NotificationPermission.granted;

  @override
  Future<NotificationPermission> permissionStatus() async => permission;

  @override
  Future<void> openSystemSettings() async {}

  @override
  Future<bool> canScheduleExact() async => true;

  @override
  Future<bool> requestExactAlarms() async => true;

  @override
  Future<void> schedule(Appointment a) async {
    final id = a.notificationId ?? a.id!;
    scheduled.remove(id);
    if (a.isCompleted || a.remindAt == null || !a.startAt.isAfter(DateTime.now())) return;
    scheduled[id] = a;
  }

  @override
  Future<void> cancel(int id) async {
    scheduled.remove(id);
    cancelled.add(id);
  }

  @override
  Future<void> cancelAll() async => scheduled.clear();
}
