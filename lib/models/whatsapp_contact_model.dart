/// Model for WhatsApp contact from /api/whatsapp/contacts
class WhatsAppContact {
  final WhatsAppUser user;
  final WhatsAppMessage? lastMessage;
  final int unreadCount;
  final String? lastMessageTime;

  WhatsAppContact({
    required this.user,
    this.lastMessage,
    required this.unreadCount,
    this.lastMessageTime,
  });

  factory WhatsAppContact.fromJson(Map<String, dynamic> json) {
    return WhatsAppContact(
      user: WhatsAppUser.fromJson(json['user'] ?? {}),
      lastMessage: json['lastMessage'] != null
          ? WhatsAppMessage.fromJson(json['lastMessage'])
          : null,
      unreadCount: json['unreadCount'] ?? 0,
      lastMessageTime: json['lastMessageTime'],
    );
  }

  /// Get display name for the contact
  String get displayName {
    final parts = <String>[];
    if (user.firstName.isNotEmpty) parts.add(user.firstName);
    if (user.middleName != null && user.middleName!.isNotEmpty) {
      parts.add(user.middleName!);
    }
    if (user.lastName != null && user.lastName!.isNotEmpty) {
      parts.add(user.lastName!);
    }
    return parts.isNotEmpty ? parts.join(' ') : user.phoneNumber;
  }

  /// Get formatted phone number
  String get formattedPhone => '${user.phoneCode} ${user.phoneNumber}';

  /// Get last message preview
  String get lastMessagePreview {
    if (lastMessage == null) return 'No messages yet';
    final content = lastMessage!.content ?? '';
    // Truncate and remove newlines for preview
    final preview = content.replaceAll('\n', ' ').trim();
    return preview.length > 50 ? '${preview.substring(0, 50)}...' : preview;
  }

  /// Check if there are unread messages
  bool get hasUnread => unreadCount > 0;
}

/// User model for WhatsApp contact
class WhatsAppUser {
  final String id;
  final String firstName;
  final String? middleName;
  final String? lastName;
  final String? email;
  final String role;
  final String phoneCode;
  final String phoneNumber;
  final bool isActive;
  final bool isWhatsapp;
  final String? department;
  final String? division;
  final String? designation;
  final bool isRegistered;
  final String? userProvidedCompany;
  final String? userProvidedIndustry;
  final String? registrationStage;
  final WhatsAppProfilePicture? profilePicture;
  final String createdAt;
  final String updatedAt;

  WhatsAppUser({
    required this.id,
    required this.firstName,
    this.middleName,
    this.lastName,
    this.email,
    required this.role,
    required this.phoneCode,
    required this.phoneNumber,
    required this.isActive,
    required this.isWhatsapp,
    this.department,
    this.division,
    this.designation,
    required this.isRegistered,
    this.userProvidedCompany,
    this.userProvidedIndustry,
    this.registrationStage,
    this.profilePicture,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WhatsAppUser.fromJson(Map<String, dynamic> json) {
    return WhatsAppUser(
      id: json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      middleName: json['middleName'],
      lastName: json['lastName'],
      email: json['email'],
      role: json['role'] ?? 'CUSTOMER',
      phoneCode: json['phoneCode'] ?? '+91',
      phoneNumber: json['phoneNumber'] ?? '',
      isActive: json['isActive'] ?? true,
      isWhatsapp: json['isWhatsapp'] ?? false,
      department: json['department'],
      division: json['division'],
      designation: json['designation'],
      isRegistered: json['isRegistered'] ?? false,
      userProvidedCompany: json['userProvidedCompany'],
      userProvidedIndustry: json['userProvidedIndustry'],
      registrationStage: json['registrationStage'],
      profilePicture: json['profilePicture'] != null
          ? WhatsAppProfilePicture.fromJson(json['profilePicture'])
          : null,
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }

  String get fullName {
    final parts = <String>[];
    if (firstName.isNotEmpty) parts.add(firstName);
    if (middleName != null && middleName!.isNotEmpty) parts.add(middleName!);
    if (lastName != null && lastName!.isNotEmpty) parts.add(lastName!);
    return parts.isNotEmpty ? parts.join(' ') : phoneNumber;
  }

  String get initials {
    if (firstName.isNotEmpty) {
      final firstInitial = firstName[0].toUpperCase();
      if (lastName != null && lastName!.isNotEmpty) {
        return '$firstInitial${lastName![0].toUpperCase()}';
      }
      return firstInitial;
    }
    return '?';
  }
}

/// Profile picture model for WhatsApp
class WhatsAppProfilePicture {
  final String id;
  final String fileName;
  final String fileKey;
  final String fileUrl;
  final String mimeType;
  final int size;

  WhatsAppProfilePicture({
    required this.id,
    required this.fileName,
    required this.fileKey,
    required this.fileUrl,
    required this.mimeType,
    required this.size,
  });

  factory WhatsAppProfilePicture.fromJson(Map<String, dynamic> json) {
    return WhatsAppProfilePicture(
      id: json['id'] ?? '',
      fileName: json['fileName'] ?? '',
      fileKey: json['fileKey'] ?? '',
      fileUrl: json['fileUrl'] ?? '',
      mimeType: json['mimeType'] ?? '',
      size: json['size'] ?? 0,
    );
  }
}

/// Message model for WhatsApp
class WhatsAppMessage {
  final String id;
  final String? createdBy;
  final String createdAt;
  final String updatedAt;
  final String userId;
  final String phoneNumber;
  final String? messageId;
  final String? content;
  final String messageType;
  final String? mediaUrl;
  final String direction; // 'inbound' or 'outbound'
  final String status; // 'sent', 'delivered', 'read', etc.
  final bool isRead;
  final Map<String, dynamic>? metadata;
  final String? referencedMessageId;
  final WhatsAppMessage? referencedMessage;

  WhatsAppMessage({
    required this.id,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
    required this.phoneNumber,
    this.messageId,
    this.content,
    required this.messageType,
    this.mediaUrl,
    required this.direction,
    required this.status,
    required this.isRead,
    this.metadata,
    this.referencedMessageId,
    this.referencedMessage,
  });

  factory WhatsAppMessage.fromJson(Map<String, dynamic> json) {
    return WhatsAppMessage(
      id: json['id'] ?? '',
      createdBy: json['createdBy'],
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      userId: json['userId'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      messageId: json['messageId'],
      content: json['content'],
      messageType: json['messageType'] ?? 'text',
      mediaUrl: json['mediaUrl'],
      direction: json['direction'] ?? 'inbound',
      status: json['status'] ?? 'sent',
      isRead: json['isRead'] ?? false,
      metadata: json['metadata'],
      referencedMessageId: json['referencedMessageId'],
      referencedMessage: json['referencedMessage'] != null
          ? WhatsAppMessage.fromJson(json['referencedMessage'])
          : null,
    );
  }

  bool get isOutbound => direction == 'outbound';
  bool get isInbound => direction == 'inbound';
  bool get hasReferencedMessage => referencedMessage != null;
}

/// Response model for WhatsApp contacts API
class WhatsAppContactsResponse {
  final List<WhatsAppContact> records;

  WhatsAppContactsResponse({
    required this.records,
  });

  factory WhatsAppContactsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    return WhatsAppContactsResponse(
      records: (data['records'] as List<dynamic>?)
              ?.map((e) => WhatsAppContact.fromJson(e))
              .toList() ??
          [],
    );
  }
}
