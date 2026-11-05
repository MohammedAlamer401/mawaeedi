import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../../../core/formatting/date_formatter.dart';
import 'appointment_model.dart';

/// عمليات قاعدة البيانات على جدول `appointments` (القسم 8).
class AppointmentRepository {
  AppointmentRepository(this._db);

  final Database _db;

  static const _table = 'appointments';

  String _s(DateTime d) => Appointment.toStorage(d);

  List<Appointment> _map(List<Map<String, Object?>> rows) => rows.map(Appointment.fromMap).toList();

  /// يضيف الموعد ويعيده بمعرّفه الجديد. معرّف الإشعار = معرّف الموعد.
  Future<Appointment> insertAppointment(Appointment appointment) async {
    return _db.transaction((txn) async {
      final id = await txn.insert(_table, appointment.toMap()..remove('id'));
      final saved = appointment.copyWith(id: id, notificationId: () => id);
      await txn.update(_table, {'notification_id': id}, where: 'id = ?', whereArgs: [id]);
      return saved;
    });
  }

  Future<Appointment?> getAppointment(int id) async {
    final rows = await _db.query(_table, where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : Appointment.fromMap(rows.first);
  }

  /// كل مواعيد يوم معيّن (بكل حالاتها) مرتبة حسب الوقت.
  Future<List<Appointment>> getAppointmentsForDay(DateTime day) async {
    final start = DateFormatter.dateOnly(day);
    final end = start.add(const Duration(days: 1));
    return _map(await _db.query(
      _table,
      where: 'start_at >= ? AND start_at < ?',
      whereArgs: [_s(start), _s(end)],
      orderBy: 'start_at ASC',
    ));
  }

  /// المواعيد المجدولة بعد اليوم [from] (افتراضياً: من بداية الغد).
  Future<List<Appointment>> getUpcomingAppointments({DateTime? from, int? limit}) async {
    final start = from ?? DateFormatter.today().add(const Duration(days: 1));
    return _map(await _db.query(
      _table,
      where: 'start_at >= ? AND status = ?',
      whereArgs: [_s(start), AppointmentStatus.scheduled.value],
      orderBy: 'start_at ASC',
      limit: limit,
    ));
  }

  /// المواعيد المجدولة التي فاتت قبل اليوم ولم تُكمَل، الأحدث أولاً.
  Future<List<Appointment>> getPastAppointments() async {
    return _map(await _db.query(
      _table,
      where: 'start_at < ? AND status = ?',
      whereArgs: [_s(DateFormatter.today()), AppointmentStatus.scheduled.value],
      orderBy: 'start_at DESC',
    ));
  }

  Future<List<Appointment>> getCompletedAppointments() async {
    return _map(await _db.query(
      _table,
      where: 'status = ?',
      whereArgs: [AppointmentStatus.completed.value],
      orderBy: 'start_at DESC',
    ));
  }

  /// المواعيد المجدولة التي لها تذكير لم يحن بعد — لإعادة مزامنة الإشعارات.
  Future<List<Appointment>> getPendingReminders(DateTime now) async {
    final rows = await _db.query(
      _table,
      where: 'status = ? AND reminder_minutes IS NOT NULL AND start_at > ?',
      whereArgs: [AppointmentStatus.scheduled.value, _s(now)],
    );
    return _map(rows).where((a) => a.remindAt!.isAfter(now)).toList();
  }

  /// المواعيد التي يقع وقت تذكيرها بين [from] و[to] (لشاشة الإشعارات).
  Future<List<Appointment>> getRemindersBetween(DateTime from, DateTime to) async {
    // وقت التذكير يسبق الموعد بيوم على الأكثر، فنوسّع نافذة البحث بيوم.
    final rows = await _db.query(
      _table,
      where: 'reminder_minutes IS NOT NULL AND start_at >= ? AND start_at < ?',
      whereArgs: [_s(from), _s(to.add(const Duration(days: 1)))],
    );
    final list = _map(rows).where((a) {
      final at = a.remindAt!;
      return !at.isBefore(from) && at.isBefore(to);
    }).toList()
      ..sort((a, b) => a.remindAt!.compareTo(b.remindAt!));
    return list;
  }

  Future<void> updateAppointment(Appointment appointment) async {
    await _db.update(_table, appointment.toMap(), where: 'id = ?', whereArgs: [appointment.id]);
  }

  Future<void> deleteAppointment(int id) async {
    await _db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> markAppointmentCompleted(int id, {bool completed = true}) async {
    await _db.update(
      _table,
      {
        'status': (completed ? AppointmentStatus.completed : AppointmentStatus.scheduled).value,
        'updated_at': _s(DateTime.now()),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

final appointmentRepositoryProvider = Provider<AppointmentRepository>(
  (ref) => AppointmentRepository(ref.watch(appDatabaseProvider).db),
);
