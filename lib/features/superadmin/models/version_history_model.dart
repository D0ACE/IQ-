import 'package:cloud_firestore/cloud_firestore.dart';

class VersionHistoryModel {
  final String id;
  final String docId;
  final String versionNo;
  final String changeDescription;
  final String performedBy;
  final DateTime performedDate;
  final String? approvedBy;
  final DateTime? approvedDate;
  final String? rejectionReason;
  final String? rejectedBy;
  final DateTime? rejectedDate;
  final String status;
  final String? docTitle; // 👈 Added for global listing
  final String? customerId; // 👈 Added for customer filtering

  VersionHistoryModel({
    required this.id,
    required this.docId,
    required this.versionNo,
    required this.changeDescription,
    required this.performedBy,
    required this.performedDate,
    this.approvedBy,
    this.approvedDate,
    this.rejectionReason,
    this.rejectedBy,
    this.rejectedDate,
    required this.status,
    this.docTitle,
    this.customerId,
  });

  factory VersionHistoryModel.fromFirestore(
    DocumentSnapshot doc, {
    String? docTitle,
    String? customerId,
  }) {
    final data = doc.data() as Map<String, dynamic>;
    return VersionHistoryModel(
      id: doc.id,
      docId: data['docId'] ?? '',
      versionNo: data['versionNo'] ?? '',
      changeDescription: data['changeDescription'] ?? '',
      performedBy: data['performedBy'] ?? '',
      performedDate: (data['performedDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      approvedBy: data['approvedBy'],
      approvedDate: (data['approvedDate'] as Timestamp?)?.toDate(),
      rejectionReason: data['rejectionReason'] ?? data['rejection_reason'],
      rejectedBy: data['rejectedBy'] ?? data['rejected_by'],
      rejectedDate: (data['rejectedDate'] as Timestamp?)?.toDate() ?? (data['rejected_date'] as Timestamp?)?.toDate(),
      status: data['status'] ?? 'draft',
      docTitle: docTitle ?? data['docTitle'],
      customerId: customerId ?? data['customerId'] ?? data['customer_id'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'docId': docId,
      'versionNo': versionNo,
      'changeDescription': changeDescription,
      'performedBy': performedBy,
      'performedDate': FieldValue.serverTimestamp(),
      'approvedBy': approvedBy,
      'approvedDate': approvedDate != null ? Timestamp.fromDate(approvedDate!) : null,
      'rejectionReason': rejectionReason,
      'rejectedBy': rejectedBy,
      'rejectedDate': rejectedDate != null ? Timestamp.fromDate(rejectedDate!) : null,
      'status': status,
      'docTitle': docTitle,
      'customerId': customerId,
    };
  }
}
