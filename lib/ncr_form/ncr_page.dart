import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:iq_plus/common/routes/go_route.dart';
import 'package:iq_plus/common/themes/app_const.dart';
import 'package:iq_plus/common/utility/utility.dart';
import 'package:iq_plus/core/local_storage/hive_service.dart';
import 'package:iq_plus/di/service_locator.dart';
import 'package:iq_plus/features/auth/model/customer_model.dart';
import 'package:iq_plus/features/auth/model/user_model.dart';
import 'package:iq_plus/ncr_form/ncr_form_page.dart';
import 'package:iq_plus/ncr_form/ncr_provider.dart';

import 'package:provider/provider.dart';
import 'package:iq_plus/common/themes/app_colors.dart';

class NcrPage extends StatefulWidget {
  const NcrPage({super.key});

  @override
  State<NcrPage> createState() => _NcrPageState();
}

class _NcrPageState extends State<NcrPage> {
  String roleId = '';
  bool isRoleLoaded = false;
  final UserModel? userLoginDetails = getIt<HiveService>().getUser();
  final CustomerModel? customerLoginDetails = getIt<HiveService>().getCustomer();

  @override
  void initState() {
    super.initState();
    fetchUserRole();
    context.read<NcrProvider>().listenToNcrs();
  }

  void fetchUserRole()  {
    roleId = userLoginDetails?.roleId??customerLoginDetails?.roleId??'';
    isRoleLoaded = true;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      backgroundColor: AppColors.whiteTextColor,
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      floatingActionButton: Utility.isCustomer(roleId)?null:Padding(
        padding: const EdgeInsets.only(top: 16),
        child: FloatingActionButton.extended(
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'Add new form',
            style: TextStyle(color: Colors.white),
          ),
          onPressed: () {
            GoRouter.of(
              context,
            ).push(AppRoutes.nCRFormPage); // navigate using GoRouter
          },
        ),
      ),
      appBar: AppBar(
        title: const Text('NCR List'),
        backgroundColor: AppColors.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Consumer<NcrProvider>(
          builder: (context, provider, _) {
            if (provider.ncrList.isEmpty) {
              return const Center(child: Text("No NCRs found"));
            }

            return ListView.builder(
              itemCount: provider.ncrList.length,
              itemBuilder: (context, index) {
                final ncr = provider.ncrList[index];
                return NcrListCard(
                  ncr: ncr,
                  roleId: roleId,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NCRFormPage(ncrData: ncr, forceEdit: false),
                      ),
                    );
                    if (mounted) {
                      setState(() {});
                    }
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class NcrListCard extends StatelessWidget {
  final Map<String, dynamic> ncr;
  final VoidCallback onTap;
  final String roleId;

  const NcrListCard({
    super.key,
    required this.ncr,
    required this.onTap,
    required this.roleId,
  });

  String get status => ncr['status'] ?? AppConst.openNCRStatusKey;

  static final Map<String, String> _companyNameCache = {};

  Future<String> _getCompanyName(String customerId) async {
    if (customerId.isEmpty) return '';
    if (_companyNameCache.containsKey(customerId)) {
      return _companyNameCache[customerId]!;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(customerId)
          .get();
      if (doc.exists && doc.data() != null) {
        final name = doc.data()?['companyName']?.toString() ?? '';
        _companyNameCache[customerId] = name;
        return name;
      }
    } catch (_) {}
    return '';
  }

  Widget _buildCompanyWidget() {
    final directName = (ncr['companyName'] ?? ncr['company'] ?? '').toString();
    final customerId = (ncr['customerId'] ?? ncr['companyId'] ?? '').toString();

    if (directName.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 2, bottom: 2),
        child: Row(
          children: [
            const Icon(Icons.business_rounded, size: 14, color: AppColors.greyTextColor),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                directName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.blackTextColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    if (customerId.isEmpty) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<String>(
      future: _getCompanyName(customerId),
      builder: (context, snapshot) {
        final name = snapshot.data ?? '';
        if (name.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 2, bottom: 2),
          child: Row(
            children: [
              const Icon(Icons.business_rounded, size: 14, color: AppColors.greyTextColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.blackTextColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete NCR"),
        content: const Text("Are you sure you want to delete this NCR?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              context.read<NcrProvider>().deleteNcr(ncr['id']);
              Navigator.pop(ctx);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// Status tag widget
  Widget _statusTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Utility.getNCRStatusColor(status), // Orange, Blue, Green
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        Utility.getNCRStatus(status),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final process = ncr['process'] ?? 'N/A';
    final createdAt = ncr['createdAt'] != null
        ? (ncr['createdAt'] as Timestamp).toDate()
        : null;

    return Card(
      color: AppColors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              /// Left status icon
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: Utility.getNCRStatusColor(status).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Utility.getNCRStatusIcons(status),
                    color: Utility.getNCRStatusColor(status),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              /// Middle: process + company + date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      process,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.titleText,
                      ),
                    ),
                    _buildCompanyWidget(),
                    if (createdAt != null)
                      Text(
                        "Created: ${DateFormat('dd MMM yyyy').format(createdAt)}",
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.greyTextColor,
                        ),
                      ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: _statusTag(),
              ),
              if (!Utility.isCustomer(roleId)) ...[
                IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.primary),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            NCRFormPage(ncrData: ncr, forceEdit: true),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _showDeleteDialog(context),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
