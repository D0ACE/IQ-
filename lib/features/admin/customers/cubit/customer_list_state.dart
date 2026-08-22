import 'package:iq_plus/features/auth/model/customer_model.dart';

abstract class CustomerListState {}

class CustomerListInitial extends CustomerListState {}

class CustomerListLoading extends CustomerListState {}

class CustomerListLoaded extends CustomerListState {
  final List<CustomerModel> customers;
  CustomerListLoaded(this.customers);
}

class CustomerListOperationSuccess extends CustomerListState {
  final String message;
  CustomerListOperationSuccess(this.message);
}

class CustomerListError extends CustomerListState {
  final String message;
  CustomerListError(this.message);
}
