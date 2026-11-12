import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home_shell.dart';
import 'screens/splash_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) =>
          const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (BuildContext context, GoRouterState state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/forgot',
      builder: (BuildContext context, GoRouterState state) =>
          const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (BuildContext context, GoRouterState state) =>
          const RegisterScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (BuildContext context, GoRouterState state) => const HomeShell(),
    ),
  ],
);
