import 'package:cloud_firestore/cloud_firestore.dart';

class PeriodicComplianceTask {
  final String id;
  final String title;
  final String description;
  final String assignedCustomerId;
  final String assignedCustomerName;
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
    DateTime? dueDate,
    String? status,
  }) {
    return PeriodicComplianceTask(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      assignedCustomerId: assignedCustomerId ?? this.assignedCustomerId,
      assignedCustomerName: assignedCustomerName ?? this.assignedCustomerName,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      createdAt: createdAt,
      createdBy: createdBy,
      createdByName: createdByName,
    );
  }
}
