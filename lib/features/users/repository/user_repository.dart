import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iq_plus/features/auth/model/role_model.dart';
import 'package:iq_plus/features/users/models/employe_user.dart';

class UserRepository {
  final FirebaseFirestore firestore;

  UserRepository(this.firestore);

  // 🔹 Fetch roles
  Future<List<RoleModel>> fetchRoles() async {
    final snapshot = await firestore.collection('roles') .where('roleId', whereNotIn: ['1', '3']).get();
    return snapshot.docs
        .map((doc) => RoleModel.fromFirestore(doc.data()))
        .toList();
  }

  // 🔹 Create user
  Future<void> createUser(EmployeeUserModel user) async {
    // prevent duplicate email
    final existing = await firestore
        .collection('users')
        .where('email', isEqualTo: user.email)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception("Email already exists");
    }

    await firestore.collection('users').add({
      "userName": user.userName,
      "email": user.email,
      "phoneNumber": user.phoneNumber,
      "password": user.password,
      "roleId": user.roleId,
      "blockStatus": user.blockStatus,
      "activeUser": true,
      "joiningDate": user.joiningDate,
      "fcmToken": "",
      "createdAt": FieldValue.serverTimestamp(),
    });
  }

  Future<List<EmployeeUserModel>> fetchUsers() async {
    final snapshot = await firestore
        .collection('users')
        .where('roleId', whereNotIn: ['1', '3','0'])
        .get();

    return snapshot.docs
        .map((doc) => EmployeeUserModel.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  Future<void> deleteUser(String userId) async {
    try {
      await firestore
          .collection('users')
          .doc(userId)
          .delete();
    } catch (e) {
      throw Exception("Failed to delete user: $e");
    }
  }

  Future<void> updateUser({
  required String userId,
  required Map<String, dynamic> data,
}) async {
  await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .update(data);
}

}
