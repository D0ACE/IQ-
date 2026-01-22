import 'package:equatable/equatable.dart';
import 'package:iq_plus/features/customer_mme/models/mme_model_req.dart';

abstract class CustomerMMEState extends Equatable {
  const CustomerMMEState();

  @override
  List<Object?> get props => [];
}

/// initial
class CustomerMMEInitial extends CustomerMMEState {}

/// loading
class CustomerMMELoading extends CustomerMMEState {}

class CustomerMMESuccess extends CustomerMMEState {}

/// success - list loaded
class CustomerMMELoaded extends CustomerMMEState {
  final List<CustomerMMEModel> list;

  const CustomerMMELoaded(this.list);

  @override
  List<Object?> get props => [list];
}

/// error
class CustomerMMEError extends CustomerMMEState {
  final String message;

  const CustomerMMEError(this.message);

  @override
  List<Object?> get props => [message];
}
