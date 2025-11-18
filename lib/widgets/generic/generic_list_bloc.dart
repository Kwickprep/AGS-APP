import 'package:flutter_bloc/flutter_bloc.dart';
import 'generic_model.dart';

// ============================================================================
// Events
// ============================================================================

abstract class GenericListEvent {}

class LoadData extends GenericListEvent {
  final int page;
  final int take;
  final String search;
  final String sortBy;
  final String sortOrder;

  LoadData({
    this.page = 1,
    this.take = 20,
    this.search = '',
    this.sortBy = 'createdAt',
    this.sortOrder = 'desc',
  });
}

class SearchData extends GenericListEvent {
  final String query;
  SearchData(this.query);
}

class SortData extends GenericListEvent {
  final String sortBy;
  final String sortOrder;
  SortData(this.sortBy, this.sortOrder);
}

class ChangePageSize extends GenericListEvent {
  final int pageSize;
  ChangePageSize(this.pageSize);
}

class ChangePage extends GenericListEvent {
  final int page;
  ChangePage(this.page);
}

class DeleteData extends GenericListEvent {
  final String id;
  DeleteData(this.id);
}

class ApplyFilters extends GenericListEvent {
  final Map<String, dynamic> filters;
  ApplyFilters(this.filters);
}

// ============================================================================
// States
// ============================================================================

abstract class GenericListState {}

class GenericListInitial extends GenericListState {}

class GenericListLoading extends GenericListState {}

class GenericListLoaded<T extends GenericModel> extends GenericListState {
  final List<T> data;
  final int total;
  final int page;
  final int take;
  final int totalPages;
  final String search;
  final String sortBy;
  final String sortOrder;
  final Map<String, dynamic>? filters;

