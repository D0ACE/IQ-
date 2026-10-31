import 'package:cloud_firestore/cloud_firestore.dart';

class EmployeeUserModel {
  static const List<String> defaultModules = ['Training Videos'];
  static const List<String> allModuleOptions = [
    'NCR',
    'Visit Summary',
    'Policies & Procedures',
    'Policy History',
    'Employees',
    'Training Videos',
    'Compliance Tasks',
  ];

  final String userId;
  final String userName;
  final String email;
  final String phoneNumber;
  final String roleId;
  final String password;
  final DateTime createdAt;
  final DateTime? joiningDate;
  final bool blockStatus;
  final String? designation;
  final String? customerId;
  final String? createdBy; // 👈 User ID of the person who created this employee
  final List<String> visibleModules;
  final bool isOtherEmployee;

  EmployeeUserModel({
    required this.userId,
    required this.userName,
    required this.email,
    required this.phoneNumber,
    required this.roleId,
    required this.password,
    required this.createdAt,
    required this.blockStatus,
    this.joiningDate,
    this.designation,
    this.customerId,
    this.createdBy,
    this.visibleModules = defaultModules,
    this.isOtherEmployee = false,
  });

  factory EmployeeUserModel.fromFirestore(String id, Map<String, dynamic> json, {String? pathCustomerId}) {
    List<String> modules = defaultModules;
    if (json['visibleModules'] != null) {
      modules = List<String>.from(json['visibleModules']);
    }

    return EmployeeUserModel(
      userId: id,
      userName: json['userName'] ?? json['name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      roleId: json['roleId'] ?? '',
      password: json['password'] ?? '',
      blockStatus: json['blockStatus'] ?? false,
      joiningDate: json['joiningDate'] is Timestamp ? (json['joiningDate'] as Timestamp).toDate() : null,
      designation: json['designation'],
      customerId: json['customerId'] ?? json['companyId'] ?? json['customer_id'] ?? pathCustomerId,
      createdBy: json['createdBy'],
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      visibleModules: modules,
      isOtherEmployee: json['isOtherEmployee'] ?? json['is_other_employee'] ?? false,
    );
  }
}
