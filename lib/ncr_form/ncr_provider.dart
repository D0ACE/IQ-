import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iq_plus/common/utility/utility.dart';
import 'package:iq_plus/core/local_storage/hive_service.dart';
import 'package:iq_plus/di/service_locator.dart';
import 'package:iq_plus/features/auth/model/customer_model.dart';
import 'package:iq_plus/features/auth/model/user_model.dart';
import 'package:iq_plus/ncr_form/ncr/repository/ncr_repository.dart';

class NcrProvider extends ChangeNotifier {
  final NcrRepository _ncrRepository = NcrRepository();

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  List<Map<String, dynamic>> _ncrList = [];
  List<Map<String, dynamic>> get ncrList => _ncrList;

  /// 🔹 Start listening to NCRs
  void listenToNcrs() async {
    // ❗ Avoid multiple listeners
    _subscription?.cancel();

    final UserModel? userLoginDetails = getIt<HiveService>().getUser();
    final CustomerModel? customerLoginDetails = getIt<HiveService>().getCustomer();

    Set<String> assignedCustomerIds = {};

    if ((userLoginDetails?.userId ?? "").isNotEmpty &&
        Utility.isConsultant(userLoginDetails?.roleId ?? "")) {
      try {
        final custSnapshot = await FirebaseFirestore.instance
            .collection('customers')
            .where('consultantId', isEqualTo: userLoginDetails!.userId)
            .get();
        assignedCustomerIds = custSnapshot.docs.map((doc) => doc.id).toSet();
      } catch (e) {
        debugPrint("Error fetching consultant customers in NcrProvider: $e");
      }
    }

    _subscription = _ncrRepository.getNcrStream().listen((snapshot) {
      final consultantId = userLoginDetails?.userId ?? '';
      final isConsultant =
          (consultantId.isNotEmpty && Utility.isConsultant(userLoginDetails?.roleId ?? ""));
      final isCustomer = (customerLoginDetails?.customerId ?? "").isNotEmpty;
      final isEmployee = Utility.isEmployee(userLoginDetails?.roleId);
      final employeeCustomerId = userLoginDetails?.customerId ?? '';

      _ncrList = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
          'status': _normalizeStatus(data['status']),
        };
      }).where((ncr) {
        if (isCustomer) {
          return (ncr['customerId'] ?? ncr['companyId']) == customerLoginDetails?.customerId;
        } else if (isEmployee) {
          return (ncr['customerId'] ?? ncr['companyId']) == employeeCustomerId;
        } else if (isConsultant) {
          final ncrConsultantId = (ncr['consultantId'] ?? '').toString();
          final ncrCustomerId = (ncr['customerId'] ?? ncr['companyId'] ?? '').toString();

          final isMyConsultantId =
              ncrConsultantId.isNotEmpty && ncrConsultantId == consultantId;
          final isMyCustomer =
              ncrCustomerId.isNotEmpty && assignedCustomerIds.contains(ncrCustomerId);

          return isMyConsultantId || isMyCustomer;
        }
        return true;
      }).toList();

      // 🔹 Sort NCRs descending by createdAt (newest first)
      _ncrList.sort((a, b) {
        final aTime = _parseDateTime(a['createdAt']) ?? _parseDateTime(a['updatedAt']);
        final bTime = _parseDateTime(b['createdAt']) ?? _parseDateTime(b['updatedAt']);
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      notifyListeners();
    });
  }

  DateTime? _parseDateTime(dynamic date) {
    if (date == null) return null;
    if (date is Timestamp) return date.toDate();
    if (date is DateTime) return date;
    if (date is String) return DateTime.tryParse(date);
    return null;
  }

  /// 🔹 Update status in Firestore and locally
  Future<void> updateStatus(String ncrId, String status) async {
    await _ncrRepository.updateNcrStatus(ncrId, status);

    final index = _ncrList.indexWhere((e) => e['id'] == ncrId);
    if (index != -1) {
      _ncrList[index]['status'] = _normalizeStatus(status);
      notifyListeners();
    }
  }

  /// 🔹 Delete NCR
  Future<void> deleteNcr(String ncrId) async {
    await _ncrRepository.deleteNcrForm(ncrId);
    // Stream listener will handle local list update automatically
  }

  String _normalizeStatus(dynamic status) {
    final s = status?.toString().toLowerCase().trim() ?? '';

    if (s == 'open') return 'open';
    if (s == 'in progress') return 'in_progress';
    if (s == 'in_progress') return 'in_progress';
    if (s == 'closed') return 'closed';

    return 'open';
  }

  /// 🔹 Dashboard getters
  int get openCount =>
      _ncrList.where((e) => e['status'] == 'open').length;

  int get inProgressCount =>
      _ncrList.where((e) => e['status'] == 'in_progress').length;

  int get closedCount =>
      _ncrList.where((e) => e['status'] == 'closed').length;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
