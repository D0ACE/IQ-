import 'package:cloud_firestore/cloud_firestore.dart';

class AwarenessQuestionModel {
  final String question;
  final List<String> options;
  final int correctOptionIndex;

  AwarenessQuestionModel({
    required this.question,
    required this.options,
    required this.correctOptionIndex,
  });

  Map<String, dynamic> toJson() => {
    'question': question,
    'options': options,
    'correct_option_index': correctOptionIndex,
  };

  factory AwarenessQuestionModel.fromJson(Map<String, dynamic> json) => AwarenessQuestionModel(
    question: json['question'] ?? '',
    options: List<String>.from(json['options'] ?? []),
    correctOptionIndex: json['correct_option_index'] ?? 0,
  );
}

class AwarenessVideoModel {
  final String videoId;
  final String title;
  final String videoUrl;
  final String fileName;
  final String filePath;
  final String createdBy; 
  final String? customerId; 
  final List<AwarenessQuestionModel> questions; 
  final DateTime createdAt;

  AwarenessVideoModel({
    required this.videoId,
    required this.title,
    required this.videoUrl,
    required this.fileName,
    required this.filePath,
    required this.createdBy,
    this.customerId,
    required this.questions,
    required this.createdAt,
  });

  factory AwarenessVideoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AwarenessVideoModel(
      videoId: doc.id,
      title: data['title'] ?? '',
      videoUrl: data['video_url'] ?? '',
      fileName: data['file_name'] ?? '',
      filePath: data['file_path'] ?? '',
      createdBy: data['created_by'] ?? '',
      customerId: data['customer_id'],
      questions: (data['questions'] as List?)
          ?.map((q) => AwarenessQuestionModel.fromJson(q as Map<String, dynamic>))
          .toList() ?? [],
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'video_url': videoUrl,
      'file_name': fileName,
      'file_path': filePath,
      'created_by': createdBy,
      'customer_id': customerId,
      'questions': questions.map((AwarenessQuestionModel q) => q.toJson()).toList(),
      'created_at': FieldValue.serverTimestamp(),
    };
  }
}
