import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iq_plus/features/auth/model/role_model.dart';
import 'package:iq_plus/features/users/cubit/employee_user_state.dart';
import 'package:iq_plus/features/users/models/employe_user.dart';
import 'package:iq_plus/features/users/repository/user_repository.dart';
import 'package:iq_plus/core/email_services/email_service.dart';
import 'package:iq_plus/core/local_storage/hive_service.dart';
import 'package:iq_plus/di/service_locator.dart';

class UserCubit extends Cubit<UserState> {
  final UserRepository repository;

  UserCubit(this.repository) : super(UserInitial());

  List<RoleModel> roles = [];
  List<EmployeeUserModel> users = [];
  
  // Track last fetch to refresh correctly
  List<String>? _lastCustomerIds;
  String? _lastCreatedBy;
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

  /// 🔹 LOAD USERS (Admins/Consultants based on viewer role)
  Future<void> loadUsers() async {
    try {
      _isEmployeeList = false;
      _lastCustomerIds = null;
      emit(UserLoading());
      
      final currentUser = getIt<HiveService>().getUser();
      users = await repository.fetchUsers(viewerRoleId: currentUser?.roleId);
      
      emit(UserLoaded(users));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  /// 🔹 LOAD EMPLOYEES
  Future<void> loadEmployees({List<String>? customerIds, String? createdBy}) async {
    try {
      _isEmployeeList = true;
      _lastCustomerIds = customerIds;
      _lastCreatedBy = createdBy;
      emit(UserLoading());
      users = await repository.fetchEmployees(customerIds: customerIds, createdBy: createdBy);
      emit(UserLoaded(users));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  /// 🔹 REFRESH Logic
  Future<void> _refresh() async {
    if (_isEmployeeList) {
      await loadEmployees(customerIds: _lastCustomerIds, createdBy: _lastCreatedBy);
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
    String? password,
    bool? blockStatus,
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
          if (password != null) 'password': password,
          'blockStatus': blockStatus,
          'activeUser': blockStatus != null ? !blockStatus : null, // 👈 Sync activeUser with blockStatus
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
