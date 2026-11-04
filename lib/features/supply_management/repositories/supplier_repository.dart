import '../models/supplier.dart';

abstract class SupplierRepository {
  Future<List<Supplier>> getAllSuppliers();
  Future<Supplier?> getSupplierById(String id);
  Future<void> addSupplier(Supplier supplier);
  Future<void> updateSupplier(Supplier supplier);
  Future<void> deleteSupplier(String id);
  Future<String> getNextSupplierId();
}
