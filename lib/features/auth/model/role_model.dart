class RoleModel {
  final String id;
  final String name;

  RoleModel({
    required this.id,
    required this.name,
  });

  // Factory constructor from Firestore document
  factory RoleModel.passValues(String id, String name) {
    return RoleModel(
      id: id,
      name: name,
    );
  }

  factory RoleModel.fromFirestore(Map<String, dynamic> json) {
    return RoleModel(
      id: json['roleId'] ?? '',
      name: json['roleName'] ?? '',
    );
  }
}