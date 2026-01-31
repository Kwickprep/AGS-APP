import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';
import '../../services/storage_service.dart';
import '../../core/permissions/permission_manager.dart';

// ============================================================================
// Events
// ============================================================================

abstract class RegistrationEvent {}

class SubmitRegistration extends RegistrationEvent {
  final String firstName;
  final String lastName;
  final String industry;
  final String companyName;
  final String department;
  final String division;

  SubmitRegistration({
    required this.firstName,
    required this.lastName,
    required this.industry,
    required this.companyName,
    required this.department,
    required this.division,
  });
}

// ============================================================================
// States
// ============================================================================

abstract class RegistrationState {}

class RegistrationInitial extends RegistrationState {}

class RegistrationLoading extends RegistrationState {}

class RegistrationSuccess extends RegistrationState {
  final UserModel user;
  RegistrationSuccess(this.user);
}

class RegistrationError extends RegistrationState {
  final String message;
  RegistrationError(this.message);
}

// ============================================================================
// BLoC
// ============================================================================

class RegistrationBloc extends Bloc<RegistrationEvent, RegistrationState> {
  final UserService _userService = GetIt.I<UserService>();
  final StorageService _storageService = GetIt.I<StorageService>();
  final String userId;

  RegistrationBloc({required this.userId}) : super(RegistrationInitial()) {
    on<SubmitRegistration>(_onSubmitRegistration);
  }

  Future<void> _onSubmitRegistration(
    SubmitRegistration event,
    Emitter<RegistrationState> emit,
  ) async {
    emit(RegistrationLoading());

    try {
      final data = {
        'firstName': event.firstName.trim(),
        'lastName': event.lastName.trim(),
        'userProvidedIndustry': event.industry,
        'userProvidedCompany': event.companyName.trim(),
        'department': event.department,
        'division': event.division,
        'isRegistered': true,
        'registrationStage': 'COMPLETED',
      };

      final updatedUserJson = await _userService.updateUser(userId, data);
      final updatedUser = UserModel.fromJson(updatedUserJson);

      // Save updated user to storage
      await _storageService.saveUser(updatedUser);

      // Update permissions
      PermissionManager().updatePermissions(updatedUser);

      emit(RegistrationSuccess(updatedUser));
    } catch (e) {
      emit(RegistrationError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
