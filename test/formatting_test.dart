import 'package:flutter_test/flutter_test.dart';
import 'package:mawaeedi/core/formatting/arabic_plural.dart';
import 'package:mawaeedi/core/formatting/date_formatter.dart';
import 'package:mawaeedi/features/appointments/data/appointment_model.dart';

void main() {
  test('صيغة الوقت 12 ساعة بالعربية', () {
    expect(DateFormatter.time(DateTime(2026, 11, 5, 9, 5)), '09:05 صباحاً');
    expect(DateFormatter.time(DateTime(2026, 11, 5, 0, 30)), '12:30 صباحاً');
    expect(DateFormatter.time(DateTime(2026, 11, 5, 12, 0)), '12:00 مساءً');
    expect(DateFormatter.time(DateTime(2026, 11, 5, 17, 45)), '05:45 مساءً');
  });

  test('التاريخ الكامل باسم اليوم', () {
    expect(DateFormatter.full(DateTime(2026, 11, 5)), 'الخميس، 5 نوفمبر 2026');
  });

  test('اليوم النسبي', () {
    final today = DateFormatter.today();
    expect(DateFormatter.relativeDay(today.add(const Duration(hours: 9))), 'اليوم');
    expect(DateFormatter.relativeDay(today.add(const Duration(days: 1))), 'غداً');
    expect(DateFormatter.relativeDay(today.subtract(const Duration(days: 1))), 'أمس');
  });

  test('صيغ العدد العربية', () {
    expect(ArabicPlural.appointments(1), 'موعد واحد');
    expect(ArabicPlural.appointments(2), 'موعدان');
    expect(ArabicPlural.appointments(5), '5 مواعيد');
    expect(ArabicPlural.appointments(12), '12 موعداً');
    expect(ArabicPlural.reminder(60), 'قبل الموعد بساعة');
    expect(ArabicPlural.reminder(15), 'قبل الموعد بـ 15 دقيقة');
  });

  test('صيغة التخزين ثابتة الطول وتعود لنفس الوقت المحلي', () {
    final t = DateTime(2026, 11, 5, 10, 30, 0, 123);
    final stored = Appointment.toStorage(t);
    expect(stored, endsWith('.000Z'));
    expect(Appointment.fromStorage(stored), DateTime(2026, 11, 5, 10, 30));
  });

  test('وقت التذكير', () {
    final now = DateTime(2026, 11, 5, 8);
    final a = Appointment(
      title: 'x',
      startAt: DateTime(2026, 11, 5, 10),
      reminderMinutes: 30,
      createdAt: now,
      updatedAt: now,
    );
    expect(a.remindAt, DateTime(2026, 11, 5, 9, 30));
    expect(a.copyWith(reminderMinutes: () => null).remindAt, isNull);
  });
}
