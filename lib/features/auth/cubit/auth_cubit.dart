import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iq_plus/common/utility/exception_utils.dart';
import 'package:iq_plus/core/local_storage/hive_service.dart';
import 'package:iq_plus/di/service_locator.dart';
import 'package:iq_plus/features/auth/cubit/sate/auth_state.dart';
import 'package:iq_plus/features/auth/model/role_model.dart';
import 'package:iq_plus/features/auth/repository/auth_repository.dart';
import 'package:iq_plus/common/constants/role_index_mapper.dart';
import 'package:iq_plus/common/utility/utility.dart';


class AuthCubit extends Cubit<AuthState> {
  final AuthRepository repo;

  AuthCubit(this.repo) : super(AuthInitial());

  /// LOGIN
  Future<void> login(String email, String password, int selectedRole) async {
  try {
    await getIt<HiveService>().clearAll();
    emit(AuthLoading());

    // 🔹 convert selected tab index → roleId
    final selectedRoleId =
        RoleIndexMapper.roleIdFromIndex(selectedRole);

    // 🔹 authenticate user
    final RoleModel role =
        await repo.login(email, password, selectedRole);

    // 🔒 role validation (CRITICAL)
    final actualRoleName = Utility.getUserRoleName(role.id);
    // If selected tab is Customer (index 3), allow both role '3' (Customer) and '4' (Employee)
    if (selectedRole == 3) {
      if (role.id != '3' && role.id != '4') {
        emit(AuthFailure("These credentials belong to a $actualRoleName. Please select the correct tab."));
        return;
      }
    } else if (role.id != selectedRoleId) {
      emit(AuthFailure("These credentials belong to a $actualRoleName. Please select the correct tab."));
      return;
    }

    // ✅ success
    emit(AuthSuccess(role.id, role.name,role.customerId));
  } catch (e) {
    emit(AuthFailure(ExceptionUtils.getMessage(e)));
  }
}

}
