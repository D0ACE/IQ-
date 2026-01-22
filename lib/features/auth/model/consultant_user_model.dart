class ConsultantUserModel {
  final String userId;
  final String userName;
  final String email;
  final String phoneNumber;
  final String roleId;

  ConsultantUserModel({
    required this.userId,
    required this.userName,
    required this.email,
    required this.phoneNumber,
    required this.roleId,
  });

  factory ConsultantUserModel.fromFirestore(String id, Map<String, dynamic> json) {
    return ConsultantUserModel(
      userId: id,
      userName: json['userName'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      roleId: json['roleId'] ?? '',
    );
  }
}
