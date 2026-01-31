import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../config/app_colors.dart';
import '../../config/routes.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_toast.dart';
import 'registration_bloc.dart';

class RegistrationScreen extends StatelessWidget {
  final String userId;

  const RegistrationScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RegistrationBloc(userId: userId),
      child: const RegistrationView(),
    );
  }
}

class RegistrationView extends StatefulWidget {
  const RegistrationView({super.key});

  @override
  State<RegistrationView> createState() => _RegistrationViewState();
}

class _RegistrationViewState extends State<RegistrationView> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _customDepartmentController = TextEditingController();
  final _customDivisionController = TextEditingController();

  int _currentStep = 0;

  String? _selectedIndustry;
  String? _selectedDepartment;
  String? _selectedDivision;
  bool _showCustomDepartment = false;
  bool _showCustomDivision = false;

  static const List<String> industries = [
    'Pharma',
    'IT',
    'Banking',
    'Telecom',
    'Education',
    'Cement and Ceramics',
    'Textiles and Apparel',
    'Metal',
    'Food and Beverage',
    'Others',
  ];

  static const List<String> departments = [
    'Marketing',
    'Sales',
    'HR / Admin',
    'Procurement',
    'Other',
  ];

  static const List<String> therapies = [
    'Cardiovascular (Cardiac)',
    'Anti-Infectives',
    'Gastrointestinal (GI)',
    'Anti-Diabetic',
    'CNS',
    'Dermatology',
    'Urology',
    'Gynecology',
    'Orthopedics',
    'Others',
  ];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _companyNameController.dispose();
    _customDepartmentController.dispose();
    _customDivisionController.dispose();
    super.dispose();
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _firstNameController.text.trim().isNotEmpty &&
            _lastNameController.text.trim().isNotEmpty;
      case 1:
        return _selectedIndustry != null &&
            _companyNameController.text.trim().isNotEmpty;
      case 2:
        if (_showCustomDepartment) {
          return _customDepartmentController.text.trim().isNotEmpty;
        }
        return _selectedDepartment != null;
      case 3:
        if (_showCustomDivision) {
          return _customDivisionController.text.trim().isNotEmpty;
        }
        return _selectedDivision != null;
      default:
        return false;
    }
  }

  void _nextStep() {
    if (!_validateCurrentStep()) {
      CustomToast.show(
        context,
        'Please fill in all required fields',
        type: ToastType.error,
      );
      return;
    }

    if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      _submitRegistration();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  void _submitRegistration() {
    final department = _showCustomDepartment
        ? _customDepartmentController.text.trim()
        : _selectedDepartment!;
    final division = _showCustomDivision
        ? _customDivisionController.text.trim()
        : _selectedDivision!;

    context.read<RegistrationBloc>().add(
      SubmitRegistration(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        industry: _selectedIndustry!,
        companyName: _companyNameController.text.trim(),
        department: department,
        division: division,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<RegistrationBloc, RegistrationState>(
        listener: (context, state) {
          if (state is RegistrationSuccess) {
            CustomToast.show(
              context,
              'Registration complete! Welcome to AGS.',
              type: ToastType.success,
            );
            Future.delayed(const Duration(milliseconds: 400), () {
              if (context.mounted) {
                Navigator.pushReplacementNamed(
                  context,
                  AppRoutes.userHome,
                );
              }
            });
          } else if (state is RegistrationError) {
            CustomToast.show(context, state.message, type: ToastType.error);
          }
        },
        builder: (context, state) {
          final isLoading = state is RegistrationLoading;
          return SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(),
                // Progress indicator
                _buildProgressBar(),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: _buildStepContent(),
                  ),
                ),
                // Navigation buttons
                _buildNavigationButtons(isLoading),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    const stepTitles = [
      'Your Name',
      'Your Organization',
      'Your Department',
      'Your Therapy / Division',
    ];
    const stepSubtitles = [
      'Let us know who you are',
      'Tell us about your company',
      'Which department do you work in?',
      'Select your therapy area',
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset('assets/images/ags_icon.png', width: 48, height: 48),
          const SizedBox(height: 20),
          Text(
            stepTitles[_currentStep],
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            stepSubtitles[_currentStep],
            style: TextStyle(
              fontSize: 15,
              color: AppColors.grey,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: List.generate(4, (index) {
          final isActive = index <= _currentStep;
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index < 3 ? 6 : 0),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primary
                    : AppColors.lightGrey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildNameStep();
      case 1:
        return _buildOrganizationStep();
      case 2:
        return _buildDepartmentStep();
      case 3:
        return _buildDivisionStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildNameStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('First Name', isRequired: true),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _firstNameController,
          hint: 'Enter your first name',
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 24),
        _buildLabel('Last Name', isRequired: true),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _lastNameController,
          hint: 'Enter your last name',
          textCapitalization: TextCapitalization.words,
        ),
      ],
    );
  }

  Widget _buildOrganizationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Industry', isRequired: true),
        const SizedBox(height: 8),
        _buildSelectionGrid(
          items: industries,
          selectedItem: _selectedIndustry,
          onSelect: (item) => setState(() => _selectedIndustry = item),
        ),
        const SizedBox(height: 24),
        _buildLabel('Company / Organization Name', isRequired: true),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _companyNameController,
          hint: 'Enter your company name',
          textCapitalization: TextCapitalization.words,
        ),
      ],
    );
  }

  Widget _buildDepartmentStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSelectionGrid(
          items: departments,
          selectedItem: _showCustomDepartment ? 'Other' : _selectedDepartment,
          onSelect: (item) {
            setState(() {
              if (item == 'Other') {
                _showCustomDepartment = true;
                _selectedDepartment = null;
              } else {
                _showCustomDepartment = false;
                _selectedDepartment = item;
                _customDepartmentController.clear();
              }
            });
          },
        ),
        if (_showCustomDepartment) ...[
          const SizedBox(height: 20),
          _buildLabel('Your Department', isRequired: true),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _customDepartmentController,
            hint: 'Enter your department name',
            textCapitalization: TextCapitalization.words,
          ),
        ],
      ],
    );
  }

  Widget _buildDivisionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSelectionGrid(
          items: therapies,
          selectedItem: _showCustomDivision ? 'Others' : _selectedDivision,
          onSelect: (item) {
            setState(() {
              if (item == 'Others') {
                _showCustomDivision = true;
                _selectedDivision = null;
              } else {
                _showCustomDivision = false;
                _selectedDivision = item;
                _customDivisionController.clear();
              }
            });
          },
        ),
        if (_showCustomDivision) ...[
          const SizedBox(height: 20),
          _buildLabel('Your Therapy / Division', isRequired: true),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _customDivisionController,
            hint: 'Enter your therapy or division',
            textCapitalization: TextCapitalization.words,
          ),
        ],
      ],
    );
  }

  Widget _buildLabel(String text, {bool isRequired = false}) {
    return RichText(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        children: isRequired
            ? const [
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: AppColors.error),
                ),
              ]
            : null,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextField(
      controller: controller,
      textCapitalization: textCapitalization,
      style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.grey, fontSize: 14),
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildSelectionGrid({
    required List<String> items,
    required String? selectedItem,
    required ValueChanged<String> onSelect,
  }) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items.map((item) {
        final isSelected = item == selectedItem;
        return GestureDetector(
          onTap: () => onSelect(item),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.lightGrey,
                width: 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              item,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.white : AppColors.textPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNavigationButtons(bool isLoading) {
    final isLastStep = _currentStep == 3;
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).viewPadding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: CustomButton(
                text: 'Back',
                onPressed: _previousStep,
                variant: ButtonVariant.outline,
                height: 52,
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: _currentStep > 0 ? 2 : 1,
            child: CustomButton(
              text: isLastStep ? 'Complete Registration' : 'Continue',
              onPressed: _nextStep,
              isLoading: isLoading,
              variant: ButtonVariant.outline,
              height: 52,
            ),
          ),
        ],
      ),
    );
  }
}
