import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iq_plus/common/app_widget/app_text_field_widget.dart';
import 'package:iq_plus/common/routes/go_route.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/common/themes/app_ui_helper.dart';
import 'package:iq_plus/common/utility/app_validation.dart';
import 'package:iq_plus/features/auth/cubit/change_password_cubit.dart';
import 'package:iq_plus/features/auth/cubit/change_password_state.dart';

class ChangePasswordDialog extends StatefulWidget {
  final String customerId;
  final bool isEmployee;

  const ChangePasswordDialog({
    super.key,
    required this.customerId,
    this.isEmployee = false,
  });

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();

  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.read<CustomerPasswordCubit>().updatePassword(
        customerId: widget.customerId,
        newPassword: passwordController.text.trim(),
        isEmployee: widget.isEmployee,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CustomerPasswordCubit, CustomerPasswordState>(
      listener: (context, state) {
        if (state is CustomerPasswordLoading) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Center(child: CircularProgressIndicator()),
          );
        }

        if (state is CustomerPasswordSuccess) {
          // close loader
          Navigator.of(context, rootNavigator: true).pop();

          // close dialog
          Navigator.of(context).pop();

          // go to dashboard (replace stack)
          context.go(widget.isEmployee ? AppRoutes.employeeDashboard : AppRoutes.customerDashboard);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Password updated successfully")),
          );
        }

        if (state is CustomerPasswordError) {
          Navigator.of(context, rootNavigator: true).pop(); // close loader

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text("Change Password"),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// 🔐 New Password
              AppTextFieldWidget(
                hintText: "New Password",
                validator: AppValidation.currentPasswordValidator,
                textFieldController: passwordController,
                isPasswordTextField: true,
                inputFormatters: [LengthLimitingTextInputFormatter(20)],
                prefixIconWidget: const Padding(
                  padding: EdgeInsets.all(defaultPadding),
                  child: Icon(
                    Icons.lock,
                    color: AppColors.kPrimaryColor,
                    size: 23,
                  ),
                ),
                contentPadding: const EdgeInsets.fromLTRB(10, 17, 10, 17),
                disableFocusBorder: true,
              ),

              const SizedBox(height: defaultPadding),

              /// 🔐 Confirm Password
              AppTextFieldWidget(
                hintText: "Confirm Password",
                validator: (value) => AppValidation.confirmPasswordValidator(
                  value,
                  passwordController.text,
                ),
                textFieldController: confirmPasswordController,
                isPasswordTextField: true,
                inputFormatters: [LengthLimitingTextInputFormatter(20)],
                prefixIconWidget: const Padding(
                  padding: EdgeInsets.all(defaultPadding),
                  child: Icon(
                    Icons.lock_outline,
                    color: AppColors.kPrimaryColor,
                    size: 23,
                  ),
                ),
                contentPadding: const EdgeInsets.fromLTRB(10, 17, 10, 17),
                disableFocusBorder: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(onPressed: _submit, child: const Text("Update")),
        ],
      ),
    );
  }
}
