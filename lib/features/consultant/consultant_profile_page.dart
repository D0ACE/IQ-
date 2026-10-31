import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iq_plus/common/app_widget/app_text_field_widget.dart';
import 'package:iq_plus/common/routes/go_route.dart';
import 'package:iq_plus/common/utility/app_validation.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/core/local_storage/hive_service.dart';
import 'package:iq_plus/di/service_locator.dart';
import 'package:iq_plus/features/auth/model/user_model.dart';
import 'package:go_router/go_router.dart';

class ConsultantProfilePage extends StatefulWidget {
  final String consultantId;
  const ConsultantProfilePage({super.key, required this.consultantId});

  @override
  State<ConsultantProfilePage> createState() => _ConsultantProfilePageState();
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

  void _showEditProfileDialog(BuildContext context) {
    if (user == null) return;
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: user!.userName);
    final emailCtrl = TextEditingController(text: user!.email);
    final phoneCtrl = TextEditingController(text: AppValidation.formatPhoneForEdit(user!.phoneNumber));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Edit Profile", style: TextStyle(fontWeight: FontWeight.w900)),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                AppTextFieldWidget(
                  labelText: "Full Name",
                  hintText: "Enter full name",
                  textFieldController: nameCtrl,
                  isRequired: true,
                  validator: AppValidation.nameValidator,
                  prefixIconWidget: const Icon(Icons.person_outline_rounded, color: AppColors.kPrimaryColor, size: 20),
                ),
                const SizedBox(height: 16),
                AppTextFieldWidget(
                  labelText: "Email Address",
                  hintText: "Enter email address",
                  textFieldController: emailCtrl,
                  isRequired: true,
                  keyboardType: TextInputType.emailAddress,
                  validator: AppValidation.checkEmailValidation,
                  prefixIconWidget: const Icon(Icons.alternate_email_rounded, color: AppColors.kPrimaryColor, size: 20),
                ),
                const SizedBox(height: 16),
                AppTextFieldWidget(
                  labelText: "Phone Number",
                  hintText: "Enter 10-digit mobile number",
                  textFieldController: phoneCtrl,
                  isRequired: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: AppValidation.phoneNumberFormatters(),
                  validator: AppValidation.phoneNumberValidator,
                  prefixText: "+91 ",
                  prefixIconWidget: const Icon(Icons.phone_iphone_rounded, color: AppColors.kPrimaryColor, size: 20),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: AppColors.buttonYellow, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonDarkGreen,
              foregroundColor: AppColors.buttonYellow,
            ),
            onPressed: () async {
              if (!formKey.currentState!.validate()) {
                return;
              }

              final newName = nameCtrl.text.trim();
              final newEmail = emailCtrl.text.trim();
              final newPhone = AppValidation.formatPhoneForDisplay(phoneCtrl.text.trim());

              try {
                // Update Firestore
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.consultantId)
                    .update({
                  'userName': newName,
                  'email': newEmail,
                  'phoneNumber': newPhone,
                });

                // Update Hive local storage
                user!.userName = newName;
                user!.email = newEmail;
                user!.phoneNumber = newPhone;
                await getIt<HiveService>().saveUser(user!);

                if (context.mounted) {
                  Navigator.pop(ctx);
                  context.go(AppRoutes.consultantDashboard);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Profile updated successfully")),
                  );
                }

                setState(() {
                  _nameCtrl.text = newName;
                  _emailCtrl.text = newEmail;
                  _phoneCtrl.text = newPhone;
                });

                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Profile updated successfully")),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to update profile: $e"), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text("Save", style: TextStyle(color: AppColors.buttonYellow, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.blackColor),
          onPressed: () => GoRouter.of(context).pop(),
        ),
        title: const Text(
          'Consultant Profile',
          style: TextStyle(color: AppColors.blackColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: AppColors.blackColor),
            onPressed: () => _showEditProfileDialog(context),
            tooltip: 'Edit Profile',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Decorative background elements
          Positioned(
            top: -50,
            right: -50,
            child: _buildDecorativeCircle(200, AppColors.kPrimaryColor.withValues(alpha: 0.03)),
          ),
          Positioned(
            bottom: 100,
            left: -30,
            child: _buildDecorativeCircle(150, AppColors.secondary.withValues(alpha: 0.03)),
          ),
          
          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _sectionTitle('Account Details'),
                const SizedBox(height: 16),
                _buildProfileCard(),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecorativeCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w900,
        color: AppColors.titleText,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.kPrimaryColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.kPrimaryColor.withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -30,
              child: Opacity(
                opacity: 0.1,
                child: const Icon(Icons.badge_rounded, size: 180, color: Colors.white),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                      child: const Icon(Icons.person_rounded, color: Colors.white, size: 40),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "SYSTEM PROFILE",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        Text(
                          _nameCtrl.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            "Licensed Consultant",
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildDetailItem(Icons.person_outline_rounded, "Full Name", _nameCtrl.text),
            const Divider(height: 32, color: Colors.black12),
            _buildDetailItem(Icons.email_outlined, "Email Address", _emailCtrl.text),
            const Divider(height: 32, color: Colors.black12),
            _buildDetailItem(Icons.phone_iphone_rounded, "Contact Number", AppValidation.formatPhoneForDisplay(_phoneCtrl.text)),
            const Divider(height: 32, color: Colors.black12),
            _buildDetailItem(Icons.badge_outlined, "Designation Role", _roleCtrl.text),
            const Divider(height: 32, color: Colors.black12),
            _buildDetailItem(
              Icons.verified_user_outlined, 
              "Account Status", 
              _statusCtrl.text.toUpperCase(),
              color: user!.activeUser ? Colors.green.shade700 : Colors.red.shade700,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value, {Color? color}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (color ?? AppColors.kPrimaryColor).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color ?? AppColors.kPrimaryColor, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: Colors.grey.shade400,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: color ?? AppColors.titleText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
