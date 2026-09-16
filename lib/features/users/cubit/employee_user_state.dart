import 'package:iq_plus/features/auth/model/role_model.dart';

abstract class UserState {}

class UserInitial extends UserState {}

class UserLoading extends UserState {}

class UserLoaded extends UserState {
  final List<dynamic> users;
  UserLoaded(this.users);
}

class UserRolesLoading extends UserState {}

class UserRolesLoaded extends UserState {
  final List<RoleModel> roles;
  UserRolesLoaded(this.roles);
}

class UserSuccess extends UserState {
  final String message;
  UserSuccess(this.message);
}


class UserError extends UserState {
  final String message;
  UserError(this.message);
}
