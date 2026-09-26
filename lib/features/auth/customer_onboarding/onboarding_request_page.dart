import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/common/themes/app_ui_helper.dart';
import 'package:iq_plus/features/auth/cubit/customer/customer_cubit.dart';
import 'package:iq_plus/features/auth/cubit/customer/state/customer_state.dart';
import 'package:iq_plus/features/auth/model/customer_model.dart';

class OnboardingRequestPage extends StatefulWidget {
  const OnboardingRequestPage({super.key});

  @override
  State<OnboardingRequestPage> createState() => _OnboardingRequestPageState();
}

class _OnboardingRequestPageState extends State<OnboardingRequestPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Fetch pending customers after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CustomerCubit>().fetchPendingCustomers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CustomerModel> _getFilteredCustomers(List<CustomerModel> customers) {
    if (_searchQuery.isEmpty) return customers;
    final q = _searchQuery.toLowerCase().trim();
    return customers.where((customer) {
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

          if (state is CustomerListLoaded) {
            final allCustomers = state.customers;

            if (allCustomers.isEmpty) {
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
            }

            final filteredCustomers = _getFilteredCustomers(allCustomers);

            return Column(
              children: [
                // 🔍 Search Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search pending requests...',
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

                // 📊 Search Results Count Indicator
                if (_searchQuery.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    color: AppColors.primary.withValues(alpha: 0.05),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Showing ${filteredCustomers.length} of ${allCustomers.length} requests",
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

                // 📋 Request List / Empty State
                Expanded(
                  child: filteredCustomers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 60,
                                color: AppColors.grey40TextColor,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "No matching pending requests found",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.grey70TextColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Try searching with a different keyword",
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
                                label: const Text("Clear Search"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: filteredCustomers.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (_, index) {
                            final customer = filteredCustomers[index];
                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(appHorizontalPadding12),
                              ),
                              elevation: 4,
                              shadowColor: AppColors.greyTextColor.withValues(alpha: 0.2),
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
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.alternate_email_rounded, size: 14, color: Colors.grey.shade400),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            customer.email,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: AppColors.grey80TextColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (customer.phoneNumber.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Icon(Icons.phone_rounded, size: 14, color: Colors.grey.shade400),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              customer.phoneNumber,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
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
                        ),
                ),
              ],
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
