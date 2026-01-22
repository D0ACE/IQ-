part of 'admin_cubit.dart';

abstract class AdminState extends Equatable {
  const AdminState();

  @override
  List<Object?> get props => [];
}

class AdminInitial extends AdminState {}

class AdminLoading extends AdminState {}

/// ✅ Used ONLY in AdminListPage
class AdminListLoaded extends AdminState {
  final List<AdminModel> admins;

  const AdminListLoaded(this.admins);

  @override
  List<Object?> get props => [admins];
}

/// ✅ Used ONLY in AdminDetailPage
class AdminDetailLoaded extends AdminState {
  final AdminModel admin;

  const AdminDetailLoaded(this.admin);

  @override
  List<Object?> get props => [admin];
}

class AdminError extends AdminState {
  final String message;

  const AdminError(this.message);

  @override
  List<Object?> get props => [message];
}
