import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:iq_plus/common/routes/go_route.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/common/utility/utility.dart';
import 'package:iq_plus/core/local_storage/hive_service.dart';
import 'package:iq_plus/di/service_locator.dart';
import 'package:iq_plus/features/auth/model/customer_model.dart';
import 'package:iq_plus/features/periodic_compliance/cubit/periodic_compliance_cubit.dart';
import 'package:iq_plus/features/periodic_compliance/cubit/periodic_compliance_state.dart';
import 'package:iq_plus/features/periodic_compliance/models/periodic_compliance_model.dart';

class PeriodicComplianceListPage extends StatefulWidget {
  const PeriodicComplianceListPage({super.key});

  @override
  State<PeriodicComplianceListPage> createState() =>
      _PeriodicComplianceListPageState();
}

class _PeriodicComplianceListPageState
    extends State<PeriodicComplianceListPage> {
  late final PeriodicComplianceCubit _periodicComplianceCubit;
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  String selectedStatusFilter = 'all'; // 'all', 'pending', 'completed'
  String selectedCompanyFilter = 'all'; // 'all' or customerId
  List<CustomerModel> customerList = [];

  @override
  void initState() {
    super.initState();
    _periodicComplianceCubit = getIt<PeriodicComplianceCubit>();
    _loadTasks();
    fetchCustomerList();
  }

  void _loadTasks() {
    final hiveService = getIt<HiveService>();
    final user = hiveService.getUser();
    final customer = hiveService.getCustomer();

    final bool isCustomer = customer != null;
    final bool isConsultant = Utility.isConsultant(user?.roleId);

    final String? customerIdFilter = isCustomer ? customer.customerId : null;
    final String? createdByFilter = isConsultant ? user?.userId : null;

    _periodicComplianceCubit.loadTasks(
      customerId: customerIdFilter,
      createdBy: createdByFilter,
      isConsultant: isConsultant,
    );
  }

  @override
  void dispose() {
    _periodicComplianceCubit.close();
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchCustomerList() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('customers').get();
      var customers = snapshot.docs
          .map((doc) => CustomerModel.fromJson(doc.data(), customerId: doc.id))
          .toList();

      final user = getIt<HiveService>().getUser();
      final roleId = user?.roleId ?? '';

      // For consultant, filter options to assigned customers only
      if (Utility.isConsultant(roleId) && (user?.userId ?? '').isNotEmpty) {
        final consultantUserId = user?.userId;
        customers = customers
            .where((c) => c.consultantId == consultantUserId)
            .toList();
      }

      if (mounted) {
        setState(() {
          customerList = customers;
        });
      }
    } catch (e) {
      debugPrint("Error fetching customers for filter: $e");
    }
  }

  bool _isCompanyValid(String value) {
    if (value == 'all') return true;
    return customerList.any((c) => c.customerId == value);
  }

  List<PeriodicComplianceTask> _getFilteredList(
      List<PeriodicComplianceTask> originalList) {
    return originalList.where((task) {
      // 1. Status Filter
      if (selectedStatusFilter != 'all') {
        if (task.status != selectedStatusFilter) {
          return false;
        }
      }

      // 2. Company Filter
      if (selectedCompanyFilter != 'all') {
        if (task.assignedCustomerId != selectedCompanyFilter) {
          return false;
        }
      }

      // 3. Search Query
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase().trim();
        final title = task.title.toLowerCase();
        final desc = task.description.toLowerCase();
        final comp = task.assignedCustomerName.toLowerCase();
        final createdBy = task.createdByName.toLowerCase();

        final matches = title.contains(q) ||
            desc.contains(q) ||
            comp.contains(q) ||
            createdBy.contains(q);

        if (!matches) return false;
      }

      return true;
    }).toList();
  }

  Widget _buildFilterChip(String label, String value, Color color) {
    final isSelected = selectedStatusFilter == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
      ),
      selected: isSelected,
      selectedColor: color,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? color : Colors.grey.shade300,
        ),
      ),
      onSelected: (bool selected) {
        if (selected) {
          setState(() {
            selectedStatusFilter = value;
          });
        }
      },
    );
  }

  Widget _buildSearchAndFilters(bool isCustomer) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🔍 SEARCH BAR
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: "Search tasks by title, description, company...",
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              prefixIcon: const Icon(Icons.search, color: AppColors.primary),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        searchController.clear();
                        setState(() {
                          searchQuery = '';
                        });
                      },
                    )
                  : null,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            onChanged: (val) {
              setState(() {
                searchQuery = val;
              });
            },
          ),

          /// 🏢 COMPANY FILTER DROPDOWN
          if (!isCustomer && customerList.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _isCompanyValid(selectedCompanyFilter)
                      ? selectedCompanyFilter
                      : 'all',
                  isExpanded: true,
                  icon: const Icon(
                    Icons.business_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: 'all',
                      child: Text('All Companies'),
                    ),
                    ...customerList.map((customer) {
                      return DropdownMenuItem(
                        value: customer.customerId,
                        child: Text(
                          customer.companyName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedCompanyFilter = value;
                      });
                    }
                  },
                ),
              ),
            ),
          ],

          /// 🏷️ STATUS CHIPS
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip("All", "all", AppColors.primary),
                const SizedBox(width: 8),
                _buildFilterChip("Pending", "pending", Colors.orange),
                const SizedBox(width: 8),
                _buildFilterChip("Completed", "completed", Colors.green),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hiveService = getIt<HiveService>();
    final customer = hiveService.getCustomer();
    final bool isCustomer = customer != null;

    return BlocProvider.value(
      value: _periodicComplianceCubit,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: AppColors.titleText,
          title: const Text(
            'Periodic Compliance Tasks',
            style: TextStyle(
                fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -0.5),
          ),
        ),
        floatingActionButton: !isCustomer
            ? FloatingActionButton.extended(
                onPressed: () async {
                  final result =
                      await context.push(AppRoutes.periodicComplianceForm);
                  if (result == true && mounted) {
                    _loadTasks();
                  }
                },
                backgroundColor: AppColors.primary,
                icon: const Icon(Icons.add_task_rounded, color: Colors.white),
                label: const Text("New Task",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
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
            buildWhen: (previous, current) =>
                current is! PeriodicComplianceActionSuccess,
            builder: (context, state) {
              if (state is PeriodicComplianceLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is PeriodicComplianceLoaded) {
                final tasks = state.tasks;
                final filteredTasks = _getFilteredList(tasks);

                return Column(
                  children: [
                    /// 🔍 SEARCH & FILTERS
                    _buildSearchAndFilters(isCustomer),

                    /// 📋 LIST VIEW
                    Expanded(
                      child: filteredTasks.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off_rounded,
                                    size: 48,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    tasks.isEmpty
                                        ? "No compliance tasks found"
                                        : "No matching compliance tasks found",
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (searchQuery.isNotEmpty ||
                                      selectedStatusFilter != 'all' ||
                                      selectedCompanyFilter != 'all') ...[
                                    const SizedBox(height: 12),
                                    TextButton.icon(
                                      icon: const Icon(Icons.refresh),
                                      label: const Text("Clear Filters"),
                                      onPressed: () {
                                        searchController.clear();
                                        setState(() {
                                          searchQuery = '';
                                          selectedStatusFilter = 'all';
                                          selectedCompanyFilter = 'all';
                                        });
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              itemCount: filteredTasks.length,
                              itemBuilder: (context, index) {
                                return _TaskCard(
                                  task: filteredTasks[index],
                                  isCustomer: isCustomer,
                                  onRefresh: _loadTasks,
                                );
                              },
                            ),
                    ),
                  ],
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
}

class _TaskCard extends StatelessWidget {
  final PeriodicComplianceTask task;
  final bool isCustomer;
  final VoidCallback? onRefresh;

  const _TaskCard({
    required this.task,
    required this.isCustomer,
    this.onRefresh,
  });

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
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: InkWell(
        onTap: () =>
            context.push(AppRoutes.periodicComplianceDetails, extra: task),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (isPending ? Colors.orange : Colors.green)
                          .withValues(alpha: 0.1),
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
                          icon: const Icon(Icons.edit_note_rounded,
                              color: Colors.blue),
                          onPressed: () async {
                            final result = await context.push(
                              AppRoutes.periodicComplianceForm,
                              extra: task,
                            );
                            if (result == true) {
                              onRefresh?.call();
                            }
                          },
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(8),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded,
                              color: Colors.redAccent),
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
                  Icon(Icons.business_rounded,
                      size: 16, color: Colors.grey.shade400),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      task.assignedCustomerName,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700),
                    ),
                  ),
                  Icon(Icons.calendar_today_rounded,
                      size: 16, color: Colors.grey.shade400),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('dd MMM yyyy').format(task.dueDate),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: isPending && task.dueDate.isBefore(DateTime.now())
                          ? Colors.red
                          : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              if (!isCustomer && isPending) ...[
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () => context
                        .read<PeriodicComplianceCubit>()
                        .markAsCompleted(task.id),
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text(
                      "COMPLETE TASK",
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
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
        content: const Text(
            "Are you sure you want to delete this compliance task?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
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
