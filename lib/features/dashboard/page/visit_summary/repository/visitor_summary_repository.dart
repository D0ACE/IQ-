import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:iq_plus/common/utility/utility.dart';
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

    List<VisitorSummaryModel> result = [];

    if (user?.roleId == '0' || user?.roleId == '1') {
      // Super Admin and Admin can see all visitor summaries globally
      final snapshot = await firestore.collection('visitor_summaries').get();
      result = snapshot.docs
          .map((e) => VisitorSummaryModel.fromJson(
              e.id, e.data()))
          .toList();
    } else if (user != null && Utility.isEmployee(user.roleId)) {
      // Employees can only see summaries for their assigned customer
      final customerId = user.customerId ?? '';
      if (customerId.isEmpty) return [];
      final snapshot = await firestore
          .collection('visitor_summaries')
          .where('customerId', isEqualTo: customerId)
          .get();
      result = snapshot.docs
          .map((e) => VisitorSummaryModel.fromJson(e.id, e.data()))
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

      result = snapshot.docs.where((doc) {
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

    return _sortVisitorSummaries(result);
  }

  Future<List<VisitorSummaryModel>> fetchVisitorSummariesForCustomer() async {
    final snapshot = await firestore
        .collection('visitor_summaries')
        .where('customerId', isEqualTo: getIt<HiveService>()
        .getCustomer()
        ?.customerId)
        .get();

    final result = snapshot.docs
        .map((e) => VisitorSummaryModel.fromJson(e.id, e.data()))
        .toList();

    return _sortVisitorSummaries(result);
  }

  /// 🔹 Sort visitor summaries descending by createdAt (newest first)
  List<VisitorSummaryModel> _sortVisitorSummaries(List<VisitorSummaryModel> list) {
    list.sort((a, b) {
      final aTime = a.createdAt?.toDate() ?? _parseVisitDate(a.visitDate);
      final bTime = b.createdAt?.toDate() ?? _parseVisitDate(b.visitDate);
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime);
    });
    return list;
  }

  DateTime? _parseVisitDate(String? visitDate) {
    if (visitDate == null || visitDate.trim().isEmpty) return null;
    try {
      return DateFormat('dd MMM yyyy').parse(visitDate.trim());
    } catch (_) {
      try {
        return DateTime.parse(visitDate.trim());
      } catch (_) {
        return null;
      }
    }
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
