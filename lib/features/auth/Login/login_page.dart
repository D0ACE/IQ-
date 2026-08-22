import 'package:flutter/material.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/common/themes/components/background.dart';
import 'package:iq_plus/common/themes/responsive.dart';

import 'components/login_form.dart';
import 'components/login_screen_top_image.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  int selectedRole = 0;

  final List<String> roles = [
    'Super Admin',
    'Admin',
    'Consultant',
    'Customer',
  ];

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = Responsive.isDesktop(context);

    return Background(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 1100 : 500,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                roleTabWidget(),
                const SizedBox(height: 10),
                Responsive(
                  mobile: MobileLoginScreen(selectedRole: selectedRole),
                  desktop: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: LoginScreenTopImage(selectedRole: selectedRole),
                      ),
                      const SizedBox(width: 40),
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 450),
                            child: LoginForm(selectedRole: selectedRole),
                          ),
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
    );
  }

  Widget roleTabWidget() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(roles.length, (index) {
              final bool isSelected = selectedRole == index;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedRole = index;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [
                              AppColors.kPrimaryLightColor,
                              AppColors.kPrimaryColor,
                            ],
                          )
                        : null,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    roles[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class MobileLoginScreen extends StatelessWidget {
  final int selectedRole;
  const MobileLoginScreen({super.key, required this.selectedRole});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        LoginScreenTopImage(selectedRole: selectedRole),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: LoginForm(selectedRole: selectedRole),
        ),
      ],
    );
  }
}
