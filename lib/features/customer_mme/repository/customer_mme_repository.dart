import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iq_plus/features/customer_mme/models/mme_model_req.dart';

class CustomerMMERepository {
  final FirebaseFirestore firestore;

  CustomerMMERepository(this.firestore);

  Future<int> _getNextId() async {
    final ref = firestore.collection('counters').doc('customer_mme');

    return firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      int lastId = snap.exists ? snap['lastId'] : 0;
      int newId = lastId + 1;
      tx.set(ref, {'lastId': newId});
      return newId;
    });
  }

  Future<void> createMME({
    required String customerId,
    required String serialNumber,
    required String deviceName,
    required DateTime lastDate,
    required DateTime nextDate,
  }) async {
    final id = await _getNextId();

    final mme = CustomerMMEModel(
      id: id.toString(),
      customerId: customerId,
      serialNumber: serialNumber,
      deviceName: deviceName,
      lastCalibrationDate: lastDate,
      nextCalibrationDate: nextDate,
    );

    await firestore.collection('customer_mme').add(mme.toMap());
  }

  Future<List<CustomerMMEModel>> fetchCustomerMME(String customerId) async {
    final snapshot = await firestore
        .collection('customer_mme')
        .where('customerId', isEqualTo: customerId)
        .get();

    List<CustomerMMEModel> customerMMEList=snapshot.docs
        .map((doc) => CustomerMMEModel.fromMap(doc.id,doc.data()))
        .toList();
    customerMMEList.sort((a, b) => a.id.compareTo(b.id));


    return customerMMEList;
  }


  Future<void> deleteMME(String docId) async {
    await firestore
        .collection('customer_mme')
        .doc(docId)
        .delete();
  }

  Future<void> createMMEBulk(
      String customerId,
      List<CustomerMMEModel> list,
      ) async {
    for (final mme in list) {
      await createMME(
        customerId: customerId,
        serialNumber: mme.serialNumber,
        deviceName: mme.deviceName,
        lastDate: mme.lastCalibrationDate,
        nextDate: mme.nextCalibrationDate,
      );
    }
  }

  Future<void> updateMME({
    required String docId,
    required String customerId,
    required String mmeId,
    required String serial,
    required String device,
    required DateTime lastDate,
    required DateTime nextDate,
  }) async {
    await firestore
        .collection('customer_mme').doc(docId).update({
      'serialNumber': serial,
      'deviceName': device,
      'lastCalibrationDate': Timestamp.fromDate(lastDate).toDate(),
      'nextCalibrationDate': Timestamp.fromDate(nextDate).toDate(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }


}

