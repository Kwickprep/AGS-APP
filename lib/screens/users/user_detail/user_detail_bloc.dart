import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../../models/user_insights_model.dart';
import '../../../services/user_service.dart';

// ============================================================================
// Events
// ============================================================================

abstract class UserDetailEvent {}

class LoadUserInsights extends UserDetailEvent {
  final String userId;
  LoadUserInsights(this.userId);
}

// ============================================================================
// States
// ============================================================================

abstract class UserDetailState {}

class UserDetailInitial extends UserDetailState {}

class UserDetailLoading extends UserDetailState {}

class UserDetailLoaded extends UserDetailState {
  final UserInsightsResponse data;
  UserDetailLoaded(this.data);
}

class UserDetailError extends UserDetailState {
  final String message;
  UserDetailError(this.message);
}

// ============================================================================
// BLoC
// ============================================================================

class UserDetailBloc extends Bloc<UserDetailEvent, UserDetailState> {
  final UserService _userService = GetIt.I<UserService>();

  UserDetailBloc() : super(UserDetailInitial()) {
    on<LoadUserInsights>(_onLoadUserInsights);
  }

  Future<void> _onLoadUserInsights(
    LoadUserInsights event,
    Emitter<UserDetailState> emit,
  ) async {
    emit(UserDetailLoading());
    try {
      final response = await _userService.getUserInsights(event.userId);
      emit(UserDetailLoaded(response as UserInsightsResponse));
    } catch (e) {
      emit(UserDetailError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
