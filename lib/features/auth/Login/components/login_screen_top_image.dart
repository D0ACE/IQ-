import 'dart:math';
import 'package:flutter/material.dart';
import 'package:iq_plus/common/app_widget/asset_icon_widget.dart';
import 'package:iq_plus/common/themes/app_assets.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/common/themes/responsive.dart';
import 'package:iq_plus/common/utility/utility.dart';

class LoginScreenTopImage extends StatelessWidget {
  final int selectedRole;
  const LoginScreenTopImage({
    super.key,
    required this.selectedRole
  });

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 🚀 Floating Identity Pod
        _buildIdentityPod(isMobile),
        
        const SizedBox(height: 50),
        
        // 🚀 Technical Metadata
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: Column(
            key: ValueKey(selectedRole),
            children: [
              Text(
                "SYSTEM INTERFACE ${selectedRole + 1}",
                style: const TextStyle(
                  fontSize: 8,
                  letterSpacing: 4,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                Utility.getRoleNameLogin(selectedRole).toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                  color: Color(0xFF1E293B),
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 24,
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.kPrimaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIdentityPod(bool isMobile) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(seconds: 4),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, (10 * sin(value * 2 * pi)).toDouble()),
          child: Container(
            height: isMobile ? 220 : 340,
            width: isMobile ? 220 : 340,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.kPrimaryColor.withValues(alpha: 0.08),
                  blurRadius: 50,
                  spreadRadius: 10,
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.5),
                  blurRadius: 20,
                  spreadRadius: -10,
                ),
              ],
            ),
            child: Center(
              child: Hero(
                tag: 'login_illustration',
                child: AssetIconWidget(
                  icon: AppAssets.login,
                  height: isMobile ? 160 : 280,
                  width: null,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
