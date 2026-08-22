import 'package:cloud_firestore/cloud_firestore.dart';

class VideoEnrollmentModel {
  final String videoId;
  final String status; // 'enrolled' or 'completed'
  final DateTime enrolledAt;
  final DateTime? completedAt;
  final int? score;
  final int? totalQuestions;

  VideoEnrollmentModel({
    required this.videoId,
    required this.status,
    required this.enrolledAt,
    this.completedAt,
    this.score,
    this.totalQuestions,
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
    );
  }
}
