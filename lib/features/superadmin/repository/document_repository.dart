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
      final historySnapshot = await _firestore
          .collection('documents')
          .doc(docId)
          .collection('version_history')
          .orderBy('performedDate', descending: true)
          .limit(1)
          .get();

      if (historySnapshot.docs.isEmpty) {
        return 'V1'; // First activation results in V1
      }

      final lastVersionStr = historySnapshot.docs.first.data()['versionNo'] as String? ?? 'V1';
      if (lastVersionStr.startsWith('V')) {
        // Handle sub-versions like V2.1, V2.2 by extracting the major number
        final String versionCore = lastVersionStr.substring(1).split('.').first;
        int versionNum = int.parse(versionCore);
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
    String? assignedReviewerEmail,
    String? docTitle,
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
      'assignedReviewerEmail': assignedReviewerEmail,
      'docTitle': docTitle,
    });
  }

  Future<void> addDocument({
    required String title,
    required File file,
    String? customerId,
    String? assignedReviewerId,
    String? assignedReviewerName,
    String? assignedReviewerEmail,
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
      'assigned_reviewer_email': assignedReviewerEmail,
      'last_change_description': 'Initial document upload',
      'last_updated_by': userEmail,
    });
  }

  Future<void> saveRichDocument({
    String? docId,
    required String title,
    required String content,
    String? customerId,
    String? assignedReviewerId,
    String? assignedReviewerName,
    String? assignedReviewerEmail,
    String? changeDescription,
  }) async {
    final user = getIt<HiveService>().getUser();
    final userEmail = user?.email ?? 'unknown';
    
    if (docId != null) {
      // 🚀 Manual Update: Just update main doc. NO history log and NO version change.
      await _firestore.collection('documents').doc(docId).update({
        'title': title,
        'content': content,
        'customer_id': customerId,
        'assigned_reviewer_id': assignedReviewerId,
        'assigned_reviewer_name': assignedReviewerName,
        'assigned_reviewer_email': assignedReviewerEmail,
        'status': 'draft', 
        'last_change_description': changeDescription ?? 'Rich text updated',
        'last_updated_by': userEmail,
        'updated_at': FieldValue.serverTimestamp(),
      });
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
        'assigned_reviewer_email': assignedReviewerEmail,
        'last_change_description': 'Initial rich text creation',
        'last_updated_by': userEmail,
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
    String? assignedReviewerEmail,
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
      // 🚀 Manual Update: Just update main doc. NO history log and NO version change.
      await _firestore.collection('documents').doc(docId).update({
        'title': title,
        'file_url': fileUrl,
        'file_name': fileName,
        'file_path': supabasePath,
        'customer_id': customerId,
        'assigned_reviewer_id': assignedReviewerId,
        'assigned_reviewer_name': assignedReviewerName,
        'assigned_reviewer_email': assignedReviewerEmail,
        'status': 'draft', 
        'last_change_description': changeDescription ?? 'Spreadsheet updated',
        'last_updated_by': userEmail,
        'updated_at': FieldValue.serverTimestamp(),
      });
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
        'assigned_reviewer_email': assignedReviewerEmail,
        'last_change_description': 'Initial excel creation',
        'last_updated_by': userEmail,
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
    String? assignedReviewerEmail,
    String? changeDescription,
  }) async {
    final user = getIt<HiveService>().getUser();
    final userEmail = user?.email ?? 'unknown';
    Map<String, dynamic> updateData = {
      'title': title,
      'customer_id': customerId,
      'assigned_reviewer_id': assignedReviewerId,
      'assigned_reviewer_name': assignedReviewerName,
      'assigned_reviewer_email': assignedReviewerEmail,
      'status': 'draft', 
      'last_change_description': changeDescription ?? 'Document updated',
      'last_updated_by': userEmail,
      'updated_at': FieldValue.serverTimestamp(),
    };

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

    // 🚀 Manual Update: Just update main doc. NO history log and NO version change.
    await _firestore.collection('documents').doc(docId).update(updateData);
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

    if (status == 'active') {
      // 🚀 Version change and history entry ONLY on activation
      final docSnapshot = await _firestore.collection('documents').doc(docId).get();
      final data = docSnapshot.data();
      if (data == null) return;

      final docTitle = data['title'];
      final currentReviewerName = data['assigned_reviewer_name'];
      final currentReviewerEmail = data['assigned_reviewer_email'];
      final changeDescription = data['last_change_description'] ?? 'Approved and Activated';
      final lastUpdatedBy = data['last_updated_by'] ?? 'System';

      // Calculate next version
      final nextVersion = await _calculateNextVersionFromHistory(docId);

      Map<String, dynamic> updateData = {
        'status': 'active',
        'current_version': nextVersion,
        'reviewed_by': userEmail,
        'reviewed_date': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('documents').doc(docId).update(updateData);

      // Log the activation in history
      await _addVersionHistory(
        docId: docId,
        versionNo: nextVersion,
        changeDescription: changeDescription,
        performedBy: lastUpdatedBy,
        approvedBy: userEmail, 
        approvedDate: DateTime.now(),
        status: 'active',
        assignedReviewerName: currentReviewerName,
        assignedReviewerEmail: currentReviewerEmail,
        docTitle: docTitle,
      );
    } else {
      // Just set to draft or other status
      await _firestore.collection('documents').doc(docId).update({
        'status': status,
        'updated_at': FieldValue.serverTimestamp(),
      });
    }
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

  Future<List<VersionHistoryModel>> getGlobalVersionHistory({
    String? userId,
    bool isConsultant = false,
    String? customerId,
  }) async {
    // 🚀 Collection Group query to fetch history from ALL documents at once
    Query query = _firestore.collectionGroup('version_history');

    if (isConsultant && userId != null) {
      final docs = await getDocuments(userId: userId, isConsultant: true);
      final docIds = docs.map((d) => d.docId).toList();
      if (docIds.isEmpty) return [];
      query = query.where('docId', whereIn: docIds);
    } else if (customerId != null) {
      final docs = await getDocuments(customerId: customerId);
      final docIds = docs.map((d) => d.docId).toList();
      if (docIds.isEmpty) return [];
      query = query.where('docId', whereIn: docIds);
    }

    final snapshot = await query.orderBy('performedDate', descending: true).get();
    
    List<VersionHistoryModel> history = [];
    
    // Map to cache document titles to avoid repeated DB hits
    Map<String, String> titleCache = {};

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      String? title = data['docTitle'];
      final String dId = data['docId'] ?? '';

      // If title is missing in history entry, fetch from parent document
      if ((title == null || title.isEmpty) && dId.isNotEmpty) {
        if (titleCache.containsKey(dId)) {
          title = titleCache[dId];
        } else {
          try {
            final parentDoc = await _firestore.collection('documents').doc(dId).get();
            title = parentDoc.data()?['title'] ?? 'Unknown Policy';
            titleCache[dId] = title!;
          } catch (e) {
            title = 'Unknown Policy';
          }
        }
      }

      history.add(VersionHistoryModel.fromFirestore(doc, docTitle: title));
    }
    
    return history;
  }
}
