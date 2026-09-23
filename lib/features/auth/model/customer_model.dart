import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

part 'customer_model.g.dart';

@HiveType(typeId: 2)
class CustomerModel extends HiveObject {
  @HiveField(0)
  String customerId;

  @HiveField(1)
  String companyName;

  @HiveField(2)
  String email;

  @HiveField(3)
  String phoneNumber;

  /// ⚠️ Stored because Firebase Auth is NOT used
  @HiveField(4)
  String password;

  @HiveField(5)
  String certificateStandard;

  @HiveField(6)
  String numberOfLocations;

  @HiveField(7)
  String numberOfEmployees;

  @HiveField(8)
  String companyFunction;

  @HiveField(9)
  String legitDocumentUrl;

  @HiveField(10)
  bool isProfileApproved;

  @HiveField(11)
  String fcmToken;

  @HiveField(12)
  String roleId;

  @HiveField(13)
  DateTime createdAt;
  @HiveField(14)
  String address;

  // ===============================
  // 🟢 NEW DEPARTMENT DETAILS
  // ===============================

  /// 🔽 Low level department
  @HiveField(15)
  String lowLevelName;

  @HiveField(16)
  String lowLevelEmail;

  @HiveField(17)
  String lowLevelMobile;

  /// 🔶 Medium level department
  @HiveField(18)
  String mediumLevelName;

  @HiveField(19)
  String mediumLevelEmail;

  @HiveField(20)
  String mediumLevelMobile;

  /// 🔺 Top level department
  @HiveField(21)
  String topLevelName;

  @HiveField(22)
  String topLevelEmail;

  @HiveField(23)
  String topLevelMobile;

  @HiveField(24)
  String? consultantId;

  @HiveField(25)
  String? nextVisitDate;


