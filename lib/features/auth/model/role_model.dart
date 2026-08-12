class RoleModel {
  final String id;
  final String customerId;
  final String name;

  RoleModel({
    required this.id,
    required this.customerId,
    required this.name,
  });

  // Factory constructor from Firestore document
  factory RoleModel.passValues(String id, String customerId, String name) {
    return RoleModel(
      id: id,
      customerId: customerId,
      name: name,
    );
  }

  factory RoleModel.fromFirestore(Map<String, dynamic> json) {
    return RoleModel(
      id: json['roleId'] ?? '',
      customerId: '',
      name: json['roleName'] ?? '',
    );
  }
}