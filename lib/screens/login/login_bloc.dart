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

class SendOtpRequested extends LoginEvent {
  final String phoneCode;
  final String phoneNumber;

  SendOtpRequested({
    required this.phoneCode,
    required this.phoneNumber,
  });
}

class VerifyOtpSubmitted extends LoginEvent {
  final String phoneCode;
  final String phoneNumber;
  final String otp;

  VerifyOtpSubmitted({
    required this.phoneCode,
    required this.phoneNumber,
    required this.otp,
  });
}

class CheckRememberMe extends LoginEvent {}

// States
abstract class LoginState {}

class LoginInitial extends LoginState {}

class LoginLoading extends LoginState {}

class OtpSent extends LoginState {
  final String phoneNumber;
  OtpSent(this.phoneNumber);
}

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

  LoginBloc() : super(LoginInitial()) {
    on<LoginSubmitted>(_onLoginSubmitted);
    on<SendOtpRequested>(_onSendOtpRequested);
    on<VerifyOtpSubmitted>(_onVerifyOtpSubmitted);
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
        emit(LoginSuccess(user));
      } else {
        emit(LoginError('Login failed. Please try again.'));
      }
    } catch (e) {
      emit(LoginError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onSendOtpRequested(
    SendOtpRequested event,
    Emitter<LoginState> emit,
  ) async {
    emit(LoginLoading());

    try {
      final result = await _authService.sendOtp(event.phoneCode, event.phoneNumber);

      if (result['success'] == true) {
        emit(OtpSent('${event.phoneCode}${event.phoneNumber}'));
      } else {
        emit(LoginError(result['message'] ?? 'Failed to send OTP. Please try again.'));
      }
    } catch (e) {
      emit(LoginError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onVerifyOtpSubmitted(
    VerifyOtpSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    emit(LoginLoading());

    try {
      final user = await _authService.verifyOtp(event.phoneCode, event.phoneNumber, event.otp);

      if (user != null) {
        emit(LoginSuccess(user));
      } else {
        emit(LoginError('Invalid OTP. Please try again.'));
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
    emit(LoginRememberMeLoaded(
      rememberMe: rememberMeData['rememberMe'],
      email: rememberMeData['email'],
      password: rememberMeData['password'],
    ));
  }
}
