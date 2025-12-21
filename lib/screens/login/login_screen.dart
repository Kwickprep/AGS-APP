import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../config/app_colors.dart';
import '../../config/routes.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_toast.dart';
import 'login_bloc.dart';
import 'dart:async';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LoginBloc(),
      child: const LoginView(),
    );
  }
}

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView>
    with AutomaticKeepAliveClientMixin {
  final _phoneController = TextEditingController();
  String _selectedCountryCode = '+91';
  String _selectedCountryFlag = 'IN';
  bool _showOtpScreen = false;

  // OTP related
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );
  Timer? _timer;
  int _remainingSeconds = 300; // 5 minutes

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _phoneController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _remainingSeconds = 300;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  void _onSendOtp() {
    if (_phoneController.text.isEmpty || _phoneController.text.length < 10) {
      CustomToast.show(
        context,
        'Please enter a valid WhatsApp number',
        type: ToastType.error,
      );
      return;
    }

    // Send OTP request with separate country code and phone number
    context.read<LoginBloc>().add(
      SendOtpRequested(
        phoneCode: _selectedCountryCode,
        phoneNumber: _phoneController.text,
      ),
    );
  }

  void _onVerifyOtp() {
    String otp = _otpControllers.map((c) => c.text).join();
    if (otp.length != 6) {
      CustomToast.show(
        context,
        'Please enter complete OTP',
        type: ToastType.error,
      );
      return;
    }

    // Verify OTP with separate country code and phone number
    context.read<LoginBloc>().add(
      VerifyOtpSubmitted(
        phoneCode: _selectedCountryCode,
        phoneNumber: _phoneController.text,
        otp: otp,
      ),
    );
  }

  void _onResendOtp() {
    // Clear OTP fields
    for (var controller in _otpControllers) {
      controller.clear();
    }
    _otpFocusNodes[0].requestFocus();

    // Reset and restart timer immediately
    setState(() {
      _remainingSeconds = 300;
    });
    _startTimer();

    // Resend OTP request with separate country code and phone number
    context.read<LoginBloc>().add(
      SendOtpRequested(
        phoneCode: _selectedCountryCode,
        phoneNumber: _phoneController.text,
      ),
    );

    // Show toast
    CustomToast.show(
      context,
      'OTP resent successfully',
      type: ToastType.success,
    );
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => CountryPickerSheet(
        selectedCountryCode: _selectedCountryCode,
        onCountrySelected: (countryCode, countryFlag) {
          setState(() {
            _selectedCountryCode = countryCode;
            _selectedCountryFlag = countryFlag;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        body: BlocConsumer<LoginBloc, LoginState>(
          listener: (context, state) {
            if (state is LoginSuccess) {
              CustomToast.show(
                context,
                'Login successful! Welcome back.',
                type: ToastType.success,
              );
              Future.delayed(const Duration(milliseconds: 500), () {
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, AppRoutes.home);
                }
              });
            } else if (state is LoginError) {
              CustomToast.show(context, state.message, type: ToastType.error);
            } else if (state is OtpSent) {
              if (!_showOtpScreen) {
                setState(() {
                  _showOtpScreen = true;
                });
                _startTimer();
                CustomToast.show(
                  context,
                  'OTP sent successfully to your WhatsApp',
                  type: ToastType.success,
                );
              }
            }
          },
          builder: (context, state) {
            return SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: _showOtpScreen
                      ? _buildOtpScreen(state)
                      : _buildPhoneScreen(state),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPhoneScreen(LoginState state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Logo
        Image.asset('assets/images/ags_full_logo.png', width: 100, height: 100),
        const SizedBox(height: 60),

        // Login Card
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              (kDebugMode)
                  ? GestureDetector(
                      onDoubleTap: () {
                        setState(() {
                          _phoneController.text = '9586829533';
                        });
                      },
                      child: const Text(
                        'Welcome Back',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : const Text(
                      'Welcome Back',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
              const SizedBox(height: 12),
              const Text(
                'Sign in with your WhatsApp number',
                style: TextStyle(fontSize: 14, color: AppColors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Country Code
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: const TextSpan(
                      text: 'Country Code ',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                      children: [
                        TextSpan(
                          text: '*',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _showCountryPicker,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.lightGrey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$_selectedCountryFlag $_selectedCountryCode',
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.black,
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down,
                            color: AppColors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // WhatsApp Number
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: const TextSpan(
                      text: 'WhatsApp Number ',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                      children: [
                        TextSpan(
                          text: '*',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.number,
                    maxLength: 10,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    decoration: InputDecoration(
                      hintText: 'Enter your WhatsApp number',
                      hintStyle: const TextStyle(
                        color: AppColors.grey,
                        fontSize: 14,
                      ),
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppColors.lightGrey,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppColors.lightGrey,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Send OTP Button
              CustomButton(
                text: 'Send OTP',
                onPressed: _onSendOtp,
                isLoading: state is LoginLoading,
                variant: ButtonVariant.outline,
                height: 50,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOtpScreen(LoginState state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Logo
        Image.asset('assets/images/ags_icon.png', width: 100, height: 100),
        const SizedBox(height: 60),

        // OTP Card
        Container(
          constraints: const BoxConstraints(maxWidth: 450),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Enter the OTP sent to your WhatsApp',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.grey,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Phone Number Display
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: const TextSpan(
                      text: 'WhatsApp Number ',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.grey,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                      children: [
                        TextSpan(
                          text: '*',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.lightGrey.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _selectedCountryFlag,
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _selectedCountryCode,
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _phoneController.text,
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // OTP Input
              LayoutBuilder(
                builder: (context, constraints) {
                  final boxWidth =
                      (constraints.maxWidth - 60) /
                      6; // 60 for spacing (5 gaps * 12)
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (index) {
                      return Container(
                        width: boxWidth.clamp(40.0, 55.0),
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _otpControllers[index],
                          focusNode: _otpFocusNodes[index],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.black,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            filled: true,
                            fillColor: AppColors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: AppColors.lightGrey,
                                width: 1.5,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: AppColors.lightGrey,
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16,
                            ),
                          ),
                          onChanged: (value) {
                            if (value.isNotEmpty && index < 5) {
                              _otpFocusNodes[index + 1].requestFocus();
                            } else if (value.isEmpty && index > 0) {
                              _otpFocusNodes[index - 1].requestFocus();
                            }
                          },
                        ),
                      );
                    }),
                  );
                },
              ),
              const SizedBox(height: 28),

              // Timer
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 18,
                      color: Color(0xFF2E7D32),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'OTP expires in: ${_formatTime(_remainingSeconds)}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Verify OTP Button
              CustomButton(
                text: 'Verify OTP',
                onPressed: _onVerifyOtp,
                isLoading: state is LoginLoading,
                variant: ButtonVariant.outline,
                height: 52,
              ),
              const SizedBox(height: 8),

              // Resend OTP
              TextButton(
                onPressed: _onResendOtp,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Resend OTP',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Country Picker Bottom Sheet
class CountryPickerSheet extends StatefulWidget {
  final String selectedCountryCode;
  final Function(String, String) onCountrySelected;

  const CountryPickerSheet({
    super.key,
    required this.selectedCountryCode,
    required this.onCountrySelected,
  });

  @override
  State<CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<CountryPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, String>> _filteredCountries = [];

  final List<Map<String, String>> _countries = [
    {'code': '+93', 'flag': 'AF', 'name': 'Afghanistan'},
    {'code': '+355', 'flag': 'AL', 'name': 'Albania'},
    {'code': '+213', 'flag': 'DZ', 'name': 'Algeria'},
    {'code': '+376', 'flag': 'AD', 'name': 'Andorra'},
    {'code': '+244', 'flag': 'AO', 'name': 'Angola'},
    {'code': '+54', 'flag': 'AR', 'name': 'Argentina'},
    {'code': '+61', 'flag': 'AU', 'name': 'Australia'},
    {'code': '+43', 'flag': 'AT', 'name': 'Austria'},
    {'code': '+880', 'flag': 'BD', 'name': 'Bangladesh'},
    {'code': '+32', 'flag': 'BE', 'name': 'Belgium'},
    {'code': '+55', 'flag': 'BR', 'name': 'Brazil'},
    {'code': '+1', 'flag': 'CA', 'name': 'Canada'},
    {'code': '+86', 'flag': 'CN', 'name': 'China'},
    {'code': '+45', 'flag': 'DK', 'name': 'Denmark'},
    {'code': '+20', 'flag': 'EG', 'name': 'Egypt'},
    {'code': '+358', 'flag': 'FI', 'name': 'Finland'},
    {'code': '+33', 'flag': 'FR', 'name': 'France'},
    {'code': '+49', 'flag': 'DE', 'name': 'Germany'},
    {'code': '+30', 'flag': 'GR', 'name': 'Greece'},
    {'code': '+852', 'flag': 'HK', 'name': 'Hong Kong'},
    {'code': '+504', 'flag': 'HN', 'name': 'Honduras'},
    {'code': '+36', 'flag': 'HU', 'name': 'Hungary'},
    {'code': '+354', 'flag': 'IS', 'name': 'Iceland'},
    {'code': '+91', 'flag': 'IN', 'name': 'India'},
    {'code': '+62', 'flag': 'ID', 'name': 'Indonesia'},
    {'code': '+98', 'flag': 'IR', 'name': 'Iran'},
    {'code': '+964', 'flag': 'IQ', 'name': 'Iraq'},
    {'code': '+353', 'flag': 'IE', 'name': 'Ireland'},
    {'code': '+972', 'flag': 'IL', 'name': 'Israel'},
    {'code': '+39', 'flag': 'IT', 'name': 'Italy'},
    {'code': '+81', 'flag': 'JP', 'name': 'Japan'},
    {'code': '+82', 'flag': 'KR', 'name': 'South Korea'},
    {'code': '+60', 'flag': 'MY', 'name': 'Malaysia'},
    {'code': '+52', 'flag': 'MX', 'name': 'Mexico'},
    {'code': '+31', 'flag': 'NL', 'name': 'Netherlands'},
    {'code': '+64', 'flag': 'NZ', 'name': 'New Zealand'},
    {'code': '+47', 'flag': 'NO', 'name': 'Norway'},
    {'code': '+92', 'flag': 'PK', 'name': 'Pakistan'},
    {'code': '+51', 'flag': 'PE', 'name': 'Peru'},
    {'code': '+63', 'flag': 'PH', 'name': 'Philippines'},
    {'code': '+48', 'flag': 'PL', 'name': 'Poland'},
    {'code': '+351', 'flag': 'PT', 'name': 'Portugal'},
    {'code': '+7', 'flag': 'RU', 'name': 'Russia'},
    {'code': '+966', 'flag': 'SA', 'name': 'Saudi Arabia'},
    {'code': '+65', 'flag': 'SG', 'name': 'Singapore'},
    {'code': '+27', 'flag': 'ZA', 'name': 'South Africa'},
    {'code': '+34', 'flag': 'ES', 'name': 'Spain'},
    {'code': '+94', 'flag': 'LK', 'name': 'Sri Lanka'},
    {'code': '+46', 'flag': 'SE', 'name': 'Sweden'},
    {'code': '+41', 'flag': 'CH', 'name': 'Switzerland'},
    {'code': '+66', 'flag': 'TH', 'name': 'Thailand'},
    {'code': '+90', 'flag': 'TR', 'name': 'Turkey'},
    {'code': '+971', 'flag': 'AE', 'name': 'UAE'},
    {'code': '+44', 'flag': 'GB', 'name': 'United Kingdom'},
    {'code': '+1', 'flag': 'US', 'name': 'United States'},
    {'code': '+84', 'flag': 'VN', 'name': 'Vietnam'},
  ];

  @override
  void initState() {
    super.initState();
    _filteredCountries = _countries;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCountries(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCountries = _countries;
      } else {
        _filteredCountries = _countries.where((country) {
          return country['name']!.toLowerCase().contains(query.toLowerCase()) ||
              country['code']!.contains(query) ||
              country['flag']!.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search Field
          TextField(
            controller: _searchController,
            onChanged: _filterCountries,
            decoration: InputDecoration(
              hintText: 'Search',
              hintStyle: const TextStyle(color: AppColors.grey),
              prefixIcon: const Icon(Icons.search, color: AppColors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.lightGrey),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.lightGrey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
          const SizedBox(height: 16),

          // Country List
          Expanded(
            child: ListView.builder(
              itemCount: _filteredCountries.length,
              itemBuilder: (context, index) {
                final country = _filteredCountries[index];
                final isSelected =
                    country['code'] == widget.selectedCountryCode;

                return InkWell(
                  onTap: () {
                    widget.onCountrySelected(
                      country['code']!,
                      country['flag']!,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Text(
                          country['flag']!,
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          country['code']!,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? AppColors.white
                                : AppColors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
