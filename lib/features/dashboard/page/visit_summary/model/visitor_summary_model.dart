import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:iq_plus/common/utility/utility.dart';

class VisitorSummaryModel {
  final String id;

  final String customerId;
  final String consultantId;

  final String clientName;
  final String location;

  final String? visitDate;
  final String fromTime;
  final String toTime;

  final String purpose;
  final String officerName;
  final String department;

  final Map<String, dynamic> scopeOfReview;

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
    required this.clientName,
    required this.location,
    required this.visitDate,
    required this.fromTime,
    required this.toTime,
    required this.purpose,
    required this.officerName,
    required this.department,
    required this.scopeOfReview,
    required this.observations,
    required this.complianceStatus,
    required this.complianceComments,
    required this.nonCompliances,
    required this.capas,
    required this.clientFeedback,
    required this.overallAssessment,
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
      clientName: json['clientName'] ?? '',
      location: json['location'] ?? '',
      visitDate:Utility.formatTimestamp(json['visitDate']),
      fromTime: json['fromTime'] ?? '',
      toTime: json['toTime'] ?? '',
      purpose: json['purpose'] ?? '',
      officerName: json['officerName'] ?? '',
      department: json['department'] ?? '',
      scopeOfReview: Map<String, dynamic>.from(
        json['scopeOfReview'] ?? {},
      ),
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
      createdAt: json['createdAt'] as Timestamp?,
    );
  }

  // -------------------------------
  // 🔹 Model → Firestore
  // -------------------------------
  Map<String, dynamic> toJson() {
    return {
      'customerId': customerId,
      'consultantId': consultantId,
      'clientName': clientName,
      'location': location,
      'visitDate': visitDate,
      'fromTime': fromTime,
      'toTime': toTime,
      'purpose': purpose,
      'officerName': officerName,
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
  final String root;
  final String impact;

  NonComplianceModel({
    required this.gap,
    required this.root,
    required this.impact,
  });

  factory NonComplianceModel.fromJson(Map<String, dynamic> json) {
    return NonComplianceModel(
      gap: json['gap'] ?? '',
      root: json['root'] ?? '',
      impact: json['impact'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'gap': gap,
    'root': root,
    'impact': impact,
  };
}

class CapaModel {
  final String action;
  final String owner;
  final String? date;

  CapaModel({
    required this.action,
    required this.owner,
    required this.date,
  });

  factory CapaModel.fromJson(Map<String, dynamic> json) {
    return CapaModel(
      action: json['action'] ?? '',
      owner: json['owner'] ?? '',
      date: Utility.formatTimestamp(json['date'] as Timestamp?),
    );
  }

  Map<String, dynamic> toJson() => {
    'action': action,
    'owner': owner,
    'date': date,
  };
}

class SignOffModel {
  final String officerName;
  final String officerSign;
  final String clientName;
  final String clientSign;
  final String? signDate;

  SignOffModel({
    required this.officerName,
    required this.officerSign,
    required this.clientName,
    required this.clientSign,
    required this.signDate,
  });

  factory SignOffModel.fromJson(Map<String, dynamic> json) {
    return SignOffModel(
      officerName: json['officerName'] ?? '',
      officerSign: json['officerSign'] ?? '',
      clientName: json['clientName'] ?? '',
      clientSign: json['clientSign'] ?? '',
      signDate: Utility.formatTimestamp(json['signDate'] as Timestamp?),
    );
  }

  Map<String, dynamic> toJson() => {
    'officerName': officerName,
    'officerSign': officerSign,
    'clientName': clientName,
    'clientSign': clientSign,
    'signDate': signDate,
  };
}
