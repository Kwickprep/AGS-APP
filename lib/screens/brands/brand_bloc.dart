import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../models/brand_model.dart';
import '../../services/brand_service.dart';

// ============================================================================
// Events
// ============================================================================

abstract class BrandEvent {}

/// Main event to load brands with all parameters
class LoadBrands extends BrandEvent {
  final int page;
  final int take;
  final String search;
  final String sortBy;
  final String sortOrder;
  final Map<String, dynamic> filters;

  LoadBrands({
    this.page = 1,
    this.take = 20,
    this.search = '',
    this.sortBy = 'createdAt',
    this.sortOrder = 'desc',
    this.filters = const {},
  });
}

class DeleteBrand extends BrandEvent {
  final String id;
  DeleteBrand(this.id);
}

// ============================================================================
// States
// ============================================================================

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
  final Map<String, dynamic> filters;

  BrandLoaded({
    required this.brands,
    required this.total,
    required this.page,
    required this.take,
    required this.totalPages,
    required this.search,
    required this.sortBy,
    required this.sortOrder,
    required this.filters,
  });

  BrandLoaded copyWith({
    List<BrandModel>? brands,
    int? total,
    int? page,
    int? take,
    int? totalPages,
    String? search,
    String? sortBy,
    String? sortOrder,
    Map<String, dynamic>? filters,
  }) {
    return BrandLoaded(
      brands: brands ?? this.brands,
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

class BrandError extends BrandState {
  final String message;
  BrandError(this.message);
}

// ============================================================================
// BLoC - Simple approach: Every change triggers API call
// ============================================================================

class BrandBloc extends Bloc<BrandEvent, BrandState> {
  final BrandService _brandService = GetIt.I<BrandService>();

  BrandBloc() : super(BrandInitial()) {
    on<LoadBrands>(_onLoadBrands);
    on<DeleteBrand>(_onDeleteBrand);
  }

  /// Load brands from API with given parameters
  Future<void> _onLoadBrands(
    LoadBrands event,
    Emitter<BrandState> emit,
  ) async {
    emit(BrandLoading());

    try {
      final response = await _brandService.getBrands(
        page: event.page,
        take: event.take,
        search: event.search,
        sortBy: event.sortBy,
        sortOrder: event.sortOrder,
        filters: event.filters,
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
        filters: event.filters,
      ));
    } catch (e) {
      emit(BrandError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// Delete brand and reload current page
  Future<void> _onDeleteBrand(
    DeleteBrand event,
    Emitter<BrandState> emit,
  ) async {
    try {
      await _brandService.deleteBrand(event.id);
      
      // Reload with current parameters if we have a loaded state
      if (state is BrandLoaded) {
        final currentState = state as BrandLoaded;
        add(LoadBrands(
          page: currentState.page,
          take: currentState.take,
          search: currentState.search,
          sortBy: currentState.sortBy,
          sortOrder: currentState.sortOrder,
          filters: currentState.filters,
        ));
      } else {
        // Otherwise just reload with defaults
        add(LoadBrands());
      }
    } catch (e) {
      emit(BrandError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
