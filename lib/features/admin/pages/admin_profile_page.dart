import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iq_plus/common/app_widget/common_gradient_button.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/common/themes/app_theme_data.dart';
import 'package:iq_plus/common/app_widget/app_text_field_widget.dart';
import 'package:iq_plus/core/local_storage/hive_service.dart';
import 'package:iq_plus/di/service_locator.dart';
import 'package:iq_plus/features/auth/model/user_model.dart';

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  UserModel? hiveUser;
  Map<String, dynamic>? firestoreUser;
  bool loading = true;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _roleCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final hiveService = getIt<HiveService>();
    hiveUser = hiveService.getUser();

    if (hiveUser == null) {
      setState(() => loading = false);
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(hiveUser!.userId)
        .get();

    firestoreUser = doc.data();

    _nameCtrl.text =
        firestoreUser?['userName'] ?? hiveUser!.userName;
    _emailCtrl.text =
        firestoreUser?['email'] ?? hiveUser!.email;
    _phoneCtrl.text =
        firestoreUser?['phoneNumber'] ?? '';
    _roleCtrl.text =
        firestoreUser?['roleName'] ?? 'Admin';

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (hiveUser == null) {
      return const Scaffold(
        body: Center(child: Text("No user found")),
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
      child: SingleChildScrollView( // ✅ KEY FIX
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
