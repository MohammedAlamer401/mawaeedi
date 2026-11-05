import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/appointments/controllers/appointments_controller.dart';
import '../features/settings/data/settings_repository.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class MawaeediApp extends ConsumerStatefulWidget {
  const MawaeediApp({super.key});

  @override
  ConsumerState<MawaeediApp> createState() => _MawaeediAppState();
}

class _MawaeediAppState extends ConsumerState<MawaeediApp> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // عند العودة للتطبيق قد يتغير «اليوم» أو تفوت مواعيد: نحدّث القوائم.
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.read(appointmentsRevisionProvider.notifier).bump(),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(settingsProvider.select((s) => s.themeMode));
    return MaterialApp.router(
      title: 'مواعيدي',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: ref.watch(routerProvider),
      // العربية فقط؛ الاتجاه RTL يأتي من اللغة تلقائياً.
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    );
  }
}
