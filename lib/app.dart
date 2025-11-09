import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'config/app_theme.dart';
import 'config/routes.dart';

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final GlobalKey<NavigatorState>? navigatorKey;

  const MyApp({Key? key, required this.isLoggedIn, this.navigatorKey}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: AppRoutes.router(isLoggedIn, navigatorKey: navigatorKey),
    );
  }
}