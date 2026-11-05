import 'package:flutter_test/flutter_test.dart';
import 'package:mawaeedi/core/formatting/date_formatter.dart';
import 'package:mawaeedi/features/appointments/data/appointment_model.dart';
import 'package:mawaeedi/features/appointments/data/appointment_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<Database> _openMemoryDb() async {
  sqfliteFfiInit();
  final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
  await db.execute('''
    CREATE TABLE appointments (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      notes TEXT,
      start_at TEXT NOT NULL,
      reminder_minutes INTEGER,
      notification_id INTEGER,
      status TEXT NOT NULL DEFAULT 'scheduled',
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
  ''');
  return db;
}

Appointment _draft(String title, DateTime startAt, {int? reminder = 15}) {
  final now = DateTime.now();
  return Appointment(title: title, startAt: startAt, reminderMinutes: reminder, createdAt: now, updatedAt: now);
}

void main() {
  late Database db;
  late AppointmentRepository repo;
  final today = DateFormatter.today();

  setUp(() async {
    db = await _openMemoryDb();
    repo = AppointmentRepository(db);
  });

  tearDown(() => db.close());

  test('الإضافة تحفظ الموعد وتجعل معرّف الإشعار = معرّف الموعد', () async {
    final saved = await repo.insertAppointment(_draft('الطبيب', today.add(const Duration(hours: 10))));
    expect(saved.id, isNotNull);
    expect(saved.notificationId, saved.id);

    final loaded = await repo.getAppointment(saved.id!);
    expect(loaded!.title, 'الطبيب');
    expect(loaded.notificationId, saved.id);
    expect(loaded.startAt, today.add(const Duration(hours: 10)));
    expect(loaded.reminderMinutes, 15);
  });

  test('تقسيم القوائم: اليوم، القادمة، السابقة، المكتملة', () async {
    await repo.insertAppointment(_draft('صباح اليوم', today.add(const Duration(hours: 9))));
    await repo.insertAppointment(_draft('مساء اليوم', today.add(const Duration(hours: 20))));
    await repo.insertAppointment(_draft('غداً', today.add(const Duration(days: 1, hours: 8))));
    final old = await repo.insertAppointment(_draft('أمس', today.subtract(const Duration(hours: 5))));
    final done = await repo.insertAppointment(_draft('بعد غد', today.add(const Duration(days: 2))));
    await repo.markAppointmentCompleted(done.id!);

    final day = await repo.getAppointmentsForDay(today);
    expect(day.map((a) => a.title), ['صباح اليوم', 'مساء اليوم']);

    expect((await repo.getUpcomingAppointments()).map((a) => a.title), ['غداً']);
    expect((await repo.getPastAppointments()).map((a) => a.id), [old.id]);
    expect((await repo.getCompletedAppointments()).map((a) => a.id), [done.id]);
  });

  test('التعديل والحذف', () async {
    final saved = await repo.insertAppointment(_draft('اجتماع', today.add(const Duration(days: 3))));
    await repo.updateAppointment(saved.copyWith(title: 'اجتماع العمل', reminderMinutes: () => null));
    final updated = await repo.getAppointment(saved.id!);
    expect(updated!.title, 'اجتماع العمل');
    expect(updated.reminderMinutes, isNull);

    await repo.deleteAppointment(saved.id!);
    expect(await repo.getAppointment(saved.id!), isNull);
  });

  test('التذكيرات المعلّقة تستثني المكتمل وبدون تذكير وما فات', () async {
    final now = DateTime.now();
    final future = await repo.insertAppointment(_draft('قادم', now.add(const Duration(hours: 3))));
    await repo.insertAppointment(_draft('بلا تذكير', now.add(const Duration(hours: 3)), reminder: null));
    await repo.insertAppointment(_draft('فات', now.subtract(const Duration(hours: 1))));
    final done = await repo.insertAppointment(_draft('مكتمل', now.add(const Duration(hours: 4))));
    await repo.markAppointmentCompleted(done.id!);

    final pending = await repo.getPendingReminders(now);
    expect(pending.map((a) => a.id), [future.id]);
  });
}
