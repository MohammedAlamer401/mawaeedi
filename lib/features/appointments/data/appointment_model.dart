/// حالة الموعد كما تُخزَّن في العمود `status`.
enum AppointmentStatus {
  scheduled('scheduled'),
  completed('completed');

  const AppointmentStatus(this.value);

  final String value;

  static AppointmentStatus parse(String value) =>
      values.firstWhere((s) => s.value == value, orElse: () => scheduled);
}

/// خيارات التذكير المعروضة في النموذج (بالدقائق). `null` = بدون تذكير.
const reminderOptions = <int?>[null, 5, 10, 15, 30, 60];

/// موعد واحد — يطابق جدول `appointments` في القسم 8 من التحليل.
///
/// [startAt] بالوقت المحلي داخل التطبيق، ويُخزَّن بتوقيت UTC بصيغة ISO-8601.
class Appointment {
  const Appointment({
    this.id,
    required this.title,
    this.notes,
    required this.startAt,
    this.reminderMinutes,
    this.notificationId,
    this.status = AppointmentStatus.scheduled,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String title;
  final String? notes;
  final DateTime startAt;
  final int? reminderMinutes;
  final int? notificationId;
  final AppointmentStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isCompleted => status == AppointmentStatus.completed;

  bool get hasReminder => reminderMinutes != null;

  /// وقت التنبيه، أو `null` إن لم يكن هناك تذكير.
  DateTime? get remindAt => reminderMinutes == null ? null : startAt.subtract(Duration(minutes: reminderMinutes!));

  /// موعد لم يكتمل وقد فات وقته.
  bool isOverdue(DateTime now) => !isCompleted && startAt.isBefore(now);

  Appointment copyWith({
    int? id,
    String? title,
    String? Function()? notes,
    DateTime? startAt,
    int? Function()? reminderMinutes,
    int? Function()? notificationId,
    AppointmentStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Appointment(
      id: id ?? this.id,
      title: title ?? this.title,
      notes: notes == null ? this.notes : notes(),
      startAt: startAt ?? this.startAt,
      reminderMinutes: reminderMinutes == null ? this.reminderMinutes : reminderMinutes(),
      notificationId: notificationId == null ? this.notificationId : notificationId(),
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// صيغة تخزين ثابتة الطول (UTC، بالثواني) حتى تصح المقارنة النصية في SQL.
  static String toStorage(DateTime value) {
    final u = value.toUtc();
    return DateTime.utc(u.year, u.month, u.day, u.hour, u.minute, u.second).toIso8601String();
  }

  static DateTime fromStorage(String value) => DateTime.parse(value).toLocal();

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'title': title,
        'notes': notes,
        'start_at': toStorage(startAt),
        'reminder_minutes': reminderMinutes,
        'notification_id': notificationId,
        'status': status.value,
        'created_at': toStorage(createdAt),
        'updated_at': toStorage(updatedAt),
      };

  factory Appointment.fromMap(Map<String, Object?> map) => Appointment(
        id: map['id'] as int,
        title: map['title'] as String,
        notes: map['notes'] as String?,
        startAt: fromStorage(map['start_at'] as String),
        reminderMinutes: map['reminder_minutes'] as int?,
        notificationId: map['notification_id'] as int?,
        status: AppointmentStatus.parse(map['status'] as String),
        createdAt: fromStorage(map['created_at'] as String),
        updatedAt: fromStorage(map['updated_at'] as String),
      );
}
