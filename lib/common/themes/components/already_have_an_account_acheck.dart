import 'package:flutter/material.dart';
import 'package:iq_plus/common/themes/app_colors.dart';

class AlreadyHaveAnAccountCheck extends StatelessWidget {
  final bool login;
  final VoidCallback press; // ✅ FIXED

  const AlreadyHaveAnAccountCheck({
    super.key,
    this.login = true,
    required this.press,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          login
              ? "Don’t have an Account ? "
              : "Already have an Account ? ",
          style: const TextStyle(color: AppColors.kPrimaryColor),
        ),
        InkWell(
          onTap: press, // ✅ NO ERROR NOW
          child: Text(
            login ? "Sign Up" : "Sign In",
            style: const TextStyle(
              color: AppColors.kPrimaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
