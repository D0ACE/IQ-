import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/rating.dart';
import '../models/supplier.dart';
import '../repositories/rating_repository.dart';
import '../services/rating_calculator.dart';
import 'supplier_provider.dart';

class RatingProvider extends ChangeNotifier {
  final RatingRepository repository;

  String _selectedPeriod = _calculateCurrentFinancialYear();
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSaving = false;

  // Key is supplierId
  final Map<String, Rating> _ratingsMap = {};

  RatingProvider({required this.repository});

  String get selectedPeriod => _selectedPeriod;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  static String _calculateCurrentFinancialYear() {
    final now = DateTime.now();
    final year = now.year;
    if (now.month >= 4) {
      return '$year-${year + 1}';
    } else {
      return '${year - 1}-$year';
    }
  }

  static List<String> getAvailablePeriods() {
    final now = DateTime.now();
    final currentYear = now.month >= 4 ? now.year : now.year - 1;
    final periods = <String>[];
    for (int y = currentYear + 1; y >= currentYear - 3; y--) {
      periods.add('$y-${y + 1}');
    }
    return periods;
  }

  Rating? getRating(String supplierId) => _ratingsMap[supplierId];

  Future<void> loadRatingsForPeriod(
    String period,
    List<Supplier> approvedSuppliers,
  ) async {
    _selectedPeriod = period;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final savedRatings = await repository.getRatingsForPeriod(period);
      _ratingsMap.clear();

      for (final r in savedRatings) {
        _ratingsMap[r.supplierId] = r;
      }

      // Initialize empty rating entries for approved suppliers that don't have one yet
      for (final s in approvedSuppliers) {
        if (!_ratingsMap.containsKey(s.id)) {
          _ratingsMap[s.id] = Rating(
            id: const Uuid().v4(),
            supplierId: s.id,
            period: period,
            qtyReceived: null,
            qtyRejected: null,
            delayDays: null,
            qr: null,
            dr: null,
            total: null,
            remarks: null,
            updatedAt: DateTime.now(),
          );
        }
      }
    } catch (e) {
      _errorMessage = 'Failed to load ratings: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateQtyReceived(String supplierId, num? qtyReceived) {
    final current = _ratingsMap[supplierId];
    final updated = _recomputeRating(
      current: current,
      supplierId: supplierId,
      qtyReceived: qtyReceived,
      qtyRejected: current?.qtyRejected,
      delayDays: current?.delayDays,
      remarks: current?.remarks,
    );
    _ratingsMap[supplierId] = updated;
    notifyListeners();
  }

  void updateQtyRejected(String supplierId, num? qtyRejected) {
    final current = _ratingsMap[supplierId];
    final updated = _recomputeRating(
      current: current,
      supplierId: supplierId,
      qtyReceived: current?.qtyReceived,
      qtyRejected: qtyRejected,
      delayDays: current?.delayDays,
      remarks: current?.remarks,
    );
    _ratingsMap[supplierId] = updated;
    notifyListeners();
  }

  void updateDelayDays(String supplierId, int? delayDays) {
    final current = _ratingsMap[supplierId];
    final updated = _recomputeRating(
      current: current,
      supplierId: supplierId,
      qtyReceived: current?.qtyReceived,
      qtyRejected: current?.qtyRejected,
      delayDays: delayDays,
      remarks: current?.remarks,
    );
    _ratingsMap[supplierId] = updated;
    notifyListeners();
  }

  void updateRemarks(String supplierId, String? remarks) {
    final current = _ratingsMap[supplierId];
    if (current == null) return;
    _ratingsMap[supplierId] = current.copyWith(
      remarks: remarks,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
  }

  /// Toggle Non-Existing status for a vendor.
  /// Sets remark "NON-EXISTING" and moves supplier status to "Non-existing".
  Future<void> toggleNonExisting(
    String supplierId,
    bool isNonExisting,
    SupplierProvider supplierProvider,
  ) async {
    final current = _ratingsMap[supplierId];
    final currentRemarks = current?.remarks ?? '';

    String newRemarks;
    if (isNonExisting) {
      if (currentRemarks.isEmpty) {
        newRemarks = 'NON-EXISTING';
      } else if (!currentRemarks.contains('NON-EXISTING')) {
        newRemarks = 'NON-EXISTING - $currentRemarks';
      } else {
        newRemarks = currentRemarks;
      }
      await supplierProvider.updateStatus(supplierId, 'Non-existing');
    } else {
      newRemarks = currentRemarks.replaceAll('NON-EXISTING', '').trim();
      if (newRemarks.startsWith('- ')) {
        newRemarks = newRemarks.substring(2).trim();
      }
      await supplierProvider.updateStatus(supplierId, 'Approved');
    }

    if (current != null) {
      _ratingsMap[supplierId] = current.copyWith(
        remarks: newRemarks,
        updatedAt: DateTime.now(),
      );
    }
    notifyListeners();
  }

  Rating _recomputeRating({
    Rating? current,
    required String supplierId,
    num? qtyReceived,
    num? qtyRejected,
    int? delayDays,
    String? remarks,
  }) {
    final qr = RatingCalculator.calculateQR(
      qtyReceived: qtyReceived,
      qtyRejected: qtyRejected,
    );
    final dr = RatingCalculator.calculateDR(delayDays: delayDays);
    final total = RatingCalculator.calculateTotal(qr: qr, dr: dr);

    String? updatedRemarks = remarks;
    if (total != null && RatingCalculator.isPoor(total)) {
      if (updatedRemarks == null || updatedRemarks.trim().isEmpty) {
        updatedRemarks = 'Review or re-evaluate';
      } else if (!updatedRemarks.contains('Review or re-evaluate')) {
        updatedRemarks = '$updatedRemarks (Review or re-evaluate)';
      }
    }

    return Rating(
      id: current?.id ?? const Uuid().v4(),
      supplierId: supplierId,
      period: _selectedPeriod,
      qtyReceived: qtyReceived,
      qtyRejected: qtyRejected,
      delayDays: delayDays,
      qr: qr,
      dr: dr,
      total: total,
      remarks: updatedRemarks,
      updatedAt: DateTime.now(),
    );
  }

  Future<void> saveAllRatings() async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final listToSave = _ratingsMap.values.toList();
      await repository.saveRatings(listToSave);
    } catch (e) {
      _errorMessage = 'Failed to save ratings: $e';
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Calculates average total score across vendors who have valid ratings in the period
  double? getAverageTotal() {
    final scoredRatings = _ratingsMap.values
        .where((r) => r.total != null)
        .toList();
    if (scoredRatings.isEmpty) return null;
    final sum = scoredRatings.fold<int>(0, (prev, r) => prev + (r.total ?? 0));
    return sum / scoredRatings.length;
  }
}
