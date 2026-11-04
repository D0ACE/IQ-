/// Pure Dart class responsible for calculating Quality Rating (QR),
/// Delivery Rating (DR), Total score, and evaluation grades according to
/// Supplier Rating Form F-7.4-03/R0.
class RatingCalculator {
  /// Maps delivery delay in days to delivery percentage score (0 to 100).
  ///
  /// Table:
  /// delay 0       -> 100
  /// 1-2           -> 90
  /// 3-4           -> 80
  /// 5-6           -> 60
  /// 7-8           -> 55
  /// 9-10          -> 50
  /// 11-12         -> 40
  /// 13-15         -> 30
  /// 16-20         -> 20
  /// more than 20  -> 0
  static int getDeliveryPercentage(int delayDays) {
    if (delayDays <= 0) return 100;
    if (delayDays <= 2) return 90;
    if (delayDays <= 4) return 80;
    if (delayDays <= 6) return 60;
    if (delayDays <= 8) return 55;
    if (delayDays <= 10) return 50;
    if (delayDays <= 12) return 40;
    if (delayDays <= 15) return 30;
    if (delayDays <= 20) return 20;
    return 0;
  }

  /// Calculates Quality Rating (QR) max 70.
  /// Formula: 70 * (Qty Received - Qty Rejected) / Qty Received, rounded to nearest whole number.
  /// Returns null if [qtyReceived] is null, 0, or negative (no supply data).
  static int? calculateQR({num? qtyReceived, num? qtyRejected}) {
    if (qtyReceived == null || qtyReceived <= 0) {
      return null;
    }
    final rejected = qtyRejected ?? 0;
    final accepted = qtyReceived - rejected;
    if (accepted <= 0) {
      return 0;
    }
    final ratio = accepted / qtyReceived;
    final score = (70.0 * ratio).round();
    return score.clamp(0, 70);
  }

  /// Calculates Delivery Rating (DR) max 30.
  /// Formula: 30 * DeliveryPercentage / 100, rounded to nearest whole number.
  /// Returns null if [delayDays] is null.
  static int? calculateDR({int? delayDays}) {
    if (delayDays == null) {
      return null;
    }
    final percentage = getDeliveryPercentage(delayDays);
    final score = (30.0 * percentage / 100.0).round();
    return score.clamp(0, 30);
  }

  /// Calculates Total rating score (max 100).
  /// Formula: QR + DR.
  /// If either QR or DR is null (e.g. no supply data in period), returns null.
  static int? calculateTotal({int? qr, int? dr}) {
    if (qr == null || dr == null) {
      return null;
    }
    return (qr + dr).clamp(0, 100);
  }

  /// Grade classification:
  /// >= 90: "Excellent" (green)
  /// 80-89: "Good" (blue)
  /// 60-79: "Average" (orange)
  /// < 60:  "Poor / Review" (red)
  /// Returns null if total is null.
  static String? getGrade(int? total) {
    if (total == null) return null;
    if (total >= 90) return 'Excellent';
    if (total >= 80) return 'Good';
    if (total >= 60) return 'Average';
    return 'Poor / Review';
  }

  /// Determines whether automatic suggestion for poor rating remarks should be triggered.
  static bool isPoor(int? total) {
    if (total == null) return false;
    return total < 60;
  }
}
