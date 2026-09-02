import 'package:equatable/equatable.dart';
import '../models/periodic_compliance_model.dart';

abstract class PeriodicComplianceState extends Equatable {
  const PeriodicComplianceState();

  @override
  List<Object?> get props => [];
}

class PeriodicComplianceInitial extends PeriodicComplianceState {}

class PeriodicComplianceLoading extends PeriodicComplianceState {}

class PeriodicComplianceLoaded extends PeriodicComplianceState {
  final List<PeriodicComplianceTask> tasks;

  const PeriodicComplianceLoaded(this.tasks);

  @override
  List<Object?> get props => [tasks];
}

class PeriodicComplianceError extends PeriodicComplianceState {
  final String message;

  const PeriodicComplianceError(this.message);

  @override
  List<Object?> get props => [message];
}

class PeriodicComplianceActionSuccess extends PeriodicComplianceState {
  final String message;

  const PeriodicComplianceActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}
