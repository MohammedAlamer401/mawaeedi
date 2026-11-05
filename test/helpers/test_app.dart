import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mawaeedi/app/app.dart';
import 'package:mawaeedi/app/router.dart';
import 'package:mawaeedi/core/notifications/notification_service.dart';
import 'package:mawaeedi/features/appointments/data/appointment_repository.dart';
import 'package:mawaeedi/features/settings/data/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

/// تطبيق كامل فوق مستودع وإشعارات وهمية.
class TestApp {
  TestApp._(this.container, this.repo, this.notifications);

  final ProviderContainer container;
  final FakeAppointmentRepository repo;
  final FakeNotificationService notifications;

  static Future<TestApp> create({Map<String, Object> prefs = const {}}) async {
    SharedPreferences.setMockInitialValues(prefs);
    final sp = await SharedPreferences.getInstance();
    final repo = FakeAppointmentRepository();
    final notifications = FakeNotificationService();
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(sp),
      appointmentRepositoryProvider.overrideWithValue(repo),
      notificationServiceProvider.overrideWithValue(notifications),
    ]);
    return TestApp._(container, repo, notifications);
  }

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const MawaeediApp()));
    // شاشة الإقلاع تبقى 1.2 ثانية على الأقل.
    await tester.pump(const Duration(milliseconds: 1500));
    await settle(tester);
  }

  void go(String location) => container.read(routerProvider).go(location);

  void push(String location) => container.read(routerProvider).push(location);

  void dispose() => container.dispose();
}

/// انتظار الرسوم المتحركة دون التعلّق بمؤشرات التحميل الدوّارة.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await settle(tester);
}
