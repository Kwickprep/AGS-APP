import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../models/brand_model.dart';
import '../../services/brand_service.dart';

// Events
abstract class BrandEvent {}

class LoadBrands extends BrandEvent {
  final int page;
  final int take;
  final String search;
  final String sortBy;
  final String sortOrder;

  LoadBrands({
    this.page = 1,
    this.take = 20,
    this.search = '',
    this.sortBy = 'createdAt',
    this.sortOrder = 'desc',
  });
}

class SearchBrands extends BrandEvent {
  final String query;
  SearchBrands(this.query);
}

class SortBrands extends BrandEvent {
  final String sortBy;
  final String sortOrder;
  SortBrands(this.sortBy, this.sortOrder);
}

class ChangePageSize extends BrandEvent {
  final int pageSize;
  ChangePageSize(this.pageSize);
}

class ChangePage extends BrandEvent {
  final int page;
  ChangePage(this.page);
}

class DeleteBrand extends BrandEvent {
  final String id;
  DeleteBrand(this.id);
}

class ApplyFilters extends BrandEvent {
  final Map<String, dynamic> filters;
  ApplyFilters(this.filters);
}

// States
abstract class BrandState {}

class BrandInitial extends BrandState {}

class BrandLoading extends BrandState {}

class BrandLoaded extends BrandState {
  final List<BrandModel> brands;
  final int total;
  final int page;
  final int take;
  final int totalPages;
  final String search;
  final String sortBy;
  final String sortOrder;
  final Map<String, dynamic>? filters;

