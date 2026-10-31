import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iq_plus/common/utility/utility.dart';
import 'package:iq_plus/core/local_storage/hive_service.dart';
import 'package:iq_plus/di/service_locator.dart';
import 'package:iq_plus/features/auth/model/role_model.dart';
import 'package:iq_plus/features/auth/model/user_model.dart';
import 'package:iq_plus/common/themes/app_const.dart';
import '../models/employe_user.dart';
import '../models/system_user_model.dart';

class UserRepository {
  final FirebaseFirestore firestore;

  UserRepository(this.firestore);

  // 🔹 Fetch roles
  Future<List<RoleModel>> fetchRoles() async {
    final UserModel? userLoginDetails = getIt<HiveService>().getUser();
    
    // 🚀 Only Allow "Admin" and "User" (formerly Consultant) in the dropdown
    if (Utility.isSuperAdmin(userLoginDetails?.roleId)) {
      final snapshot = await firestore
          .collection('roles')
          .where('roleId', whereIn: ['1', '2']).get();
      return snapshot.docs
          .map((doc) => RoleModel.fromFirestore(doc.data()))
          .toList();
    } else {
      // Admins can only add "User" (formerly Consultant)
      final snapshot = await firestore
          .collection('roles')
          .where('roleId', isEqualTo: '2').get();
      return snapshot.docs
          .map((doc) => RoleModel.fromFirestore(doc.data()))
          .toList();
    }
  }

  // 🔹 Create User (Handles both System Users and Customer Employees)
  Future<void> createUser(dynamic user) async {
    // 1. Check uniqueness across all users and employees
    String email = "";
    if (user is EmployeeUserModel) {
      email = user.email;
    } else if (user is SystemUserModel) {
      email = user.email;
    }

    final mainUserCheck = await firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    final employeeCheck = await firestore
        .collectionGroup('employees')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (mainUserCheck.docs.isNotEmpty || employeeCheck.docs.isNotEmpty) {
      throw Exception("Email already exists");
    }

    Map<String, dynamic> userData;

    if (user is EmployeeUserModel) {
      userData = {
        "userName": user.userName,
        "email": user.email,
        "phoneNumber": user.phoneNumber,
        "password": user.password,
        "roleId": user.roleId,
        "blockStatus": user.blockStatus,
        "joiningDate": user.joiningDate,
        "designation": user.designation,
        "customerId": user.customerId,
        "createdBy": user.createdBy,
        "visibleModules": user.visibleModules,
        "fcmToken": "",
        "createdAt": FieldValue.serverTimestamp(),
      };

      // 🚀 Store in sub-collection for Employees
      await firestore
          .collection('customers')
          .doc(user.customerId)
          .collection('employees')
          .add(userData);
    } else if (user is SystemUserModel) {
      userData = user.toMap();
      userData["createdAt"] = FieldValue.serverTimestamp();
      
      // 🚀 Store in main "users" collection for Admins/Consultants
      await firestore.collection('users').add(userData);
    }
  }

