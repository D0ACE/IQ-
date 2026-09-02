import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iq_plus/common/routes/go_route.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/common/utility/utility.dart';
import 'package:iq_plus/core/local_storage/hive_service.dart';
import 'package:iq_plus/di/service_locator.dart';
import 'package:iq_plus/features/admin/customers/cubit/customer_list_cubit.dart';
import 'package:iq_plus/features/admin/customers/cubit/customer_list_state.dart';
import 'package:iq_plus/features/users/cubit/employee_user_cubit.dart';
import 'package:iq_plus/features/users/cubit/employee_user_state.dart';
import 'package:iq_plus/features/users/models/employe_user.dart';
import 'package:iq_plus/features/users/pages/add_user_dialog.dart';

class EmployeeListPage extends StatefulWidget {
  const EmployeeListPage({super.key});

  @override
  State<EmployeeListPage> createState() => _EmployeeListPageState();
}

class _EmployeeListPageState extends State<EmployeeListPage> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final user = getIt<HiveService>().getUser();
    final customer = getIt<HiveService>().getCustomer();
    final customerCubit = context.read<CustomerListCubit>();
    
    List<String>? customerIds;
    String? createdBy;

    if (user != null && Utility.isConsultant(user.roleId)) {
      // 🚀 For consultants, show ONLY employees THEY created
      createdBy = user.userId;
      
      // Also fetch their assigned customers to resolve company names in the UI
      await customerCubit.fetchApprovedCustomers(user.userId);
    } else if (customer != null && Utility.isCustomer(customer.roleId)) {
      // For customers, show all employees of their company
      customerIds = [customer.customerId];
    } else {
      // For Admins/SuperAdmins, show all employees and resolve company names
      await customerCubit.fetchApprovedCustomers(null);
    }
    
    if (mounted) {
      context.read<UserCubit>().loadEmployees(
        customerIds: customerIds,
        createdBy: createdBy,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text(
          'Employees',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        actions: [
          if (!Utility.isCustomer(getIt<HiveService>().getCustomer()?.roleId ?? getIt<HiveService>().getUser()?.roleId))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton.icon(
              onPressed: () async {
                await context.push(AppRoutes.addEmployee);
                _loadData();
              },
              icon: const Icon(Icons.add, color: Colors.white, size: 18),
              label: const Text("Add Employee",style: TextStyle(color: Colors.white),),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.kPrimaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            ),
        ],
      ),
      body: BlocBuilder<UserCubit, UserState>(
        builder: (context, state) {
          if (state is UserLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is UserError) {
            return Center(
              child: Text(
                state.message,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final employees = context.read<UserCubit>().users;

          if (employees.isNotEmpty) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: ListView.separated(
                itemCount: employees.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final employee = employees[index];

                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.kPrimaryLightColor,
                            child: Text(
                              employee.userName.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.kPrimaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),

                          /// EMPLOYEE INFO
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        employee.userName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.kPrimaryColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        Utility.getUserRoleName(employee.roleId).toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.kPrimaryColor,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (employee.designation != null)
                                  Text(
                                    employee.designation!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.email_outlined, size: 14, color: Colors.grey),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        employee.email,
                                        style: const TextStyle(fontSize: 13, color: Colors.black87),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.phone_outlined, size: 14, color: Colors.grey),
                                    const SizedBox(width: 6),
                                    Text(
                                      employee.phoneNumber,
                                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                BlocBuilder<CustomerListCubit, CustomerListState>(
                                  builder: (context, customerState) {
                                    String companyName = ""; // Default empty
                                    if (customerState is CustomerListLoaded) {
                                      try {
                                        companyName = customerState.customers
                                            .firstWhere((c) => c.customerId == employee.customerId)
                                            .companyName;
                                      } catch (_) {
                                        companyName = "Organization N/A";
                                      }
                                    } else if (customerState is CustomerListLoading) {
                                      companyName = "Fetching...";
                                    }
                                    
                                    if (companyName.isEmpty) return const SizedBox.shrink();

                                    return Row(
                                      children: [
                                        const Icon(Icons.business, size: 14, color: Colors.grey),
                                        const SizedBox(width: 6),
                                        Text(
                                          companyName,
                                          style: const TextStyle(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),

                          /// ACTIONS
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (!Utility.isCustomer(getIt<HiveService>().getCustomer()?.roleId ?? getIt<HiveService>().getUser()?.roleId))
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (employee.blockStatus ? Colors.red : Colors.green).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    employee.blockStatus ? "Blocked" : "Active",
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: employee.blockStatus ? Colors.red : Colors.green,
                                    ),
                                  ),
                                ),
                              
                              if (Utility.isCustomer(getIt<HiveService>().getCustomer()?.roleId ?? getIt<HiveService>().getUser()?.roleId))
                                ElevatedButton.icon(
                                  onPressed: () {
                                    context.push(AppRoutes.trainingResults, extra: {
                                      'userId': employee.userId,
                                      'userName': employee.userName,
                                      'customerId': employee.customerId, // 🚀 Pass customerId
                                    });
                                  },
                                  icon: const Icon(Icons.bar_chart, size: 16),
                                  label: const Text("View Training Results", style: TextStyle(fontSize: 12)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.kPrimaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),

                              if (!Utility.isCustomer(getIt<HiveService>().getCustomer()?.roleId ?? getIt<HiveService>().getUser()?.roleId))
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => BlocProvider.value(
                                            value: context.read<UserCubit>(),
                                            child: AddUserDialog(user: employee),
                                          ),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                      onPressed: () => _showDeleteDialog(context, employee),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          } else if (state is UserLoaded && employees.isEmpty) {
            return const Center(
              child: Text(
                "No employees found",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          return const SizedBox();
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, EmployeeUserModel employee) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Employee"),
        content: Text("Are you sure you want to delete ${employee.userName}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<UserCubit>().deleteUser(employee.userId, customerId: employee.customerId);
              Navigator.pop(ctx);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
