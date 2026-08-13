import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iq_plus/features/auth/cubit/change_password_state.dart';
import 'package:iq_plus/features/auth/repository/auth_repository.dart';

class CustomerPasswordCubit extends Cubit<CustomerPasswordState> {
  final AuthRepository repository;

  CustomerPasswordCubit(this.repository)
      : super(CustomerPasswordInitial());

  Future<void> updatePassword({
    required String customerId,
    required String newPassword,
    bool isEmployee = false,
  }) async {
    try {
      emit(CustomerPasswordLoading());

      await repository.updateCustomerPassword(
        customerId: customerId,
        newPassword: newPassword,
        isEmployee: isEmployee,
      );

      emit(CustomerPasswordSuccess());
    } catch (e) {
      emit(CustomerPasswordError("Failed to update password"));
    }
  }
}
