import 'package:flutter_bloc/flutter_bloc.dart';
import 'superadmin_state.dart';

class SuperAdminCubit extends Cubit<SuperAdminState> {
  SuperAdminCubit() : super(SuperAdminInitial());

  void loadDashboard() {
    emit(SuperAdminLoading());
    emit(SuperAdminLoaded());
  }
}
