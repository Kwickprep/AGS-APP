import 'package:ags/screens/inquiries/inquiry_create_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../config/app_colors.dart';
import '../../models/inquiry_model.dart';
import '../../services/inquiry_service.dart';
import '../../widgets/generic/index.dart';
import '../../widgets/common_list_card.dart';

/// Inquiry list screen with card-based UI
class InquiryScreenNew extends StatefulWidget {
  const InquiryScreenNew({Key? key}) : super(key: key);

  @override
  State<InquiryScreenNew> createState() => _InquiryScreenNewState();
}

class _InquiryScreenNewState extends State<InquiryScreenNew> {
  late GenericListBloc<InquiryModel> _bloc;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _bloc = GenericListBloc<InquiryModel>(
      service: GetIt.I<InquiryService>(),
      sortComparator: _inquirySortComparator,
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
        title: const Text('Inquiries'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _navigateToCreate,
            tooltip: 'Create Inquiry',
          ),
        ],
      ),
      body: BlocProvider<GenericListBloc<InquiryModel>>(
        create: (_) => _bloc,
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search inquiries...',
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
              child: BlocBuilder<GenericListBloc<InquiryModel>, GenericListState>(
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
                  } else if (state is GenericListLoaded<InquiryModel>) {
                    if (state.data.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.assignment_outlined, size: 64, color: AppColors.grey),
                            const SizedBox(height: 16),
                            const Text('No inquiries found', style: TextStyle(fontSize: 16)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _navigateToCreate,
                              child: const Text('Create Inquiry'),
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
                          final inquiry = state.data[index];
                          return _buildInquiryCard(inquiry);
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

  Widget _buildInquiryCard(InquiryModel inquiry) {
    return CommonListCard(
      title: inquiry.name,
      statusBadge: StatusBadgeConfig.status(inquiry.status),
      rows: [
        CardRowConfig(
          icon: Icons.business_outlined,
          text: inquiry.company,
          iconColor: AppColors.primary,
        ),
        CardRowConfig(
          icon: Icons.person_outline,
          text: inquiry.contactUser,
          iconColor: AppColors.primary,
        ),
        CardRowConfig(
          icon: Icons.calendar_today_outlined,
          text: inquiry.createdAt,
          iconColor: AppColors.primary,
        ),
      ],
      onView: () {
        // Navigate to inquiry detail/view
        _showInquiryDetails(inquiry);
      },
      onDelete: () {
        _confirmDelete(inquiry);
      },
    );
  }

  void _showInquiryDetails(InquiryModel inquiry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(inquiry.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Company', inquiry.company),
              _buildDetailRow('Contact User', inquiry.contactUser),
              _buildDetailRow('Status', inquiry.status),
              _buildDetailRow('Note', inquiry.note.isEmpty ? '-' : inquiry.note),
              _buildDetailRow('Created By', inquiry.createdBy),
              _buildDetailRow('Created Date', inquiry.createdAt),
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

  void _confirmDelete(InquiryModel inquiry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "${inquiry.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _bloc.add(DeleteData(inquiry.id));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Inquiry deleted successfully')),
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
      MaterialPageRoute(builder: (context) => const InquiryCreateScreen()),
    );
    if (result == true && mounted) {
      _bloc.add(LoadData());
    }
  }

  /// Sort comparator for inquiries
  int _inquirySortComparator(InquiryModel a, InquiryModel b, String sortBy, String sortOrder) {
    int comparison = 0;

    switch (sortBy) {
      case 'name':
        comparison = a.name.compareTo(b.name);
        break;
      case 'company':
        comparison = a.company.compareTo(b.company);
        break;
      case 'contactUser':
        comparison = a.contactUser.compareTo(b.contactUser);
        break;
      case 'status':
        comparison = a.status.compareTo(b.status);
        break;
      case 'createdAt':
        comparison = _parseDate(a.createdAt).compareTo(_parseDate(b.createdAt));
        break;
      case 'createdBy':
        comparison = a.createdBy.compareTo(b.createdBy);
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
