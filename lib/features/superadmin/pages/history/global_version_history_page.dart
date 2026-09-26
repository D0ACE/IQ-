import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/common/widgets/common_app_bar.dart';
import 'package:iq_plus/core/local_storage/hive_service.dart';
import 'package:iq_plus/di/service_locator.dart';
import 'package:iq_plus/features/admin/customers/cubit/customer_list_cubit.dart';
import 'package:iq_plus/features/admin/customers/cubit/customer_list_state.dart';
import 'package:iq_plus/features/auth/model/customer_model.dart';
import 'package:iq_plus/features/superadmin/cubit/document_cubit.dart';
import 'package:iq_plus/features/superadmin/cubit/document_state.dart';
import 'package:iq_plus/common/utility/utility.dart';
import 'package:iq_plus/features/superadmin/models/version_history_model.dart';

class GlobalVersionHistoryPage extends StatefulWidget {
  const GlobalVersionHistoryPage({super.key});

  @override
  State<GlobalVersionHistoryPage> createState() => _GlobalVersionHistoryPageState();
}

class _GlobalVersionHistoryPageState extends State<GlobalVersionHistoryPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'all'; // 'all', 'active', 'draft', 'rejected'
  String _selectedCompanyFilter = 'all'; // 'all' or customerId

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final user = getIt<HiveService>().getUser();
      final customer = getIt<HiveService>().getCustomer();
      
      context.read<DocumentCubit>().loadGlobalVersionHistory(
        userId: user?.userId,
        isConsultant: Utility.isConsultant(user?.roleId),
        customerId: customer?.customerId,
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _hasActiveFilters =>
      _searchQuery.isNotEmpty || _statusFilter != 'all' || _selectedCompanyFilter != 'all';

  void _clearAllFilters() {
    if (!mounted) return;
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _statusFilter = 'all';
      _selectedCompanyFilter = 'all';
    });
  }

  List<VersionHistoryModel> _getFilteredHistory(
    List<VersionHistoryModel> history,
    List<CustomerModel> customers,
  ) {
    return history.where((v) {
      // 1. Company Filter
      if (_selectedCompanyFilter != 'all') {
        if (v.customerId != _selectedCompanyFilter) {
          return false;
        }
      }

      // 2. Search Query
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase().trim();
        final docTitle = (v.docTitle ?? '').toLowerCase();
        final versionNo = v.versionNo.toLowerCase();
        final description = v.changeDescription.toLowerCase();
        final performedBy = v.performedBy.toLowerCase();
        final approvedBy = (v.approvedBy ?? '').toLowerCase();
        final rejectedBy = (v.rejectedBy ?? '').toLowerCase();
        final rejectionReason = (v.rejectionReason ?? '').toLowerCase();

        String companyName = '';
        if (v.customerId != null) {
          try {
            companyName = customers
                .firstWhere((c) => c.customerId == v.customerId)
                .companyName
                .toLowerCase();
          } catch (_) {}
        }

        final matches = docTitle.contains(q) ||
            versionNo.contains(q) ||
            description.contains(q) ||
            performedBy.contains(q) ||
            approvedBy.contains(q) ||
            rejectedBy.contains(q) ||
            rejectionReason.contains(q) ||
            companyName.contains(q);

        if (!matches) return false;
      }

      // 3. Status Filter
      final status = v.status.toLowerCase();
      if (_statusFilter == 'active' && status != 'active') {
        return false;
      }
      if (_statusFilter == 'draft' && status != 'draft') {
        return false;
      }
      if (_statusFilter == 'rejected' && (status != 'rejected' && status != 'reject')) {
        return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: const CommonAppBar(title: 'All Policies Version History'),
      body: BlocBuilder<DocumentCubit, DocumentState>(
        builder: (context, state) {
          if (state is DocumentLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is DocumentError) {
            return Center(child: Text(state.message));
          }
          if (state is GlobalVersionHistoryLoaded) {
            final hive = getIt<HiveService>();
            final user = hive.getUser();
            final customer = hive.getCustomer();
            final String? roleId = user?.roleId ?? customer?.roleId;

            final bool isCustomer = Utility.isCustomer(roleId);
            final bool isEmployee = Utility.isEmployee(roleId);
            final bool isConsultant = Utility.isConsultant(roleId);

            final allHistory = isEmployee 
                ? state.history.where((v) => v.status == 'active').toList() 
                : state.history;

            if (allHistory.isEmpty) {
              return Center(
                child: Text(
                  isEmployee ? 'No active policy history found' : 'No version history found',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                ),
              );
            }

            return BlocBuilder<CustomerListCubit, CustomerListState>(
              builder: (context, customerState) {
                List<CustomerModel> customers = [];
                final bool isCustomerLoading = customerState is CustomerListLoading;
                if (customerState is CustomerListLoaded) {
                  customers = customerState.customers;
                }

                // 🚀 Role-based company filter setup
                final bool showCompanyFilter = !isCustomer && !isEmployee;
                List<CustomerModel> availableCustomers = customers;
                if (isConsultant) {
                  availableCustomers = customers
                      .where((c) => c.consultantId == user?.userId)
                      .toList();
                }

                // Sanitize selected company filter if no longer in available customers
                if (_selectedCompanyFilter != 'all') {
                  final bool isValid = availableCustomers.any((c) => c.customerId == _selectedCompanyFilter);
                  if (!isValid) {
                    _selectedCompanyFilter = 'all';
                  }
                }

                final filteredHistory = _getFilteredHistory(allHistory, customers);
                final int totalCount = allHistory.length;
                final int activeCount = allHistory.where((v) => v.status == 'active').length;
                final int draftCount = allHistory.where((v) => v.status == 'draft').length;
                final int rejectedCount = allHistory.where((v) => v.status == 'rejected' || v.status == 'reject').length;

                return Column(
                  children: [
                    // 🔍 Search Bar & Status Filter Header
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Column(
                        children: [
                          // Search Input Field
                          Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (val) {
                                if (!mounted) return;
                                setState(() {
                                  _searchQuery = val;
                                });
                              },
                              decoration: InputDecoration(
                                hintText: 'Search title, company, version, author...',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 14,
                                ),
                                prefixIcon: const Icon(
                                  Icons.search_rounded,
                                  color: AppColors.kPrimaryColor,
                                  size: 22,
                                ),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.close_rounded, size: 20),
                                        onPressed: () {
                                          _searchController.clear();
                                          if (!mounted) return;
                                          setState(() {
                                            _searchQuery = '';
                                          });
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),

                          // 🏢 Company Dropdown Filter (Hidden for Customers/Employees, Assigned-only for Consultants)
                          if (showCompanyFilter) ...[
                            if (isCustomerLoading) ...[
                              const SizedBox(height: 10),
                              Container(
                                height: 44,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.business_rounded, size: 20, color: AppColors.kPrimaryColor),
                                    SizedBox(width: 10),
                                    Text(
                                      "Loading companies...",
                                      style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
                                    ),
                                    Spacer(),
                                    SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.kPrimaryColor),
                                    ),
                                  ],
                                ),
                              ),
                            ] else if (availableCustomers.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Container(
                                height: 44,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedCompanyFilter,
                                    isExpanded: true,
                                    icon: const Icon(Icons.business_rounded, size: 20, color: AppColors.kPrimaryColor),
                                    style: const TextStyle(
                                      color: AppColors.titleText,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    items: [
                                      const DropdownMenuItem(
                                        value: 'all',
                                        child: Text('All Companies'),
                                      ),
                                      ...availableCustomers.map((c) => DropdownMenuItem(
                                            value: c.customerId,
                                            child: Text(
                                              c.companyName,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          )),
                                    ],
                                    onChanged: (val) {
                                      if (val != null && mounted) {
                                        setState(() {
                                          _selectedCompanyFilter = val;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ],

                          // 🟢 Status Filter Chips (Shown if not employee restricted)
                          if (!isEmployee) ...[
                            const SizedBox(height: 12),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: Row(
                                children: [
                                  _buildStatusChip(
                                    label: 'All ($totalCount)',
                                    value: 'all',
                                  ),
                                  const SizedBox(width: 8),
                                  _buildStatusChip(
                                    label: 'Active ($activeCount)',
                                    value: 'active',
                                    activeColor: Colors.green,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildStatusChip(
                                    label: 'Draft ($draftCount)',
                                    value: 'draft',
                                    activeColor: Colors.orange,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildStatusChip(
                                    label: 'Rejected ($rejectedCount)',
                                    value: 'rejected',
                                    activeColor: Colors.redAccent,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // 📊 Active Filter Indicator Bar
                    if (_hasActiveFilters)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        color: AppColors.kPrimaryColor.withValues(alpha: 0.05),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Showing ${filteredHistory.length} of ${allHistory.length} history records",
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.titleText,
                              ),
                            ),
                            GestureDetector(
                              onTap: _clearAllFilters,
                              child: const Row(
                                children: [
                                  Icon(Icons.refresh_rounded, size: 14, color: AppColors.kPrimaryColor),
                                  SizedBox(width: 4),
                                  Text(
                                    "Clear filters",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.kPrimaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    // 📋 History List / Empty Filter State
                    Expanded(
                      child: filteredHistory.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.history_toggle_off_rounded,
                                    size: 64,
                                    color: Colors.grey.shade300,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    "No matching version history found",
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Try adjusting your search query or filters",
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: _clearAllFilters,
                                    icon: const Icon(Icons.clear_all_rounded, size: 18),
                                    label: const Text("Reset Filters"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.kPrimaryColor,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: filteredHistory.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final v = filteredHistory[index];
                                final isRejected = v.status == 'rejected' || v.status == 'reject';
                                final statusColor = v.status == 'active'
                                    ? Colors.green
                                    : isRejected
                                        ? Colors.red
                                        : Colors.orange;

                                String companyName = '';
                                if (v.customerId != null && customers.isNotEmpty) {
                                  try {
                                    companyName = customers
                                        .firstWhere((c) => c.customerId == v.customerId)
                                        .companyName;
                                  } catch (_) {}
                                }

                                return Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                v.docTitle ?? "Document History",
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.purple),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: statusColor.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                v.status.toUpperCase(),
                                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (companyName.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.business_rounded, size: 14, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Text(
                                                companyName,
                                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blueGrey),
                                              ),
                                            ],
                                          ),
                                        ],
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Text("Version: ", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                            Text(v.versionNo, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.purple)),
                                            const Spacer(),
                                            Text(
                                              DateFormat('dd MMM yyyy, hh:mm a').format(v.performedDate),
                                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                        const Divider(height: 20),
                                        Text(
                                          "Description of the change: ${v.changeDescription}",
                                          style: const TextStyle(fontSize: 13, height: 1.4),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          "Performed By: ${v.performedBy} on ${DateFormat('dd MMM yyyy').format(v.performedDate)}",
                                          style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.blueGrey),
                                        ),
                                        if (v.status == 'active' && v.approvedBy != null)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Text(
                                              "Approved by: ${v.approvedBy} on ${v.approvedDate != null ? DateFormat('dd MMM yyyy').format(v.approvedDate!) : 'N/A'}",
                                              style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        if (isRejected && (v.rejectionReason != null || v.rejectedBy != null))
                                          Container(
                                            margin: const EdgeInsets.only(top: 8),
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: Colors.red.withValues(alpha: 0.08),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "Rejected by: ${v.rejectedBy ?? v.performedBy}",
                                                  style: const TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold),
                                                ),
                                                if (v.rejectionReason != null && v.rejectionReason!.isNotEmpty) ...[
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    "Reason: ${v.rejectionReason}",
                                                    style: TextStyle(fontSize: 11, color: Colors.red.shade900, fontWeight: FontWeight.w600),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildStatusChip({
    required String label,
    required String value,
    Color? activeColor,
  }) {
    final bool isSelected = _statusFilter == value;
    final Color color = activeColor ?? AppColors.kPrimaryColor;

    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey.shade700,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          fontSize: 13,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected && mounted) {
          setState(() {
            _statusFilter = value;
          });
        }
      },
      selectedColor: color,
      backgroundColor: const Color(0xFFF1F5F9),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide.none,
      ),
    );
  }
}
