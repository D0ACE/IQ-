import 'package:equatable/equatable.dart';
import '../models/kpi_model.dart';

abstract class KpiState extends Equatable {
  const KpiState();

  @override
  List<Object?> get props => [];
}

class KpiInitial extends KpiState {}

class KpiLoading extends KpiState {}

class KpiLoaded extends KpiState {
  final List<KpiTask> tasks;

  const KpiLoaded(this.tasks);

  @override
  List<Object?> get props => [tasks];
}

class KpiError extends KpiState {
  final String message;

  const KpiError(this.message);

  @override
  List<Object?> get props => [message];
}

class KpiActionSuccess extends KpiState {
  final String message;

  const KpiActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}
