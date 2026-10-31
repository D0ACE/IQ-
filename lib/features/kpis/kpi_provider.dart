import 'dart:async';
import 'package:flutter/material.dart';
import 'package:iq_plus/di/service_locator.dart';
import 'package:iq_plus/features/kpis/models/kpi_model.dart';
import 'package:iq_plus/features/kpis/repository/kpi_repository.dart';

class KpiProvider extends ChangeNotifier {
  final KpiRepository _repository = getIt<KpiRepository>();
  StreamSubscription? _subscription;

  List<KpiTask> _taskList = [];
  List<KpiTask> get taskList => _taskList;

  void listenToTasks({
    String? customerId,
    String? createdBy,
    bool isConsultant = false,
  }) {
    _subscription?.cancel();
    _subscription = _repository.getTasksStream(
      customerId: customerId,
      createdBy: createdBy,
      isConsultant: isConsultant,
    ).listen((tasks) {
      _taskList = tasks;
      notifyListeners();
    });
  }

  int get openCount => _taskList.where((t) => t.effectiveStatus == 'open').length;
  int get pendingCount => openCount;
  int get inProgressCount => _taskList.where((t) {
        final s = t.effectiveStatus;
        return s == 'in_progress' || s == 'in progress';
      }).length;
  int get completedCount => _taskList.where((t) => t.effectiveStatus == 'completed').length;
  int get nonCompliantCount => _taskList.where((t) => t.effectiveStatus == 'non_compliant').length;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
