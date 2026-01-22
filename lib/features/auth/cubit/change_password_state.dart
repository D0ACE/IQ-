abstract class CustomerPasswordState {}

class CustomerPasswordInitial extends CustomerPasswordState {}

class CustomerPasswordLoading extends CustomerPasswordState {}

class CustomerPasswordSuccess extends CustomerPasswordState {}

class CustomerPasswordError extends CustomerPasswordState {
  final String message;
  CustomerPasswordError(this.message);
}
