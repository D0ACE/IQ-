import 'package:cloud_firestore/cloud_firestore.dart';

class EmployeeUserModel {
  final String userId;
  final String userName;
  final String email;
  final String phoneNumber;
  final String roleId;
  final String password;
  final DateTime createdAt;
  final DateTime? joiningDate;
  final bool blockStatus;

  EmployeeUserModel({
    required this.userId,
    required this.userName,
    required this.email,
    required this.phoneNumber,
    required this.roleId,
    required this.password,
    required this.createdAt,
    required this.blockStatus,
     this.joiningDate,
  });

  factory EmployeeUserModel.fromFirestore(String id, Map<String, dynamic> json) {
    return EmployeeUserModel(
      userId: id,
      userName: json['userName'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      roleId: json['roleId'] ?? '',
      password: json['password'] ?? '',
      blockStatus: json['blockStatus'] ?? '',
      joiningDate: json['joiningDate'] is Timestamp?(json['joiningDate'] as Timestamp).toDate():null,

      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }
}
