import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/consultant_model.dart';
import 'consultant_state.dart';


class ConsultantCubit extends Cubit<ConsultantState> {
  ConsultantCubit() : super(ConsultantInitial());

  Future<void> fetchConsultants() async {
    try {
      emit(ConsultantLoading());

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('roleId', isEqualTo: '2') // consultant role
          .where('activeUser', isEqualTo: true)
          .get();

      List<ConsultantModel> consultantsList = snapshot.docs
          .map(
            (doc) => ConsultantModel.fromFirestore(
              doc.id,
              doc.data(),
            ),
          )
          .toList();

      emit(ConsultantLoaded(consultantsList));
    } catch (e) {
      emit(ConsultantError(e.toString()));
    }
  }
}
