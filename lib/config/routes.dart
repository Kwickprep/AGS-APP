import 'package:ags/screens/activities/activity_screen.dart';
import 'package:ags/screens/products/product_screen.dart';
import 'package:ags/screens/user_home/customer_shell.dart';
import 'package:ags/screens/messages/message_screen.dart';
import 'package:ags/core/permissions/permission_manager.dart';
import 'package:ags/screens/registration/registration_screen.dart';

import 'package:flutter/material.dart';
import '../screens/category/category_screen.dart';
import '../screens/category/category_create_screen.dart';
import '../screens/groups/group_screen.dart';
import '../screens/startup/startup_screen.dart';
import '../screens/login/login_screen.dart';
import '../screens/signup/signup_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/theme/theme_screen.dart';
import '../screens/theme/theme_create_screen.dart';
import '../screens/brands/brand_screen.dart';
import '../screens/brands/brand_create_screen.dart';
import '../screens/tags/tag_screen.dart';
import '../screens/tags/tag_create_screen.dart';
import '../screens/activities/activity_create_screen.dart';
import '../screens/inquiries/inquiry_screen.dart';
import '../screens/inquiries/inquiry_create_screen.dart';
import '../screens/groups/group_create_screen.dart';
import '../screens/users/user_screen.dart';
import '../screens/users/user_create_screen.dart';
import '../screens/activity_types/activity_type_screen.dart';
import '../screens/activity_types/activity_type_create_screen.dart';
import '../screens/companies/company_screen.dart';
import '../screens/companies/company_create_screen.dart';
import '../screens/whatsapp_template_categories/template_category_screen.dart';
import '../screens/whatsapp_template_categories/template_category_create_screen.dart';
import '../screens/whatsapp_auto_replies/auto_reply_screen.dart';
import '../screens/whatsapp_auto_replies/auto_reply_create_screen.dart';
import '../screens/whatsapp_campaigns/campaign_screen.dart';
import '../screens/whatsapp_campaigns/campaign_create_screen.dart';

class AppRoutes {
  static const String startup = '/startup';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String themes = '/themes';
  static const String createTheme = '/themes/create';
  static const String categories = '/categories';
  static const String createCategory = '/categories/create';
  static const String brands = '/brands';
  static const String createBrand = '/brands/create';
  static const String tags = '/tags';
  static const String createTag = '/tags/create';
  static const String activities = '/activities';
  static const String createActivity = '/activities/create';
  static const String inquiries = '/inquiries';
  static const String createInquiry = '/inquiries/create';
  static const String groups = '/groups';
  static const String createGroup = '/groups/create';
  static const String products = '/products';
  static const String users = '/users';
  static const String createUser = '/users/create';
  static const String activityTypes = '/activity-types';
  static const String createActivityType = '/activity-types/create';
  static const String companies = '/companies';
  static const String createCompany = '/companies/create';
  static const String userHome = '/userHome';
  static const String registration = '/registration';
  static const String messages = '/messages';
  static const String templateCategories = '/whatsapp/template-categories';
  static const String createTemplateCategory = '/whatsapp/template-categories/create';
  static const String autoReplies = '/whatsapp/auto-replies';
  static const String createAutoReply = '/whatsapp/auto-replies/create';
  static const String campaigns = '/whatsapp/campaigns';
  static const String createCampaign = '/whatsapp/campaigns/create';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      startup: (context) => const StartupScreen(),
      login: (context) => const LoginScreen(),
      signup: (context) => const SignupScreen(),
      home: (context) => const HomeScreen(),
      themes: (context) => const ThemeScreen(),
      createTheme: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return ThemeCreateScreen(
          isEdit: args?['isEdit'] ?? false,
          themeData: args?['themeData'],
        );
      },
      categories: (context) => const CategoryScreen(),
      createCategory: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return CategoryCreateScreen(
          isEdit: args?['isEdit'] ?? false,
          categoryData: args?['categoryData'],
        );
      },
      brands: (context) => const BrandScreen(),
      createBrand: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return BrandCreateScreen(
          isEdit: args?['isEdit'] ?? false,
          brandData: args?['brandData'],
        );
      },
      tags: (context) => const TagScreen(),
      createTag: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return TagCreateScreen(
          isEdit: args?['isEdit'] ?? false,
          tagData: args?['tagData'],
        );
      },
      activities: (context) => const ActivityScreen(),
      createActivity: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return ActivityCreateScreen(
          isEdit: args?['isEdit'] ?? false,
          activity: args?['activity'],
        );
      },
      inquiries: (context) => const InquiryScreen(),
      createInquiry: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return InquiryCreateScreen(
          isEdit: args?['isEdit'] ?? false,
          inquiryData: args?['inquiryData'],
        );
      },
      groups: (context) => const GroupScreen(),
      createGroup: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return GroupCreateScreen(
          group: args?['group'],
          isEdit: args?['isEdit'] ?? false,
        );
      },
      products: (context) => const ProductScreen(),
      users: (context) => const UserScreen(),
      createUser: (context) => const UserCreateScreen(),
      activityTypes: (context) => const ActivityTypeScreen(),
      createActivityType: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return ActivityTypeCreateScreen(
          isEdit: args?['isEdit'] ?? false,
          activityTypeData: args?['activityTypeData'],
        );
      },
      companies: (context) => const CompanyScreen(),
      createCompany: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return CompanyCreateScreen(
          isEdit: args?['isEdit'] ?? false,
          companyData: args?['companyData'],
        );
      },
      userHome: (context) {
        return const CustomerShell();
      },
      registration: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return RegistrationScreen(userId: args?['userId'] ?? '');
      },
      messages: (context) => const MessageScreen(),
      // WhatsApp sub-modules
      templateCategories: (context) => const TemplateCategoryScreen(),
      createTemplateCategory: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return TemplateCategoryCreateScreen(
          isEdit: args?['isEdit'] ?? false,
          data: args?['data'],
        );
      },
      autoReplies: (context) => const AutoReplyScreen(),
      createAutoReply: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return AutoReplyCreateScreen(
          isEdit: args?['isEdit'] ?? false,
          data: args?['data'],
        );
      },
      campaigns: (context) => const CampaignScreen(),
      createCampaign: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return CampaignCreateScreen(
          isEdit: args?['isEdit'] ?? false,
          data: args?['data'],
        );
      },
    };
  }

  static String getInitialRoute(bool isLoggedIn) {
    if (!isLoggedIn) return login;
    return getHomeRoute();
  }

  /// Get the appropriate home route based on user role
  static String getHomeRoute() {
    final role = PermissionManager().role;
    if (role == 'CUSTOMER') {
      return userHome;
    }
    return home;
  }
}
