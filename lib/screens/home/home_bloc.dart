import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../core/permissions/permission_manager.dart';
import '../../models/dashboard_models.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/dashboard_service.dart';

// =============================================================================
// Events
// =============================================================================

abstract class HomeEvent {}

class LoadDashboard extends HomeEvent {}

class RefreshDashboard extends HomeEvent {}

// =============================================================================
// Per-widget loading status
// =============================================================================

enum WidgetStatus { loading, loaded, error }

// =============================================================================
// State
// =============================================================================

class HomeState {
  final UserModel? user;
  final bool isLoading; // initial full-screen loader

  // Summary (Admin)
  final WidgetStatus summaryStatus;
  final DashboardSummary? summary;

  // Employee stats
  final WidgetStatus employeeStatsStatus;
  final EmployeeStats? employeeStats;

  // Inquiries
  final WidgetStatus inquiriesStatus;
  final DashboardInquiriesResponse? inquiries;

  // Activities
  final WidgetStatus activitiesStatus;
  final DashboardActivitiesResponse? activities;

  // WhatsApp
  final WidgetStatus whatsappStatus;
  final WhatsAppUnreadResponse? whatsapp;

  // Campaigns
  final WidgetStatus campaignsStatus;
  final DashboardCampaignsResponse? campaigns;

  // Activity type analytics
  final WidgetStatus activityAnalyticsStatus;
  final ActivityTypeAnalytics? activityAnalytics;

  // Inquiry status
  final WidgetStatus inquiryStatusStatus;
  final InquiryStatusAnalytics? inquiryStatus;

  // Funnel
  final WidgetStatus funnelStatus;
  final ProductSearchFunnel? funnel;

  // Sources
  final WidgetStatus sourcesStatus;
  final ProductSearchSourceAnalytics? sources;

  // Top themes
  final WidgetStatus topThemesStatus;
  final TopThemesAnalytics? topThemes;

  // Top categories
  final WidgetStatus topCategoriesStatus;
  final TopCategoriesAnalytics? topCategories;

  // Top products
  final WidgetStatus topProductsStatus;
  final TopProductsAnalytics? topProducts;

  // Top companies
  final WidgetStatus topCompaniesStatus;
  final TopCompaniesAnalytics? topCompanies;

  const HomeState({
    this.user,
    this.isLoading = true,
    this.summaryStatus = WidgetStatus.loading,
    this.summary,
    this.employeeStatsStatus = WidgetStatus.loading,
    this.employeeStats,
    this.inquiriesStatus = WidgetStatus.loading,
    this.inquiries,
    this.activitiesStatus = WidgetStatus.loading,
    this.activities,
    this.whatsappStatus = WidgetStatus.loading,
    this.whatsapp,
    this.campaignsStatus = WidgetStatus.loading,
    this.campaigns,
    this.activityAnalyticsStatus = WidgetStatus.loading,
    this.activityAnalytics,
    this.inquiryStatusStatus = WidgetStatus.loading,
    this.inquiryStatus,
    this.funnelStatus = WidgetStatus.loading,
    this.funnel,
    this.sourcesStatus = WidgetStatus.loading,
    this.sources,
    this.topThemesStatus = WidgetStatus.loading,
    this.topThemes,
    this.topCategoriesStatus = WidgetStatus.loading,
    this.topCategories,
    this.topProductsStatus = WidgetStatus.loading,
    this.topProducts,
    this.topCompaniesStatus = WidgetStatus.loading,
    this.topCompanies,
  });

