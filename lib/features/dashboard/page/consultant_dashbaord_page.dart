import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iq_plus/common/routes/go_route.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/common/themes/responsive.dart';
import 'package:iq_plus/common/widgets/common_app_bar.dart';

import 'package:iq_plus/core/local_storage/hive_service.dart';
import 'package:iq_plus/di/service_locator.dart';
import 'package:iq_plus/features/admin/customers/cubit/customer_list_cubit.dart';
import 'package:iq_plus/features/admin/customers/cubit/customer_list_state.dart';
import 'package:iq_plus/features/dashboard/page/visit_summary/cubit/visitor_summary_cubit.dart';
import 'package:iq_plus/features/dashboard/page/visit_summary/cubit/visitor_summary_state.dart';
import 'package:iq_plus/ncr_form/ncr/repository/ncr_repository.dart';
import 'package:iq_plus/ncr_form/ncr_provider.dart';

class ConsultantDashboardPage extends StatefulWidget {
  const ConsultantDashboardPage({super.key});

  @override
  State<ConsultantDashboardPage> createState() =>
      _ConsultantDashboardPageState();
}

class _ConsultantDashboardPageState extends State<ConsultantDashboardPage> {
  final user = getIt<HiveService>().getUser();

  @override
  void initState() {
    super.initState();
    context.read<VisitorSummaryCubit>().loadVisitorSummaries();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      drawer: _buildBeautifulDrawer(),
      appBar: const CommonAppBar(title: 'Consultant Dashboard'),

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
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
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
    // final assignedCustomers = hiveService.getAssignedCustomers(
    //   currentUser?.userId ?? '',
    // );
    //
    // // 🔹 Assigned customers for this consultant
    // hiveService
    //     .getAllCustomers()
    //     .where((c) => c.assignedConsultantId == currentUser?.userId)
    //     .toList();
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
                  final consultantId = getIt<HiveService>().getUser()?.userId;
                  if (consultantId != null && consultantId.isNotEmpty) {
                    GoRouter.of(context).pop(); // close drawer
                    GoRouter.of(context).push(
                      AppRoutes.consultantProfile,
                      extra: consultantId, // pass the ID here
                    );
                  } else {
                    // optional: show error if ID is missing
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Invalid consultant ID")),
                    );
                  }
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            getIt<HiveService>().getUser()?.userName ??
                                "Consultant",

                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              getIt<HiveService>().getUser()?.email ?? "",
                              style: const TextStyle(color: Colors.white70),
                            ),
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
                    ),
                  ],
                ),
              ),
            ),

            _drawerItem(
              icon: Icons.report_problem_outlined,
              title: 'NCR',
              onTap: () {
                GoRouter.of(context).pop(); // closes the drawer
                GoRouter.of(context).push(AppRoutes.ncrPage); // navigate
              },
            ),

         _drawerItem(
              icon: Icons.event_available,
              title: 'Visitor Summary',
              onTap: () {
                GoRouter.of(context).pop(); // closes the drawer
                GoRouter.of(context).push(AppRoutes.visitorSummaryList); // navigate
              },
            ),

            _drawerItem(
              icon: Icons.policy_outlined,
              title: 'Policies & Procedures',
              onTap: () {
                GoRouter.of(context).pop();
                GoRouter.of(context).push(AppRoutes.documentList);
              },
            ),

            _drawerItem(
              icon: Icons.history,
              title: 'All Policies Version History',
              onTap: () {
                GoRouter.of(context).pop();
                GoRouter.of(context).push(AppRoutes.globalVersionHistory);
              },
            ),

            // 🔵 My Customers (Expandable)
            _drawerItem(
              icon: Icons.supervised_user_circle_outlined,
              title: 'Assign Customers',
              onTap: () {
                if ((user?.userId??'').isNotEmpty) {
                  GoRouter.of(context).pop();
                  GoRouter.of(context).push(
                    AppRoutes.assignCustomers,
                    extra: user?.userId,
                  );
                } else {
                  // optional: show error if ID is missing
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Invalid consultant ID")),
                  );
                }
              },
            ),

            _drawerItem(
              icon: Icons.contact_support_outlined,
              title: 'Contact Us',
              onTap: () {
                GoRouter.of(context).pop(); // closes the drawer
                GoRouter.of(context).push(AppRoutes.contactUs); // navigate
              },
            ),

            _drawerItem(
              icon: Icons.logout,
              title: 'Logout',
              onTap: () {
                final hiveService = getIt<HiveService>();
                hiveService.clearAll(); // clear local storage
                GoRouter.of(context).pop(); // close the drawer
                context.go(
                  AppRoutes.login,
                ); // navigate to login and replace the stack
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
        BlocBuilder<CustomerListCubit, CustomerListState>(
            builder: (c, state) {
              if (state is CustomerListLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              int count=(state is CustomerListLoaded) ?state.customers.length:0;
              return GestureDetector(onTap:(){ GoRouter.of(context).push(
                AppRoutes.assignCustomers,
                extra: user?.userId,
              );},child: _statCard('Assign Customers', '$count', AppColors.purple));
          }
        ),
        const SizedBox(height: 16),
        FutureBuilder<int>(
          future: NcrRepository().getNCRCountOnce(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final count = snapshot.data ?? 0;

            return GestureDetector(onTap:(){ GoRouter.of(context).push(AppRoutes.ncrPage);},child: _statCard('Total NCR', '$count', AppColors.paid));
          },
        ),
        const SizedBox(height: 16),
        BlocBuilder<VisitorSummaryCubit, VisitorSummaryState>(
            builder: (c, state) {
              if (state is VisitorSummaryLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              int count=(state is VisitorSummaryLoaded) ?state.list.length:0;
              return GestureDetector(onTap:(){ GoRouter.of(context).push(
                AppRoutes.visitorSummaryList,
                extra: user?.userId,
              );},child: _statCard('Total Visitor Summary', '$count', AppColors.blue));
            }
        ),
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
          onTap: () => GoRouter.of(context).push(AppRoutes.ncrPage),
        ),

        // 🟠 Static tiles (NO navigation for now)
        // _clickableCard(
        //   title: 'Risk',
        //   icon: Icons.warning_amber_rounded,
        //   onTap: () {
        //     // later you can navigate
        //   },
        // ),

        _clickableCard(
          title: 'Visitor Summary',
          icon: Icons.event_available,
          onTap: () {
            GoRouter.of(context).push(AppRoutes.visitorSummaryList);
          },
        ),

        _clickableCard(
          title: 'Policies & Procedures',
          icon: Icons.policy,
          onTap: () => GoRouter.of(context).push(AppRoutes.documentList),
        ),

        _clickableCard(
          title: 'All Policies Version History',
          icon: Icons.history,
          onTap: () => GoRouter.of(context).push(AppRoutes.globalVersionHistory),
        ),

        // _clickableCard(
        //   title: 'Next Audit',
        //   icon: Icons.fact_check,
        //   onTap: () {},
        // ),
        //
        // _clickableCard(
        //   title: 'Next Training',
        //   icon: Icons.school,
        //   onTap: () {},
        // ),
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
