import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/supplier.dart';
import 'supplier_repository.dart';

class FirestoreSupplierRepository implements SupplierRepository {
  FirestoreSupplierRepository(this._firestore);

  final FirebaseFirestore _firestore;
  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('supply_suppliers');

  Map<String, dynamic> _json(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = Map<String, dynamic>.from(doc.data() ?? <String, dynamic>{});
    final createdAt = data['createdAt'];
    if (createdAt is Timestamp) {
      data['createdAt'] = createdAt.toDate().toIso8601String();
    }
    data['id'] ??= doc.id;
    return data;
  }

  @override
  Future<List<Supplier>> getAllSuppliers() async {
    final snapshot = await _collection
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => Supplier.fromJson(_json(doc))).toList();
  }

  @override
  Future<Supplier?> getSupplierById(String id) async {
    final doc = await _collection.doc(id).get();
    return doc.exists ? Supplier.fromJson(_json(doc)) : null;
  }

  @override
  Future<void> addSupplier(Supplier supplier) =>
      _collection.doc(supplier.id).set(supplier.toJson());

  @override
  Future<void> updateSupplier(Supplier supplier) => _collection
      .doc(supplier.id)
      .set(supplier.toJson(), SetOptions(merge: true));

  @override
  Future<void> deleteSupplier(String id) => _collection.doc(id).delete();

  @override
  Future<String> getNextSupplierId() async {
    final snapshot = await _collection.get();
    var maxNumber = 0;
    final regex = RegExp(r'MSP/(\d+)', caseSensitive: false);
    for (final doc in snapshot.docs) {
      final match = regex.firstMatch((doc.data()['id'] ?? doc.id).toString());
      final number = int.tryParse(match?.group(1) ?? '');
      if (number != null && number > maxNumber) maxNumber = number;
    }
    return 'MSP/${(maxNumber + 1).toString().padLeft(2, '0')}';
  }
}
