import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_text_styles.dart';
import '../../../models/user_insights_model.dart';
import 'user_detail_bloc.dart';
import 'tabs/overview_tab.dart';
import 'tabs/inquiries_tab.dart';
import 'tabs/activities_tab.dart';
import 'tabs/whatsapp_tab.dart';
import 'tabs/product_searches_tab.dart';
import 'tabs/assignments_tab.dart';

class UserDetailScreen extends StatefulWidget {
  final String userId;

  const UserDetailScreen({super.key, required this.userId});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen>
    with SingleTickerProviderStateMixin {
  late UserDetailBloc _bloc;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _bloc = UserDetailBloc();
    _bloc.add(LoadUserInsights(widget.userId));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<UserDetailBloc>(
      create: (_) => _bloc,
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        appBar: AppBar(
          leading: const BackButton(),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: BlocBuilder<UserDetailBloc, UserDetailState>(
            builder: (context, state) {
              if (state is UserDetailLoaded) {
                return Text(
                  state.data.profile.fullName,
                  style: AppTextStyles.heading2.copyWith(color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                );
              }
              return Text(
                'User Details',
                style: AppTextStyles.heading2.copyWith(color: AppColors.textPrimary),
              );
            },
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(49),
            child: Column(
              children: [
                const Divider(height: 0.5, thickness: 1, color: AppColors.divider),
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  tabAlignment: TabAlignment.start,
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Inquiries'),
                    Tab(text: 'Activities'),
                    Tab(text: 'WhatsApp'),
                    Tab(text: 'Searches'),
                    Tab(text: 'Assignments'),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: BlocBuilder<UserDetailBloc, UserDetailState>(
          builder: (context, state) {
            if (state is UserDetailLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is UserDetailError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                      const SizedBox(height: 16),
                      Text(
                        state.message,
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _bloc.add(LoadUserInsights(widget.userId)),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            } else if (state is UserDetailLoaded) {
              return _buildTabs(state.data);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildTabs(UserInsightsResponse data) {
    return TabBarView(
      controller: _tabController,
      children: [
        OverviewTab(data: data),
        InquiriesTab(inquiries: data.inquiries),
        ActivitiesTab(activities: data.activities),
        WhatsappTab(whatsapp: data.whatsapp),
        ProductSearchesTab(searches: data.productSearches),
        AssignmentsTab(assignments: data.assignments),
      ],
    );
  }
}
