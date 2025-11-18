import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../config/app_colors.dart';
import '../../services/activity_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_toast.dart';

class ActivityCreateScreen extends StatefulWidget {
  const ActivityCreateScreen({Key? key}) : super(key: key);

  @override
  State<ActivityCreateScreen> createState() => _ActivityCreateScreenState();
}

class _ActivityCreateScreenState extends State<ActivityCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final ActivityService _activityService = GetIt.I<ActivityService>();

  // Form controllers
  final _activityTypeController = TextEditingController();
  final _companyController = TextEditingController();
  final _inquiryController = TextEditingController();
  final _userController = TextEditingController();
  final _themeController = TextEditingController();
  final _categoryController = TextEditingController();
  final _priceRangeController = TextEditingController();
  final _productController = TextEditingController();
  final _moqController = TextEditingController();
  final _documentsController = TextEditingController();
  final _nextScheduleDateController = TextEditingController();
  final _noteController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _activityTypeController.dispose();
    _companyController.dispose();
    _inquiryController.dispose();
    _userController.dispose();
    _themeController.dispose();
    _categoryController.dispose();
    _priceRangeController.dispose();
    _productController.dispose();
    _moqController.dispose();
    _documentsController.dispose();
    _nextScheduleDateController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _createActivity() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final data = {
        'activityType': _activityTypeController.text.trim(),
        'company': _companyController.text.trim(),
        'inquiry': _inquiryController.text.trim(),
        'user': _userController.text.trim(),
        'theme': _themeController.text.trim(),
        'category': _categoryController.text.trim(),
        'priceRange': _priceRangeController.text.trim(),
        'product': _productController.text.trim(),
        'moq': _moqController.text.trim(),
        'documents': _documentsController.text.trim(),
        'nextScheduleDate': _nextScheduleDateController.text.trim(),
        'note': _noteController.text.trim(),
      };

      await _activityService.createActivity(data);

      if (mounted) {
        CustomToast.show(
          context,
          'Activity created successfully',
          type: ToastType.success,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          e.toString().replaceAll('Exception: ', ''),
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Create Activity'),
        backgroundColor: AppColors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Activity Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      CustomTextField(
                        controller: _activityTypeController,
                        label: 'Activity Type',
                        hint: 'Enter activity type',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter activity type';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _companyController,
                        label: 'Company',
                        hint: 'Enter company name',
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _inquiryController,
                        label: 'Inquiry',
                        hint: 'Enter inquiry',
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _userController,
                        label: 'User',
                        hint: 'Enter user',
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _themeController,
                        label: 'Theme',
                        hint: 'Enter theme',
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _categoryController,
                        label: 'Category',
                        hint: 'Enter category',
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _priceRangeController,
                        label: 'Price Range',
                        hint: 'Enter price range',
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _productController,
                        label: 'Product',
                        hint: 'Enter product',
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _moqController,
                        label: 'MOQ',
                        hint: 'Enter minimum order quantity',
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _documentsController,
                        label: 'Documents',
                        hint: 'Enter documents',
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _nextScheduleDateController,
                        label: 'Next Schedule Date',
                        hint: 'Enter next schedule date',
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _noteController,
                        label: 'Details/Notes',
                        hint: 'Enter activity details or notes',
                        // maxLines: 4,
                      ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).padding.bottom + 16,
                        ),
                        child: CustomButton(
                          onPressed: _isLoading ? (){} : _createActivity,
                          text: _isLoading ? 'Creating...' : 'Create Activity',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}
