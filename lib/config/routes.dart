import 'package:ags/screens/activities/activity_screen_card.dart';
import 'package:ags/screens/brands/brand_screen_card.dart';
import 'package:ags/screens/category/category_screen_card.dart';
import 'package:ags/screens/groups/group_screen_card.dart';
import 'package:ags/screens/inquiries/inquiry_screen_new.dart';
import 'package:ags/screens/products/product_screen_card.dart';
import 'package:ags/screens/tags/tag_screen_card.dart';
import 'package:ags/screens/theme/theme_screen_card.dart';
import 'package:flutter/material.dart';
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
import '../screens/inquiries/inquiry_screen.dart';
import '../screens/inquiries/inquiry_create_screen.dart';
import '../screens/groups/group_screen.dart';
import '../screens/groups/group_create_screen.dart';
import '../screens/products/product_screen.dart';

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
  static const String inquiries = '/inquiries';
  static const String createInquiry = '/inquiries/create';
  static const String groups = '/groups';
  static const String createGroup = '/groups/create';
  static const String products = '/products';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      startup: (context) => const StartupScreen(),
      login: (context) => const LoginScreen(),
      signup: (context) => const SignupScreen(),
      home: (context) => const HomeScreen(),
      themes: (context) => const ThemeScreenCard(),
      categories: (context) => const CategoryScreenCard(),
      brands: (context) => const BrandScreenCard(),
      tags: (context) => const TagScreenCard(),
      activities: (context) => const ActivityScreenCard(),
      createActivity: (context) => const ActivityCreateScreen(),
      inquiries: (context) => const InquiryScreenNew(),
      createInquiry: (context) => const InquiryCreateScreen(),
      groups: (context) => const GroupScreenCard(),
      createGroup: (context) => const GroupCreateScreen(),
      products: (context) => const ProductScreenCard(),
    };
  }

  static String getInitialRoute(bool isLoggedIn) {
    return isLoggedIn ? home : login;
  }
}
