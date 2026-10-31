import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iq_plus/common/routes/go_route.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/common/utility/utility.dart';
import 'package:iq_plus/common/widgets/common_app_bar.dart';
import 'package:iq_plus/core/local_storage/hive_service.dart';
import 'package:iq_plus/di/service_locator.dart';
import 'package:iq_plus/features/admin/customers/cubit/customer_list_cubit.dart';
import 'package:iq_plus/features/admin/customers/cubit/customer_list_state.dart';
import 'package:iq_plus/features/auth/model/customer_model.dart';
import 'package:iq_plus/features/superadmin/models/document_model.dart';
import 'package:iq_plus/features/superadmin/models/version_history_model.dart';
import 'package:iq_plus/features/superadmin/repository/document_repository.dart';
import 'package:iq_plus/features/superadmin/cubit/document_cubit.dart';
import 'package:iq_plus/features/superadmin/cubit/document_state.dart';
import 'package:intl/intl.dart';

class CustomerPolicyListPage extends StatefulWidget {
  const CustomerPolicyListPage({super.key});

  @override
  State<CustomerPolicyListPage> createState() => _CustomerPolicyListPageState();
}

class _CustomerPolicyListPageState extends State<CustomerPolicyListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'all'; // 'all', 'active', 'draft', 'rejected'
  String _selectedCompanyFilter = 'all'; // 'all' or customerId

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final hive = getIt<HiveService>();
      final customer = hive.getCustomer();
      final user = hive.getUser();

      final bool isConsultant = Utility.isConsultant(user?.roleId);
      final String? consultantIdFilter = isConsultant ? user?.userId : null;

      // 🚀 Determine customerId from either Customer or Employee session
      final String? effectiveCustomerId = customer?.customerId ?? user?.customerId;

      context.read<DocumentCubit>().loadDocuments(
        userId: consultantIdFilter,
        isConsultant: isConsultant,
        customerId: effectiveCustomerId,
      );

      context.read<CustomerListCubit>().fetchApprovedCustomers(consultantIdFilter);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static final Map<String, String> _companyNameCache = {};

  Future<String> _getCompanyNameForDoc(String? customerId) async {
    if (customerId == null || customerId.isEmpty) return '';
    if (_companyNameCache.containsKey(customerId)) {
      return _companyNameCache[customerId]!;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(customerId)
          .get();
      if (doc.exists && doc.data() != null) {
        final name = doc.data()?['companyName']?.toString() ?? '';
        _companyNameCache[customerId] = name;
        return name;
      }
    } catch (_) {}
    return '';
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

  List<DocumentModel> _getFilteredDocuments(
    List<DocumentModel> docs,
    List<CustomerModel> customers,
  ) {
    final hive = getIt<HiveService>();
    final user = hive.getUser();
    final customer = hive.getCustomer();
    final effectiveCustomerId = customer?.customerId ?? user?.customerId;
    final roleId = user?.roleId ?? customer?.roleId;
    final isRestricted = Utility.isCustomer(roleId) || Utility.isEmployee(roleId);

    return docs.where((doc) {
      if (isRestricted && effectiveCustomerId != null && effectiveCustomerId.isNotEmpty) {
        if (doc.customerId != effectiveCustomerId) {
          return false;
        }
      }

      // 1. Company Filter
      if (_selectedCompanyFilter != 'all') {
        if (doc.customerId != _selectedCompanyFilter) {
          return false;
        }
      }

      // 2. Search Query Filter
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase().trim();
        final title = doc.title.toLowerCase();
        final createdBy = doc.createdBy.toLowerCase();
        final reviewedBy = (doc.reviewedBy ?? '').toLowerCase();
        final version = doc.currentVersion.toLowerCase();
        final fileType = doc.fileType.toLowerCase();

        String companyName = '';
        if (doc.customerId != null) {
          try {
            companyName = customers
                .firstWhere((c) => c.customerId == doc.customerId)
                .companyName
                .toLowerCase();
          } catch (_) {}
        }

        final matches = title.contains(q) ||
            createdBy.contains(q) ||
            reviewedBy.contains(q) ||
            version.contains(q) ||
            fileType.contains(q) ||
            companyName.contains(q);

        if (!matches) return false;
      }

      // 3. Status Filter
      final String status = doc.status.toLowerCase();
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const CommonAppBar(title: 'My Policies & Procedures'),
      body: Stack(
        children: [
          // 🎨 Optimized Dot Pattern Background (Non-interactive)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _DotPatternPainter(
                  dotColor: AppColors.kPrimaryColor.withValues(alpha: 0.05),
                ),
              ),
            ),
          ),

          BlocBuilder<DocumentCubit, DocumentState>(
            builder: (context, state) {
              if (state is DocumentLoading || state is GlobalVersionHistoryLoaded || state is DocumentInitial || state is DocumentOperationSuccess) {
                if (state is GlobalVersionHistoryLoaded || state is DocumentInitial) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    final hive = getIt<HiveService>();
                    final customer = hive.getCustomer();
                    final user = hive.getUser();

                    final bool isConsultant = Utility.isConsultant(user?.roleId);
                    final String? consultantIdFilter = isConsultant ? user?.userId : null;
                    final String? effectiveCustomerId = customer?.customerId ?? user?.customerId;

                    context.read<DocumentCubit>().loadDocuments(
                      userId: consultantIdFilter,
                      isConsultant: isConsultant,
                      customerId: effectiveCustomerId,
                    );
                  });
                }
                return const Center(child: CircularProgressIndicator());
              }
              if (state is DocumentError) {
                return Center(child: Text(state.message));
              }
              if (state is DocumentLoaded) {
                final hive = getIt<HiveService>();
                final user = hive.getUser();
                final customer = hive.getCustomer();
                final String? roleId = user?.roleId ?? customer?.roleId;

                final bool isCustomer = Utility.isCustomer(roleId);
                final bool isEmployee = Utility.isEmployee(roleId);
                final bool isConsultant = Utility.isConsultant(roleId);

                final allDocs = isEmployee
                    ? state.documents.where((doc) => doc.status == 'active').toList()
                    : state.documents;

                if (allDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.policy_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          isEmployee ? 'No active policies found' : 'No policies assigned yet',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                        ),
                      ],
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

                    final companyFilteredDocs = _selectedCompanyFilter == 'all'
                        ? allDocs
                        : allDocs.where((d) => d.customerId == _selectedCompanyFilter).toList();

                    final filteredDocs = _getFilteredDocuments(companyFilteredDocs, customers);
                    final int totalCount = companyFilteredDocs.length;
                    final int activeCount = companyFilteredDocs.where((d) => d.status == 'active').length;
                    final int draftCount = companyFilteredDocs.where((d) => d.status == 'draft').length;
                    final int rejectedCount = companyFilteredDocs.where((d) => d.status == 'rejected' || d.status == 'reject').length;

                    return Column(
                      children: [
                        // 🔍 Search Bar & Filters Header Section
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
                                    hintText: 'Search policy title, company, author...',
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

                              // 🏢 Separate Customer Filter Loading / Selector (Hidden for Customers/Employees)
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

                              // 🟢 Status Filter Chips (Only shown if not restricted to employees)
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
                                  "Showing ${filteredDocs.length} of ${allDocs.length} policies",
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

                        // 📋 Policy List View / Empty Filter State
                        Expanded(
                          child: filteredDocs.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.policy_outlined,
                                        size: 64,
                                        color: Colors.grey.shade300,
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        "No matching policies found",
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
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: filteredDocs.length,
                                  itemBuilder: (context, index) {
                                    final doc = filteredDocs[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 24),
                                      child: _neoModernPolicyCard(doc),
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
        ],
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

  Widget _neoModernPolicyCard(DocumentModel doc) {
    final hive = getIt<HiveService>();
    final user = hive.getUser();
    final customer = hive.getCustomer();
    final String? roleId = user?.roleId ?? customer?.roleId;

    final bool canEditOrDelete = !Utility.isEmployee(roleId) &&
        (Utility.isConsultant(roleId) ||
            Utility.isAdmin(roleId) ||
            Utility.isSuperAdmin(roleId) ||
            doc.createdByUserId == user?.userId);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () => context.push(AppRoutes.customerPolicyDetail, extra: doc.docId),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(_getFileIcon(doc.fileType), color: const Color(0xFF6366F1), size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  doc.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                    color: AppColors.titleText,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (doc.status == 'active'
                                          ? Colors.green
                                          : (doc.status == 'rejected' || doc.status == 'reject')
                                              ? Colors.red
                                              : Colors.orange)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  doc.status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: doc.status == 'active'
                                        ? Colors.green
                                        : (doc.status == 'rejected' || doc.status == 'reject')
                                            ? Colors.red
                                            : Colors.orange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.kPrimaryLightColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  doc.currentVersion,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.kPrimaryColor,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Prepared on ${DateFormat('dd MMM').format(doc.createdAt)}",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.subText.withValues(alpha: 0.6),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          if (doc.customerId != null && doc.customerId!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            FutureBuilder<String>(
                              future: _getCompanyNameForDoc(doc.customerId),
                              builder: (context, snapshot) {
                                final name = snapshot.data ?? '';
                                if (name.isEmpty) return const SizedBox.shrink();
                                return Row(
                                  children: [
                                    const Icon(Icons.business_rounded, size: 13, color: Colors.blueGrey),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.blueGrey,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.history_rounded, color: AppColors.subText),
                      onPressed: () => _showVersionHistoryDialog(context, doc.docId, doc.title),
                    ),
                    if (canEditOrDelete) ...[
                      IconButton(
                        icon: const Icon(Icons.edit_note_rounded, color: Colors.blue),
                        tooltip: 'Edit Policy',
                        onPressed: () {
                          if (doc.fileType.toLowerCase() == '.xlsx') {
                            context.push(AppRoutes.excelEditor, extra: doc);
                          } else {
                            context.push(AppRoutes.documentEditor, extra: doc);
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                        tooltip: 'Delete Policy',
                        onPressed: () => _confirmDelete(context, doc.docId, doc.filePath),
                      ),
                    ],
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Divider(color: Colors.black12, height: 1),
                ),
                Row(
                  children: [
                    Expanded(child: _auditItemModern("Prepared By", doc.createdBy, Icons.edit_note_rounded)),
                    Expanded(child: _auditItemModern("Reviewed By", doc.reviewedBy ?? "N/A", Icons.rate_review_rounded)),
                  ],
                ),
                if ((doc.status == 'rejected' || doc.status == 'reject') &&
                    doc.rejectionReason != null &&
                    doc.rejectionReason!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.cancel_outlined, color: Colors.red, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "REJECTION REASON",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.red,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                doc.rejectionReason!,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.red.shade900,
                                ),
                              ),
                              if (doc.rejectedBy != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  "By: ${doc.rejectedBy}",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (doc.status == 'draft' && Utility.isCustomer(roleId)) ...[
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _showRejectDialog(context, doc.docId),
                        icon: const Icon(Icons.cancel_outlined, size: 18, color: Colors.red),
                        label: const Text(
                          "REJECT POLICY",
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => _showStatusDialog(context, doc.docId),
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text(
                          "APPROVE POLICY",
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.buttonYellow),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.buttonDarkGreen,
                          foregroundColor: AppColors.buttonYellow,
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showStatusDialog(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        title: const Text(
          'Approve & Activate Policy?',
          style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.titleText),
        ),
        content: const Text(
          'Are you sure you want to mark this policy as ACTIVE? This confirms you have reviewed and accepted the policy content.',
          style: TextStyle(color: AppColors.subText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: AppColors.buttonYellow, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<DocumentCubit>().updateStatus(docId, 'active');
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonDarkGreen,
              foregroundColor: AppColors.buttonYellow,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('APPROVE', style: TextStyle(color: AppColors.buttonYellow, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, String docId) {
    final TextEditingController reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        title: const Text(
          'Reject Policy',
          style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.titleText),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Please enter the reason for rejecting this policy:',
                style: TextStyle(color: AppColors.subText, fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Enter rejection reason...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Rejection reason is required';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: AppColors.buttonYellow, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                context.read<DocumentCubit>().updateStatus(
                      docId,
                      'rejected',
                      rejectionReason: reasonController.text.trim(),
                    );
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonDarkGreen,
              foregroundColor: AppColors.buttonYellow,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('REJECT', style: TextStyle(color: AppColors.buttonYellow, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String docId, String? filePath) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Policy'),
        content: const Text('Are you sure you want to delete this policy document?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: AppColors.buttonYellow, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<DocumentCubit>().deleteDocument(docId, filePath);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonDarkGreen,
              foregroundColor: AppColors.buttonYellow,
            ),
            child: const Text('DELETE', style: TextStyle(color: AppColors.buttonYellow, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _auditItemModern(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.subText.withValues(alpha: 0.4)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: AppColors.subText.withValues(alpha: 0.5),
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.titleText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showVersionHistoryDialog(BuildContext context, String docId, String title) {
    String dialogQuery = '';
    final ScrollController verticalController = ScrollController();
    final historyFuture = DocumentRepository().getVersionHistory(docId);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            constraints: const BoxConstraints(maxWidth: 820),
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Version History',
                  style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.titleText),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.subText.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: FutureBuilder<List<VersionHistoryModel>>(
                future: historyFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 100,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }
                  final hive = getIt<HiveService>();
                  final user = hive.getUser();
                  final customer = hive.getCustomer();
                  final String? roleId = user?.roleId ?? customer?.roleId;
                  final bool isEmployee = Utility.isEmployee(roleId);

                  var history = isEmployee 
                      ? (snapshot.data ?? []).where((v) => v.status == 'active').toList() 
                      : (snapshot.data ?? []);

                  if (history.isEmpty) {
                    return SizedBox(
                      height: 100,
                      child: Center(child: Text(isEmployee ? "No active history found" : "No history found")),
                    );
                  }

                  if (dialogQuery.isNotEmpty) {
                    final q = dialogQuery.toLowerCase().trim();
                    history = history.where((v) {
                      final versionNo = v.versionNo.toLowerCase();
                      final desc = v.changeDescription.toLowerCase();
                      final performedBy = v.performedBy.toLowerCase();
                      final approvedBy = (v.approvedBy ?? '').toLowerCase();
                      final rejectedBy = (v.rejectedBy ?? '').toLowerCase();
                      final reason = (v.rejectionReason ?? '').toLowerCase();
                      return versionNo.contains(q) ||
                          desc.contains(q) ||
                          performedBy.contains(q) ||
                          approvedBy.contains(q) ||
                          rejectedBy.contains(q) ||
                          reason.contains(q);
                    }).toList();
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Dialog Search Field
                      Container(
                        height: 40,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextField(
                          onChanged: (val) => setDialogState(() => dialogQuery = val),
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Search version, author, description...',
                            hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.purple, size: 18),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),

                      if (history.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: Text("No matching history found", style: TextStyle(color: Colors.grey)),
                        )
                      else
                        Flexible(
                          child: Scrollbar(
                            controller: verticalController,
                            thumbVisibility: true,
                            child: SingleChildScrollView(
                              controller: verticalController,
                              scrollDirection: Axis.vertical,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
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
                                    DataColumn(label: Text('Version')),
                                    DataColumn(label: Text('Status')),
                                    DataColumn(label: Text('Change Description')),
                                    DataColumn(label: Text('Performed By & Date')),
                                    DataColumn(label: Text('Approval / Rejection Info')),
                                  ],
                                  rows: history.asMap().entries.map((entry) {
                                    final int index = entry.key;
                                    final VersionHistoryModel v = entry.value;
                                    final isActive = v.status == 'active';
                                    final isRejected = v.status == 'rejected' || v.status == 'reject';
                                    final statusColor = isActive
                                        ? Colors.green
                                        : isRejected
                                            ? Colors.red
                                            : Colors.orange;

                                    return DataRow(
                                      color: index % 2 == 1
                                          ? WidgetStateProperty.all(const Color(0xFFFAFAFA))
                                          : WidgetStateProperty.all(Colors.white),
                                      cells: [
                                        DataCell(Text('${index + 1}')),
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: statusColor.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
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
                                        DataCell(
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                v.performedBy.isEmpty ? '-' : v.performedBy,
                                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                              ),
                                              Text(
                                                DateFormat('dd MMM yyyy, hh:mm a').format(v.performedDate),
                                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                        ),
                                        DataCell(
                                          ConstrainedBox(
                                            constraints: const BoxConstraints(maxWidth: 220),
                                            child: isActive && v.approvedBy != null
                                                ? Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Text(
                                                        "Approved by: ${v.approvedBy}",
                                                        style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      if (v.approvedDate != null)
                                                        Text(
                                                          DateFormat('dd MMM yyyy').format(v.approvedDate!),
                                                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                                                        ),
                                                    ],
                                                  )
                                                : isRejected && (v.rejectionReason != null || v.rejectedBy != null)
                                                    ? Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          Text(
                                                            "Rejected by: ${v.rejectedBy ?? v.performedBy}",
                                                            style: const TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold),
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                          if (v.rejectionReason != null && v.rejectionReason!.isNotEmpty)
                                                            Text(
                                                              "Reason: ${v.rejectionReason}",
                                                              style: TextStyle(fontSize: 11, color: Colors.red.shade900),
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
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Close',
                  style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.buttonYellow),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  IconData _getFileIcon(String type) {
    final t = type.toLowerCase();
    if (t.contains('pdf')) return Icons.picture_as_pdf;
    if (t.contains('doc')) return Icons.description;
    if (t.contains('xls')) return Icons.table_chart;
    if (t.contains('quill')) return Icons.edit_note;
    return Icons.insert_drive_file;
  }
}

class _DotPatternPainter extends CustomPainter {
  final Color dotColor;
  _DotPatternPainter({required this.dotColor});

  @override
  void paint(Canvas canvas, Size size) {
    const double spacing = 30.0;
    final paint = Paint()
      ..color = dotColor
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final List<Offset> points = [];
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        points.add(Offset(x, y));
      }
    }
    canvas.drawPoints(PointMode.points, points, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
