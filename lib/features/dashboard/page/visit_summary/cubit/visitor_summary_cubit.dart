import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:iq_plus/core/email_services/email_service.dart';
import 'package:iq_plus/features/auth/model/customer_model.dart';
import 'package:iq_plus/features/auth/model/user_model.dart';
import 'package:iq_plus/features/dashboard/page/visit_summary/cubit/visitor_summary_state.dart';
import 'package:iq_plus/features/dashboard/page/visit_summary/repository/visitor_summary_repository.dart';
import 'package:iq_plus/features/users/models/employe_user.dart';

class VisitorSummaryCubit extends Cubit<VisitorSummaryState> {
  final VisitorSummaryRepository repository;

  VisitorSummaryCubit(this.repository) : super(VisitorSummaryInitial());

  Future<void> loadVisitorSummaries() async {
    emit(VisitorSummaryLoading());
    try {
      final list = await repository.fetchVisitorSummaries();
      emit(VisitorSummaryLoaded(list));
    } catch (e) {
      emit(VisitorSummaryError(e.toString()));
    }
  }

  Future<void> loadVisitorSummariesForCustomer() async {
    emit(VisitorSummaryLoading());
    try {
      final list = await repository.fetchVisitorSummariesForCustomer();
      emit(VisitorSummaryLoaded(list));
    } catch (e) {
      emit(VisitorSummaryError(e.toString()));
    }
  }


  /// 🔹 CREATE
  Future<void> createVisitorSummary({
    required Map<String, dynamic> payload,
    required CustomerModel? selectedCustomer,
    required UserModel? consultantUserModel,
  }) async {
    try {
      emit(VisitorSummaryLoading());

      final data = _normalizePayload(payload);

      await repository.createVisitorSummary(data);
      //if ((selectedCustomer?.email ?? '').isNotEmpty) {
        BrevoEmailService.sendVisitorSummaryMailFromPayload(
          toEmail: selectedCustomer?.email ?? '',
          toName: selectedCustomer?.companyName ?? '',
          payload: payload,
          selectedCustomer:selectedCustomer ,
          consultantUserModel:consultantUserModel ,
        );
      //}
    //  if ((consultantUserModel?.email ?? '').isNotEmpty) {
        BrevoEmailService.sendVisitorSummaryMailFromPayload(
          toEmail: consultantUserModel?.email ?? '',
          toName: consultantUserModel?.userName ?? '',
          payload: payload,
          selectedCustomer:selectedCustomer ,
          consultantUserModel:consultantUserModel ,
        );
      //}
      List<EmployeeUserModel> adminUsers = await repository.fetchAdminUsers();
      for (var admin in adminUsers) {
      //  if ((admin.email ?? '').isNotEmpty) {
          BrevoEmailService.sendVisitorSummaryMailFromPayload(
            toEmail: admin.email ?? '',
            toName: admin.userName ?? '',
            payload: payload,
            selectedCustomer:selectedCustomer ,
            consultantUserModel:consultantUserModel ,
          );
        //}
      }
      emit(VisitorSummarySuccess('Visitor summary saved'));
      loadVisitorSummaries();
    } catch (e) {
      emit(VisitorSummaryError(e.toString()));
    }
  }

  /// 🔹 UPDATE (for edit flow later)
  Future<void> updateVisitorSummary({
    required String docId,
    required Map<String, dynamic> payload,
    required CustomerModel? selectedCustomer,
    required UserModel? consultantUserModel,
  }) async {
    try {
      emit(VisitorSummaryLoading());

      final data = _normalizePayload(payload);

      await repository.updateVisitorSummary(docId: docId, data: data);


      //if ((selectedCustomer?.email ?? '').isNotEmpty) {
      BrevoEmailService.sendVisitorSummaryMailFromPayload(
        toEmail: selectedCustomer?.email ?? '',
        toName: selectedCustomer?.companyName ?? '',
        payload: payload,
        selectedCustomer:selectedCustomer ,
        consultantUserModel:consultantUserModel ,
        isUpdateVisitorSummary: true,
      );
      //}
      //  if ((consultantUserModel?.email ?? '').isNotEmpty) {
      BrevoEmailService.sendVisitorSummaryMailFromPayload(
        toEmail: consultantUserModel?.email ?? '',
        toName: consultantUserModel?.userName ?? '',
        payload: payload,
        selectedCustomer:selectedCustomer ,
        consultantUserModel:consultantUserModel ,
        isUpdateVisitorSummary: true,
      );
      //}
      List<EmployeeUserModel> adminUsers = await repository.fetchAdminUsers();
      for (var admin in adminUsers) {
        //  if ((admin.email ?? '').isNotEmpty) {
        BrevoEmailService.sendVisitorSummaryMailFromPayload(
          toEmail: admin.email ?? '',
          toName: admin.userName ?? '',
          payload: payload,
          selectedCustomer:selectedCustomer ,
          consultantUserModel:consultantUserModel ,
          isUpdateVisitorSummary: true,
        );
        //}
      }
      emit(VisitorSummarySuccess('Visitor summary updated'));
      loadVisitorSummaries();
    } catch (e) {
      emit(VisitorSummaryError(e.toString()));
    }
  }

  /// ✅ DELETE
  Future<void> deleteVisitorSummary(String id) async {
    emit(VisitorSummaryLoading());
    try {
      await repository.deleteVisitorSummary(id);
      loadVisitorSummaries();
    } catch (e) {
      emit(VisitorSummaryError(e.toString()));
    }
  }

  /// 🔹 Convert dates to Firestore Timestamp
  Map<String, dynamic> _normalizePayload(Map<String, dynamic> raw) {
    return {
      ...raw,
      'visitDate': _toTimestamp(raw['visitDate']),
      'signOff': {
        ...raw['signOff'],
        'signDate': _toTimestamp(raw['signOff']?['signDate']),
      },
      'capas': (raw['capas'] as List).map((c) {
        return {...c, 'date': _toTimestamp(c['date'])};
      }).toList(),
    };
  }

  Timestamp? _toTimestamp(dynamic value) {
    if (value == null || value.toString().isEmpty) return null;
    try {
      // Parse "10 Jan 2026" format
      final date = DateFormat('dd MMM yyyy').parse(value.toString());
      return Timestamp.fromDate(date);
    } catch (e) {
      // fallback to ISO parse
      try {
        return Timestamp.fromDate(DateTime.parse(value.toString()));
      } catch (_) {
        return null;
      }
    }
  }
}
