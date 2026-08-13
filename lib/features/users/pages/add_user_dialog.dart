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
      backgroundColor: AppColors.backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        widget.user == null ? "Add User" : "Edit User",
        style: const TextStyle(fontWeight: FontWeight.w600),
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
                    /// 👤 Name
                    _field(
                      AppTextFieldWidget(
                        hintText: "Name",
                        textFieldController: nameController,
                        isRequired: true,
                      ),
                    ),

                    /// 📧 Email
                    _field(
                      AppTextFieldWidget(
                        keyboardType: TextInputType.emailAddress,
                        hintText: "Email",
                        textFieldController: emailController,
                        validator: AppValidation.checkEmailValidation,
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
                      ),
                    ),

                    /// 🔐 Password
                    _field(
                      AppTextFieldWidget(
                        hintText: "Password",
                        textFieldController: passwordController,
                        isPasswordTextField: true,
                        validator: AppValidation.currentPasswordValidator,
                      ),
                    ),

                    /// 📅 Joining Date Picker (Show only for New User)
                    if (widget.user == null)
                      _field(
                        TextFormField(
                          controller: joiningDateController,
                          readOnly: true,
                          decoration: _dropdownDecoration("Joining Date"),
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
                          decoration: _dropdownDecoration("Select Role"),
                          items: cubit.roles.map((role) {
                            return DropdownMenuItem(
                              value: role.id,
                              child: Text(role.name.toUpperCase()),
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
                        decoration: _dropdownDecoration("User Status"),
                        items: const [
                          DropdownMenuItem(value: false, child: Text("Active")),
                          DropdownMenuItem(value: true, child: Text("Blocked")),
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
      actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      actions: [
        TextButton(
          onPressed: () => GoRouter.of(context).pop(),

          child: const Text("Cancel"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.kPrimaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
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
                  roleId: selectedRoleId!,
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
            widget.user == null ? "Create User" : "Update User",
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  /// spacing helper
  Widget _field(Widget child) =>
      Padding(padding: const EdgeInsets.only(bottom: 14), child: child);

  /// dropdown decoration
  InputDecoration _dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }
}
