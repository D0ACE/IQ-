import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 1)
class UserModel extends HiveObject {
  @HiveField(0)
  String userId;

  @HiveField(1)
  String userName;

  @HiveField(2)
  String email;

  @HiveField(3)
  String phoneNumber;

  /// ⚠️ Plain text because Firebase Auth is NOT used
  @HiveField(4)
  String password;

  @HiveField(5)
  String roleId;

  @HiveField(6)
  bool activeUser;

  @HiveField(7)
  bool blockStatus;

  @HiveField(8)
  String fcmToken;

  @HiveField(9)
  DateTime createdAt;

  UserModel({
    required this.userId,
    required this.userName,
    required this.email,
    required this.phoneNumber,
    required this.password,
    required this.roleId,
    required this.activeUser,
    required this.blockStatus,
    required this.fcmToken,
    required this.createdAt,
  });
}