  HomeState copyWith({
    UserModel? user,
    bool? isLoading,
    WidgetStatus? summaryStatus,
    DashboardSummary? summary,
    WidgetStatus? employeeStatsStatus,
    EmployeeStats? employeeStats,
    WidgetStatus? inquiriesStatus,
    DashboardInquiriesResponse? inquiries,
    WidgetStatus? activitiesStatus,
    DashboardActivitiesResponse? activities,
    WidgetStatus? whatsappStatus,
    WhatsAppUnreadResponse? whatsapp,
    WidgetStatus? campaignsStatus,
    DashboardCampaignsResponse? campaigns,
    WidgetStatus? activityAnalyticsStatus,
    ActivityTypeAnalytics? activityAnalytics,
    WidgetStatus? inquiryStatusStatus,
    InquiryStatusAnalytics? inquiryStatus,
    WidgetStatus? funnelStatus,
    ProductSearchFunnel? funnel,
    WidgetStatus? sourcesStatus,
    ProductSearchSourceAnalytics? sources,
    WidgetStatus? topThemesStatus,
    TopThemesAnalytics? topThemes,
    WidgetStatus? topCategoriesStatus,
    TopCategoriesAnalytics? topCategories,
    WidgetStatus? topProductsStatus,
    TopProductsAnalytics? topProducts,
    WidgetStatus? topCompaniesStatus,
    TopCompaniesAnalytics? topCompanies,
  }) {
    return HomeState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      summaryStatus: summaryStatus ?? this.summaryStatus,
      summary: summary ?? this.summary,
      employeeStatsStatus: employeeStatsStatus ?? this.employeeStatsStatus,
      employeeStats: employeeStats ?? this.employeeStats,
      inquiriesStatus: inquiriesStatus ?? this.inquiriesStatus,
      inquiries: inquiries ?? this.inquiries,
      activitiesStatus: activitiesStatus ?? this.activitiesStatus,
      activities: activities ?? this.activities,
      whatsappStatus: whatsappStatus ?? this.whatsappStatus,
      whatsapp: whatsapp ?? this.whatsapp,
      campaignsStatus: campaignsStatus ?? this.campaignsStatus,
      campaigns: campaigns ?? this.campaigns,
      activityAnalyticsStatus:
          activityAnalyticsStatus ?? this.activityAnalyticsStatus,
      activityAnalytics: activityAnalytics ?? this.activityAnalytics,
      inquiryStatusStatus: inquiryStatusStatus ?? this.inquiryStatusStatus,
      inquiryStatus: inquiryStatus ?? this.inquiryStatus,
      funnelStatus: funnelStatus ?? this.funnelStatus,
      funnel: funnel ?? this.funnel,
      sourcesStatus: sourcesStatus ?? this.sourcesStatus,
      sources: sources ?? this.sources,
      topThemesStatus: topThemesStatus ?? this.topThemesStatus,
      topThemes: topThemes ?? this.topThemes,
      topCategoriesStatus: topCategoriesStatus ?? this.topCategoriesStatus,
      topCategories: topCategories ?? this.topCategories,
      topProductsStatus: topProductsStatus ?? this.topProductsStatus,
      topProducts: topProducts ?? this.topProducts,
      topCompaniesStatus: topCompaniesStatus ?? this.topCompaniesStatus,
      topCompanies: topCompanies ?? this.topCompanies,
    );
  }
}

