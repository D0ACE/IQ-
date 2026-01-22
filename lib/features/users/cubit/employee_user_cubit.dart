import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iq_plus/features/auth/model/role_model.dart';
import 'package:iq_plus/features/users/cubit/employee_user_state.dart';
import 'package:iq_plus/features/users/models/employe_user.dart';
import 'package:iq_plus/features/users/repository/user_repository.dart';

class UserCubit extends Cubit<UserState> {
  final UserRepository repository;

  UserCubit(this.repository) : super(UserInitial());

  List<RoleModel> roles = [];
  List<EmployeeUserModel> users = [];

  /// 🔹 LOAD ROLES
  Future<void> loadRoles() async {
    try {
      emit(UserRolesLoading());
      roles = await repository.fetchRoles();
      emit(UserRolesLoaded(roles));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  /// 🔹 ADD USER
  Future<void> addUser(EmployeeUserModel user) async {
    emit(UserLoading());
    try {
      await repository.createUser(user);
      emit(UserSuccess("User created successfully"));
      await loadUsers(); // ✅ await added
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  /// 🔹 LOAD USERS
  Future<void> loadUsers() async {
    try {
      emit(UserLoading());
      users = await repository.fetchUsers();
      emit(UserLoaded(users));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  /// 🔹 DELETE USER
  Future<void> deleteUser(String userId) async {
    emit(UserLoading());
    try {
      await repository.deleteUser(userId);
      await loadUsers(); // ✅ await added
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  /// 🔹 UPDATE USER
  Future<void> updateUser({
    required String userId,
    required String userName,
    required String email,
    required String phoneNumber,
    required String roleId,
    DateTime? joiningDate,
  }) async {
    try {
      emit(UserLoading());

      await repository.updateUser(
        userId: userId,
        data: {
          'userName': userName,
          'email': email,
          'phoneNumber': phoneNumber,
          'roleId': roleId,
          'joiningDate': joiningDate,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      await loadUsers(); // 🔄 refresh list
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }
}
