import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iq_plus/features/admin/model/admin_model.dart';

class AdminRepository {
  final _firestore = FirebaseFirestore.instance;

  /// 🔹 Get ALL admins
  Future<List<AdminModel>> getAllAdmins() async {
    final snapshot = await _firestore.collection('admins').get();

    return snapshot.docs
        .map((doc) => AdminModel.fromJson(doc.data()))
        .toList();
  }

  /// 🔹 Get SINGLE admin
  Future<AdminModel> getAdminById(String adminId) async {
    final doc = await _firestore.collection('admins').doc(adminId).get();

    if (!doc.exists) {
      throw Exception('Admin not found');
    }

    return AdminModel.fromJson(doc.data()!);
  }
}
