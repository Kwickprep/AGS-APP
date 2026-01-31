import 'package:flutter/material.dart';
import 'config/app_theme.dart';
import 'config/routes.dart';

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
