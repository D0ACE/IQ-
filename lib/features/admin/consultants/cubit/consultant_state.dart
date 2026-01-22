import '../model/consultant_model.dart';

abstract class ConsultantState {}

class ConsultantInitial extends ConsultantState {}

class ConsultantLoading extends ConsultantState {}

class ConsultantLoaded extends ConsultantState {
  final List<ConsultantModel> consultants;
  ConsultantLoaded(this.consultants);
}

class ConsultantError extends ConsultantState {
  final String message;
  ConsultantError(this.message);
}
