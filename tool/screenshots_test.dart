// يلتقط صوراً للشاشات بالخط الحقيقي للمراجعة البصرية — بنفس أداة «نسبتي».
// التشغيل: flutter test tool/screenshots_test.dart --update-goldens
// الصور تُحفظ في build/screenshots/.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mawaeedi/core/formatting/date_formatter.dart';

import '../test/helpers/test_app.dart';

Future<void> _loadFonts() async {
  final cairo = FontLoader('Cairo')..addFont(rootBundle.load('assets/fonts/Cairo-Variable.ttf'));
  await cairo.load();
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  final icons = File('$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (flutterRoot != null && icons.existsSync()) {
    final loader = FontLoader('MaterialIcons')..addFont(icons.readAsBytes().then(ByteData.sublistView));
    await loader.load();
  }
}

Future<void> _shot(String name) =>
    expectLater(find.byType(MaterialApp), matchesGoldenFile('../build/screenshots/$name.png'));

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// بيانات نموذجية: مواعيد اليوم (منها مكتمل وفائت) والقادمة والسابقة.
void _seed(TestApp app) {
  final now = DateTime.now();
  final today = DateFormatter.today();
  app.repo
    ..add('اجتماع العمل', now.subtract(const Duration(hours: 2)), reminder: 30, completed: true)
    ..add('موعد طبيب الأسنان', now.subtract(const Duration(minutes: 40)), reminder: 15)
    ..add('مراجعة المشروع', now.add(const Duration(hours: 3)), reminder: 60, notes: 'إحضار ملف العرض والتقرير الشهري')
    ..add('تمرين الرياضة', today.add(const Duration(hours: 23, minutes: 30)), reminder: null)
    ..add('زيارة الوالدة', today.add(const Duration(days: 1, hours: 17)), reminder: 30)
    ..add('تجديد جواز السفر', today.add(const Duration(days: 3, hours: 10)), reminder: 60)
    ..add('دفع فاتورة الإنترنت', today.subtract(const Duration(days: 2)).add(const Duration(hours: 12)), reminder: 10);
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('screens', (tester) async {
    _phone(tester);
    final app = await TestApp.create(prefs: {'display_name': 'محمد الأمير'});
    addTearDown(app.dispose);
    _seed(app);
    await app.pump(tester);
    await _shot('01_home');

    await tapVisible(tester, find.text('مواعيدي').last);
    await _shot('02_appointments');

    await tapVisible(tester, find.text('الإشعارات').last);
    await _shot('03_notifications');

    await tapVisible(tester, find.text('حسابي').last);
    await _shot('04_account');

    app.push('/appointment/3/edit');
    await settle(tester);
    await _shot('05_form');
    await tester.scrollUntilVisible(find.text('سيصلك التذكير'), 200, scrollable: find.byType(Scrollable).last);
    await settle(tester);
    await _shot('06_form_reminder');
  });

  testWidgets('details sheet + dark', (tester) async {
    _phone(tester);
    final app = await TestApp.create(prefs: {'display_name': 'محمد', 'theme_mode': 'dark'});
    addTearDown(app.dispose);
    _seed(app);
    await app.pump(tester);
    await _shot('07_home_dark');
    await tapVisible(tester, find.text('مراجعة المشروع').first);
    await _shot('08_details_sheet_dark');
  });

  testWidgets('empty', (tester) async {
    _phone(tester);
    final app = await TestApp.create();
    addTearDown(app.dispose);
    await app.pump(tester);
    await _shot('09_home_empty');
  });
}
