import 'package:cloud_firestore/cloud_firestore.dart';

class NcrFormModel {
  String process;
  String iqaNo;
  String clause;
  String ncrNo;
  String statement;
  String evidence;
  String classification;
  String dueDate;
  String correction;
  String plannedDate;
  String actualDate;
  String rootCause;
  String correctiveAction;
  String verification;
  String auditor;
  String approvedBy;
  String consultantId;
  String companyId;
  String employeeId;
  String employeeName;
  String employeeEmail;
  String status;
  Timestamp createdAt;

  NcrFormModel({
    required this.process,
    required this.iqaNo,
    required this.clause,
    required this.ncrNo,
    required this.statement,
    required this.evidence,
    required this.classification,
    required this.dueDate,
    required this.correction,
    required this.plannedDate,
    required this.actualDate,
    required this.rootCause,
    required this.correctiveAction,
    required this.verification,
    required this.auditor,
    required this.approvedBy,
    required this.consultantId,
    required this.companyId,
    required this.employeeId,
    required this.employeeName,
    required this.employeeEmail,
    required this.status,
    required this.createdAt,
  });

  /// 🔹 Convert model to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'process': process,
      'iqaNo': iqaNo,
      'clause': clause,
      'ncrNo': ncrNo,
      'statement': statement,
      'evidence': evidence,
      'classification': classification,
      'dueDate': dueDate,
      'correction': correction,
      'plannedDate': plannedDate,
      'actualDate': actualDate,
      'rootCause': rootCause,
      'correctiveAction': correctiveAction,
      'verification': verification,
      'auditor': auditor,
      'approvedBy': approvedBy,
      'consultantId': consultantId,
      'customerId': companyId,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'employeeEmail': employeeEmail,
      'status': status,
      'createdAt': createdAt,
    };
  }
}

