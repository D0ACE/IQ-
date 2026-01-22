import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iq_plus/common/routes/go_route.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/common/themes/responsive.dart';
import 'package:iq_plus/core/local_storage/hive_service.dart';
import 'package:iq_plus/di/service_locator.dart';
import 'package:iq_plus/features/admin/customers/pages/customer_list_page.dart';
import 'package:iq_plus/features/admin/pages/admin_profile_page.dart';
import 'package:iq_plus/features/auth/Login/login_page.dart';
import 'package:iq_plus/features/auth/cubit/customer/customer_cubit.dart';
import 'package:iq_plus/features/auth/customer_onboarding/onboarding_mode.dart';
import 'package:iq_plus/features/auth/customer_onboarding/onboarding_request_page.dart';
import 'package:iq_plus/features/auth/customer_onboarding/page/customer_onboarding_page.dart';
import 'package:iq_plus/features/dashboard/page/contact_us_page.dart';

import 'package:iq_plus/features/users/cubit/employee_user_cubit.dart';
import 'package:iq_plus/features/users/pages/employe_user_list_page.dart';
import 'package:iq_plus/ncr_form/ncr_page.dart';
import 'package:iq_plus/ncr_form/ncr_provider.dart';

import 'package:provider/provider.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      drawer: _buildBeautifulDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(color: AppColors.titleText),
        ),
        iconTheme: const IconThemeData(color: AppColors.kPrimaryColor),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Responsive(
          mobile: SingleChildScrollView(
            child: Column(
              children: [
                _buildStatsColumn(),
                const SizedBox(height: 20),
                _buildChartsColumn(context),
                const SizedBox(height: 24),
                _dashboardClickableList(),
              ],
            ),
          ),
          desktop: SingleChildScrollView(
            child: Row(
              children: [
                Expanded(flex: 2, child: _buildStatsColumn()),
                const SizedBox(width: 20),
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      _buildChartsColumn(context),
                      const SizedBox(height: 24),
                      _dashboardClickableList(),
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

  /// 🌈 Drawer
  Widget _buildBeautifulDrawer() {
    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Container(
        decoration: const BoxDecoration(gradient: AppColors.mainGradient),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              child: InkWell(
                onTap: () {
                  GoRouter.of(context).pop();

                  /// close drawer
                  context.push(AppRoutes.adminProfile);
                },
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        color: AppColors.purple,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          getIt<HiveService>().getUser()?.userName ?? "Admin",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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

            _drawerItem(
              icon: Icons.person_add,
              title: 'Onboarding Request',
              onTap: () {
                context.pop();
                context.push(AppRoutes.onboardingRequest);
              },
            ),

            _drawerItem(
              icon: Icons.people,
              title: 'Customers',
              onTap: () {
                context.pop();
                context.push(AppRoutes.customerList);
              },
            ),
            _drawerItem(
              icon: Icons.people,
              title: 'Consultants',
              onTap: () {
                context.pop();
                context.push(AppRoutes.employeeList);
              },
            ),
                       // ✅ Add Admin
          _drawerItem(
            icon: Icons.person_add_alt,
            title: 'Add Admin',
            onTap: () {
              context.pop();
              context.push(AppRoutes.createAdmin); // navigate to Add Admin page
            },
          ),

          // ✅ Admins (List)
          _drawerItem(
            icon: Icons.admin_panel_settings,
            title: 'Admins',
            onTap: () {
              context.pop();
              context.push(AppRoutes.adminList); // navigate to Admin List page
            },
          ),
            _drawerItem(
              icon: Icons.contact_mail,
              title: 'Contact Us',
              onTap: () {
                context.pop();
                context.push(AppRoutes.contactUs);
              },
            ),
            _drawerItem(
              icon: Icons.logout,
              title: 'Logout',
              onTap: () {
                getIt<HiveService>().clearAll();
                context.go(AppRoutes.login); // clear stack and go to login
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String title,
    required GestureTapCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      onTap: onTap,
    );
  }

  /// 📊 Stats
  Widget _buildStatsColumn() {
    return Column(
      children: [
        _statCard('Users', '1,245', AppColors.purple),
        const SizedBox(height: 16),
        _statCard('Revenue', '\$12,345', AppColors.paid),
        const SizedBox(height: 16),
        _statCard('Orders', '321', AppColors.blue),
      ],
    );
  }

  Widget _statCard(String title, String value, Color color) {
    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, color: AppColors.subText),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 📈 NCR CHART (PROVIDER DRIVEN)
  Widget _buildChartsColumn(BuildContext context) {
    final ncrProvider = context.watch<NcrProvider>();

    final barValues = [
      ncrProvider.openCount.toDouble(),
      ncrProvider.inProgressCount.toDouble(),
      ncrProvider.closedCount.toDouble(),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'NCR Overview',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.titleText,
          ),
        ),
        const SizedBox(height: 14),
        Card(
          elevation: 10,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 280,
              child: AnimatedBarChart(
                values: barValues,
                barColor: AppColors.barColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 🔗 Dashboard Navigation
  Widget _dashboardClickableList() {
    return Column(
      children: [
        // 🔴 Existing NCR tile
        _clickableCard(
          title: 'NCR',
          icon: Icons.report_problem,
          onTap: () => context.push(AppRoutes.ncrPage),
        ),

        // 🟠 Static tiles (NO navigation for now)
        _clickableCard(
          title: 'Risk',
          icon: Icons.warning_amber_rounded,
          onTap: () {},
        ),

        _clickableCard(
          title: 'Next Visit',
          icon: Icons.event_available,
          onTap: () {},
        ),

        _clickableCard(
          title: 'Next Audit',
          icon: Icons.fact_check,
          onTap: () {},
        ),

        _clickableCard(
          title: 'Next Training',
          icon: Icons.school,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _clickableCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Card(
        elevation: 8,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
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

/// 📊 Animated Bar Chart
class AnimatedBarChart extends StatelessWidget {
  final List<double> values;
  final Color barColor;

  const AnimatedBarChart({
    super.key,
    required this.values,
    required this.barColor,
  });

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        maxY: values.isEmpty ? 5 : values.reduce(max) + 2,
        barGroups: values.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value,
                color: barColor,
                width: 18,
                borderRadius: BorderRadius.circular(8),
              ),
            ],
          );
        }).toList(),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) =>
                  Text(['Open', 'In Progress', 'Closed'][value.toInt()]),
            ),
          ),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
        ),
      ),
    );
  }
}
