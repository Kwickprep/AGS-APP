class ContactModel {
  final String id;
  final String firstName;
  final String? middleName;
  final String? lastName;
  final String? email;
  final String phoneCode;
  final String phoneNumber;
  final String phone; // Formatted phone with code
  final String role;
  final String? company;
  final String? department;
  final String? designation;
  final String? division;
  final String? influenceType;
  final String? employeeCode;
  final String? groups;
  final String isActive; // Can be "Active" or "Inactive" from API
  final String? createdBy;
  final String? createdAt;
  final String? displayValue;
  final String? searchValue;
  final bool? isWhatsapp;
  final String? isAcknowledged;

  ContactModel({
    required this.id,
    required this.firstName,
    this.middleName,
    this.lastName,
    this.email,
    required this.phoneCode,
    required this.phoneNumber,
    required this.phone,
    required this.role,
    this.company,
    this.department,
    this.designation,
    this.division,
    this.influenceType,
    this.employeeCode,
    this.groups,
    required this.isActive,
    this.createdBy,
    this.createdAt,
    this.displayValue,
    this.searchValue,
    this.isWhatsapp,
    this.isAcknowledged,
  });

  String get fullName {
    final parts = [
      firstName,
      if (middleName != null && middleName!.isNotEmpty && middleName != '-') middleName,
      if (lastName != null && lastName!.isNotEmpty && lastName != '-') lastName,
    ];
    return parts.join(' ');
  }

  String get displayPhone => phone;

  bool get isActiveStatus => isActive.toLowerCase() == 'active';

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      id: json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      middleName: json['middleName'] == '-' ? null : json['middleName'],
      lastName: json['lastName'] == '-' ? null : json['lastName'],
      email: json['email'] == '-' ? null : json['email'],
      phoneCode: json['phoneCode'] ?? '+91',
      phoneNumber: json['phoneNumber'] ?? '',
      phone: json['phone'] ?? '${json['phoneCode'] ?? '+91'} ${json['phoneNumber'] ?? ''}',
      role: json['role'] ?? 'CUSTOMER',
      company: json['company'] == '-' ? null : json['company'],
      department: json['department'] == '-' ? null : json['department'],
      designation: json['designation'] == '-' ? null : json['designation'],
      division: json['division'] == '-' ? null : json['division'],
      influenceType: json['influenceType'] == '-' ? null : json['influenceType'],
      employeeCode: json['employeeCode'] == '-' ? null : json['employeeCode'],
      groups: json['groups'] == '-' ? null : json['groups'],
      isActive: json['isActive'] is bool 
          ? (json['isActive'] ? 'Active' : 'Inactive')
          : (json['isActive'] ?? 'Active'),
      createdBy: json['createdBy'] == '-' ? null : json['createdBy'],
      createdAt: json['createdAt'],
      displayValue: json['displayValue'],
      searchValue: json['searchValue'],
      isWhatsapp: json['isWhatsapp'],
      isAcknowledged: json['isAcknowledged'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'middleName': middleName,
      'lastName': lastName,
      'email': email,
      'phoneCode': phoneCode,
      'phoneNumber': phoneNumber,
      'phone': phone,
      'role': role,
      'company': company,
      'department': department,
      'designation': designation,
      'division': division,
      'influenceType': influenceType,
      'employeeCode': employeeCode,
      'groups': groups,
      'isActive': isActive,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'displayValue': displayValue,
      'searchValue': searchValue,
      'isWhatsapp': isWhatsapp,
      'isAcknowledged': isAcknowledged,
    };
  }
}
