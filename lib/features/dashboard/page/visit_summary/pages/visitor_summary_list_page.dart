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
import 'package:iq_plus/features/auth/model/user_model.dart';
import 'package:iq_plus/features/dashboard/page/visit_summary/cubit/visitor_summary_cubit.dart';
import 'package:iq_plus/features/dashboard/page/visit_summary/cubit/visitor_summary_state.dart';
import 'package:iq_plus/features/dashboard/page/visit_summary/model/visitor_summary_model.dart';
import 'package:iq_plus/features/dashboard/page/visit_summary/pages/widgets/visitor_summary_details_dialog.dart';

class VisitorSummaryListPage extends StatefulWidget {
  const VisitorSummaryListPage({super.key});

  @override
  State<VisitorSummaryListPage> createState() => _VisitorSummaryListPageState();
}

class _VisitorSummaryListPageState extends State<VisitorSummaryListPage> {
  String roleId = '';
  final UserModel? userLoginDetails = getIt<HiveService>().getUser();
  final CustomerModel? customerLoginDetails = getIt<HiveService>().getCustomer();

  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  String selectedCompanyFilter = 'all';
  List<CustomerModel> customerList = [];

  @override
  void initState() {
    super.initState();
    fetchUserRole();
    fetchCustomerList();
    context.read<VisitorSummaryCubit>().loadVisitorSummaries();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void fetchUserRole() {
    roleId = userLoginDetails?.roleId ?? customerLoginDetails?.roleId ?? '';
  }

  Future<void> fetchCustomerList() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('customers').get();
      var customers = snapshot.docs
          .map((doc) => CustomerModel.fromJson(doc.data(), customerId: doc.id))
          .toList();

      // For consultant, filter options to assigned customers only
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

  bool _isCompanyValid(String value) {
    if (value == 'all') return true;
    return customerList.any((c) => c.customerId == value);
  }

  String _getCompanyName(VisitorSummaryModel item) {
    if (item.customerId.isNotEmpty) {
      for (final c in customerList) {
        if (c.customerId == item.customerId) {
          return c.companyName;
        }
      }
    }
    return '';
  }

  List<VisitorSummaryModel> _getFilteredList(List<VisitorSummaryModel> originalList) {
    return originalList.where((item) {
      // 1. Company Filter
      if (selectedCompanyFilter != 'all') {
        final selectedCustomer = customerList.firstWhere(
          (c) => c.customerId == selectedCompanyFilter,
          orElse: () => CustomerModel(
            customerId: '',
            companyName: '',
            email: '',
            phoneNumber: '',
            password: '',
            certificateStandard: '',
            numberOfLocations: '',
            numberOfEmployees: '',
            companyFunction: '',
            legitDocumentUrl: '',
            isProfileApproved: false,
            fcmToken: '',
            roleId: '',
            createdAt: DateTime.now(),
            address: '',
            lowLevelName: '',
            lowLevelEmail: '',
            lowLevelMobile: '',
            mediumLevelName: '',
            mediumLevelEmail: '',
            mediumLevelMobile: '',
            topLevelName: '',
            topLevelEmail: '',
            topLevelMobile: '',
          ),
        );

        final matchesId = item.customerId == selectedCompanyFilter;
        final matchesName = selectedCustomer.companyName.isNotEmpty &&
            item.clientName.toLowerCase() == selectedCustomer.companyName.toLowerCase();

        if (!matchesId && !matchesName) return false;
      }

      // 2. Search Query
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase().trim();
        final clientName = item.clientName.toLowerCase();
        final location = item.location.toLowerCase();
        final purpose = item.purpose.toLowerCase();
        final department = item.department.toLowerCase();
        final officerName = item.officerName.toLowerCase();

        final matches = clientName.contains(q) ||
            location.contains(q) ||
            purpose.contains(q) ||
            department.contains(q) ||
            officerName.contains(q);

        if (!matches) return false;
      }

      return true;
    }).toList();
  }

