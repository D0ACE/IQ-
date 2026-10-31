import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iq_plus/common/routes/go_route.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/common/widgets/common_app_bar.dart';
import 'package:iq_plus/features/superadmin/cubit/document_cubit.dart';
import 'package:iq_plus/features/superadmin/cubit/document_state.dart';
import 'package:iq_plus/features/admin/customers/cubit/customer_list_cubit.dart';
import 'package:iq_plus/features/admin/customers/cubit/customer_list_state.dart';
import 'package:iq_plus/features/auth/model/customer_model.dart';
import 'package:iq_plus/common/utility/utility.dart';
import 'package:iq_plus/core/local_storage/hive_service.dart';
import 'package:iq_plus/di/service_locator.dart';
import 'package:iq_plus/features/superadmin/models/version_history_model.dart';
import 'package:iq_plus/features/superadmin/repository/document_repository.dart';
import 'package:intl/intl.dart';

class DocumentListPage extends StatefulWidget {
  const DocumentListPage({super.key});

  @override
  State<DocumentListPage> createState() => _DocumentListPageState();
}

class _DocumentListPageState extends State<DocumentListPage> {
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
      final isConsultant = Utility.isConsultant(user?.roleId);
      final String? consultantIdFilter = isConsultant ? user?.userId : null;
      context.read<DocumentCubit>().loadDocuments(
        userId: user?.userId,
        isConsultant: isConsultant,
      );
      context.read<CustomerListCubit>().fetchApprovedCustomers(consultantIdFilter);
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

