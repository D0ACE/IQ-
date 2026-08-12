import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iq_plus/core/local_storage/hive_service.dart';
import 'package:iq_plus/di/service_locator.dart';
import 'package:iq_plus/features/superadmin/models/document_model.dart';
import 'package:iq_plus/features/superadmin/models/version_history_model.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:iq_plus/core/supabase/supabase_config.dart';

class DocumentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _supabase = Supabase.instance.client;

  Future<List<DocumentModel>> getDocuments({String? userId, bool isConsultant = false, String? customerId}) async {
    Query query = _firestore.collection('documents');

    if (isConsultant && userId != null) {
      query = query.where(
        Filter.or(
          Filter('created_by_user_id', isEqualTo: userId),
          Filter('assigned_reviewer_id', isEqualTo: userId),
        ),
      );
    } else if (customerId != null) {
      query = query.where('customer_id', isEqualTo: customerId).where('status', isEqualTo: 'active');
    }

    final snapshot = await query.orderBy('created_at', descending: true).get();
    return snapshot.docs.map((doc) => DocumentModel.fromFirestore(doc)).toList();
  }

  Future<int> _getNextId() async {
    final counterRef = _firestore.collection('metadata').doc('document_counter');
    
    return await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(counterRef);

      if (!snapshot.exists) {
        transaction.set(counterRef, {'count': 1});
        return 1;
      }

      int newCount = (snapshot.data()?['count'] ?? 0) + 1;
      transaction.update(counterRef, {'count': newCount});
      return newCount;
    });
  }

  Future<String> _getCurrentVersionFromHistory(String docId) async {
    try {
      final historySnapshot = await _firestore
          .collection('documents')
          .doc(docId)
          .collection('version_history')
          .orderBy('performedDate', descending: true)
          .limit(1)
          .get();

      if (historySnapshot.docs.isNotEmpty) {
        return historySnapshot.docs.first.data()['versionNo'] as String? ?? 'V1';
      }
    } catch (e) {
      developer.log("Error fetching current version: $e");
    }
    return 'V1';
  }

  Future<String> _calculateNextVersionFromHistory(String docId) async {
    try {
      final lastVersionStr = await _getCurrentVersionFromHistory(docId);
      if (lastVersionStr.startsWith('V')) {
        int versionNum = int.parse(lastVersionStr.substring(1));
        return 'V${versionNum + 1}';
      }
    } catch (e) {
      developer.log("Error calculating next version: $e");
    }
    return 'V1'; 
  }

  Future<void> _addVersionHistory({
    required String docId,
    required String versionNo,
    required String changeDescription,
    required String performedBy,
    String? approvedBy,
    DateTime? approvedDate,
    required String status,
    String? assignedReviewerName,
  }) async {
    final historyRef = _firestore.collection('documents').doc(docId).collection('version_history');
    await historyRef.add({
      'docId': docId,
      'versionNo': versionNo,
      'changeDescription': changeDescription,
      'performedBy': performedBy,
      'performedDate': FieldValue.serverTimestamp(),
      'approvedBy': approvedBy,
      'approvedDate': approvedDate != null ? Timestamp.fromDate(approvedDate) : null,
      'status': status,
      'assignedReviewerName': assignedReviewerName,
    });
  }

  Future<void> addDocument({
    required String title,
    required File file,
    String? customerId,
    String? assignedReviewerId,
    String? assignedReviewerName,
  }) async {
    final fileName = p.basename(file.path);
    final extension = p.extension(file.path);
    final user = getIt<HiveService>().getUser();
    final userEmail = user?.email ?? 'unknown';
    final userId = user?.userId ?? 'unknown';
    
    final String supabasePath = 'policies/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    await _supabase.storage.from(SupabaseConfig.bucketName).upload(
      supabasePath,
      file,
      fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
    );
    
    final String fileUrl = _supabase.storage.from(SupabaseConfig.bucketName).getPublicUrl(supabasePath);

    final nextId = await _getNextId();

    await _firestore.collection('documents').add({
      'id': nextId,
      'title': title,
      'file_url': fileUrl,
      'file_name': fileName,
      'file_path': supabasePath,
      'file_type': extension,
      'created_at': FieldValue.serverTimestamp(),
      'created_by': userEmail,
      'created_by_user_id': userId,
      'status': 'draft',
      'version': 'V1', 
      'current_version': 'V1', 
      'customer_id': customerId,
      'assigned_reviewer_id': assignedReviewerId,
      'assigned_reviewer_name': assignedReviewerName,
    });
  }

  Future<void> saveRichDocument({
    String? docId,
    required String title,
    required String content,
    String? customerId,
    String? assignedReviewerId,
    String? assignedReviewerName,
    String? changeDescription,
  }) async {
    final user = getIt<HiveService>().getUser();
    final userEmail = user?.email ?? 'unknown';
    
    if (docId != null) {
      final docSnapshot = await _firestore.collection('documents').doc(docId).get();
      final currentData = docSnapshot.data();
      final String oldContent = currentData?['content'] ?? '';
      
      bool contentChanged = oldContent != content;
      
      String versionToUse;
      if (contentChanged) {
        versionToUse = await _calculateNextVersionFromHistory(docId);
      } else {
        versionToUse = await _getCurrentVersionFromHistory(docId);
      }

      await _firestore.collection('documents').doc(docId).update({
        'title': title,
        'content': content,
        'customer_id': customerId,
        'assigned_reviewer_id': assignedReviewerId,
        'assigned_reviewer_name': assignedReviewerName,
        'status': 'draft', 
        'version': 'V1',
        'current_version': versionToUse,
        'updated_at': FieldValue.serverTimestamp(),
      });

      if (changeDescription != null && changeDescription.isNotEmpty) {
        await _addVersionHistory(
          docId: docId,
          versionNo: versionToUse,
          changeDescription: changeDescription,
          performedBy: userEmail,
          status: 'draft',
          assignedReviewerName: assignedReviewerName,
        );
      }
    } else {
      final nextId = await _getNextId();
      await _firestore.collection('documents').add({
        'id': nextId,
        'title': title,
        'content': content,
        'file_name': '$title.quill',
        'file_type': '.quill',
        'file_url': '', 
        'file_path': '',
        'created_at': FieldValue.serverTimestamp(),
        'created_by': userEmail,
        'created_by_user_id': user?.userId ?? 'unknown',
        'status': 'draft',
        'version': 'V1',
        'current_version': 'V1',
        'customer_id': customerId,
        'assigned_reviewer_id': assignedReviewerId,
        'assigned_reviewer_name': assignedReviewerName,
      });
    }
  }

  Future<void> saveExcelBytes({
    String? docId,
    required String title,
    required Uint8List bytes,
    String? customerId,
    String? currentFilePath,
    String? assignedReviewerId,
    String? assignedReviewerName,
    String? changeDescription,
    bool isContentChanged = true,
  }) async {
    final user = getIt<HiveService>().getUser();
    final userEmail = user?.email ?? 'unknown';
    final fileName = "$title.xlsx";

    String supabasePath = currentFilePath ?? 'policies/${DateTime.now().millisecondsSinceEpoch}_$fileName';

    if (isContentChanged || currentFilePath == null) {
      if (currentFilePath != null && currentFilePath.isNotEmpty) {
        try {
          await _supabase.storage.from(SupabaseConfig.bucketName).remove([currentFilePath]);
        } catch (e) {
          developer.log("Error removing old file: $e");
        }
      }
      
      supabasePath = 'policies/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      await _supabase.storage.from(SupabaseConfig.bucketName).uploadBinary(
        supabasePath,
        bytes,
        fileOptions: const FileOptions(cacheControl: '3600', contentType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'),
      );
    }
    
    final String fileUrl = _supabase.storage.from(SupabaseConfig.bucketName).getPublicUrl(supabasePath);

    if (docId != null) {
      String versionToUse;
      if (isContentChanged) {
        versionToUse = await _calculateNextVersionFromHistory(docId);
      } else {
        versionToUse = await _getCurrentVersionFromHistory(docId);
      }

      await _firestore.collection('documents').doc(docId).update({
        'title': title,
        'file_url': fileUrl,
        'file_name': fileName,
        'file_path': supabasePath,
        'customer_id': customerId,
        'assigned_reviewer_id': assignedReviewerId,
        'assigned_reviewer_name': assignedReviewerName,
        'status': 'draft', 
        'version': 'V1',
        'current_version': versionToUse,
        'updated_at': FieldValue.serverTimestamp(),
      });

      if (changeDescription != null && changeDescription.isNotEmpty) {
        await _addVersionHistory(
          docId: docId,
          versionNo: versionToUse,
          changeDescription: changeDescription,
          performedBy: userEmail,
          status: 'draft',
          assignedReviewerName: assignedReviewerName,
        );
      }
    } else {
      final nextId = await _getNextId();
      await _firestore.collection('documents').add({
        'id': nextId,
        'title': title,
        'file_url': fileUrl,
        'file_name': fileName,
        'file_path': supabasePath,
        'file_type': '.xlsx',
        'created_at': FieldValue.serverTimestamp(),
        'created_by': userEmail,
        'created_by_user_id': user?.userId ?? 'unknown',
        'status': 'draft',
        'version': 'V1',
        'current_version': 'V1',
        'customer_id': customerId,
        'assigned_reviewer_id': assignedReviewerId,
        'assigned_reviewer_name': assignedReviewerName,
      });
    }
  }

  Future<void> updateDocument({
    required String docId,
    required String title,
    File? newFile,
    String? currentFilePath,
    String? customerId,
    String? assignedReviewerId,
    String? assignedReviewerName,
    String? changeDescription,
  }) async {
    Map<String, dynamic> updateData = {
      'title': title,
      'customer_id': customerId,
      'assigned_reviewer_id': assignedReviewerId,
      'assigned_reviewer_name': assignedReviewerName,
      'status': 'draft', 
      'version': 'V1',
      'updated_at': FieldValue.serverTimestamp(),
    };

    bool contentChanged = newFile != null;

    if (newFile != null) {
      if (currentFilePath != null && currentFilePath.isNotEmpty) {
        try {
          await _supabase.storage.from(SupabaseConfig.bucketName).remove([currentFilePath]);
        } catch (e) {
          developer.log("Error removing old file: $e");
        }
      }

      final fileName = p.basename(newFile.path);
      final extension = p.extension(newFile.path);
      final String supabasePath = 'policies/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      
      await _supabase.storage.from(SupabaseConfig.bucketName).upload(supabasePath, newFile);
      
      final String fileUrl = _supabase.storage.from(SupabaseConfig.bucketName).getPublicUrl(supabasePath);

      updateData['file_url'] = fileUrl;
      updateData['file_name'] = fileName;
      updateData['file_path'] = supabasePath;
      updateData['file_type'] = extension;
    }

    String versionToUse;
    if (contentChanged) {
      versionToUse = await _calculateNextVersionFromHistory(docId);
    } else {
      versionToUse = await _getCurrentVersionFromHistory(docId);
    }
    
    updateData['current_version'] = versionToUse;

    await _firestore.collection('documents').doc(docId).update(updateData);

    if (changeDescription != null && changeDescription.isNotEmpty) {
      await _addVersionHistory(
        docId: docId,
        versionNo: versionToUse,
        changeDescription: changeDescription,
        performedBy: getIt<HiveService>().getUser()?.email ?? 'unknown',
        status: 'draft',
        assignedReviewerName: assignedReviewerName,
      );
    }
  }

  Future<void> deleteDocument(String docId, String? supabasePath) async {
    if (supabasePath != null && supabasePath.isNotEmpty) {
      try {
        await _supabase.storage.from(SupabaseConfig.bucketName).remove([supabasePath]);
      } catch (e) {
        developer.log("Error deleting document from storage: $e");
      }
    }
    await _firestore.collection('documents').doc(docId).delete();
  }

  Future<void> updateStatus(String docId, String status) async {
    final user = getIt<HiveService>().getUser();
    final userEmail = user?.email ?? 'unknown';

    Map<String, dynamic> updateData = {
      'status': status,
      'updated_at': FieldValue.serverTimestamp(),
    };

    if (status == 'active') {
      updateData['reviewed_by'] = userEmail;
      updateData['reviewed_date'] = FieldValue.serverTimestamp();
      
      final historySnapshot = await _firestore
          .collection('documents')
          .doc(docId)
          .collection('version_history')
          .orderBy('performedDate', descending: true)
          .limit(1)
          .get();
          
      final String latestVersion = historySnapshot.docs.isNotEmpty 
          ? historySnapshot.docs.first.data()['versionNo'] 
          : 'V1';

      await _addVersionHistory(
        docId: docId,
        versionNo: latestVersion,
        changeDescription: 'Document Approved & Activated',
        performedBy: userEmail,
        approvedBy: userEmail, 
        approvedDate: DateTime.now(),
        status: 'active',
      );
    }

    await _firestore.collection('documents').doc(docId).update(updateData);
  }

  Future<List<VersionHistoryModel>> getVersionHistory(String docId) async {
    final snapshot = await _firestore
        .collection('documents')
        .doc(docId)
        .collection('version_history')
        .orderBy('performedDate', descending: true)
        .get();
    return snapshot.docs.map((doc) => VersionHistoryModel.fromFirestore(doc)).toList();
  }
}
