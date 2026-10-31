import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iq_plus/common/routes/go_route.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/common/themes/responsive.dart';
import 'package:iq_plus/common/widgets/common_app_bar.dart';
import 'package:iq_plus/core/local_storage/hive_service.dart';
import 'package:iq_plus/di/service_locator.dart';
import 'package:iq_plus/features/auth/model/user_model.dart';
import 'package:iq_plus/features/auth/cubit/auth_cubit.dart';
import 'package:iq_plus/features/auth/repository/auth_repository.dart';
import 'package:iq_plus/features/auth/Login/change_password_dialog.dart';
import 'package:iq_plus/features/auth/cubit/change_password_cubit.dart';
import 'package:iq_plus/features/users/models/employe_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmployeeDashboardPage extends StatefulWidget {
  const EmployeeDashboardPage({super.key});

  @override
  State<EmployeeDashboardPage> createState() => _EmployeeDashboardPageState();
}

class _EmployeeDashboardPageState extends State<EmployeeDashboardPage> {
  UserModel? get user => getIt<HiveService>().getUser();
  late final bool isDirectEmailLogin = user?.password == null || user!.password.isEmpty;
  String? companyName;
  List<String> visibleModules = List.from(EmployeeUserModel.defaultModules);

  @override
  void initState() {
    super.initState();
    // 🚀 Check if user is blocked
    context.read<AuthCubit>().checkBlockStatus();
    _loadEmployeeData();
  }

