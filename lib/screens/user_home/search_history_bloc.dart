import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../models/activity_model.dart';
import '../../services/activity_service.dart';

// ============================================================================
// Events
// ============================================================================

abstract class SearchHistoryEvent {}

class LoadSearchHistory extends SearchHistoryEvent {}

class RefreshSearchHistory extends SearchHistoryEvent {}

class LoadMoreSearchHistory extends SearchHistoryEvent {}

// ============================================================================
// States
// ============================================================================

abstract class SearchHistoryState {}

class SearchHistoryInitial extends SearchHistoryState {}

class SearchHistoryLoading extends SearchHistoryState {}

class SearchHistoryLoaded extends SearchHistoryState {
  final List<ActivityModel> activities;
  final int total;
  final int page;
  final bool hasMore;

  SearchHistoryLoaded({
    required this.activities,
    required this.total,
    required this.page,
    required this.hasMore,
  });
}

class SearchHistoryError extends SearchHistoryState {
  final String message;
  SearchHistoryError({required this.message});
}

// ============================================================================
// BLoC
// ============================================================================

class SearchHistoryBloc extends Bloc<SearchHistoryEvent, SearchHistoryState> {
  final ActivityService _activityService = GetIt.I<ActivityService>();

  static const String _productSearchActivityTypeId = '68e77f49728d6edb593273cc';
  static const int _pageSize = 15;

  SearchHistoryBloc() : super(SearchHistoryInitial()) {
    on<LoadSearchHistory>(_onLoadSearchHistory);
    on<RefreshSearchHistory>(_onRefreshSearchHistory);
    on<LoadMoreSearchHistory>(_onLoadMoreSearchHistory);
  }

  Future<void> _onLoadSearchHistory(
    LoadSearchHistory event,
    Emitter<SearchHistoryState> emit,
  ) async {
    emit(SearchHistoryLoading());
    await _fetchPage(1, emit);
  }

  Future<void> _onRefreshSearchHistory(
    RefreshSearchHistory event,
    Emitter<SearchHistoryState> emit,
  ) async {
    await _fetchPage(1, emit);
  }

  Future<void> _onLoadMoreSearchHistory(
    LoadMoreSearchHistory event,
    Emitter<SearchHistoryState> emit,
  ) async {
    if (state is! SearchHistoryLoaded) return;
    final currentState = state as SearchHistoryLoaded;
    if (!currentState.hasMore) return;

    final nextPage = currentState.page + 1;

    try {
      final response = await _activityService.getActivities(
        page: nextPage,
        take: _pageSize,
        sortBy: 'createdAt',
        sortOrder: 'desc',
        filters: {'activityTypeId': _productSearchActivityTypeId},
      );

      final allActivities = [...currentState.activities, ...response.records];

      emit(SearchHistoryLoaded(
        activities: allActivities,
        total: response.total,
        page: nextPage,
        hasMore: allActivities.length < response.total,
      ));
    } catch (e) {
      // Keep current data on pagination error
      emit(currentState);
    }
  }

  Future<void> _fetchPage(int page, Emitter<SearchHistoryState> emit) async {
    try {
      final response = await _activityService.getActivities(
        page: page,
        take: _pageSize,
        sortBy: 'createdAt',
        sortOrder: 'desc',
        filters: {'activityTypeId': _productSearchActivityTypeId},
      );

      emit(SearchHistoryLoaded(
        activities: response.records,
        total: response.total,
        page: page,
        hasMore: response.records.length < response.total,
      ));
    } catch (e) {
      emit(SearchHistoryError(
        message: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }
}
