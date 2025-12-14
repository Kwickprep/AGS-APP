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
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Setup dependencies
  setupDependencies();

  // Check session
  final authService = getIt<AuthService>();
  final isLoggedIn = await authService.checkAndRestoreSession();

  runApp(MyApp(isLoggedIn: isLoggedIn));
}