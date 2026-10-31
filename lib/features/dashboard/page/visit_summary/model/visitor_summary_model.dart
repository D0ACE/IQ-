import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iq_plus/common/utility/utility.dart';

class VisitorSummaryModel {
  final String id;

  final String customerId;
  final String consultantId;

  final String location;

  final String? visitDate;
  final String loginTime;
  final String logoutTime;

  String get fromTime => loginTime;
  String get toTime => logoutTime;

  final String purpose;
  final String consultantCoachName;
  String get officerName => consultantCoachName;

  final String department;

  final List<String> scopeOfReview;

  final List<ObservationModel> observations;

  final String complianceStatus;
  final String complianceComments;

  final List<NonComplianceModel> nonCompliances;
  final List<CapaModel> capas;

  final String clientFeedback;
  final String overallAssessment;

  final SignOffModel signOff;

  final Timestamp? createdAt;

  VisitorSummaryModel({
    required this.id,
    required this.customerId,
    required this.consultantId,
    required this.location,
    required this.visitDate,
    required this.loginTime,
    required this.logoutTime,
    required this.purpose,
    required this.consultantCoachName,
    required this.department,
    required this.scopeOfReview,
    this.observations = const [],
    required this.complianceStatus,
    required this.complianceComments,
    required this.nonCompliances,
    required this.capas,
    required this.clientFeedback,
    this.overallAssessment = '',
    required this.signOff,
    required this.createdAt,
  });

  // -------------------------------
  // 🔹 Firestore → Model
  // -------------------------------
  factory VisitorSummaryModel.fromJson(
      String id,
      Map<String, dynamic> json,
      ) {
    return VisitorSummaryModel(
      id: id,
      customerId: json['customerId'] ?? '',
      consultantId: json['consultantId'] ?? '',
      location: json['location'] ?? '',
      visitDate: Utility.formatTimestamp(json['visitDate']),
      loginTime: json['loginTime'] ?? json['fromTime'] ?? '',
      logoutTime: json['logoutTime'] ?? json['toTime'] ?? '',
      purpose: json['purpose'] ?? '',
      consultantCoachName: json['consultantCoachName'] ?? json['officerName'] ?? '',
      department: json['department'] ?? '',
      scopeOfReview: (json['scopeOfReview'] is List)
          ? (json['scopeOfReview'] as List).map((e) => e.toString()).toList()
          : (json['scopeOfReview'] is Map)
              ? (json['scopeOfReview'] as Map).keys.map((k) => k.toString()).toList()
              : [],
      observations: (json['observations'] as List<dynamic>? ?? [])
          .map((e) => ObservationModel.fromJson(e))
          .toList(),
      complianceStatus: json['complianceStatus'] ?? '',
      complianceComments: json['complianceComments'] ?? '',
      nonCompliances: (json['nonCompliances'] as List<dynamic>? ?? [])
          .map((e) => NonComplianceModel.fromJson(e))
          .toList(),
      capas: (json['capas'] as List<dynamic>? ?? [])
          .map((e) => CapaModel.fromJson(e))
          .toList(),
      clientFeedback: json['clientFeedback'] ?? '',
      overallAssessment: json['overallAssessment'] ?? '',
      signOff: SignOffModel.fromJson(json['signOff'] ?? {}),
      createdAt: json['createdAt'] is Timestamp ? json['createdAt'] as Timestamp : null,
    );
  }

