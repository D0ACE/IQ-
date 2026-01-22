import 'package:cloud_firestore/cloud_firestore.dart';

class VisitorSummaryModel {
  final String id;
  final Map<String, dynamic> data;

  VisitorSummaryModel({
    required this.id,
    required this.data,
  });

  Map<String, dynamic> toMap() => {
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
      };

  factory VisitorSummaryModel.fromFirestore(
      String id, Map<String, dynamic> json) {
    return VisitorSummaryModel(id: id, data: json);
  }
}
