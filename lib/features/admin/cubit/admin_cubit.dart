import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:iq_plus/features/admin/model/admin_model.dart';
import 'package:iq_plus/features/admin/repository/admin_repository.dart';

part 'admin_state.dart';

class AdminCubit extends Cubit<AdminState> {
  final AdminRepository repository;

  AdminCubit(this.repository) : super(AdminInitial());

  /// 🔹 Fetch ALL admins (ONLY for AdminListPage)
  Future<void> fetchAllAdmins() async {
    try {
      emit(AdminLoading());

      final admins = await repository.getAllAdmins();

      emit(AdminListLoaded(admins));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  /// 🔹 Fetch SINGLE admin (ONLY for AdminDetailPage)
  Future<void> fetchAdminById(String adminId) async {
    emit(AdminLoading());

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(adminId)
          .get();

      if (!doc.exists) {
        emit(AdminError('Admin not found'));
        return;
      }

      final admin = AdminModel.fromJson(doc.data()!);
      emit(AdminDetailLoaded(admin));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }
}