  List<dynamic> _getFilteredDocuments(
    List<dynamic> docs,
    List<CustomerModel> customers,
    bool isConsultant,
    String? userId,
  ) {
    Set<String> assignedCustomerIds = {};
    if (isConsultant && userId != null) {
      assignedCustomerIds = customers
          .where((c) => c.consultantId == userId)
          .map((c) => c.customerId)
          .toSet();
    }

    return docs.where((doc) {
      // 🚀 Consultant strict assigned customers constraint
      if (isConsultant && userId != null) {
        final bool isAssignedDoc = doc.customerId != null && assignedCustomerIds.contains(doc.customerId);
        final bool isCreatedByConsultant = doc.createdByUserId == userId;
        if (!isAssignedDoc && !isCreatedByConsultant) {
          return false;
        }
      }

      // 1. Company Filter
      if (_selectedCompanyFilter != 'all') {
        if (doc.customerId != _selectedCompanyFilter) {
          return false;
        }
      }

      // 2. Search Query
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase().trim();
        final title = (doc.title ?? '').toString().toLowerCase();
        final createdBy = (doc.createdBy ?? '').toString().toLowerCase();
        final reviewedBy = (doc.reviewedBy ?? '').toString().toLowerCase();
        final version = (doc.currentVersion ?? '').toString().toLowerCase();
        final fileType = (doc.fileType ?? '').toString().toLowerCase();

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
      final String status = (doc.status ?? '').toString().toLowerCase();
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
      appBar: const CommonAppBar(title: 'Policies & Procedures'),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOptions(context),
        backgroundColor: AppColors.buttonDarkGreen,
        child: const Icon(Icons.add, color: AppColors.buttonYellow),
      ),
      body: BlocBuilder<DocumentCubit, DocumentState>(
        builder: (context, state) {
          if (state is DocumentLoading || state is GlobalVersionHistoryLoaded || state is DocumentInitial || state is DocumentOperationSuccess) {
            if (state is GlobalVersionHistoryLoaded || state is DocumentInitial) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                final user = getIt<HiveService>().getUser();
                final isConsultant = Utility.isConsultant(user?.roleId);
                final String? consultantIdFilter = isConsultant ? user?.userId : null;
                context.read<DocumentCubit>().loadDocuments(
                  userId: consultantIdFilter,
                  isConsultant: isConsultant,
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

            final allDocs = state.documents;
            if (allDocs.isEmpty) {
              return const Center(child: Text('No documents found'));
            }

            return BlocBuilder<CustomerListCubit, CustomerListState>(
              builder: (context, customerState) {
                List<CustomerModel> customers = [];
                final bool isCustomerLoading = customerState is CustomerListLoading;
                if (customerState is CustomerListLoaded) {
                  customers = customerState.customers;
                }

                // 🚀 Role-based customer dropdown filtering:
                // - Hide dropdown for Customers & Employees
                // - Show ONLY assigned customers for Consultants
                // - Show all customers for Admins / SuperAdmins
                final bool showCompanyFilter = !isCustomer && !isEmployee;
                List<CustomerModel> availableCustomers = customers;
                if (isConsultant) {
                  availableCustomers = customers
                      .where((c) => c.consultantId == user?.userId)
                      .toList();
                }

                // Sanitize selected company filter if no longer valid
                if (_selectedCompanyFilter != 'all') {
                  final bool isValid = availableCustomers.any((c) => c.customerId == _selectedCompanyFilter);
                  if (!isValid) {
                    _selectedCompanyFilter = 'all';
                  }
                }

                final companyFilteredDocs = _selectedCompanyFilter == 'all'
                    ? allDocs
                    : allDocs.where((d) => d.customerId == _selectedCompanyFilter).toList();

                final filteredDocs = _getFilteredDocuments(
                  companyFilteredDocs,
                  customers,
                  isConsultant,
                  user?.userId,
                );

                final int totalCount = companyFilteredDocs.length;
                final int activeCount = companyFilteredDocs.where((d) => d.status == 'active').length;
                final int draftCount = companyFilteredDocs.where((d) => d.status == 'draft').length;
                final int rejectedCount = companyFilteredDocs.where((d) => d.status == 'rejected' || d.status == 'reject').length;

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

                          // 🏢 Separate Customer Filter Loading / Selector
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
                                        child: Text('All Assigned Companies'),
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

                    // 📋 Document List View / Empty Filter State
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
                                    "Try adjusting your search query or status filter",
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
                              padding: const EdgeInsets.all(16),
                              itemCount: filteredDocs.length,
                              itemBuilder: (context, index) {
                                final doc = filteredDocs[index];
                                final isRichDoc = doc.content != null;
                                final isDocx = doc.fileName.toLowerCase().endsWith('.docx');

                                final hive = getIt<HiveService>();
                                final user = hive.getUser();
                                final customer = hive.getCustomer();
                                final String? currentUserId = user?.userId ?? customer?.customerId;
                                final String? roleId = user?.roleId ?? customer?.roleId;

                                final bool isCreator = doc.createdByUserId == currentUserId;
                                final bool isSystemAdmin = Utility.isSuperAdmin(roleId) || Utility.isAdmin(roleId);
                                final bool isConsultantUser = Utility.isConsultant(roleId);
                                final bool isCustomerUser = Utility.isCustomer(roleId);

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: Column(
                                    children: [
                                      ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: AppColors.kPrimaryLightColor,
                                          child: Text(
                                            doc.id.toString(),
                                            style: const TextStyle(fontSize: 10, color: AppColors.purple, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        title: Text(doc.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Version: ${doc.currentVersion}",
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                            if (doc.customerId != null)
                                              BlocBuilder<CustomerListCubit, CustomerListState>(
                                                builder: (context, customerState) {
                                                  String customerName = doc.customerId!;
                                                  if (customerState is CustomerListLoaded) {
                                                    try {
                                                      customerName = customerState.customers
                                                          .firstWhere((c) => c.customerId == doc.customerId)
                                                          .companyName;
                                                    } catch (_) {}
                                                  }
                                                  return Text(
                                                    "Customer: $customerName",
                                                    style: const TextStyle(fontSize: 10, color: Colors.blueGrey, fontWeight: FontWeight.w600),
                                                  );
                                                },
                                              ),
                                          ],
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (isSystemAdmin || isConsultantUser || isCreator || isCustomerUser)
                                              IconButton(
                                                tooltip: 'View Details',
                                                icon: const Icon(Icons.visibility, color: Colors.blueAccent),
                                                onPressed: () => context.push(AppRoutes.customerPolicyDetail, extra: doc),
                                              ),
                                            if (isSystemAdmin || isConsultantUser || isCreator)
                                              IconButton(
                                                tooltip: (isRichDoc || isDocx) ? 'Edit / Read Content' : 'Edit (Rich Text)',
                                                icon: const Icon(
                                                  Icons.edit_note, 
                                                  color: Colors.blue
                                                ),
                                                onPressed: () {
                                                  if (doc.fileType.toLowerCase() == '.xlsx'){
                                                    context.push(AppRoutes.excelEditor, extra: doc);
                                                  } else {
                                                    context.push(AppRoutes.documentEditor, extra: doc);
                                                  }
                                                },
                                              ),
                                            if (isCustomerUser && doc.customerId == currentUserId)
                                              IconButton(
                                                tooltip: 'Status',
                                                icon: Icon(
                                                  doc.status == 'active' ? Icons.task_alt : Icons.pending,
                                                  color: doc.status == 'active' ? Colors.green : Colors.orange,
                                                ),
                                                onPressed: () {
                                                  if (doc.status == 'active') {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(content: Text("This policy is already Active.")),
                                                    );
                                                  } else {
                                                    _showStatusDialog(context, doc.docId, doc.status);
                                                  }
                                                },
                                              ),
                                            IconButton(
                                              tooltip: 'Version History',
                                              icon: const Icon(Icons.history, color: Colors.blueGrey),
                                              onPressed: () => _showVersionHistoryDialog(context, doc.docId, doc.title),
                                            ),
                                            if (isSystemAdmin || isConsultantUser || isCreator)
                                              IconButton(
                                                tooltip: 'Delete',
                                                icon: const Icon(Icons.delete, color: Colors.red),
                                                onPressed: () => _confirmDelete(context, doc.docId, doc.filePath),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const Divider(height: 1),
                                      Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(child: _auditItem("Prepared By", doc.createdBy)),
                                                Expanded(child: _auditItem("Prepared Date", DateFormat('dd MMM yyyy').format(doc.createdAt))),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Expanded(child: _auditItem("Reviewed By", doc.reviewedBy ?? "N/A")),
                                                Expanded(child: _auditItem("Reviewed Date", doc.reviewedDate != null ? DateFormat('dd MMM yyyy').format(doc.reviewedDate!) : "N/A")),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Align(
                                                    alignment: Alignment.centerLeft,
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: (doc.status == 'active'
                                                                ? Colors.green
                                                                : (doc.status == 'rejected' || doc.status == 'reject')
                                                                    ? Colors.red
                                                                    : Colors.orange)
                                                            .withValues(alpha: 0.1),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: Text(
                                                        doc.status.toUpperCase(),
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.bold,
                                                          color: doc.status == 'active'
                                                              ? Colors.green
                                                              : (doc.status == 'rejected' || doc.status == 'reject')
                                                                  ? Colors.red
                                                                  : Colors.orange,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const Spacer(),
                                              ],
                                            ),
                                            if ((doc.status == 'rejected' || doc.status == 'reject') &&
                                                doc.rejectionReason != null &&
                                                doc.rejectionReason!.isNotEmpty) ...[
                                              const SizedBox(height: 8),
                                              Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  color: Colors.red.withValues(alpha: 0.08),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        const Icon(Icons.cancel_outlined, color: Colors.red, size: 16),
                                                        const SizedBox(width: 6),
                                                        Expanded(
                                                          child: Text(
                                                            "Rejection Reason: ${doc.rejectionReason}",
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              fontWeight: FontWeight.bold,
                                                              color: Colors.red.shade900,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    if (doc.rejectedBy != null)
                                                      Padding(
                                                        padding: const EdgeInsets.only(top: 2, left: 22),
                                                        child: Text(
                                                          "Rejected by: ${doc.rejectedBy}",
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            fontStyle: FontStyle.italic,
                                                            color: Colors.red.shade700,
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
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

  Widget _auditItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Manage Policies & Procedures", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.edit_note, color: Colors.white)),
              title: const Text("Create Policy"),
              subtitle: const Text("Write your own policy from scratch"),
              onTap: () {
                Navigator.pop(ctx);
                context.push(AppRoutes.documentEditor);
              },
            ),
            const Divider(),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.upload_file, color: Colors.white)),
              title: const Text("Upload Policy"),
              subtitle: const Text("Upload existing PDF, Docx, or Excel files"),
              onTap: () {
                Navigator.pop(ctx);
                context.push(AppRoutes.documentAddEdit);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusDialog(BuildContext context, String docId, String currentStatus) {
    if (currentStatus == 'active') return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Policy Status'),
        content: const Text('Would you like to approve & activate this policy, or reject it with a reason?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL', style: TextStyle(color: AppColors.buttonYellow, fontWeight: FontWeight.bold))),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showRejectDialog(context, docId);
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.neutralBorder),
              backgroundColor: AppColors.buttonDarkGreen,
              foregroundColor: AppColors.buttonYellow,
            ),
            child: const Text('Reject Policy', style: TextStyle(color: AppColors.buttonYellow, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<DocumentCubit>().updateStatus(docId, 'active');
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.buttonDarkGreen, foregroundColor: AppColors.buttonYellow),
            child: const Text('Approve Policy', style: TextStyle(color: AppColors.buttonYellow, fontWeight: FontWeight.bold)),
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
        title: const Text('Reject Policy'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Please enter the reason for rejecting this policy:'),
              const SizedBox(height: 12),
              TextFormField(
                controller: reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Enter rejection reason...',
                  border: OutlineInputBorder(),
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
            child: const Text('Cancel'),
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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.buttonDarkGreen, foregroundColor: AppColors.buttonYellow),
            child: const Text('Reject', style: TextStyle(color: AppColors.buttonYellow, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
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
                  var history = snapshot.data ?? [];
                  if (history.isEmpty) {
                    return const SizedBox(
                      height: 100,
                      child: Center(child: Text("No history found")),
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
                child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.buttonYellow)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, String docId, String? filePath) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Document'),
        content: const Text('Are you sure you want to delete this document?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL', style: TextStyle(color: AppColors.buttonYellow, fontWeight: FontWeight.bold))),
          TextButton(
            onPressed: () {
              context.read<DocumentCubit>().deleteDocument(docId, filePath);
              Navigator.pop(ctx);
            },
            child: const Text('DELETE', style: TextStyle(color: AppColors.buttonYellow, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
