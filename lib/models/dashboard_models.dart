// =============================================================================
// Dashboard API response models — one class per endpoint
// =============================================================================

// 1. GET /dashboard/summary
class DashboardSummary {
  final int totalAdmins;
  final int totalEmployees;
  final int totalCompanies;
  final int totalCustomers;

  DashboardSummary({
    required this.totalAdmins,
    required this.totalEmployees,
    required this.totalCompanies,
    required this.totalCustomers,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      totalAdmins: json['totalAdmins'] ?? 0,
      totalEmployees: json['totalEmployees'] ?? 0,
      totalCompanies: json['totalCompanies'] ?? 0,
      totalCustomers: json['totalCustomers'] ?? 0,
    );
  }
}

// 2. GET /dashboard/employee-stats
class EmployeeStats {
  final int totalAssignedCompanies;
  final int totalAssignedCustomers;

  EmployeeStats({
    required this.totalAssignedCompanies,
    required this.totalAssignedCustomers,
  });

  factory EmployeeStats.fromJson(Map<String, dynamic> json) {
    return EmployeeStats(
      totalAssignedCompanies: json['totalAssignedCompanies'] ?? 0,
      totalAssignedCustomers: json['totalAssignedCustomers'] ?? 0,
    );
  }
}

// 3. GET /dashboard/inquiries
class DashboardInquiry {
  final String id;
  final String name;
  final String status;
  final String createdAt;
  final String companyName;
  final String contactName;

  DashboardInquiry({
    required this.id,
    required this.name,
    required this.status,
    required this.createdAt,
    required this.companyName,
    required this.contactName,
  });

  factory DashboardInquiry.fromJson(Map<String, dynamic> json) {
    final company = json['company'] as Map<String, dynamic>?;
    final contact = json['contactUser'] as Map<String, dynamic>?;
    final firstName = contact?['firstName'] ?? '';
    final lastName = contact?['lastName'] ?? '';
    return DashboardInquiry(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      status: json['status'] ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      companyName: company?['name'] ?? '',
      contactName: '$firstName $lastName'.trim(),
    );
  }
}

class DashboardInquiriesResponse {
  final List<DashboardInquiry> records;
  final int total;

  DashboardInquiriesResponse({required this.records, required this.total});

  factory DashboardInquiriesResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['records'] as List<dynamic>?)
            ?.map((e) => DashboardInquiry.fromJson(e))
            .toList() ??
        [];
    return DashboardInquiriesResponse(
      records: list,
      total: json['total'] ?? list.length,
    );
  }
}

// 4. GET /dashboard/activities/scheduled
class DashboardActivity {
  final String id;
  final String createdAt;
  final String nextScheduleDate;
  final String nextScheduleNote;
  final bool isOverdue;
  final String activityTypeName;
  final String companyName;
  final String inquiryName;
  final String userName;

  DashboardActivity({
    required this.id,
    required this.createdAt,
    required this.nextScheduleDate,
    required this.nextScheduleNote,
    required this.isOverdue,
    required this.activityTypeName,
    required this.companyName,
    required this.inquiryName,
    required this.userName,
  });

  factory DashboardActivity.fromJson(Map<String, dynamic> json) {
    final activityType = json['activityType'] as Map<String, dynamic>?;
    final company = json['company'] as Map<String, dynamic>?;
    final inquiry = json['inquiry'] as Map<String, dynamic>?;
    final user = json['user'] as Map<String, dynamic>?;
    final firstName = user?['firstName'] ?? '';
    final lastName = user?['lastName'] ?? '';
    return DashboardActivity(
      id: json['id'] ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      nextScheduleDate: json['nextScheduleDate']?.toString() ?? '',
      nextScheduleNote: json['nextScheduleNote'] ?? '',
      isOverdue: json['isOverdue'] ?? false,
      activityTypeName: activityType?['name'] ?? '',
      companyName: company?['name'] ?? '',
      inquiryName: inquiry?['name'] ?? '',
      userName: '$firstName $lastName'.trim(),
    );
  }
}

