import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:iq_plus/common/routes/go_route.dart';
import 'package:iq_plus/common/themes/app_const.dart';
import 'package:iq_plus/common/utility/utility.dart';
import 'package:iq_plus/core/local_storage/hive_service.dart';
import 'package:iq_plus/di/service_locator.dart';
import 'package:iq_plus/features/auth/model/customer_model.dart';
import 'package:iq_plus/features/auth/model/user_model.dart';
import 'package:iq_plus/ncr_form/ncr_form_page.dart';
import 'package:iq_plus/ncr_form/ncr_provider.dart';

import 'package:provider/provider.dart';
import 'package:iq_plus/common/themes/app_colors.dart';

class NcrPage extends StatefulWidget {
  const NcrPage({super.key});

  @override
  State<NcrPage> createState() => _NcrPageState();
}

class _NcrPageState extends State<NcrPage> {
  String roleId = '';
  bool isRoleLoaded = false;
  final UserModel? userLoginDetails = getIt<HiveService>().getUser();
  final CustomerModel? customerLoginDetails = getIt<HiveService>().getCustomer();

  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  String selectedStatusFilter = 'all'; // 'all', 'open', 'in_progress', 'closed'
  String selectedCompanyFilter = 'all'; // 'all' or customerId
  List<CustomerModel> customerList = [];

