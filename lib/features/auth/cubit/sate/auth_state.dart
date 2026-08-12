abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final String roleId;
  final String roleName;
  final String customerId;
  AuthSuccess(this.roleId,this.roleName,this.customerId);
}

class AuthFailure extends AuthState {
  final String message;
  AuthFailure(this.message);
}
