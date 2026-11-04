import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/supplier.dart';
import '../repositories/supplier_repository.dart';

class SupplierProvider extends ChangeNotifier {
  final SupplierRepository repository;
  final String? registeredBy;
  final String? registeredByRole;

  List<Supplier> _suppliers = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _recentlyAddedId;

  SupplierProvider({
    required this.repository,
    this.registeredBy,
    this.registeredByRole,
  });

  List<Supplier> get suppliers => List.unmodifiable(_suppliers);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get recentlyAddedId => _recentlyAddedId;

  List<Supplier> get approvedSuppliers =>
      _suppliers.where((s) => s.status == 'Approved').toList();

  int get approvedCount => approvedSuppliers.length;
  int get temporaryCount =>
      _suppliers.where((s) => s.status == 'Temporary').length;
  int get notRecommendedCount =>
      _suppliers.where((s) => s.status == 'Not Recommended').length;
  int get nonExistingCount =>
      _suppliers.where((s) => s.status == 'Non-existing').length;
  int get totalCount => _suppliers.length;

  void clearRecentlyAddedHighlight() {
    _recentlyAddedId = null;
    notifyListeners();
  }

  Future<void> loadSuppliers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _suppliers = await repository.getAllSuppliers();
    } catch (e) {
      _errorMessage = 'Failed to load suppliers: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Validates duplicate name or GST registration number
  String? checkForDuplicate({
    required String name,
    required String? gstNo,
    String? currentId,
  }) {
    final cleanName = name.trim().toLowerCase();
    final cleanGst = gstNo?.trim().toUpperCase();

    for (final s in _suppliers) {
      if (currentId != null && s.id == currentId) continue;

      if (s.name.trim().toLowerCase() == cleanName) {
        return 'A supplier with the name "${s.name}" is already registered (ID: ${s.id}).';
      }

      if (cleanGst != null &&
          cleanGst.isNotEmpty &&
          s.gstNo != null &&
          s.gstNo!.trim().toUpperCase() == cleanGst) {
        return 'A supplier with the GSTIN "$cleanGst" is already registered under "${s.name}" (ID: ${s.id}).';
      }
    }
    return null;
  }

  /// Adds a new supplier.
  /// Automatically:
  /// 1. Checks duplicate
  /// 2. Auto-generates next ID (MSP/NN)
  /// 3. Sets Date of Inclusion = today (dd-MM-yyyy)
  /// 4. Sets status to "Pending" until an authorized staff member approves it.
  Future<Supplier> registerSupplier({
    required String category,
    required String name,
    required String address,
    String? factoryAddress,
    required String phone,
    String? fax,
    String? email,
    int? yearEstablished,
    required String natureOfBusiness,
    String? dealerFor,
    String? mdName,
    required List<dynamic> contacts,
    required String productRange,
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
    required String evaluationMethod,
    required String purchaseMethod,
    required bool recommended,
    String? preparedBy,
    String? approvedBy,
    String? registeredBy,
    String? registeredByRole,
  }) async {
    final duplicateErr = checkForDuplicate(name: name, gstNo: gstNo);
    if (duplicateErr != null) {
      throw Exception(duplicateErr);
    }

    final newId = await repository.getNextSupplierId();
    final today = DateFormat('dd-MM-yyyy').format(DateTime.now());
    // Supplier registration is a request. Approval is a separate staff action.
    const status = 'Pending';

    final newSupplier = Supplier(
      id: newId,
      name: name.trim(),
      address: address.trim(),
      factoryAddress: factoryAddress?.trim().isNotEmpty == true
          ? factoryAddress!.trim()
          : null,
      phone: phone.trim(),
      fax: fax?.trim().isNotEmpty == true ? fax!.trim() : null,
      email: email?.trim().isNotEmpty == true ? email!.trim() : null,
      yearEstablished: yearEstablished,
      natureOfBusiness: natureOfBusiness,
      dealerFor: dealerFor?.trim().isNotEmpty == true
          ? dealerFor!.trim()
          : null,
      mdName: mdName?.trim().isNotEmpty == true ? mdName!.trim() : null,
      contacts: List.from(contacts),
      productRange: productRange.trim(),
      otherFirmAssessment: otherFirmAssessment?.trim().isNotEmpty == true
          ? otherFirmAssessment!.trim()
          : null,
      qcSystem: qcSystem?.trim().isNotEmpty == true ? qcSystem!.trim() : null,
      manpowerQualified: manpowerQualified,
      manpowerSkilled: manpowerSkilled,
      manpowerUnskilled: manpowerUnskilled,
      machinery: machinery?.trim().isNotEmpty == true
          ? machinery!.trim()
          : null,
      annualTurnover: annualTurnover?.trim().isNotEmpty == true
          ? annualTurnover!.trim()
          : null,
      gstNo: gstNo?.trim().toUpperCase(),
      bankers: bankers?.trim().isNotEmpty == true ? bankers!.trim() : null,
      majorCustomers: majorCustomers?.trim().isNotEmpty == true
          ? majorCustomers!.trim()
          : null,
      evaluationMethod: evaluationMethod,
      purchaseMethod: purchaseMethod,
      recommended: recommended,
      preparedBy: preparedBy?.trim().isNotEmpty == true
          ? preparedBy!.trim()
          : null,
      approvedBy: approvedBy?.trim().isNotEmpty == true
          ? approvedBy!.trim()
          : null,
      dateOfInclusion: today,
      status: status,
      category: category,
      createdAt: DateTime.now(),
      registeredBy: registeredBy ?? this.registeredBy,
      registeredByRole: registeredByRole ?? this.registeredByRole,
    );

    await repository.addSupplier(newSupplier);
    _suppliers.add(newSupplier);
    _recentlyAddedId = newId;
    notifyListeners();
    return newSupplier;
  }

  Future<void> updateSupplier(Supplier supplier) async {
    final duplicateErr = checkForDuplicate(
      name: supplier.name,
      gstNo: supplier.gstNo,
      currentId: supplier.id,
    );
    if (duplicateErr != null) {
      throw Exception(duplicateErr);
    }

    await repository.updateSupplier(supplier);
    final idx = _suppliers.indexWhere((s) => s.id == supplier.id);
    if (idx != -1) {
      _suppliers[idx] = supplier;
    }
    notifyListeners();
  }

  Future<void> updateStatus(String id, String newStatus) async {
    final idx = _suppliers.indexWhere((s) => s.id == id);
    if (idx != -1) {
      final updated = _suppliers[idx].copyWith(status: newStatus);
      await repository.updateSupplier(updated);
      _suppliers[idx] = updated;
      notifyListeners();
    }
  }

  Future<void> deleteSupplier(String id) async {
    await repository.deleteSupplier(id);
    _suppliers.removeWhere((s) => s.id == id);
    notifyListeners();
  }
}
