import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:iq_plus/core/local_storage/hive_service.dart';
import 'package:iq_plus/di/service_locator.dart';
import 'package:iq_plus/features/dashboard/page/visit_summary/model/visitor_summary_model.dart';
import 'package:iq_plus/features/users/models/employe_user.dart';

class VisitorSummaryRepository {
  final FirebaseFirestore firestore;

  VisitorSummaryRepository(this.firestore);

  Future<void> createVisitorSummary(Map<String, dynamic> data) async {
    await firestore.collection('visitor_summaries').add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateVisitorSummary({
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    await firestore
        .collection('visitor_summaries')
        .doc(docId)
        .update(data);
  }

  Future<List<EmployeeUserModel>> fetchAdminUsers() async {
    final snapshot = await firestore
        .collection('users')
        .where('roleId', whereNotIn: ['2', '3'])
        .get();

    return snapshot.docs
        .map((doc) => EmployeeUserModel.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  Future<List<VisitorSummaryModel>> fetchVisitorSummaries() async {
    final user = getIt<HiveService>().getUser();

    if (user?.roleId == '0' || user?.roleId == '1') {
      // Super Admin and Admin can see all visitor summaries globally
      final snapshot = await firestore.collection('visitor_summaries').get();
      return snapshot.docs
          .map((e) => VisitorSummaryModel.fromJson(
              e.id, e.data()))
          .toList();
    } else {
      // Consultants can see summaries created by them OR for their assigned customers
      final custSnapshot = await firestore
          .collection('customers')
          .where('consultantId', isEqualTo: user?.userId)
          .get();
      final assignedCustomerIds =
          custSnapshot.docs.map((doc) => doc.id).toSet();

      final snapshot = await firestore.collection('visitor_summaries').get();

      return snapshot.docs.where((doc) {
        final data = doc.data();
        final consultantId = (data['consultantId'] ?? '').toString();
        final customerId = (data['customerId'] ?? '').toString();

        final isMyConsultantId =
            consultantId.isNotEmpty && consultantId == user?.userId;
        final isMyCustomer =
            customerId.isNotEmpty && assignedCustomerIds.contains(customerId);

        return isMyConsultantId || isMyCustomer;
      }).map((e) => VisitorSummaryModel.fromJson(
          e.id, e.data())).toList();
    }
  }

  Future<List<VisitorSummaryModel>> fetchVisitorSummariesForCustomer() async {
    final snapshot = await firestore
        .collection('visitor_summaries')
        .where('customerId', isEqualTo: getIt<HiveService>()
        .getCustomer()
        ?.customerId)
        .get();

    return snapshot.docs
        .map((e) => VisitorSummaryModel.fromJson(e.id, e.data()))
        .toList();
  }

  /// ✅ DELETE
  Future<void> deleteVisitorSummary(String id) async {
    try {
      await firestore.collection('visitor_summaries').doc(id).delete();
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}
