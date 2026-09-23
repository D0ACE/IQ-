import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iq_plus/core/email_services/email_service.dart';
import 'package:iq_plus/features/admin/customers/cubit/customer_list_state.dart';
import 'package:iq_plus/features/auth/model/customer_model.dart';
import 'package:iq_plus/features/auth/model/user_model.dart';
import 'package:iq_plus/features/auth/repository/auth_repository.dart';

class CustomerListCubit extends Cubit<CustomerListState> {
  final AuthRepository repo;

  CustomerListCubit(this.repo) : super(CustomerListInitial());

  // 🔄 Memory for refreshing the correct list
  Future<void> Function()? _lastFetchAction;

  void safeEmit(CustomerListState state) {
    if (!isClosed) {
      emit(state);
    }
  }

  Future<void> fetchCustomers() async {
    _lastFetchAction = () => fetchCustomers();
    safeEmit(CustomerListLoading());
    try {
      final customers = await repo.getAllCustomers();
      safeEmit(CustomerListLoaded(customers));
    } catch (e) {
      safeEmit(CustomerListError(e.toString()));
    }
  }

  Future<void> fetchAssignCustomers(String consultantId) async {
    _lastFetchAction = () => fetchAssignCustomers(consultantId);
    safeEmit(CustomerListLoading());
    try {
      final customers = await repo.getFetchAssignCustomers(consultantId);
      safeEmit(CustomerListLoaded(customers));
    } catch (e) {
      safeEmit(CustomerListError(e.toString()));
    }
  }

  Future<void> fetchApprovedCustomers(String? consultantId) async {
    _lastFetchAction = () => fetchApprovedCustomers(consultantId);
    safeEmit(CustomerListLoading());
    try {
      if ((consultantId ?? '').isNotEmpty) {
        final customers = await repo.getFetchConsultantCustomers(consultantId!);
        safeEmit(CustomerListLoaded(customers));
      } else {
        final customers = await repo.getFetchAllApprovedCustomers();
        safeEmit(CustomerListLoaded(customers));
      }
    } catch (e) {
      safeEmit(CustomerListError(e.toString()));
    }
  }

  /// 🔄 Utility to refresh based on last action
  Future<void> refresh() async {
    if (_lastFetchAction != null) {
      await _lastFetchAction!();
    } else {
      await fetchCustomers();
    }
  }

  Future<void> approveCustomer({
    required String customerId,
    required String companyName,
    required String customerEmail,
    required String consultantId,
  }) async {
    try {
      safeEmit(CustomerListLoading());
      await repo.approveCustomer(
        customerId: customerId,
        companyName: companyName,
        customerEmail: customerEmail,
        consultantId: consultantId,
      );
      safeEmit(CustomerListOperationSuccess("Customer approved successfully"));
      await refresh();
    } catch (e) {
      safeEmit(CustomerListError(e.toString()));
    }
  }

  Future<void> updateCustomerNextVisitDate({
    required CustomerModel customer,
    required UserModel? consultant,
    required String nextVisitDate,
  }) async {
    try {
      safeEmit(CustomerListLoading());
      await repo.updateCustomerNextVisitDate(
        customerId: customer.customerId,
        nextVisitDate: nextVisitDate,
      );
      safeEmit(CustomerListOperationSuccess("Visit date updated successfully"));
      await refresh();
      await BrevoEmailService.sendNextVisitDateAssignedMail(
        customer: customer,
        consultant: consultant,
        nextVisitDate: nextVisitDate,
      );
    } catch (e) {
      safeEmit(CustomerListError("Failed to update visit date: ${e.toString()}"));
    }
  }

  /// ➕ CREATE CUSTOMER
  Future<void> createCustomer(CustomerModel customer) async {
    try {
      safeEmit(CustomerListLoading());
      await repo.createCustomer(customer);

      // 📧 If direct approval is active, send credentials email
      if (customer.isProfileApproved) {
        await BrevoEmailService.sendCustomerApprovedMail(
          companyName: customer.companyName,
          email: customer.email,
          password: customer.password,
        );
      }

      safeEmit(CustomerListOperationSuccess("Customer created successfully"));
      await refresh();
    } catch (e) {
      safeEmit(CustomerListError(e.toString()));
    }
  }

  /// 🔁 UPDATE CUSTOMER
  Future<void> updateCustomer(CustomerModel customer) async {
    try {
      safeEmit(CustomerListLoading());
      await repo.updateCustomer(customer);
      safeEmit(CustomerListOperationSuccess("Customer updated successfully"));
      await refresh();
    } catch (e) {
      safeEmit(CustomerListError(e.toString()));
    }
  }

  /// ❌ DELETE CUSTOMER
  Future<void> deleteCustomer(String customerId) async {
    try {
      safeEmit(CustomerListLoading());
      await repo.deleteCustomer(customerId);
      safeEmit(CustomerListOperationSuccess("Customer deleted successfully"));
      await refresh();
    } catch (e) {
      safeEmit(CustomerListError(e.toString()));
    }
  }
}
