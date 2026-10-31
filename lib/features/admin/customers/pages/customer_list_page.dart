import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iq_plus/common/routes/go_route.dart';
import 'package:iq_plus/common/utility/app_validation.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/features/admin/customers/cubit/customer_list_cubit.dart';
import 'package:iq_plus/features/admin/customers/cubit/customer_list_state.dart';
import 'package:iq_plus/features/auth/model/customer_model.dart';
import 'package:go_router/go_router.dart';
import 'package:iq_plus/features/admin/customers/widgets/customer_add_edit_dialog.dart';

class CustomerListPage extends StatefulWidget {
  const CustomerListPage({super.key});

  @override
  State<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends State<CustomerListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CustomerModel> _getFilteredCustomers(List<CustomerModel> customers) {
    // 🚫 Filter out customers without valid data / company name
    final validCustomers = customers.where((c) => c.companyName.trim().isNotEmpty).toList();
    if (_searchQuery.isEmpty) return validCustomers;
    final q = _searchQuery.toLowerCase().trim();
    return validCustomers.where((customer) {
      final matchName = customer.companyName.toLowerCase().contains(q);
      final matchEmail = customer.email.toLowerCase().contains(q);
      final matchPhone = customer.phoneNumber.toLowerCase().contains(q);
      final matchAddress = customer.address.toLowerCase().contains(q);
      final matchStandard = customer.certificateStandard.toLowerCase().contains(q);
      final matchFunction = customer.companyFunction.toLowerCase().contains(q);
      final matchTopName = customer.topLevelName.toLowerCase().contains(q);
      final matchMediumName = customer.mediumLevelName.toLowerCase().contains(q);
      final matchLowName = customer.lowLevelName.toLowerCase().contains(q);

      return matchName ||
          matchEmail ||
          matchPhone ||
          matchAddress ||
          matchStandard ||
          matchFunction ||
          matchTopName ||
          matchMediumName ||
          matchLowName;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.titleText,
        centerTitle: false,
        title: const Text(
          'Customer Management',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -0.5),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(context),
        backgroundColor: AppColors.buttonDarkGreen,
        icon: const Icon(Icons.business_center_rounded, color: AppColors.buttonYellow),
        label: const Text("Add Customer", style: TextStyle(color: AppColors.buttonYellow, fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          // 🎨 Background Pattern
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _DotPatternPainter(
                  dotColor: AppColors.primary.withValues(alpha: 0.05),
                ),
              ),
            ),
          ),

          BlocListener<CustomerListCubit, CustomerListState>(
            listener: (context, state) {
              if (state is CustomerListOperationSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message)),
                );
              }
              if (state is CustomerListError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message), backgroundColor: Colors.red),
                );
              }
            },
            child: BlocBuilder<CustomerListCubit, CustomerListState>(
              builder: (context, state) {
                if (state is CustomerListLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is CustomerListLoaded || state is CustomerListOperationSuccess) {
                  final allCustomers = state is CustomerListLoaded ? state.customers : <CustomerModel>[];

                  if (allCustomers.isEmpty && state is CustomerListOperationSuccess) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final filteredCustomers = _getFilteredCustomers(allCustomers);

                  return Column(
                    children: [
                      // 🔍 Search Bar Section
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
                              hintText: 'Search company, email, phone, standard...',
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

                      // 📊 Active Search Indicator Bar
                      if (_searchQuery.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          color: AppColors.primary.withValues(alpha: 0.05),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Showing ${filteredCustomers.length} of ${allCustomers.length} customers",
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.titleText,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                                child: const Row(
                                  children: [
                                    Icon(Icons.close_rounded, size: 14, color: AppColors.primary),
                                    SizedBox(width: 4),
                                    Text(
                                      "Clear search",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      // 📋 Customer List / Empty State
                      Expanded(
                        child: filteredCustomers.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _searchQuery.isNotEmpty
                                          ? Icons.search_off_rounded
                                          : Icons.business_rounded,
                                      size: 64,
                                      color: Colors.grey.shade300,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _searchQuery.isNotEmpty
                                          ? "No matching customers found"
                                          : "No customers found",
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (_searchQuery.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        "Try searching with a different term",
                                        style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() {
                                            _searchQuery = '';
                                          });
                                        },
                                        icon: const Icon(Icons.clear_rounded, size: 18),
                                        label: const Text("CLEAR SEARCH"),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.buttonDarkGreen,
                                          foregroundColor: AppColors.buttonYellow,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                                physics: const BouncingScrollPhysics(),
                                itemCount: filteredCustomers.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: _CustomerCard(
                                      customer: filteredCustomers[index],
                                      onTap: () async {
                                        await GoRouter.of(context).push(
                                          AppRoutes.customerDetail,
                                          extra: filteredCustomers[index],
                                        );
                                        if (context.mounted) {
                                          context.read<CustomerListCubit>().fetchCustomers();
                                        }
                                      },
                                      onEdit: () => _showAddEditDialog(context, customer: filteredCustomers[index]),
                                      onDelete: () => _showDeleteConfirm(context, filteredCustomers[index]),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                }

                if (state is CustomerListError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 64, color: Colors.redAccent),
                        const SizedBox(height: 16),
                        Text(
                          "Failed to load customers",
                          style: TextStyle(color: Colors.grey.shade800, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            state.message,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => context.read<CustomerListCubit>().fetchCustomers(),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text("TRY AGAIN"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.buttonDarkGreen,
                            foregroundColor: AppColors.buttonYellow,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddEditDialog(BuildContext context, {CustomerModel? customer}) {
    showDialog(
      context: context,
      builder: (ctx) => BlocProvider.value(
        value: context.read<CustomerListCubit>(),
        child: CustomerAddEditDialog(customer: customer),
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, CustomerModel customer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text(
          "Delete Customer",
          style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.titleText),
        ),
        content: Text(
          "Are you sure you want to remove ${customer.companyName}?\nAll associated data will be permanently deleted.",
          style: TextStyle(color: Colors.grey.shade600, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "CANCEL",
              style: TextStyle(color: AppColors.buttonYellow,
 fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonDarkGreen,
              foregroundColor: AppColors.buttonYellow,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              context.read<CustomerListCubit>().deleteCustomer(customer.customerId);
              Navigator.pop(ctx);
            },
            child: const Text("DELETE ACCOUNT", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final CustomerModel customer;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CustomerCard({
    required this.customer,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // 🏢 Avatar
                  Container(
                    height: 60,
                    width: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.1),
                          AppColors.primary.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      customer.companyName.isNotEmpty ? customer.companyName[0].toUpperCase() : 'C',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),

                  // 📝 Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.companyName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                            color: AppColors.titleText,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.alternate_email_rounded, size: 14, color: Colors.grey.shade400),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                customer.email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.phone_rounded, size: 14, color: Colors.grey.shade400),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                AppValidation.formatPhoneForDisplay(customer.phoneNumber),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.people_outline_rounded, size: 14, color: Colors.grey.shade400),
                            const SizedBox(width: 6),
                            Text(
                              'Workforce: ${customer.numberOfEmployees}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ⚡ Actions
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (customer.isProfileApproved ? Colors.green : Colors.orange).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          customer.isProfileApproved ? 'APPROVED' : 'PENDING',
                          style: TextStyle(
                            color: customer.isProfileApproved ? Colors.green : Colors.orange,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_note_rounded, color: Colors.blue, size: 24),
                            onPressed: onEdit,
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(8),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
                            onPressed: onDelete,
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(8),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
