import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/kpi_repository.dart';
import '../models/kpi_model.dart';
import 'kpi_state.dart';

class KpiCubit extends Cubit<KpiState> {
  final KpiRepository _repository;
  StreamSubscription? _subscription;

  KpiCubit(this._repository) : super(KpiInitial());

  void safeEmit(KpiState state) {
    if (!isClosed) {
      emit(state);
    }
  }

  void loadTasks({
    String? customerId,
    String? createdBy,
    bool isConsultant = false,
  }) {
    safeEmit(KpiLoading());
    _subscription?.cancel();
    _subscription = _repository.getTasksStream(
      customerId: customerId,
      createdBy: createdBy,
      isConsultant: isConsultant,
    ).listen(
      (tasks) {
        safeEmit(KpiLoaded(tasks));
      },
      onError: (error) {
        safeEmit(KpiError(error.toString()));
      },
    );
  }

  Future<void> addTask(KpiTask task) async {
    try {
      await _repository.createTask(task);
      safeEmit(const KpiActionSuccess("KPI's task created successfully"));
    } catch (e) {
      safeEmit(KpiError(e.toString()));
    }
  }

  Future<void> updateTask(KpiTask task) async {
    try {
      await _repository.updateTask(task);
      safeEmit(const KpiActionSuccess("KPI's task updated successfully"));
    } catch (e) {
      safeEmit(KpiError(e.toString()));
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await _repository.deleteTask(taskId);
      safeEmit(const KpiActionSuccess("KPI's task deleted successfully"));
    } catch (e) {
      safeEmit(KpiError(e.toString()));
    }
  }

  Future<void> saveProgress(
    String taskId, {
    required String evidenceUrl,
    required String evidenceFileName,
    String comment = '',
    String achieved = '',
    String achievedType = '',
  }) async {
    try {
      final bool isNonCompliant = await _repository.saveTaskProgress(
        taskId,
        evidenceUrl: evidenceUrl,
        evidenceFileName: evidenceFileName,
        comment: comment,
        achieved: achieved,
        achievedType: achievedType,
      );
      if (isNonCompliant) {
        safeEmit(const KpiActionSuccess('Progress saved successfully.'));
      } else {
        safeEmit(const KpiActionSuccess('Progress saved. Task status updated to In Progress.'));
      }
    } catch (e) {
      safeEmit(KpiError(e.toString()));
    }
  }

  Future<void> markAsCompleted(
    String taskId, {
    String evidenceUrl = '',
    String evidenceFileName = '',
    String comment = '',
    String achieved = '',
    String achievedType = '',
  }) async {
    try {
      await _repository.completeTask(
        taskId,
        evidenceUrl: evidenceUrl,
        evidenceFileName: evidenceFileName,
        comment: comment,
        achieved: achieved,
        achievedType: achievedType,
      );
      safeEmit(const KpiActionSuccess("KPI's task completed successfully"));
    } catch (e) {
      safeEmit(KpiError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
