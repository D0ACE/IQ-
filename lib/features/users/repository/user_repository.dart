import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iq_plus/common/utility/utility.dart';
import 'package:iq_plus/core/local_storage/hive_service.dart';
import 'package:iq_plus/di/service_locator.dart';
import 'package:iq_plus/features/auth/model/role_model.dart';
import 'package:iq_plus/features/auth/model/user_model.dart';
import 'package:iq_plus/features/users/models/employe_user.dart';
import 'package:iq_plus/common/themes/app_const.dart';

class UserRepository {
  final FirebaseFirestore firestore;

  UserRepository(this.firestore);

  // 🔹 Fetch roles
  Future<List<RoleModel>> fetchRoles() async {
    final UserModel? userLoginDetails = getIt<HiveService>().getUser();
    if(Utility.isSuperAdmin(userLoginDetails?.roleId)){
      final snapshot = await firestore.collection('roles') .where('roleId', whereNotIn: ['0']).get();
      return snapshot.docs
          .map((doc) => RoleModel.fromFirestore(doc.data()))
          .toList();
    }else{
      final snapshot = await firestore.collection('roles') .where('roleId', whereNotIn: ['0','1']).get();
      return snapshot.docs
          .map((doc) => RoleModel.fromFirestore(doc.data()))
          .toList();
    }
  }

  // 🔹 Create User (Handles both System Users and Customer Employees)
  Future<void> createUser(EmployeeUserModel user) async {
    // 1. Check uniqueness across all users and employees
    final mainUserCheck = await firestore
        .collection('users')
        .where('email', isEqualTo: user.email)
        .limit(1)
        .get();

    final employeeCheck = await firestore
        .collectionGroup('employees')
        .where('email', isEqualTo: user.email)
        .limit(1)
        .get();

    if (mainUserCheck.docs.isNotEmpty || employeeCheck.docs.isNotEmpty) {
      throw Exception("Email already exists");
    }

    final userData = {
      "userName": user.userName,
      "email": user.email,
      "phoneNumber": user.phoneNumber,
      "password": user.password,
      "roleId": user.roleId,
      "blockStatus": user.blockStatus,
      "activeUser": true,
      "joiningDate": user.joiningDate,
      "designation": user.designation,
      "customerId": user.customerId,
      "createdBy": user.createdBy,
      "fcmToken": "",
      "createdAt": FieldValue.serverTimestamp(),
    };

    if (user.roleId == AppConst.employeeRole && user.customerId != null) {
      // 🚀 Store in sub-collection for Employees
      await firestore
          .collection('customers')
          .doc(user.customerId)
          .collection('employees')
          .add(userData);
    } else {
      // 🚀 Store in main "users" collection for Admins/Consultants
      await firestore.collection('users').add(userData);
    }
  }

  // 🔹 Fetch Users (System Consultants)
  Future<List<EmployeeUserModel>> fetchUsers() async {
    final snapshot = await firestore
        .collection('users')
        .where('roleId', isEqualTo: AppConst.consultantRole) // Only Consultants (Role 2)
        .get();
    return snapshot.docs
        .map((doc) => EmployeeUserModel.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  // 🔹 Fetch Employees (Role 4)
  Future<List<EmployeeUserModel>> fetchEmployees({List<String>? customerIds, String? createdBy}) async {
    Query query = firestore.collectionGroup('employees');

    if (customerIds != null && customerIds.isNotEmpty) {
      query = query.where('customerId', whereIn: customerIds);
    }

    if (createdBy != null && createdBy.isNotEmpty) {
      query = query.where('createdBy', isEqualTo: createdBy);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => EmployeeUserModel.fromFirestore(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }

  // 🔹 Delete User
  Future<void> deleteUser(String userId, {String? customerId}) async {
    try {
      if (customerId != null) {
        await firestore
            .collection('customers')
            .doc(customerId)
            .collection('employees')
            .doc(userId)
            .delete();
      } else {
        // Try deleting from main users
        final doc = await firestore.collection('users').doc(userId).get();
        if (doc.exists) {
          await doc.reference.delete();
        } else {
          // If not in main, search in all employees
          final snap = await firestore.collectionGroup('employees').get();
          final employeeDoc = snap.docs.firstWhere((d) => d.id == userId);
          await employeeDoc.reference.delete();
        }
      }
    } catch (e) {
      throw Exception("Failed to delete user: $e");
    }
  }

  // 🔹 Update User
  Future<void> updateUser({
    required String userId,
    required Map<String, dynamic> data,
    String? customerId,
  }) async {
    if (customerId != null) {
      await firestore
          .collection('customers')
          .doc(customerId)
          .collection('employees')
          .doc(userId)
          .update(data);
    } else {
      final doc = await firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        await doc.reference.update(data);
      } else {
        final snap = await firestore.collectionGroup('employees').get();
        final employeeDoc = snap.docs.firstWhere((d) => d.id == userId);
        await employeeDoc.reference.update(data);
      }
    }
  }

  // 🔹 Global Statistics
  Future<int> getTotalCustomerCount() async {
    final snapshot = await firestore.collection('customers').count().get();
    return snapshot.count ?? 0;
  }

  Future<int> getTotalConsultantCount() async {
    final snapshot = await firestore.collection('users').where('roleId', isEqualTo: AppConst.consultantRole).count().get();
    return snapshot.count ?? 0;
  }

  Future<int> getTotalAdminCount() async {
    final snapshot = await firestore.collection('users').where('roleId', isEqualTo: AppConst.adminRole).count().get();
    return snapshot.count ?? 0;
  }

  Future<int> getTotalActiveUserCount() async {
    final users = await firestore.collection('users').where('blockStatus', isEqualTo: false).count().get();
    final customers = await firestore.collection('customers').where('isProfileApproved', isEqualTo: true).count().get();
    final employees = await firestore.collectionGroup('employees').where('blockStatus', isEqualTo: false).count().get();
    return (users.count ?? 0) + (customers.count ?? 0) + (employees.count ?? 0);
  }
}
