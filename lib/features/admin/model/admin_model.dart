class AdminModel {
  final String adminId;
  final String userName;
  final String email;
  final String phone;
  final String role;
  final bool isActive;

  AdminModel({
    required this.adminId,
    required this.userName,
    required this.email,
    required this.phone,
    required this.role,
    required this.isActive,
  });

  /// 🔹 Firestore → Model
  factory AdminModel.fromJson(Map<String, dynamic> json) {
    return AdminModel(
      adminId: json['adminId'] ?? '',
      userName: json['userName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'admin',
      isActive: json['isActive'] ?? true,
    );
  }

  /// 🔹 Model → Firestore
  Map<String, dynamic> toJson() {
    return {
      'adminId': adminId,
      'userName': userName,
      'email': email,
      'phone': phone,
      'role': role,
      'isActive': isActive,
    };
  }
}
