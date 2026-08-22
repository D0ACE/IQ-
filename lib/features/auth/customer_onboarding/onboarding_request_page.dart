import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/common/themes/app_ui_helper.dart';
import 'package:iq_plus/features/auth/cubit/customer/customer_cubit.dart';
import 'package:iq_plus/features/auth/cubit/customer/state/customer_state.dart';

class OnboardingRequestPage extends StatefulWidget {
  const OnboardingRequestPage({super.key});

  @override
  State<OnboardingRequestPage> createState() => _OnboardingRequestPageState();
}

class _OnboardingRequestPageState extends State<OnboardingRequestPage> {
  @override
  void initState() {
    super.initState();
    // Fetch pending customers after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerCubit>().fetchPendingCustomers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text(
          "Onboarding Requests",
          style: TextStyle(
            color: AppColors.titleText,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.whiteColor,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.titleText),
      ),
      body: BlocBuilder<CustomerCubit, CustomerState>(
        builder: (context, state) {
          if (state is CustomerLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CustomerListLoaded && state.customers.isNotEmpty) {
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.customers.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, index) {
                final customer = state.customers[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(appHorizontalPadding12),
                  ),
                  elevation: 4,
                  shadowColor: AppColors.greyTextColor.withValues(alpha:0.2),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    title: Text(
                      customer.companyName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.titleText,
                      ),
                    ),
                    subtitle: Text(
                      customer.email,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.grey80TextColor,
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: AppColors.mainGradient,
                        borderRadius:
                            BorderRadius.circular(appHorizontalPadding8),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: AppColors.whiteColor,
                      ),
                    ),
                    onTap: () async {
                      await GoRouter.of(context).push(
                        '/customer-onboarding',
                        extra: customer,
                      );
                      if (context.mounted) {
                        context.read<CustomerCubit>().fetchPendingCustomers();
                      }
                    },

                  ),
                );
              },
            );
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.hourglass_empty,
                  size: 60,
                  color: AppColors.grey40TextColor,
                ),
                const SizedBox(height: 16),
                const Text(
                  "No pending requests",
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.grey70TextColor,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
