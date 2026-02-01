import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../core/permissions/permission_manager.dart';
import '../../widgets/app_drawer.dart';
import 'home_bloc.dart';
import 'widgets/summary_cards_widget.dart';
import 'widgets/employee_stats_widget.dart';
import 'widgets/quick_links_widget.dart';
import 'widgets/recent_inquiries_widget.dart';
import 'widgets/scheduled_activities_widget.dart';
import 'widgets/whatsapp_unread_widget.dart';
import 'widgets/scheduled_campaigns_widget.dart';
import 'widgets/activity_analytics_widget.dart';
import 'widgets/inquiry_status_widget.dart';
import 'widgets/product_search_funnel_widget.dart';
import 'widgets/product_search_source_widget.dart';
import 'widgets/top_themes_widget.dart';
import 'widgets/top_categories_widget.dart';
import 'widgets/top_products_widget.dart';
import 'widgets/top_companies_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeBloc()..add(LoadDashboard()),
      child: const HomeView(),
    );
  }
}

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
            onPressed: () => context.read<HomeBloc>().add(RefreshDashboard()),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      backgroundColor: AppColors.background,
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final isAdmin = PermissionManager().role == 'ADMIN';
          final userName = state.user?.firstName ?? '';

          return RefreshIndicator(
            onRefresh: () async {
              context.read<HomeBloc>().add(RefreshDashboard());
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Welcome header
                if (userName.isNotEmpty) ...[
                  Text(
                    'Welcome, $userName',
                    style: AppTextStyles.heading2.copyWith(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 16),
                ],

                // Quick links
                const QuickLinksWidget(),

                // Summary / Employee stats (role-based)
                if (isAdmin)
                  SummaryCardsWidget(
                    status: state.summaryStatus,
                    data: state.summary,
                  )
                else
                  EmployeeStatsWidget(
                    status: state.employeeStatsStatus,
                    data: state.employeeStats,
                  ),

                // Recent inquiries
                RecentInquiriesWidget(
                  status: state.inquiriesStatus,
                  data: state.inquiries,
                ),

                // Scheduled activities
                ScheduledActivitiesWidget(
                  status: state.activitiesStatus,
                  data: state.activities,
                ),

                // WhatsApp unread
                WhatsappUnreadWidget(
                  status: state.whatsappStatus,
                  data: state.whatsapp,
                ),

                // Scheduled campaigns
                ScheduledCampaignsWidget(
                  status: state.campaignsStatus,
                  data: state.campaigns,
                ),

                // Section header: Analytics
                _sectionHeader('Business Analytics'),

                // Activity type analytics
                ActivityAnalyticsWidget(
                  status: state.activityAnalyticsStatus,
                  data: state.activityAnalytics,
                ),

                // Inquiry status
                InquiryStatusWidget(
                  status: state.inquiryStatusStatus,
                  data: state.inquiryStatus,
                ),

                // Section header: Product Search
                _sectionHeader('Product Search Analytics'),

                // Funnel
                ProductSearchFunnelWidget(
                  status: state.funnelStatus,
                  data: state.funnel,
                ),

                // Sources
                ProductSearchSourceWidget(
                  status: state.sourcesStatus,
                  data: state.sources,
                ),

                // Top themes
                TopThemesWidget(
                  status: state.topThemesStatus,
                  data: state.topThemes,
                ),

                // Top categories
                TopCategoriesWidget(
                  status: state.topCategoriesStatus,
                  data: state.topCategories,
                ),

                // Top products
                TopProductsWidget(
                  status: state.topProductsStatus,
                  data: state.topProducts,
                ),

                // Top companies
                TopCompaniesWidget(
                  status: state.topCompaniesStatus,
                  data: state.topCompanies,
                ),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Text(
        title,
        style: AppTextStyles.heading3.copyWith(color: AppColors.textPrimary),
      ),
    );
  }
}
