import 'package:cloud_firestore/cloud_firestore.dart';

class DocumentModel {
  final String docId; // Firestore document ID
  final int id; // Auto-increment ID
  final String title;
  final String fileUrl;
  final String fileName;
  final String filePath; // Path in Supabase bucket
  final String fileType;
  final DateTime createdAt;
  final String createdBy; // User email
  final String createdByUserId; // User ID
  final String status; // 'draft' or 'active'
  final String version; // Always 'V1' per requirement
  final String currentVersion; // The series (V1, V2, V3...)
  final String? reviewedBy;
  final DateTime? reviewedDate;
  final String? rejectionReason;
  final String? rejectedBy;
  final DateTime? rejectedDate;
  final String? content; // JSON Delta for rich text
  final String? customerId; // Linked customer ID

  DocumentModel({
    required this.docId,
    required this.id,
    required this.title,
    required this.fileUrl,
    required this.fileName,
    required this.filePath,
    required this.fileType,
    required this.createdAt,
    required this.createdBy,
    required this.createdByUserId,
    required this.status,
    required this.version,
    this.reviewedBy,
    this.reviewedDate,
    this.rejectionReason,
    this.rejectedBy,
    this.rejectedDate,
    this.content,
    this.customerId,
    required this.currentVersion,
  });

  factory DocumentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DocumentModel(
      docId: doc.id,
      id: data['id'] ?? 0,
      title: data['title'] ?? '',
      fileUrl: data['file_url'] ?? '',
      fileName: data['file_name'] ?? '',
      filePath: data['file_path'] ?? '',
      fileType: data['file_type'] ?? '',
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['created_by'] ?? '',
      createdByUserId: data['created_by_user_id'] ?? '',
      status: data['status'] ?? 'draft',
      version: data['version'] ?? 'V1',
      currentVersion: data['current_version'] ?? 'V1',
      reviewedBy: data['reviewed_by'],
      reviewedDate: (data['reviewed_date'] as Timestamp?)?.toDate(),
      rejectionReason: data['rejection_reason'] ?? data['rejectionReason'],
      rejectedBy: data['rejected_by'] ?? data['rejectedBy'],
      rejectedDate: (data['rejected_date'] as Timestamp?)?.toDate() ?? (data['rejectedDate'] as Timestamp?)?.toDate(),
      content: data['content'],
      customerId: data['customer_id'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'title': title,
      'file_url': fileUrl,
      'file_name': fileName,
      'file_path': filePath,
      'file_type': fileType,
      'created_at': FieldValue.serverTimestamp(),
      'created_by': createdBy,
      'created_by_user_id': createdByUserId,
      'status': status,
      'version': version,
      'current_version': currentVersion,
      'reviewed_by': reviewedBy,
      'reviewed_date': reviewedDate != null ? Timestamp.fromDate(reviewedDate!) : null,
      'rejection_reason': rejectionReason,
      'rejected_by': rejectedBy,
      'rejected_date': rejectedDate != null ? Timestamp.fromDate(rejectedDate!) : null,
      'content': content,
      'customer_id': customerId,
    };
  }
}
