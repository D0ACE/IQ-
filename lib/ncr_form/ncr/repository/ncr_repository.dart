import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iq_plus/common/utility/utility.dart';
import 'package:iq_plus/core/local_storage/hive_service.dart';
import 'package:iq_plus/di/service_locator.dart';
import 'package:iq_plus/features/auth/model/customer_model.dart';
import 'package:iq_plus/features/auth/model/user_model.dart';
import 'package:iq_plus/ncr_form/ncr/model/ncr_form_model.dart';


class NcrRepository {
  /// 🔹 Reference to NCR forms collection
  final CollectionReference ncrCollection =
      FirebaseFirestore.instance.collection('ncr_forms');

  /// Save new NCR
  Future<void> saveNcrForm(NcrFormModel model) async {
    await ncrCollection.add(model.toMap());
  }

  /// Update full NCR or partial data
  Future<void> updateNcrForm(String docId, Map<String, dynamic> data) async {
    await ncrCollection.doc(docId).update(data);
  }

  //Update NCR Status
   Future<void> updateNcrStatus(String docId, String status) async {

  final s = status.toLowerCase().trim();

  await ncrCollection.doc(docId).update({
    'status': s,
    'updatedAt': Timestamp.now(),
  });
}

  /// Delete NCR form
  Future<void> deleteNcrForm(String docId) async {
    await ncrCollection.doc(docId).delete();
  }



  /// Stream NCRs (optionally filtered by consultantId)
  Stream<QuerySnapshot<Map<String, dynamic>>> getNcrStream() {
    final UserModel? userLoginDetails = getIt<HiveService>().getUser();
    final CustomerModel? customerLoginDetails = getIt<HiveService>().getCustomer();
    if ((customerLoginDetails?.customerId??"").isNotEmpty) {
      return ncrCollection
          .where('customerId', isEqualTo: customerLoginDetails?.customerId)
          .snapshots()
          .map((snapshot) => snapshot as QuerySnapshot<Map<String, dynamic>>);
    }else  if ((userLoginDetails?.userId??"").isNotEmpty && Utility.isConsultant(userLoginDetails?.roleId??"")) {
      return ncrCollection
          .where('consultantId', isEqualTo: userLoginDetails?.userId)
          .snapshots()
          .map((snapshot) => snapshot as QuerySnapshot<Map<String, dynamic>>);
    } else {
      return ncrCollection
          .snapshots()
          .map((snapshot) => snapshot as QuerySnapshot<Map<String, dynamic>>);
    }
  }

  Future<int> getNCRCountOnce() async {
    final snapshot = await getNcrStream().first;
    return snapshot.docs.length;
  }
}
