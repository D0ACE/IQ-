import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iq_plus/features/users/models/employe_user.dart';

class VisitorSummaryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createVisitorSummary(Map<String, dynamic> data) async {
    await _firestore.collection('visitor_summaries').add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateVisitorSummary({
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    await _firestore
        .collection('visitor_summaries')
        .doc(docId)
        .update(data);
  }

  Future<List<EmployeeUserModel>> fetchAdminUsers() async {
    final snapshot = await _firestore
        .collection('users')
        .where('roleId', whereNotIn: ['2', '3'])
        .get();

    return snapshot.docs
        .map((doc) => EmployeeUserModel.fromFirestore(doc.id, doc.data()))
        .toList();
  }
}
