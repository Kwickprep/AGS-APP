import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../models/activity_model.dart';
import '../../services/activity_service.dart';

// Events
abstract class ActivityEvent {}

class LoadActivities extends ActivityEvent {
  final int page;
  final int take;
  final String search;
  final String sortBy;
  final String sortOrder;

  LoadActivities({
    this.page = 1,
    this.take = 20,
    this.search = '',
    this.sortBy = 'createdAt',
    this.sortOrder = 'desc',
  });
}

class SearchActivities extends ActivityEvent {
  final String query;
  SearchActivities(this.query);
}

class SortActivities extends ActivityEvent {
  final String sortBy;
  final String sortOrder;
  SortActivities(this.sortBy, this.sortOrder);
}

class ChangePageSize extends ActivityEvent {
  final int pageSize;
  ChangePageSize(this.pageSize);
}

class ChangePage extends ActivityEvent {
  final int page;
  ChangePage(this.page);
}

class DeleteActivity extends ActivityEvent {
  final String id;
  DeleteActivity(this.id);
}

class ApplyFilters extends ActivityEvent {
  final Map<String, dynamic> filters;
  ApplyFilters(this.filters);
}

// States
abstract class ActivityState {}

class ActivityInitial extends ActivityState {}

class ActivityLoading extends ActivityState {}

class ActivityLoaded extends ActivityState {
  final List<ActivityModel> activities;
  final int total;
  final int page;
  final int take;
  final int totalPages;
  final String search;
  final String sortBy;
  final String sortOrder;
  final Map<String, dynamic>? filters;

  ActivityLoaded({
    required this.activities,
    required this.total,
    required this.page,
    required this.take,
    required this.totalPages,
    required this.search,
    required this.sortBy,
    required this.sortOrder,
    this.filters,
  });
}

class ActivityError extends ActivityState {
  final String message;
  ActivityError(this.message);
}

// Bloc
class ActivityBloc extends Bloc<ActivityEvent, ActivityState> {
  final ActivityService _activityService = GetIt.I<ActivityService>();

  // Keep track of current parameters
  int _currentPage = 1;
  int _currentPageSize = 20;
  String _currentSearch = '';
  String _currentSortBy = 'createdAt';
  String _currentSortOrder = 'desc';
  Map<String, dynamic> _currentFilters = {};

  // Cache original data for client-side filtering
  List<ActivityModel> _allActivities = [];
  int _originalTotal = 0;

  ActivityBloc() : super(ActivityInitial()) {
    on<LoadActivities>(_onLoadActivities);
    on<SearchActivities>(_onSearchActivities);
    on<SortActivities>(_onSortActivities);
    on<ChangePageSize>(_onChangePageSize);
    on<ChangePage>(_onChangePage);
    on<DeleteActivity>(_onDeleteActivity);
    on<ApplyFilters>(_onApplyFilters);
  }

