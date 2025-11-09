class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String role;
  final String? phoneCode;
  final String? phoneNumber;
  final List<String>? permissions;
  final bool? isActive;
  final String? designation;
  final String? employeeCode;

  UserModel({
    required this.id,
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    this.role = '',
    this.phoneCode,
    this.phoneNumber,
    this.permissions,
    this.isActive,
    this.designation,
    this.employeeCode,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      phoneCode: json['phoneCode'],
      phoneNumber: json['phoneNumber'],
      permissions: json['permissions'] != null
          ? List<String>.from(json['permissions'])
          : null,
      isActive: json['isActive'],
      designation: json['designation'],
      employeeCode: json['employeeCode'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'role': role,
      if (phoneCode != null) 'phoneCode': phoneCode,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (permissions != null) 'permissions': permissions,
      if (isActive != null) 'isActive': isActive,
      if (designation != null) 'designation': designation,
      if (employeeCode != null) 'employeeCode': employeeCode,
    };
  }

  String get fullName => '$firstName $lastName'.trim();
  String get phone => phoneCode != null && phoneNumber != null
      ? '$phoneCode $phoneNumber'
      : '';
}
