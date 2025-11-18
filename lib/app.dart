import 'package:flutter/material.dart';
import 'config/app_theme.dart';
import 'config/routes.dart';

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final GlobalKey<NavigatorState>? navigatorKey;

  const MyApp({Key? key, required this.isLoggedIn, this.navigatorKey}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      initialRoute: AppRoutes.getInitialRoute(isLoggedIn),
      routes: AppRoutes.getRoutes(),
    );
  }
}
