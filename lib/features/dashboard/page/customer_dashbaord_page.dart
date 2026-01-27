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
import 'package:iq_plus/features/admin/consultants/model/consultant_model.dart';
import 'package:iq_plus/features/admin/customers/pages/customer_profile_edit_page.dart';
import 'package:iq_plus/features/admin/customers/pages/customer_profile_page.dart';
import 'package:iq_plus/features/auth/Login/login_page.dart';
import 'package:iq_plus/features/chatbot/chat_screen.dart';
import 'package:iq_plus/features/customer_mme/cubit/customer_mme_cubit.dart';
import 'package:iq_plus/features/customer_mme/cubit/customer_mme_state.dart';
import 'package:iq_plus/features/customer_mme/pages/customer_mme_list_page.dart';
import 'package:iq_plus/features/dashboard/page/contact_us_page.dart';
import 'package:iq_plus/features/dashboard/page/visit_summary/visit_summary_page.dart';
import 'package:iq_plus/ncr_form/ncr_page.dart';
import 'package:iq_plus/ncr_form/ncr_provider.dart';
import 'package:iq_plus/features/auth/model/customer_model.dart';

import 'package:provider/provider.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  ConsultantModel? assignedConsultant;
  bool isConsultantLoading = false;
  CustomerModel? customerModel;
  final user = getIt<HiveService>().getUser();
  final customer = getIt<HiveService>().getCustomer();

  // @override
  // void initState() {
  //   final hiveService = getIt<HiveService>();
  //   customerModel = hiveService.getCustomer();
  //   if ((customerModel?.customerId ?? '').isNotEmpty) {
  //     context.read<CustomerMMECubit>().loadMME(customerModel!.customerId);
  //   }
  //   _fetchAssignedConsultant(customerModel!.customerId);
  //   super.initState();
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      drawer: _buildBeautifulDrawer(),
      appBar: const CommonAppBar(
  title: 'Governance Risk and Compliance Dashboard',
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
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildChartsColumn(context),
                      const SizedBox(height: 24),
                      _buildStatsColumn(),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      const Text(
                        'Other Details',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.titleText,
                        ),
                      ),
                      const SizedBox(height: 14),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.dashboard, color: AppColors.purple),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Dashboard',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            _profileDropdown(context),

            _drawerItem(
              icon: Icons.devices,
              title: 'MME',
              onTap: () {
                if ((customerModel?.customerId ?? '').isNotEmpty) {
                  GoRouter.of(context).pop();
                  context.push(
                    AppRoutes.customerMMEList, // route path for edit page
                    extra:
                        customerModel!.customerId, // pass the customer object
                  );
                }
              },
            ),
            // _drawerItem(
            //   icon: Icons.badge,
            //   title: 'My Consultant',
            //   onTap: () async {
            //     final customer = getIt<HiveService>().getCustomer();
            //     if (customer == null) return;

            //     final consultant = await getAssignedConsultant(
            //       customer.customerId,
            //     );

            //     if (consultant == null) {
            //       ScaffoldMessenger.of(context).showSnackBar(
            //         const SnackBar(content: Text('No consultant assigned')),
            //       );
            //       return;
            //     }

            //     context.push(AppRoutes.consultantProfile, extra: consultant);
            //   },
            // ),

            _drawerItem(
              icon: Icons.contact_mail,
              title: 'Contact Us',
              onTap: () {
                GoRouter.of(context).pop(); // closes the drawer
                GoRouter.of(context).push(AppRoutes.contactUs); // navigate
              },
            ),

            _drawerItem(
              icon: Icons.chat,
              title: 'Chat with us',
              onTap: () {
                GoRouter.of(context).pop(); // close the drawer
                context.push(AppRoutes.chat); // navigate using GoRouter
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

  Widget _profileDropdown(BuildContext context) {
    final hiveService = getIt<HiveService>();

    return ExpansionTile(
      leading: const Icon(Icons.person, color: Colors.white),
      title: const Text(
        'Profile',
        style: TextStyle(color: Colors.white, fontSize: 16),
      ),
      iconColor: Colors.white,
      collapsedIconColor: Colors.white,
      children: [
        ListTile(
          title: const Text(
            "View Profile",
            style: TextStyle(color: Colors.white),
          ),
          onTap: () {
            final customer = hiveService.getCustomer();
            if (customer != null) {
              GoRouter.of(context).pop();
              context.push(
                AppRoutes.customerProfile, // define this route path
                extra: customer, // pass the customer object
              );
            }
          },
        ),
        ListTile(
          title: const Text(
            "Edit Profile",
            style: TextStyle(color: Colors.white),
          ),
          onTap: () async {
            final customer = hiveService.getCustomer();
            if (customer != null) {
              GoRouter.of(context).pop();
              await context.push(
                AppRoutes.customerProfileEdit, // route path for edit page
                extra: customer, // pass the customer object
              );
            }
          },
        ),
      ],
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

  Widget _buildStatsColumn() {
    return BlocBuilder<CustomerMMECubit, CustomerMMEState>(
      builder: (context, state) {
        if (state is CustomerMMELoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is CustomerMMELoaded) {
          return _statCard(
            'Monitoring and Measuring Equipment',
            '${state.list.length}',
            AppColors.purple,
            () {
              if ((customerModel?.customerId ?? '').isNotEmpty) {
                context.push(
                  AppRoutes.customerMMEList, // route path for edit page
                  extra: customerModel!.customerId, // pass the customer object
                );
              }
            },
          );
        } else {
          return SizedBox();
        }
      },
    );
  }

  Widget _statCard(
    String title,
    String value,
    Color color,
    GestureTapCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2), width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon Section
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.precision_manufacturing,
                  color: color,
                  size: 26,
                ),
              ),

              const SizedBox(width: 16),

              // Text Section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.subText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
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

              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColors.subText,
              ),
            ],
          ),
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

          onTap: () {
            GoRouter.of(context).pop(); // close drawer if needed
            GoRouter.of(
              context,
            ).push(AppRoutes.NCRFormPage); // navigate to NcrPage
          },
        ),

        _clickableCard(
          title: 'Visit Summary',
          icon: Icons.warning_amber_rounded,
          onTap: () {
            GoRouter.of(context).pop(); // close drawer if needed
            GoRouter.of(context).push(AppRoutes.visitorSummary); // navigate
          },
        ),

        // 🟠 Static tiles (NO navigation for now)
        _clickableCard(
          title: 'Risk',
          icon: Icons.warning_amber_rounded,
          onTap: () {
            // later you can navigate
          },
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

  // Future<void> _fetchAssignedConsultant(String customerId) async {
  //   setState(() => isConsultantLoading = true);

  //   try {
  //     final consultant = await getAssignedConsultant(customerId);

  //     setState(() {
  //       assignedConsultant = consultant;
  //       isConsultantLoading = false;
  //     });
  //   } catch (e) {
  //     setState(() => isConsultantLoading = false);
  //   }
  // }
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