  String _formatDate(dynamic value) {
    if (value == null) return '-';

    if (value.runtimeType.toString() == 'Timestamp') {
      return DateFormat('dd MMM yyyy').format(value.toDate());
    }

    if (value is DateTime) {
      return DateFormat('dd MMM yyyy').format(value);
    }

    if (value is String) {
      return value;
    }

    return '-';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(title: const Text('Visitor Summary')),
      floatingActionButton: Utility.isCustomer(roleId)
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                context.push(AppRoutes.visitorSummary);
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Visit'),
            ),
      body: BlocBuilder<VisitorSummaryCubit, VisitorSummaryState>(
        builder: (context, state) {
          if (state is VisitorSummaryLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is VisitorSummaryLoaded) {
            final allItems = state.list;
            final filteredItems = _getFilteredList(allItems);

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    children: [
                      /// 🔍 SEARCH BAR
                      TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: "Search by client name, location, purpose...",
                          hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                          prefixIcon: const Icon(Icons.search, color: AppColors.kPrimaryColor),
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
                      if (!Utility.isCustomer(roleId) && customerList.isNotEmpty) ...[
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
                                color: AppColors.kPrimaryColor,
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
                    ],
                  ),
                ),

                /// 📋 LIST VIEW
                Expanded(
                  child: filteredItems.isEmpty
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
                                allItems.isEmpty
                                    ? 'No visitor summaries found'
                                    : 'No matching visitor summaries found',
                                style: const TextStyle(color: Colors.grey, fontSize: 15),
                              ),
                              if (searchQuery.isNotEmpty || selectedCompanyFilter != 'all') ...[
                                const SizedBox(height: 12),
                                TextButton.icon(
                                  icon: const Icon(Icons.refresh),
                                  label: const Text("Clear Filters"),
                                  onPressed: () {
                                    searchController.clear();
                                    setState(() {
                                      searchQuery = '';
                                      selectedCompanyFilter = 'all';
                                    });
                                  },
                                ),
                              ],
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: filteredItems.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (_, index) {
                            final item = filteredItems[index];

                            return InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (_) =>
                                      VisitorSummaryDetailsDialog(model: item),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    /// ─── DATE BADGE ─────────────────────────
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: AppColors.kPrimaryColor
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: Text(
                                          _formatDate(item.visitDate),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.kPrimaryColor,
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 14),

                                    /// ─── DETAILS ───────────────────────────
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          /// Client Name
                                          Text(
                                            item.clientName,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),

                                          /// Company Name (On top of location)
                                          if (_getCompanyName(item).isNotEmpty) ...[
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.business_rounded,
                                                  size: 14,
                                                  color: AppColors.kPrimaryColor,
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    _getCompanyName(item),
                                                    style: const TextStyle(
                                                      color: Colors.black87,
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                          ],

                                          /// Location
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.location_on_outlined,
                                                size: 14,
                                                color: Colors.grey,
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  item.location,
                                                  style: const TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 13,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    /// ─── EDIT & DELETE (For non-customers) ────────────────────────────
                                    if (!Utility.isCustomer(roleId)) ...[
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          color: AppColors.kPrimaryColor,
                                        ),
                                        onPressed: () {
                                          context.push(
                                            AppRoutes.visitorSummary,
                                            extra: {
                                              'id': item.id,
                                              'visitorSummaryModel': item,
                                            },
                                          );
                                        },
                                      ),

                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.red,
                                        ),
                                        onPressed: () {
                                          _showDeleteDialog(context, item.id);
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          }

          if (state is VisitorSummaryError) {
            return Center(
              child: Text(
                state.error,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          return const SizedBox();
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Visitor Summary'),
        content: const Text(
          'Are you sure you want to delete this visitor summary?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<VisitorSummaryCubit>().deleteVisitorSummary(id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
