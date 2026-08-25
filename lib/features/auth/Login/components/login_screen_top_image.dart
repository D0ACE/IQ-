import 'package:flutter/material.dart';
import 'package:iq_plus/common/app_widget/asset_icon_widget.dart';
import 'package:iq_plus/common/themes/app_assets.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/common/themes/app_ui_helper.dart';
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
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            Utility.getRoleNameLogin(selectedRole).toUpperCase(),
            key: ValueKey(selectedRole),
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 3,
              fontWeight: FontWeight.w900,
              color: AppColors.kPrimaryColor.withValues(alpha: 0.5),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "Access Portal",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: isMobile ? 32 : 42,
            color: AppColors.titleText,
            letterSpacing: -1,
            height: 1,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.kPrimaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: defaultPadding * 2.5),
        Row(
          children: [
            const Spacer(),
            Expanded(
              flex: 10,
              child: AssetIconWidget(
                icon: AppAssets.login,
                height: isMobile ? 180 : 280,
                width: null,
              ),
            ),
            const Spacer(),
          ],
        ),
      ],
    );
  }
}
