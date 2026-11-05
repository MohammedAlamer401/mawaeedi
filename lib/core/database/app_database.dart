import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// قاعدة SQLite المحلية داخل مساحة التطبيق الخاصة (القسم 8).
class AppDatabase {
  AppDatabase._(this.db);

  final Database db;

  static const fileName = 'mawaeedi.db';
  static const schemaVersion = 1;

  static Future<AppDatabase> open() async {
    final dir = await getDatabasesPath();
    final db = await openDatabase(
      p.join(dir, fileName),
      version: schemaVersion,
      onCreate: (db, version) async {
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
        await db.execute('CREATE INDEX idx_appointments_start ON appointments (start_at)');
        await db.execute('CREATE INDEX idx_appointments_status ON appointments (status, start_at)');
      },
      // الترحيلات المستقبلية تُضاف هنا حسب [schemaVersion].
      onUpgrade: (db, oldVersion, newVersion) async {},
    );
    return AppDatabase._(db);
  }
}

/// تُهيَّأ في `main` قبل تشغيل التطبيق ثم تُمرَّر عبر `overrideWithValue`.
final appDatabaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('appDatabaseProvider must be overridden in main()'),
);
