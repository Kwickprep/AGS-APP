import 'package:get_it/get_it.dart';
import '../models/dashboard_models.dart';
import 'api_service.dart';

class DashboardService {
  final ApiService _api = GetIt.I<ApiService>();

  // 1. Summary statistics (Admin)
  Future<DashboardSummary> getSummary() async {
    try {
      final res = await _api.get('/api/dashboard/summary');
      return DashboardSummary.fromJson(res.data['data']);
    } catch (e) {
      throw Exception('Failed to load summary: $e');
    }
  }

  // 2. Employee stats
  Future<EmployeeStats> getEmployeeStats() async {
    try {
      final res = await _api.get('/api/dashboard/employee-stats');
      return EmployeeStats.fromJson(res.data['data']);
    } catch (e) {
      throw Exception('Failed to load employee stats: $e');
    }
  }

  // 3. Recent inquiries
  Future<DashboardInquiriesResponse> getInquiries({int limit = 5}) async {
    try {
      final res = await _api.get('/api/dashboard/inquiries', params: {
        'limit': limit.toString(),
      });
      return DashboardInquiriesResponse.fromJson(res.data['data']);
    } catch (e) {
      throw Exception('Failed to load inquiries: $e');
    }
  }

  // 4. Scheduled activities
  Future<DashboardActivitiesResponse> getScheduledActivities({
    int limit = 5,
  }) async {
    try {
      final res = await _api.get(
        '/api/dashboard/activities/scheduled',
        params: {'limit': limit.toString()},
      );
      return DashboardActivitiesResponse.fromJson(res.data['data']);
    } catch (e) {
      throw Exception('Failed to load scheduled activities: $e');
    }
  }

  // 5. WhatsApp unread
  Future<WhatsAppUnreadResponse> getWhatsAppUnread({int limit = 5}) async {
    try {
      final res = await _api.get('/api/dashboard/whatsapp/unread', params: {
        'limit': limit.toString(),
      });
      return WhatsAppUnreadResponse.fromJson(res.data['data']);
    } catch (e) {
      throw Exception('Failed to load WhatsApp unread: $e');
    }
  }

  // 6. Scheduled campaigns
  Future<DashboardCampaignsResponse> getScheduledCampaigns({
    int limit = 5,
  }) async {
    try {
      final res = await _api.get(
        '/api/dashboard/campaigns/scheduled',
        params: {'limit': limit.toString()},
      );
      return DashboardCampaignsResponse.fromJson(res.data['data']);
    } catch (e) {
      throw Exception('Failed to load campaigns: $e');
    }
  }

  // 7. Activity type analytics
  Future<ActivityTypeAnalytics> getActivityTypeAnalytics() async {
    try {
      final res = await _api.get('/api/dashboard/analytics/activity-types');
      return ActivityTypeAnalytics.fromJson(res.data['data']);
    } catch (e) {
      throw Exception('Failed to load activity analytics: $e');
    }
  }

  // 8. Inquiry status distribution
  Future<InquiryStatusAnalytics> getInquiryStatusAnalytics() async {
    try {
      final res =
          await _api.get('/api/dashboard/analytics/inquiries/status');
      return InquiryStatusAnalytics.fromJson(res.data['data']);
    } catch (e) {
      throw Exception('Failed to load inquiry status: $e');
    }
  }

  // 9. Product search funnel
  Future<ProductSearchFunnel> getProductSearchFunnel() async {
    try {
      final res = await _api.get(
        '/api/dashboard/analytics/product-search/funnel',
      );
      return ProductSearchFunnel.fromJson(res.data['data']);
    } catch (e) {
      throw Exception('Failed to load search funnel: $e');
    }
  }

  // 10. Product search sources
  Future<ProductSearchSourceAnalytics> getProductSearchSources() async {
    try {
      final res = await _api.get(
        '/api/dashboard/analytics/product-search/sources',
      );
      return ProductSearchSourceAnalytics.fromJson(res.data['data']);
    } catch (e) {
      throw Exception('Failed to load search sources: $e');
    }
  }

  // 11. Top themes
  Future<TopThemesAnalytics> getTopThemes({int limit = 5}) async {
    try {
      final res = await _api.get(
        '/api/dashboard/analytics/product-search/themes',
        params: {'limit': limit.toString()},
      );
      return TopThemesAnalytics.fromJson(res.data['data']);
    } catch (e) {
      throw Exception('Failed to load top themes: $e');
    }
  }

  // 12. Top categories
  Future<TopCategoriesAnalytics> getTopCategories({int limit = 5}) async {
    try {
      final res = await _api.get(
        '/api/dashboard/analytics/product-search/categories',
        params: {'limit': limit.toString()},
      );
      return TopCategoriesAnalytics.fromJson(res.data['data']);
    } catch (e) {
      throw Exception('Failed to load top categories: $e');
    }
  }

  // 13. Top products
  Future<TopProductsAnalytics> getTopProducts({int limit = 5}) async {
    try {
      final res = await _api.get(
        '/api/dashboard/analytics/product-search/products',
        params: {'limit': limit.toString()},
      );
      return TopProductsAnalytics.fromJson(res.data['data']);
    } catch (e) {
      throw Exception('Failed to load top products: $e');
    }
  }

  // 14. Top companies
  Future<TopCompaniesAnalytics> getTopCompanies({int limit = 5}) async {
    try {
      final res = await _api.get(
        '/api/dashboard/analytics/inquiries/companies',
        params: {'limit': limit.toString()},
      );
      return TopCompaniesAnalytics.fromJson(res.data['data']);
    } catch (e) {
      throw Exception('Failed to load top companies: $e');
    }
  }
}
