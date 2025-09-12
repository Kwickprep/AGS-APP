import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';

// Events
abstract class HomeEvent {}

class LoadUserData extends HomeEvent {}

// States
abstract class HomeState {}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final UserModel? user;
  HomeLoaded(this.user);
}

// Bloc
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final AuthService _authService = GetIt.I<AuthService>();

  HomeBloc() : super(HomeInitial()) {
    on<LoadUserData>(_onLoadUserData);
  }

  Future<void> _onLoadUserData(
      LoadUserData event,
      Emitter<HomeState> emit,
      ) async {
    emit(HomeLoading());
    final user = await _authService.getCurrentUser();
    emit(HomeLoaded(user));
  }
}