  BrandLoaded({
    required this.brands,
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

class BrandError extends BrandState {
  final String message;
  BrandError(this.message);
}

// Bloc
class BrandBloc extends Bloc<BrandEvent, BrandState> {
  final BrandService _brandService = GetIt.I<BrandService>();

  // Keep track of current parameters
  int _currentPage = 1;
  int _currentPageSize = 20;
  String _currentSearch = '';
  String _currentSortBy = 'createdAt';
  String _currentSortOrder = 'desc';
  Map<String, dynamic> _currentFilters = {};

  // Cache original data for client-side filtering
  List<BrandModel> _allBrands = [];
  int _originalTotal = 0;

  BrandBloc() : super(BrandInitial()) {
    on<LoadBrands>(_onLoadBrands);
    on<SearchBrands>(_onSearchBrands);
    on<SortBrands>(_onSortBrands);
    on<ChangePageSize>(_onChangePageSize);
    on<ChangePage>(_onChangePage);
    on<DeleteBrand>(_onDeleteBrand);
    on<ApplyFilters>(_onApplyFilters);
  }

  Future<void> _onLoadBrands(
      LoadBrands event,
      Emitter<BrandState> emit,
      ) async {
    emit(BrandLoading());

    try {
      _currentPage = event.page;
      _currentPageSize = event.take;
      _currentSearch = event.search;
      _currentSortBy = event.sortBy;
      _currentSortOrder = event.sortOrder;

      final response = await _brandService.getBrands(
        page: event.page,
        take: event.take,
        search: event.search,
        sortBy: event.sortBy,
        sortOrder: event.sortOrder,
      );

      // Store all brands for client-side filtering
      _allBrands = response.records;
      _originalTotal = response.total;

      // Apply filters
      final filteredBrands = _applyClientSideFilters(_allBrands);

      emit(BrandLoaded(
        brands: filteredBrands,
        total: filteredBrands.length,
        page: response.page,
        take: response.take,
        totalPages: (filteredBrands.length / response.take).ceil(),
        search: event.search,
        sortBy: event.sortBy,
        sortOrder: event.sortOrder,
        filters: _currentFilters,
      ));
    } catch (e) {
      emit(BrandError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onSearchBrands(
      SearchBrands event,
      Emitter<BrandState> emit,
      ) async {
    _currentSearch = event.query;
    _currentPage = 1; // Reset to first page on search
    add(LoadBrands(
      page: _currentPage,
      take: _currentPageSize,
      search: _currentSearch,
      sortBy: _currentSortBy,
      sortOrder: _currentSortOrder,
    ));
  }

  Future<void> _onSortBrands(
      SortBrands event,
      Emitter<BrandState> emit,
      ) async {
    _currentSortBy = event.sortBy;
    _currentSortOrder = event.sortOrder;

    // Handle reset to default (no sort)
    if (event.sortBy.isEmpty || event.sortOrder.isEmpty) {
      _currentSortBy = 'createdAt';
      _currentSortOrder = 'desc';
    }

    // If we have cached data, sort it client-side for better performance
    if (_allBrands.isNotEmpty && state is BrandLoaded) {
      List<BrandModel> processedBrands = [..._allBrands];

      // Only sort if we have valid sort parameters
      if (event.sortBy.isNotEmpty && event.sortOrder.isNotEmpty) {
        processedBrands = _sortClientSide(processedBrands);
      } else {
        // Reset to original order (by createdAt desc)
        processedBrands = _sortClientSide(processedBrands);
      }

      final filteredBrands = _applyClientSideFilters(processedBrands);

      emit(BrandLoaded(
        brands: filteredBrands,
        total: filteredBrands.length,
        page: _currentPage,
        take: _currentPageSize,
        totalPages: (filteredBrands.length / _currentPageSize).ceil(),
        search: _currentSearch,
        sortBy: event.sortBy.isEmpty ? '' : _currentSortBy,
        sortOrder: event.sortOrder.isEmpty ? '' : _currentSortOrder,
        filters: _currentFilters,
      ));
    } else {
      add(LoadBrands(
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
      Emitter<BrandState> emit,
      ) async {
    _currentPageSize = event.pageSize;
    _currentPage = 1; // Reset to first page when changing page size
    add(LoadBrands(
      page: _currentPage,
      take: _currentPageSize,
      search: _currentSearch,
      sortBy: _currentSortBy,
      sortOrder: _currentSortOrder,
    ));
  }

  Future<void> _onChangePage(
      ChangePage event,
      Emitter<BrandState> emit,
      ) async {
    _currentPage = event.page;
    add(LoadBrands(
      page: _currentPage,
      take: _currentPageSize,
      search: _currentSearch,
      sortBy: _currentSortBy,
      sortOrder: _currentSortOrder,
    ));
  }

  Future<void> _onDeleteBrand(
      DeleteBrand event,
      Emitter<BrandState> emit,
      ) async {
    try {
      await _brandService.deleteBrand(event.id);
      // Reload brands after deletion
      add(LoadBrands(
        page: _currentPage,
        take: _currentPageSize,
        search: _currentSearch,
        sortBy: _currentSortBy,
        sortOrder: _currentSortOrder,
      ));
    } catch (e) {
      emit(BrandError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onApplyFilters(
      ApplyFilters event,
      Emitter<BrandState> emit,
      ) async {
    _currentFilters = event.filters;

    // Apply filters to cached data
    if (_allBrands.isNotEmpty && state is BrandLoaded) {
      final filteredBrands = _applyClientSideFilters(_allBrands);

      emit(BrandLoaded(
        brands: filteredBrands,
        total: filteredBrands.length,
        page: _currentPage,
        take: _currentPageSize,
        totalPages: (filteredBrands.length / _currentPageSize).ceil(),
        search: _currentSearch,
        sortBy: _currentSortBy,
        sortOrder: _currentSortOrder,
        filters: _currentFilters,
      ));
    } else {
      // If no cached data, reload from server
      add(LoadBrands(
        page: _currentPage,
        take: _currentPageSize,
        search: _currentSearch,
        sortBy: _currentSortBy,
        sortOrder: _currentSortOrder,
      ));
    }
  }

  List<BrandModel> _applyClientSideFilters(List<BrandModel> brands) {
    List<BrandModel> filteredBrands = [...brands];

    // Apply status filter
    if (_currentFilters.containsKey('status')) {
      final statusFilter = _currentFilters['status'];
      if (statusFilter == 'active') {
        filteredBrands = filteredBrands.where((brand) => brand.isActive).toList();
      } else if (statusFilter == 'inactive') {
        filteredBrands = filteredBrands.where((brand) => !brand.isActive).toList();
      }
    }

    // Apply other filters as needed
    // You can add more filter types here

    return filteredBrands;
  }

  List<BrandModel> _sortClientSide(List<BrandModel> brands) {
    brands.sort((a, b) {
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

    return brands;
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