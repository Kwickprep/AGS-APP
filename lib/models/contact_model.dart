class ContactModel {
  final String id;
  final String firstName;
  final String? middleName;
  final String? lastName;
  final String? email;
  final String phoneCode;
  final String phoneNumber;
  final String role;
  final bool isActive;

  ContactModel({
    required this.id,
    required this.firstName,
    this.middleName,
    this.lastName,
    this.email,
    required this.phoneCode,
    required this.phoneNumber,
    required this.role,
    required this.isActive,
  });

  String get fullName {
    final parts = [
      firstName,
      if (middleName != null && middleName!.isNotEmpty) middleName,
      if (lastName != null && lastName!.isNotEmpty) lastName,
    ];
    return parts.join(' ');
  }

  String get displayPhone => '$phoneCode$phoneNumber';

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      id: json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      middleName: json['middleName'],
      lastName: json['lastName'],
      email: json['email'],
      phoneCode: json['phoneCode'] ?? '+91',
      phoneNumber: json['phoneNumber'] ?? '',
      role: json['role'] ?? 'CUSTOMER',
      isActive: json['isActive'] ?? true,
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
      'role': role,
      'isActive': isActive,
    };
  }
}
