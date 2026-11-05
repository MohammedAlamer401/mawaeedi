import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/appointments/presentation/screens/appointment_form_screen.dart';
import '../features/appointments/presentation/screens/appointments_screen.dart';
import '../features/appointments/presentation/screens/home_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/shell/app_shell.dart';
import '../features/splash/splash_screen.dart';

abstract final class AppRoutes {
  static const splash = '/';
  static const home = '/home';
  static const appointments = '/appointments';
  static const settings = '/settings';
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
            routes: [GoRoute(path: AppRoutes.appointments, builder: (_, _) => const AppointmentsScreen())],
          ),
          StatefulShellBranch(routes: [GoRoute(path: AppRoutes.settings, builder: (_, _) => const SettingsScreen())]),
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
