import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iq_plus/common/routes/go_route.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/common/themes/app_extension.dart';
import 'package:iq_plus/common/themes/app_theme_data.dart';
import 'package:iq_plus/common/themes/app_ui_helper.dart';
import 'package:iq_plus/di/service_locator.dart';
import 'package:iq_plus/features/admin/consultants/cubit/consultant_cubit.dart';
import 'package:iq_plus/features/admin/customers/cubit/customer_list_cubit.dart';
import 'package:iq_plus/features/admin/customers/cubit/customer_list_state.dart';
import 'package:iq_plus/features/admin/customers/pages/customer_detail_page.dart';
import 'package:iq_plus/features/auth/model/customer_model.dart';
import 'package:iq_plus/features/auth/repository/auth_repository.dart';
import 'package:go_router/go_router.dart';

class CustomerListPage extends StatelessWidget {
  const CustomerListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CustomerListCubit>()..fetchCustomers(),
      child: Scaffold(
        backgroundColor: AppColors.whiteColor,
        appBar: AppBar(
          title: const Text('Approved Customers'),
          backgroundColor: AppColors.primary,
        ),
        body: BlocBuilder<CustomerListCubit, CustomerListState>(
          builder: (context, state) {
            if (state is CustomerListLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is CustomerListLoaded) {
              // Filter only approved customers
              final approvedCustomers = state.customers
                  .where((customer) => customer.isProfileApproved)
                  .toList();

              if (approvedCustomers.isEmpty) {
                return const Center(child: Text('No approved customers found'));
              }

              return ListView.separated(
                padding: const EdgeInsets.all(appHorizontalPadding15),
                itemCount: approvedCustomers.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 20), // vertical spacing
                itemBuilder: (context, index) {
                  return _CustomerCard(
                    customer: approvedCustomers[index],
                    onTap: () {
                      GoRouter.of(context).push(
                        AppRoutes.customerDetail,
                        extra: approvedCustomers[index],
                      );
                    },
                  );
                },
              );
            }

            return const Center(child: Text('No customers found'));
          },
        ),
      ),
    );
  }
}

/// --------------------------------------------
/// CUSTOMER CARD
/// --------------------------------------------
class _CustomerCard extends StatelessWidget {
  final CustomerModel customer;
  final VoidCallback onTap;

  const _CustomerCard({required this.customer, required this.onTap});

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
                backgroundColor: AppColors.primary.withOpacity(0.15),
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
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      customer.email,
                      style: AppThemeData.textFieldTextStyle.copyWith(
                        color: AppColors.greyLoginTextColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Employees: ${customer.numberOfEmployees}',
                      style: AppThemeData.textFieldTextStyle.copyWith(
                        fontSize: 13,
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
                decoration: BoxDecoration(
                  color: customer.isProfileApproved
                      ? Colors.green.withOpacity(0.15)
                      : Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  customer.isProfileApproved ? 'Approved' : 'Pending',
                  style: TextStyle(
                    color: customer.isProfileApproved
                        ? Colors.green
                        : Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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
