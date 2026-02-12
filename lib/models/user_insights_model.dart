// ============================================================================
// User Insights Model — Parses GET /api/users/{userId}/insights
// ============================================================================

class UserInsightsResponse {
  final UserProfile profile;
  final UserStats stats;
  final UserInquiries inquiries;
  final UserActivities activities;
  final UserWhatsApp whatsapp;
  final UserAssignments assignments;
  final UserProductSearches productSearches;

  UserInsightsResponse({
    required this.profile,
    required this.stats,
    required this.inquiries,
    required this.activities,
    required this.whatsapp,
    required this.assignments,
    required this.productSearches,
  });

  factory UserInsightsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return UserInsightsResponse(
      profile: UserProfile.fromJson(data['profile'] ?? {}),
      stats: UserStats.fromJson(data['stats'] ?? {}),
      inquiries: UserInquiries.fromJson(data['inquiries'] ?? {}),
      activities: UserActivities.fromJson(data['activities'] ?? {}),
      whatsapp: UserWhatsApp.fromJson(data['whatsapp'] ?? {}),
      assignments: UserAssignments.fromJson(data['assignments'] ?? {}),
      productSearches: UserProductSearches.fromJson(data['productSearches'] ?? {}),
    );
  }
}

// ============================================================================
// Profile
// ============================================================================

class UserProfile {
  final String id;
  final String firstName;
  final String middleName;
  final String lastName;
  final String email;
  final String phone;
  final String role;
  final String department;
  final String designation;
  final String division;
  final String employeeCode;
  final bool isActive;
  final bool isWhatsapp;
  final String note;
  final String? profilePicture;
  final String company;
  final List<String> assignedCompanies;
  final String creator;
  final String? createdAt;
  final String? updatedAt;
  final Map<String, dynamic> address;

  UserProfile({
    required this.id,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.role,
    required this.department,
    required this.designation,
    required this.division,
    required this.employeeCode,
    required this.isActive,
    required this.isWhatsapp,
    required this.note,
    this.profilePicture,
    required this.company,
    required this.assignedCompanies,
    required this.creator,
    this.createdAt,
    this.updatedAt,
    required this.address,
  });

  String get fullName {
    final parts = [firstName, middleName, lastName]
        .where((p) => p.isNotEmpty && p != '-')
        .toList();
    return parts.isEmpty ? 'N/A' : parts.join(' ');
  }

  String get initials {
    final f = firstName.isNotEmpty ? firstName[0] : '';
    final l = lastName.isNotEmpty ? lastName[0] : '';
    return '$f$l'.toUpperCase();
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: _str(json['id']),
      firstName: _str(json['firstName']),
      middleName: _str(json['middleName']),
      lastName: _str(json['lastName']),
      email: _str(json['email']),
      phone: _str(json['phone']),
      role: _str(json['role']),
      department: _str(json['department']),
      designation: _str(json['designation']),
      division: _str(json['division']),
      employeeCode: _str(json['employeeCode']),
      isActive: json['isActive'] == true || json['isActive'] == 'Active',
      isWhatsapp: json['isWhatsapp'] == true,
      note: _str(json['note']),
      profilePicture: json['profilePicture'],
      company: _str(json['company']),
      assignedCompanies: (json['assignedCompanies'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      creator: _str(json['creator']),
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      address: (json['address'] as Map<String, dynamic>?) ?? {},
    );
  }
}

// ============================================================================
// Stats
// ============================================================================

class UserStats {
  final int totalInquiries;
  final int totalActivities;
  final int totalMessages;
  final int totalProductSearches;
  final int assignedCompanies;
  final int assignedCustomers;
  final int groupCount;

  UserStats({
    required this.totalInquiries,
    required this.totalActivities,
    required this.totalMessages,
    required this.totalProductSearches,
    required this.assignedCompanies,
    required this.assignedCustomers,
    required this.groupCount,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalInquiries: _int(json['totalInquiries']),
      totalActivities: _int(json['totalActivities']),
      totalMessages: _int(json['totalMessages']),
      totalProductSearches: _int(json['totalProductSearches']),
      assignedCompanies: _int(json['assignedCompanies']),
      assignedCustomers: _int(json['assignedCustomers']),
      groupCount: _int(json['groupCount']),
    );
  }
}

// ============================================================================
// Inquiries
// ============================================================================

class UserInquiries {
  final int total;
  final List<InsightInquiryStatus> byStatus;
  final List<InsightTrendItem> trend;
  final List<InsightRecentInquiry> recent;

  UserInquiries({
    required this.total,
    required this.byStatus,
    required this.trend,
    required this.recent,
  });

