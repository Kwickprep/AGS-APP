import 'package:flutter/material.dart';
import 'config/app_theme.dart';
import 'config/routes.dart';
import 'core/permissions/permission_manager.dart';

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final bool needsRegistration;
  final String userId;
  final GlobalKey<NavigatorState>? navigatorKey;

  const MyApp({
    super.key,
    required this.isLoggedIn,
    this.needsRegistration = false,
    this.userId = '',
    this.navigatorKey,
  });

  // Routes that CUSTOMER users must NOT access
  static const _adminOnlyRoutes = {
    AppRoutes.home,
    AppRoutes.themes,
    AppRoutes.createTheme,
    AppRoutes.categories,
    AppRoutes.createCategory,
    AppRoutes.brands,
    AppRoutes.createBrand,
    AppRoutes.tags,
    AppRoutes.createTag,
    AppRoutes.activities,
    AppRoutes.createActivity,
    AppRoutes.inquiries,
    AppRoutes.createInquiry,
    AppRoutes.groups,
    AppRoutes.createGroup,
    AppRoutes.products,
    AppRoutes.users,
    AppRoutes.createUser,
    AppRoutes.activityTypes,
    AppRoutes.createActivityType,
    AppRoutes.companies,
    AppRoutes.createCompany,
    AppRoutes.messages,
    AppRoutes.templateCategories,
    AppRoutes.createTemplateCategory,
    AppRoutes.autoReplies,
    AppRoutes.createAutoReply,
    AppRoutes.campaigns,
    AppRoutes.createCampaign,
  };

  @override
  Widget build(BuildContext context) {
    String initialRoute;
    if (!isLoggedIn) {
      initialRoute = AppRoutes.login;
    } else if (needsRegistration) {
      initialRoute = AppRoutes.registration;
    } else {
      initialRoute = AppRoutes.getHomeRoute();
    }

    return MaterialApp(
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      initialRoute: initialRoute,
      onGenerateRoute: (settings) {
        // Inject userId for registration when launched as initial route
        if (settings.name == AppRoutes.registration && settings.arguments == null) {
          return MaterialPageRoute(
            builder: (context) =>
                AppRoutes.getRoutes()[AppRoutes.registration]!(context),
            settings: RouteSettings(
              name: AppRoutes.registration,
              arguments: {'userId': userId},
            ),
          );
        }

        // Route guard: block CUSTOMER from admin routes
        final role = PermissionManager().role;
        if (role == 'CUSTOMER' && _adminOnlyRoutes.contains(settings.name)) {
          return MaterialPageRoute(
            builder: (_) => const _UnauthorizedScreen(),
            settings: settings,
          );
        }

        final builder = AppRoutes.getRoutes()[settings.name];
        if (builder != null) {
          return MaterialPageRoute(
            builder: builder,
            settings: settings,
          );
        }
        return null;
      },
    );
  }
}

class _UnauthorizedScreen extends StatelessWidget {
  const _UnauthorizedScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Access Denied')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'You do not have access to this page.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pushReplacementNamed(
                AppRoutes.getHomeRoute(),
              ),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}
