import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iq_plus/common/app_widget/app_text_field_widget.dart';
import 'package:iq_plus/common/app_widget/common_gradient_button.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/common/themes/app_ui_helper.dart';
import 'package:iq_plus/features/admin/service/admin_service.dart';


class CreateAdminPage extends StatefulWidget {
  const CreateAdminPage({super.key});

  @override
  State<CreateAdminPage> createState() => _CreateAdminPageState();
}

class _CreateAdminPageState extends State<CreateAdminPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _mobileCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();

  bool _isLoading = false;

  void _createAdmin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await AdminService.createAdmin(
        userName: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _mobileCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admin created successfully')),
      );

      _formKey.currentState!.reset();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Create Admin'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(appHorizontalPadding20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(),
                const SizedBox(height: 24),

                _buildNameField(),
                const SizedBox(height: 16),

                _buildEmailField(),
                const SizedBox(height: 16),

                _buildMobileField(),
                const SizedBox(height: 16),

                _buildPasswordField(),
                const SizedBox(height: 30),

                GradientButton(
                  text: 'Create Admin',
                  isLoading: _isLoading,
                  onPressed: _createAdmin,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===================== UI SECTIONS =====================

  Widget _header() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Admin Details',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.titleText,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Fill the details below to create a new admin',
          style: TextStyle(fontSize: 14, color: AppColors.subText),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return AppTextFieldWidget(
      labelText: 'Admin Name',
      hintText: 'Enter full name',
      isRequired: true,
      textFieldController: _nameCtrl,
      prefixIconWidget: const Icon(Icons.person_outline),
      textCapitalization: TextCapitalization.words,
      validator: (value) =>
          value == null || value.trim().length < 3 ? 'Enter valid name' : null,
    );
  }

  Widget _buildEmailField() {
    return AppTextFieldWidget(
      labelText: 'Email Address',
      hintText: 'admin@email.com',
      isRequired: true,
      keyboardType: TextInputType.emailAddress,
      textFieldController: _emailCtrl,
      prefixIconWidget: const Icon(Icons.email_outlined),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Email is required';
        if (!value.contains('@')) return 'Enter valid email';
        return null;
      },
    );
  }

  Widget _buildMobileField() {
    return AppTextFieldWidget(
      labelText: 'Mobile Number',
      hintText: '10 digit mobile number',
      isRequired: true,
      keyboardType: TextInputType.phone,
      textFieldController: _mobileCtrl,
      prefixIconWidget: const Icon(Icons.phone_outlined),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
      validator: (value) => value != null && value.length == 10
          ? null
          : 'Enter valid mobile number',
    );
  }

  Widget _buildPasswordField() {
    return AppTextFieldWidget(
      labelText: 'Password',
      hintText: 'Minimum 6 characters',
      isRequired: true,
      isPasswordTextField: true,
      textFieldController: _passwordCtrl,
      prefixIconWidget: const Icon(Icons.lock_outline),
      validator: (value) => value != null && value.length >= 6
          ? null
          : 'Password must be at least 6 characters',
    );
  }
}
