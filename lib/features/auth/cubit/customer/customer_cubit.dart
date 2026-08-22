import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iq_plus/features/auth/cubit/customer/state/customer_state.dart';
import 'package:iq_plus/features/auth/model/customer_model.dart';
import 'package:iq_plus/features/auth/repository/auth_repository.dart';
import 'package:iq_plus/core/email_services/email_service.dart';

class CustomerCubit extends Cubit<CustomerState> {
  final AuthRepository repo;

  CustomerCubit(this.repo) : super(CustomerInitial());

  /// ✅ CREATE CUSTOMER (Signup)
  Future<void> createCustomer(CustomerModel data) async {
    emit(CustomerLoading());

    try {
      final doc = FirebaseFirestore.instance.collection('customers').doc();

      await doc.set(
        data.copyWith(
          customerId: doc.id, // ✅ IMPORTANT
          isProfileApproved: false, // ensure new users are pending approval
        ).toJson(),
      );

      // 📧 Send email notification to customer
      await BrevoEmailService.sendCustomerCreatedMail(
        companyName: data.companyName,
        email: data.email,
      );

      emit(CustomerSuccess());
    } catch (e) {
      emit(CustomerError(e.toString()));
    }
  }

  /// ✅ ADMIN APPROVE CUSTOMER
  Future<void> approveCustomer(String customerId) async {
    emit(CustomerLoading());

    try {
      await FirebaseFirestore.instance
          .collection('customers')
          .doc(customerId)
          .update({'isProfileApproved': true});

      await fetchPendingCustomers(); // ✅ refresh pending list after approval
    } catch (e) {
      emit(CustomerError(e.toString()));
    }
  }

  /// ✅ FETCH PENDING ONBOARDING REQUESTS (ADMIN)
  Future<void> fetchPendingCustomers() async {
    emit(CustomerLoading());

    try {
      final snap = await FirebaseFirestore.instance
          .collection('customers')
          .where('isProfileApproved', isEqualTo: false)
          .get();

      final customers = snap.docs
          .map(
            (doc) => CustomerModel.fromJson(
              doc.data(),
              customerId: doc.id,
            ),
          )
          .toList();

      emit(CustomerListLoaded(customers));
    } catch (e) {
      emit(CustomerError(e.toString()));
    }
  }
}
