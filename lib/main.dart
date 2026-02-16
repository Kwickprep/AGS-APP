import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'app.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/storage_service.dart';
import 'services/theme_service.dart';
import 'services/category_service.dart';
import 'services/brand_service.dart';
import 'services/tag_service.dart';
import 'services/activity_service.dart';
import 'services/inquiry_service.dart';
import 'services/group_service.dart';
import 'services/product_service.dart';
import 'services/file_upload_service.dart';
import 'services/user_service.dart';
import 'services/activity_type_service.dart';
import 'services/company_service.dart';
import 'services/user_product_search_service.dart';
import 'services/whatsapp_service.dart';
import 'models/user_model.dart';
import 'services/dashboard_service.dart';
import 'services/whatsapp_template_category_service.dart';
import 'services/whatsapp_auto_reply_service.dart';
import 'services/whatsapp_campaign_service.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  // Services
  getIt.registerSingleton<StorageService>(StorageService());
  getIt.registerSingleton<ApiService>(ApiService());
  getIt.registerSingleton<AuthService>(AuthService());
  getIt.registerSingleton<ThemeService>(ThemeService());
  getIt.registerSingleton<CategoryService>(CategoryService());
  getIt.registerSingleton<BrandService>(BrandService());
  getIt.registerSingleton<TagService>(TagService());
  getIt.registerSingleton<ActivityService>(ActivityService());
  getIt.registerSingleton<InquiryService>(InquiryService());
  getIt.registerSingleton<GroupService>(GroupService());
  getIt.registerSingleton<ProductService>(ProductService());
  getIt.registerSingleton<FileUploadService>(FileUploadService());
  getIt.registerSingleton<UserService>(UserService());
  getIt.registerSingleton<ActivityTypeService>(ActivityTypeService());
  getIt.registerSingleton<CompanyService>(CompanyService());
  getIt.registerSingleton<UserProductSearchService>(UserProductSearchService());
  getIt.registerSingleton<WhatsAppService>(WhatsAppService());
  getIt.registerSingleton<DashboardService>(DashboardService());
  getIt.registerSingleton<WhatsAppTemplateCategoryService>(WhatsAppTemplateCategoryService());
  getIt.registerSingleton<WhatsAppAutoReplyService>(WhatsAppAutoReplyService());
  getIt.registerSingleton<WhatsAppCampaignService>(WhatsAppCampaignService());
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Setup dependencies
  setupDependencies();

  // Check session
  final authService = getIt<AuthService>();
  final isLoggedIn = await authService.checkAndRestoreSession();

  // Check if logged-in customer needs registration
  // Fetch fresh user data from API to avoid stale cache issues
  bool needsRegistration = false;
  String userId = '';
  if (isLoggedIn) {
    final storageService = getIt<StorageService>();
    final cachedUser = await storageService.getUser();
    if (cachedUser != null) {
      userId = cachedUser.id;
      try {
        // Fetch fresh user profile from backend
        final userService = getIt<UserService>();
        final freshUserData = await userService.getUserById(cachedUser.id);
        final freshUser = UserModel.fromJson(freshUserData['record'] as Map<String, dynamic>);
        // Update cache with fresh data
        await storageService.saveUser(freshUser);
        needsRegistration = freshUser.needsRegistration;
        userId = freshUser.id;
      } catch (_) {
        // API call failed (offline, etc.) — fall back to cached data
        needsRegistration = cachedUser.needsRegistration;
      }
    }
  }

  runApp(MyApp(
    isLoggedIn: isLoggedIn,
    needsRegistration: needsRegistration,
    userId: userId,
  ));
}