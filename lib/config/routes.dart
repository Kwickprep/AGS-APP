import 'package:go_router/go_router.dart';
import '../screens/brands/brand_screen.dart';
import '../screens/category/category_screen.dart';
import '../screens/startup/startup_screen.dart';
import '../screens/login/login_screen.dart';
import '../screens/signup/signup_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/theme/theme_screen.dart';

class AppRoutes {
  static const String startup = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String categories = '/categories';
  static const String themes = '/themes';
  static const String brands = '/brands';


  static final router = GoRouter(
    initialLocation: startup,
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
    ],
  );
}