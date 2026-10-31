import 'package:flutter/material.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/common/themes/app_strings.dart';

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final double radiusSize;
  final bool isLoading;

  const GradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.radiusSize = 10,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed, // ✅ DISABLE WHEN LOADING
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isLoading
                ? [
                    AppColors.buttonDarkGreen.withValues(alpha: 0.6),
                    AppColors.buttonDarkGreen.withValues(alpha: 0.6),
                  ]
                : [
                    AppColors.buttonDarkGreen,
                    AppColors.buttonDarkGreen,
                  ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(radiusSize),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowColorBrand,
              blurRadius: 20,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.loginAccent,
                  ),
                )
              : Text(
                  text,
                  style: const TextStyle(
                    color: AppColors.buttonYellow,
                    fontSize: 16,
                    fontFamily: AppFonts.fontOpenSansBold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}
