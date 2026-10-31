import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:iq_plus/common/routes/go_route.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/common/utility/utility.dart';
import 'package:iq_plus/core/local_storage/hive_service.dart';
import 'package:iq_plus/core/supabase/supabase_config.dart';
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
  String selectedStatusFilter = 'all'; // 'all', 'pending', 'in_progress', 'completed'
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

    final String? customerIdFilter = isCustomer
        ? customer.customerId
        : (Utility.isEmployee(user?.roleId) ? user?.customerId : null);
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
    final hiveService = getIt<HiveService>();
    final user = hiveService.getUser();
    final customer = hiveService.getCustomer();
    final effectiveCustomerId = customer?.customerId ?? user?.customerId;
    final roleId = user?.roleId ?? customer?.roleId;
    final isRestricted = Utility.isCustomer(roleId) || Utility.isEmployee(roleId);

    return originalList.where((task) {
      if (isRestricted && effectiveCustomerId != null && effectiveCustomerId.isNotEmpty) {
        if (task.assignedCustomerId != effectiveCustomerId) {
          return false;
        }
      }

      // 1. Status Filter
      if (selectedStatusFilter != 'all') {
        final effStatus = task.effectiveStatus;
        if (selectedStatusFilter == 'non_compliant' || selectedStatusFilter == 'non compliant') {
          if (effStatus != 'non_compliant') return false;
        } else if (selectedStatusFilter == 'open' || selectedStatusFilter == 'pending') {
          if (effStatus != 'open') return false;
        } else {
          if (effStatus != selectedStatusFilter.toLowerCase()) {
            return false;
          }
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
                _buildFilterChip("Open", "open", Colors.orange),
                const SizedBox(width: 8),
                _buildFilterChip("In Progress", "in_progress", Colors.blue),
                const SizedBox(width: 8),
                _buildFilterChip("Completed", "completed", Colors.green),
                const SizedBox(width: 8),
                _buildFilterChip("Non Compliant", "non_compliant", Colors.red),
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
    final user = hiveService.getUser();
    final bool isCustomer = customer != null;
    final bool isEmployee = Utility.isEmployee(user?.roleId);
    final bool isReadOnly = isCustomer || isEmployee;

    return BlocProvider.value(
      value: _periodicComplianceCubit,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: AppColors.titleText,
          title: const Text(
            'Compliance Tasks',
            style: TextStyle(
                fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -0.5),
          ),
        ),
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (!isReadOnly) ...[
              FloatingActionButton.extended(
                heroTag: 'new_task_btn',
                onPressed: () async {
                  final result =
                      await context.push(AppRoutes.periodicComplianceForm);
                  if (result == true && mounted) {
                    _loadTasks();
                  }
                },
                backgroundColor: AppColors.buttonDarkGreen,
                icon: const Icon(Icons.add_task_rounded, color: AppColors.buttonYellow),
                label: const Text(
                  "New Task",
                  style: TextStyle(
                    color: AppColors.buttonYellow,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            FloatingActionButton.extended(
              heroTag: 'kpi_btn',
              onPressed: () {
                context.push(AppRoutes.kpiList);
              },
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              elevation: 3,
              icon: const Icon(Icons.analytics_outlined, color: AppColors.primary),
              label: const Text(
                "KPI's",
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
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
                                  isCustomer: isReadOnly,
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
      case 'in progress':
        return Colors.blue;
      case 'non_compliant':
      case 'non compliant':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'COMPLETED';
      case 'in_progress':
      case 'in progress':
        return 'IN PROGRESS';
      case 'non_compliant':
      case 'non compliant':
        return 'NON COMPLIANT';
      case 'open':
      case 'pending':
      default:
        return 'OPEN';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = task.status.toLowerCase() == 'completed';
    final statusColor = _getStatusColor(task.effectiveStatus);
    final statusText = _getStatusText(task.effectiveStatus);

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
                  Row(
                    children: [
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      if (task.isAutoGenerate) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.autorenew_rounded,
                                  size: 12, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(
                                task.frequency.toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
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
                      color: task.isNonCompliant
                          ? Colors.red
                          : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              if (task.target.isNotEmpty || task.achieved.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (task.target.isNotEmpty)
                        Text(
                          'Target: ${task.targetType == 'Number' ? task.target.replaceAll('%', '') : (task.target.endsWith('%') ? task.target : '${task.target}%')}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      if (task.achieved.isNotEmpty)
                        Text(
                          'Achieved: ${task.achievedType == 'Number' ? task.achieved.replaceAll('%', '') : (task.achieved.endsWith('%') ? task.achieved : '${task.achieved}%')}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              if (task.comment.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.comment_rounded,
                          size: 16, color: Colors.amber.shade800),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Comments:",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              task.comment,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.titleText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (task.evidenceUrl.isNotEmpty) ...[
                const SizedBox(height: 12),
                Builder(
                  builder: (context) {
                    final urls = task.evidenceUrl
                        .split(',')
                        .map((e) => e.trim())
                        .where((e) => e.isNotEmpty)
                        .toList();
                    final names = task.evidenceFileName
                        .split(',')
                        .map((e) => e.trim())
                        .where((e) => e.isNotEmpty)
                        .toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.attach_file_rounded,
                                size: 14, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              "Evidence Documents (${urls.length}):",
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: List.generate(urls.length, (index) {
                            final url = urls[index];
                            final name = (index < names.length &&
                                    names[index].isNotEmpty)
                                ? names[index]
                                : 'Document ${index + 1}';
                            return InkWell(
                              onTap: () async {
                                final uri = Uri.parse(url);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri,
                                      mode: LaunchMode.externalApplication);
                                }
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.description_rounded,
                                        size: 14, color: AppColors.primary),
                                    const SizedBox(width: 6),
                                    ConstrainedBox(
                                      constraints:
                                          const BoxConstraints(maxWidth: 160),
                                      child: Text(
                                        name,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.titleText,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.open_in_new_rounded,
                                        size: 12, color: AppColors.primary),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    );
                  },
                ),
              ],
              if (!isCustomer && !isCompleted) ...[
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () => _showEvidenceUploadDialog(context, task),
                    icon: const Icon(Icons.upload_file_rounded, size: 16),
                    label: Text(
                      task.status.toLowerCase() == 'in_progress'
                          ? "UPDATE PROGRESS / COMPLETE"
                          : "COMPLETE TASK",
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonDarkGreen,
                      foregroundColor: AppColors.buttonYellow,
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

  void _showEvidenceUploadDialog(
      BuildContext context, PeriodicComplianceTask task) {
    final cubit = context.read<PeriodicComplianceCubit>();
    Uint8List? selectedFileBytes;
    String? selectedFileName;
    final TextEditingController achievedController = TextEditingController(
        text: (task.achieved).replaceAll('%', '').trim());
    String selectedAchievedType =
        task.achievedType.isNotEmpty ? task.achievedType : 'Percentage';
    final TextEditingController commentController = TextEditingController(
        text: task.comment);
    bool isUploading = false;

    final existingUrls = task.evidenceUrl
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final existingNames = task.evidenceFileName
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final int existingCount = existingUrls.length;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setState) {
          Future<void> pickFile() async {
            if (existingCount >= 10) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Maximum limit of 10 evidence files reached"),
                  backgroundColor: Colors.orange,
                ),
              );
              return;
            }

            try {
              final result = await FilePicker.platform.pickFiles(
                type: FileType.any,
                withData: true,
              );
              if (result != null && result.files.isNotEmpty) {
                final file = result.files.single;
                setState(() {
                  selectedFileBytes = file.bytes;
                  selectedFileName = file.name;
                });
              }
            } catch (e) {
              debugPrint("Error picking file: $e");
            }
          }

          Future<String?> uploadSelectedFile() async {
            if (selectedFileBytes == null || selectedFileName == null) {
              return null;
            }
            final sanitizedFileName =
                selectedFileName!.replaceAll(RegExp(r'[^\w.-]'), '_');
            final String supabasePath =
                'compliance_evidence/task_${task.id}_${DateTime.now().millisecondsSinceEpoch}_$sanitizedFileName';

            final supabase = Supabase.instance.client;
            await supabase.storage
                .from(SupabaseConfig.bucketName)
                .uploadBinary(
                  supabasePath,
                  selectedFileBytes!,
                  fileOptions:
                      const FileOptions(cacheControl: '3600', upsert: true),
                );

            return supabase.storage
                .from(SupabaseConfig.bucketName)
                .getPublicUrl(supabasePath);
          }

          String formatAchieved(String input, String achievedType) {
            final clean = input.trim().replaceAll('%', '').trim();
            if (clean.isEmpty) return '';
            if (achievedType == 'Percentage') {
              return '$clean%';
            } else {
              return clean;
            }
          }

          Future<void> handleSave() async {
            if (existingCount >= 10 && selectedFileBytes != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Maximum limit of 10 evidence files reached"),
                  backgroundColor: Colors.orange,
                ),
              );
              return;
            }

            setState(() => isUploading = true);

            try {
              final uploadedUrl = await uploadSelectedFile();
              final formattedAchieved = formatAchieved(
                  achievedController.text, selectedAchievedType);

              await cubit.saveProgress(
                task.id,
                evidenceUrl: uploadedUrl ?? '',
                evidenceFileName: selectedFileName ?? '',
                comment: commentController.text.trim(),
                achieved: formattedAchieved,
                achievedType: selectedAchievedType,
              );

              if (dialogCtx.mounted) {
                Navigator.pop(dialogCtx);
              }
            } catch (e) {
              if (context.mounted) {
                setState(() => isUploading = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Error saving progress: $e"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          }

          Future<void> handleComplete() async {
            setState(() => isUploading = true);

            try {
              final uploadedUrl = await uploadSelectedFile();
              final formattedAchieved = formatAchieved(
                  achievedController.text, selectedAchievedType);

              await cubit.markAsCompleted(
                task.id,
                evidenceUrl: uploadedUrl ?? '',
                evidenceFileName: selectedFileName ?? '',
                comment: commentController.text.trim(),
                achieved: formattedAchieved,
                achievedType: selectedAchievedType,
              );

              if (dialogCtx.mounted) {
                Navigator.pop(dialogCtx);
              }
            } catch (e) {
              if (context.mounted) {
                setState(() => isUploading = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Error completing task: $e"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          }

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.upload_file_rounded,
                                color: AppColors.primary, size: 24),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Text(
                              "Task Action & Evidence",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppColors.titleText,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Update progress for '${task.title}'. You can upload up to 10 files, add notes, and set achieved value.",
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 16),

                      /// Achieved Format & Value
                      DropdownButtonFormField<String>(
                        initialValue: selectedAchievedType,
                        decoration: InputDecoration(
                          labelText: "Achieved Format",
                          hintText: "Select format",
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 2),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'Percentage',
                              child: Text('Percentage (%)')),
                          DropdownMenuItem(
                              value: 'Number', child: Text('Number')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => selectedAchievedType = val);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: achievedController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: "Achieved Value",
                          hintText: selectedAchievedType == 'Percentage'
                              ? "e.g. 75%"
                              : "e.g. 95",
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (existingCount > 0) ...[
                        Text(
                          "Uploaded Evidence Files ($existingCount / 10):",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Column(
                          children: List.generate(existingCount, (idx) {
                            final name = (idx < existingNames.length &&
                                    existingNames[idx].isNotEmpty)
                              ? existingNames[idx]
                              : 'Document ${idx + 1}';
                            final url = (idx < existingUrls.length)
                                ? existingUrls[idx]
                                : '';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border:
                                    Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.description_rounded,
                                      size: 16, color: AppColors.primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (url.isNotEmpty)
                                    IconButton(
                                      icon: const Icon(
                                          Icons.open_in_new_rounded,
                                          size: 16,
                                          color: AppColors.primary),
                                      onPressed: () async {
                                        final uri = Uri.parse(url);
                                        if (await canLaunchUrl(uri)) {
                                          await launchUrl(uri,
                                              mode: LaunchMode
                                                  .externalApplication);
                                        }
                                      },
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(4),
                                    ),
                                ],
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 12),
                      ],

                      /// File upload area
                      if (existingCount < 10)
                        InkWell(
                          onTap: isUploading ? null : pickFile,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: selectedFileName != null
                                  ? Colors.green.shade50
                                      .withValues(alpha: 0.5)
                                  : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: selectedFileName != null
                                    ? Colors.green.shade300
                                    : Colors.grey.shade300,
                                width: selectedFileName != null ? 1.5 : 1,
                              ),
                            ),
                            child: selectedFileName != null
                                ? Row(
                                    children: [
                                      const Icon(Icons.description_rounded,
                                          color: Colors.green, size: 28),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              selectedFileName!,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.titleText,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            const Text(
                                              "File selected",
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.green,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (!isUploading)
                                        IconButton(
                                          icon: const Icon(Icons.close_rounded,
                                              color: Colors.grey),
                                          onPressed: () {
                                            setState(() {
                                              selectedFileBytes = null;
                                              selectedFileName = null;
                                            });
                                          },
                                        ),
                                    ],
                                  )
                                : Column(
                                    children: [
                                      Icon(Icons.cloud_upload_outlined,
                                          size: 36,
                                          color: AppColors.primary
                                              .withValues(alpha: 0.7)),
                                      const SizedBox(height: 8),
                                      const Text(
                                        "Click to choose document",
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "PDF, DOC, Images, Spreadsheets, etc.",
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: const Text(
                            "Maximum limit of 10 evidence files reached.",
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange,
                                fontWeight: FontWeight.bold),
                          ),
                        ),

                      const SizedBox(height: 16),
                      TextFormField(
                        controller: commentController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: "Comment / Notes",
                          hintText: "Enter any comments or notes...",
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 2),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: isUploading
                                ? null
                                : () => Navigator.pop(dialogCtx),
                            child: const Text("Cancel"),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: (isUploading || existingCount >= 10)
                                ? null
                                : handleSave,
                            icon: const Icon(Icons.save_rounded, size: 16),
                            label: const Text(
                              "SAVE",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.buttonDarkGreen,
                              foregroundColor: AppColors.buttonYellow,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: isUploading ? null : handleComplete,
                            icon: isUploading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.buttonYellow,
                                    ),
                                  )
                                : const Icon(Icons.check_circle_rounded,
                                    size: 16),
                            label: Text(
                              isUploading ? "Uploading..." : "COMPLETE TASK",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.buttonDarkGreen,
                              foregroundColor: AppColors.buttonYellow,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
