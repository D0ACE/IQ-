import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/periodic_compliance_repository.dart';
import '../models/periodic_compliance_model.dart';
import 'periodic_compliance_state.dart';

class PeriodicComplianceCubit extends Cubit<PeriodicComplianceState> {
  final PeriodicComplianceRepository _repository;
  StreamSubscription? _subscription;

  PeriodicComplianceCubit(this._repository) : super(PeriodicComplianceInitial());

  void safeEmit(PeriodicComplianceState state) {
    if (!isClosed) {
      emit(state);
    }
  }

  void loadTasks({
    String? customerId,
    String? createdBy,
    bool isConsultant = false,
  }) {
    safeEmit(PeriodicComplianceLoading());
    _subscription?.cancel();
    _subscription = _repository.getTasksStream(
      customerId: customerId,
      createdBy: createdBy,
      isConsultant: isConsultant,
    ).listen(
      (tasks) {
        safeEmit(PeriodicComplianceLoaded(tasks));
      },
      onError: (error) {
        safeEmit(PeriodicComplianceError(error.toString()));
      },
    );
  }

  Future<void> addTask(PeriodicComplianceTask task) async {
    try {
      await _repository.createTask(task);
      safeEmit(const PeriodicComplianceActionSuccess('Task created successfully'));
    } catch (e) {
      safeEmit(PeriodicComplianceError(e.toString()));
    }
  }

  Future<void> updateTask(PeriodicComplianceTask task) async {
    try {
      await _repository.updateTask(task);
      safeEmit(const PeriodicComplianceActionSuccess('Task updated successfully'));
    } catch (e) {
      safeEmit(PeriodicComplianceError(e.toString()));
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await _repository.deleteTask(taskId);
      safeEmit(const PeriodicComplianceActionSuccess('Task deleted successfully'));
    } catch (e) {
      safeEmit(PeriodicComplianceError(e.toString()));
    }
  }

  Future<void> markAsCompleted(String taskId) async {
    try {
      await _repository.completeTask(taskId);
      safeEmit(const PeriodicComplianceActionSuccess('Task completed successfully'));
    } catch (e) {
      safeEmit(PeriodicComplianceError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
