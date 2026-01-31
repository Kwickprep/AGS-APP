class UserModel {
  final String id;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String email;
  final String role;
  final String? phoneCode;
  final String? phoneNumber;
  final List<String>? permissions;
  final bool? isActive;
  final bool? isRegistered;
  final String? registrationStage;
  final String? userProvidedIndustry;
  final String? userProvidedCompany;
  final String? division;
  final String? designation;
  final String? employeeCode;
  final String? bloodGroup;
  final String? gender;
  final String? dateOfBirth;
  final String? aboutMe;
  final String? businessUnit;
  final String? status;
  final String? reportingTo;
  final String? department;
  final String? employeeType;
  final String? companyEmail;
  final String? companyMobileNumber;
  final String? seatingLocation;
  final String? extensionNumber;
  final String? profilePictureUrl;

  UserModel({
    required this.id,
    this.firstName = '',
    this.middleName,
    this.lastName = '',
    this.email = '',
    this.role = '',
    this.phoneCode,
    this.phoneNumber,
    this.permissions,
    this.isActive,
    this.isRegistered,
    this.registrationStage,
    this.userProvidedIndustry,
    this.userProvidedCompany,
    this.division,
    this.designation,
    this.employeeCode,
    this.bloodGroup,
    this.gender,
    this.dateOfBirth,
    this.aboutMe,
    this.businessUnit,
    this.status,
    this.reportingTo,
    this.department,
    this.employeeType,
    this.companyEmail,
    this.companyMobileNumber,
    this.seatingLocation,
    this.extensionNumber,
    this.profilePictureUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      middleName: json['middleName'],
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      phoneCode: json['phoneCode'],
      phoneNumber: json['phoneNumber'],
      permissions: json['permissions'] != null
          ? List<String>.from(json['permissions'])
          : null,
      isActive: json['isActive'],
      isRegistered: json['isRegistered'],
      registrationStage: json['registrationStage'],
      userProvidedIndustry: json['userProvidedIndustry'],
      userProvidedCompany: json['userProvidedCompany'],
      division: json['division'],
      designation: json['designation'],
      employeeCode: json['employeeCode'],
      bloodGroup: json['bloodGroup'],
      gender: json['gender'],
      dateOfBirth: json['dateOfBirth'],
      aboutMe: json['aboutMe'],
      businessUnit: json['businessUnit'],
      status: json['status'],
      reportingTo: json['reportingTo'],
      department: json['department'],
      employeeType: json['employeeType'],
      companyEmail: json['companyEmail'],
      companyMobileNumber: json['companyMobileNumber'],
      seatingLocation: json['seatingLocation'],
      extensionNumber: json['extensionNumber'],
      profilePictureUrl: json['profilePictureUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      if (middleName != null) 'middleName': middleName,
      'lastName': lastName,
      'email': email,
      'role': role,
      if (phoneCode != null) 'phoneCode': phoneCode,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (permissions != null) 'permissions': permissions,
      if (isActive != null) 'isActive': isActive,
      if (isRegistered != null) 'isRegistered': isRegistered,
      if (registrationStage != null) 'registrationStage': registrationStage,
      if (userProvidedIndustry != null) 'userProvidedIndustry': userProvidedIndustry,
      if (userProvidedCompany != null) 'userProvidedCompany': userProvidedCompany,
      if (division != null) 'division': division,
      if (designation != null) 'designation': designation,
      if (employeeCode != null) 'employeeCode': employeeCode,
      if (bloodGroup != null) 'bloodGroup': bloodGroup,
      if (gender != null) 'gender': gender,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
      if (aboutMe != null) 'aboutMe': aboutMe,
      if (businessUnit != null) 'businessUnit': businessUnit,
      if (status != null) 'status': status,
      if (reportingTo != null) 'reportingTo': reportingTo,
      if (department != null) 'department': department,
      if (employeeType != null) 'employeeType': employeeType,
      if (companyEmail != null) 'companyEmail': companyEmail,
      if (companyMobileNumber != null) 'companyMobileNumber': companyMobileNumber,
      if (seatingLocation != null) 'seatingLocation': seatingLocation,
      if (extensionNumber != null) 'extensionNumber': extensionNumber,
      if (profilePictureUrl != null) 'profilePictureUrl': profilePictureUrl,
    };
  }

  /// Whether this user needs to complete registration
  bool get needsRegistration => isRegistered != true && role == 'CUSTOMER';

  String get fullName {
    final parts = [firstName, if (middleName != null) middleName, lastName];
    return parts.where((p) => p != null && p.isNotEmpty).join(' ');
  }

  String get phone => phoneCode != null && phoneNumber != null
      ? '$phoneCode $phoneNumber'
      : '';
}
