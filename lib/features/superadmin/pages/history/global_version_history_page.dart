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
  final ScrollController _scrollController = ScrollController();

  String _searchQuery = '';
  String _statusFilter = 'all'; // 'all', 'active', 'draft', 'rejected'
  String _selectedCompanyFilter = 'all'; // 'all' or customerId

  // 🎛️ View Mode Selector (Default to Table Format)
  bool _isTableView = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadInitialData();
    });
  }

  void _loadInitialData() {
    final user = getIt<HiveService>().getUser();
    final customer = getIt<HiveService>().getCustomer();

    context.read<DocumentCubit>().loadGlobalVersionHistory(
      userId: user?.userId,
      isConsultant: Utility.isConsultant(user?.roleId),
      customerId: customer?.customerId ?? user?.customerId,
    );
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    // Trigger fetch from Firebase when user reaches within 200px from the bottom
    if (maxScroll - currentScroll <= 200) {
      final user = getIt<HiveService>().getUser();
      final customer = getIt<HiveService>().getCustomer();

      context.read<DocumentCubit>().loadMoreGlobalVersionHistory(
        userId: user?.userId,
        isConsultant: Utility.isConsultant(user?.roleId),
        customerId: customer?.customerId ?? user?.customerId,
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
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

            final String? effectiveCustomerId = customer?.customerId ?? user?.customerId;

            final allHistory = (isEmployee || isCustomer) &&
                    effectiveCustomerId != null &&
                    effectiveCustomerId.isNotEmpty
                ? state.history
                    .where((v) =>
                        (isCustomer || v.status == 'active') &&
                        v.customerId == effectiveCustomerId)
                    .toList()
                : state.history;

            if (allHistory.isEmpty && !state.isLoadingMore) {
              return Center(
                child: Text(
                  isEmployee
                      ? 'No active policy history found'
                      : 'No version history found',
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

                if (_selectedCompanyFilter != 'all') {
                  final bool isValid = availableCustomers
                      .any((c) => c.customerId == _selectedCompanyFilter);
                  if (!isValid) {
                    _selectedCompanyFilter = 'all';
                  }
                }

                final companyFilteredHistory = _selectedCompanyFilter == 'all'
                    ? allHistory
                    : allHistory.where((v) => v.customerId == _selectedCompanyFilter).toList();

                final filteredHistory = _getFilteredHistory(companyFilteredHistory, customers);
                final int totalCount = companyFilteredHistory.length;
                final int activeCount =
                    companyFilteredHistory.where((v) => v.status == 'active').length;
                final int draftCount =
                    companyFilteredHistory.where((v) => v.status == 'draft').length;
                final int rejectedCount = companyFilteredHistory
                    .where((v) => v.status == 'rejected' || v.status == 'reject')
                    .length;

                return Column(
                  children: [
                    // 🔍 Search Bar & Header Controls
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              // Search Input Field
                              Expanded(
                                child: Container(
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
                                      hintText:
                                          'Search title, company, version, author...',
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
                              ),
                              const SizedBox(width: 8),

                              // 🎛️ Table / Card View Switcher
                              Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.table_chart_rounded,
                                        color: _isTableView
                                            ? AppColors.kPrimaryColor
                                            : Colors.grey,
                                      ),
                                      tooltip: 'Table Format',
                                      onPressed: () {
                                        if (!_isTableView && mounted) {
                                          setState(() => _isTableView = true);
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.grid_view_rounded,
                                        color: !_isTableView
                                            ? AppColors.kPrimaryColor
                                            : Colors.grey,
                                      ),
                                      tooltip: 'Card Format',
                                      onPressed: () {
                                        if (_isTableView && mounted) {
                                          setState(() => _isTableView = false);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // 🏢 Company Filter
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
                                    Icon(Icons.business_rounded,
                                        size: 20, color: AppColors.kPrimaryColor),
                                    SizedBox(width: 10),
                                    Text(
                                      "Loading companies...",
                                      style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500),
                                    ),
                                    Spacer(),
                                    SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.kPrimaryColor),
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
                                    icon: const Icon(Icons.business_rounded,
                                        size: 20, color: AppColors.kPrimaryColor),
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

                          // 🟢 Status Filter Chips
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
                              "Showing ${filteredHistory.length} of ${companyFilteredHistory.length} loaded records",
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
                                  Icon(Icons.refresh_rounded,
                                      size: 14, color: AppColors.kPrimaryColor),
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

                    // 📋 Main Body
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
                                    style: TextStyle(
                                        color: Colors.grey.shade500, fontSize: 13),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: _clearAllFilters,
                                    icon: const Icon(Icons.clear_all_rounded, size: 18),
                                    label: const Text("Reset Filters"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.buttonDarkGreen,
                                      foregroundColor: AppColors.buttonYellow,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : _isTableView
                              ? _buildTableView(
                                  historyList: filteredHistory,
                                  customers: customers,
                                  isLoadingMore: state.isLoadingMore,
                                  hasMore: state.hasMore,
                                )
                              : _buildCardListView(
                                  historyList: filteredHistory,
                                  customers: customers,
                                  isLoadingMore: state.isLoadingMore,
                                  hasMore: state.hasMore,
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

  /// 📊 Table Format View with Scroll-to-Bottom Pagination
  Widget _buildTableView({
    required List<VersionHistoryModel> historyList,
    required List<CustomerModel> customers,
    required bool isLoadingMore,
    required bool hasMore,
  }) {
    return SingleChildScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      scrollDirection: Axis.vertical,
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                headingTextStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.titleText,
                  fontSize: 13,
                ),
                dataTextStyle: const TextStyle(fontSize: 13, color: Colors.black87),
                horizontalMargin: 16,
                columnSpacing: 20,
                columns: const [
                  DataColumn(label: Text('#')),
                  DataColumn(label: Text('Policy Title / Company')),
                  DataColumn(label: Text('Version')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Change Description')),
                  DataColumn(label: Text('Performed By & Date')),
                  DataColumn(label: Text('Approval / Rejection Info')),
                ],
                rows: historyList.asMap().entries.map((entry) {
                  final int index = entry.key;
                  final VersionHistoryModel v = entry.value;
                  final bool isRejected =
                      v.status == 'rejected' || v.status == 'reject';
                  final Color statusColor = v.status == 'active'
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

                  return DataRow(
                    color: index % 2 == 1
                        ? WidgetStateProperty.all(const Color(0xFFFAFAFA))
                        : WidgetStateProperty.all(Colors.white),
                    cells: [
                      // # Index
                      DataCell(Text('${index + 1}')),

                      // Policy Title & Company
                      DataCell(
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 220),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                v.docTitle ?? 'Document History',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.purple,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (companyName.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.business_rounded,
                                        size: 12, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        companyName,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blueGrey,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      // Version
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.purple.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            v.versionNo,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.purple,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),

                      // Status Badge
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: statusColor.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            v.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ),

                      // Change Description
                      DataCell(
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 240),
                          child: Text(
                            v.changeDescription.isEmpty ? '-' : v.changeDescription,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),

                      // Performed By & Date
                      DataCell(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              v.performedBy.isEmpty ? '-' : v.performedBy,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 12),
                            ),
                            Text(
                              DateFormat('dd MMM yyyy, hh:mm a')
                                  .format(v.performedDate),
                              style:
                                  const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),

                      // Approval / Rejection Info
                      DataCell(
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 220),
                          child: v.status == 'active' && v.approvedBy != null
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Approved by: ${v.approvedBy}",
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (v.approvedDate != null)
                                      Text(
                                        DateFormat('dd MMM yyyy')
                                            .format(v.approvedDate!),
                                        style: const TextStyle(
                                            fontSize: 10, color: Colors.grey),
                                      ),
                                  ],
                                )
                              : isRejected &&
                                      (v.rejectionReason != null ||
                                          v.rejectedBy != null)
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Rejected by: ${v.rejectedBy ?? v.performedBy}",
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.red,
                                              fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (v.rejectionReason != null &&
                                            v.rejectionReason!.isNotEmpty)
                                          Text(
                                            "Reason: ${v.rejectionReason}",
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.red.shade900),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                      ],
                                    )
                                  : const Text('-'),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),

        // Bottom scroll loading / status indicator
        _buildBottomLoadingStatus(
          isLoadingMore: isLoadingMore,
          hasMore: hasMore,
          loadedCount: historyList.length,
        ),
      ],
    ),
  );
}

  /// 📇 Card Format View
  Widget _buildCardListView({
    required List<VersionHistoryModel> historyList,
    required List<CustomerModel> customers,
    required bool isLoadingMore,
    required bool hasMore,
  }) {
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: historyList.length + 1,
      separatorBuilder: (_, index) =>
          index < historyList.length ? const SizedBox(height: 12) : const SizedBox.shrink(),
      itemBuilder: (context, index) {
        if (index == historyList.length) {
          return _buildBottomLoadingStatus(
            isLoadingMore: isLoadingMore,
            hasMore: hasMore,
            loadedCount: historyList.length,
          );
        }

        final v = historyList[index];
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
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.purple),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        v.status.toUpperCase(),
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: statusColor),
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
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.blueGrey),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text("Version: ",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    Text(v.versionNo,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.purple)),
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
                  style: const TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: Colors.blueGrey),
                ),
                if (v.status == 'active' && v.approvedBy != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      "Approved by: ${v.approvedBy} on ${v.approvedDate != null ? DateFormat('dd MMM yyyy').format(v.approvedDate!) : 'N/A'}",
                      style: const TextStyle(
                          fontSize: 11,
                          color: Colors.green,
                          fontWeight: FontWeight.bold),
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
                          style: const TextStyle(
                              fontSize: 11,
                              color: Colors.red,
                              fontWeight: FontWeight.bold),
                        ),
                        if (v.rejectionReason != null &&
                            v.rejectionReason!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            "Reason: ${v.rejectionReason}",
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.red.shade900,
                                fontWeight: FontWeight.w600),
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
    );
  }

  /// 🔄 Bottom Status Indicator for Infinite Scroll
  Widget _buildBottomLoadingStatus({
    required bool isLoadingMore,
    required bool hasMore,
    required int loadedCount,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: isLoadingMore
            ? const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.kPrimaryColor,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Fetching more records from Firebase...",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              )
            : !hasMore && loadedCount > 0
                ? Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "All $loadedCount records loaded",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
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
