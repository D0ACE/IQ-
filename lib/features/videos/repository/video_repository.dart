import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:iq_plus/core/email_services/email_service.dart';
import 'package:iq_plus/core/supabase/supabase_config.dart';
import 'package:iq_plus/features/videos/models/video_model.dart';
import 'package:iq_plus/features/videos/models/video_enrollment_model.dart';

class VideoRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _supabase = Supabase.instance.client;

  Future<void> uploadVideo({
    required String title,
    required Uint8List bytes,
    required String fileName,
    required String userId,
    String? customerId,
    required List<AwarenessQuestionModel> questions,
    required bool accessToOtherEmployees,
  }) async {
    final String supabasePath = 'videos/${DateTime.now().millisecondsSinceEpoch}_$fileName';

    try {
      // 1. Upload to Supabase Storage using Binary (Web compatible)
      await _supabase.storage.from(SupabaseConfig.bucketName).uploadBinary(
        supabasePath,
        bytes,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );
    } on StorageException catch (e) {
      if (e.statusCode == '413') {
        throw 'The video file is too large for the storage server. Please try a smaller video (max 50MB).';
      }
      rethrow;
    }

    final String videoUrl = _supabase.storage.from(SupabaseConfig.bucketName).getPublicUrl(supabasePath);

    // 2. Save to Firestore
    await _firestore.collection('videos').add({
      'title': title,
      'video_url': videoUrl,
      'file_name': fileName,
      'file_path': supabasePath,
      'created_by': userId,
      'customer_id': customerId,
      'questions': questions.map((AwarenessQuestionModel q) => q.toJson()).toList(),
      'access_to_other_employees': accessToOtherEmployees,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateVideo({
    required String videoId,
    required String title,
    Uint8List? newBytes,
    String? newFileName,
    String? oldFilePath,
    required String userId,
    String? customerId,
    required List<AwarenessQuestionModel> questions,
    required bool accessToOtherEmployees,
  }) async {
    String? videoUrl;
    String? supabasePath;

    if (newBytes != null && newFileName != null) {
      supabasePath = 'videos/${DateTime.now().millisecondsSinceEpoch}_$newFileName';

      try {
        await _supabase.storage.from(SupabaseConfig.bucketName).uploadBinary(
          supabasePath,
          newBytes,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );
      } on StorageException catch (e) {
        if (e.statusCode == '413') {
          throw 'The video file is too large for the storage server. Please try a smaller video (max 50MB).';
        }
        rethrow;
      }

      videoUrl = _supabase.storage.from(SupabaseConfig.bucketName).getPublicUrl(supabasePath);

      if (oldFilePath != null && oldFilePath.isNotEmpty) {
        try {
          await _supabase.storage.from(SupabaseConfig.bucketName).remove([oldFilePath]);
        } catch (_) {}
      }
    }

    final Map<String, dynamic> updateData = {
      'title': title,
      'customer_id': customerId,
      'questions': questions.map((AwarenessQuestionModel q) => q.toJson()).toList(),
      'access_to_other_employees': accessToOtherEmployees,
      'updated_at': FieldValue.serverTimestamp(),
    };

    if (videoUrl != null && supabasePath != null && newFileName != null) {
      updateData['video_url'] = videoUrl;
      updateData['file_name'] = newFileName;
      updateData['file_path'] = supabasePath;
    }

    await _firestore.collection('videos').doc(videoId).update(updateData);
  }

  Future<List<AwarenessVideoModel>> getVideos({
    String? customerId,
    String? createdBy,
    bool isConsultant = false,
  }) async {
    Query query = _firestore.collection('videos');

    if (customerId != null && customerId.isNotEmpty) {
      query = query.where('customer_id', isEqualTo: customerId);
    } else if (isConsultant && createdBy != null && createdBy.isNotEmpty) {
      // 🚀 For consultants, show videos created by them, public videos, or assigned to their customers
      final custSnapshot = await _firestore
          .collection('customers')
          .where('consultantId', isEqualTo: createdBy)
          .get();
      final assignedCustomerIds =
          custSnapshot.docs.map((doc) => doc.id).toSet();

      final snapshot = await query.orderBy('created_at', descending: true).get();
      final allVideos = snapshot.docs
          .map((doc) => AwarenessVideoModel.fromFirestore(doc))
          .toList();

      return allVideos.where((v) {
        final isCreatedByMe = v.createdBy == createdBy;
        final isPublic = v.customerId == null || v.customerId!.isEmpty;
        final isMyCustomerVideo =
            v.customerId != null && assignedCustomerIds.contains(v.customerId);

        return isCreatedByMe || isPublic || isMyCustomerVideo;
      }).toList();
    } else if (createdBy != null && createdBy.isNotEmpty) {
      query = query.where('created_by', isEqualTo: createdBy);
    }

    final snapshot = await query.orderBy('created_at', descending: true).get();
    return snapshot.docs
        .map((doc) => AwarenessVideoModel.fromFirestore(doc))
        .toList();
  }

  Future<void> assignEmployeesToVideo({
    required String videoId,
    required List<String> employeeIds,
  }) async {
    // 1. Fetch current video document to check existing assigned employees and video title
    final videoDoc = await _firestore.collection('videos').doc(videoId).get();
    final videoData = videoDoc.data() ?? {};
    final String videoTitle = videoData['title'] ?? 'Training Video';
    final String? customerId = videoData['customer_id'];
    final List<String> previousEmployeeIds = videoData['assigned_employee_ids'] != null
        ? List<String>.from(videoData['assigned_employee_ids'])
        : [];

    // 2. Identify newly assigned employee IDs (only those NOT previously assigned)
    final newlyAssignedIds = employeeIds
        .where((id) => !previousEmployeeIds.contains(id))
        .toList();

    // 3. Update Firestore document
    await _firestore.collection('videos').doc(videoId).update({
      'assigned_employee_ids': employeeIds,
      'updated_at': FieldValue.serverTimestamp(),
    });

    // 4. Send email to newly assigned employees (sent only once unless unassigned and reassigned)
    if (newlyAssignedIds.isNotEmpty) {
      _sendEmailsToNewlyAssignedEmployees(
        newlyAssignedIds: newlyAssignedIds,
        videoTitle: videoTitle,
        customerId: customerId,
      );
    }
  }

  Future<void> _sendEmailsToNewlyAssignedEmployees({
    required List<String> newlyAssignedIds,
    required String videoTitle,
    String? customerId,
  }) async {
    try {
      String? companyName;
      if (customerId != null && customerId.isNotEmpty) {
        try {
          final custDoc = await _firestore.collection('customers').doc(customerId).get();
          if (custDoc.exists) {
            companyName = custDoc.data()?['companyName'];
          }
        } catch (_) {}
      }

      final snapshot = await _firestore.collectionGroup('employees').get();
      final matchedDocs = snapshot.docs.where((doc) => newlyAssignedIds.contains(doc.id));

      for (final doc in matchedDocs) {
        final data = doc.data();
        final String email = data['email'] ?? '';
        final String userName = data['userName'] ?? 'Employee';

        if (email.isNotEmpty) {
          try {
            await BrevoEmailService.sendVideoAssignedMail(
              employeeEmail: email,
              employeeName: userName,
              videoTitle: videoTitle,
              companyName: companyName,
            );
          } catch (e) {
            debugPrint("Error sending video assignment email to $email: $e");
          }
        }
      }
    } catch (e) {
      debugPrint("Error in _sendEmailsToNewlyAssignedEmployees: $e");
    }
  }

  Future<void> enrollInVideo({
    required String videoId,
    required String employeeId,
    required String customerId,
  }) async {
    final enrollmentRef = _firestore
        .collection('customers')
        .doc(customerId)
        .collection('employees')
        .doc(employeeId)
        .collection('video_enrollments')
        .doc(videoId);

    final docSnap = await enrollmentRef.get();
    int currentAttempts = 0;
    if (docSnap.exists && docSnap.data() != null) {
      currentAttempts = docSnap.data()?['attempt_count'] ?? 0;
    }

    int newAttempts = currentAttempts + 1;
    if (newAttempts > 3) {
      throw 'Maximum 3 attempts reached for this training course.';
    }

    await enrollmentRef.set({
      'video_id': videoId,
      'enrolled_at': FieldValue.serverTimestamp(),
      'status': 'enrolled',
      'attempt_count': newAttempts,
    }, SetOptions(merge: true));
  }

  Future<List<VideoEnrollmentModel>> getVideoEnrollments({
    required String employeeId,
    required String customerId,
  }) async {
    final snapshot = await _firestore
        .collection('customers')
        .doc(customerId)
        .collection('employees')
        .doc(employeeId)
        .collection('video_enrollments')
        .get();

    return snapshot.docs.map((doc) => VideoEnrollmentModel.fromFirestore(doc)).toList();
  }

  Future<void> submitQuizResult({
    required String videoId,
    required String employeeId,
    required String customerId,
    required int score,
    required int totalQuestions,
  }) async {
    final enrollmentRef = _firestore
        .collection('customers')
        .doc(customerId)
        .collection('employees')
        .doc(employeeId)
        .collection('video_enrollments')
        .doc(videoId);

    final double percentage = (totalQuestions > 0) ? (score / totalQuestions) * 100 : 0;
    final bool passed = percentage >= 80;
    final String status = passed ? 'completed' : 'failed';

    await enrollmentRef.set({
      'score': score,
      'total_questions': totalQuestions,
      'completed_at': FieldValue.serverTimestamp(),
      'status': status,
    }, SetOptions(merge: true));
  }

  Future<void> deleteVideo(String videoId, String filePath) async {
    try {
      await _supabase.storage.from(SupabaseConfig.bucketName).remove([filePath]);
    } catch (e) {
      // Log error but continue with Firestore deletion
    }

    await _firestore.collection('videos').doc(videoId).delete();
  }
}
