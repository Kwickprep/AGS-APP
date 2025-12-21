import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../models/inquiry_model.dart';
import '../../services/inquiry_service.dart';

// ============================================================================
// Events
// ============================================================================

abstract class InquiryEvent {}

/// Main event to load inquiries with all parameters
class LoadInquiries extends InquiryEvent {
  final int page;
  final int take;
  final String search;
  final String sortBy;
  final String sortOrder;
  final Map<String, dynamic> filters;

  LoadInquiries({
    this.page = 1,
    this.take = 20,
    this.search = '',
    this.sortBy = 'createdAt',
    this.sortOrder = 'desc',
    this.filters = const {},
  });
}

class DeleteInquiry extends InquiryEvent {
  final String id;
  DeleteInquiry(this.id);
}

// ============================================================================
// States
// ============================================================================

abstract class InquiryState {}

class InquiryInitial extends InquiryState {}

class InquiryLoading extends InquiryState {}

class InquiryLoaded extends InquiryState {
  final List<InquiryModel> inquiries;
  final int total;
  final int page;
  final int take;
  final int totalPages;
  final String search;
  final String sortBy;
  final String sortOrder;
  final Map<String, dynamic> filters;

  InquiryLoaded({
    required this.inquiries,
    required this.total,
    required this.page,
    required this.take,
    required this.totalPages,
    required this.search,
    required this.sortBy,
    required this.sortOrder,
    required this.filters,
  });

  InquiryLoaded copyWith({
    List<InquiryModel>? inquiries,
    int? total,
    int? page,
    int? take,
    int? totalPages,
    String? search,
    String? sortBy,
    String? sortOrder,
    Map<String, dynamic>? filters,
  }) {
    return InquiryLoaded(
      inquiries: inquiries ?? this.inquiries,
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

class InquiryError extends InquiryState {
  final String message;
  InquiryError(this.message);
}

// ============================================================================
// BLoC - Simple approach: Every change triggers API call
// ============================================================================

class InquiryBloc extends Bloc<InquiryEvent, InquiryState> {
  final InquiryService _inquiryService = GetIt.I<InquiryService>();

  InquiryBloc() : super(InquiryInitial()) {
    on<LoadInquiries>(_onLoadInquiries);
    on<DeleteInquiry>(_onDeleteInquiry);
  }

  /// Load inquiries from API with given parameters
  Future<void> _onLoadInquiries(
    LoadInquiries event,
    Emitter<InquiryState> emit,
  ) async {
    emit(InquiryLoading());

    try {
      final response = await _inquiryService.getInquiries(
        page: event.page,
        take: event.take,
        search: event.search,
        sortBy: event.sortBy,
        sortOrder: event.sortOrder,
        filters: event.filters,
      );

      emit(InquiryLoaded(
        inquiries: response.records,
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
      emit(InquiryError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// Delete inquiry and reload current page
  Future<void> _onDeleteInquiry(
    DeleteInquiry event,
    Emitter<InquiryState> emit,
  ) async {
    try {
      await _inquiryService.deleteInquiry(event.id);
      
      // Reload with current parameters if we have a loaded state
      if (state is InquiryLoaded) {
        final currentState = state as InquiryLoaded;
        add(LoadInquiries(
          page: currentState.page,
          take: currentState.take,
          search: currentState.search,
          sortBy: currentState.sortBy,
          sortOrder: currentState.sortOrder,
          filters: currentState.filters,
        ));
      } else {
        // Otherwise just reload with defaults
        add(LoadInquiries());
      }
    } catch (e) {
      emit(InquiryError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
