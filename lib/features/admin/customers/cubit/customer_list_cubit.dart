import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iq_plus/features/admin/customers/cubit/customer_list_state.dart';
import 'package:iq_plus/features/auth/repository/auth_repository.dart';

class CustomerListCubit extends Cubit<CustomerListState> {
  final AuthRepository repo;

  CustomerListCubit(this.repo) : super(CustomerListInitial());

  Future<void> fetchCustomers() async {
    emit(CustomerListLoading());
    try {
      final customers = await repo.getAllCustomers();
      print(customers.toString());
      emit(CustomerListLoaded(customers));
    } catch (e) {
      emit(CustomerListError(e.toString()));
    }
  }

  Future<void> fetchApprovedCustomers() async {
    emit(CustomerListLoading());
    try {
      final customers = await repo.getFetchAllApprovedCustomers();
      print(customers.toString());
      emit(CustomerListLoaded(customers));
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
}
