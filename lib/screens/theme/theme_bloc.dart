import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../models/theme_model.dart';
import '../../services/theme_service.dart';

// Events
abstract class ThemeEvent {}

class LoadThemes extends ThemeEvent {
  final int page;
  final int take;
  final String search;
  final String sortBy;
  final String sortOrder;

  LoadThemes({
    this.page = 1,
    this.take = 20,
    this.search = '',
    this.sortBy = 'createdAt',
    this.sortOrder = 'desc',
  });
}

class SearchThemes extends ThemeEvent {
  final String query;
  SearchThemes(this.query);
}

class SortThemes extends ThemeEvent {
  final String sortBy;
  final String sortOrder;
  SortThemes(this.sortBy, this.sortOrder);
}

class ChangePageSize extends ThemeEvent {
  final int pageSize;
  ChangePageSize(this.pageSize);
}

class ChangePage extends ThemeEvent {
  final int page;
  ChangePage(this.page);
}

class DeleteTheme extends ThemeEvent {
  final String id;
  DeleteTheme(this.id);
}

class ApplyFilters extends ThemeEvent {
  final Map<String, dynamic> filters;
  ApplyFilters(this.filters);
}

// States
abstract class ThemeState {}

class ThemeInitial extends ThemeState {}

class ThemeLoading extends ThemeState {}

class ThemeLoaded extends ThemeState {
  final List<ThemeModel> themes;
  final int total;
  final int page;
  final int take;
  final int totalPages;
  final String search;
  final String sortBy;
  final String sortOrder;
  final Map<String, dynamic>? filters;