  factory UserInquiries.fromJson(Map<String, dynamic> json) {
    return UserInquiries(
      total: _int(json['total']),
      byStatus: _list(json['byStatus'], InsightInquiryStatus.fromJson),
      trend: _list(json['trend'], InsightTrendItem.fromJson),
      recent: _list(json['recent'], InsightRecentInquiry.fromJson),
    );
  }
}

class InsightInquiryStatus {
  final String status;
  final int count;
  final double percentage;

  InsightInquiryStatus({
    required this.status,
    required this.count,
    required this.percentage,
  });

  factory InsightInquiryStatus.fromJson(Map<String, dynamic> json) {
    return InsightInquiryStatus(
      status: _str(json['status']),
      count: _int(json['count']),
      percentage: _dbl(json['percentage']),
    );
  }
}

class InsightTrendItem {
  final String month;
  final int count;
  final int? sent;
  final int? received;

  InsightTrendItem({
    required this.month,
    required this.count,
    this.sent,
    this.received,
  });

  factory InsightTrendItem.fromJson(Map<String, dynamic> json) {
    return InsightTrendItem(
      month: _str(json['month']),
      count: _int(json['count']),
      sent: json['sent'] as int?,
      received: json['received'] as int?,
    );
  }
}

class InsightRecentInquiry {
  final String id;
  final String name;
  final String status;
  final String company;
  final String? date;

  InsightRecentInquiry({
    required this.id,
    required this.name,
    required this.status,
    required this.company,
    this.date,
  });

  factory InsightRecentInquiry.fromJson(Map<String, dynamic> json) {
    return InsightRecentInquiry(
      id: _str(json['id']),
      name: _str(json['name']),
      status: _str(json['status']),
      company: _str(json['company']),
      date: json['date'] ?? json['createdAt'],
    );
  }
}

// ============================================================================
// Activities
// ============================================================================

class UserActivities {
  final int total;
  final List<InsightActivityByType> byType;
  final List<InsightActivityBySource> bySource;
  final List<InsightTrendItem> trend;
  final List<InsightRecentActivity> recent;

  UserActivities({
    required this.total,
    required this.byType,
    required this.bySource,
    required this.trend,
    required this.recent,
  });

  factory UserActivities.fromJson(Map<String, dynamic> json) {
    return UserActivities(
      total: _int(json['total']),
      byType: _list(json['byType'], InsightActivityByType.fromJson),
      bySource: _list(json['bySource'], InsightActivityBySource.fromJson),
      trend: _list(json['trend'], InsightTrendItem.fromJson),
      recent: _list(json['recent'], InsightRecentActivity.fromJson),
    );
  }
}

class InsightActivityByType {
  final String type;
  final int count;
  final double percentage;

  InsightActivityByType({
    required this.type,
    required this.count,
    required this.percentage,
  });

  factory InsightActivityByType.fromJson(Map<String, dynamic> json) {
    return InsightActivityByType(
      type: _str(json['type']),
      count: _int(json['count']),
      percentage: _dbl(json['percentage']),
    );
  }
}

class InsightActivityBySource {
  final String source;
  final int count;
  final double percentage;

  InsightActivityBySource({
    required this.source,
    required this.count,
    required this.percentage,
  });

  factory InsightActivityBySource.fromJson(Map<String, dynamic> json) {
    return InsightActivityBySource(
      source: _str(json['source']),
      count: _int(json['count']),
      percentage: _dbl(json['percentage']),
    );
  }
}

class InsightRecentActivity {
  final String id;
  final String typeName;
  final String companyName;
  final String inquiryName;
  final String? date;

  InsightRecentActivity({
    required this.id,
    required this.typeName,
    required this.companyName,
    required this.inquiryName,
    this.date,
  });

  factory InsightRecentActivity.fromJson(Map<String, dynamic> json) {
    return InsightRecentActivity(
      id: _str(json['id']),
      typeName: _str(json['typeName']),
      companyName: _str(json['companyName']),
      inquiryName: _str(json['inquiryName']),
      date: json['date'] ?? json['createdAt'],
    );
  }
}

// ============================================================================
// WhatsApp
// ============================================================================

class UserWhatsApp {
  final int totalSent;
  final int totalReceived;
  final int unread;
  final String? lastMessageAt;
  final List<InsightTrendItem> trend;
  final List<InsightWhatsAppMessage> recentMessages;

  UserWhatsApp({
    required this.totalSent,
    required this.totalReceived,
    required this.unread,
    this.lastMessageAt,
    required this.trend,
    required this.recentMessages,
  });

