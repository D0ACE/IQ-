abstract class SuperAdminState {}

class SuperAdminInitial extends SuperAdminState {}

class SuperAdminLoading extends SuperAdminState {}

class SuperAdminLoaded extends SuperAdminState {}

class SuperAdminError extends SuperAdminState {
  final String message;
  SuperAdminError(this.message);
}
