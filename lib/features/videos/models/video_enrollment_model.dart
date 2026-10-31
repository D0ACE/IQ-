import 'package:cloud_firestore/cloud_firestore.dart';

class VideoEnrollmentModel {
  final String videoId;
  final String status; // 'enrolled', 'completed', or 'failed'
  final DateTime enrolledAt;
  final DateTime? completedAt;
  final int? score;
  final int? totalQuestions;
  final int attemptCount;

  VideoEnrollmentModel({
    required this.videoId,
    required this.status,
    required this.enrolledAt,
    this.completedAt,
    this.score,
    this.totalQuestions,
    this.attemptCount = 1,
  });

  factory VideoEnrollmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VideoEnrollmentModel(
      videoId: doc.id,
      status: data['status'] ?? 'enrolled',
      enrolledAt: (data['enrolled_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completed_at'] as Timestamp?)?.toDate(),
      score: data['score'],
      totalQuestions: data['total_questions'],
      attemptCount: data['attempt_count'] ?? 1,
    );
  }
}
