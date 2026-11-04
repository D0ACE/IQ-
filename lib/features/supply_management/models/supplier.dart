import 'contact_person.dart';

class Supplier {
  final String id; // Format: MSP/NN
  final String name;
  final String address;
  final String? factoryAddress;
  final String phone;
  final String? fax;
  final String? email;
  final int? yearEstablished;
  final String natureOfBusiness; // Manufacturer / Dealer
  final String? dealerFor;
  final String? mdName;
  final List<ContactPerson> contacts;
  final String productRange;
  final String? otherFirmAssessment;
  final String? qcSystem;
  final int? manpowerQualified;
  final int? manpowerSkilled;
  final int? manpowerUnskilled;
  final String? machinery;
  final String? annualTurnover;
  final String? gstNo;
  final String? bankers;
  final String? majorCustomers;
  final String evaluationMethod; // On-site / Sample / Based on Brand
  final String purchaseMethod; // Verbal / With PO
  final bool recommended; // true for Yes, false for No
  final String? preparedBy;
  final String? approvedBy;
  final String dateOfInclusion; // dd-MM-yyyy
  final String status; // Approved / Temporary / Not Recommended / Non-existing
  final String category; // Fixed Assets / Spare Parts / Consumables / Services
  final DateTime createdAt;
  final String? registeredBy;
  final String? registeredByRole;

