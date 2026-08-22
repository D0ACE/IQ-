import 'package:flutter/material.dart';
import 'package:iq_plus/common/app_widget/asset_icon_widget.dart';
import 'package:iq_plus/common/themes/app_assets.dart';
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
      children: [
        Text(
          "${Utility.getRoleNameLogin(selectedRole)} Login",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 28 : 35,
          ),
        ),
         SizedBox(height: defaultPadding * 2),
        Row(
          children: [
            const Spacer(),
            Expanded(
              flex: 8,
              child: AssetIconWidget(icon:AppAssets.login,height: null,width: null,),
            ),
            const Spacer(),
          ],
        ),
        const SizedBox(height: defaultPadding * 2),
      ],
    );
  }
}
