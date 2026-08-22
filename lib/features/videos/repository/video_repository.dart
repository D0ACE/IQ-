import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  }) async {
    final String supabasePath = 'videos/${DateTime.now().millisecondsSinceEpoch}_$fileName';

    // 1. Upload to Supabase Storage using Binary (Web compatible)
    await _supabase.storage.from(SupabaseConfig.bucketName).uploadBinary(
      supabasePath,
      bytes,
      fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
    );

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
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Future<List<AwarenessVideoModel>> getVideos({String? customerId, String? createdBy}) async {
    Query query = _firestore.collection('videos');

    if (customerId != null) {
      query = query.where('customer_id', isEqualTo: customerId);
    }

    if (createdBy != null && createdBy.isNotEmpty) {
      query = query.where('created_by', isEqualTo: createdBy);
    }
    
    final snapshot = await query.orderBy('created_at', descending: true).get();
    return snapshot.docs.map((doc) => AwarenessVideoModel.fromFirestore(doc)).toList();
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

    await enrollmentRef.set({
      'video_id': videoId,
      'enrolled_at': FieldValue.serverTimestamp(),
      'status': 'enrolled',
    });
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

    await enrollmentRef.update({
      'score': score,
      'total_questions': totalQuestions,
      'completed_at': FieldValue.serverTimestamp(),
      'status': 'completed',
    });
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