  // -------------------------------
  // 🔹 Model → Firestore
  // -------------------------------
  Map<String, dynamic> toJson() {
    return {
      'customerId': customerId,
      'consultantId': consultantId,
      'location': location,
      'visitDate': visitDate,
      'loginTime': loginTime,
      'logoutTime': logoutTime,
      'purpose': purpose,
      'consultantCoachName': consultantCoachName,
      'department': department,
      'scopeOfReview': scopeOfReview,
      'observations': observations.map((e) => e.toJson()).toList(),
      'complianceStatus': complianceStatus,
      'complianceComments': complianceComments,
      'nonCompliances': nonCompliances.map((e) => e.toJson()).toList(),
      'capas': capas.map((e) => e.toJson()).toList(),
      'clientFeedback': clientFeedback,
      'overallAssessment': overallAssessment,
      'signOff': signOff.toJson(),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

/* ================================
   🔹 SUB MODELS
================================ */

class ObservationModel {
  final String obs;
  final String process;
  final String severity;

  ObservationModel({
    required this.obs,
    required this.process,
    required this.severity,
  });

  factory ObservationModel.fromJson(Map<String, dynamic> json) {
    return ObservationModel(
      obs: json['obs'] ?? '',
      process: json['process'] ?? '',
      severity: json['severity'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'obs': obs,
    'process': process,
    'severity': severity,
  };
}

class NonComplianceModel {
  final String gap;
  final String category;
  final String actionRequired;
  final String responsible;
  final String? targetDate;

  String get root => category;
  String get impact => actionRequired;

  NonComplianceModel({
    required this.gap,
    this.category = 'Minor',
    this.actionRequired = '',
    this.responsible = '',
    this.targetDate,
  });

  factory NonComplianceModel.fromJson(Map<String, dynamic> json) {
    return NonComplianceModel(
      gap: json['descriptionOfNc'] ?? json['gap'] ?? '',
      category: json['categoryOfNc'] ?? json['category'] ?? json['root'] ?? 'Minor',
      actionRequired: json['actionRequired'] ?? json['impact'] ?? '',
      responsible: json['responsible'] ?? '',
      targetDate: Utility.formatTimestamp(json['targetDate'] ?? json['targetDateStr'] ?? json['date']),
    );
  }

  Map<String, dynamic> toJson() => {
    'gap': gap,
    'category': category,
    'actionRequired': actionRequired,
    'responsible': responsible,
    'targetDate': targetDate,
  };
}

class CapaModel {
  final String action;
  final String rootCause;
  final String owner;
  final String? date;
  final String actionTakenBy;
  final String evidence;

  CapaModel({
    required this.action,
    required this.rootCause,
    String? owner,
    required this.date,
    this.actionTakenBy = '',
    this.evidence = '',
  }) : owner = owner ?? rootCause;

  factory CapaModel.fromJson(Map<String, dynamic> json) {
    return CapaModel(
      action: json['actionTaken'] ?? json['action'] ?? '',
      rootCause: json['rootCause'] ?? json['owner'] ?? '',
      date: Utility.formatTimestamp(json['dateOfAction'] ?? json['date']),
      actionTakenBy: json['actionTakenBy'] ?? '',
      evidence: json['evidence'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'action': action,
    'rootCause': rootCause,
    'date': date,
    'actionTakenBy': actionTakenBy,
    'evidence': evidence,
  };
}

class SignOffModel {
  final String consultantCoachName;
  String get officerName => consultantCoachName;
  final String officerSign;
  final String clientName;
  final String clientSign;
  final String? signDate;

  SignOffModel({
    required this.consultantCoachName,
    required this.officerSign,
    required this.clientName,
    required this.clientSign,
    required this.signDate,
  });

  factory SignOffModel.fromJson(Map<String, dynamic> json) {
    return SignOffModel(
      consultantCoachName: json['consultantCoachName'] ?? json['officerName'] ?? '',
      officerSign: json['officerSign'] ?? '',
      clientName: json['clientName'] ?? '',
      clientSign: json['clientSign'] ?? '',
      signDate: Utility.formatTimestamp(json['signDate']),
    );
  }

  Map<String, dynamic> toJson() => {
    'consultantCoachName': consultantCoachName,
    'officerSign': officerSign,
    'clientName': clientName,
    'clientSign': clientSign,
    'signDate': signDate,
  };
}
