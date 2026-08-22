import 'package:flutter/material.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/common/themes/app_theme_data.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool centerTitle;

  const CommonAppBar({
    super.key,
    required this.title,
    this.actions,
    this.centerTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.mainGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: centerTitle,

        // Title
        title: Text(
          title,
          style: AppThemeData.appBarTitleTextStyle.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.grey90TextColor, // Dark contrast
            shadows: const [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 3,
                color: Colors.black26,
              ),
            ],
          ),
        ),

        // Back & Icons
        iconTheme: const IconThemeData(color: AppColors.whiteColor),

        actions: actions,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(70);
}
