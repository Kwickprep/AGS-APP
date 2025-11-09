import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../models/tag_model.dart';
import '../../services/tag_service.dart';

// Events
abstract class TagEvent {}

class LoadTags extends TagEvent {
  final int page;
  final int take;
  final String search;
  final String sortBy;
  final String sortOrder;

  LoadTags({
    this.page = 1,
    this.take = 20,
    this.search = '',
    this.sortBy = 'createdAt',
    this.sortOrder = 'desc',
  });
}

class SearchTags extends TagEvent {
  final String query;
  SearchTags(this.query);
}

class SortTags extends TagEvent {
  final String sortBy;
  final String sortOrder;
  SortTags(this.sortBy, this.sortOrder);
}

class ChangePageSize extends TagEvent {
  final int pageSize;
  ChangePageSize(this.pageSize);
}

class ChangePage extends TagEvent {
  final int page;
  ChangePage(this.page);
}

class DeleteTag extends TagEvent {
  final String id;
  DeleteTag(this.id);
}

class ApplyFilters extends TagEvent {
  final Map<String, dynamic> filters;
  ApplyFilters(this.filters);
}

// States
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
  final Map<String, dynamic>? filters;

  TagLoaded({
    required this.tags,
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

class TagError extends TagState {
  final String message;
  TagError(this.message);
}

// Bloc
class TagBloc extends Bloc<TagEvent, TagState> {
  final TagService _tagService = GetIt.I<TagService>();

  // Keep track of current parameters
  int _currentPage = 1;
  int _currentPageSize = 20;
  String _currentSearch = '';
  String _currentSortBy = 'createdAt';
  String _currentSortOrder = 'desc';
  Map<String, dynamic> _currentFilters = {};

  // Cache original data for client-side filtering
  List<TagModel> _allTags = [];
  int _originalTotal = 0;

  TagBloc() : super(TagInitial()) {
    on<LoadTags>(_onLoadTags);
    on<SearchTags>(_onSearchTags);
    on<SortTags>(_onSortTags);
    on<ChangePageSize>(_onChangePageSize);
    on<ChangePage>(_onChangePage);
    on<DeleteTag>(_onDeleteTag);
    on<ApplyFilters>(_onApplyFilters);
  }

  Future<void> _onLoadTags(
    LoadTags event,
    Emitter<TagState> emit,
  ) async {
    emit(TagLoading());

    try {
      _currentPage = event.page;
      _currentPageSize = event.take;
      _currentSearch = event.search;
      _currentSortBy = event.sortBy;
      _currentSortOrder = event.sortOrder;

      final response = await _tagService.getTags(
        page: event.page,
        take: event.take,
        search: event.search,
        sortBy: event.sortBy,
        sortOrder: event.sortOrder,
      );

      // Store all tags for client-side filtering
      _allTags = response.records;
      _originalTotal = response.total;

      // Apply filters
      final filteredTags = _applyClientSideFilters(_allTags);

      emit(TagLoaded(
        tags: filteredTags,
        total: filteredTags.length,
        page: response.page,
        take: response.take,
        totalPages: (filteredTags.length / response.take).ceil(),
        search: event.search,
        sortBy: event.sortBy,
        sortOrder: event.sortOrder,
        filters: _currentFilters,
      ));
    } catch (e) {
      emit(TagError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onSearchTags(
    SearchTags event,
    Emitter<TagState> emit,
  ) async {
    _currentSearch = event.query;
    _currentPage = 1; // Reset to first page on search
    add(LoadTags(
      page: _currentPage,
      take: _currentPageSize,
      search: _currentSearch,
      sortBy: _currentSortBy,
      sortOrder: _currentSortOrder,
    ));
  }

  Future<void> _onSortTags(
    SortTags event,
    Emitter<TagState> emit,
  ) async {
    _currentSortBy = event.sortBy;
    _currentSortOrder = event.sortOrder;

    // If we have cached data, sort it client-side for better performance
    if (_allTags.isNotEmpty && state is TagLoaded) {
      final sortedTags = _sortClientSide([..._allTags]);
      final filteredTags = _applyClientSideFilters(sortedTags);

      emit(TagLoaded(
        tags: filteredTags,
        total: filteredTags.length,
        page: _currentPage,
        take: _currentPageSize,
        totalPages: (filteredTags.length / _currentPageSize).ceil(),
        search: _currentSearch,
        sortBy: _currentSortBy,
        sortOrder: _currentSortOrder,
        filters: _currentFilters,
      ));
    } else {
      add(LoadTags(
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
    Emitter<TagState> emit,
  ) async {
    _currentPageSize = event.pageSize;
    _currentPage = 1; // Reset to first page when changing page size
    add(LoadTags(
      page: _currentPage,
      take: _currentPageSize,
      search: _currentSearch,
      sortBy: _currentSortBy,
      sortOrder: _currentSortOrder,
    ));
  }

  Future<void> _onChangePage(
    ChangePage event,
    Emitter<TagState> emit,
  ) async {
    _currentPage = event.page;
    add(LoadTags(
      page: _currentPage,
      take: _currentPageSize,
      search: _currentSearch,
      sortBy: _currentSortBy,
      sortOrder: _currentSortOrder,
    ));
  }

  Future<void> _onDeleteTag(
    DeleteTag event,
    Emitter<TagState> emit,
  ) async {
    try {
      await _tagService.deleteTag(event.id);
      // Reload tags after deletion
      add(LoadTags(
        page: _currentPage,
        take: _currentPageSize,
        search: _currentSearch,
        sortBy: _currentSortBy,
        sortOrder: _currentSortOrder,
      ));
    } catch (e) {
      emit(TagError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onApplyFilters(
    ApplyFilters event,
    Emitter<TagState> emit,
  ) async {
    _currentFilters = event.filters;

    // Apply filters to cached data
    if (_allTags.isNotEmpty && state is TagLoaded) {
      final filteredTags = _applyClientSideFilters(_allTags);

      emit(TagLoaded(
        tags: filteredTags,
        total: filteredTags.length,
        page: _currentPage,
        take: _currentPageSize,
        totalPages: (filteredTags.length / _currentPageSize).ceil(),
        search: _currentSearch,
        sortBy: _currentSortBy,
        sortOrder: _currentSortOrder,
        filters: _currentFilters,
      ));
    } else {
      // If no cached data, reload from server
      add(LoadTags(
        page: _currentPage,
        take: _currentPageSize,
        search: _currentSearch,
        sortBy: _currentSortBy,
        sortOrder: _currentSortOrder,
      ));
    }
  }

  List<TagModel> _applyClientSideFilters(List<TagModel> tags) {
    List<TagModel> filteredTags = [...tags];

    // Apply status filter
    if (_currentFilters.containsKey('status')) {
      final statusFilter = _currentFilters['status'];
      if (statusFilter == 'active') {
        filteredTags = filteredTags.where((tag) => tag.isActive).toList();
      } else if (statusFilter == 'inactive') {
        filteredTags = filteredTags.where((tag) => !tag.isActive).toList();
      }
    }

    // Apply other filters as needed
    // You can add more filter types here

    return filteredTags;
  }

  List<TagModel> _sortClientSide(List<TagModel> tags) {
    tags.sort((a, b) {
      int comparison = 0;

      switch (_currentSortBy) {
        case 'name':
          comparison = a.name.compareTo(b.name);
          break;
        case 'createdAt':
          // Parse dates and compare
          comparison = _parseDate(a.createdAt).compareTo(_parseDate(b.createdAt));
          break;
        case 'isActive':
          comparison = a.isActive == b.isActive ? 0 : (a.isActive ? 1 : -1);
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

    return tags;
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
