import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/appointments/presentation/screens/appointment_form_screen.dart';
import '../features/appointments/presentation/screens/appointments_screen.dart';
import '../features/appointments/presentation/screens/home_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/shell/app_shell.dart';
import '../features/splash/splash_screen.dart';

abstract final class AppRoutes {
  static const splash = '/';
  static const home = '/home';
  static const appointments = '/appointments';
  static const notifications = '/notifications';
  static const account = '/account';

  /// قائمة «مواعيدي» مفتوحة على تبويب معيّن (today, upcoming, past, completed).
  static String appointmentsTab(String tab) => '/appointments?tab=$tab';
  static const newAppointment = '/appointment/new';

  static String editAppointment(int id) => '/appointment/$id/edit';
}

final _rootKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: AppRoutes.home, builder: (_, _) => const HomeScreen())]),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.appointments,
                builder: (_, state) => AppointmentsScreen(initialTab: state.uri.queryParameters['tab']),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.notifications, builder: (_, _) => const NotificationsScreen())],
          ),
          StatefulShellBranch(routes: [GoRoute(path: AppRoutes.account, builder: (_, _) => const SettingsScreen())]),
        ],
      ),
      GoRoute(
        path: AppRoutes.newAppointment,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const AppointmentFormScreen(),
      ),
      GoRoute(
        path: '/appointment/:id/edit',
        parentNavigatorKey: _rootKey,
        builder: (_, state) => AppointmentFormScreen(appointmentId: int.parse(state.pathParameters['id']!)),
      ),
    ],
  );
});
