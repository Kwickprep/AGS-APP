import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../models/tag_model.dart';
import '../../services/tag_service.dart';

// ============================================================================
// Events
// ============================================================================

abstract class TagEvent {}

/// Main event to load tags with all parameters
class LoadTags extends TagEvent {
  final int page;
  final int take;
  final String search;
  final String sortBy;
  final String sortOrder;
  final Map<String, dynamic> filters;

  LoadTags({
    this.page = 1,
    this.take = 20,
    this.search = '',
    this.sortBy = 'createdAt',
    this.sortOrder = 'desc',
    this.filters = const {},
  });
}

class DeleteTag extends TagEvent {
  final String id;
  DeleteTag(this.id);
}

// ============================================================================
// States
// ============================================================================

abstract class TagState {}

class TagInitial extends TagState {}

class TagLoading extends TagState {}

class TagLoaded extends TagState {
  final List<TagModel> tags;
  final int total;
  final int page;
  final int take;
  final int totalPages;
  final String search;
  final String sortBy;
  final String sortOrder;
  final Map<String, dynamic> filters;

  TagLoaded({
    required this.tags,
    required this.total,
    required this.page,
    required this.take,
    required this.totalPages,
    required this.search,
    required this.sortBy,
    required this.sortOrder,
    required this.filters,
  });

  TagLoaded copyWith({
    List<TagModel>? tags,
    int? total,
    int? page,
    int? take,
    int? totalPages,
    String? search,
    String? sortBy,
    String? sortOrder,
    Map<String, dynamic>? filters,
  }) {
    return TagLoaded(
      tags: tags ?? this.tags,
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

class TagError extends TagState {
  final String message;
  TagError(this.message);
}

// ============================================================================
// BLoC - Simple approach: Every change triggers API call
// ============================================================================

class TagBloc extends Bloc<TagEvent, TagState> {
  final TagService _tagService = GetIt.I<TagService>();

  TagBloc() : super(TagInitial()) {
    on<LoadTags>(_onLoadTags);
    on<DeleteTag>(_onDeleteTag);
  }

  /// Load tags from API with given parameters
  Future<void> _onLoadTags(
    LoadTags event,
    Emitter<TagState> emit,
  ) async {
    emit(TagLoading());

    try {
      final response = await _tagService.getTags(
        page: event.page,
        take: event.take,
        search: event.search,
        sortBy: event.sortBy,
        sortOrder: event.sortOrder,
        filters: event.filters,
      );

      emit(TagLoaded(
        tags: response.records,
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
      emit(TagError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// Delete tag and reload current page
  Future<void> _onDeleteTag(
    DeleteTag event,
    Emitter<TagState> emit,
  ) async {
    try {
      await _tagService.deleteTag(event.id);
      
      // Reload with current parameters if we have a loaded state
      if (state is TagLoaded) {
        final currentState = state as TagLoaded;
        add(LoadTags(
          page: currentState.page,
          take: currentState.take,
          search: currentState.search,
          sortBy: currentState.sortBy,
          sortOrder: currentState.sortOrder,
          filters: currentState.filters,
        ));
      } else {
        // Otherwise just reload with defaults
        add(LoadTags());
      }
    } catch (e) {
      emit(TagError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