  CustomerModel({
    required this.customerId,
    required this.companyName,
    required this.email,
    required this.phoneNumber,
    required this.password,
    required this.certificateStandard,
    required this.numberOfLocations,
    required this.numberOfEmployees,
    required this.companyFunction,
    required this.legitDocumentUrl,
    required this.isProfileApproved,
    required this.fcmToken,
    required this.roleId,
    required this.createdAt,
    required this.address,
    // 🔽 New
    required this.lowLevelName,
    required this.lowLevelEmail,
    required this.lowLevelMobile,

    required this.mediumLevelName,
    required this.mediumLevelEmail,
    required this.mediumLevelMobile,

    required this.topLevelName,
    required this.topLevelEmail,
    required this.topLevelMobile,

    this.consultantId,
    this.nextVisitDate,
  });
  CustomerModel copyWith({
    String? customerId,
    String? companyName,
    String? phoneNumber,
    String? address,
    String? certificateStandard,
    String? numberOfLocations,
    String? numberOfEmployees,
    String? companyFunction,
    String? legitDocumentUrl,
    String? topLevelName,
    String? topLevelEmail,
    String? topLevelMobile,
    String? mediumLevelName,
    String? mediumLevelEmail,
    String? mediumLevelMobile,
    String? lowLevelName,
    String? lowLevelEmail,
    String? lowLevelMobile,
    bool? isProfileApproved,
    String? nextVisitDate,
    String? consultantId,
    String? email,
    String? password,
    String? fcmToken,
    String? roleId,
    DateTime? createdAt,
  }) {
    return CustomerModel(
      customerId: customerId ?? this.customerId,
      companyName: companyName ?? this.companyName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      password: password ?? this.password,
      certificateStandard: certificateStandard ?? this.certificateStandard,
      numberOfLocations: numberOfLocations ?? this.numberOfLocations,
      numberOfEmployees: numberOfEmployees ?? this.numberOfEmployees,
      companyFunction: companyFunction ?? this.companyFunction,
      legitDocumentUrl: legitDocumentUrl ?? this.legitDocumentUrl,
      isProfileApproved: isProfileApproved ?? this.isProfileApproved,
      fcmToken: fcmToken ?? this.fcmToken,
      roleId: roleId ?? this.roleId,
      createdAt: createdAt ?? this.createdAt,
      address: address ?? this.address,
      topLevelName: topLevelName ?? this.topLevelName,
      topLevelEmail: topLevelEmail ?? this.topLevelEmail,
      topLevelMobile: topLevelMobile ?? this.topLevelMobile,
      mediumLevelName: mediumLevelName ?? this.mediumLevelName,
      mediumLevelEmail: mediumLevelEmail ?? this.mediumLevelEmail,
      mediumLevelMobile: mediumLevelMobile ?? this.mediumLevelMobile,
      lowLevelName: lowLevelName ?? this.lowLevelName,
      lowLevelEmail: lowLevelEmail ?? this.lowLevelEmail,
      lowLevelMobile: lowLevelMobile ?? this.lowLevelMobile,
      nextVisitDate: nextVisitDate ?? this.nextVisitDate,
      consultantId: consultantId ?? this.consultantId,
    );
  }
  /// 🔁 Firestore → CustomerModel
  Map<String, dynamic> toJson() {
  return {
    'customerId': customerId,
    'companyName': companyName,
    'email': email,
    'phoneNumber': phoneNumber,
    'password': password,
    'certificateStandard': certificateStandard,
    'numberOfLocations': numberOfLocations,
    'numberOfEmployees': numberOfEmployees,
    'companyFunction': companyFunction,
    'legitDocumentUrl': legitDocumentUrl,
    'isProfileApproved': isProfileApproved,
    'fcmToken': fcmToken,
    'roleId': roleId,
    'createdAt': Timestamp.fromDate(createdAt),
    'address': address,

    'lowLevelName': lowLevelName,
    'lowLevelEmail': lowLevelEmail,
    'lowLevelMobile': lowLevelMobile,

    'mediumLevelName': mediumLevelName,
    'mediumLevelEmail': mediumLevelEmail,
    'mediumLevelMobile': mediumLevelMobile,

    'topLevelName': topLevelName,
    'topLevelEmail': topLevelEmail,
    'topLevelMobile': topLevelMobile,

    'consultantId': consultantId,
    'nextVisitDate': nextVisitDate,

  };
}


factory CustomerModel.fromJson(
  Map<String, dynamic> json, {
  required String customerId,
}) {
  return CustomerModel(
    customerId: customerId,
    companyName: json['companyName'] ?? '',
    email: json['email'] ?? '',
    phoneNumber: json['phoneNumber'] ?? '',
    password: json['password'] ?? '',
    certificateStandard: json['certificateStandard'] ?? '',
    numberOfLocations: json['numberOfLocations'] ?? '',
    numberOfEmployees: json['numberOfEmployees'] ?? '',
    companyFunction: json['companyFunction'] ?? '',
    legitDocumentUrl: json['legitDocumentUrl'] ?? '',
    isProfileApproved: json['isProfileApproved'] ?? false,
    fcmToken: json['fcmToken'] ?? '',
    roleId: json['roleId'] ?? '',
    createdAt: json['createdAt'] != null
    ? (json['createdAt'] as Timestamp).toDate()
    : DateTime.now(),
    address: json['address'] ?? '',

    // Low
    lowLevelName: _getVal(json, ['lowLevelName', 'low_level_name'], 'lowLevelDepartment', 'name'),
    lowLevelEmail: _getVal(json, ['lowLevelEmail', 'low_level_email'], 'lowLevelDepartment', 'email'),
    lowLevelMobile: _getVal(json, ['lowLevelMobile', 'low_level_mobile'], 'lowLevelDepartment', 'mobile'),

    // Medium
    mediumLevelName: _getVal(json, ['mediumLevelName', 'medium_level_name'], 'mediumLevelDepartment', 'name'),
    mediumLevelEmail: _getVal(json, ['mediumLevelEmail', 'medium_level_email'], 'mediumLevelDepartment', 'email'),
    mediumLevelMobile: _getVal(json, ['mediumLevelMobile', 'medium_level_mobile'], 'mediumLevelDepartment', 'mobile'),

    // Top
    topLevelName: _getVal(json, ['topLevelName', 'top_level_name'], 'topLevelDepartment', 'name'),
    topLevelEmail: _getVal(json, ['topLevelEmail', 'top_level_email'], 'topLevelDepartment', 'email'),
    topLevelMobile: _getVal(json, ['topLevelMobile', 'top_level_mobile'], 'topLevelDepartment', 'mobile'),

    consultantId: json['consultantId'] ?? json['consultant_id'],
    nextVisitDate: json['nextVisitDate'] ?? json['next_visit_date'],
  );
}

static String _getVal(Map<String, dynamic> json, List<String> flatKeys, String nestedKey, String subKey) {
  for (final key in flatKeys) {
    if (json[key] != null && json[key].toString().isNotEmpty) {
      return json[key].toString();
    }
  }
  if (json[nestedKey] != null && json[nestedKey] is Map) {
    return json[nestedKey][subKey]?.toString() ?? '';
  }
  return '';
}

// ✅ ADD THIS
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomerModel &&
          runtimeType == other.runtimeType &&
          customerId.isNotEmpty &&
          customerId == other.customerId);

  @override
  int get hashCode => customerId.hashCode;

}
