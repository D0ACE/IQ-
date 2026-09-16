import 'package:cloud_firestore/cloud_firestore.dart';

class SystemUserModel {
  final String userId;
  final String userName;
  final String email;
  final String phoneNumber;
  final String roleId;
  final String password;
  final bool activeUser;
  final bool blockStatus;
  final String fcmToken;
  final DateTime createdAt;

  SystemUserModel({
    required this.userId,
    required this.userName,
    required this.email,
    required this.phoneNumber,
    required this.roleId,
    required this.password,
    required this.activeUser,
    required this.blockStatus,
    required this.fcmToken,
    required this.createdAt,
  });

  factory SystemUserModel.fromFirestore(String id, Map<String, dynamic> json) {
    return SystemUserModel(
      userId: id,
      userName: json['userName'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      roleId: json['roleId'] ?? '',
      password: json['password'] ?? '',
      activeUser: json['activeUser'] ?? true,
      blockStatus: json['blockStatus'] ?? false,
      fcmToken: json['fcmToken'] ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "userName": userName,
      "email": email,
      "phoneNumber": phoneNumber,
      "password": password,
      "roleId": roleId,
      "activeUser": activeUser,
      "blockStatus": blockStatus,
      "fcmToken": fcmToken,
      "createdAt": createdAt,
    };
  }
}
