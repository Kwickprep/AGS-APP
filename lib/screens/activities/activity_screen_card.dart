import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../config/app_colors.dart';
import '../../models/activity_model.dart';
import '../../services/activity_service.dart';
import '../../widgets/generic/index.dart';
import '../../widgets/common_list_card.dart';
import 'activity_create_screen.dart';

/// Activity list screen with card-based UI
class ActivityScreenCard extends StatefulWidget {
  const ActivityScreenCard({Key? key}) : super(key: key);

  @override
  State<ActivityScreenCard> createState() => _ActivityScreenCardState();
}

class _ActivityScreenCardState extends State<ActivityScreenCard> {
  late GenericListBloc<ActivityModel> _bloc;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _bloc = GenericListBloc<ActivityModel>(
      service: GetIt.I<ActivityService>(),
      sortComparator: _activitySortComparator,
    );
    _bloc.add(LoadData());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Activities'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _navigateToCreate,
            tooltip: 'Create Activity',
          ),
        ],
      ),
      body: BlocProvider<GenericListBloc<ActivityModel>>(
        create: (_) => _bloc,
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search activities...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _bloc.add(SearchData(''));
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.lightGrey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.lightGrey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                ),
                onChanged: (value) {
                  _bloc.add(SearchData(value));
                  setState(() {});
                },
              ),
            ),

            // Card list
            Expanded(
              child: BlocBuilder<GenericListBloc<ActivityModel>, GenericListState>(
                builder: (context, state) {
                  if (state is GenericListLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is GenericListError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                          const SizedBox(height: 16),
                          Text(state.message, style: const TextStyle(fontSize: 16)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => _bloc.add(LoadData()),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  } else if (state is GenericListLoaded<ActivityModel>) {
                    if (state.data.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.event_note_outlined, size: 64, color: AppColors.grey),
                            const SizedBox(height: 16),
                            const Text('No activities found', style: TextStyle(fontSize: 16)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _navigateToCreate,
                              child: const Text('Create Activity'),
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        _bloc.add(LoadData());
                        await Future.delayed(const Duration(milliseconds: 500));
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: state.data.length,
                        itemBuilder: (context, index) {
                          final activity = state.data[index];
                          return _buildActivityCard(activity);
                        },
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(ActivityModel activity) {
    return CommonListCard(
      title: activity.inquiry,
      statusBadge: StatusBadgeConfig.status(activity.activityType),
      rows: [
        CardRowConfig(
          icon: Icons.business_outlined,
          text: activity.company,
          iconColor: AppColors.primary,
        ),
        CardRowConfig(
          icon: Icons.person_outline,
          text: activity.user,
          iconColor: AppColors.primary,
        ),
        CardRowConfig(
          icon: Icons.calendar_today_outlined,
          text: activity.nextScheduleDate.isNotEmpty
              ? activity.nextScheduleDate
              : activity.createdAt,
          iconColor: AppColors.primary,
        ),
      ],
      onView: () {
        _showActivityDetails(activity);
      },
      onDelete: () {
        _confirmDelete(activity);
      },
    );
  }

  void _showActivityDetails(ActivityModel activity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(activity.inquiry),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Activity Type', activity.activityType),
              _buildDetailRow('Company', activity.company),
              _buildDetailRow('User', activity.user),
              _buildDetailRow('Theme', activity.theme),
              _buildDetailRow('Category', activity.category),
              _buildDetailRow('Product', activity.product),
              _buildDetailRow('Price Range', activity.priceRange),
              _buildDetailRow('MOQ', activity.moq),
              _buildDetailRow('Documents', activity.documents.isEmpty ? '-' : activity.documents),
              _buildDetailRow('Next Schedule', activity.nextScheduleDate.isEmpty ? '-' : activity.nextScheduleDate),
              _buildDetailRow('Note', activity.note.isEmpty ? '-' : activity.note),
              _buildDetailRow('Created By', activity.createdBy),
              _buildDetailRow('Created Date', activity.createdAt),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: AppColors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(ActivityModel activity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete this activity for "${activity.inquiry}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _bloc.add(DeleteData(activity.id));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Activity deleted successfully')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToCreate() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ActivityCreateScreen()),
    );
    if (result == true && mounted) {
      _bloc.add(LoadData());
    }
  }

  /// Sort comparator for activities
  int _activitySortComparator(ActivityModel a, ActivityModel b, String sortBy, String sortOrder) {
    int comparison = 0;

    switch (sortBy) {
      case 'inquiry':
        comparison = a.inquiry.compareTo(b.inquiry);
        break;
      case 'activityType':
        comparison = a.activityType.compareTo(b.activityType);
        break;
      case 'company':
        comparison = a.company.compareTo(b.company);
        break;
      case 'user':
        comparison = a.user.compareTo(b.user);
        break;
      case 'createdAt':
        comparison = _parseDate(a.createdAt).compareTo(_parseDate(b.createdAt));
        break;
      case 'nextScheduleDate':
        comparison = _parseDate(a.nextScheduleDate).compareTo(_parseDate(b.nextScheduleDate));
        break;
      default:
        comparison = 0;
    }

    return sortOrder == 'asc' ? comparison : -comparison;
  }

  /// Parse date string in format "DD-MM-YYYY"
  DateTime _parseDate(String dateStr) {
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[2]), // year
          int.parse(parts[1]), // month
          int.parse(parts[0]), // day
        );
      }
    } catch (e) {
      // Return current date if parsing fails
    }
    return DateTime.now();
  }
}
