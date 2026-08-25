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
import 'package:iq_plus/features/customer_mme/cubit/customer_mme_cubit.dart';
import 'package:iq_plus/features/customer_mme/cubit/customer_mme_state.dart';
import 'package:iq_plus/features/dashboard/page/visit_summary/cubit/visitor_summary_cubit.dart';
import 'package:iq_plus/features/dashboard/page/visit_summary/cubit/visitor_summary_state.dart';
import 'package:iq_plus/ncr_form/ncr_provider.dart';
import 'package:iq_plus/features/auth/model/customer_model.dart';


class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with TickerProviderStateMixin {
  ConsultantModel? assignedConsultant;
  bool isConsultantLoading = false;
  CustomerModel? customerModel;
  final user = getIt<HiveService>().getUser();
  final customer = getIt<HiveService>().getCustomer();

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

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    final hiveService = getIt<HiveService>();
    customerModel = hiveService.getCustomer();

    if ((customerModel?.customerId ?? '').isNotEmpty) {
      context.read<CustomerMMECubit>().loadMME(customerModel!.customerId);
    }

    // 🚀 Start listening to NCR data for the graph
    context.read<NcrProvider>().listenToNcrs();

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
      appBar: CommonAppBar(
        title: '${customerModel?.companyName ?? 'Partner'} Dashboard',
      ),
      body: Stack(
        children: [
          // Decorative background elements
          Positioned(
            top: -50,
            right: -50,
            child: _buildDecorativeCircle(200, AppColors.kPrimaryColor.withValues(alpha: 0.03)),
          ),
          Positioned(
            bottom: 100,
            left: -30,
            child: _buildDecorativeCircle(150, AppColors.secondary.withValues(alpha: 0.03)),
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
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
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
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.kPrimaryColor,
            AppColors.kPrimaryColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.kPrimaryColor.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.waves_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hello, ${customerModel?.companyName ?? 'Partner'}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      "Welcome back to your command center",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 🌈 Drawer
  Widget _buildBeautifulDrawer() {
    final String companyName = customerModel?.companyName ?? 'Your Company';
    final String email = customer?.email ?? 'portal@iqplus.com';

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
          // Modern Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
            decoration: BoxDecoration(
              color: AppColors.kPrimaryColor,
              borderRadius: const BorderRadius.only(topRight: Radius.circular(30)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.kPrimaryColor.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.dashboard_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(height: 16),
                Text(
                  companyName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              children: [
                _drawerSectionTitle('ACCOUNT'),
                _profileDropdown(context),
                
                const SizedBox(height: 16),
                _drawerSectionTitle('OPERATIONS'),
                _drawerItem(
                  icon: Icons.devices_rounded,
                  title: 'MME Tracker',
                  onTap: () {
                    if ((customerModel?.customerId ?? '').isNotEmpty) {
                      GoRouter.of(context).pop();
                      context.push(AppRoutes.customerMMEList, extra: customerModel!.customerId);
                    }
                  },
                ),
                _drawerItem(
                  icon: Icons.description_rounded,
                  title: 'Policies & Procedures',
                  onTap: () {
                    GoRouter.of(context).pop();
                    context.push(AppRoutes.customerPolicyList);
                  },
                ),
                _drawerItem(
                  icon: Icons.history_edu_rounded,
                  title: 'Policy History',
                  onTap: () {
                    GoRouter.of(context).pop();
                    context.push(AppRoutes.globalVersionHistory);
                  },
                ),
                _drawerItem(
                  icon: Icons.group_add_rounded,
                  title: 'Our Employees',
                  onTap: () {
                    GoRouter.of(context).pop();
                    context.push(AppRoutes.employeeListing);
                  },
                ),
                //Todo Video
                /*_drawerItem(
                  icon: Icons.video_library_outlined,
                  title: 'Training Videos',
                  onTap: () {
                    GoRouter.of(context).pop();
                    context.push(AppRoutes.videoList);
                  },
                ),*/

                const SizedBox(height: 16),
                _drawerSectionTitle('SUPPORT'),
                _drawerItem(
                  icon: Icons.alternate_email_rounded,
                  title: 'Contact Us',
                  onTap: () {
                    GoRouter.of(context).pop();
                    GoRouter.of(context).push(AppRoutes.contactUs);
                  },
                ),
                _drawerItem(
                  icon: Icons.forum_rounded,
                  title: 'Support Chat',
                  onTap: () {
                    GoRouter.of(context).pop();
                    context.push(AppRoutes.chat);
                  },
                ),
              ],
            ),
          ),

          // Footer Logout
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: _drawerItem(
              icon: Icons.logout_rounded,
              title: 'Sign Out',
              color: Colors.redAccent,
              onTap: () {
                getIt<HiveService>().clearAll();
                GoRouter.of(context).pop();
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

  Widget _profileDropdown(BuildContext context) {
    final hiveService = getIt<HiveService>();
    final customer = hiveService.getCustomer();

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        leading: Icon(Icons.person_outline_rounded, color: Colors.grey.shade600, size: 22),
        title: Text(
          'My Profile',
          style: TextStyle(color: Colors.grey.shade700, fontSize: 14, fontWeight: FontWeight.w600),
        ),
        children: [
          _drawerSubItem(
            title: "View Profile",
            onTap: () async {
              GoRouter.of(context).pop();
              if (customer == null) return;
              final result = await context.push(AppRoutes.customerProfile, extra: customer) as CustomerModel?;
              if (result != null) setState(() => customerModel = result);
            },
          ),
          _drawerSubItem(
            title: "Edit Profile",
            onTap: () async {
              GoRouter.of(context).pop();
              if (customer == null) return;
              await context.push(AppRoutes.customerProfileEdit, extra: customer);
            },
          ),
        ],
      ),
    );
  }

  Widget _drawerSubItem({required String title, required VoidCallback onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 48),
      title: Text(
        title,
        style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
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

  Widget _buildStatsColumn() {
    return BlocBuilder<CustomerMMECubit, CustomerMMEState>(
      builder: (context, state) {
        if (state is CustomerMMELoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is CustomerMMELoaded) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Equipment Monitoring'),
              const SizedBox(height: 14),
              _statCard(
                'Monitoring and Measuring Equipment',
                '${state.list.length}',
                AppColors.purple,
                () {
                  if ((customerModel?.customerId ?? '').isNotEmpty) {
                    context.push(
                      AppRoutes.customerMMEList,
                      extra: customerModel!.customerId,
                    );
                  }
                },
              ),
            ],
          );
        } else {
          return const SizedBox();
        }
      },
    );
  }

  Widget _statCard(String title,
      String value,
      Color color,
      GestureTapCallback onTap,) {
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
                      colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.05)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    Icons.precision_manufacturing_rounded,
                    color: color,
                    size: 30,
                  ),
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
        Container(
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
                  const Text(
                    "NCR Trends",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.kPrimaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      "Real-time",
                      style: TextStyle(color: AppColors.kPrimaryColor, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 250,
                child: AnimatedBarChart(
                  values: barValues,
                  barColor: AppColors.kPrimaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

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
              title: 'Risk',
              icon: Icons.shield_rounded,
              onTap: () {},
            ),
            _clickableCard(
              title: 'Next Visit',
              icon: Icons.event_available_rounded,
              onTap: () => showNextVisitDialog(),
            ),
            _clickableCard(
              title: 'Next Audit',
              icon: Icons.fact_check_rounded,
              onTap: () {},
            ),
            _clickableCard(
              title: 'Next Training',
              icon: Icons.school_rounded,
              onTap: () {},
            ),
            _clickableCard(
              title: 'Policies & Procedures',
              icon: Icons.description_rounded,
              onTap: () => context.push(AppRoutes.customerPolicyList),
            ),
            _clickableCard(
              title: 'Our Employees',
              icon: Icons.group_rounded,
              onTap: () => context.push(AppRoutes.employeeListing),
            ),
            //Todo Video
            /*_clickableCard(
              title: 'Training Videos',
              icon: Icons.video_library_rounded,
              onTap: () => context.push(AppRoutes.videoList),
            ),*/
            _clickableCard(
              title: 'All Policies Version History',
              icon: Icons.history_rounded,
              onTap: () => context.push(AppRoutes.globalVersionHistory),
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
    // Internal theme logic to keep the function signature identical
    Color themeColor = AppColors.kPrimaryColor;
    if (title.contains('NCR')) {
      themeColor = Colors.orange;
    } else if (title.contains('Risk')) {
      themeColor = Colors.redAccent;
    }
    else if (title.contains('Visit')) {
      themeColor = Colors.indigo;
    }
    else if (title.contains('Audit')) {themeColor = Colors.teal;}
    else if (title.contains('Training')) {
      themeColor = Colors.amber.shade700;
    }
    else if (title.contains('Employees')) {
      themeColor = Colors.pinkAccent;
    }
    else if (title.contains('Policies')) {
      themeColor = AppColors.purple;
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
                          "Explore details",
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

  void showNextVisitDialog() {
    showDialog(
      context: context,
      builder: (_) =>
          NextVisitDateDialog(nextVisitDate: customer?.nextVisitDate),
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
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.shade100,
            strokeWidth: 1,
          ),
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

class NextVisitDateDialog extends StatelessWidget {
  final String? nextVisitDate;

  const NextVisitDateDialog({super.key, required this.nextVisitDate});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      child: Container(
        width: MediaQuery
            .of(context)
            .size
            .width / 4,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            /// Header
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Next Visit Date',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close, size: 20),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            /// Date Card
            BlocBuilder<VisitorSummaryCubit, VisitorSummaryState>(
              bloc: context.read<VisitorSummaryCubit>()
                ..loadVisitorSummariesForCustomer(),
              builder: (context, state) {
                if (state is VisitorSummaryLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is VisitorSummaryLoaded) {
                  if (state.list.isEmpty) {
                    return const Center(
                      child: Text(
                        'No visit date found',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }
                  return Expanded(
                    child: ListView.separated(
                        itemCount: state.list.length,
                        separatorBuilder: (_, _) =>
                            SizedBox(
                              height: 10,
                            ),
                        itemBuilder: (context, index) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: 18,
                              horizontal: 14,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.kPrimaryLightColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppColors.kPrimaryColor),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [

                                /// Date (Top Center)
                                Center(
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today,
                                        size: 26,
                                        color: AppColors.kPrimaryColor,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        state.list[index].visitDate ??
                                            'Not Assigned',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.kPrimaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 16),
                                Divider(
                                    color: AppColors.kPrimaryColor.withValues(alpha:
                                        0.3)),

                                const SizedBox(height: 10),

                                /// Purpose
                                _infoRow(
                                  icon: Icons.flag,
                                  label: 'Purpose',
                                  value: state.list[index].purpose,
                                ),

                                /// Officer Name
                                _infoRow(
                                  icon: Icons.person,
                                  label: 'Officer',
                                  value: state.list[index].officerName,
                                ),

                                /// Department
                                _infoRow(
                                  icon: Icons.apartment,
                                  label: 'Department',
                                  value: state.list[index].department,
                                ),

                                /// Location
                                _infoRow(
                                  icon: Icons.location_on,
                                  label: 'Location',
                                  value: state.list[index].location,
                                ),
                              ],
                            ),
                          );
                        }
                    ),
                  );
                }
                if (state is VisitorSummaryError) {
                  return Center(
                    child: Text(
                      state.error,
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                return const SizedBox();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    String? value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.kPrimaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: Colors.black),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: value?.isNotEmpty == true ? value : '—',
                    style: TextStyle(color: Colors.grey.shade800),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

}