  GenericListLoaded({
    required this.data,
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

class GenericListError extends GenericListState {
  final String message;
  GenericListError(this.message);
}

// ============================================================================
// Service Interface
// ============================================================================

/// Interface that services must implement to work with GenericListBloc
abstract class GenericListService<T extends GenericModel> {
  Future<GenericResponse<T>> getData({
    required int page,
    required int take,
    required String search,
    required String sortBy,
    required String sortOrder,
  });

  Future<void> deleteData(String id);
}

// ============================================================================
// BLoC
// ============================================================================

/// Generic BLoC for list pages with searching, filtering, sorting, and pagination
class GenericListBloc<T extends GenericModel>
    extends Bloc<GenericListEvent, GenericListState> {
  final GenericListService<T> service;
  final int Function(T a, T b, String sortBy, String sortOrder) sortComparator;
  final bool Function(T model, Map<String, dynamic> filters)? filterPredicate;

  // Keep track of current parameters
  int _currentPage = 1;
  int _currentPageSize = 20;
  String _currentSearch = '';
  String _currentSortBy = 'createdAt';
  String _currentSortOrder = 'desc';
  Map<String, dynamic> _currentFilters = {};

  // Cache original data for client-side filtering/sorting
  List<T> _allData = [];
  int _originalTotal = 0;

  GenericListBloc({
    required this.service,
    required this.sortComparator,
    this.filterPredicate,
  }) : super(GenericListInitial()) {
    on<LoadData>(_onLoadData);
    on<SearchData>(_onSearchData);
    on<SortData>(_onSortData);
    on<ChangePageSize>(_onChangePageSize);
    on<ChangePage>(_onChangePage);
    on<DeleteData>(_onDeleteData);
    on<ApplyFilters>(_onApplyFilters);
  }

  Future<void> _onLoadData(
    LoadData event,
    Emitter<GenericListState> emit,
  ) async {
    emit(GenericListLoading());

    try {
      _currentPage = event.page;
      _currentPageSize = event.take;
      _currentSearch = event.search;
      _currentSortBy = event.sortBy;
      _currentSortOrder = event.sortOrder;

      final response = await service.getData(
        page: event.page,
        take: event.take,
        search: event.search,
        sortBy: event.sortBy,
        sortOrder: event.sortOrder,
      );

      // Store all data for client-side filtering
      _allData = response.records;
      _originalTotal = response.total;

      // Apply filters
      final filteredData = _applyClientSideFilters(_allData);

      emit(GenericListLoaded<T>(
        data: filteredData,
        total: filteredData.length,
        page: response.page,
        take: response.take,
        totalPages: (filteredData.length / response.take).ceil(),
        search: event.search,
        sortBy: event.sortBy,
        sortOrder: event.sortOrder,
        filters: _currentFilters,
      ));
    } catch (e) {
      emit(GenericListError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onSearchData(
    SearchData event,
    Emitter<GenericListState> emit,
  ) async {
    _currentSearch = event.query;
    _currentPage = 1; // Reset to first page on search
    add(LoadData(
      page: _currentPage,
      take: _currentPageSize,
      search: _currentSearch,
      sortBy: _currentSortBy,
      sortOrder: _currentSortOrder,
    ));
  }

  Future<void> _onSortData(
    SortData event,
    Emitter<GenericListState> emit,
  ) async {
    _currentSortBy = event.sortBy;
    _currentSortOrder = event.sortOrder;

    // Handle reset to default (no sort)
    if (event.sortBy.isEmpty || event.sortOrder.isEmpty) {
      _currentSortBy = 'createdAt';
      _currentSortOrder = 'desc';
    }

    // If we have cached data, sort it client-side for better performance
    if (_allData.isNotEmpty && state is GenericListLoaded) {
      List<T> processedData = [..._allData];

      // Sort the data
      processedData = _sortClientSide(processedData);

      // Apply filters
      final filteredData = _applyClientSideFilters(processedData);

      emit(GenericListLoaded<T>(
        data: filteredData,
        total: filteredData.length,
        page: _currentPage,
        take: _currentPageSize,
        totalPages: (filteredData.length / _currentPageSize).ceil(),
        search: _currentSearch,
        sortBy: event.sortBy.isEmpty ? '' : _currentSortBy,
        sortOrder: event.sortOrder.isEmpty ? '' : _currentSortOrder,
        filters: _currentFilters,
      ));
    } else {
      add(LoadData(
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
    Emitter<GenericListState> emit,
  ) async {
    _currentPageSize = event.pageSize;
    _currentPage = 1; // Reset to first page when changing page size
    add(LoadData(
      page: _currentPage,
      take: _currentPageSize,
      search: _currentSearch,
      sortBy: _currentSortBy,
      sortOrder: _currentSortOrder,
    ));
  }

  Future<void> _onChangePage(
    ChangePage event,
    Emitter<GenericListState> emit,
  ) async {
    _currentPage = event.page;
    add(LoadData(
      page: _currentPage,
      take: _currentPageSize,
      search: _currentSearch,
      sortBy: _currentSortBy,
      sortOrder: _currentSortOrder,
    ));
  }

  Future<void> _onDeleteData(
    DeleteData event,
    Emitter<GenericListState> emit,
  ) async {
    try {
      await service.deleteData(event.id);
      // Reload data after deletion
      add(LoadData(
        page: _currentPage,
        take: _currentPageSize,
        search: _currentSearch,
        sortBy: _currentSortBy,
        sortOrder: _currentSortOrder,
      ));
    } catch (e) {
      emit(GenericListError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onApplyFilters(
    ApplyFilters event,
    Emitter<GenericListState> emit,
  ) async {
    _currentFilters = event.filters;

    // Apply filters to cached data
    if (_allData.isNotEmpty && state is GenericListLoaded) {
      final filteredData = _applyClientSideFilters(_allData);

      emit(GenericListLoaded<T>(
        data: filteredData,
        total: filteredData.length,
        page: _currentPage,
        take: _currentPageSize,
        totalPages: (filteredData.length / _currentPageSize).ceil(),
        search: _currentSearch,
        sortBy: _currentSortBy,
        sortOrder: _currentSortOrder,
        filters: _currentFilters,
      ));
    } else {
      // If no cached data, reload from server
      add(LoadData(
        page: _currentPage,
        take: _currentPageSize,
        search: _currentSearch,
        sortBy: _currentSortBy,
        sortOrder: _currentSortOrder,
      ));
    }
  }

  List<T> _applyClientSideFilters(List<T> data) {
    if (filterPredicate == null || _currentFilters.isEmpty) {
      return data;
    }

    return data.where((model) => filterPredicate!(model, _currentFilters)).toList();
  }

  List<T> _sortClientSide(List<T> data) {
    data.sort((a, b) => sortComparator(a, b, _currentSortBy, _currentSortOrder));
    return data;
  }
}
