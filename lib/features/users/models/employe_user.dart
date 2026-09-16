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
  final bool activeUser; // 👈 Add this field
  final String? designation;
  final String? customerId;
  final String? createdBy; // 👈 User ID of the person who created this employee

  EmployeeUserModel({
    required this.userId,
    required this.userName,
    required this.email,
    required this.phoneNumber,
    required this.roleId,
    required this.password,
    required this.createdAt,
    required this.blockStatus,
    required this.activeUser, // 👈 Add this
    this.joiningDate,
    this.designation,
    this.customerId,
    this.createdBy,
  });

  factory EmployeeUserModel.fromFirestore(String id, Map<String, dynamic> json) {
    return EmployeeUserModel(
      userId: id,
      userName: json['userName'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      roleId: json['roleId'] ?? '',
      password: json['password'] ?? '',
      blockStatus: json['blockStatus'] ?? false,
      activeUser: json['activeUser'] ?? true, // 👈 Add this
      joiningDate: json['joiningDate'] is Timestamp ? (json['joiningDate'] as Timestamp).toDate() : null,
      designation: json['designation'],
      customerId: json['customerId'],
      createdBy: json['createdBy'],
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
