import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iq_plus/common/routes/go_route.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/common/themes/app_theme_data.dart';
import 'package:iq_plus/common/themes/app_ui_helper.dart';
import 'package:iq_plus/core/local_storage/hive_service.dart';
import 'package:iq_plus/di/service_locator.dart';
import 'package:iq_plus/features/admin/customers/cubit/customer_list_cubit.dart';
import 'package:iq_plus/features/admin/customers/cubit/customer_list_state.dart';
import 'package:iq_plus/features/admin/customers/widgets/assign_next_visit_dialog.dart';
import 'package:iq_plus/features/auth/model/customer_model.dart';
import 'package:go_router/go_router.dart';

class AssignCustomersPage extends StatefulWidget {
  final String consultantId;
  const AssignCustomersPage({super.key, required this.consultantId});

  @override
  State<AssignCustomersPage> createState() => _AssignCustomersPageState();
}

class _AssignCustomersPageState extends State<AssignCustomersPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: AppBar(
        title: const Text('Assigned Customers'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 🔍 Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search assigned customers...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () {
                            _searchController.clear();
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

          Expanded(
            child: BlocBuilder<CustomerListCubit, CustomerListState>(
              builder: (c, state) {
                if (state is CustomerListLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is CustomerListLoaded) {
                  // Filter only approved customers with valid data
                  var assignedCustomers = state.customers
                      .where((customer) => customer.isProfileApproved && customer.companyName.trim().isNotEmpty)
                      .toList();

                  if (_searchQuery.isNotEmpty) {
                    final q = _searchQuery.toLowerCase().trim();
                    assignedCustomers = assignedCustomers.where((customer) {
                      final matchName = customer.companyName.toLowerCase().contains(q);
                      final matchEmail = customer.email.toLowerCase().contains(q);
                      final matchVisit = (customer.nextVisitDate ?? '').toLowerCase().contains(q);
                      final matchPhone = customer.phoneNumber.toLowerCase().contains(q);
                      return matchName || matchEmail || matchVisit || matchPhone;
                    }).toList();
                  }

                  if (assignedCustomers.isEmpty) {
                    return Center(
                      child: Text(
                        _searchQuery.isNotEmpty
                            ? 'No assigned customers match your search'
                            : 'No customers assigned',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(appHorizontalPadding15),
                    itemCount: assignedCustomers.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 20),
                    itemBuilder: (cc, index) {
                      return _CustomerCard(
                        context: context,
                        consultantId: widget.consultantId,
                        customer: assignedCustomers[index],
                        onTap: () {
                          GoRouter.of(context).push(
                            AppRoutes.customerDetail,
                            extra: assignedCustomers[index],
                          );
                        },
                      );
                    },
                  );
                }

                return const Center(child: Text('No customers assigned'));
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// --------------------------------------------
/// CUSTOMER CARD
/// --------------------------------------------
class _CustomerCard extends StatelessWidget {
  final CustomerModel customer;
  final String consultantId;
  final VoidCallback onTap;
  final BuildContext context;

  const _CustomerCard({
    required this.customer,
    required this.consultantId,
    required this.onTap,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(appHorizontalPadding15),
          child: Row(
            children: [
              /// Avatar
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                child: Text(
                  customer.companyName.isNotEmpty
                      ? customer.companyName[0].toUpperCase()
                      : 'C',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),

              const SizedBox(width: 14),

              /// Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.companyName,
                      style: AppThemeData.textFieldTextStyle.copyWith(
                        fontSize: 16,
                        color: AppColors.blackColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      customer.email,
                      style: AppThemeData.textFieldTextStyle.copyWith(
                        color: AppColors.grey80TextColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Next Visit Date: ${customer.nextVisitDate ?? "N/A"}',
                      style: AppThemeData.textFieldTextStyle.copyWith(
                        fontSize: 13,
                        color: AppColors.grey70TextColor,
                      ),
                    ),
                  ],
                ),
              ),

              /// Status Chip
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                child: TextButton(
                  onPressed: () async {
                    final String? nextVisitDate = await showDialog<String>(
                      context: context,
                      builder: (_) => AssignNextVisitDialog(customer: customer),
                    );

                    if (nextVisitDate != null) {
                      if (!context.mounted) return;
                      context.read<CustomerListCubit>().updateCustomerNextVisitDate(
                            customer: customer,
                            consultant: getIt<HiveService>().getUser(),
                            nextVisitDate: nextVisitDate,
                          );
                    }
                  },
                  style: TextButton.styleFrom(
                    side: const BorderSide(color: AppColors.kPrimaryColor, width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'ADD/EDIT NEXT VISIT DATE',
                    style: TextStyle(
                      color: AppColors.buttonYellow,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
