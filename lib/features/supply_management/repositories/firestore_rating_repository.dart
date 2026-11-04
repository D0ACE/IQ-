import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rating.dart';
import 'rating_repository.dart';

class FirestoreRatingRepository implements RatingRepository {
  FirestoreRatingRepository(this._firestore);

  final FirebaseFirestore _firestore;
  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('supply_ratings');

  Rating _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = Map<String, dynamic>.from(doc.data() ?? <String, dynamic>{});
    final updatedAt = data['updatedAt'];
    if (updatedAt is Timestamp) {
      data['updatedAt'] = updatedAt.toDate().toIso8601String();
    }
    data['id'] ??= doc.id;
    return Rating.fromJson(data);
  }

  @override
  Future<List<Rating>> getRatingsForPeriod(String period) async {
    final snapshot = await _collection.where('period', isEqualTo: period).get();
    return snapshot.docs.map(_fromDoc).toList();
  }

  @override
  Future<void> saveRating(Rating rating) => saveRatings([rating]);

  @override
  Future<void> saveRatings(List<Rating> ratings) async {
    final batch = _firestore.batch();
    for (final rating in ratings) {
      batch.set(
        _collection.doc('${rating.supplierId}_${rating.period}'),
        rating.toJson(),
      );
    }
    await batch.commit();
  }

  @override
  Future<void> deleteRatingsForSupplier(String supplierId) async {
    final snapshot = await _collection
        .where('supplierId', isEqualTo: supplierId)
        .get();
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
