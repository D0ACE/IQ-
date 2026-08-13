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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      drawer: _buildDrawer(),
      appBar: const CommonAppBar(
        title: 'Employee Dashboard',
      ),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Responsive(
          mobile: SingleChildScrollView(
            child: Column(
              children: [
                _welcomeCard(),
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
                  child: _welcomeCard(),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 3,
                  child: _dashboardClickableList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _welcomeCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: AppColors.mainGradient,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: AppColors.purple, size: 35),
            ),
            const SizedBox(height: 16),
            Text(
              "Welcome, ${user?.userName ?? 'Employee'}",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              user?.email ?? "",
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(gradient: AppColors.mainGradient),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.dashboard, color: AppColors.purple),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.userName ?? 'Employee',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    user?.email ?? '',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            _drawerItem(
              icon: Icons.policy_outlined,
              title: 'My Company Policies',
              onTap: () {
                GoRouter.of(context).pop();
                context.push(AppRoutes.customerPolicyList);
              },
            ),
            _drawerItem(
              icon: Icons.lock_outline,
              title: 'Change Password',
              onTap: () {
                GoRouter.of(context).pop();
                _showChangePasswordDialog();
              },
            ),
            _drawerItem(
              icon: Icons.logout,
              title: 'Logout',
              onTap: () {
                getIt<HiveService>().clearAll();
                GoRouter.of(context).pop();
                context.go(AppRoutes.login);
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
    required VoidCallback onTap,
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

  Widget _dashboardClickableList() {
    return Column(
      children: [
        _clickableCard(
          title: 'Policies & Procedures',
          icon: Icons.policy,
          onTap: () => context.push(AppRoutes.customerPolicyList),
        ),
        _clickableCard(
          title: 'Change Password',
          icon: Icons.lock_reset,
          onTap: _showChangePasswordDialog,
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
        elevation: 6,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
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