  Supplier({
    required this.id,
    required this.name,
    required this.address,
    this.factoryAddress,
    required this.phone,
    this.fax,
    this.email,
    this.yearEstablished,
    required this.natureOfBusiness,
    this.dealerFor,
    this.mdName,
    required this.contacts,
    required this.productRange,
    this.otherFirmAssessment,
    this.qcSystem,
    this.manpowerQualified,
    this.manpowerSkilled,
    this.manpowerUnskilled,
    this.machinery,
    this.annualTurnover,
    this.gstNo,
    this.bankers,
    this.majorCustomers,
    required this.evaluationMethod,
    required this.purchaseMethod,
    required this.recommended,
    this.preparedBy,
    this.approvedBy,
    required this.dateOfInclusion,
    required this.status,
    required this.category,
    required this.createdAt,
    this.registeredBy,
    this.registeredByRole,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'factoryAddress': factoryAddress,
      'phone': phone,
      'fax': fax,
      'email': email,
      'yearEstablished': yearEstablished,
      'natureOfBusiness': natureOfBusiness,
      'dealerFor': dealerFor,
      'mdName': mdName,
      'contacts': contacts.map((c) => c.toJson()).toList(),
      'productRange': productRange,
      'otherFirmAssessment': otherFirmAssessment,
      'qcSystem': qcSystem,
      'manpowerQualified': manpowerQualified,
      'manpowerSkilled': manpowerSkilled,
      'manpowerUnskilled': manpowerUnskilled,
      'machinery': machinery,
      'annualTurnover': annualTurnover,
      'gstNo': gstNo,
      'bankers': bankers,
      'majorCustomers': majorCustomers,
      'evaluationMethod': evaluationMethod,
      'purchaseMethod': purchaseMethod,
      'recommended': recommended,
      'preparedBy': preparedBy,
      'approvedBy': approvedBy,
      'dateOfInclusion': dateOfInclusion,
      'status': status,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'registeredBy': registeredBy,
      'registeredByRole': registeredByRole,
    };
  }

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      factoryAddress: json['factoryAddress'] as String?,
      phone: json['phone'] as String? ?? '',
      fax: json['fax'] as String?,
      email: json['email'] as String?,
      yearEstablished: json['yearEstablished'] as int?,
      natureOfBusiness: json['natureOfBusiness'] as String? ?? 'Manufacturer',
      dealerFor: json['dealerFor'] as String?,
      mdName: json['mdName'] as String?,
      contacts: (json['contacts'] as List<dynamic>? ?? [])
          .map((c) => ContactPerson.fromJson(c as Map<String, dynamic>))
          .toList(),
      productRange: json['productRange'] as String? ?? '',
      otherFirmAssessment: json['otherFirmAssessment'] as String?,
      qcSystem: json['qcSystem'] as String?,
      manpowerQualified: json['manpowerQualified'] as int?,
      manpowerSkilled: json['manpowerSkilled'] as int?,
      manpowerUnskilled: json['manpowerUnskilled'] as int?,
      machinery: json['machinery'] as String?,
      annualTurnover: json['annualTurnover']?.toString(),
      gstNo: json['gstNo'] as String?,
      bankers: json['bankers'] as String?,
      majorCustomers: json['majorCustomers'] as String?,
      evaluationMethod: json['evaluationMethod'] as String? ?? 'Based on Brand',
      purchaseMethod: json['purchaseMethod'] as String? ?? 'With PO',
      recommended: json['recommended'] as bool? ?? true,
      preparedBy: json['preparedBy'] as String?,
      approvedBy: json['approvedBy'] as String?,
      dateOfInclusion: json['dateOfInclusion'] as String? ?? '',
      status: json['status'] as String? ?? 'Approved',
      category: json['category'] as String? ?? 'Spare Parts',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      registeredBy: json['registeredBy'] as String?,
      registeredByRole: json['registeredByRole'] as String?,
    );
  }

  Supplier copyWith({
    String? id,
    String? name,
    String? address,
    String? factoryAddress,
    String? phone,
    String? fax,
    String? email,
    int? yearEstablished,
    String? natureOfBusiness,
    String? dealerFor,
    String? mdName,
    List<ContactPerson>? contacts,
    String? productRange,
    String? otherFirmAssessment,
    String? qcSystem,
    int? manpowerQualified,
    int? manpowerSkilled,
    int? manpowerUnskilled,
    String? machinery,
    String? annualTurnover,
    String? gstNo,
    String? bankers,
    String? majorCustomers,
    String? evaluationMethod,
    String? purchaseMethod,
    bool? recommended,
    String? preparedBy,
    String? approvedBy,
    String? dateOfInclusion,
    String? status,
    String? category,
    DateTime? createdAt,
    String? registeredBy,
    String? registeredByRole,
  }) {
    return Supplier(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      factoryAddress: factoryAddress ?? this.factoryAddress,
      phone: phone ?? this.phone,
      fax: fax ?? this.fax,
      email: email ?? this.email,
      yearEstablished: yearEstablished ?? this.yearEstablished,
      natureOfBusiness: natureOfBusiness ?? this.natureOfBusiness,
      dealerFor: dealerFor ?? this.dealerFor,
      mdName: mdName ?? this.mdName,
      contacts: contacts ?? this.contacts,
      productRange: productRange ?? this.productRange,
      otherFirmAssessment: otherFirmAssessment ?? this.otherFirmAssessment,
      qcSystem: qcSystem ?? this.qcSystem,
      manpowerQualified: manpowerQualified ?? this.manpowerQualified,
      manpowerSkilled: manpowerSkilled ?? this.manpowerSkilled,
      manpowerUnskilled: manpowerUnskilled ?? this.manpowerUnskilled,
      machinery: machinery ?? this.machinery,
      annualTurnover: annualTurnover ?? this.annualTurnover,
      gstNo: gstNo ?? this.gstNo,
      bankers: bankers ?? this.bankers,
      majorCustomers: majorCustomers ?? this.majorCustomers,
      evaluationMethod: evaluationMethod ?? this.evaluationMethod,
      purchaseMethod: purchaseMethod ?? this.purchaseMethod,
      recommended: recommended ?? this.recommended,
      preparedBy: preparedBy ?? this.preparedBy,
      approvedBy: approvedBy ?? this.approvedBy,
      dateOfInclusion: dateOfInclusion ?? this.dateOfInclusion,
      status: status ?? this.status,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      registeredBy: registeredBy ?? this.registeredBy,
      registeredByRole: registeredByRole ?? this.registeredByRole,
    );
  }
}
