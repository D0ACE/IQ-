import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iq_plus/common/utility/exception_utils.dart';
import 'package:iq_plus/core/local_storage/hive_service.dart';
import 'package:iq_plus/di/service_locator.dart';
import 'package:iq_plus/features/auth/cubit/sate/auth_state.dart';
import 'package:iq_plus/features/auth/model/role_model.dart';
import 'package:iq_plus/features/auth/repository/auth_repository.dart';
import 'package:iq_plus/common/constants/role_index_mapper.dart';


class AuthCubit extends Cubit<AuthState> {
  final AuthRepository repo;

  AuthCubit(this.repo) : super(AuthInitial());

  /// LOGIN
  Future<void> login(String email, String password, int selectedRole) async {
  try {
    getIt<HiveService>().clearAll();
    emit(AuthLoading());

    // 🔹 convert selected tab index → roleId
    final selectedRoleId =
        RoleIndexMapper.roleIdFromIndex(selectedRole);

    // 🔹 authenticate user
    final RoleModel role =
        await repo.login(email, password, selectedRole);

    // 🔒 role validation (CRITICAL)
    if (role.id != selectedRoleId) {
      emit(AuthFailure("Unauthorized role login"));
      return;
    }

    // ✅ success
    emit(AuthSuccess(role.id, role.name));
  } catch (e) {
    emit(AuthFailure(ExceptionUtils.getMessage(e)));
  }
}

}