  factory UserWhatsApp.fromJson(Map<String, dynamic> json) {
    return UserWhatsApp(
      totalSent: _int(json['totalSent']),
      totalReceived: _int(json['totalReceived']),
      unread: _int(json['unread']),
      lastMessageAt: json['lastMessageAt'],
      trend: _list(json['trend'], InsightTrendItem.fromJson),
      recentMessages: _list(json['recentMessages'], InsightWhatsAppMessage.fromJson),
    );
  }
}

class InsightWhatsAppMessage {
  final String id;
  final String body;
  final String direction; // "inbound" or "outbound"
  final String? timestamp;
  final String status;

  InsightWhatsAppMessage({
    required this.id,
    required this.body,
    required this.direction,
    this.timestamp,
    required this.status,
  });

  bool get isInbound => direction == 'inbound';

  factory InsightWhatsAppMessage.fromJson(Map<String, dynamic> json) {
    return InsightWhatsAppMessage(
      id: _str(json['id']),
      body: _str(json['body']),
      direction: _str(json['direction']),
      timestamp: json['timestamp'] ?? json['createdAt'],
      status: _str(json['status']),
    );
  }
}

// ============================================================================
// Assignments
// ============================================================================

class UserAssignments {
  final List<InsightNameCount> companies;
  final List<InsightNameCount> customers;
  final List<InsightNameCount> groups;

  UserAssignments({
    required this.companies,
    required this.customers,
    required this.groups,
  });

  factory UserAssignments.fromJson(Map<String, dynamic> json) {
    return UserAssignments(
      companies: _list(json['companies'], InsightNameCount.fromJson),
      customers: _list(json['customers'], InsightNameCount.fromJson),
      groups: _list(json['groups'], InsightNameCount.fromJson),
    );
  }
}

class InsightNameCount {
  final String id;
  final String name;
  final int count;

  InsightNameCount({
    required this.id,
    required this.name,
    required this.count,
  });

  factory InsightNameCount.fromJson(Map<String, dynamic> json) {
    return InsightNameCount(
      id: _str(json['id']),
      name: _str(json['name']),
      count: _int(json['count']),
    );
  }
}

// ============================================================================
// Product Searches
// ============================================================================

class UserProductSearches {
  final int totalSearches;
  final int completedSearches;
  final double completionRate;
  final List<InsightNameCount> topThemes;
  final List<InsightNameCount> topCategories;
  final List<InsightNameCount> topPriceRanges;
  final List<InsightNameCount> topProducts;
  final List<InsightNameCount> topBrands;
  final List<InsightNameCount> topMOQs;
  final List<InsightRecentSearch> recentSearches;

  UserProductSearches({
    required this.totalSearches,
    required this.completedSearches,
    required this.completionRate,
    required this.topThemes,
    required this.topCategories,
    required this.topPriceRanges,
    required this.topProducts,
    required this.topBrands,
    required this.topMOQs,
    required this.recentSearches,
  });

  factory UserProductSearches.fromJson(Map<String, dynamic> json) {
    return UserProductSearches(
      totalSearches: _int(json['totalSearches']),
      completedSearches: _int(json['completedSearches']),
      completionRate: _dbl(json['completionRate']),
      topThemes: _list(json['topThemes'], InsightNameCount.fromJson),
      topCategories: _list(json['topCategories'], InsightNameCount.fromJson),
      topPriceRanges: _list(json['topPriceRanges'], InsightNameCount.fromJson),
      topProducts: _list(json['topProducts'], InsightNameCount.fromJson),
      topBrands: _list(json['topBrands'], InsightNameCount.fromJson),
      topMOQs: _list(json['topMOQs'], InsightNameCount.fromJson),
      recentSearches: _list(json['recentSearches'], InsightRecentSearch.fromJson),
    );
  }
}

class InsightRecentSearch {
  final String id;
  final String inputText;
  final String theme;
  final String priceRange;
  final String stage;
  final String? date;

  InsightRecentSearch({
    required this.id,
    required this.inputText,
    required this.theme,
    required this.priceRange,
    required this.stage,
    this.date,
  });

  factory InsightRecentSearch.fromJson(Map<String, dynamic> json) {
    return InsightRecentSearch(
      id: _str(json['id']),
      inputText: _str(json['inputText']),
      theme: _str(json['theme']),
      priceRange: _str(json['priceRange']),
      stage: _str(json['stage']),
      date: json['date'] ?? json['createdAt'],
    );
  }
}

// ============================================================================
// Helpers
// ============================================================================

String _str(dynamic v) {
  if (v == null) return '';
  if (v is String) return v;
  if (v is Map) return v['name']?.toString() ?? v['id']?.toString() ?? '';
  return v.toString();
}

int _int(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

double _dbl(dynamic v) {
  if (v == null) return 0.0;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}

List<T> _list<T>(dynamic v, T Function(Map<String, dynamic>) fromJson) {
  if (v == null || v is! List) return [];
  return v.map((e) => fromJson(e as Map<String, dynamic>)).toList();
}
