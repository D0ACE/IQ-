import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:iq_plus/common/routes/go_route.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/common/utility/utility.dart';
import 'package:iq_plus/core/local_storage/hive_service.dart';
import 'package:iq_plus/di/service_locator.dart';
import 'package:iq_plus/features/periodic_compliance/cubit/periodic_compliance_cubit.dart';
import 'package:iq_plus/features/periodic_compliance/cubit/periodic_compliance_state.dart';
import 'package:iq_plus/features/periodic_compliance/models/periodic_compliance_model.dart';

class PeriodicComplianceListPage extends StatelessWidget {
  const PeriodicComplianceListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final hiveService = getIt<HiveService>();
    final user = hiveService.getUser();
    final customer = hiveService.getCustomer();

    final bool isCustomer = customer != null;
    final bool isConsultant = Utility.isConsultant(user?.roleId);

    final String? customerIdFilter = isCustomer ? customer.customerId : null;
    final String? createdByFilter = isConsultant ? user?.userId : null;

    return BlocProvider(
      create: (_) => getIt<PeriodicComplianceCubit>()..loadTasks(
        customerId: customerIdFilter,
        createdBy: createdByFilter,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: AppColors.titleText,
          title: const Text(
            'Periodic Compliance Tasks',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -0.5),
          ),
        ),
        floatingActionButton: !isCustomer
            ? FloatingActionButton.extended(
                onPressed: () => context.push(AppRoutes.periodicComplianceForm),
                backgroundColor: AppColors.primary,
                icon: const Icon(Icons.add_task_rounded, color: Colors.white),
                label: const Text("New Task", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              )
            : null,
        body: BlocListener<PeriodicComplianceCubit, PeriodicComplianceState>(
          listener: (context, state) {
            if (state is PeriodicComplianceActionSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
          child: BlocBuilder<PeriodicComplianceCubit, PeriodicComplianceState>(
            buildWhen: (previous, current) => current is! PeriodicComplianceActionSuccess,
            builder: (context, state) {
              if (state is PeriodicComplianceLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is PeriodicComplianceLoaded) {
                final tasks = state.tasks;
                if (tasks.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    return _TaskCard(
                      task: tasks[index],
                      isCustomer: isCustomer,
                    );
                  },
                );
              }

              if (state is PeriodicComplianceError) {
                return Center(child: Text('Error: ${state.message}'));
              }

              return const SizedBox();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_turned_in_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "No compliance tasks found",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final PeriodicComplianceTask task;
  final bool isCustomer;

  const _TaskCard({required this.task, required this.isCustomer});

  @override
  Widget build(BuildContext context) {
    final bool isPending = task.status == 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => context.push(AppRoutes.periodicComplianceDetails, extra: task),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (isPending ? Colors.orange : Colors.green).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      task.status.toUpperCase(),
                      style: TextStyle(
                        color: isPending ? Colors.orange : Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  if (!isCustomer)
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_note_rounded, color: Colors.blue),
                          onPressed: () => context.push(AppRoutes.periodicComplianceForm, extra: task),
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(8),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                          onPressed: () => _showDeleteConfirm(context),
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(8),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                task.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.titleText,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                task.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade600, height: 1.5),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.business_rounded, size: 16, color: Colors.grey.shade400),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      task.assignedCustomerName,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                    ),
                  ),
                  Icon(Icons.calendar_today_rounded, size: 16, color: Colors.grey.shade400),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('dd MMM yyyy').format(task.dueDate),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: isPending && task.dueDate.isBefore(DateTime.now()) ? Colors.red : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              if (!isCustomer && isPending) ...[
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () => context.read<PeriodicComplianceCubit>().markAsCompleted(task.id),
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text(
                      "COMPLETE TASK",
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Task"),
        content: const Text("Are you sure you want to delete this compliance task?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              context.read<PeriodicComplianceCubit>().deleteTask(task.id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
