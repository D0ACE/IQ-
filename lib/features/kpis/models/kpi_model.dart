import 'package:cloud_firestore/cloud_firestore.dart';

class KpiTask {
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
  final String target;
  final String achieved;
  final String targetType; // 'Percentage' or 'Number'
  final String achievedType; // 'Percentage' or 'Number'
  final DateTime dueDate;
  final String status; // 'pending', 'in_progress', 'completed'
  final DateTime createdAt;
  final String createdBy;
  final String createdByName;
  final String evidenceUrl;
  final String evidenceFileName;
  final bool isAutoGenerate;
  final String frequency; // 'Weekly', 'Monthly', 'Quarterly', 'Biannually', 'Annually'
  final String comment;

  KpiTask({
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
    this.target = '',
    this.achieved = '',
    this.targetType = 'Percentage',
    this.achievedType = 'Percentage',
    required this.dueDate,
    required this.status,
    required this.createdAt,
    required this.createdBy,
    required this.createdByName,
    this.evidenceUrl = '',
    this.evidenceFileName = '',
    this.isAutoGenerate = false,
    this.frequency = 'Monthly',
    this.comment = '',
  });

  bool get isNonCompliant {
    final s = status.toLowerCase();
    if (s == 'completed') return false;
    if (s == 'non_compliant' || s == 'non compliant') return true;
    return dueDate.isBefore(DateTime.now());
  }

  String get effectiveStatus {
    final s = status.toLowerCase();
    if (s == 'completed') return 'completed';
    if (isNonCompliant) return 'non_compliant';
    if (s == 'in_progress' || s == 'in progress') return 'in_progress';
    return 'open';
  }

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
      'target': target,
      'achieved': achieved,
      'targetType': targetType,
      'achievedType': achievedType,
      'dueDate': Timestamp.fromDate(dueDate),
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'createdByName': createdByName,
      'evidenceUrl': evidenceUrl,
      'evidenceFileName': evidenceFileName,
      'isAutoGenerate': isAutoGenerate,
      'frequency': frequency,
      'comment': comment,
    };
  }

  factory KpiTask.fromJson(Map<String, dynamic> json, String id) {
    return KpiTask(
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
      target: (json['target'] ?? json['targetValue'] ?? '').toString(),
      achieved: (json['achieved'] ?? json['achievedValue'] ?? '').toString(),
      targetType: json['targetType'] ?? json['targetUnit'] ?? 'Percentage',
      achievedType: json['achievedType'] ?? json['achievedUnit'] ?? 'Percentage',
      dueDate: json['dueDate'] != null
          ? (json['dueDate'] as Timestamp).toDate()
          : DateTime.now(),
      status: json['status'] ?? 'open',
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      createdBy: json['createdBy'] ?? '',
      createdByName: json['createdByName'] ?? '',
      evidenceUrl: json['evidenceUrl'] ?? json['documentUrl'] ?? '',
      evidenceFileName: json['evidenceFileName'] ?? json['documentName'] ?? '',
      isAutoGenerate: json['isAutoGenerate'] ?? false,
      frequency: json['frequency'] ?? 'Monthly',
      comment: json['comment'] ?? json['comments'] ?? '',
    );
  }

  KpiTask copyWith({
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
    String? target,
    String? achieved,
    String? targetType,
    String? achievedType,
    DateTime? dueDate,
    String? status,
    String? evidenceUrl,
    String? evidenceFileName,
    bool? isAutoGenerate,
    String? frequency,
    String? comment,
  }) {
    return KpiTask(
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
      target: target ?? this.target,
      achieved: achieved ?? this.achieved,
      targetType: targetType ?? this.targetType,
      achievedType: achievedType ?? this.achievedType,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      createdAt: createdAt,
      createdBy: createdBy,
      createdByName: createdByName,
      evidenceUrl: evidenceUrl ?? this.evidenceUrl,
      evidenceFileName: evidenceFileName ?? this.evidenceFileName,
      isAutoGenerate: isAutoGenerate ?? this.isAutoGenerate,
      frequency: frequency ?? this.frequency,
      comment: comment ?? this.comment,
    );
  }
}
