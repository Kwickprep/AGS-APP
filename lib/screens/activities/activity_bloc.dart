import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../models/activity_model.dart';
import '../../services/activity_service.dart';

// ============================================================================
// Events
// ============================================================================

abstract class ActivityEvent {}

/// Main event to load activities with all parameters
class LoadActivities extends ActivityEvent {
  final int page;
  final int take;
  final String search;
  final String sortBy;
  final String sortOrder;
  final Map<String, dynamic> filters;

  LoadActivities({
    this.page = 1,
    this.take = 20,
    this.search = '',
    this.sortBy = 'createdAt',
    this.sortOrder = 'desc',
    this.filters = const {},
  });
}

class DeleteActivity extends ActivityEvent {
  final String id;
  DeleteActivity(this.id);
}

// ============================================================================
// States
// ============================================================================

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
  final Map<String, dynamic> filters;

  ActivityLoaded({
    required this.activities,
    required this.total,
    required this.page,
    required this.take,
    required this.totalPages,
    required this.search,
    required this.sortBy,
    required this.sortOrder,
    required this.filters,
  });

  /// Helper method to create a new state with updated parameters
  ActivityLoaded copyWith({
    List<ActivityModel>? activities,
    int? total,
    int? page,
    int? take,
    int? totalPages,
    String? search,
    String? sortBy,
    String? sortOrder,
    Map<String, dynamic>? filters,
  }) {
    return ActivityLoaded(
      activities: activities ?? this.activities,
      total: total ?? this.total,
      page: page ?? this.page,
      take: take ?? this.take,
      totalPages: totalPages ?? this.totalPages,
      search: search ?? this.search,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
      filters: filters ?? this.filters,
    );
  }
}

class ActivityError extends ActivityState {
  final String message;
  ActivityError(this.message);
}

// ============================================================================
// BLoC - Simple approach: Every change triggers API call
// ============================================================================

class ActivityBloc extends Bloc<ActivityEvent, ActivityState> {
  final ActivityService _activityService = GetIt.I<ActivityService>();

  ActivityBloc() : super(ActivityInitial()) {
    on<LoadActivities>(_onLoadActivities);
    on<DeleteActivity>(_onDeleteActivity);
  }

  /// Load activities from API with given parameters
  Future<void> _onLoadActivities(
    LoadActivities event,
    Emitter<ActivityState> emit,
  ) async {
    emit(ActivityLoading());

    try {
      final response = await _activityService.getActivities(
        page: event.page,
        take: event.take,
        search: event.search,
        sortBy: event.sortBy,
        sortOrder: event.sortOrder,
        filters: event.filters,
      );

      emit(ActivityLoaded(
        activities: response.records,
        total: response.total,
        page: response.page,
        take: response.take,
        totalPages: response.totalPages,
        search: event.search,
        sortBy: event.sortBy,
        sortOrder: event.sortOrder,
        filters: event.filters,
      ));
    } catch (e) {
      emit(ActivityError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// Delete activity and reload current page
  Future<void> _onDeleteActivity(
    DeleteActivity event,
    Emitter<ActivityState> emit,
  ) async {
    try {
      await _activityService.deleteActivity(event.id);
      
      // Reload with current parameters if we have a loaded state
      if (state is ActivityLoaded) {
        final currentState = state as ActivityLoaded;
        add(LoadActivities(
          page: currentState.page,
          take: currentState.take,
          search: currentState.search,
          sortBy: currentState.sortBy,
          sortOrder: currentState.sortOrder,
          filters: currentState.filters,
        ));
      } else {
        // Otherwise just reload with defaults
        add(LoadActivities());
      }
    } catch (e) {
      emit(ActivityError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
