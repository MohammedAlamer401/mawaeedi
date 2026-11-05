import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/app_svg_icon.dart';

/// الصدفة الرئيسية مع شريط التنقل السفلي.
///
/// الاتجاه RTL يجعل «الرئيسية» أول عنصر من اليمين تلقائياً.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const destinations = [
    NavigationDestination(
      icon: AppSvgIcon(AppSvgIcons.home, muted: true),
      selectedIcon: AppSvgIcon(AppSvgIcons.home),
      label: 'الرئيسية',
    ),
    NavigationDestination(
      icon: AppSvgIcon(AppSvgIcons.calendar, muted: true),
      selectedIcon: AppSvgIcon(AppSvgIcons.calendar),
      label: 'مواعيدي',
    ),
    NavigationDestination(
      icon: AppSvgIcon(AppSvgIcons.settings, muted: true),
      selectedIcon: AppSvgIcon(AppSvgIcons.settings),
      label: 'الإعدادات',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        destinations: destinations,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
