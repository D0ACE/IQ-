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
  final String status;
  final String? assignedReviewerName;

  VersionHistoryModel({
    required this.id,
    required this.docId,
    required this.versionNo,
    required this.changeDescription,
    required this.performedBy,
    required this.performedDate,
    this.approvedBy,
    this.approvedDate,
    required this.status,
    this.assignedReviewerName,
  });

  factory VersionHistoryModel.fromFirestore(DocumentSnapshot doc) {
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
      status: data['status'] ?? 'draft',
      assignedReviewerName: data['assignedReviewerName'],
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
      'status': status,
      'assignedReviewerName': assignedReviewerName,
    };
  }
}