class DashboardActivitiesResponse {
  final List<DashboardActivity> records;
  final int total;

  DashboardActivitiesResponse({required this.records, required this.total});

  factory DashboardActivitiesResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['records'] as List<dynamic>?)
            ?.map((e) => DashboardActivity.fromJson(e))
            .toList() ??
        [];
    return DashboardActivitiesResponse(
      records: list,
      total: json['total'] ?? list.length,
    );
  }
}

// 5. GET /dashboard/whatsapp/unread
class WhatsAppUnreadContact {
  final String phoneNumber;
  final int unreadCount;
  final String lastMessageTime;
  final String userName;

  WhatsAppUnreadContact({
    required this.phoneNumber,
    required this.unreadCount,
    required this.lastMessageTime,
    required this.userName,
  });

  factory WhatsAppUnreadContact.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    final firstName = user?['firstName'] ?? '';
    final lastName = user?['lastName'] ?? '';
    return WhatsAppUnreadContact(
      phoneNumber: json['phoneNumber'] ?? '',
      unreadCount: json['unreadCount'] ?? 0,
      lastMessageTime: json['lastMessageTime']?.toString() ?? '',
      userName: '$firstName $lastName'.trim(),
    );
  }
}

class WhatsAppUnreadResponse {
  final List<WhatsAppUnreadContact> contacts;
  final int totalUnreadMessages;

  WhatsAppUnreadResponse({
    required this.contacts,
    required this.totalUnreadMessages,
  });

  factory WhatsAppUnreadResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['contacts'] as List<dynamic>?)
            ?.map((e) => WhatsAppUnreadContact.fromJson(e))
            .toList() ??
        [];
    return WhatsAppUnreadResponse(
      contacts: list,
      totalUnreadMessages: json['totalUnreadMessages'] ?? 0,
    );
  }
}

// 6. GET /dashboard/campaigns/scheduled
class DashboardCampaign {
  final String id;
  final String name;
  final String startDateTime;
  final int contactCount;
  final String status;
  final String categoryName;
  final String creatorName;

  DashboardCampaign({
    required this.id,
    required this.name,
    required this.startDateTime,
    required this.contactCount,
    required this.status,
    required this.categoryName,
    required this.creatorName,
  });

  factory DashboardCampaign.fromJson(Map<String, dynamic> json) {
    final category = json['templateCategory'] as Map<String, dynamic>?;
    final creator = json['creator'] as Map<String, dynamic>?;
    final firstName = creator?['firstName'] ?? '';
    final lastName = creator?['lastName'] ?? '';
    return DashboardCampaign(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      startDateTime: json['startDateTime']?.toString() ?? '',
      contactCount: json['contactCount'] ?? 0,
      status: json['status'] ?? '',
      categoryName: category?['name'] ?? '',
      creatorName: '$firstName $lastName'.trim(),
    );
  }
}

class DashboardCampaignsResponse {
  final List<DashboardCampaign> campaigns;
  final int total;

  DashboardCampaignsResponse({required this.campaigns, required this.total});

  factory DashboardCampaignsResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['campaigns'] as List<dynamic>?)
            ?.map((e) => DashboardCampaign.fromJson(e))
            .toList() ??
        [];
    return DashboardCampaignsResponse(
      campaigns: list,
      total: json['total'] ?? list.length,
    );
  }
}

// 7. GET /dashboard/analytics/activity-types
class ActivityTypeStat {
  final String activityTypeId;
  final String activityTypeName;
  final int count;
  final double percentage;

  ActivityTypeStat({
    required this.activityTypeId,
    required this.activityTypeName,
    required this.count,
    required this.percentage,
  });

  factory ActivityTypeStat.fromJson(Map<String, dynamic> json) {
    return ActivityTypeStat(
      activityTypeId: json['activityTypeId'] ?? '',
      activityTypeName: json['activityTypeName'] ?? '',
      count: json['count'] ?? 0,
      percentage: (json['percentage'] ?? 0).toDouble(),
    );
  }
}

class ActivityTypeAnalytics {
  final List<ActivityTypeStat> stats;
  final int total;

