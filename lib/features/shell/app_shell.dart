import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/app_svg_icon.dart';
import '../notifications/notifications_providers.dart';
import '../settings/data/settings_repository.dart';

/// الصدفة الرئيسية مع شريط التنقل السفلي — كما في «نسبتي» ولوحة التصميم:
/// الرئيسية، مواعيدي، الإشعارات (بشارة غير المقروء)، حسابي.
///
/// الاتجاه RTL يجعل «الرئيسية» أول عنصر من اليمين تلقائياً.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const notificationsIndex = 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unseen = ref.watch(unseenRemindersCountProvider);
    Widget bell({required bool muted}) => Badge(
          isLabelVisible: unseen > 0 && navigationShell.currentIndex != notificationsIndex,
          label: Text('$unseen'),
          child: AppSvgIcon(AppSvgIcons.bell, muted: muted),
        );

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        destinations: [
          const NavigationDestination(
            icon: AppSvgIcon(AppSvgIcons.home, muted: true),
            selectedIcon: AppSvgIcon(AppSvgIcons.home),
            label: 'الرئيسية',
          ),
          const NavigationDestination(
            icon: AppSvgIcon(AppSvgIcons.calendar, muted: true),
            selectedIcon: AppSvgIcon(AppSvgIcons.calendar),
            label: 'مواعيدي',
          ),
          NavigationDestination(icon: bell(muted: true), selectedIcon: bell(muted: false), label: 'الإشعارات'),
          const NavigationDestination(
            icon: AppSvgIcon(AppSvgIcons.profile, muted: true),
            selectedIcon: AppSvgIcon(AppSvgIcons.profile),
            label: 'حسابي',
          ),
        ],
        onDestinationSelected: (index) {
          if (index == notificationsIndex) ref.read(settingsProvider.notifier).markNotificationsSeen();
          navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);
        },
      ),
    );
  }
}
