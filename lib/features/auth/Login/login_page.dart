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
    return Background(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(child: roleTabWidget()),
            Responsive(
              mobile: MobileLoginScreen(selectedRole: selectedRole),
              desktop: Row(
                children: [
                  Expanded(
                    child: LoginScreenTopImage(selectedRole: selectedRole),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 450,
                          child: LoginForm(selectedRole: selectedRole),
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

  Widget roleTabWidget() {
    return Center(
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.only(bottom: 30),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF3E5F5), // light purple
                  Color(0xFFFFFFFF), // white
                ],
              ),
            ),
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
                      horizontal: 26,
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
                      color: isSelected ? null : Colors.transparent,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      roles[index],
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

        ],
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
        Row(
          children: [
            const Spacer(),
            Expanded(flex: 8, child: LoginForm(selectedRole: selectedRole)),
            const Spacer(),
          ],
        ),
      ],
    );
  }
}
