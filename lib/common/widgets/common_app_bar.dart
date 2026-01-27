import 'package:flutter/material.dart';
import 'package:iq_plus/common/themes/app_colors.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const CommonAppBar({
    super.key,
    required this.title,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.titleText,
        ),
      ),
      iconTheme: const IconThemeData(
        color: AppColors.kPrimaryColor,
      ),
      actions: actions,
    );
  }

  /// Required when using custom AppBar
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
