import 'package:iq_plus/features/auth/model/customer_model.dart';

abstract class CustomerState {}

class CustomerInitial extends CustomerState {}

class CustomerLoading extends CustomerState {}

class CustomerSuccess extends CustomerState {}

class CustomerApproved extends CustomerState {}

class CustomerError extends CustomerState {
  final String message;
  CustomerError(this.message);
}

class CustomerListLoaded extends CustomerState {
  final List<CustomerModel> customers;
  CustomerListLoaded(this.customers);
}
