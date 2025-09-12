import 'package:flutter_bloc/flutter_bloc.dart';

// Events
abstract class SignupEvent {}

class SignupSubmitted extends SignupEvent {
  final String email;
  final String phone;
  final String password;

  SignupSubmitted({
    required this.email,
    required this.phone,
    required this.password,
  });
}

// States
abstract class SignupState {}

class SignupInitial extends SignupState {}

class SignupLoading extends SignupState {}

class SignupSuccess extends SignupState {}

class SignupError extends SignupState {
  final String message;
  SignupError(this.message);
}

// Bloc
class SignupBloc extends Bloc<SignupEvent, SignupState> {
  SignupBloc() : super(SignupInitial()) {
    on<SignupSubmitted>(_onSignupSubmitted);
  }

  Future<void> _onSignupSubmitted(
      SignupSubmitted event,
      Emitter<SignupState> emit,
      ) async {
    emit(SignupLoading());

    // TODO: Implement signup when API is provided
    await Future.delayed(const Duration(seconds: 2));
    emit(SignupError('Signup API not implemented yet'));
  }
}
