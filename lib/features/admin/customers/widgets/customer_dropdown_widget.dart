import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/di/service_locator.dart';
import 'package:iq_plus/features/admin/customers/cubit/customer_list_cubit.dart';
import 'package:iq_plus/features/admin/customers/cubit/customer_list_state.dart';
import 'package:iq_plus/features/auth/model/customer_model.dart';

class CustomerDropdownWidget extends StatelessWidget {
  final CustomerModel? selectedCustomer;
  final ValueChanged<CustomerModel?> onChanged;
  final String hint;
  final bool? readOnly;
  final String? consultantId;

  const CustomerDropdownWidget({
    super.key,
    this.selectedCustomer,
    this.readOnly,
    required this.onChanged,
    this.hint = 'Select company',
    this.consultantId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CustomerListCubit>()..fetchApprovedCustomers(consultantId),
      child: BlocBuilder<CustomerListCubit, CustomerListState>(
        builder: (context, state) {
          if (state is CustomerListLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CustomerListLoaded) {
            CustomerModel? matchedCustomer;
            if (selectedCustomer != null && selectedCustomer!.customerId.isNotEmpty) {
              final matches = state.customers.where(
                (c) => c.customerId == selectedCustomer!.customerId,
              );
              if (matches.length == 1) {
                matchedCustomer = matches.first;
              }
            }

            return DropdownButtonFormField<CustomerModel>(
              // ignore: deprecated_member_use
              value: matchedCustomer,
              isExpanded: true,
              hint: Text(hint),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: state.customers.map((customer) {
                return DropdownMenuItem<CustomerModel>(
                  value: customer,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.primary.withValues(alpha:0.15),
                        child: Text(
                          customer.companyName.isNotEmpty
                              ? customer.companyName[0].toUpperCase()
                              : 'C',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          customer.companyName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (readOnly ?? false) ? null : onChanged,
            );
          }

          if (state is CustomerListError) {
            return Text(
              state.message,
              style: const TextStyle(color: Colors.red),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
