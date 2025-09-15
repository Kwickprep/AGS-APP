import 'package:ags/services/storage_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';

// Events
abstract class LoginEvent {}

class LoginSubmitted extends LoginEvent {
  final String email;
  final String password;
  final bool rememberMe;

  LoginSubmitted({
    required this.email,
    required this.password,
    required this.rememberMe,
  });
}

class CheckRememberMe extends LoginEvent {}

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

class LoginRememberMeLoaded extends LoginState {
  final bool rememberMe;
  final String email;
  final String password;

  LoginRememberMeLoaded({
    required this.rememberMe,
    required this.email,
    required this.password,
  });
}

// Bloc
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthService _authService = GetIt.I<AuthService>();
  final StorageService _storageService = GetIt.I<StorageService>();

  LoginBloc() : super(LoginInitial()) {
    on<LoginSubmitted>(_onLoginSubmitted);
    on<CheckRememberMe>(_onCheckRememberMe);
  }

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    emit(LoginLoading());

    try {
      final user = await _authService.login(
        event.email,
        event.password,
        event.rememberMe,
      );
      if (user != null) {
        _storageService.saveUser(user);
        emit(LoginSuccess(user));
      } else {
        emit(LoginError('Login failed. Please try again.'));
      }
    } catch (e) {
      emit(LoginError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCheckRememberMe(
    CheckRememberMe event,
    Emitter<LoginState> emit,
  ) async {
    final rememberMeData = await _authService.getRememberMeData();
    emit(
      LoginRememberMeLoaded(
        rememberMe: rememberMeData['rememberMe'],
        email: rememberMeData['email'],
        password: rememberMeData['password'],
      ),
    );
  }
}
