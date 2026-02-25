import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iq_plus/core/email_services/email_service.dart';
import 'package:iq_plus/features/admin/customers/cubit/customer_list_state.dart';
import 'package:iq_plus/features/auth/model/customer_model.dart';
import 'package:iq_plus/features/auth/model/user_model.dart';
import 'package:iq_plus/features/auth/repository/auth_repository.dart';

class CustomerListCubit extends Cubit<CustomerListState> {
  final AuthRepository repo;

  CustomerListCubit(this.repo) : super(CustomerListInitial());

  Future<void> fetchCustomers() async {
    emit(CustomerListLoading());
    try {
      final customers = await repo.getAllCustomers();
      
      emit(CustomerListLoaded(customers));
    } catch (e) {
      emit(CustomerListError(e.toString()));
    }
  }

  Future<void> fetchAssignCustomers(String consultantId) async {
    emit(CustomerListLoading());
    try {
      final customers = await repo.getFetchAssignCustomers(consultantId);
      
      emit(CustomerListLoaded(customers));
    } catch (e) {
      emit(CustomerListError(e.toString()));
    }
  }

  Future<void> fetchApprovedCustomers(String? consultantId) async {
    emit(CustomerListLoading());
    try {
      if((consultantId??'').isNotEmpty){
        final customers = await repo.getFetchConsultantCustomers(consultantId);
        
        emit(CustomerListLoaded(customers));
      }else{
        final customers = await repo.getFetchAllApprovedCustomers();
        
        emit(CustomerListLoaded(customers));
      }
    } catch (e) {
      emit(CustomerListError(e.toString()));
    }
  }

  Future<void> approveCustomer({required String customerId,required String companyName,required String customerEmail,required String consultantId,}) async {
    await repo.approveCustomer(customerId: customerId,
        companyName: companyName,
        customerEmail:customerEmail,
        consultantId: consultantId);
    fetchCustomers();
  }

  Future<void> updateCustomerNextVisitDate({
    required CustomerModel customer,
    required UserModel? consultant,
    required String nextVisitDate,
  }) async {
    try {
      emit(CustomerListLoading());

      await repo.updateCustomerNextVisitDate(
        customerId: customer.customerId,
        nextVisitDate: nextVisitDate,
      );
      fetchAssignCustomers(consultant?.userId??"");
      await BrevoEmailService.sendNextVisitDateAssignedMail(
        customer: customer,
        consultant: consultant,
        nextVisitDate: nextVisitDate,
      );
    } catch (e) {
      emit(CustomerListError("Failed to update password"));
    }
  }
}
