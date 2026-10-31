import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iq_plus/common/utility/app_validation.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/core/local_storage/hive_service.dart';
import 'package:iq_plus/di/service_locator.dart';
import 'package:iq_plus/features/auth/model/user_model.dart';
import 'package:go_router/go_router.dart';

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

    _nameCtrl.text = firestoreUser?['userName'] ?? hiveUser!.userName;
    _emailCtrl.text = firestoreUser?['email'] ?? hiveUser!.email;
    _phoneCtrl.text = firestoreUser?['phoneNumber'] ?? '';
    _roleCtrl.text = firestoreUser?['roleName'] ?? 'Administrator';

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
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
          'System Administrator',
          style: TextStyle(color: AppColors.blackColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
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
                _sectionTitle('Access Credentials'),
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
    final String roleLabel = _roleCtrl.text.toUpperCase();
    final bool isSuperAdmin = roleLabel.contains("SUPER");
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isSuperAdmin ? const Color(0xFF0F172A) : AppColors.kPrimaryColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: (isSuperAdmin ? const Color(0xFF0F172A) : AppColors.kPrimaryColor).withValues(alpha: 0.15),
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
                child: Icon(
                  isSuperAdmin ? Icons.vpn_key_rounded : Icons.security_rounded, 
                  size: 180, 
                  color: Colors.white
                ),
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
                      child: Icon(
                        isSuperAdmin ? Icons.admin_panel_settings_rounded : Icons.person_rounded, 
                        color: Colors.white, 
                        size: 40
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isSuperAdmin ? "ROOT AUTHORIZATION" : "PRIVILEGED ACCOUNT",
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
                            color: Colors.black.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            roleLabel,
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
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
              hiveUser?.activeUser == true ? "ACTIVE" : "INACTIVE",
              color: hiveUser?.activeUser == true ? Colors.green.shade700 : Colors.red.shade700,
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
