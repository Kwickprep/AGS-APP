import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../models/company_model.dart';
import '../../services/company_service.dart';

// ============================================================================
// Events
// ============================================================================

abstract class CompanyEvent {}

/// Main event to load companies with all parameters
class LoadCompanies extends CompanyEvent {
  final int page;
  final int take;
  final String search;
  final String sortBy;
  final String sortOrder;
  final Map<String, dynamic> filters;

  LoadCompanies({
    this.page = 1,
    this.take = 20,
    this.search = '',
    this.sortBy = 'createdAt',
    this.sortOrder = 'desc',
    this.filters = const {},
  });
}

class DeleteCompany extends CompanyEvent {
  final String id;
  DeleteCompany(this.id);
}

// ============================================================================
// States
// ============================================================================

abstract class CompanyState {}

class CompanyInitial extends CompanyState {}

class CompanyLoading extends CompanyState {}

class CompanyLoaded extends CompanyState {
  final List<CompanyModel> companies;
  final int total;
  final int page;
  final int take;
  final int totalPages;
  final String search;
  final String sortBy;
  final String sortOrder;
  final Map<String, dynamic> filters;

  CompanyLoaded({
    required this.companies,
    required this.total,
    required this.page,
    required this.take,
    required this.totalPages,
    required this.search,
    required this.sortBy,
    required this.sortOrder,
    required this.filters,
  });

  CompanyLoaded copyWith({
    List<CompanyModel>? companies,
    int? total,
    int? page,
    int? take,
    int? totalPages,
    String? search,
    String? sortBy,
    String? sortOrder,
    Map<String, dynamic>? filters,
  }) {
    return CompanyLoaded(
      companies: companies ?? this.companies,
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

class CompanyError extends CompanyState {
  final String message;
  CompanyError(this.message);
}

// ============================================================================
// BLoC - Simple approach: Every change triggers API call
// ============================================================================

class CompanyBloc extends Bloc<CompanyEvent, CompanyState> {
  final CompanyService _companyService = GetIt.I<CompanyService>();

  CompanyBloc() : super(CompanyInitial()) {
    on<LoadCompanies>(_onLoadCompanies);
    on<DeleteCompany>(_onDeleteCompany);
  }

  /// Load companies from API with given parameters
  Future<void> _onLoadCompanies(
    LoadCompanies event,
    Emitter<CompanyState> emit,
  ) async {
    emit(CompanyLoading());

    try {
      final response = await _companyService.getCompanies(
        page: event.page,
        take: event.take,
        search: event.search.trim(),
        sortBy: event.sortBy,
        sortOrder: event.sortOrder,
        filters: event.filters,
      );

      emit(CompanyLoaded(
        companies: response.records,
        total: response.total,
        page: event.page,
        take: event.take,
        totalPages: response.totalPages,
        search: event.search,
        sortBy: event.sortBy,
        sortOrder: event.sortOrder,
        filters: event.filters,
      ));
    } catch (e) {
      emit(CompanyError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// Delete company and reload current page
  Future<void> _onDeleteCompany(
    DeleteCompany event,
    Emitter<CompanyState> emit,
  ) async {
    try {
      await _companyService.deleteCompany(event.id);

      // Reload with current parameters if we have a loaded state
      if (state is CompanyLoaded) {
        final currentState = state as CompanyLoaded;
        add(LoadCompanies(
          page: currentState.page,
          take: currentState.take,
          search: currentState.search,
          sortBy: currentState.sortBy,
          sortOrder: currentState.sortOrder,
          filters: currentState.filters,
        ));
      } else {
        // Otherwise just reload with defaults
        add(LoadCompanies());
      }
    } catch (e) {
      emit(CompanyError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
