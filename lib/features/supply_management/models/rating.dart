class Rating {
  final String id;
  final String supplierId;
  final String period; // e.g. "2025-2026"
  final num? qtyReceived;
  final num? qtyRejected;
  final int? delayDays;
  final int? qr; // Quality Rating (max 70)
  final int? dr; // Delivery Rating (max 30)
  final int? total; // QR + DR (max 100)
  final String? remarks;
  final DateTime updatedAt;

  Rating({
    required this.id,
    required this.supplierId,
    required this.period,
    this.qtyReceived,
    this.qtyRejected,
    this.delayDays,
    this.qr,
    this.dr,
    this.total,
    this.remarks,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'supplierId': supplierId,
      'period': period,
      'qtyReceived': qtyReceived,
      'qtyRejected': qtyRejected,
      'delayDays': delayDays,
      'qr': qr,
      'dr': dr,
      'total': total,
      'remarks': remarks,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      id: json['id'] as String? ?? '',
      supplierId: json['supplierId'] as String? ?? '',
      period: json['period'] as String? ?? '',
      qtyReceived: json['qtyReceived'] as num?,
      qtyRejected: json['qtyRejected'] as num?,
      delayDays: json['delayDays'] as int?,
      qr: json['qr'] as int?,
      dr: json['dr'] as int?,
      total: json['total'] as int?,
      remarks: json['remarks'] as String?,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Rating copyWith({
    String? id,
    String? supplierId,
    String? period,
    num? qtyReceived,
    num? qtyRejected,
    int? delayDays,
    int? qr,
    int? dr,
    int? total,
    String? remarks,
    DateTime? updatedAt,
  }) {
    return Rating(
      id: id ?? this.id,
      supplierId: supplierId ?? this.supplierId,
      period: period ?? this.period,
      qtyReceived: qtyReceived ?? this.qtyReceived,
      qtyRejected: qtyRejected ?? this.qtyRejected,
      delayDays: delayDays ?? this.delayDays,
      qr: qr ?? this.qr,
      dr: dr ?? this.dr,
      total: total ?? this.total,
      remarks: remarks ?? this.remarks,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
