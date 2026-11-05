import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/widgets/app_svg_icon.dart';
import '../appointments/controllers/appointments_controller.dart';

/// تهيئة الإشعارات ومزامنتها مع قاعدة البيانات عند كل تشغيل.
final appInitProvider = FutureProvider<void>((ref) async {
  await ref.read(notificationServiceProvider).initialize();
  await ref.read(appointmentsControllerProvider).resyncAll();
});

/// شاشة الإقلاع — بنفس أسلوب «نسبتي»: دوائر زخرفية، شعار، اسم وشعار نصي.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  static const minimumDuration = Duration(milliseconds: 1200);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final minimum = Future<void>.delayed(SplashScreen.minimumDuration);
    try {
      await ref.read(appInitProvider.future);
    } catch (_) {
      // فشل تهيئة الإشعارات لا يمنع استخدام التطبيق.
    }
    await minimum;
    if (mounted) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.background,
      body: Stack(
        children: [
          PositionedDirectional(top: -170, end: -150, child: _blob(320, p.primarySoft)),
          PositionedDirectional(bottom: -190, start: -150, child: _blob(360, p.primarySoft)),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const MawaeediLogo(size: 150),
                    const SizedBox(height: 12),
                    Text(
                      'مواعيدي',
                      style: AppTextStyles.style(60, FontWeight.w800, color: p.primaryDark, height: 1.5),
                    ),
                    Text(
                      'جدولي .. في متناول يدي',
                      style: AppTextStyles.style(19, FontWeight.w500, color: p.textSecondary),
                    ),
                    const SizedBox(height: 56),
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(
                        strokeWidth: 3.5,
                        color: p.primary,
                        backgroundColor: p.primarySoft,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blob(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.8), shape: BoxShape.circle),
      );
}
