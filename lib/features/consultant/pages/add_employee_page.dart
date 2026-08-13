import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iq_plus/common/app_widget/app_text_field_widget.dart';
import 'package:iq_plus/common/app_widget/common_gradient_button.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/common/themes/app_ui_helper.dart';
import 'package:iq_plus/common/utility/utility.dart';
import 'package:iq_plus/common/themes/app_const.dart';
import 'package:iq_plus/common/utility/app_validation.dart';
import 'package:iq_plus/core/local_storage/hive_service.dart';
import 'package:iq_plus/di/service_locator.dart';
import 'package:iq_plus/features/admin/customers/widgets/customer_dropdown_widget.dart';
import 'package:iq_plus/features/auth/model/customer_model.dart';
import 'package:iq_plus/features/users/cubit/employee_user_cubit.dart';
import 'package:iq_plus/features/users/cubit/employee_user_state.dart';
import 'package:iq_plus/features/users/models/employe_user.dart';

class AddEmployeePage extends StatefulWidget {
  const AddEmployeePage({super.key});

  @override
  State<AddEmployeePage> createState() => _AddEmployeePageState();
}

class _AddEmployeePageState extends State<AddEmployeePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _designationCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  late String _generatedPassword;
  CustomerModel? _selectedCustomer;
  final _currentUser = getIt<HiveService>().getUser();

  @override
  void initState() {
    super.initState();
    _generatedPassword = Utility.autoGeneratePassword();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _designationCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a customer")),
      );
      return;
    }

    final employee = EmployeeUserModel(
      userId: '', // Firestore will generate
      userName: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phoneNumber: _phoneCtrl.text.trim(), 
      roleId: AppConst.employeeRole, // 🚀 Using New Role ID 4
      password: _generatedPassword,
      createdAt: DateTime.now(),
      blockStatus: false,
      designation: _designationCtrl.text.trim(),
      customerId: _selectedCustomer!.customerId,
      createdBy: _currentUser?.userId,
    );

    context.read<UserCubit>().addUser(
          employee,
          companyName: _selectedCustomer!.companyName,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UserCubit, UserState>(
      listener: (context, state) {
        if (state is UserSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
          // 🚀 Just pop back to listing. Listing will refresh via await.
          context.pop();
        } else if (state is UserError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBg,
        appBar: AppBar(
          title: const Text("Add Employee"),
          backgroundColor: AppColors.kPrimaryColor,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(appHorizontalPadding20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Select Company",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                verticalSpaceSmall,
                CustomerDropdownWidget(
                  consultantId: Utility.isConsultant(_currentUser?.roleId) ? _currentUser?.userId : null,
                  onChanged: (customer) {
                    setState(() {
                      _selectedCustomer = customer;
                    });
                  },
                ),
                verticalSpace20,
                AppTextFieldWidget(
                  labelText: "Employee Name",
                  hintText: "Enter name",
                  textFieldController: _nameCtrl,
                  isRequired: true,
                ),
                verticalSpace15,
                AppTextFieldWidget(
                  labelText: "Designation",
                  hintText: "Enter designation",
                  textFieldController: _designationCtrl,
                  isRequired: true,
                ),
                verticalSpace15,
                AppTextFieldWidget(
                  labelText: "Email Address",
                  hintText: "Enter email",
                  textFieldController: _emailCtrl,
                  isRequired: true,
                  keyboardType: TextInputType.emailAddress,
                ),
                verticalSpace15,
                AppTextFieldWidget(
                  labelText: "Mobile Number",
                  hintText: "Enter mobile number",
                  textFieldController: _phoneCtrl,
                  isRequired: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: AppValidation.phoneNumberValidator,
                ),
                verticalSpace15,
                AppTextFieldWidget(
                  labelText: "Auto-generated Password",
                  textFieldController: TextEditingController(text: _generatedPassword),
                  readOnly: true,
                  isEnabled: false,
                ),
                verticalSpaceLarge,
                BlocBuilder<UserCubit, UserState>(
                  builder: (context, state) {
                    return GradientButton(
                      text: "Create Employee",
                      isLoading: state is UserLoading,
                      onPressed: state is UserLoading ? () {} : _submit,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
