import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iq_plus/common/app_widget/app_text_field_widget.dart';
import 'package:iq_plus/common/app_widget/common_gradient_button.dart';
import 'package:iq_plus/common/routes/go_route.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/common/themes/app_const.dart';
import 'package:iq_plus/common/themes/components/already_have_an_account_acheck.dart';
import 'package:iq_plus/common/utility/app_validation.dart';
import 'package:iq_plus/di/service_locator.dart';
import 'package:iq_plus/features/auth/Login/change_password_dialog.dart';
import 'package:iq_plus/features/auth/cubit/auth_cubit.dart';
import 'package:iq_plus/features/auth/cubit/change_password_cubit.dart';
import 'package:iq_plus/features/auth/cubit/sate/auth_state.dart';
import 'package:iq_plus/features/auth/customer_onboarding/onboarding_mode.dart';
import 'package:iq_plus/features/auth/repository/auth_repository.dart';

import 'package:iq_plus/features/admin/customers/widgets/customer_dropdown_widget.dart';
import 'package:iq_plus/features/auth/model/customer_model.dart';
import 'package:iq_plus/features/users/models/employe_user.dart';
import 'package:iq_plus/features/auth/model/user_model.dart';
import 'package:iq_plus/core/local_storage/hive_service.dart';

class LoginForm extends StatefulWidget {
  final int selectedRole;
  const LoginForm({super.key, required this.selectedRole});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController _employeeLoginEmailController =
      TextEditingController();
  CustomerModel? _loginCustomer;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final List<String> roles = ['Super Admin', 'Admin', 'Consultant', 'Customer'];

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    _employeeLoginEmailController.dispose();
    super.dispose();
  }

  Future<void> _loginAsEmployee() async {
    final email = _employeeLoginEmailController.text.trim();
    if (_loginCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a customer company")),
      );
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid email address")),
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final firestore = FirebaseFirestore.instance;
      final employeesRef = firestore
          .collection('customers')
          .doc(_loginCustomer!.customerId)
          .collection('employees');

      final query = await employeesRef
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      String employeeId;
      String userName;

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        employeeId = doc.id;
        final data = doc.data();
        userName = data['userName'] ?? email.split('@').first;
        await doc.reference.update({'isOtherEmployee': true});
      } else {
        userName = email.split('@').first;
        final newEmpDoc = await employeesRef.add({
          'userName': userName,
          'email': email,
          'phoneNumber': '',
          'roleId': AppConst.employeeRole,
          'password': '',
          'blockStatus': false,
          'activeUser': true,
          'customerId': _loginCustomer!.customerId,
          'isOtherEmployee': true,
          'createdAt': FieldValue.serverTimestamp(),
          'visibleModules': EmployeeUserModel.defaultModules,
        });
        employeeId = newEmpDoc.id;
      }

      await getIt<HiveService>().clearAll();
      await getIt<HiveService>().saveUser(
        UserModel(
          userId: employeeId,
          userName: userName,
          email: email,
          phoneNumber: '',
          password: '',
          roleId: AppConst.employeeRole,
          activeUser: true,
          blockStatus: false,
          fcmToken: '',
          customerId: _loginCustomer!.customerId,
          createdAt: DateTime.now(),
        ),
      );

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        GoRouter.of(context).go(AppRoutes.employeeDashboard);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: AppColors.loginError,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AuthCubit>(),
      child: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            if (state.roleId == "0") {
              GoRouter.of(context).go(AppRoutes.superAdminDashboard);
            } else if (state.roleId == "1") {
              GoRouter.of(context).go(AppRoutes.adminDashboard);
            } else if (state.roleId == "2") {
              GoRouter.of(context).go(AppRoutes.consultantDashboard);
            } else if (state.roleName == AppConst.isAutoGeneratedPassCustomer) {
              showChangePasswordDialog(
                context,
                state.customerId,
                isEmployee: false,
              );
            } else if (state.roleName == AppConst.isAutoGeneratedPassEmployee) {
              showChangePasswordDialog(
                context,
                state.customerId,
                isEmployee: true,
              );
            } else if (state.roleName == AppConst.isCustomer) {
              GoRouter.of(context).go(AppRoutes.customerDashboard);
            } else if (state.roleName == AppConst.isEmployee) {
              GoRouter.of(context).go(AppRoutes.employeeDashboard);
            }
          }

          if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppColors.loginBackground,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                content: Text(
                  state.message,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            );
          }
        },
        child: _buildForm(context),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topCenter,
          minHeight: 0,
          maxHeight: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 🚀 Modern Heading
              const Text(
                "Access Portal",
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: AppColors.loginTextPrimary,
                  letterSpacing: -2,
                  height: 1,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Manage your compliance as ${roles[widget.selectedRole]}",
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.loginTextSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 50),

              // 📧 Email Field
              _buildFieldHeader("SYSTEM IDENTIFIER"),
              const SizedBox(height: 10),
              _buildAnimatedField(
                index: 1,
                child: AppTextFieldWidget(
                  keyboardType: TextInputType.emailAddress,
                  hintText: "Your secure email",
                  textFieldController: emailController,
                  validator: AppValidation.checkEmailValidation,
                  prefixIconWidget: const Icon(
                    Icons.alternate_email_rounded,
                    size: 18,
                    color: AppColors.loginTextMuted,
                  ),
                  textStyle: const TextStyle(
                    color: AppColors.loginTextPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: _inputDecoration(),
                ),
              ),

              const SizedBox(height: 28),

              // 🔑 Password Field
              _buildFieldHeader("ENCRYPTED KEY"),
              const SizedBox(height: 10),
              _buildAnimatedField(
                index: 2,
                child: AppTextFieldWidget(
                  hintText: "Enter passkey",
                  validator: AppValidation.currentPasswordValidator,
                  textFieldController: passwordController,
                  isPasswordTextField: true,
                  prefixIconWidget: const Icon(
                    Icons.lock_rounded,
                    size: 18,
                    color: AppColors.loginTextMuted,
                  ),
                  textStyle: const TextStyle(
                    color: AppColors.loginTextPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: _inputDecoration(),
                ),
              ),

              const SizedBox(height: 35),

              // ⚡ Action Button
              _buildAnimatedField(
                index: 3,
                child: BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, state) {
                    return GradientButton(
                      text: state is AuthLoading
                          ? "AUTHORIZING..."
                          : "START SESSION",
                      onPressed: state is AuthLoading
                          ? () {}
                          : () => onTapContinue(context),
                      radiusSize: AppConst.radiusLg,
                    );
                  },
                ),
              ),

              // 🔗 Secondary Action (Customer only)
              if (widget.selectedRole == 3) ...[
                const SizedBox(height: 45),
                _buildAnimatedField(
                  index: 4,
                  child: Column(
                    children: [
                      const Text(
                        "UNAUTHORIZED?",
                        style: TextStyle(
                          color: AppColors.loginBorder,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 20),
                      AlreadyHaveAnAccountCheck(
                        login: true,
                        press: () => GoRouter.of(context).push(
                          AppRoutes.customerOnboarding,
                          extra: OnboardingMode.create,
                        ),
                      ),
                      const SizedBox(height: 35),
                      const Divider(color: AppColors.loginBorder),
                      const SizedBox(height: 20),
                      const Text(
                        "OTHER EMPLOYEE LOGIN PORTAL",
                        style: TextStyle(
                          color: AppColors.loginTextSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      CustomerDropdownWidget(
                        selectedCustomer: _loginCustomer,
                        onChanged: (cust) {
                          setState(() {
                            _loginCustomer = cust;
                          });
                        },
                        hint: "Select Customer Company",
                      ),
                      const SizedBox(height: 16),
                      AppTextFieldWidget(
                        keyboardType: TextInputType.emailAddress,
                        hintText: "Employee Email Address",
                        textFieldController: _employeeLoginEmailController,
                        prefixIconWidget: const Icon(
                          Icons.person_outline_rounded,
                          size: 18,
                          color: AppColors.loginTextMuted,
                        ),
                        textStyle: const TextStyle(
                          color: AppColors.loginTextPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: _inputDecoration(),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _loginAsEmployee,
                          icon: const Icon(Icons.login_rounded, size: 18),
                          label: const Text(
                            "ACCESS EMPLOYEE PORTAL",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.buttonDarkGreen,
                            foregroundColor: AppColors.buttonYellow,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldHeader(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w900,
        color: AppColors.loginTextMuted,
        letterSpacing: 2,
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      hintStyle: TextStyle(
        color: AppColors.loginTextPrimary.withValues(alpha: 0.35),
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 22, horizontal: 24),
      filled: true,
      fillColor: AppColors.loginInputSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConst.radiusLg),
        borderSide: BorderSide(color: AppColors.loginBorder, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConst.radiusLg),
        borderSide: BorderSide(color: AppColors.loginBorder, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConst.radiusLg),
        borderSide: const BorderSide(color: AppColors.loginPrimary, width: 2),
      ),
    );
  }

  Widget _buildAnimatedField({required int index, required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + (index * 150)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  void onTapContinue(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      context.read<AuthCubit>().login(
        emailController.text.trim(),
        passwordController.text.trim(),
        widget.selectedRole,
      );
    }
  }

  void showChangePasswordDialog(
    BuildContext context,
    String customerId, {
    bool isEmployee = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return BlocProvider(
          create: (_) =>
              CustomerPasswordCubit(AuthRepository(FirebaseFirestore.instance)),
          child: ChangePasswordDialog(
            customerId: customerId,
            isEmployee: isEmployee,
          ),
        );
      },
    );
  }
}
