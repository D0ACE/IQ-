import 'package:flutter/material.dart';
import 'package:iq_plus/common/app_widget/app_text_field_widget.dart';
import 'package:iq_plus/common/app_widget/common_gradient_button.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/common/themes/app_theme_data.dart';
import 'package:iq_plus/core/local_storage/hive_service.dart';
import 'package:iq_plus/di/service_locator.dart';
import 'package:iq_plus/features/auth/model/user_model.dart';

class ConsultantProfilePage extends StatefulWidget {
   final String consultantId;
  const ConsultantProfilePage({ super.key,
    required this.consultantId,});

  @override
  State<ConsultantProfilePage> createState() =>
      _ConsultantProfilePageState();
}

class _ConsultantProfilePageState extends State<ConsultantProfilePage> {
  UserModel? user;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _roleCtrl = TextEditingController();
  final _statusCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    final hiveService = getIt<HiveService>();
    user = hiveService.getUser();

    if (user == null) return;

    _nameCtrl.text = user!.userName;
    _emailCtrl.text = user!.email;
    _phoneCtrl.text = user!.phoneNumber;
    _roleCtrl.text = "Consultant";
    _statusCtrl.text = user!.activeUser ? "Active" : "Inactive";
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("No consultant found")),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildProfileCard()),
        ],
      ),
    );
  }

  /// 🔝 Gradient Header
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 30),
      decoration: const BoxDecoration(
        gradient: AppColors.mainGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 42,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.person,
              size: 45,
              color: AppColors.purple,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _nameCtrl.text,
            style: AppThemeData.black18TextStyle.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _emailCtrl.text,
            style: AppThemeData.grey14TextStyle.copyWith(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  /// 🧾 Profile Card
  Widget _buildProfileCard() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Profile Details",
                style: AppThemeData.black18TextStyle.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              AppTextFieldWidget(
                labelText: "Full Name",
                textFieldController: _nameCtrl,
                readOnly: true,
              ),
              const SizedBox(height: 14),

              AppTextFieldWidget(
                labelText: "Email Address",
                textFieldController: _emailCtrl,
                readOnly: true,
              ),
              const SizedBox(height: 14),

              AppTextFieldWidget(
                labelText: "Phone Number",
                textFieldController: _phoneCtrl,
                readOnly: true,
              ),
              const SizedBox(height: 14),

              AppTextFieldWidget(
                labelText: "Role",
                textFieldController: _roleCtrl,
                readOnly: true,
              ),
              const SizedBox(height: 14),

              AppTextFieldWidget(
                labelText: "Status",
                textFieldController: _statusCtrl,
                readOnly: true,
              ),

              const SizedBox(height: 30),

              GradientButton(
                text: "Edit Profile (Coming Soon)",
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
