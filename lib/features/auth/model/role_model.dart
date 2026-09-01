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
    final String rId = json['roleId'] ?? '';
    String rName = json['roleName'] ?? '';

    // 🚀 Map "User" (Role 2) to "Consultant" for display
    if (rId == '2' || rName.toLowerCase() == 'user') {
      rName = 'Consultant';
    }

    return RoleModel(
      id: rId,
      customerId: '',
      name: rName,
    );
  }
}
