import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:country_picker/country_picker.dart';
import 'package:country_state_city/country_state_city.dart' as csc;
import '../../config/app_colors.dart';
import '../../services/user_service.dart';
import '../../services/file_upload_service.dart';
import '../../services/activity_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_dropdown.dart';
import '../../widgets/custom_toast.dart';
import '../../models/user_screen_model.dart';

class UserCreateScreen extends StatefulWidget {
  const UserCreateScreen({super.key});

  @override
  State<UserCreateScreen> createState() => _UserCreateScreenState();
}

class _UserCreateScreenState extends State<UserCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final UserService _userService = GetIt.I<UserService>();
  final FileUploadService _fileUploadService = GetIt.I<FileUploadService>();
  final ActivityService _activityService = GetIt.I<ActivityService>();
  final ImagePicker _imagePicker = ImagePicker();

  // Form controllers
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _employeeCodeController = TextEditingController();
  final _designationController = TextEditingController();
  final _departmentController = TextEditingController();
  final _divisionController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _noteController = TextEditingController();
  final _userSearchController = TextEditingController();

  // Dropdown values
  Country _selectedPhoneCountry = CountryParser.parseCountryCode('IN');
  String _selectedRole = 'CUSTOMER';
  String? _selectedInfluenceType;
  String? _selectedCountryValue;
  String? _selectedStateValue;
  String? _selectedCityValue;
  String? _selectedDepartment;
  String? _selectedCompany;
  List<String> _selectedUserIds = [];

  // Profile picture
  File? _profilePicture;
  String? _profilePictureId;
  bool _isUploadingImage = false;

  // Data
  List<CompanyDropdownModel> _companies = [];
  List<Map<String, dynamic>> _companyUsers = [];
  List<Map<String, dynamic>> _filteredCompanyUsers = [];

  // Country, State, City data
  List<csc.Country> _countries = [];
  List<csc.State> _states = [];
  List<csc.City> _cities = [];

  bool _isLoading = false;
  bool _isLoadingData = true;
  bool _isEdit = false;
  UserScreenModel? _editUser;

  // Hardcoded options
  final List<String> _roles = ['CUSTOMER', 'ADMIN', 'EMPLOYEE'];
  final List<String> _influenceTypes = ['Decision Maker','Influencer','User','Gatekeeper'];
  final List<String> _departments = [
    'Sales',
    'Marketing',
    'IT',
    'HR',
    'Finance',
    'Operations',
  ];

  /// Get phone number length based on country code
  int _getPhoneLength(String countryCode) {
    // Map of country codes to their phone number lengths
    const Map<String, int> phoneLengths = {
      '1': 10,    // US, Canada
      '7': 10,    // Russia, Kazakhstan
      '20': 10,   // Egypt
      '27': 9,    // South Africa
      '30': 10,   // Greece
      '31': 9,    // Netherlands
      '32': 9,    // Belgium
      '33': 9,    // France
      '34': 9,    // Spain
      '36': 9,    // Hungary
      '39': 10,   // Italy
      '40': 10,   // Romania
      '41': 9,    // Switzerland
      '43': 10,   // Austria
      '44': 10,   // UK
      '45': 8,    // Denmark
      '46': 9,    // Sweden
      '47': 8,    // Norway
      '48': 9,    // Poland
      '49': 10,   // Germany
      '51': 9,    // Peru
      '52': 10,   // Mexico
      '53': 8,    // Cuba
      '54': 10,   // Argentina
      '55': 11,   // Brazil
      '56': 9,    // Chile
      '57': 10,   // Colombia
      '58': 10,   // Venezuela
      '60': 9,    // Malaysia
      '61': 9,    // Australia
      '62': 11,   // Indonesia
      '63': 10,   // Philippines
      '64': 9,    // New Zealand
      '65': 8,    // Singapore
      '66': 9,    // Thailand
      '81': 10,   // Japan
      '82': 10,   // South Korea
      '84': 10,   // Vietnam
      '86': 11,   // China
      '90': 10,   // Turkey
      '91': 10,   // India
      '92': 10,   // Pakistan
      '93': 9,    // Afghanistan
      '94': 9,    // Sri Lanka
      '95': 9,    // Myanmar
      '98': 10,   // Iran
      '212': 9,   // Morocco
      '213': 9,   // Algeria
      '216': 8,   // Tunisia
      '218': 9,   // Libya
      '220': 7,   // Gambia
      '221': 9,   // Senegal
      '222': 8,   // Mauritania
      '223': 8,   // Mali
      '224': 9,   // Guinea
      '225': 10,  // Ivory Coast
      '226': 8,   // Burkina Faso
      '227': 8,   // Niger
      '228': 8,   // Togo
      '229': 8,   // Benin
      '230': 8,   // Mauritius
      '231': 9,   // Liberia
      '232': 8,   // Sierra Leone
      '233': 9,   // Ghana
      '234': 10,  // Nigeria
      '235': 8,   // Chad
      '236': 8,   // Central African Republic
      '237': 9,   // Cameroon
      '238': 7,   // Cape Verde
      '239': 7,   // Sao Tome and Principe
      '240': 9,   // Equatorial Guinea
      '241': 7,   // Gabon
      '242': 9,   // Republic of Congo
      '243': 9,   // DR Congo
      '244': 9,   // Angola
      '245': 7,   // Guinea-Bissau
      '246': 7,   // British Indian Ocean Territory
      '248': 7,   // Seychelles
      '249': 9,   // Sudan
      '250': 9,   // Rwanda
      '251': 9,   // Ethiopia
      '252': 8,   // Somalia
      '253': 8,   // Djibouti
      '254': 10,  // Kenya
      '255': 9,   // Tanzania
      '256': 9,   // Uganda
      '257': 8,   // Burundi
      '258': 9,   // Mozambique
      '260': 9,   // Zambia
      '261': 9,   // Madagascar
      '262': 9,   // Reunion
      '263': 9,   // Zimbabwe
      '264': 9,   // Namibia
      '265': 9,   // Malawi
      '266': 8,   // Lesotho
      '267': 8,   // Botswana
      '268': 8,   // Swaziland
      '269': 7,   // Comoros
      '297': 7,   // Aruba
      '298': 6,   // Faroe Islands
      '299': 6,   // Greenland
      '350': 8,   // Gibraltar
      '351': 9,   // Portugal
      '352': 9,   // Luxembourg
      '353': 9,   // Ireland
      '354': 7,   // Iceland
      '355': 9,   // Albania
      '356': 8,   // Malta
      '357': 8,   // Cyprus
      '358': 9,   // Finland
      '359': 9,   // Bulgaria
      '370': 8,   // Lithuania
      '371': 8,   // Latvia
      '372': 8,   // Estonia
      '373': 8,   // Moldova
      '374': 8,   // Armenia
      '375': 9,   // Belarus
      '376': 6,   // Andorra
      '377': 8,   // Monaco
      '378': 10,  // San Marino
      '380': 9,   // Ukraine
      '381': 9,   // Serbia
      '382': 8,   // Montenegro
      '383': 8,   // Kosovo
      '385': 9,   // Croatia
      '386': 8,   // Slovenia
      '387': 8,   // Bosnia and Herzegovina
      '389': 8,   // Macedonia
      '420': 9,   // Czech Republic
      '421': 9,   // Slovakia
      '423': 7,   // Liechtenstein
      '852': 8,   // Hong Kong
      '853': 8,   // Macau
      '855': 9,   // Cambodia
      '856': 9,   // Laos
      '880': 10,  // Bangladesh
      '886': 9,   // Taiwan
      '960': 7,   // Maldives
      '961': 8,   // Lebanon
      '962': 9,   // Jordan
      '963': 9,   // Syria
      '964': 10,  // Iraq
      '965': 8,   // Kuwait
      '966': 9,   // Saudi Arabia
      '967': 9,   // Yemen
      '968': 8,   // Oman
      '970': 9,   // Palestine
      '971': 9,   // UAE
      '972': 9,   // Israel
      '973': 8,   // Bahrain
      '974': 8,   // Qatar
      '975': 8,   // Bhutan
      '976': 8,   // Mongolia
      '977': 10,  // Nepal
      '992': 9,   // Tajikistan
      '993': 8,   // Turkmenistan
      '994': 9,   // Azerbaijan
      '995': 9,   // Georgia
      '996': 9,   // Kyrgyzstan
      '998': 9,   // Uzbekistan
    };
    
    return phoneLengths[countryCode] ?? 10; // Default to 10 if not found
  }

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _loadCountries();
    _userSearchController.addListener(_filterUsers);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Get user data from route arguments
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is UserScreenModel && !_isEdit) {
      _editUser = args;
      _isEdit = true;
      _loadUserDetailsAndPrefill();
    }
  }

  Future<void> _loadUserDetailsAndPrefill() async {
    if (_editUser == null) return;

    try {
      // Fetch full user details
      final userDetails = await _userService.getUserById(_editUser!.id);
      await _prefillUserData(userDetails);
    } catch (e) {
      // If fetching fails, prefill with available data from UserScreenModel
      _prefillBasicUserData();
    }
  }

  Future<void> _prefillUserData(Map<String, dynamic> userDetails) async {
    final user = _editUser!;

    // Prefill basic information
    _firstNameController.text = userDetails['firstName'] ?? user.firstName;
    _middleNameController.text = userDetails['middleName'] ?? user.middleName;
    _lastNameController.text = userDetails['lastName'] ?? user.lastName;
    _emailController.text = userDetails['email'] ?? user.email;
    _selectedRole = (userDetails['role'] ?? user.role).isNotEmpty
        ? (userDetails['role'] ?? user.role)
        : 'CUSTOMER';

    // Parse and prefill phone number
    final phoneCode = userDetails['phoneCode'] ?? '';
    final phoneNumber = userDetails['phoneNumber'] ?? '';

    if (phoneCode.isNotEmpty && phoneNumber.isNotEmpty) {
      final cleanPhoneCode = phoneCode.replaceAll('+', '');
      try {
        _selectedPhoneCountry = CountryParser.parsePhoneCode(cleanPhoneCode);
      } catch (e) {
        // If parsing fails, keep the default country
      }
      _phoneNumberController.text = phoneNumber;
    }

    // Prefill role-specific fields
    if (_selectedRole == 'CUSTOMER') {
      _designationController.text = userDetails['designation'] ?? user.designation;
      _departmentController.text = userDetails['department'] ?? user.department;
      _divisionController.text = userDetails['division'] ?? user.division;

      final influenceType = userDetails['influenceType'] ?? user.influenceType;
      if (influenceType.isNotEmpty && influenceType != '-') {
        _selectedInfluenceType = influenceType;
      }

      // Prefill address if available
      if (userDetails['address'] != null) {
        final address = userDetails['address'];
        _selectedCountryValue = address['countryIsoCode'];
        _selectedStateValue = address['stateIsoCode'];
        _selectedCityValue = address['cityName'];
        _postalCodeController.text = address['postalCode'] ?? '';
        _addressLine1Controller.text = address['addressLine1'] ?? '';
        _addressLine2Controller.text = address['addressLine2'] ?? '';

        // Load states and cities for the selected country/state
        if (_selectedCountryValue != null) {
          await _loadStates(_selectedCountryValue!);
          if (_selectedStateValue != null) {
            await _loadCities(_selectedCountryValue!, _selectedStateValue!);
          }
        }
      }

      _noteController.text = userDetails['note'] ?? '';
    } else {
      // ADMIN or EMPLOYEE role
      _employeeCodeController.text = userDetails['employeeCode'] ?? user.employeeCode;

      final department = userDetails['department'] ?? user.department;
      if (department.isNotEmpty && department != '-') {
        _selectedDepartment = department;
      }

      // Prefill company and selected users
      final companyIds = userDetails['companyIds'] as List<dynamic>?;
      if (companyIds != null && companyIds.isNotEmpty) {
        _selectedCompany = companyIds[0] as String;

        // Load users for the selected company
        await _loadUsersByCompany();

        // Prefill selected user IDs
        final companyUserIds = userDetails['companyUserIds'] as List<dynamic>?;
        if (companyUserIds != null && companyUserIds.isNotEmpty) {
          _selectedUserIds = companyUserIds.map((id) => id as String).toList();
        }
      }
    }

    // Trigger a rebuild to show the prefilled data
    if (mounted) {
      setState(() {});
    }
  }

  void _prefillBasicUserData() {
    if (_editUser == null) return;

    final user = _editUser!;

    // Prefill basic information
    _firstNameController.text = user.firstName;
    _middleNameController.text = user.middleName;
    _lastNameController.text = user.lastName;
    _emailController.text = user.email;
    _selectedRole = user.role.isNotEmpty ? user.role : 'CUSTOMER';

    // Parse and prefill phone number
    if (user.phone.isNotEmpty) {
      final phoneParts = user.phone.split(' ');
      if (phoneParts.length >= 2) {
        final phoneCode = phoneParts[0].replaceAll('+', '');
        final phoneNumber = phoneParts.sublist(1).join('');

        // Try to find the country by phone code
        try {
          _selectedPhoneCountry = CountryParser.parsePhoneCode(phoneCode);
        } catch (e) {
          // If parsing fails, keep the default country
        }

        _phoneNumberController.text = phoneNumber;
      }
    }

    // Prefill role-specific fields
    setState(() {
      if (_selectedRole == 'CUSTOMER') {
        _designationController.text = user.designation;
        _departmentController.text = user.department;
        _divisionController.text = user.division;
        if (user.influenceType.isNotEmpty && user.influenceType != '-') {
          _selectedInfluenceType = user.influenceType;
        }
      } else {
        _employeeCodeController.text = user.employeeCode;
        if (user.department.isNotEmpty && user.department != '-') {
          _selectedDepartment = user.department;
        }
      }
    });
  }

  Future<void> _loadCountries() async {
    final countries = await csc.getAllCountries();
    setState(() {
      _countries = countries;
    });
  }

  Future<void> _loadStates(String countryId) async {
    final states = await csc.getStatesOfCountry(countryId);
    setState(() {
      _states = states;
      _selectedStateValue = null;
      _cities = [];
      _selectedCityValue = null;
    });
  }

  Future<void> _loadCities(String countryCode, String stateCode) async {
    final stateCities = await csc.getStateCities(countryCode, stateCode);
    setState(() {
      _cities = stateCities;
      _selectedCityValue = null;
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _employeeCodeController.dispose();
    _designationController.dispose();
    _departmentController.dispose();
    _divisionController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _noteController.dispose();
    _userSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoadingData = true);

    try {
      final companies = await _activityService.getActiveCompanies();
      setState(() {
        _companies = companies;
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() => _isLoadingData = false);
      if (mounted) {
        CustomToast.show(
          context,
          e.toString().replaceAll('Exception: ', ''),
          type: ToastType.error,
        );
      }
    }
  }

  Future<void> _loadCompaniesWithUsers() async {
    try {
      // First API call: Get companies with users
      final companiesWithUsers = await _activityService.getActiveCompaniesWithUsers();

      setState(() {
        _companies = companiesWithUsers;
      });
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          'Failed to load companies: ${e.toString().replaceAll('Exception: ', '')}',
          type: ToastType.error,
        );
      }
    }
  }

  Future<void> _loadUsersByCompany() async {
    if (_selectedCompany == null) {
      setState(() {
        _companyUsers = [];
        _filteredCompanyUsers = [];
      });
      return;
    }

    try {
      final users = await _userService.getUsersByCompanies([_selectedCompany!]);
      setState(() {
        _companyUsers = users;
        _filteredCompanyUsers = users;
      });
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          'Failed to load users: ${e.toString()}',
          type: ToastType.error,
        );
      }
    }
  }

  void _filterUsers() {
    final query = _userSearchController.text.toLowerCase();
    setState(() {
      _filteredCompanyUsers = _companyUsers.where((user) {
        final firstName = (user['firstName'] ?? '').toString().toLowerCase();
        final lastName = (user['lastName'] ?? '').toString().toLowerCase();
        final email = (user['email'] ?? '').toString().toLowerCase();
        final phone = (user['phone'] ?? '').toString().toLowerCase();
        return firstName.contains(query) ||
            lastName.contains(query) ||
            email.contains(query) ||
            phone.contains(query);
      }).toList();
    });
  }

  Future<void> _pickProfilePicture() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        final file = File(image.path);
        final fileSize = await file.length();

        if (fileSize > 5 * 1024 * 1024) {
          if (mounted) {
            CustomToast.show(
              context,
              'Image size must be less than 5MB',
              type: ToastType.error,
            );
          }
          return;
        }

        setState(() => _profilePicture = file);
        await _uploadProfilePicture();
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          'Failed to pick image: ${e.toString()}',
          type: ToastType.error,
        );
      }
    }
  }

  Future<void> _uploadProfilePicture() async {
    if (_profilePicture == null) return;

    setState(() => _isUploadingImage = true);

    try {
      final fileId = await _fileUploadService.uploadFile(
        _profilePicture!,
        isPublic: false,
      );
      setState(() {
        _profilePictureId = fileId;
        _isUploadingImage = false;
      });
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
        _profilePicture = null;
      });
      if (mounted) {
        CustomToast.show(
          context,
          'Failed to upload image: ${e.toString()}',
          type: ToastType.error,
        );
      }
    }
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final Map<String, dynamic> data = {
        'firstName': _firstNameController.text.trim(),
        'middleName': _middleNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phoneCode': '+${_selectedPhoneCountry.phoneCode}',
        'phoneNumber': _phoneNumberController.text.trim(),
        'role': _selectedRole,
      };

      if (_profilePictureId != null) {
        data['profilePictureId'] = _profilePictureId;
      }

      if (_selectedRole == 'CUSTOMER') {
        data['designation'] = _designationController.text.trim();
        data['department'] = _departmentController.text.trim();
        data['division'] = _divisionController.text.trim();
        data['influenceType'] = _selectedInfluenceType;
        String? cityName;
        if (_selectedCityValue != null && _cities.isNotEmpty) {
          final selectedCity = _cities.firstWhere(
            (city) => city.name == _selectedCityValue,
            orElse: () => _cities.first,
          );
          cityName = selectedCity.name;
        }

        data['address'] = {
          'countryIsoCode': _selectedCountryValue,
          'stateIsoCode': _selectedStateValue,
          'cityName': cityName ?? _cityController.text.trim(),
          'addressLine1': _addressLine1Controller.text.trim(),
          'addressLine2': _addressLine2Controller.text.trim(),
          'postalCode': _postalCodeController.text.trim(),
        };
        data['note'] = _noteController.text.trim();
      } else {
        data['employeeCode'] = _employeeCodeController.text.trim();
        data['department'] = _selectedDepartment;
        if (_selectedCompany != null) {
          data['companyIds'] = [_selectedCompany];
        }
        data['companyUserIds'] = _selectedUserIds;
      }

      if (_isEdit && _editUser != null) {
        await _userService.updateUser(_editUser!.id, data);
      } else {
        await _userService.createUser(data);
      }

      if (mounted) {
        CustomToast.show(
          context,
          _isEdit ? 'User updated successfully' : 'User created successfully',
          type: ToastType.success,
        );
        Navigator.pop(context, true);
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
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEdit ? 'Edit User' : 'Create User',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoadingData
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          : GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SafeArea(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Personal Information Section
                        _buildSection(
                          title: 'Personal Information',
                          subtitle: 'Basic profile details',
                          child: Column(
                            children: [
                              _buildProfilePictureUpload(),
                              const SizedBox(height: 24),
                              _buildFieldRow([
                                _buildTextField(
                                  label: 'First Name',
                                  hint: 'Olivia',
                                  controller: _firstNameController,
                                  isRequired: true,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Required';
                                    }
                                    return null;
                                  },
                                ),
                                _buildTextField(
                                  label: 'Middle Name',
                                  hint: 'Joel',
                                  controller: _middleNameController,
                                ),
                              ]),
                              const SizedBox(height: 16),
                              _buildFieldRow([
                                _buildTextField(
                                  label: 'Last Name',
                                  hint: 'Rhye',
                                  controller: _lastNameController,
                                  isRequired: true,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Required';
                                    }
                                    return null;
                                  },
                                ),
                                CustomDropdown<String>(
                                  label: 'Role',
                                  hint: 'Select role',
                                  value: _selectedRole,
                                  items: _roles.map((role) {
                                    return DropdownItem(
                                      value: role,
                                      label: role,
                                    );
                                  }).toList(),
                                  onChanged: (value) async {
                                    setState(() {
                                      _selectedRole = value ?? 'CUSTOMER';
                                      _selectedCompany = null;
                                      _selectedUserIds = [];
                                      _companyUsers = [];
                                      _filteredCompanyUsers = [];
                                    });

                                    // Call API when role is EMPLOYEE or ADMIN
                                    if (_selectedRole == 'EMPLOYEE' || _selectedRole == 'ADMIN') {
                                      await _loadCompaniesWithUsers();
                                    }
                                  },
                                  isRequired: true,
                                ),
                              ]),
                            ],
                          ),
                        ),

                        // Contact Information Section
                        _buildSection(
                          title: 'Contact Information',
                          subtitle: 'Email and phone details',
                          child: Column(
                            children: [
                              _buildFieldRow([
                                _buildTextField(
                                  label: 'Email',
                                  hint: 'olivia.rhye@business.com',
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value != null &&
                                        value.trim().isNotEmpty &&
                                        !RegExp(
                                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                        ).hasMatch(value)) {
                                      return 'Invalid email';
                                    }
                                    return null;
                                  },
                                ),
                                _buildPhoneCodePicker(),
                              ]),
                              const SizedBox(height: 16),
                              _buildFieldRow([
                                _buildTextField(
                                  maxLines: 1,
                                  maxLength: _getPhoneLength(_selectedPhoneCountry.phoneCode),
                                  label: 'Phone Number',
                                  hint: '1234567890',
                                  controller: _phoneNumberController,
                                  keyboardType: TextInputType.phone,
                                  isRequired: true,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  validator: (value) {
                                    final expectedLength = _getPhoneLength(_selectedPhoneCountry.phoneCode);
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Required';
                                    }
                                    if (value.trim().length != expectedLength) {
                                      return 'Must be $expectedLength digits';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox.shrink(),
                              ]),
                            ],
                          ),
                        ),

                        // Role-specific sections
                        if (_selectedRole == 'CUSTOMER') ...[
                          _buildCustomerSection(),
                        ] else ...[
                          _buildEmployeeSection(),
                        ],

                        // Action Buttons
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              CustomButton(
                                text: _isEdit ? 'Update User' : 'Create User',
                                onPressed: _createUser,
                                isLoading: _isLoading,
                                icon: Icons.check,
                              ),
                              const SizedBox(height: 12),
                              CustomButton(
                                text: 'Cancel',
                                onPressed: () => Navigator.pop(context),
                                variant: ButtonVariant.outline,
                                icon: Icons.close,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePictureUpload() {
    return Center(
      child: Stack(
        children: [
          GestureDetector(
            onTap: _pickProfilePicture,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.background,
                border: Border.all(color: AppColors.lightGrey, width: 2),
              ),
              child: _isUploadingImage
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    )
                  : _profilePicture != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: Image.file(_profilePicture!, fit: BoxFit.cover),
                    )
                  : const Icon(
                      Icons.person_outline,
                      size: 48,
                      color: AppColors.grey,
                    ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickProfilePicture,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.lightGrey, width: 2),
                ),
                child: const Icon(
                  Icons.edit,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldRow(List<Widget> children) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < children.length; i++) ...[
          Expanded(child: children[i]),
          if (i < children.length - 1) const SizedBox(width: 16),
        ],
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool isRequired = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            children: [
              if (isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: AppColors.error, fontSize: 14),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          buildCounter:
              (
                context, {
                required currentLength,
                required isFocused,
                required maxLength,
              }) {
                return Offstage();
              },
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          maxLength: maxLength,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: AppColors.textLight,
              fontSize: 14,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildCustomerSection() {
    return Column(
      children: [
        _buildSection(
          title: 'Professional Details',
          subtitle: 'Work-related information',
          child: Column(
            children: [
              _buildFieldRow([
                _buildTextField(
                  label: 'Designation',
                  hint: 'Sr. Mobile App Developer',
                  controller: _designationController,
                ),
                _buildTextField(
                  label: 'Department',
                  hint: 'Mobile Team',
                  controller: _departmentController,
                ),
              ]),
              const SizedBox(height: 16),
              _buildFieldRow([
                _buildTextField(
                  label: 'Division',
                  hint: 'Engineering',
                  controller: _divisionController,
                ),
                CustomDropdown<String>(
                  label: 'Influence Type',
                  hint: 'Select type',
                  value: _selectedInfluenceType,
                  items: _influenceTypes.map((type) {
                    return DropdownItem(value: type, label: type);
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedInfluenceType = value);
                  },
                  onClear: () {
                    setState(() => _selectedInfluenceType = null);
                  },
                ),
              ]),
            ],
          ),
        ),
        _buildSection(
          title: 'Address Information',
          subtitle: 'Location details',
          child: Column(
            children: [
              _buildFieldRow([
                CustomDropdown<String>(
                  label: 'Country',
                  hint: 'Select country',
                  value: _selectedCountryValue,
                  items: _countries.map((country) {
                    return DropdownItem(
                      value: country.isoCode,
                      label: country.name,
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCountryValue = value;
                    });
                    if (value != null) {
                      _loadStates(value);
                    }
                  },
                  onClear: () {
                    setState(() {
                      _selectedCountryValue = null;
                      _selectedStateValue = null;
                      _selectedCityValue = null;
                      _states = [];
                      _cities = [];
                    });
                  },
                ),
                CustomDropdown<String>(
                  label: 'State',
                  hint: 'Select state',
                  value: _selectedStateValue,
                  items: _states.map((state) {
                    return DropdownItem(
                      value: state.isoCode,
                      label: state.name,
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedStateValue = value;
                    });
                    if (value != null && _selectedCountryValue != null) {
                      _loadCities(_selectedCountryValue!, value);
                    }
                  },
                  isEnabled: _selectedCountryValue != null,
                  onClear: () {
                    setState(() {
                      _selectedStateValue = null;
                      _selectedCityValue = null;
                      _cities = [];
                    });
                  },
                ),
              ]),
              const SizedBox(height: 16),
              _buildFieldRow([
                CustomDropdown<String>(
                  label: 'City',
                  hint: 'Select city',
                  value: _selectedCityValue,
                  items: _cities.map((city) {
                    return DropdownItem(value: city.name, label: city.name);
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCityValue = value;
                    });
                  },
                  isEnabled: _selectedStateValue != null,
                  onClear: () {
                    setState(() {
                      _selectedCityValue = null;
                    });
                  },
                ),
                const SizedBox.shrink(),
              ]),
              const SizedBox(height: 16),
              _buildFieldRow([
                _buildTextField(
                  label: 'Postal Code',
                  hint: '123456',
                  controller: _postalCodeController,
                  keyboardType: TextInputType.number,
                ),
              ]),
              const SizedBox(height: 16),
              _buildFieldRow([
                _buildTextField(
                  label: 'Address Line 1',
                  hint: 'Enter address',
                  controller: _addressLine1Controller,
                ),
                _buildTextField(
                  label: 'Address Line 2',
                  hint: 'Enter address',
                  controller: _addressLine2Controller,
                ),
              ]),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Note',
                hint: 'Add any additional notes...',
                controller: _noteController,
                maxLines: 4,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmployeeSection() {
    return Column(
      children: [
        _buildSection(
          title: 'Employee Information',
          subtitle: 'Employment details',
          child: Column(
            children: [
              _buildFieldRow([
                _buildTextField(
                  label: 'Employee Code',
                  hint: 'MI-257',
                  controller: _employeeCodeController,
                ),
                CustomDropdown<String>(
                  label: 'Department',
                  hint: 'Select department',
                  value: _selectedDepartment,
                  items: _departments.map((dept) {
                    return DropdownItem(value: dept, label: dept);
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedDepartment = value);
                  },
                  onClear: () {
                    setState(() => _selectedDepartment = null);
                  },
                ),
              ]),
              const SizedBox(height: 20),
              CustomDropdown<String>(
                label: 'Select Company',
                hint: 'Select company',
                value: _selectedCompany,
                items: _companies.map((company) {
                  return DropdownItem(value: company.id, label: company.name);
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCompany = value;
                    _selectedUserIds = [];
                  });
                  _loadUsersByCompany();
                },
                onClear: () {
                  setState(() {
                    _selectedCompany = null;
                    _companyUsers = [];
                    _filteredCompanyUsers = [];
                    _selectedUserIds = [];
                  });
                },
              ),
            ],
          ),
        ),
        if (_selectedCompany != null) ...[
          _buildSection(
            title: 'Select Users',
            subtitle: 'Choose users from selected company',
            child: Column(
              children: [
                TextField(
                  controller: _userSearchController,
                  decoration: InputDecoration(
                    hintText: 'Search users...',
                    hintStyle: const TextStyle(
                      color: AppColors.grey,
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildUsersTable(),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildUsersTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.lightGrey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: const [
                SizedBox(
                  width: 40,
                  child: Text(
                    '',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'NAME',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'EMAIL',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'PHONE',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'ROLE',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          if (_filteredCompanyUsers.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'No users found',
                style: TextStyle(color: AppColors.grey),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredCompanyUsers.length,
              itemBuilder: (context, index) {
                final user = _filteredCompanyUsers[index];
                final userId = user['id'] as String;
                final isSelected = _selectedUserIds.contains(userId);

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: index == _filteredCompanyUsers.length - 1
                            ? Colors.transparent
                            : AppColors.lightGrey,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 40,
                        child: Checkbox(
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedUserIds.add(userId);
                              } else {
                                _selectedUserIds.remove(userId);
                              }
                            });
                          },
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'
                              .trim(),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          (user['email'] ?? '-').toString(),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          (user['phone'] ?? '-').toString(),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          (user['role'] ?? '-').toString(),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPhoneCodePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            text: 'Phone Code',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            children: [
              TextSpan(
                text: ' *',
                style: TextStyle(color: AppColors.error, fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () {
            showCountryPicker(
              context: context,
              showPhoneCode: true,
              onSelect: (Country country) {
                setState(() {
                  _selectedPhoneCountry = country;
                });
              },
              countryListTheme: CountryListThemeData(
                padding: EdgeInsets.zero,
                borderRadius: BorderRadius.circular(12),
                inputDecoration: InputDecoration(
                  labelText: 'Search',
                  hintText: 'Start typing to search',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.lightGrey),
                  ),
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.lightGrey),
            ),
            child: Row(
              children: [
                Text(
                  _selectedPhoneCountry.flagEmoji,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 8),
                Text(
                  '+${_selectedPhoneCountry.phoneCode}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.arrow_drop_down, color: AppColors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
