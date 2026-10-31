import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iq_plus/common/utility/utility.dart';
import 'package:iq_plus/core/email_services/email_service.dart';
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

    if (customerId != null && customerId.isNotEmpty) {
      query = query.where('customer_id', isEqualTo: customerId);
    } else if (isConsultant && userId != null && userId.isNotEmpty) {
      // 🚀 For consultants, fetch customers assigned to this consultant
      final custSnapshot = await _firestore
          .collection('customers')
          .where('consultantId', isEqualTo: userId)
          .get();
      final assignedCustomerIds =
          custSnapshot.docs.map((doc) => doc.id).toSet();

      final snapshot = await query.orderBy('created_at', descending: true).get();
      final allDocs = snapshot.docs
          .map((doc) => DocumentModel.fromFirestore(doc))
          .toList();

      return allDocs.where((doc) {
        final isCreatedByMe = doc.createdByUserId == userId;
        final isPublic = doc.customerId == null || doc.customerId!.isEmpty;
        final isMyCustomerDoc = doc.customerId != null &&
            assignedCustomerIds.contains(doc.customerId);

        return isCreatedByMe || isPublic || isMyCustomerDoc;
      }).toList();
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

/*  Future<String> _getCurrentVersionFromHistory(String docId) async {
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
  }*/

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
    String? rejectionReason,
    String? rejectedBy,
    DateTime? rejectedDate,
    required String status,
    String? docTitle,
    String? customerId,
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
      'rejectionReason': rejectionReason,
      'rejectedBy': rejectedBy,
      'rejectedDate': rejectedDate != null ? Timestamp.fromDate(rejectedDate) : null,
      'status': status,
      'docTitle': docTitle,
      'customerId': customerId,
    });
  }

  Future<void> _notifyCustomerPolicyEvent({
    String? docId,
    String? customerId,
    required String policyTitle,
    required bool isUpdate,
    String? changeDescription,
  }) async {
    try {
      String? targetCustomerId = customerId;
      if ((targetCustomerId == null || targetCustomerId.isEmpty) && docId != null && docId.isNotEmpty) {
        final docSnap = await _firestore.collection('documents').doc(docId).get();
        if (docSnap.exists) {
          targetCustomerId = docSnap.data()?['customer_id'];
        }
      }

      final currentUser = getIt<HiveService>().getUser();
      final String performedBy = currentUser?.userName ?? currentUser?.email ?? 'Admin/Consultant';

      void addIfValid(String? emailVal, Set<String> targetSet) {
        if (emailVal != null) {
          final trimmed = emailVal.trim();
          if (trimmed.isNotEmpty && !Utility.emailValidationPattern(value: trimmed)) {
            targetSet.add(trimmed);
          }
        }
      }

      List<Map<String, dynamic>> targetCustomers = [];

      if (targetCustomerId != null && targetCustomerId.isNotEmpty) {
        final custDoc = await _firestore.collection('customers').doc(targetCustomerId).get();
        if (custDoc.exists && custDoc.data() != null) {
          targetCustomers.add(custDoc.data()!);
        }
      } else {
        // Global policy for all approved customers
        final snapshot = await _firestore
            .collection('customers')
            .where('isProfileApproved', isEqualTo: true)
            .get();
        targetCustomers = snapshot.docs.map((d) => d.data()).toList();
      }

      for (final custData in targetCustomers) {
        final String companyName = custData['companyName'] ?? custData['name'] ?? 'Valued Customer';
        final Set<String> recipientEmails = {};

        addIfValid(custData['email'], recipientEmails);

        for (final email in recipientEmails) {
          if (isUpdate) {
            await BrevoEmailService.sendPolicyUpdatedMail(
              customerEmail: email,
              customerName: companyName,
              policyTitle: policyTitle,
              updatedBy: performedBy,
              changeDescription: changeDescription ?? 'Policy updated',
            );
          } else {
            await BrevoEmailService.sendPolicyCreatedMail(
              customerEmail: email,
              customerName: companyName,
              policyTitle: policyTitle,
              createdBy: performedBy,
            );
          }
        }
      }
    } catch (e) {
      developer.log("Error sending policy email notification: $e");
    }
  }

  Future<void> addDocument({
    required String title,
    required Uint8List bytes,
    required String fileName,
    String? customerId,
  }) async {
    final extension = p.extension(fileName);
    final user = getIt<HiveService>().getUser();
    final userEmail = user?.email ?? 'unknown';
    final userId = user?.userId ?? 'unknown';
    
    final String supabasePath = 'policies/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    try {
      await _supabase.storage.from(SupabaseConfig.bucketName).uploadBinary(
        supabasePath,
        bytes,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );
    } on StorageException catch (e) {
      if (e.statusCode == '413') {
        throw 'The file is too large for the storage server. Please try a smaller file (max 50MB).';
      }
      rethrow;
    }
    
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
      'last_change_description': 'Initial document upload',
      'last_updated_by': userEmail,
    });

    _notifyCustomerPolicyEvent(
      customerId: customerId,
      policyTitle: title,
      isUpdate: false,
    );
  }

  Future<void> saveRichDocument({
    String? docId,
    required String title,
    required String content,
    String? customerId,
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
        'status': 'draft', 
        'last_change_description': changeDescription ?? 'Rich text updated',
        'last_updated_by': userEmail,
        'updated_at': FieldValue.serverTimestamp(),
      });
      _notifyCustomerPolicyEvent(
        docId: docId,
        customerId: customerId,
        policyTitle: title,
        isUpdate: true,
        changeDescription: changeDescription ?? 'Rich text updated',
      );
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
        'last_change_description': 'Initial rich text creation',
        'last_updated_by': userEmail,
      });
      _notifyCustomerPolicyEvent(
        customerId: customerId,
        policyTitle: title,
        isUpdate: false,
      );
    }
  }

  Future<void> saveExcelBytes({
    String? docId,
    required String title,
    required Uint8List bytes,
    String? customerId,
    String? currentFilePath,
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
      try {
        await _supabase.storage.from(SupabaseConfig.bucketName).uploadBinary(
          supabasePath,
          bytes,
          fileOptions: const FileOptions(cacheControl: '3600', contentType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'),
        );
      } on StorageException catch (e) {
        if (e.statusCode == '413') {
          throw 'The spreadsheet is too large for the storage server. Please try a smaller file (max 50MB).';
        }
        rethrow;
      }
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
        'status': 'draft', 
        'last_change_description': changeDescription ?? 'Spreadsheet updated',
        'last_updated_by': userEmail,
        'updated_at': FieldValue.serverTimestamp(),
      });
      _notifyCustomerPolicyEvent(
        docId: docId,
        customerId: customerId,
        policyTitle: title,
        isUpdate: true,
        changeDescription: changeDescription ?? 'Spreadsheet updated',
      );
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
        'last_change_description': 'Initial excel creation',
        'last_updated_by': userEmail,
      });
      _notifyCustomerPolicyEvent(
        customerId: customerId,
        policyTitle: title,
        isUpdate: false,
      );
    }
  }

  Future<void> updateDocument({
    required String docId,
    required String title,
    Uint8List? newFileBytes,
    String? newFileName,
    String? currentFilePath,
    String? customerId,
    String? changeDescription,
  }) async {
    final user = getIt<HiveService>().getUser();
    final userEmail = user?.email ?? 'unknown';
    Map<String, dynamic> updateData = {
      'title': title,
      'customer_id': customerId,
      'status': 'draft', 
      'last_change_description': changeDescription ?? 'Document updated',
      'last_updated_by': userEmail,
      'updated_at': FieldValue.serverTimestamp(),
    };

    if (newFileBytes != null && newFileName != null) {
      if (currentFilePath != null && currentFilePath.isNotEmpty) {
        try {
          await _supabase.storage.from(SupabaseConfig.bucketName).remove([currentFilePath]);
        } catch (e) {
          developer.log("Error removing old file: $e");
        }
      }

      final extension = p.extension(newFileName);
      final String supabasePath = 'policies/${DateTime.now().millisecondsSinceEpoch}_$newFileName';
      
      try {
        await _supabase.storage.from(SupabaseConfig.bucketName).uploadBinary(supabasePath, newFileBytes);
      } on StorageException catch (e) {
        if (e.statusCode == '413') {
          throw 'The new file is too large for the storage server. Please try a smaller file (max 50MB).';
        }
        rethrow;
      }
      
      final String fileUrl = _supabase.storage.from(SupabaseConfig.bucketName).getPublicUrl(supabasePath);

      updateData['file_url'] = fileUrl;
      updateData['file_name'] = newFileName;
      updateData['file_path'] = supabasePath;
      updateData['file_type'] = extension;
    }

    // 🚀 Manual Update: Just update main doc. NO history log and NO version change.
    await _firestore.collection('documents').doc(docId).update(updateData);
    _notifyCustomerPolicyEvent(
      docId: docId,
      customerId: customerId,
      policyTitle: title,
      isUpdate: true,
      changeDescription: changeDescription ?? 'Document updated',
    );
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

  Future<void> updateStatus(String docId, String status, {String? rejectionReason}) async {
    final hive = getIt<HiveService>();
    final user = hive.getUser();
    final customer = hive.getCustomer();
    
    final String userEmail = user?.email ?? customer?.email ?? 'unknown';
    final String? roleId = user?.roleId ?? customer?.roleId;
    final String? currentUserId = user?.userId ?? customer?.customerId;

    final docSnapshot = await _firestore.collection('documents').doc(docId).get();
    final data = docSnapshot.data();
    if (data == null) return;

    final String? assignedCustomerId = data['customer_id'];
    final bool isAssignedCustomer = Utility.isCustomer(roleId) && assignedCustomerId == currentUserId;

    if (status == 'active') {
      // 🚀 Authorization check: Only the assigned Customer can approve
      if (!isAssignedCustomer) {
        throw Exception("Only the assigned customer is authorized to approve this policy.");
      }

      final docTitle = data['title'];
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
        docTitle: docTitle,
        customerId: assignedCustomerId,
      );
    } else if (status == 'rejected' || status == 'reject') {
      // 🚀 Authorization check: Only the assigned Customer can reject
      if (!isAssignedCustomer) {
        throw Exception("Only the assigned customer is authorized to reject this policy.");
      }

      final docTitle = data['title'];
      final currentVersion = data['current_version'] ?? 'V1';
      final String reasonText = rejectionReason ?? 'Policy rejected by customer';

      Map<String, dynamic> updateData = {
        'status': 'rejected',
        'rejection_reason': reasonText,
        'rejected_by': userEmail,
        'rejected_date': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('documents').doc(docId).update(updateData);

      // Log the rejection in history
      await _addVersionHistory(
        docId: docId,
        versionNo: currentVersion,
        changeDescription: 'Rejected: $reasonText',
        performedBy: userEmail,
        rejectionReason: reasonText,
        rejectedBy: userEmail,
        rejectedDate: DateTime.now(),
        status: 'rejected',
        docTitle: docTitle,
        customerId: assignedCustomerId,
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

  Future<DocumentModel?> getDocumentById(String docId) async {
    try {
      final doc = await _firestore.collection('documents').doc(docId).get();
      if (doc.exists) {
        return DocumentModel.fromFirestore(doc);
      }
    } catch (e) {
      developer.log("Error fetching document by ID: $e");
    }
    return null;
  }

  Future<List<VersionHistoryModel>> getGlobalVersionHistory({
    String? userId,
    bool isConsultant = false,
    String? customerId,
  }) async {
    try {
      Set<String>? allowedDocIds;

      if ((isConsultant && userId != null) || customerId != null) {
        final docs = await getDocuments(
          userId: userId,
          isConsultant: isConsultant,
          customerId: customerId,
        );
        allowedDocIds = docs.map((d) => d.docId).toSet();
        if (allowedDocIds.isEmpty) return [];
      }

      final snapshot = await _firestore
          .collectionGroup('version_history')
          .orderBy('performedDate', descending: true)
          .get();

      List<VersionHistoryModel> history = [];

      // Map to cache document info to avoid repeated DB hits
      Map<String, Map<String, String>> docCache = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final String dId = data['docId'] ?? '';

        if (allowedDocIds != null && !allowedDocIds.contains(dId)) {
          continue;
        }

        String? title = data['docTitle'];
        String? custId = data['customerId'] ?? data['customer_id'];

        // If title or customerId is missing in history entry, fetch from parent document
        if ((title == null || title.isEmpty || custId == null || custId.isEmpty) && dId.isNotEmpty) {
          if (docCache.containsKey(dId)) {
            title = docCache[dId]?['title'];
            custId = docCache[dId]?['customerId'];
          } else {
            try {
              final parentDoc = await _firestore.collection('documents').doc(dId).get();
              final parentData = parentDoc.data();
              title = parentData?['title'] ?? 'Unknown Policy';
              custId = parentData?['customer_id'] ?? parentData?['customerId'];
              docCache[dId] = {
                'title': title!,
                'customerId': custId ?? '',
              };
            } catch (e) {
              title = 'Unknown Policy';
            }
          }
        }

        history.add(VersionHistoryModel.fromFirestore(doc, docTitle: title, customerId: custId));
      }

      return history;
    } catch (e) {
      developer.log("Error fetching global version history: $e");
      return [];
    }
  }

  Future<PaginatedVersionHistoryResult> getGlobalVersionHistoryPaginated({
    String? userId,
    bool isConsultant = false,
    String? customerId,
    DocumentSnapshot? lastDocument,
    int limit = 15,
  }) async {
    try {
      Set<String>? allowedDocIds;

      if ((isConsultant && userId != null) || customerId != null) {
        final docs = await getDocuments(
          userId: userId,
          isConsultant: isConsultant,
          customerId: customerId,
        );
        allowedDocIds = docs.map((d) => d.docId).toSet();
        if (allowedDocIds.isEmpty) {
          return PaginatedVersionHistoryResult(
            history: [],
            lastDocument: null,
            hasMore: false,
          );
        }
      }

      List<VersionHistoryModel> history = [];
      DocumentSnapshot? currentLastDoc = lastDocument;
      bool hasMore = true;
      Map<String, Map<String, String>> docCache = {};

      while (history.length < limit && hasMore) {
        Query query = _firestore
            .collectionGroup('version_history')
            .orderBy('performedDate', descending: true)
            .limit(limit);

        if (currentLastDoc != null) {
          query = query.startAfterDocument(currentLastDoc);
        }

        final snapshot = await query.get();

        if (snapshot.docs.isEmpty) {
          hasMore = false;
          break;
        }

        currentLastDoc = snapshot.docs.last;

        if (snapshot.docs.length < limit) {
          hasMore = false;
        }

        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final String dId = data['docId'] ?? '';

          if (allowedDocIds != null && !allowedDocIds.contains(dId)) {
            continue;
          }

          String? title = data['docTitle'];
          String? custId = data['customerId'] ?? data['customer_id'];

          if ((title == null || title.isEmpty || custId == null || custId.isEmpty) && dId.isNotEmpty) {
            if (docCache.containsKey(dId)) {
              title = docCache[dId]?['title'];
              custId = docCache[dId]?['customerId'];
            } else {
              try {
                final parentDoc = await _firestore.collection('documents').doc(dId).get();
                final parentData = parentDoc.data();
                title = parentData?['title'] ?? 'Unknown Policy';
                custId = parentData?['customer_id'] ?? parentData?['customerId'];
                docCache[dId] = {
                  'title': title!,
                  'customerId': custId ?? '',
                };
              } catch (e) {
                title = 'Unknown Policy';
              }
            }
          }

          history.add(VersionHistoryModel.fromFirestore(doc, docTitle: title, customerId: custId));
        }
      }

      return PaginatedVersionHistoryResult(
        history: history,
        lastDocument: currentLastDoc,
        hasMore: hasMore,
      );
    } catch (e) {
      developer.log("Error fetching paginated global version history: $e");
      return PaginatedVersionHistoryResult(
        history: [],
        lastDocument: null,
        hasMore: false,
      );
    }
  }
}

class PaginatedVersionHistoryResult {
  final List<VersionHistoryModel> history;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;

  PaginatedVersionHistoryResult({
    required this.history,
    this.lastDocument,
    required this.hasMore,
  });
}