// =============================================================================
// BLoC
// =============================================================================

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final AuthService _authService = GetIt.I<AuthService>();
  final DashboardService _dashboardService = GetIt.I<DashboardService>();

  HomeBloc() : super(const HomeState()) {
    on<LoadDashboard>(_onLoad);
    on<RefreshDashboard>(_onRefresh);
  }

  bool get _isAdmin => PermissionManager().role == 'ADMIN';

  Future<void> _onLoad(LoadDashboard event, Emitter<HomeState> emit) async {
    emit(const HomeState(isLoading: true));

    // Load user first
    final user = await _authService.getCurrentUser();
    emit(state.copyWith(user: user, isLoading: false));

    // Fire all API calls in parallel
    await _loadAllWidgets(emit);
  }

  Future<void> _onRefresh(
      RefreshDashboard event, Emitter<HomeState> emit) async {
    // Reset all statuses to loading
    emit(HomeState(
      user: state.user,
      isLoading: false,
    ));
    await _loadAllWidgets(emit);
  }

  Future<void> _loadAllWidgets(Emitter<HomeState> emit) async {
    final futures = <Future<void>>[];

    // Summary / Employee stats (role-based)
    if (_isAdmin) {
      futures.add(_loadSummary(emit));
    } else {
      futures.add(_loadEmployeeStats(emit));
    }

    futures.addAll([
      _loadInquiries(emit),
      _loadActivities(emit),
      _loadWhatsApp(emit),
      _loadCampaigns(emit),
      _loadActivityAnalytics(emit),
      _loadInquiryStatus(emit),
      _loadFunnel(emit),
      _loadSources(emit),
      _loadTopThemes(emit),
      _loadTopCategories(emit),
      _loadTopProducts(emit),
      _loadTopCompanies(emit),
    ]);

    await Future.wait(futures);
  }

  Future<void> _loadSummary(Emitter<HomeState> emit) async {
    try {
      final data = await _dashboardService.getSummary();
      emit(state.copyWith(
        summaryStatus: WidgetStatus.loaded,
        summary: data,
      ));
    } catch (_) {
      emit(state.copyWith(summaryStatus: WidgetStatus.error));
    }
  }

  Future<void> _loadEmployeeStats(Emitter<HomeState> emit) async {
    try {
      final data = await _dashboardService.getEmployeeStats();
      emit(state.copyWith(
        employeeStatsStatus: WidgetStatus.loaded,
        employeeStats: data,
      ));
    } catch (_) {
      emit(state.copyWith(employeeStatsStatus: WidgetStatus.error));
    }
  }

  Future<void> _loadInquiries(Emitter<HomeState> emit) async {
    try {
      final data = await _dashboardService.getInquiries();
      emit(state.copyWith(
        inquiriesStatus: WidgetStatus.loaded,
        inquiries: data,
      ));
    } catch (_) {
      emit(state.copyWith(inquiriesStatus: WidgetStatus.error));
    }
  }

  Future<void> _loadActivities(Emitter<HomeState> emit) async {
    try {
      final data = await _dashboardService.getScheduledActivities();
      emit(state.copyWith(
        activitiesStatus: WidgetStatus.loaded,
        activities: data,
      ));
    } catch (_) {
      emit(state.copyWith(activitiesStatus: WidgetStatus.error));
    }
  }

  Future<void> _loadWhatsApp(Emitter<HomeState> emit) async {
    try {
      final data = await _dashboardService.getWhatsAppUnread();
      emit(state.copyWith(
        whatsappStatus: WidgetStatus.loaded,
        whatsapp: data,
      ));
    } catch (_) {
      emit(state.copyWith(whatsappStatus: WidgetStatus.error));
    }
  }

  Future<void> _loadCampaigns(Emitter<HomeState> emit) async {
    try {
      final data = await _dashboardService.getScheduledCampaigns();
      emit(state.copyWith(
        campaignsStatus: WidgetStatus.loaded,
        campaigns: data,
      ));
    } catch (_) {
      emit(state.copyWith(campaignsStatus: WidgetStatus.error));
    }
  }

  Future<void> _loadActivityAnalytics(Emitter<HomeState> emit) async {
    try {
      final data = await _dashboardService.getActivityTypeAnalytics();
      emit(state.copyWith(
        activityAnalyticsStatus: WidgetStatus.loaded,
        activityAnalytics: data,
      ));
    } catch (_) {
      emit(state.copyWith(activityAnalyticsStatus: WidgetStatus.error));
    }
  }

  Future<void> _loadInquiryStatus(Emitter<HomeState> emit) async {
    try {
      final data = await _dashboardService.getInquiryStatusAnalytics();
      emit(state.copyWith(
        inquiryStatusStatus: WidgetStatus.loaded,
        inquiryStatus: data,
      ));
    } catch (_) {
      emit(state.copyWith(inquiryStatusStatus: WidgetStatus.error));
    }
  }

  Future<void> _loadFunnel(Emitter<HomeState> emit) async {
    try {
      final data = await _dashboardService.getProductSearchFunnel();
      emit(state.copyWith(
        funnelStatus: WidgetStatus.loaded,
        funnel: data,
      ));
    } catch (_) {
      emit(state.copyWith(funnelStatus: WidgetStatus.error));
    }
  }

  Future<void> _loadSources(Emitter<HomeState> emit) async {
    try {
      final data = await _dashboardService.getProductSearchSources();
      emit(state.copyWith(
        sourcesStatus: WidgetStatus.loaded,
        sources: data,
      ));
    } catch (_) {
      emit(state.copyWith(sourcesStatus: WidgetStatus.error));
    }
  }

  Future<void> _loadTopThemes(Emitter<HomeState> emit) async {
    try {
      final data = await _dashboardService.getTopThemes();
      emit(state.copyWith(
        topThemesStatus: WidgetStatus.loaded,
        topThemes: data,
      ));
    } catch (_) {
      emit(state.copyWith(topThemesStatus: WidgetStatus.error));
    }
  }

  Future<void> _loadTopCategories(Emitter<HomeState> emit) async {
    try {
      final data = await _dashboardService.getTopCategories();
      emit(state.copyWith(
        topCategoriesStatus: WidgetStatus.loaded,
        topCategories: data,
      ));
    } catch (_) {
      emit(state.copyWith(topCategoriesStatus: WidgetStatus.error));
    }
  }

  Future<void> _loadTopProducts(Emitter<HomeState> emit) async {
    try {
      final data = await _dashboardService.getTopProducts();
      emit(state.copyWith(
        topProductsStatus: WidgetStatus.loaded,
        topProducts: data,
      ));
    } catch (_) {
      emit(state.copyWith(topProductsStatus: WidgetStatus.error));
    }
  }

  Future<void> _loadTopCompanies(Emitter<HomeState> emit) async {
    try {
      final data = await _dashboardService.getTopCompanies();
      emit(state.copyWith(
        topCompaniesStatus: WidgetStatus.loaded,
        topCompanies: data,
      ));
    } catch (_) {
      emit(state.copyWith(topCompaniesStatus: WidgetStatus.error));
    }
  }
}
