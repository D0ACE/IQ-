import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iq_plus/features/auth/model/role_model.dart';
import 'package:iq_plus/features/users/cubit/employee_user_state.dart';
import 'package:iq_plus/features/users/models/employe_user.dart';
import 'package:iq_plus/features/users/repository/user_repository.dart';
import 'package:iq_plus/core/email_services/email_service.dart';

class UserCubit extends Cubit<UserState> {
  final UserRepository repository;

  UserCubit(this.repository) : super(UserInitial());

  List<RoleModel> roles = [];
  List<EmployeeUserModel> users = [];
  
  // Track last fetch to refresh correctly
  List<String>? _lastCustomerIds;
  bool _isEmployeeList = false;

  @override
  void emit(UserState state) {
    if (isClosed) return;
    super.emit(state);
  }

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
  Future<void> addUser(EmployeeUserModel user, {String? companyName}) async {
    emit(UserLoading());
    try {
      await repository.createUser(user);

      // 📧 Send Credentials Email if it's an employee linked to a company
      if (companyName != null) {
        // Set mode to employee so refresh loads the correct list
        _isEmployeeList = true;
        _lastCustomerIds = user.customerId != null ? [user.customerId!] : null;

        await BrevoEmailService.sendEmployeeCreatedMail(
          userName: user.userName,
          email: user.email,
          password: user.password,
          companyName: companyName,
        );
      }

      emit(UserSuccess("User created successfully"));
      await _refresh(); 
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  /// 🔹 LOAD USERS (Consultants)
  Future<void> loadUsers() async {
    try {
      _isEmployeeList = false;
      _lastCustomerIds = null;
      emit(UserLoading());
      users = await repository.fetchUsers();
      emit(UserLoaded(users));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  /// 🔹 LOAD EMPLOYEES
  Future<void> loadEmployees({List<String>? customerIds}) async {
    try {
      _isEmployeeList = true;
      _lastCustomerIds = customerIds;
      emit(UserLoading());
      users = await repository.fetchEmployees(customerIds: customerIds);
      emit(UserLoaded(users));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  /// 🔹 REFRESH Logic
  Future<void> _refresh() async {
    if (_isEmployeeList) {
      await loadEmployees(customerIds: _lastCustomerIds);
    } else {
      await loadUsers();
    }
  }

  /// 🔹 DELETE USER
  Future<void> deleteUser(String userId, {String? customerId}) async {
    emit(UserLoading());
    try {
      await repository.deleteUser(userId, customerId: customerId);
      await _refresh();
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
    String? designation,
    String? customerId,
    DateTime? joiningDate,
  }) async {
    try {
      emit(UserLoading());

      await repository.updateUser(
        userId: userId,
        customerId: customerId,
        data: {
          'userName': userName,
          'email': email,
          'phoneNumber': phoneNumber,
          'roleId': roleId,
          'joiningDate': joiningDate,
          'designation': designation,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      await _refresh(); 
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }
}
