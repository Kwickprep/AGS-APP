import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../models/activity_type_model.dart';
import '../../services/activity_type_service.dart';

// ============================================================================
// Events
// ============================================================================

abstract class ActivityTypeEvent {}

/// Main event to load activity types with all parameters
class LoadActivityTypes extends ActivityTypeEvent {
  final int page;
  final int take;
  final String search;
  final String sortBy;
  final String sortOrder;
  final Map<String, dynamic> filters;

  LoadActivityTypes({
    this.page = 1,
    this.take = 20,
    this.search = '',
    this.sortBy = 'createdAt',
    this.sortOrder = 'desc',
    this.filters = const {},
  });
}

class DeleteActivityType extends ActivityTypeEvent {
  final String id;
  DeleteActivityType(this.id);
}

// ============================================================================
// States
// ============================================================================

abstract class ActivityTypeState {}

class ActivityTypeInitial extends ActivityTypeState {}

class ActivityTypeLoading extends ActivityTypeState {}

class ActivityTypeLoaded extends ActivityTypeState {
  final List<ActivityTypeModel> activityTypes;
  final int total;
  final int page;
  final int take;
  final int totalPages;
  final String search;
  final String sortBy;
  final String sortOrder;
  final Map<String, dynamic> filters;

  ActivityTypeLoaded({
    required this.activityTypes,
    required this.total,
    required this.page,
    required this.take,
    required this.totalPages,
    required this.search,
    required this.sortBy,
    required this.sortOrder,
    required this.filters,
  });

  ActivityTypeLoaded copyWith({
    List<ActivityTypeModel>? activityTypes,
    int? total,
    int? page,
    int? take,
    int? totalPages,
    String? search,
    String? sortBy,
    String? sortOrder,
    Map<String, dynamic>? filters,
  }) {
    return ActivityTypeLoaded(
      activityTypes: activityTypes ?? this.activityTypes,
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

class ActivityTypeError extends ActivityTypeState {
  final String message;
  ActivityTypeError(this.message);
}

// ============================================================================
// BLoC - Simple approach: Every change triggers API call
// ============================================================================

class ActivityTypeBloc extends Bloc<ActivityTypeEvent, ActivityTypeState> {
  final ActivityTypeService _activityTypeService = GetIt.I<ActivityTypeService>();

  ActivityTypeBloc() : super(ActivityTypeInitial()) {
    on<LoadActivityTypes>(_onLoadActivityTypes);
    on<DeleteActivityType>(_onDeleteActivityType);
  }

  /// Load activity types from API with given parameters
  Future<void> _onLoadActivityTypes(
    LoadActivityTypes event,
    Emitter<ActivityTypeState> emit,
  ) async {
    emit(ActivityTypeLoading());

    try {
      final response = await _activityTypeService.getActivityTypes(
        page: event.page,
        take: event.take,
        search: event.search,
        sortBy: event.sortBy,
        sortOrder: event.sortOrder,
        filters: event.filters,
      );

      emit(ActivityTypeLoaded(
        activityTypes: response.records,
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
      emit(ActivityTypeError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// Delete activity type and reload current page
  Future<void> _onDeleteActivityType(
    DeleteActivityType event,
    Emitter<ActivityTypeState> emit,
  ) async {
    try {
      await _activityTypeService.deleteActivityType(event.id);

      // Reload with current parameters if we have a loaded state
      if (state is ActivityTypeLoaded) {
        final currentState = state as ActivityTypeLoaded;
        add(LoadActivityTypes(
          page: currentState.page,
          take: currentState.take,
          search: currentState.search,
          sortBy: currentState.sortBy,
          sortOrder: currentState.sortOrder,
          filters: currentState.filters,
        ));
      } else {
        // Otherwise just reload with defaults
        add(LoadActivityTypes());
      }
    } catch (e) {
      emit(ActivityTypeError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
