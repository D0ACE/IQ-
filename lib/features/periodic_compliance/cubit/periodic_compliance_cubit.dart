import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/periodic_compliance_repository.dart';
import '../models/periodic_compliance_model.dart';
import 'periodic_compliance_state.dart';

class PeriodicComplianceCubit extends Cubit<PeriodicComplianceState> {
  final PeriodicComplianceRepository _repository;
  StreamSubscription? _subscription;

  PeriodicComplianceCubit(this._repository) : super(PeriodicComplianceInitial());

  void loadTasks({String? customerId, String? createdBy}) {
    emit(PeriodicComplianceLoading());
    _subscription?.cancel();
    _subscription = _repository.getTasksStream(customerId: customerId, createdBy: createdBy).listen(
      (tasks) {
        emit(PeriodicComplianceLoaded(tasks));
      },
      onError: (error) {
        emit(PeriodicComplianceError(error.toString()));
      },
    );
  }

  Future<void> addTask(PeriodicComplianceTask task) async {
    try {
      await _repository.createTask(task);
      emit(const PeriodicComplianceActionSuccess('Task created successfully'));
    } catch (e) {
      emit(PeriodicComplianceError(e.toString()));
    }
  }

  Future<void> updateTask(PeriodicComplianceTask task) async {
    try {
      await _repository.updateTask(task);
      emit(const PeriodicComplianceActionSuccess('Task updated successfully'));
    } catch (e) {
      emit(PeriodicComplianceError(e.toString()));
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await _repository.deleteTask(taskId);
      emit(const PeriodicComplianceActionSuccess('Task deleted successfully'));
    } catch (e) {
      emit(PeriodicComplianceError(e.toString()));
    }
  }

  Future<void> markAsCompleted(String taskId) async {
    try {
      await _repository.completeTask(taskId);
      emit(const PeriodicComplianceActionSuccess('Task completed successfully'));
    } catch (e) {
      emit(PeriodicComplianceError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
