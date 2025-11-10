import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import '../screens/category/category_screen.dart';
import '../screens/startup/startup_screen.dart';
import '../screens/login/login_screen.dart';
import '../screens/signup/signup_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/theme/theme_screen.dart';
import '../screens/brands/brand_screen.dart';
import '../screens/tags/tag_screen.dart';
import '../screens/activities/activity_screen.dart';
import '../screens/activities/activity_create_screen.dart';
import '../services/auth_service.dart';

class AppRoutes {
  static const String startup = '/startup';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String themes = '/themes';
  static const String categories = '/categories';
  static const String brands = '/brands';
  static const String tags = '/tags';
  static const String activities = '/activities';
  static const String createActivity = '/activities/create';

  static GoRouter router(bool isLoggedIn, {GlobalKey<NavigatorState>? navigatorKey}) {
    return GoRouter(
      navigatorKey: navigatorKey,
      initialLocation: isLoggedIn ? home : login,
      redirect: (context, state) async {
        final authService = GetIt.I<AuthService>();
        final loggedIn = await authService.isLoggedIn();
        final isOnStartup = state.uri.path == startup;
        final isOnLogin = state.uri.path == login;
        final isOnSignup = state.uri.path == signup;

        // If logged in and trying to access startup/login/signup, redirect to home
        if (loggedIn && (isOnStartup || isOnLogin || isOnSignup)) {
          return home;
        }

        // If not logged in and not on public pages, redirect to login
        if (!loggedIn && !isOnStartup && !isOnLogin && !isOnSignup) {
          return login;
        }

        return null; // No redirect needed
      },
      routes: [
        GoRoute(
          path: startup,
          builder: (context, state) => const StartupScreen(),
        ),
        GoRoute(path: login, builder: (context, state) => const LoginScreen()),
        GoRoute(
          path: signup,
          builder: (context, state) => const SignupScreen(),
        ),
        GoRoute(
          path: home,
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: themes,
          builder: (context, state) => const ThemeScreen(),
        ),
        GoRoute(
          path: categories,
          builder: (context, state) => const CategoryScreen(),
        ),
        GoRoute(
          path: brands,
          builder: (context, state) => const BrandScreen(),
        ),
        GoRoute(
          path: tags,
          builder: (context, state) => const TagScreen(),
        ),
        GoRoute(
          path: activities,
          builder: (context, state) => const ActivityScreen(),
        ),
        GoRoute(
          path: createActivity,
          builder: (context, state) => const ActivityCreateScreen(),
        ),
      ],
    );
  }
}