  ActivityTypeAnalytics({required this.stats, required this.total});

  factory ActivityTypeAnalytics.fromJson(Map<String, dynamic> json) {
    final list = (json['stats'] as List<dynamic>?)
            ?.map((e) => ActivityTypeStat.fromJson(e))
            .toList() ??
        [];
    return ActivityTypeAnalytics(
      stats: list,
      total: json['total'] ?? 0,
    );
  }
}

// 8. GET /dashboard/analytics/inquiries/status
class InquiryStatusItem {
  final String status;
  final String statusName;
  final int count;
  final double percentage;
  final String color;

  InquiryStatusItem({
    required this.status,
    required this.statusName,
    required this.count,
    required this.percentage,
    required this.color,
  });

  factory InquiryStatusItem.fromJson(Map<String, dynamic> json) {
    return InquiryStatusItem(
      status: json['status'] ?? '',
      statusName: json['statusName'] ?? '',
      count: json['count'] ?? 0,
      percentage: (json['percentage'] ?? 0).toDouble(),
      color: json['color'] ?? '#6B7280',
    );
  }
}

class InquiryStatusAnalytics {
  final List<InquiryStatusItem> distribution;
  final int totalInquiries;

  InquiryStatusAnalytics({
    required this.distribution,
    required this.totalInquiries,
  });

  factory InquiryStatusAnalytics.fromJson(Map<String, dynamic> json) {
    final list = (json['distribution'] as List<dynamic>?)
            ?.map((e) => InquiryStatusItem.fromJson(e))
            .toList() ??
        [];
    return InquiryStatusAnalytics(
      distribution: list,
      totalInquiries: json['totalInquiries'] ?? 0,
    );
  }
}

// 9. GET /dashboard/analytics/product-search/funnel
class FunnelStage {
  final String stage;
  final String stageName;
  final int count;
  final double percentage;
  final double? dropOffRate;

  FunnelStage({
    required this.stage,
    required this.stageName,
    required this.count,
    required this.percentage,
    this.dropOffRate,
  });

  factory FunnelStage.fromJson(Map<String, dynamic> json) {
    return FunnelStage(
      stage: json['stage'] ?? '',
      stageName: json['stageName'] ?? '',
      count: json['count'] ?? 0,
      percentage: (json['percentage'] ?? 0).toDouble(),
      dropOffRate: json['dropOffRate']?.toDouble(),
    );
  }
}

class ProductSearchFunnel {
  final List<FunnelStage> stages;
  final int totalSearches;
  final double completionRate;

  ProductSearchFunnel({
    required this.stages,
    required this.totalSearches,
    required this.completionRate,
  });

  factory ProductSearchFunnel.fromJson(Map<String, dynamic> json) {
    final list = (json['stages'] as List<dynamic>?)
            ?.map((e) => FunnelStage.fromJson(e))
            .toList() ??
        [];
    return ProductSearchFunnel(
      stages: list,
      totalSearches: json['totalSearches'] ?? 0,
      completionRate: (json['completionRate'] ?? 0).toDouble(),
    );
  }
}

// 10. GET /dashboard/analytics/product-search/sources
class ProductSearchSource {
  final String source;
  final String sourceName;
  final int count;
  final double percentage;

  ProductSearchSource({
    required this.source,
    required this.sourceName,
    required this.count,
    required this.percentage,
  });

  factory ProductSearchSource.fromJson(Map<String, dynamic> json) {
    return ProductSearchSource(
      source: json['source'] ?? '',
      sourceName: json['sourceName'] ?? '',
      count: json['count'] ?? 0,
      percentage: (json['percentage'] ?? 0).toDouble(),
    );
  }
}

class ProductSearchSourceAnalytics {
  final List<ProductSearchSource> sources;
  final int totalSearches;

  ProductSearchSourceAnalytics({
    required this.sources,
    required this.totalSearches,
  });

