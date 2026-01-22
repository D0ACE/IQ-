import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerMMEModel {
  final String? docId;
  final String id;
  final String customerId;
  final String serialNumber;
  final String deviceName;
  final DateTime lastCalibrationDate;
  final DateTime nextCalibrationDate;

  CustomerMMEModel({
     this.docId,
    required this.id,
    required this.customerId,
    required this.serialNumber,
    required this.deviceName,
    required this.lastCalibrationDate,
    required this.nextCalibrationDate,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'customerId': customerId,
    'serialNumber': serialNumber,
    'deviceName': deviceName,
    'lastCalibrationDate': lastCalibrationDate,
    'nextCalibrationDate': nextCalibrationDate,
    'createdAt': FieldValue.serverTimestamp(),
  };

  factory CustomerMMEModel.fromMap(String docId,Map<String, dynamic> map) {
    return CustomerMMEModel(
      docId: docId,
      id: map['id'],
      customerId: map['customerId'],
      serialNumber: map['serialNumber'],
      deviceName: map['deviceName'],
      lastCalibrationDate: map['lastCalibrationDate'].toDate(),
      nextCalibrationDate: map['nextCalibrationDate'].toDate(),
    );
  }
}
