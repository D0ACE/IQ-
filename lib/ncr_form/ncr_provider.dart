import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iq_plus/ncr_form/ncr/repository/ncr_repository.dart';

class NcrProvider extends ChangeNotifier {
  final NcrRepository _ncrRepository = NcrRepository();

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  List<Map<String, dynamic>> _ncrList = [];
  List<Map<String, dynamic>> get ncrList => _ncrList;

  /// 🔹 Start listening to NCRs
  void listenToNcrs() {
    // ❗ Avoid multiple listeners
    _subscription?.cancel();

    _subscription = _ncrRepository
        .getNcrStream()
        .listen((snapshot) {
      _ncrList = snapshot.docs.map((doc) {
  final data = doc.data();

  return {
    'id': doc.id,
    ...data,
    'status': _normalizeStatus(data['status']),
  };
}).toList();


      notifyListeners();
    });
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


  //   /// 🔹 Update status in Firestore and locally
  // Future<void> updateStatus(String ncrId, String status) async {
  //   // Update Firestore
  //   await _ncrRepository.updateStatus(ncrId, status);

  //   // Update locally
  //   final index = _ncrList.indexWhere((e) => e['id'] == ncrId);
  //   if (index != -1) {
  //     _ncrList[index]['status'] = status;
  //     notifyListeners();
  //   }
  // }

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
