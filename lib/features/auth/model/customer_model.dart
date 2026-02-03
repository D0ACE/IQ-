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
}) {
  return CustomerModel(
    customerId: customerId ?? this.customerId,
    companyName: companyName ?? this.companyName,
    email: email,
    phoneNumber: phoneNumber ?? this.phoneNumber,
    password: password,
    certificateStandard: certificateStandard ?? this.certificateStandard,
    numberOfLocations: numberOfLocations ?? this.numberOfLocations,
    numberOfEmployees: numberOfEmployees ?? this.numberOfEmployees,
    companyFunction: companyFunction,
    legitDocumentUrl: legitDocumentUrl,
    isProfileApproved: isProfileApproved ?? this.isProfileApproved,
    fcmToken: fcmToken,
    roleId: roleId,
    createdAt: createdAt,
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
    lowLevelName: json['lowLevelDepartment']?['name'] ?? '',
    lowLevelEmail: json['lowLevelDepartment']?['email'] ?? '',
    lowLevelMobile: json['lowLevelDepartment']?['mobile'] ?? '',

    // Medium
    mediumLevelName: json['mediumLevelDepartment']?['name'] ?? '',
    mediumLevelEmail: json['mediumLevelDepartment']?['email'] ?? '',
    mediumLevelMobile: json['mediumLevelDepartment']?['mobile'] ?? '',

    // Top
    topLevelName: json['topLevelDepartment']?['name'] ?? '',
    topLevelEmail: json['topLevelDepartment']?['email'] ?? '',
    topLevelMobile: json['topLevelDepartment']?['mobile'] ?? '',

    consultantId: json['consultantId'],
    nextVisitDate: json['nextVisitDate'],
  );
}


}
