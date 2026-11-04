import '../models/rating.dart';

abstract class RatingRepository {
  Future<List<Rating>> getRatingsForPeriod(String period);
  Future<void> saveRating(Rating rating);
  Future<void> saveRatings(List<Rating> ratings);
  Future<void> deleteRatingsForSupplier(String supplierId);
}
