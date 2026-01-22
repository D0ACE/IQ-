import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iq_plus/ncr_form/ncr/model/ncr_form_model.dart';


class NcrRepository {
  /// 🔹 Reference to NCR forms collection
  final CollectionReference ncrCollection =
      FirebaseFirestore.instance.collection('ncr_forms');

  /// Save new NCR
  Future<void> saveNcrForm(NcrFormModel model) async {
    await ncrCollection.add(model.toMap());
  }

  /// Update NCR Status
  Future<void> updateStatus(String docId, String status) async {
    await ncrCollection.doc(docId).update({'status': status});
  }

  /// Stream NCRs (optionally filtered by consultantId)
  Stream<QuerySnapshot<Map<String, dynamic>>> getNcrStream({String? consultantId}) {
    if (consultantId != null && consultantId.isNotEmpty) {
      return ncrCollection
          .where('consultantId', isEqualTo: consultantId)
          .snapshots()
          .map((snapshot) => snapshot as QuerySnapshot<Map<String, dynamic>>);
    } else {
      return ncrCollection
          .snapshots()
          .map((snapshot) => snapshot as QuerySnapshot<Map<String, dynamic>>);
    }
  }
}
