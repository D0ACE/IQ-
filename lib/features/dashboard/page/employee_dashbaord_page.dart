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
import 'package:iq_plus/features/auth/Login/change_password_dialog.dart';
import 'package:iq_plus/features/auth/cubit/change_password_cubit.dart';
import 'package:iq_plus/features/auth/repository/auth_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmployeeDashboardPage extends StatefulWidget {
  const EmployeeDashboardPage({super.key});

  @override
  State<EmployeeDashboardPage> createState() => _EmployeeDashboardPageState();
}

class _EmployeeDashboardPageState extends State<EmployeeDashboardPage> {
  final user = getIt<HiveService>().getUser();
  String? companyName;

  @override
  void initState() {
    super.initState();
    _loadCompanyName();
  }

  Future<void> _loadCompanyName() async {
    if (user?.customerId != null) {
      final customer = await AuthRepository(FirebaseFirestore.instance)
          .getCustomerById(user!.customerId!);
      if (mounted) {
        setState(() {
          companyName = customer?.companyName;
        });
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
                  dotColor: AppColors.kPrimaryColor.withOpacity(0.05),
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
                color: AppColors.kPrimaryColor.withOpacity(0.3),
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
                    backgroundColor: Colors.white.withOpacity(0.1),
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
                  color: Colors.black.withOpacity(0.06),
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
                    border: Border.all(color: AppColors.kPrimaryColor.withOpacity(0.1), width: 2),
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
                          color: AppColors.subText.withOpacity(0.7),
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
      backgroundColor: AppColors.scaffoldBg,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
            decoration: const BoxDecoration(
              gradient: AppColors.mainGradient,
              borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const CircleAvatar(
                    radius: 35,
                    backgroundColor: AppColors.kPrimaryLightColor,
                    child: Icon(Icons.dashboard_rounded, color: AppColors.purple, size: 35),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  user?.userName ?? 'Employee',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  user?.email ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _drawerItem(
                  icon: Icons.policy_rounded,
                  title: 'Policies & Procedures',
                  onTap: () {
                    GoRouter.of(context).pop();
                    context.push(AppRoutes.customerPolicyList);
                  },
                ),
                _drawerItem(
                  icon: Icons.video_library,
                  title: 'My Training Videos',
                  onTap: () {
                    GoRouter.of(context).pop();
                    context.push(AppRoutes.employeeTraining);
                  },
                ),
                _drawerItem(
                  icon: Icons.lock_rounded,
                  title: 'Change Password',
                  onTap: () {
                    GoRouter.of(context).pop();
                    _showChangePasswordDialog();
                  },
                ),
                const Divider(height: 40, thickness: 1, indent: 10, endIndent: 10),
                _drawerItem(
                  icon: Icons.logout_rounded,
                  title: 'Logout',
                  color: Colors.redAccent,
                  onTap: () {
                    getIt<HiveService>().clearAll();
                    GoRouter.of(context).pop();
                    context.go(AppRoutes.login);
                  },
                ),
              ],
            ),
          ),
        ],
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
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: color != null ? color.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          leading: Icon(icon, color: color ?? AppColors.purple),
          title: Text(
            title,
            style: TextStyle(
              color: color ?? AppColors.titleText,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: const Icon(Icons.chevron_right, size: 20),
          onTap: onTap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _dashboardGrid(BuildContext context, {required bool isMobile}) {
    final actions = [
      _ActionItem(
        title: 'Policies',
        subtitle: 'View company docs',
        icon: Icons.auto_stories_rounded,
        color: const Color(0xFF6366F1), // Indigo
        onTap: () => context.push(AppRoutes.customerPolicyList),
      ),
      _ActionItem(
        title: 'Trainings',
        subtitle: 'Watch & Learn',
        icon: Icons.video_library_rounded,
        color: const Color(0xFF8B5CF6), // Violet
        onTap: () => context.push(AppRoutes.employeeTraining),
      ),
      _ActionItem(
        title: 'Results',
        subtitle: 'View performance',
        icon: Icons.assignment_turned_in_rounded,
        color: const Color(0xFF10B981), // Emerald
        onTap: () => context.push(AppRoutes.trainingResults),
      ),
      _ActionItem(
        title: 'Security',
        subtitle: 'Update settings',
        icon: Icons.shield_rounded,
        color: const Color(0xFFF59E0B), // Amber
        onTap: _showChangePasswordDialog,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 2 : 4,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: isMobile ? 0.85 : 1,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        return _glowActionTile(actions[index]);
      },
    );
  }

  Widget _glowActionTile(_ActionItem item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: item.color.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: item.onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(item.icon, color: item.color, size: 28),
                ),
                const Spacer(),
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.titleText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.subText.withOpacity(0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
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
