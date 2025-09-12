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

  BrandLoaded({
    required this.brands,
    required this.total,
    required this.page,
    required this.take,
    required this.totalPages,
    required this.search,
    required this.sortBy,
    required this.sortOrder,
  });
}

class BrandError extends BrandState {
  final String message;
  BrandError(this.message);
}

// Bloc
class BrandBloc extends Bloc<BrandEvent, BrandState> {
  final BrandService _brandService = GetIt.I<BrandService>();

  int _currentPage = 1;
  int _currentPageSize = 20;
  String _currentSearch = '';
  String _currentSortBy = 'createdAt';
  String _currentSortOrder = 'desc';

  BrandBloc() : super(BrandInitial()) {
    on<LoadBrands>(_onLoadBrands);
    on<SearchBrands>(_onSearchBrands);
    on<SortBrands>(_onSortBrands);
    on<ChangePageSize>(_onChangePageSize);
    on<ChangePage>(_onChangePage);
    on<DeleteBrand>(_onDeleteBrand);
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

      emit(BrandLoaded(
        brands: response.records,
        total: response.total,
        page: response.page,
        take: response.take,
        totalPages: response.totalPages,
        search: event.search,
        sortBy: event.sortBy,
        sortOrder: event.sortOrder,
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
    _currentPage = 1;
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
    add(LoadBrands(
      page: _currentPage,
      take: _currentPageSize,
      search: _currentSearch,
      sortBy: _currentSortBy,
      sortOrder: _currentSortOrder,
    ));
  }

  Future<void> _onChangePageSize(
      ChangePageSize event,
      Emitter<BrandState> emit,
      ) async {
    _currentPageSize = event.pageSize;
    _currentPage = 1;
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
}