  Future<void> _loadEmployeeData() async {
    if (user != null) {
      if (user!.customerId != null && user!.customerId!.isNotEmpty) {
        final customer = await AuthRepository(FirebaseFirestore.instance)
            .getCustomerById(user!.customerId!);
        if (mounted) {
          setState(() {
            companyName = customer?.companyName;
          });
        }
      }

      try {
        DocumentSnapshot? empDoc;
        if (user!.customerId != null && user!.customerId!.isNotEmpty) {
          empDoc = await FirebaseFirestore.instance
              .collection('customers')
              .doc(user!.customerId)
              .collection('employees')
              .doc(user!.userId)
              .get();
        }

        if (empDoc == null || !empDoc.exists) {
          final snap = await FirebaseFirestore.instance
              .collectionGroup('employees')
              .where('email', isEqualTo: user!.email)
              .limit(1)
              .get();
          if (snap.docs.isNotEmpty) {
            empDoc = snap.docs.first;
          }
        }

        if (empDoc != null && empDoc.exists) {
          final data = empDoc.data() as Map<String, dynamic>?;
          if (data != null && data['visibleModules'] != null) {
            final modulesList = List<String>.from(data['visibleModules']);
            if (mounted) {
              setState(() {
                visibleModules = modulesList;
              });
            }
          }
        }
      } catch (e) {
        debugPrint("Error loading employee visible modules: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: _buildDrawer(),
      appBar: const CommonAppBar(
        title: 'Employee Dashboard',
      ),
      body: Stack(
        children: [
          // 🎨 Optimized Dot Pattern Background (Non-interactive)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _DotPatternPainter(
                  dotColor: AppColors.kPrimaryColor.withValues(alpha: 0.05),
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Responsive(
              mobile: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  children: [
                    _neoModernHeader(),
                    const SizedBox(height: 40),
                    _dashboardGrid(context, isMobile: true),
                  ],
                ),
              ),
              desktop: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    _neoModernHeader(),
                    const SizedBox(height: 60),
                    _dashboardGrid(context, isMobile: false),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _neoModernHeader() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          height: 140,
          decoration: BoxDecoration(
            color: AppColors.kPrimaryColor,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: AppColors.kPrimaryColor.withValues(alpha: 0.3),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Stack(
              children: [
                Positioned(
                  right: -30,
                  top: -30,
                  child: CircleAvatar(
                    radius: 80,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: -20,
          left: 24,
          right: 24,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.kPrimaryColor.withValues(alpha: 0.1), width: 2),
                  ),
                  child: const CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.kPrimaryLightColor,
                    child: Icon(Icons.person_rounded, color: AppColors.kPrimaryColor, size: 30),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        user?.userName ?? 'Employee',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.titleText,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        user?.email ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.subText.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (companyName != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.kPrimaryLightColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      companyName!,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.kPrimaryColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: Stack(
        children: [
          // 🎨 Main Vibrant Gradient Background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.kPrimaryColor,
                    Color(0xFF8B5CF6), // Vibrant Violet
                    Colors.white,
                  ],
                  stops: [0.0, 0.4, 0.8],
                ),
              ),
            ),
          ),
          
          // 🎨 Decorative Glass Circles for Header Depth
          Positioned(
            top: -40,
            left: -40,
            child: _buildGlassCircle(150, Colors.white.withValues(alpha: 0.1)),
          ),
          Positioned(
            top: 100,
            right: -30,
            child: _buildGlassCircle(100, Colors.white.withValues(alpha: 0.05)),
          ),

          // 🎨 Background Watermark
          Positioned(
            bottom: -50,
            left: -50,
            child: Icon(
              Icons.dashboard_rounded,
              size: 300,
              color: AppColors.kPrimaryColor.withValues(alpha: 0.02),
            ),
          ),

          Column(
            children: [
              // 🚀 Stylish Header Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 70, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
                      ),
                      child: const CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person_rounded, color: AppColors.kPrimaryColor, size: 35),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      user?.userName ?? 'Employee',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                        shadows: [
                          Shadow(
                            color: Colors.black12,
                            offset: Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user?.email ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),

              // 📋 Menu Area
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 20,
                        offset: Offset(0, -10),
                      ),
                    ],
                  ),
                  child: ListView(
                    padding: EdgeInsets.zero,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      if (visibleModules.contains('NCR'))
                        _drawerItem(
                          icon: Icons.report_problem_rounded,
                          title: 'NCR',
                          onTap: () {
                            GoRouter.of(context).pop();
                            context.push(AppRoutes.ncrPage);
                          },
                        ),
                      if (visibleModules.contains('Visit Summary'))
                        _drawerItem(
                          icon: Icons.fact_check_rounded,
                          title: 'Visit Summary',
                          onTap: () {
                            GoRouter.of(context).pop();
                            context.push(AppRoutes.visitorSummaryList);
                          },
                        ),
                      if (visibleModules.contains('Policies & Procedures'))
                        _drawerItem(
                          icon: Icons.policy_rounded,
                          title: 'Policies & Procedures',
                          onTap: () {
                            GoRouter.of(context).pop();
                            context.push(AppRoutes.customerPolicyList);
                          },
                        ),
                      if (visibleModules.contains('Policy History'))
                        _drawerItem(
                          icon: Icons.manage_history_rounded,
                          title: 'Policy History',
                          onTap: () {
                            GoRouter.of(context).pop();
                            context.push(AppRoutes.globalVersionHistory);
                          },
                        ),
                      if (visibleModules.contains('Employees'))
                        _drawerItem(
                          icon: Icons.people_alt_rounded,
                          title: 'Employees',
                          onTap: () {
                            GoRouter.of(context).pop();
                            context.push(AppRoutes.employeeListing);
                          },
                        ),
                      if (visibleModules.contains('Training Videos')) ...[
                        _drawerItem(
                          icon: Icons.video_library,
                          title: 'My Training Videos',
                          onTap: () {
                            GoRouter.of(context).pop();
                            context.push(AppRoutes.employeeTraining);
                          },
                        ),
                        _drawerItem(
                          icon: Icons.assignment_turned_in,
                          title: 'My Training Results',
                          onTap: () {
                            GoRouter.of(context).pop();
                            context.push(AppRoutes.trainingResults);
                          },
                        ),
                      ],
                      if (visibleModules.contains('Compliance Tasks'))
                        _drawerItem(
                          icon: Icons.task_alt_rounded,
                          title: 'Compliance Tasks',
                          onTap: () {
                            GoRouter.of(context).pop();
                            context.push(AppRoutes.periodicComplianceList);
                          },
                        ),
                      if (!isDirectEmailLogin)
                        _drawerItem(
                          icon: Icons.lock_rounded,
                          title: 'Change Password',
                          onTap: () {
                            GoRouter.of(context).pop();
                            _showChangePasswordDialog();
                          },
                        ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                        child: Divider(height: 1, color: Colors.black12),
                      ),
                      _drawerItem(
                        icon: Icons.logout_rounded,
                        title: 'Logout',
                        color: Colors.redAccent,
                        onTap: () async {
                          final router = GoRouter.of(context);
                          await getIt<HiveService>().clearAll();
                          if (router.canPop()) {
                            router.pop();
                          }
                          router.go(AppRoutes.login);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: color != null ? color.withValues(alpha: 0.08) : AppColors.kPrimaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (color ?? AppColors.kPrimaryColor).withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          leading: Icon(icon, color: color ?? AppColors.kPrimaryColor, size: 22),
          title: Text(
            title,
            style: TextStyle(
              color: color ?? AppColors.titleText,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right_rounded, 
            size: 18, 
            color: (color ?? AppColors.kPrimaryColor).withValues(alpha: 0.3)
          ),
          onTap: onTap,
          dense: true,
        ),
      ),
    );
  }

  Widget _dashboardGrid(BuildContext context, {required bool isMobile}) {
    final List<_ActionItem> actions = [];

    if (visibleModules.contains('NCR')) {
      actions.add(
        _ActionItem(
          title: 'NCR',
          subtitle: 'Non-Conformance',
          icon: Icons.report_problem_rounded,
          color: const Color(0xFFEF4444),
          onTap: () => context.push(AppRoutes.ncrPage),
        ),
      );
    }

    if (visibleModules.contains('Visit Summary')) {
      actions.add(
        _ActionItem(
          title: 'Visit Summary',
          subtitle: 'Audit & Visits',
          icon: Icons.fact_check_rounded,
          color: const Color(0xFF0EA5E9),
          onTap: () => context.push(AppRoutes.visitorSummaryList),
        ),
      );
    }

    if (visibleModules.contains('Policies & Procedures')) {
      actions.add(
        _ActionItem(
          title: 'Policies & Procedures',
          subtitle: 'Company Docs',
          icon: Icons.auto_stories_rounded,
          color: const Color(0xFF6366F1),
          onTap: () => context.push(AppRoutes.customerPolicyList),
        ),
      );
    }

    if (visibleModules.contains('Policy History')) {
      actions.add(
        _ActionItem(
          title: 'Policy History',
          subtitle: 'Version History',
          icon: Icons.manage_history_rounded,
          color: const Color(0xFF8B5CF6),
          onTap: () => context.push(AppRoutes.globalVersionHistory),
        ),
      );
    }

    if (visibleModules.contains('Employees')) {
      actions.add(
        _ActionItem(
          title: 'Employees',
          subtitle: 'Team Directory',
          icon: Icons.people_alt_rounded,
          color: const Color(0xFFEC4899),
          onTap: () => context.push(AppRoutes.employeeListing),
        ),
      );
    }

    if (visibleModules.contains('Training Videos')) {
      actions.add(
        _ActionItem(
          title: 'My Training Videos',
          subtitle: 'Watch & Learn',
          icon: Icons.video_library_rounded,
          color: const Color(0xFF8B5CF6),
          onTap: () => context.push(AppRoutes.employeeTraining),
        ),
      );
      actions.add(
        _ActionItem(
          title: 'My Training Results',
          subtitle: 'Performance',
          icon: Icons.assignment_turned_in_rounded,
          color: const Color(0xFF10B981),
          onTap: () => context.push(AppRoutes.trainingResults),
        ),
      );
    }

    if (visibleModules.contains('Compliance Tasks')) {
      actions.add(
        _ActionItem(
          title: 'Compliance Tasks',
          subtitle: 'Tasks & Audits',
          icon: Icons.task_alt_rounded,
          color: const Color(0xFF14B8A6),
          onTap: () => context.push(AppRoutes.periodicComplianceList),
        ),
      );
    }

    if (!isDirectEmailLogin) {
      actions.add(
        _ActionItem(
          title: 'Change Password',
          subtitle: 'Security',
          icon: Icons.shield_rounded,
          color: const Color(0xFFF59E0B),
          onTap: _showChangePasswordDialog,
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 2 : 4,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: isMobile ? 1.15 : 1.35, // Balanced for visibility and style
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        return _compactActionTile(actions[index]);
      },
    );
  }

  Widget _compactActionTile(_ActionItem item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: item.color.withValues(alpha: 0.15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: item.color.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // 🎨 Decorative Background Tint
            Positioned.fill(
              child: Container(color: item.color.withValues(alpha: 0.03)),
            ),
            // 🎨 Large Background Watermark Icon
            Positioned(
              right: -15,
              bottom: -15,
              child: Icon(
                item.icon,
                size: 80,
                color: item.color.withValues(alpha: 0.04),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: item.onTap,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: item.color.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(item.icon, color: item.color, size: 24),
                      ),
                      const Spacer(),
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: AppColors.titleText,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.subText.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios_rounded, 
                               color: item.color.withValues(alpha: 0.4), size: 10),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return BlocProvider(
          create: (_) => CustomerPasswordCubit(getIt<AuthRepository>()),
          child: ChangePasswordDialog(
            customerId: user!.userId,
            isEmployee: true,
          ),
        );
      },
    );
  }
}

class _ActionItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _ActionItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _DotPatternPainter extends CustomPainter {
  final Color dotColor;
  _DotPatternPainter({required this.dotColor});

  @override
  void paint(Canvas canvas, Size size) {
    const double spacing = 30.0;
    final paint = Paint()
      ..color = dotColor
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final List<Offset> points = [];
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        points.add(Offset(x, y));
      }
    }
    canvas.drawPoints(PointMode.points, points, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
