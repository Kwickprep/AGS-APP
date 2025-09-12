import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import '../screens/category/category_screen.dart';
import '../screens/startup/startup_screen.dart';
import '../screens/login/login_screen.dart';
import '../screens/signup/signup_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/theme/theme_screen.dart';

import '../screens/brands/brand_screen.dart';
import '../services/auth_service.dart';

class AppRoutes {
  static const String startup = '/startup';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String themes = '/themes';
  static const String categories = '/categories';
  static const String brands = '/brands';

  static GoRouter router(bool isLoggedIn) {
    return GoRouter(
      initialLocation: isLoggedIn ? home : startup,
      routes: [
        GoRoute(
          path: startup,
          builder: (context, state) => const StartupScreen(),
        ),
        GoRoute(
          path: login,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: signup,
          builder: (context, state) => const SignupScreen(),
        ),
        GoRoute(
          path: home,
          builder: (context, state) => const HomeScreen(),
          redirect: (context, state) async {
            // Double-check authentication status
            final authService = GetIt.I<AuthService>();
            final isLoggedIn = await authService.isLoggedIn();
            if (!isLoggedIn) {
              return login;
            }
            return null;
          },
        ),
        GoRoute(
          path: themes,
          builder: (context, state) => const ThemeScreen(),
          redirect: (context, state) async {
            final authService = GetIt.I<AuthService>();
            final isLoggedIn = await authService.isLoggedIn();
            if (!isLoggedIn) {
              return login;
            }
            return null;
          },
        ),
        GoRoute(
          path: categories,
          builder: (context, state) => const CategoryScreen(),
          redirect: (context, state) async {
            final authService = GetIt.I<AuthService>();
            final isLoggedIn = await authService.isLoggedIn();
            if (!isLoggedIn) {
              return login;
            }
            return null;
          },
        ),
        GoRoute(
          path: brands,
          builder: (context, state) => const BrandScreen(),
          redirect: (context, state) async {
            final authService = GetIt.I<AuthService>();
            final isLoggedIn = await authService.isLoggedIn();
            if (!isLoggedIn) {
              return login;
            }
            return null;
          },
        ),
      ],
    );
  }
}