  // 🔹 Fetch Users (Filtered based on viewer role)
  Future<List<SystemUserModel>> fetchUsers({String? viewerRoleId}) async {
    Query query = firestore.collection('users');

    if (Utility.isSuperAdmin(viewerRoleId)) {
      // 🚀 Super Admin sees both Admins and Consultants
      query = query.where('roleId', whereIn: [AppConst.adminRole, AppConst.consultantRole]);
    } else {
      // 🚀 Admins (or others) only see Consultants
      query = query.where('roleId', isEqualTo: AppConst.consultantRole);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => SystemUserModel.fromFirestore(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }

  // 🔹 Fetch Employees (Role 4)
  Future<List<EmployeeUserModel>> fetchEmployees({
    List<String>? customerIds,
    String? createdBy,
    String? consultantId,
  }) async {
    try {
      if (consultantId != null && consultantId.isNotEmpty) {
        // 🚀 For consultants, fetch assigned customers
        final custSnapshot = await firestore
            .collection('customers')
            .where('consultantId', isEqualTo: consultantId)
            .get();
        final assignedCustomerIds =
            custSnapshot.docs.map((doc) => doc.id).toSet();

        final snapshot = await firestore.collectionGroup('employees').get();
        final allEmployees = snapshot.docs
            .map((doc) => EmployeeUserModel.fromFirestore(
                doc.id, doc.data(), pathCustomerId: doc.reference.parent.parent?.id))
            .toList();

        return allEmployees.where((emp) {
          if (emp.isOtherEmployee) return false;
          final isCreatedByMe = emp.createdBy == consultantId;
          final isMyCustomerEmp = emp.customerId != null &&
              assignedCustomerIds.contains(emp.customerId);
          return isCreatedByMe || isMyCustomerEmp;
        }).toList();
      }

      Query query = firestore.collectionGroup('employees');

      if (customerIds != null && customerIds.isNotEmpty) {
        query = query.where('customerId', whereIn: customerIds);
      }

      if (createdBy != null && createdBy.isNotEmpty) {
        query = query.where('createdBy', isEqualTo: createdBy);
      }

      final snapshot = await query.get();
      final employees = snapshot.docs
          .map((doc) => EmployeeUserModel.fromFirestore(
              doc.id, doc.data() as Map<String, dynamic>, pathCustomerId: doc.reference.parent.parent?.id))
          .toList();
      return employees.where((emp) => !emp.isOtherEmployee).toList();
    } catch (e) {
      developer.log("Error fetching employees: $e");
      // Return empty list if index is missing to prevent UI crash
      return [];
    }
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
    final snapshot = await firestore.collection('customers').get();
    return snapshot.docs.where((doc) {
      final data = doc.data();
      final companyName = (data['companyName'] ?? '').toString().trim();
      return companyName.isNotEmpty;
    }).length;
  }

  Future<int> getTotalConsultantCount() async {
    final snapshot = await firestore.collection('users').where('roleId', isEqualTo: AppConst.consultantRole).count().get();
    return snapshot.count ?? 0;
  }

  Future<int> getTotalAdminCount() async {
    final snapshot = await firestore.collection('admins').count().get();
    return snapshot.count ?? 0;
  }

  Future<int> getTotalSystemUserCount() async {
    final snapshot = await firestore
        .collection('users')
        .where('roleId', whereIn: [AppConst.adminRole, AppConst.consultantRole])
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  // 🔹 Real-time Stream Statistics
  Stream<int> getCustomerCountStream() {
    return firestore.collection('customers').snapshots().map((snapshot) {
      return snapshot.docs.where((doc) {
        final data = doc.data();
        final companyName = (data['companyName'] ?? '').toString().trim();
        return companyName.isNotEmpty;
      }).length;
    });
  }

  Stream<int> getConsultantCountStream() {
    return firestore
        .collection('users')
        .where('roleId', isEqualTo: AppConst.consultantRole)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<int> getAdminCountStream() {
    return firestore
        .collection('admins')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<int> getSystemUserCountStream() {
    return firestore
        .collection('users')
        .where('roleId', whereIn: [AppConst.adminRole, AppConst.consultantRole])
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<int> getTotalActiveUserCount() async {
    try {
      final users = await firestore.collection('users').where('blockStatus', isEqualTo: false).count().get();
      final customersSnap = await firestore.collection('customers').where('isProfileApproved', isEqualTo: true).get();
      final activeCustomersCount = customersSnap.docs.where((doc) {
        final data = doc.data();
        final companyName = (data['companyName'] ?? '').toString().trim();
        return companyName.isNotEmpty;
      }).length;
      
      // 🚀 Wrap collectionGroup in try-catch to prevent crash if index is missing
      int employeeCount = 0;
      try {
        final employees = await firestore.collectionGroup('employees').where('blockStatus', isEqualTo: false).count().get();
        employeeCount = employees.count ?? 0;
      } catch (e) {
        developer.log("Firestore Index Error for employees blockStatus: $e");
        // Fallback or just return 0 for now until index is created
      }
      
      return (users.count ?? 0) + activeCustomersCount + employeeCount;
    } catch (e) {
      developer.log("Error calculating active users: $e");
      return 0;
    }
  }
}