  Future<void> _onLoadActivities(
    LoadActivities event,
    Emitter<ActivityState> emit,
  ) async {
    print('ActivityBloc: Loading activities...');
    emit(ActivityLoading());

    try {
      _currentPage = event.page;
      _currentPageSize = event.take;
      _currentSearch = event.search;
      _currentSortBy = event.sortBy;
      _currentSortOrder = event.sortOrder;

      print('ActivityBloc: Calling API...');
      final response = await _activityService.getActivities(
        page: event.page,
        take: event.take,
        search: event.search,
        sortBy: event.sortBy,
        sortOrder: event.sortOrder,
      );

      print('ActivityBloc: Response received - Total: ${response.total}, Records: ${response.records.length}');

      // Store all activities for client-side filtering
      _allActivities = response.records;
      _originalTotal = response.total;

      // Apply filters
      final filteredActivities = _applyClientSideFilters(_allActivities);

      print('ActivityBloc: Emitting ActivityLoaded state');
      emit(ActivityLoaded(
        activities: filteredActivities,
        total: filteredActivities.length,
        page: response.page,
        take: response.take,
        totalPages: (filteredActivities.length / response.take).ceil(),
        search: event.search,
        sortBy: event.sortBy,
        sortOrder: event.sortOrder,
        filters: _currentFilters,
      ));
    } catch (e) {
      print('ActivityBloc: Error - $e');
      emit(ActivityError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onSearchActivities(
    SearchActivities event,
    Emitter<ActivityState> emit,
  ) async {
    _currentSearch = event.query;
    _currentPage = 1; // Reset to first page on search
    add(LoadActivities(
      page: _currentPage,
      take: _currentPageSize,
      search: _currentSearch,
      sortBy: _currentSortBy,
      sortOrder: _currentSortOrder,
    ));
  }

  Future<void> _onSortActivities(
    SortActivities event,
    Emitter<ActivityState> emit,
  ) async {
    _currentSortBy = event.sortBy;
    _currentSortOrder = event.sortOrder;

    // Handle reset to default (no sort)
    if (event.sortBy.isEmpty || event.sortOrder.isEmpty) {
      _currentSortBy = 'createdAt';
      _currentSortOrder = 'desc';
    }

    // If we have cached data, sort it client-side for better performance
    if (_allActivities.isNotEmpty && state is ActivityLoaded) {
      List<ActivityModel> processedActivities = [..._allActivities];

      // Only sort if we have valid sort parameters
      if (event.sortBy.isNotEmpty && event.sortOrder.isNotEmpty) {
        processedActivities = _sortClientSide(processedActivities);
      } else {
        // Reset to original order (by createdAt desc)
        processedActivities = _sortClientSide(processedActivities);
      }

      final filteredActivities = _applyClientSideFilters(processedActivities);

      emit(ActivityLoaded(
        activities: filteredActivities,
        total: filteredActivities.length,
        page: _currentPage,
        take: _currentPageSize,
        totalPages: (filteredActivities.length / _currentPageSize).ceil(),
        search: _currentSearch,
        sortBy: event.sortBy.isEmpty ? '' : _currentSortBy,
        sortOrder: event.sortOrder.isEmpty ? '' : _currentSortOrder,
        filters: _currentFilters,
      ));
    } else {
      add(LoadActivities(
        page: _currentPage,
        take: _currentPageSize,
        search: _currentSearch,
        sortBy: _currentSortBy,
        sortOrder: _currentSortOrder,
      ));
    }
  }

  Future<void> _onChangePageSize(
    ChangePageSize event,
    Emitter<ActivityState> emit,
  ) async {
    _currentPageSize = event.pageSize;
    _currentPage = 1; // Reset to first page when changing page size
    add(LoadActivities(
      page: _currentPage,
      take: _currentPageSize,
      search: _currentSearch,
      sortBy: _currentSortBy,
      sortOrder: _currentSortOrder,
    ));
  }

  Future<void> _onChangePage(
    ChangePage event,
    Emitter<ActivityState> emit,
  ) async {
    _currentPage = event.page;
    add(LoadActivities(
      page: _currentPage,
      take: _currentPageSize,
      search: _currentSearch,
      sortBy: _currentSortBy,
      sortOrder: _currentSortOrder,
    ));
  }

  Future<void> _onDeleteActivity(
    DeleteActivity event,
    Emitter<ActivityState> emit,
  ) async {
    try {
      await _activityService.deleteActivity(event.id);
      // Reload activities after deletion
      add(LoadActivities(
        page: _currentPage,
        take: _currentPageSize,
        search: _currentSearch,
        sortBy: _currentSortBy,
        sortOrder: _currentSortOrder,
      ));
    } catch (e) {
      emit(ActivityError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onApplyFilters(
    ApplyFilters event,
    Emitter<ActivityState> emit,
  ) async {
    _currentFilters = event.filters;

    // Apply filters to cached data
    if (_allActivities.isNotEmpty && state is ActivityLoaded) {
      final filteredActivities = _applyClientSideFilters(_allActivities);

      emit(ActivityLoaded(
        activities: filteredActivities,
        total: filteredActivities.length,
        page: _currentPage,
        take: _currentPageSize,
        totalPages: (filteredActivities.length / _currentPageSize).ceil(),
        search: _currentSearch,
        sortBy: _currentSortBy,
        sortOrder: _currentSortOrder,
        filters: _currentFilters,
      ));
    } else {
      // If no cached data, reload from server
      add(LoadActivities(
        page: _currentPage,
        take: _currentPageSize,
        search: _currentSearch,
        sortBy: _currentSortBy,
        sortOrder: _currentSortOrder,
      ));
    }
  }

  List<ActivityModel> _applyClientSideFilters(List<ActivityModel> activities) {
    List<ActivityModel> filteredActivities = [...activities];

    // Apply filters as needed
    // You can add more filter types here based on requirements

    return filteredActivities;
  }

  List<ActivityModel> _sortClientSide(List<ActivityModel> activities) {
    activities.sort((a, b) {
      int comparison = 0;

      switch (_currentSortBy) {
        case 'activityType':
          comparison = a.activityType.compareTo(b.activityType);
          break;
        case 'company':
          comparison = a.company.compareTo(b.company);
          break;
        case 'inquiry':
          comparison = a.inquiry.compareTo(b.inquiry);
          break;
        case 'user':
          comparison = a.user.compareTo(b.user);
          break;
        case 'theme':
          comparison = a.theme.compareTo(b.theme);
          break;
        case 'category':
          comparison = a.category.compareTo(b.category);
          break;
        case 'createdAt':
          // Parse dates and compare
          comparison = _parseDate(a.createdAt).compareTo(_parseDate(b.createdAt));
          break;
        case 'createdBy':
          comparison = a.createdBy.compareTo(b.createdBy);
          break;
        default:
          comparison = 0;
      }

      // Apply sort order
      return _currentSortOrder == 'asc' ? comparison : -comparison;
    });

    return activities;
  }

  DateTime _parseDate(String dateStr) {
    // Parse date string in format "DD-MM-YYYY"
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
