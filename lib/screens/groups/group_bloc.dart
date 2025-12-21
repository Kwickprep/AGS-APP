import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../models/group_model.dart';
import '../../services/group_service.dart';

// ============================================================================
// Events
// ============================================================================

abstract class GroupEvent {}

/// Main event to load groups with all parameters
class LoadGroups extends GroupEvent {
  final int page;
  final int take;
  final String search;
  final String sortBy;
  final String sortOrder;
  final Map<String, dynamic> filters;

  LoadGroups({
    this.page = 1,
    this.take = 20,
    this.search = '',
    this.sortBy = 'createdAt',
    this.sortOrder = 'desc',
    this.filters = const {},
  });
}

class DeleteGroup extends GroupEvent {
  final String id;
  DeleteGroup(this.id);
}

// ============================================================================
// States
// ============================================================================

abstract class GroupState {}

class GroupInitial extends GroupState {}

class GroupLoading extends GroupState {}

class GroupLoaded extends GroupState {
  final List<GroupModel> groups;
  final int total;
  final int page;
  final int take;
  final int totalPages;
  final String search;
  final String sortBy;
  final String sortOrder;
  final Map<String, dynamic> filters;

  GroupLoaded({
    required this.groups,
    required this.total,
    required this.page,
    required this.take,
    required this.totalPages,
    required this.search,
    required this.sortBy,
    required this.sortOrder,
    required this.filters,
  });

  GroupLoaded copyWith({
    List<GroupModel>? groups,
    int? total,
    int? page,
    int? take,
    int? totalPages,
    String? search,
    String? sortBy,
    String? sortOrder,
    Map<String, dynamic>? filters,
  }) {
    return GroupLoaded(
      groups: groups ?? this.groups,
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

class GroupError extends GroupState {
  final String message;
  GroupError(this.message);
}

// ============================================================================
// BLoC - Simple approach: Every change triggers API call
// ============================================================================

class GroupBloc extends Bloc<GroupEvent, GroupState> {
  final GroupService _groupService = GetIt.I<GroupService>();

  GroupBloc() : super(GroupInitial()) {
    on<LoadGroups>(_onLoadGroups);
    on<DeleteGroup>(_onDeleteGroup);
  }

  /// Load groups from API with given parameters
  Future<void> _onLoadGroups(
    LoadGroups event,
    Emitter<GroupState> emit,
  ) async {
    emit(GroupLoading());

    try {
      final response = await _groupService.getGroups(
        page: event.page,
        take: event.take,
        search: event.search,
        sortBy: event.sortBy,
        sortOrder: event.sortOrder,
        filters: event.filters,
      );

      emit(GroupLoaded(
        groups: response.records,
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
      emit(GroupError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// Delete group and reload current page
  Future<void> _onDeleteGroup(
    DeleteGroup event,
    Emitter<GroupState> emit,
  ) async {
    try {
      await _groupService.deleteGroup(event.id);
      
      // Reload with current parameters if we have a loaded state
      if (state is GroupLoaded) {
        final currentState = state as GroupLoaded;
        add(LoadGroups(
          page: currentState.page,
          take: currentState.take,
          search: currentState.search,
          sortBy: currentState.sortBy,
          sortOrder: currentState.sortOrder,
          filters: currentState.filters,
        ));
      } else {
        // Otherwise just reload with defaults
        add(LoadGroups());
      }
    } catch (e) {
      emit(GroupError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
