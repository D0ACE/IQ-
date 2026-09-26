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
import 'package:iq_plus/features/auth/model/customer_model.dart';
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
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  String selectedStatusFilter = 'all'; // 'all', 'active', 'blocked'
  String selectedCompanyFilter = 'all'; // 'all' or customerId

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _loadData() async {
    final user = getIt<HiveService>().getUser();
    final customer = getIt<HiveService>().getCustomer();
    final customerCubit = context.read<CustomerListCubit>();

    List<String>? customerIds;
    String? createdBy;
    String? consultantId;

    if (user != null && Utility.isConsultant(user.roleId)) {
      // 🚀 For consultants, show employees of their assigned customers OR created by them
      consultantId = user.userId;

      // Also fetch their assigned customers to resolve company names in the UI (Run in background)
      customerCubit.fetchApprovedCustomers(user.userId);
    } else if (customer != null && Utility.isCustomer(customer.roleId)) {
      // For customers, show all employees of their company
      customerIds = [customer.customerId];
    } else {
      // For Admins/SuperAdmins, show all employees and resolve company names (Run in background)
      customerCubit.fetchApprovedCustomers(null);
    }

    if (mounted) {
      context.read<UserCubit>().loadEmployees(
            customerIds: customerIds,
            createdBy: createdBy,
            consultantId: consultantId,
          );
    }
  }

  bool _isCompanyValid(String value, List<CustomerModel> customerList) {
    if (value == 'all') return true;
    return customerList.any((c) => c.customerId == value);
  }

  List<EmployeeUserModel> _getFilteredList(
    List<EmployeeUserModel> originalList,
    List<CustomerModel> customerList,
  ) {
    return originalList.where((employee) {
      // 1. Status Filter
      if (selectedStatusFilter == 'active' && employee.blockStatus) {
        return false;
      }
      if (selectedStatusFilter == 'blocked' && !employee.blockStatus) {
        return false;
      }

      // 2. Company Filter
      if (selectedCompanyFilter != 'all') {
        if (employee.customerId != selectedCompanyFilter) {
          return false;
        }
      }

      // 3. Search Query
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase().trim();
        final name = employee.userName.toLowerCase();
        final email = employee.email.toLowerCase();
        final phone = employee.phoneNumber.toLowerCase();
        final designation = (employee.designation ?? '').toLowerCase();

        String companyName = '';
        for (final c in customerList) {
          if (c.customerId == employee.customerId) {
            companyName = c.companyName.toLowerCase();
            break;
          }
        }

        final matches = name.contains(q) ||
            email.contains(q) ||
            phone.contains(q) ||
            designation.contains(q) ||
            companyName.contains(q);

        if (!matches) return false;
      }

      return true;
    }).toList();
  }

  Widget _buildFilterChip(String label, String value, Color color) {
    final isSelected = selectedStatusFilter == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
      ),
      selected: isSelected,
      selectedColor: color,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? color : Colors.grey.shade300,
        ),
      ),
      onSelected: (bool selected) {
        if (selected) {
          setState(() {
            selectedStatusFilter = value;
          });
        }
      },
    );
  }

  Widget _buildSearchAndFilters(
      List<CustomerModel> customerList, bool isCustomerUser) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🔍 SEARCH BAR
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: "Search by name, email, phone, designation...",
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              prefixIcon:
                  const Icon(Icons.search, color: AppColors.kPrimaryColor),
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
          if (!isCustomerUser && customerList.isNotEmpty) ...[
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
                  value: _isCompanyValid(selectedCompanyFilter, customerList)
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
                      child: Text('All Organizations'),
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

          /// 🏷️ STATUS CHIPS
          if (!isCustomerUser) ...[
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip("All", "all", AppColors.kPrimaryColor),
                  const SizedBox(width: 8),
                  _buildFilterChip("Active", "active", Colors.green),
                  const SizedBox(width: 8),
                  _buildFilterChip("Blocked", "blocked", Colors.redAccent),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentRole = getIt<HiveService>().getCustomer()?.roleId ??
        getIt<HiveService>().getUser()?.roleId;
    final isCustomerUser = Utility.isCustomer(currentRole);

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
          if (!isCustomerUser)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await context.push(AppRoutes.addEmployee);
                  if (result == true) {
                    _loadData();
                  }
                },
                icon: const Icon(Icons.add, color: Colors.white, size: 18),
                label: const Text(
                  "Add Employee",
                  style: TextStyle(color: Colors.white),
                ),
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
      body: BlocBuilder<CustomerListCubit, CustomerListState>(
        builder: (context, customerState) {
          List<CustomerModel> customerList = [];
          if (customerState is CustomerListLoaded) {
            customerList = customerState.customers;
          }

          return BlocConsumer<UserCubit, UserState>(
            listener: (context, state) {
              if (state is UserError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            builder: (context, state) {
              if (state is UserLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final rawUsers = context.read<UserCubit>().users;
              final employees =
                  rawUsers.whereType<EmployeeUserModel>().toList();
              final filteredEmployees =
                  _getFilteredList(employees, customerList);

              return Column(
                children: [
                  /// 🔍 SEARCH & FILTERS
                  _buildSearchAndFilters(customerList, isCustomerUser),

                  /// 📋 EMPLOYEE LIST
                  Expanded(
                    child: filteredEmployees.isEmpty
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
                                  employees.isEmpty
                                      ? "No employees found"
                                      : "No matching employees found",
                                  style: const TextStyle(
                                    color: Colors.grey,
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
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            itemCount: filteredEmployees.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final employee = filteredEmployees[index];

                              String companyName = "";
                              if (employee.customerId != null &&
                                  employee.customerId!.isNotEmpty) {
                                for (final c in customerList) {
                                  if (c.customerId == employee.customerId) {
                                    companyName = c.companyName;
                                    break;
                                  }
                                }
                                if (companyName.isEmpty &&
                                    customerState is CustomerListLoading) {
                                  companyName = "Fetching...";
                                }
                              }

                              return Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                      color: Colors.grey.shade200),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundColor:
                                            AppColors.kPrimaryLightColor,
                                        child: Text(
                                          employee.userName.isNotEmpty
                                              ? employee.userName
                                                  .substring(0, 1)
                                                  .toUpperCase()
                                              : "?",
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    employee.userName,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: AppColors
                                                        .kPrimaryColor
                                                        .withValues(
                                                            alpha: 0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Text(
                                                    Utility.getUserRoleName(
                                                            employee.roleId)
                                                        .toUpperCase(),
                                                    style: const TextStyle(
                                                      fontSize: 9,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      color: AppColors
                                                          .kPrimaryColor,
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
                                                  color:
                                                      Colors.grey.shade600,
                                                  fontWeight:
                                                      FontWeight.w500,
                                                ),
                                              ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                const Icon(
                                                    Icons.email_outlined,
                                                    size: 14,
                                                    color: Colors.grey),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    employee.email,
                                                    style: const TextStyle(
                                                        fontSize: 13,
                                                        color: Colors
                                                            .black87),
                                                    overflow: TextOverflow
                                                        .ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(
                                                    Icons.phone_outlined,
                                                    size: 14,
                                                    color: Colors.grey),
                                                const SizedBox(width: 6),
                                                Text(
                                                  employee.phoneNumber,
                                                  style: const TextStyle(
                                                      fontSize: 13,
                                                      color: Colors
                                                          .black87),
                                                ),
                                              ],
                                            ),
                                            if (companyName.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  const Icon(Icons.business,
                                                      size: 14,
                                                      color: Colors.grey),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(
                                                      companyName,
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            Colors.blueGrey,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                      overflow: TextOverflow
                                                          .ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),

                                      /// ACTIONS
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          if (!isCustomerUser)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                color: (employee.blockStatus
                                                        ? Colors.red
                                                        : Colors.green)
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                employee.blockStatus
                                                    ? "Blocked"
                                                    : "Active",
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight:
                                                      FontWeight.bold,
                                                  color: employee.blockStatus
                                                      ? Colors.red
                                                      : Colors.green,
                                                ),
                                              ),
                                            ),
                                          if (isCustomerUser)
                                            ElevatedButton.icon(
                                              onPressed: () {
                                                context.push(
                                                    AppRoutes.trainingResults,
                                                    extra: {
                                                      'userId': employee.userId,
                                                      'userName':
                                                          employee.userName,
                                                      'customerId': employee
                                                          .customerId,
                                                    });
                                              },
                                              icon: const Icon(Icons.bar_chart,
                                                  size: 16),
                                              label: const Text(
                                                  "View Training Results",
                                                  style: TextStyle(
                                                      fontSize: 12)),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    AppColors.kPrimaryColor,
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets
                                                    .symmetric(
                                                    horizontal: 12,
                                                    vertical: 8),
                                                minimumSize: Size.zero,
                                                tapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8),
                                                ),
                                              ),
                                            ),
                                          if (!isCustomerUser)
                                            Row(
                                              children: [
                                                IconButton(
                                                  icon: const Icon(
                                                      Icons.edit_outlined,
                                                      color: Colors.blue,
                                                      size: 20),
                                                  onPressed: () async {
                                                    final userCubit = context
                                                        .read<UserCubit>();
                                                    final result =
                                                        await showDialog(
                                                      context: context,
                                                      builder: (_) =>
                                                          BlocProvider.value(
                                                        value: userCubit,
                                                        child: AddUserDialog(
                                                            user: employee),
                                                      ),
                                                    );
                                                    if (result == true) {
                                                      _loadData();
                                                    }
                                                  },
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                      Icons.delete_outline,
                                                      color: Colors.redAccent,
                                                      size: 20),
                                                  onPressed: () =>
                                                      _showDeleteDialog(
                                                          context, employee),
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
                  ),
                ],
              );
            },
          );
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
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<UserCubit>().deleteUser(employee.userId,
                  customerId: employee.customerId);
              Navigator.pop(ctx);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
