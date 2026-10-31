import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iq_plus/common/utility/exception_utils.dart';
import 'package:iq_plus/core/local_storage/hive_service.dart';
import 'package:iq_plus/di/service_locator.dart';
import 'package:iq_plus/features/auth/cubit/sate/auth_state.dart';
import 'package:iq_plus/features/auth/model/role_model.dart';
import 'package:iq_plus/features/auth/repository/auth_repository.dart';
import 'package:iq_plus/common/constants/role_index_mapper.dart';
import 'package:iq_plus/common/themes/app_const.dart';
import 'package:iq_plus/common/utility/utility.dart';


class AuthCubit extends Cubit<AuthState> {
  final AuthRepository repo;
  StreamSubscription? _userBlockSubscription;

  AuthCubit(this.repo) : super(AuthInitial()) {
    checkBlockStatus();
    startListeningToUserBlockStatus();
  }

  @override
  Future<void> close() {
    _userBlockSubscription?.cancel();
    return super.close();
  }

  /// LOGIN
  Future<void> login(String email, String password, int selectedRole) async {
  try {
    await getIt<HiveService>().clearAll();
    _userBlockSubscription?.cancel();
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

    startListeningToUserBlockStatus();

    // ✅ success
    emit(AuthSuccess(role.id, role.name,role.customerId));
  } catch (e) {
    emit(AuthFailure(ExceptionUtils.getMessage(e)));
  }
}

  /// CHECK USER BLOCK STATUS
  Future<void> checkBlockStatus() async {
    try {
      final isBlocked = await repo.isUserBlocked();
      if (isBlocked) {
        _userBlockSubscription?.cancel();
        await getIt<HiveService>().clearAll();
        emit(AuthUserBlocked("Your account is blocked. Please contact the administrator."));
      }
    } catch (e) {
      // ignore
    }
  }

  /// REAL-TIME STREAM LISTENER FOR BLOCK STATUS
  void startListeningToUserBlockStatus() {
    _userBlockSubscription?.cancel();
    final user = getIt<HiveService>().getUser();
    if (user == null) return;

    try {
      if (user.roleId == AppConst.adminRole ||
          user.roleId == AppConst.consultantRole ||
          user.roleId == AppConst.superAdminRole ||
          user.roleId == '1' ||
          user.roleId == '2' ||
          user.roleId == '0') {
        _userBlockSubscription = FirebaseFirestore.instance
            .collection('users')
            .doc(user.userId)
            .snapshots()
            .listen((doc) async {
          if (doc.exists) {
            final data = doc.data();
            if (data != null &&
                (data['blockStatus'] == true || data['activeUser'] == false)) {
              _userBlockSubscription?.cancel();
              await getIt<HiveService>().clearAll();
              emit(AuthUserBlocked("Your account is blocked. Please contact the administrator."));
            }
          } else {
            _userBlockSubscription?.cancel();
            await getIt<HiveService>().clearAll();
            emit(AuthUserBlocked("Your account has been deleted or blocked. Please contact the administrator."));
          }
        }, onError: (e) {
          debugPrint("User block stream error: $e");
        });
      } else if (user.roleId == AppConst.employeeRole || user.roleId == '4') {
        if (user.customerId != null && user.customerId!.isNotEmpty) {
          _userBlockSubscription = FirebaseFirestore.instance
              .collection('customers')
              .doc(user.customerId)
              .collection('employees')
              .doc(user.userId)
              .snapshots()
              .listen((doc) async {
            if (doc.exists) {
              final data = doc.data();
              if (data != null &&
                  (data['blockStatus'] == true || data['activeUser'] == false)) {
                _userBlockSubscription?.cancel();
                await getIt<HiveService>().clearAll();
                emit(AuthUserBlocked("Your account is blocked. Please contact the administrator."));
              }
            } else {
              _userBlockSubscription?.cancel();
              await getIt<HiveService>().clearAll();
              emit(AuthUserBlocked("Your account has been deleted or blocked. Please contact the administrator."));
            }
          }, onError: (e) {
            debugPrint("Employee block stream error: $e");
          });
        }
      }
    } catch (e) {
      debugPrint("Error starting user block status listener: $e");
    }
  }

}
