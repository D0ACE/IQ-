import 'package:cloud_firestore/cloud_firestore.dart';

class PeriodicComplianceTask {
  final String id;
  final String title;
  final String description;
  final String assignedCustomerId;
  final String assignedCustomerName;
  final String assignedCustomerLowLevelName;
  final String assignedCustomerLowLevelEmail;
  final String assignedCustomerLowLevelMobile;
  final String assignedCustomerMediumLevelName;
  final String assignedCustomerMediumLevelEmail;
  final String assignedCustomerMediumLevelMobile;
  final DateTime dueDate;
  final String status; // 'pending', 'completed'
  final DateTime createdAt;
  final String createdBy;
  final String createdByName;

  PeriodicComplianceTask({
    required this.id,
    required this.title,
    required this.description,
    required this.assignedCustomerId,
    required this.assignedCustomerName,
    this.assignedCustomerLowLevelName = '',
    this.assignedCustomerLowLevelEmail = '',
    this.assignedCustomerLowLevelMobile = '',
    this.assignedCustomerMediumLevelName = '',
    this.assignedCustomerMediumLevelEmail = '',
    this.assignedCustomerMediumLevelMobile = '',
    required this.dueDate,
    required this.status,
    required this.createdAt,
    required this.createdBy,
    required this.createdByName,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'assignedCustomerId': assignedCustomerId,
      'assignedCustomerName': assignedCustomerName,
      'assignedCustomerLowLevelName': assignedCustomerLowLevelName,
      'assignedCustomerLowLevelEmail': assignedCustomerLowLevelEmail,
      'assignedCustomerLowLevelMobile': assignedCustomerLowLevelMobile,
      'assignedCustomerMediumLevelName': assignedCustomerMediumLevelName,
      'assignedCustomerMediumLevelEmail': assignedCustomerMediumLevelEmail,
      'assignedCustomerMediumLevelMobile': assignedCustomerMediumLevelMobile,
      'dueDate': Timestamp.fromDate(dueDate),
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'createdByName': createdByName,
    };
  }

  factory PeriodicComplianceTask.fromJson(Map<String, dynamic> json, String id) {
    return PeriodicComplianceTask(
      id: id,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      assignedCustomerId: json['assignedCustomerId'] ?? '',
      assignedCustomerName: json['assignedCustomerName'] ?? '',
      assignedCustomerLowLevelName: json['assignedCustomerLowLevelName'] ?? json['assignedCustomerLowName'] ?? '',
      assignedCustomerLowLevelEmail: json['assignedCustomerLowLevelEmail'] ?? json['assignedCustomerLowEmail'] ?? '',
      assignedCustomerLowLevelMobile: json['assignedCustomerLowLevelMobile'] ?? json['assignedCustomerLowMobile'] ?? '',
      assignedCustomerMediumLevelName: json['assignedCustomerMediumLevelName'] ?? json['assignedCustomerMediumName'] ?? '',
      assignedCustomerMediumLevelEmail: json['assignedCustomerMediumLevelEmail'] ?? json['assignedCustomerMediumEmail'] ?? '',
      assignedCustomerMediumLevelMobile: json['assignedCustomerMediumLevelMobile'] ?? json['assignedCustomerMediumMobile'] ?? '',
      dueDate: json['dueDate'] != null
          ? (json['dueDate'] as Timestamp).toDate()
          : DateTime.now(),
      status: json['status'] ?? 'pending',
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      createdBy: json['createdBy'] ?? '',
      createdByName: json['createdByName'] ?? '',
    );
  }

  PeriodicComplianceTask copyWith({
    String? title,
    String? description,
    String? assignedCustomerId,
    String? assignedCustomerName,
    String? assignedCustomerLowLevelName,
    String? assignedCustomerLowLevelEmail,
    String? assignedCustomerLowLevelMobile,
    String? assignedCustomerMediumLevelName,
    String? assignedCustomerMediumLevelEmail,
    String? assignedCustomerMediumLevelMobile,
    DateTime? dueDate,
    String? status,
  }) {
    return PeriodicComplianceTask(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      assignedCustomerId: assignedCustomerId ?? this.assignedCustomerId,
      assignedCustomerName: assignedCustomerName ?? this.assignedCustomerName,
      assignedCustomerLowLevelName: assignedCustomerLowLevelName ?? this.assignedCustomerLowLevelName,
      assignedCustomerLowLevelEmail: assignedCustomerLowLevelEmail ?? this.assignedCustomerLowLevelEmail,
      assignedCustomerLowLevelMobile: assignedCustomerLowLevelMobile ?? this.assignedCustomerLowLevelMobile,
      assignedCustomerMediumLevelName: assignedCustomerMediumLevelName ?? this.assignedCustomerMediumLevelName,
      assignedCustomerMediumLevelEmail: assignedCustomerMediumLevelEmail ?? this.assignedCustomerMediumLevelEmail,
      assignedCustomerMediumLevelMobile: assignedCustomerMediumLevelMobile ?? this.assignedCustomerMediumLevelMobile,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      createdAt: createdAt,
      createdBy: createdBy,
      createdByName: createdByName,
    );
  }
}