  factory ProductSearchSourceAnalytics.fromJson(Map<String, dynamic> json) {
    final list = (json['sources'] as List<dynamic>?)
            ?.map((e) => ProductSearchSource.fromJson(e))
            .toList() ??
        [];
    return ProductSearchSourceAnalytics(
      sources: list,
      totalSearches: json['totalSearches'] ?? 0,
    );
  }
}

// 11-14: Top items (themes, categories, products, companies) share a pattern
class RankedItem {
  final int rank;
  final String id;
  final String name;
  final int count;
  final double percentage;
  final String? imageUrl;
  final String? industry;

  RankedItem({
    required this.rank,
    required this.id,
    required this.name,
    required this.count,
    required this.percentage,
    this.imageUrl,
    this.industry,
  });
}

// 11. GET /dashboard/analytics/product-search/themes
class TopThemesAnalytics {
  final List<RankedItem> themes;
  final int totalSelections;

  TopThemesAnalytics({required this.themes, required this.totalSelections});

  factory TopThemesAnalytics.fromJson(Map<String, dynamic> json) {
    final list = (json['themes'] as List<dynamic>?)
            ?.map((e) => RankedItem(
                  rank: e['rank'] ?? 0,
                  id: e['themeId'] ?? '',
                  name: e['themeName'] ?? '',
                  count: e['count'] ?? 0,
                  percentage: (e['percentage'] ?? 0).toDouble(),
                ))
            .toList() ??
        [];
    return TopThemesAnalytics(
      themes: list,
      totalSelections: json['totalSelections'] ?? 0,
    );
  }
}

// 12. GET /dashboard/analytics/product-search/categories
class TopCategoriesAnalytics {
  final List<RankedItem> categories;
  final int totalSelections;

  TopCategoriesAnalytics({
    required this.categories,
    required this.totalSelections,
  });

  factory TopCategoriesAnalytics.fromJson(Map<String, dynamic> json) {
    final list = (json['categories'] as List<dynamic>?)
            ?.map((e) => RankedItem(
                  rank: e['rank'] ?? 0,
                  id: e['categoryId'] ?? '',
                  name: e['categoryName'] ?? '',
                  count: e['count'] ?? 0,
                  percentage: (e['percentage'] ?? 0).toDouble(),
                ))
            .toList() ??
        [];
    return TopCategoriesAnalytics(
      categories: list,
      totalSelections: json['totalSelections'] ?? 0,
    );
  }
}

// 13. GET /dashboard/analytics/product-search/products
class TopProductsAnalytics {
  final List<RankedItem> products;
  final int totalCompletions;

  TopProductsAnalytics({
    required this.products,
    required this.totalCompletions,
  });

  factory TopProductsAnalytics.fromJson(Map<String, dynamic> json) {
    final list = (json['products'] as List<dynamic>?)
            ?.map((e) => RankedItem(
                  rank: e['rank'] ?? 0,
                  id: e['productId'] ?? '',
                  name: e['productName'] ?? '',
                  count: e['count'] ?? 0,
                  percentage: (e['percentage'] ?? 0).toDouble(),
                  imageUrl: e['imageUrl'],
                ))
            .toList() ??
        [];
    return TopProductsAnalytics(
      products: list,
      totalCompletions: json['totalCompletions'] ?? 0,
    );
  }
}

// 14. GET /dashboard/analytics/inquiries/companies
class TopCompaniesAnalytics {
  final List<RankedItem> companies;
  final int totalInquiries;

  TopCompaniesAnalytics({
    required this.companies,
    required this.totalInquiries,
  });

  factory TopCompaniesAnalytics.fromJson(Map<String, dynamic> json) {
    final list = (json['companies'] as List<dynamic>?)
            ?.map((e) => RankedItem(
                  rank: e['rank'] ?? 0,
                  id: e['companyId'] ?? '',
                  name: e['companyName'] ?? '',
                  count: e['inquiryCount'] ?? 0,
                  percentage: 0,
                  industry: e['industry'],
                ))
            .toList() ??
        [];
    return TopCompaniesAnalytics(
      companies: list,
      totalInquiries: json['totalInquiries'] ?? 0,
    );
  }
}
