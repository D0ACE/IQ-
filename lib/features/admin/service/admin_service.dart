import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/admin_model.dart';

class AdminService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ✅ CREATE ADMIN (NAMED PARAMETERS)
  static Future<void> createAdmin({
    required String userName,
    required String email,
    required String phone,
    required String password,
  }) async {
    // 1️⃣ Create Auth user
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = userCredential.user!.uid;

    // 2️⃣ Create model
    final admin = AdminModel(
      adminId: uid,
      userName: userName,
      email: email,
      phone: phone,
      role: 'admin',
      isActive: true,
    );

    // 3️⃣ Save to Firestore
    await _firestore
        .collection('admins')
        .doc(uid)
        .set(admin.toJson());
  }
}
