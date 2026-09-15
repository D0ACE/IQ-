import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:iq_plus/common/app_widget/app_text_field_widget.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/common/utility/app_validation.dart';
import 'package:iq_plus/features/users/cubit/employee_user_cubit.dart';
import 'package:iq_plus/features/users/cubit/employee_user_state.dart';
import 'package:iq_plus/features/users/models/employe_user.dart';
import 'package:iq_plus/core/local_storage/hive_service.dart';
import 'package:iq_plus/di/service_locator.dart';

class AddUserDialog extends StatefulWidget {
  final EmployeeUserModel? user;
  const AddUserDialog({super.key, this.user});

  @override
  State<AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<AddUserDialog> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final joiningDateController = TextEditingController();

  String? selectedRoleId;
  bool blockStatus = false;
  DateTime? joiningDate;

  @override
  void initState() {
    super.initState();
    context.read<UserCubit>().loadRoles();

    if (widget.user != null) {
      final u = widget.user!;
      nameController.text = u.userName;
      emailController.text = u.email;
      phoneController.text = u.phoneNumber;
      selectedRoleId = u.roleId;
      passwordController.text = u.password;
      blockStatus = u.blockStatus;
      joiningDate = u.joiningDate;
      if (joiningDate != null) {
        joiningDateController.text = DateFormat(
          'dd MMM yyyy',
        ).format(joiningDate!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 700;

    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.user == null ? "Add New User" : "Edit User Profile",
            style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.titleText),
          ),
          const SizedBox(height: 4),
          Text(
            widget.user == null ? "Register a new system user" : "Update account details for ${widget.user!.userName}",
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
          ),
        ],
      ),
      content: SizedBox(
        width: isDesktop ? 520 : double.maxFinite,
        child: BlocBuilder<UserCubit, UserState>(
          builder: (context, state) {
            final cubit = context.read<UserCubit>();

            return Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    /// 👤 Name
                    _field(
                      AppTextFieldWidget(
                        hintText: "Full Name",
                        textFieldController: nameController,
                        isRequired: true,
                        prefixIconWidget: const Icon(Icons.person_outline_rounded, color: AppColors.kPrimaryColor, size: 20),
                      ),
                    ),

                    /// 📧 Email
                    _field(
                      AppTextFieldWidget(
                        keyboardType: TextInputType.emailAddress,
                        hintText: "Email Address",
                        textFieldController: emailController,
                        validator: AppValidation.checkEmailValidation,
                        prefixIconWidget: const Icon(Icons.alternate_email_rounded, color: AppColors.kPrimaryColor, size: 20),
                      ),
                    ),

                    /// 📞 Phone
                    _field(
                      AppTextFieldWidget(
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        hintText: "Phone Number",
                        textFieldController: phoneController,
                        validator: AppValidation.phoneNumberValidator,
                        prefixIconWidget: const Icon(Icons.phone_iphone_rounded, color: AppColors.kPrimaryColor, size: 20),
                      ),
                    ),

                    /// 🔐 Password
                    _field(
                      AppTextFieldWidget(
                        hintText: "Account Password",
                        textFieldController: passwordController,
                        isPasswordTextField: true,
                        validator: AppValidation.currentPasswordValidator,
                        prefixIconWidget: const Icon(Icons.lock_outline_rounded, color: AppColors.kPrimaryColor, size: 20),
                      ),
                    ),

                    /// 📅 Joining Date Picker (Show only for New User)
                    if (widget.user == null)
                      _field(
                        TextFormField(
                          controller: joiningDateController,
                          readOnly: true,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          decoration: _dropdownDecoration("Joining Date").copyWith(
                            prefixIcon: const Icon(Icons.calendar_today_rounded, color: AppColors.kPrimaryColor, size: 20),
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? "Joining date required"
                              : null,
                          onTap: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: joiningDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );

                            if (pickedDate != null) {
                              setState(() {
                                joiningDate = pickedDate;
                                joiningDateController.text = DateFormat(
                                  'dd MMM yyyy',
                                ).format(pickedDate);
                              });
                            }
                          },
                        ),
                      ),

                    /// 🧩 Role dropdown (Show only for New User)
                    if (widget.user == null)
                      _field(
                        DropdownButtonFormField<String>(
                          initialValue: selectedRoleId,
                          style: const TextStyle(fontSize: 14, color: AppColors.titleText, fontWeight: FontWeight.w600),
                          decoration: _dropdownDecoration("Assign System Role").copyWith(
                            prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.kPrimaryColor, size: 20),
                          ),
                          items: cubit.roles.map((role) {
                            return DropdownMenuItem(
                              value: role.id,
                              child: Text(role.name.toUpperCase(), style: const TextStyle(fontSize: 13)),
                            );
                          }).toList(),
                          onChanged: (value) =>
                              setState(() => selectedRoleId = value),
                          validator: (v) => v == null ? "Role required" : null,
                        ),
                      ),

                    /// 🚫 User status
                    _field(
                      DropdownButtonFormField<bool>(
                        initialValue: blockStatus,
                        style: const TextStyle(fontSize: 14, color: AppColors.titleText, fontWeight: FontWeight.w600),
                        decoration: _dropdownDecoration("Account Status").copyWith(
                          prefixIcon: const Icon(Icons.verified_user_outlined, color: AppColors.kPrimaryColor, size: 20),
                        ),
                        items: const [
                          DropdownMenuItem(value: false, child: Text("ACTIVE", style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: true, child: Text("BLOCKED", style: TextStyle(fontSize: 13))),
                        ],
                        onChanged: (value) =>
                            setState(() => blockStatus = value ?? false),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      actions: [
        TextButton(
          onPressed: () => GoRouter.of(context).pop(),
          child: Text(
            "Cancel",
            style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.kPrimaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              /// 🔁 EDIT MODE
              if (widget.user != null) {
                context.read<UserCubit>().updateUser(
                  userId: widget.user!.userId,
                  userName: nameController.text.trim(),
                  email: emailController.text.trim(),
                  phoneNumber: phoneController.text.trim(),
                  password: passwordController.text.trim(),
                  roleId: selectedRoleId!,
                  blockStatus: blockStatus,
                  joiningDate: joiningDate,
                  designation: widget.user!.designation, // 👈 Keep existing designation
                  customerId: widget.user!.customerId,   // 👈 Keep existing customerId
                );
              }
              /// ➕ ADD MODE
              else {
                final currentUser = getIt<HiveService>().getUser();
                context.read<UserCubit>().addUser(
                  EmployeeUserModel(
                    userId: '',
                    userName: nameController.text.trim(),
                    email: emailController.text.trim(),
                    phoneNumber: phoneController.text.trim(),
                    password: passwordController.text.trim(),
                    roleId: selectedRoleId!,
                    blockStatus: blockStatus,
                    joiningDate: joiningDate!,
                    createdAt: DateTime.now(),
                    createdBy: currentUser?.userId,
                  ),
                );
              }

              GoRouter.of(context).pop();
            }
          },
          child: Text(
            widget.user == null ? "Create User" : "Update Account",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  /// spacing helper
  Widget _field(Widget child) =>
      Padding(padding: const EdgeInsets.only(bottom: 16), child: child);

  /// dropdown decoration
  InputDecoration _dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500),
      floatingLabelStyle: const TextStyle(color: AppColors.kPrimaryColor, fontWeight: FontWeight.bold),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.kPrimaryColor, width: 1.5)),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