  ThemeLoaded({
    required this.themes,
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

class ThemeError extends ThemeState {
  final String message;
  ThemeError(this.message);
}

// Bloc
class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  final ThemeService _themeService = GetIt.I<ThemeService>();

  // Keep track of current parameters
  int _currentPage = 1;
  int _currentPageSize = 20;
  String _currentSearch = '';
  String _currentSortBy = 'createdAt';
  String _currentSortOrder = 'desc';
  Map<String, dynamic> _currentFilters = {};

  // Cache original data for client-side filtering
  List<ThemeModel> _allThemes = [];
  int _originalTotal = 0;

  ThemeBloc() : super(ThemeInitial()) {
    on<LoadThemes>(_onLoadThemes);
    on<SearchThemes>(_onSearchThemes);
    on<SortThemes>(_onSortThemes);
    on<ChangePageSize>(_onChangePageSize);
    on<ChangePage>(_onChangePage);
    on<DeleteTheme>(_onDeleteTheme);
    on<ApplyFilters>(_onApplyFilters);
  }

  Future<void> _onLoadThemes(
      LoadThemes event,
      Emitter<ThemeState> emit,
      ) async {
    emit(ThemeLoading());

    try {
      _currentPage = event.page;
      _currentPageSize = event.take;
      _currentSearch = event.search;
      _currentSortBy = event.sortBy;
      _currentSortOrder = event.sortOrder;

      final response = await _themeService.getThemes(
        page: event.page,
        take: event.take,
        search: event.search,
        sortBy: event.sortBy,
        sortOrder: event.sortOrder,
      );

      // Store all themes for client-side filtering
      _allThemes = response.records;
      _originalTotal = response.total;

      // Apply filters
      final filteredThemes = _applyClientSideFilters(_allThemes);

      emit(ThemeLoaded(
        themes: filteredThemes,
        total: filteredThemes.length,
        page: response.page,
        take: response.take,
        totalPages: (filteredThemes.length / response.take).ceil(),
        search: event.search,
        sortBy: event.sortBy,
        sortOrder: event.sortOrder,
        filters: _currentFilters,
      ));
    } catch (e) {
      emit(ThemeError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onSearchThemes(
      SearchThemes event,
      Emitter<ThemeState> emit,
      ) async {
    _currentSearch = event.query;
    _currentPage = 1; // Reset to first page on search
    add(LoadThemes(
      page: _currentPage,
      take: _currentPageSize,
      search: _currentSearch,
      sortBy: _currentSortBy,
      sortOrder: _currentSortOrder,
    ));
  }

  Future<void> _onSortThemes(
      SortThemes event,
      Emitter<ThemeState> emit,
      ) async {
    _currentSortBy = event.sortBy;
    _currentSortOrder = event.sortOrder;

    // If we have cached data, sort it client-side for better performance
    if (_allThemes.isNotEmpty && state is ThemeLoaded) {
      final sortedThemes = _sortClientSide([..._allThemes]);
      final filteredThemes = _applyClientSideFilters(sortedThemes);

      emit(ThemeLoaded(
        themes: filteredThemes,
        total: filteredThemes.length,
        page: _currentPage,
        take: _currentPageSize,
        totalPages: (filteredThemes.length / _currentPageSize).ceil(),
        search: _currentSearch,
        sortBy: _currentSortBy,
        sortOrder: _currentSortOrder,
        filters: _currentFilters,
      ));
    } else {
      add(LoadThemes(
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
      Emitter<ThemeState> emit,
      ) async {
    _currentPageSize = event.pageSize;
    _currentPage = 1; // Reset to first page when changing page size
    add(LoadThemes(
      page: _currentPage,
      take: _currentPageSize,
      search: _currentSearch,
      sortBy: _currentSortBy,
      sortOrder: _currentSortOrder,
    ));
  }

  Future<void> _onChangePage(
      ChangePage event,
      Emitter<ThemeState> emit,
      ) async {
    _currentPage = event.page;
    add(LoadThemes(
      page: _currentPage,
      take: _currentPageSize,
      search: _currentSearch,

      sortBy: _currentSortBy,
      sortOrder: _currentSortOrder,
    ));
  }

  Future<void> _onDeleteTheme(
      DeleteTheme event,
      Emitter<ThemeState> emit,
      ) async {
    try {
      await _themeService.deleteTheme(event.id);
      // Reload themes after deletion
      add(LoadThemes(
        page: _currentPage,
        take: _currentPageSize,
        search: _currentSearch,
        sortBy: _currentSortBy,
        sortOrder: _currentSortOrder,
      ));
    } catch (e) {
      emit(ThemeError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onApplyFilters(
      ApplyFilters event,
      Emitter<ThemeState> emit,
      ) async {
    _currentFilters = event.filters;

    // Apply filters to cached data
    if (_allThemes.isNotEmpty && state is ThemeLoaded) {
      final filteredThemes = _applyClientSideFilters(_allThemes);

      emit(ThemeLoaded(
        themes: filteredThemes,
        total: filteredThemes.length,
        page: _currentPage,
        take: _currentPageSize,
        totalPages: (filteredThemes.length / _currentPageSize).ceil(),
        search: _currentSearch,
        sortBy: _currentSortBy,
        sortOrder: _currentSortOrder,
        filters: _currentFilters,
      ));
    } else {
      // If no cached data, reload from server
      add(LoadThemes(
        page: _currentPage,
        take: _currentPageSize,
        search: _currentSearch,
        sortBy: _currentSortBy,
        sortOrder: _currentSortOrder,
      ));
    }
  }

  List<ThemeModel> _applyClientSideFilters(List<ThemeModel> themes) {
    List<ThemeModel> filteredThemes = [...themes];

    // Apply status filter
    if (_currentFilters.containsKey('status')) {
      final statusFilter = _currentFilters['status'];
      if (statusFilter == 'active') {
        filteredThemes = filteredThemes.where((theme) => theme.isActive).toList();
      } else if (statusFilter == 'inactive') {
        filteredThemes = filteredThemes.where((theme) => !theme.isActive).toList();
      }
    }

    // Apply other filters as needed
    // You can add more filter types here

    return filteredThemes;
  }

  List<ThemeModel> _sortClientSide(List<ThemeModel> themes) {
    themes.sort((a, b) {
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

    return themes;
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