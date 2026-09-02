import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iq_plus/common/routes/go_route.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/common/themes/responsive.dart';
import 'package:iq_plus/common/utility/utility.dart';
import 'package:iq_plus/common/widgets/common_app_bar.dart';
import 'package:iq_plus/core/local_storage/hive_service.dart';
import 'package:iq_plus/di/service_locator.dart';
import 'package:iq_plus/features/users/repository/user_repository.dart';
import 'package:iq_plus/features/periodic_compliance/periodic_compliance_provider.dart';

import 'package:iq_plus/ncr_form/ncr_provider.dart';

import 'package:provider/provider.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage>
    with TickerProviderStateMixin {
  final user = getIt<HiveService>().getUser();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    // 🚀 Start listening to NCR data for the graph
    context.read<NcrProvider>().listenToNcrs();
    context.read<PeriodicComplianceProvider>().listenToTasks();

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      drawer: _buildBeautifulDrawer(),
      appBar: const CommonAppBar(title: 'Admin Command Center'),
      body: Stack(
        children: [
          // Decorative background elements
          Positioned(
            top: -50,
            right: -50,
            child: _buildDecorativeCircle(
              200,
              AppColors.kPrimaryColor.withValues(alpha: 0.03),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -30,
            child: _buildDecorativeCircle(
              150,
              AppColors.secondary.withValues(alpha: 0.03),
            ),
          ),

          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _welcomeHeader(),
                    const SizedBox(height: 24),
                    Responsive(
                      mobile: Column(
                        children: [
                          _buildChartsColumn(context),
                          const SizedBox(height: 24),
                          _buildStatsColumn(),
                          const SizedBox(height: 24),
                          _sectionTitle('Quick Actions'),
                          const SizedBox(height: 14),
                          _dashboardClickableList(),
                        ],
                      ),
                      desktop: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              children: [
                                _buildChartsColumn(context),
                                const SizedBox(height: 24),
                                _buildStatsColumn(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _sectionTitle('Quick Access'),
                                const SizedBox(height: 14),
                                _dashboardClickableList(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecorativeCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w900,
        color: AppColors.titleText,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _welcomeHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.kPrimaryColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.kPrimaryColor.withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            Positioned(
              right: -50,
              top: -50,
              child: Opacity(
                opacity: 0.1,
                child: Icon(
                  Icons.admin_panel_settings_rounded,
                  size: 250,
                  color: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: const Icon(
                          Icons.shield_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "WELCOME,",
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                            Text(
                              user?.userName ?? 'Administrator',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified_user_rounded,
                          color: Colors.amber,
                          size: 14,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "System administration is active",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🌈 Drawer
  Widget _buildBeautifulDrawer() {
    final String adminName = user?.userName ?? "Admin";
    final String email = user?.email ?? "admin@iqplus.com";
    Utility.isSuperAdmin(user?.roleId ?? "");

    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          // Futuristic Premium Header
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.kPrimaryColor,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(30),
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(30),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Opacity(
                      opacity: 0.15,
                      child: Icon(
                        Icons.admin_panel_settings_rounded,
                        size: 150,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                    child: InkWell(
                      onTap: () {
                        GoRouter.of(context).pop();
                        context.push(AppRoutes.adminProfile);
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            child: const Icon(
                              Icons.manage_accounts_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            adminName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            email,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              "VIEW PROFILE",
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              children: [
                _drawerSectionTitle('SYSTEM OVERSIGHT'),
                _drawerItem(
                  icon: Icons.person_add_rounded,
                  title: 'Onboarding Request',
                  onTap: () {
                    GoRouter.of(context).pop();
                    context.push(AppRoutes.onboardingRequest);
                  },
                ),
                _drawerItem(
                  icon: Icons.business_rounded,
                  title: 'Customers',
                  onTap: () {
                    GoRouter.of(context).pop();
                    context.push(AppRoutes.customerList);
                  },
                ),
                _drawerItem(
                  icon: Icons.badge_rounded,
                  title: 'Users',
                  onTap: () {
                    GoRouter.of(context).pop();
                    context.push(AppRoutes.employeeList);
                  },
                ),
                _drawerItem(
                  icon: Icons.policy_rounded,
                  title: 'Policies & Procedures',
                  onTap: () {
                    GoRouter.of(context).pop();
                    context.push(AppRoutes.documentList);
                  },
                ),

                const SizedBox(height: 20),
                _drawerSectionTitle('OPERATIONS'),
                _drawerItem(
                  icon: Icons.history_edu_rounded,
                  title: 'All Policies Version History',
                  onTap: () {
                    GoRouter.of(context).pop();
                    context.push(AppRoutes.globalVersionHistory);
                  },
                ),
                _drawerItem(
                  icon: Icons.group_rounded,
                  title: 'Employees',
                  onTap: () {
                    GoRouter.of(context).pop();
                    context.push(AppRoutes.employeeListing);
                  },
                ),
                //Todo Video
                _drawerItem(
                  icon: Icons.video_library_outlined,
                  title: 'Training Videos',
                  onTap: () {
                    GoRouter.of(context).pop();
                    context.push(AppRoutes.videoList);
                  },
                ),
                _drawerItem(
                  icon: Icons.assignment_rounded,
                  title: 'Compliance Tasks',
                  onTap: () {
                    GoRouter.of(context).pop();
                    context.push(AppRoutes.periodicComplianceList);
                  },
                ),

                const SizedBox(height: 20),
                _drawerSectionTitle('COMMUNICATION'),
                _drawerItem(
                  icon: Icons.alternate_email_rounded,
                  title: 'Contact Us',
                  onTap: () {
                    GoRouter.of(context).pop();
                    context.push(AppRoutes.contactUs);
                  },
                ),
              ],
            ),
          ),

          // Futuristic Logout Footer
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade100)),
            ),
            child: _drawerItem(
              icon: Icons.logout_rounded,
              title: 'Logout',
              color: Colors.redAccent,
              onTap: () {
                getIt<HiveService>().clearAll();
                context.go(AppRoutes.login);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 12, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: Colors.grey.shade400,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String title,
    required GestureTapCallback onTap,
    Color? color,
  }) {
    final Color itemColor = color ?? Colors.grey.shade700;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(icon, color: itemColor, size: 22),
        title: Text(
          title,
          style: TextStyle(
            color: itemColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        onTap: onTap,
        dense: true,
      ),
    );
  }

  /// 📊 Stats
  Widget _buildStatsColumn() {
    final userRepository = getIt<UserRepository>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('System Statistics'),
        const SizedBox(height: 14),
        FutureBuilder<int>(
          future: userRepository.getTotalActiveUserCount(),
          builder: (context, snapshot) {
            return _statCard(
              'Total Active Users',
              snapshot.connectionState == ConnectionState.waiting
                  ? '...'
                  : '${snapshot.data ?? 0}',
              AppColors.purple,
              Icons.people_alt_rounded,
              () {},
            );
          },
        ),
        const SizedBox(height: 16),
        FutureBuilder<int>(
          future: userRepository.getTotalCustomerCount(),
          builder: (context, snapshot) {
            return _statCard(
              'Total Customers',
              snapshot.connectionState == ConnectionState.waiting
                  ? '...'
                  : '${snapshot.data ?? 0}',
              AppColors.paid,
              Icons.business_center_rounded,
              () => context.push(AppRoutes.customerList),
            );
          },
        ),
        const SizedBox(height: 16),
        FutureBuilder<int>(
          future: userRepository.getTotalConsultantCount(),
          builder: (context, snapshot) {
            return _statCard(
              'Total Users',
              snapshot.connectionState == ConnectionState.waiting
                  ? '...'
                  : '${snapshot.data ?? 0}',
              AppColors.blue,
              Icons.badge_rounded,
              () => context.push(AppRoutes.employeeList),
            );
          },
        ),
      ],
    );
  }

  Widget _statCard(
    String title,
    String value,
    Color color,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.2),
                        color.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, color: color, size: 30),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: AppColors.titleText,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 20,
                  color: color.withValues(alpha: 0.3),
                ),
              ],
            ),
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
        _sectionTitle('Compliance Overview'),
        const SizedBox(height: 14),
        _buildChartCard(
          title: "Global NCR Trends",
          badgeText: "Real-time",
          badgeColor: AppColors.kPrimaryColor,
          child: SizedBox(
            height: 250,
            child: AnimatedBarChart(
              values: barValues,
              barColor: AppColors.kPrimaryColor,
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildPeriodicComplianceChart(context),
      ],
    );
  }

  Widget _buildChartCard({
    required String title,
    required String badgeText,
    required Color badgeColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          child,
        ],
      ),
    );
  }

  Widget _buildPeriodicComplianceChart(BuildContext context) {
    final provider = context.watch<PeriodicComplianceProvider>();

    final barValues = [
      provider.pendingCount.toDouble(),
      provider.completedCount.toDouble(),
    ];

    return _buildChartCard(
      title: "Periodic Compliance Tasks",
      badgeText: "Task Analytics",
      badgeColor: Colors.orange,
      child: SizedBox(
        height: 250,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: barValues.isEmpty ? 5 : (barValues.reduce(max) + 2).toDouble(),
            barTouchData: BarTouchData(enabled: true),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  getTitlesWidget: (value, meta) {
                    const labels = ['Pending', 'Completed'];
                    if (value.toInt() >= 0 && value.toInt() < labels.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          labels[value.toInt()],
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (value, meta) => Text(
                    value.toInt().toString(),
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
                  ),
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(show: true, drawVerticalLine: false),
            borderData: FlBorderData(show: false),
            barGroups: barValues.asMap().entries.map((entry) {
              return BarChartGroupData(
                x: entry.key,
                barRods: [
                  BarChartRodData(
                    toY: entry.value,
                    color: entry.key == 0 ? Colors.orange : Colors.green,
                    width: 22,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(6),
                      topRight: Radius.circular(6),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  /// 🔗 Dashboard Navigation
  Widget _dashboardClickableList() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth > 500;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: isDesktop ? 2 : 1,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: isDesktop ? 2.5 : 4.2,
          children: [
            _clickableCard(
              title: 'NCR',
              icon: Icons.report_problem_rounded,
              onTap: () => context.push(AppRoutes.ncrPage),
            ),
            _clickableCard(
              title: 'Customer Management',
              icon: Icons.business_rounded,
              onTap: () => context.push(AppRoutes.customerList),
            ),
            _clickableCard(
              title: 'User Management',
              icon: Icons.badge_rounded,
              onTap: () => context.push(AppRoutes.employeeList),
            ),
            _clickableCard(
              title: 'Policies & Procedures',
              icon: Icons.description_rounded,
              onTap: () => context.push(AppRoutes.documentList),
            ),
            _clickableCard(
              title: 'Policy History',
              icon: Icons.history_rounded,
              onTap: () => context.push(AppRoutes.globalVersionHistory),
            ),
            _clickableCard(
              title: 'Employees',
              icon: Icons.group_rounded,
              onTap: () => context.push(AppRoutes.employeeListing),
            ),
            //Todo Video
            _clickableCard(
              title: 'Training Videos',
              icon: Icons.video_library_rounded,
              onTap: () => context.push(AppRoutes.videoList),
            ),
            _clickableCard(
              title: 'Compliance Tasks',
              icon: Icons.assignment_rounded,
              onTap: () => context.push(AppRoutes.periodicComplianceList),
            ),
          ],
        );
      },
    );
  }

  Widget _clickableCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    Color themeColor = AppColors.kPrimaryColor;
    if (title.contains('NCR')) {
      themeColor = Colors.orange;
    } else if (title.contains('Customer')) {
      themeColor = Colors.indigo;
    } else if (title.contains('Policies')) {
      themeColor = Colors.teal;
    } else if (title.contains('History')) {
      themeColor = Colors.blueGrey;
    } else if (title.contains('Employees')) {
      themeColor = Colors.pinkAccent;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade50),
        boxShadow: [
          BoxShadow(
            color: themeColor.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: themeColor.withValues(alpha: 0.05),
            highlightColor: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: themeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: themeColor, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: AppColors.titleText,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          "System Management",
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade400,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: Colors.grey.shade200,
                  ),
                ],
              ),
            ),
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
        alignment: BarChartAlignment.spaceAround,
        maxY: values.isEmpty ? 5 : (values.reduce(max) + 2).toDouble(),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => Colors.blueGrey.withValues(alpha: 0.8),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                rod.toY.round().toString(),
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                const labels = ['Open', 'Progress', 'Closed'];
                if (value.toInt() >= 0 && value.toInt() < labels.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      labels[value.toInt()],
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Colors.grey.shade100, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barGroups: values.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value,
                gradient: LinearGradient(
                  colors: [barColor, barColor.withValues(alpha: 0.6)],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: 22,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: values.isEmpty ? 5 : (values.reduce(max) + 2).toDouble(),
                  color: Colors.grey.shade50,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
