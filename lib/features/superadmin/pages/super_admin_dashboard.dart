import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iq_plus/common/utility/utility.dart';
import 'package:iq_plus/common/widgets/common_app_bar.dart';
import 'package:iq_plus/features/admin/customers/cubit/customer_list_cubit.dart';
import 'package:iq_plus/features/admin/customers/cubit/customer_list_state.dart';

import 'package:iq_plus/common/routes/go_route.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/common/themes/responsive.dart';
import 'package:iq_plus/core/local_storage/hive_service.dart';
import 'package:iq_plus/di/service_locator.dart';
import 'package:iq_plus/ncr_form/ncr_provider.dart';

class SuperadminDashboardPage extends StatelessWidget {
  const SuperadminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      drawer: _buildDrawer(context),
      appBar: const CommonAppBar(
  title: 'Super Admin Dashboard',
),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: SingleChildScrollView(
          child: Responsive(
            mobile: SingleChildScrollView(
              child: Column(
                children: [
                  _statsSection(),
                  const SizedBox(height: 24),
                  _ncrChart(context),
                  const SizedBox(height: 24),
                  _dashboardCards(context),
                ],
              ),
            ),
            desktop: Row(
              children: [
                Expanded(flex: 2, child: _statsSection()),
                const SizedBox(width: 20),
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      _ncrChart(context),
                      const SizedBox(height: 24),
                      _dashboardCards(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================
  // 🌈 DRAWER
  // =========================
  Drawer _buildDrawer(BuildContext context) {
    
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(gradient: AppColors.mainGradient),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              child: InkWell(
                onTap: () {
                  context.pop(); // close drawer
                  context.push(AppRoutes.adminProfile); // SAME profile page
                },
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.admin_panel_settings,
                        color: AppColors.purple,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          getIt<HiveService>().getUser()?.userName ??
                              "Super Admin",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          getIt<HiveService>().getUser()?.email ?? "",
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "View Profile",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 🔹 ADMIN
            // _drawerItem(
            //   context,
            //   icon: Icons.people,
            //   title: 'Customers',
            //   route: AppRoutes.customerList,
            // ),
             // 🔹 Customers Section as ExpansionTile
            BlocBuilder<CustomerListCubit, CustomerListState>(
                builder: (context, state) {
                  if (state is CustomerListLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }else  if (state is CustomerListLoaded) {
                    final allCustomers = state.customers
                        .where((customer) => customer.isProfileApproved)
                        .toList();

                    if (allCustomers.isEmpty) {
                      return const Center(child: Text('No approved customers found'));
                    }
                   return   ExpansionTile(
                     leading: const Icon(Icons.people, color: Colors.white),
                     title: const Text(
                       'Customers',
                       style: TextStyle(color: Colors.white, fontSize: 16),
                     ),
                     children: allCustomers.map((customer) {
                       return ListTile(
                         title: Text(
                           customer.companyName,
                           style: const TextStyle(color: Colors.white70),
                         ),
                         subtitle: Text(
                           customer.email,
                           style: const TextStyle(color: Colors.white54, fontSize: 12),
                         ),
                         onTap: () {
                           context.pop(); // close drawer
                           context.push(
                             AppRoutes.customerProfile,
                             extra: customer,
                           );
                         },
                       );
                     }).toList(),
                   );
                  }
                  return const SizedBox();
            }
          ),
            _drawerItem(
              context,
              icon: Icons.badge,
              title: 'Consultants',
              route: AppRoutes.employeeList,
            ),

            // ✅ Add Admin
            if(Utility.isSuperAdmin(getIt<HiveService>().getUser()?.roleId??""))
              _drawerItem(
                context,
                icon: Icons.person_add_alt,
                title: 'Add Admin',
                onTap: () {
                  context.pop();
                  context.push(AppRoutes.createAdmin); // navigate to Add Admin page
                },
              ),

            // 🔹 SUPER ADMIN ONLY
            // _drawerItem(
            //   context,
            //   icon: Icons.person_add_alt,
            //   title: 'Add Admin',
            //   onTap: () {
            //     context.pop(); // close drawer
            //     context.push(AppRoutes.createAdmin);
            //   }, // or AddAdmin page
            // ),
            _drawerItem(
              context,
              icon: Icons.admin_panel_settings,
              title: 'Admins',
              route: AppRoutes.adminList,
            ),

            _drawerItem(
              context,
              icon: Icons.description,
              title: 'Policies & Procedures',
              route: AppRoutes.documentList,
            ),


            // 🔹 COMMON
            _drawerItem(
              context,
              icon: Icons.contact_mail,
              title: 'Contact Us',
              route: AppRoutes.contactUs,
            ),

            _drawerItem(
              context,
              icon: Icons.logout,
              title: 'Logout',
              onTap: () {
                getIt<HiveService>().clearAll();
                context.go(AppRoutes.login);
              },
            ),
          ],
        ),
      ),
    );
  }

  ListTile _drawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? route,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      onTap:
          onTap ??
          () {
            context.pop();
            if (route != null) context.push(route);
          },
    );
  }

  // =========================
  // 📊 STATS
  // =========================
  Widget _statsSection() {
    return Column(
      children: [
        _statCard('Total Customers', 'ALL', AppColors.purple),
        const SizedBox(height: 16),
        _statCard('Total Consultants', 'ALL', AppColors.blue),
        const SizedBox(height: 16),
        _statCard('Admins', 'ALL', AppColors.paid),
      ],
    );
  }

  Widget _statCard(String title, String value, Color color) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withValues(alpha:0.15),
              child: Icon(Icons.analytics, color: color),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.subText,
                    fontSize: 14,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // 📈 NCR CHART
  // =========================
  Widget _ncrChart(BuildContext context) {
    final provider = context.watch<NcrProvider>();
    final values = [
      provider.openCount.toDouble(),
      provider.inProgressCount.toDouble(),
      provider.closedCount.toDouble(),
    ];

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 260,
          child: BarChart(
            BarChartData(
              maxY: values.reduce(max) + 2,
              barGroups: values.asMap().entries.map((e) {
                return BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: e.value,
                      width: 18,
                      color: AppColors.barColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  // =========================
  // 🔗 DASHBOARD CARDS
  // =========================
  Widget _dashboardCards(BuildContext context) {
    return Column(
      children: [
        _dashboardCard(
          title: 'NCR',
          icon: Icons.report_problem,
          onTap: () => context.push(AppRoutes.ncrPage),
        ),
        _dashboardCard(
          title: 'Customer Management',
          icon: Icons.people,
          onTap: () => context.push(AppRoutes.customerList),
        ),
        _dashboardCard(
          title: 'Consultant Management',
          icon: Icons.badge,
          onTap: () => context.push(AppRoutes.employeeList),
        ),
        _dashboardCard(
          title: 'Visit Summary',
          icon: Icons.event_available,
          onTap: () => context.push(AppRoutes.visitorSummary),
        ),
        _dashboardCard(
          title: 'Policies & Procedures',
          icon: Icons.description,
          onTap: () => context.push(AppRoutes.documentList),
        ),
      ],
    );
  }

  Widget _dashboardCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Card(
        elevation: 6,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.kPrimaryLightColor,
                child: Icon(icon, color: AppColors.kPrimaryColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.titleText,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
