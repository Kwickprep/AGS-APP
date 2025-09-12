import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';

// Events
abstract class LoginEvent {}

class LoginSubmitted extends LoginEvent {
  final String email;
  final String password;

  LoginSubmitted({required this.email, required this.password});
}

// States
abstract class LoginState {}

class LoginInitial extends LoginState {}

class LoginLoading extends LoginState {}

class LoginSuccess extends LoginState {
  final UserModel user;
  LoginSuccess(this.user);
}

class LoginError extends LoginState {
  final String message;
  LoginError(this.message);
}

// Bloc
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthService _authService = GetIt.I<AuthService>();

  LoginBloc() : super(LoginInitial()) {
    on<LoginSubmitted>(_onLoginSubmitted);
  }

  Future<void> _onLoginSubmitted(
      LoginSubmitted event,
      Emitter<LoginState> emit,
      ) async {
    emit(LoginLoading());

    try {
      final user = await _authService.login(event.email, event.password);
      if (user != null) {
        emit(LoginSuccess(user));
      } else {
        emit(LoginError('Login failed. Please try again.'));
      }
    } catch (e) {
      emit(LoginError(e.toString()));
      print(e);
    }
  }
}
