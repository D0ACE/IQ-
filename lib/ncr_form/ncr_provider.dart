import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iq_plus/ncr_form/ncr/repository/ncr_repository.dart';


class NcrProvider extends ChangeNotifier {
  final NcrRepository _ncrRepository = NcrRepository();

  List<Map<String, dynamic>> _ncrList = [];
  List<Map<String, dynamic>> get ncrList => _ncrList;

  /// 🔹 Start listening to NCRs
  void listenToNcrs({String? consultantId}) {
    _ncrRepository.getNcrStream(consultantId: consultantId).listen(
      (QuerySnapshot<Map<String, dynamic>> snapshot) {
        _ncrList = snapshot.docs.map((doc) {
          return {
            'id': doc.id,
            ...doc.data(),
          };
        }).toList();

        notifyListeners();
      },
    );
  }

  /// 🔹 Update status in Firestore and locally
  Future<void> updateStatus(String ncrId, String status) async {
    // Update Firestore
    await _ncrRepository.updateStatus(ncrId, status);

    // Update locally
    final index = _ncrList.indexWhere((e) => e['id'] == ncrId);
    if (index != -1) {
      _ncrList[index]['status'] = status;
      notifyListeners();
    }
  }

  /// 🔹 Dashboard getters
  int get openCount => _ncrList.where((e) => e['status'] == 'open').length;

  int get inProgressCount =>
      _ncrList.where((e) => e['status'] == 'in_progress').length;

  int get closedCount => _ncrList.where((e) => e['status'] == 'closed').length;
}
