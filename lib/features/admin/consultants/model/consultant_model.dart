import 'package:cloud_firestore/cloud_firestore.dart';

class ConsultantModel {
  final String id;
  final String userName;

  ConsultantModel({
    required this.id,
    required this.userName,
  });

  // Factory constructor from Firestore document
  factory ConsultantModel.fromFirestore(String id, Map<String, dynamic> data) {
    return ConsultantModel(
      id: id,
      userName: data['userName'] ?? '',
    );
  }
}

// Function to fetch all consultants
Future<List<ConsultantModel>> getConsultants() async {
  final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .where('roleId', isEqualTo: '2') // only consultants
      .where('activeUser', isEqualTo: true) // only active users
      .get();

  return snapshot.docs
      .map((doc) => ConsultantModel.fromFirestore(doc.id, doc.data()))
      .toList();
}