  @override
  void initState() {
    super.initState();
    fetchUserRole();
    fetchCustomerList();
    context.read<NcrProvider>().listenToNcrs();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void fetchUserRole()  {
    roleId = userLoginDetails?.roleId??customerLoginDetails?.roleId??'';
    isRoleLoaded = true;
  }

  Future<void> fetchCustomerList() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('customers').get();
      var customers = snapshot.docs
          .map((doc) => CustomerModel.fromJson(doc.data(), customerId: doc.id))
          .toList();

      // Populate global cache for card rendering
      for (final c in customers) {
        NcrListCard._companyNameCache[c.customerId] = c.companyName;
      }

      // For consultant, filter dropdown options to assigned customers only
      if (Utility.isConsultant(roleId) &&
          (userLoginDetails?.userId ?? '').isNotEmpty) {
        final consultantUserId = userLoginDetails?.userId;
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

  String _getCompanyNameById(String id) {
    if (id.isEmpty) return '';
    for (final c in customerList) {
      if (c.customerId == id) return c.companyName;
    }
    return NcrListCard._companyNameCache[id] ?? '';
  }

  List<Map<String, dynamic>> _getFilteredList(List<Map<String, dynamic>> originalList) {
    return originalList.where((ncr) {
      final status = ncr['status'] ?? AppConst.openNCRStatusKey;
      final customerId = (ncr['customerId'] ?? ncr['companyId'] ?? '').toString();
      final companyName = (ncr['companyName'] ?? ncr['company'] ?? '').toString();

      // 1. Status Filter
      if (selectedStatusFilter != 'all' && status != selectedStatusFilter) {
        return false;
      }

      // 2. Company Filter
      if (selectedCompanyFilter != 'all') {
        final selectedCompName = _getCompanyNameById(selectedCompanyFilter).toLowerCase();
        final matches = customerId == selectedCompanyFilter ||
            (selectedCompName.isNotEmpty &&
                companyName.toLowerCase() == selectedCompName);
        if (!matches) return false;
      }

      // 3. Search Query
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase().trim();
        final process = (ncr['process'] ?? '').toString().toLowerCase();
        final compName = companyName.toLowerCase();
        final cachedCompName = _getCompanyNameById(customerId).toLowerCase();
        final ncrNo = (ncr['ncrNo'] ?? '').toString().toLowerCase();
        final clause = (ncr['clause'] ?? '').toString().toLowerCase();
        final statement = (ncr['statement'] ?? '').toString().toLowerCase();

        final matches = process.contains(q) ||
            compName.contains(q) ||
            cachedCompName.contains(q) ||
            ncrNo.contains(q) ||
            clause.contains(q) ||
            statement.contains(q);

        if (!matches) return false;
      }

      return true;
    }).toList();
  }

  Widget _buildFilterChip({
    required String label,
    required String value,
    required int count,
    required Color color,
  }) {
    final isSelected = selectedStatusFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(
          "$label ($count)",
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.blackTextColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
        selected: isSelected,
        selectedColor: color,
        backgroundColor: AppColors.greyTextFormFiledColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? color : AppColors.greyBorderColor,
          ),
        ),
        onSelected: (bool selected) {
          if (selected) {
            setState(() {
              selectedStatusFilter = value;
            });
          }
        },
      ),
    );
  }

  bool _isCompanyValid(String value) {
    if (value == 'all') return true;
    return customerList.any((c) => c.customerId == value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteTextColor,
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      floatingActionButton: Utility.isCustomer(roleId)?null:Padding(
        padding: const EdgeInsets.only(top: 16),
        child: FloatingActionButton.extended(
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'Add new form',
            style: TextStyle(color: Colors.white),
          ),
          onPressed: () {
            GoRouter.of(
              context,
            ).push(AppRoutes.nCRFormPage); // navigate using GoRouter
          },
        ),
      ),
      appBar: AppBar(
        title: const Text('NCR List'),
        backgroundColor: AppColors.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Consumer<NcrProvider>(
          builder: (context, provider, _) {
            final allNcrs = provider.ncrList;
            final filteredNcrs = _getFilteredList(allNcrs);

            final openCount = allNcrs.where((e) => e['status'] == AppConst.openNCRStatusKey).length;
            final inProgressCount = allNcrs.where((e) => e['status'] == AppConst.inProgressNCRStatusKey).length;
            final closedCount = allNcrs.where((e) => e['status'] == AppConst.closedNCRStatusKey).length;

            return Column(
              children: [
                /// 🔍 SEARCH BAR
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: "Search NCR by Process / Area / Department",
                    hintStyle: TextStyle(fontSize: 13, color: AppColors.greyTextColor),
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    filled: true,
                    fillColor: AppColors.greyTextFormFiledColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {
                      searchQuery = val;
                    });
                  },
                ),
                const SizedBox(height: 10),

                /// 🏢 COMPANY FILTER (For non-customers)
                if (!Utility.isCustomer(roleId) && customerList.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.greyTextFormFiledColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.greyBorderColor),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _isCompanyValid(selectedCompanyFilter)
                            ? selectedCompanyFilter
                            : 'all',
                        isExpanded: true,
                        icon: const Icon(Icons.business_rounded, color: AppColors.primary, size: 20),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.blackTextColor,
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
                  const SizedBox(height: 10),
                ],

                /// 🏷️ STATUS FILTER CHIPS
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: "All",
                        value: "all",
                        count: allNcrs.length,
                        color: AppColors.primary,
                      ),
                      _buildFilterChip(
                        label: "Open",
                        value: AppConst.openNCRStatusKey,
                        count: openCount,
                        color: AppColors.orange,
                      ),
                      _buildFilterChip(
                        label: "In Progress",
                        value: AppConst.inProgressNCRStatusKey,
                        count: inProgressCount,
                        color: AppColors.blue,
                      ),
                      _buildFilterChip(
                        label: "Closed",
                        value: AppConst.closedNCRStatusKey,
                        count: closedCount,
                        color: AppColors.green,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                /// 📋 NCR LIST VIEW
                Expanded(
                  child: filteredNcrs.isEmpty
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
                                allNcrs.isEmpty
                                    ? "No NCRs found"
                                    : "No matching NCRs found",
                                style: TextStyle(
                                  color: AppColors.greyTextColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
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
                          itemCount: filteredNcrs.length,
                          itemBuilder: (context, index) {
                            final ncr = filteredNcrs[index];
                            return NcrListCard(
                              ncr: ncr,
                              roleId: roleId,
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        NCRFormPage(ncrData: ncr, forceEdit: false),
                                  ),
                                );
                                if (mounted) {
                                  setState(() {});
                                }
                              },
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class NcrListCard extends StatelessWidget {
  final Map<String, dynamic> ncr;
  final VoidCallback onTap;
  final String roleId;

  const NcrListCard({
    super.key,
    required this.ncr,
    required this.onTap,
    required this.roleId,
  });

  String get status => ncr['status'] ?? AppConst.openNCRStatusKey;

  static final Map<String, String> _companyNameCache = {};

  Future<String> _getCompanyName(String customerId) async {
    if (customerId.isEmpty) return '';
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

  Widget _buildCompanyWidget() {
    final directName = (ncr['companyName'] ?? ncr['company'] ?? '').toString();
    final customerId = (ncr['customerId'] ?? ncr['companyId'] ?? '').toString();

    if (directName.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 2, bottom: 2),
        child: Row(
          children: [
            const Icon(Icons.business_rounded, size: 14, color: AppColors.greyTextColor),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                directName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.blackTextColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    if (customerId.isEmpty) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<String>(
      future: _getCompanyName(customerId),
      builder: (context, snapshot) {
        final name = snapshot.data ?? '';
        if (name.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 2, bottom: 2),
          child: Row(
            children: [
              const Icon(Icons.business_rounded, size: 14, color: AppColors.greyTextColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.blackTextColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete NCR"),
        content: const Text("Are you sure you want to delete this NCR?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              context.read<NcrProvider>().deleteNcr(ncr['id']);
              Navigator.pop(ctx);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// Status tag widget
  Widget _statusTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Utility.getNCRStatusColor(status), // Orange, Blue, Green
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        Utility.getNCRStatus(status),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final process = ncr['process'] ?? 'N/A';
    final createdAt = ncr['createdAt'] != null
        ? (ncr['createdAt'] as Timestamp).toDate()
        : null;

    return Card(
      color: AppColors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              /// Left status icon
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: Utility.getNCRStatusColor(status).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Utility.getNCRStatusIcons(status),
                    color: Utility.getNCRStatusColor(status),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              /// Middle: process + company + date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      process,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.titleText,
                      ),
                    ),
                    _buildCompanyWidget(),
                    if (createdAt != null)
                      Text(
                        "Created: ${DateFormat('dd MMM yyyy').format(createdAt)}",
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.greyTextColor,
                        ),
                      ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: _statusTag(),
              ),
              if (!Utility.isCustomer(roleId)) ...[
                IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.primary),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            NCRFormPage(ncrData: ncr, forceEdit: true),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _showDeleteDialog(context),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
