import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:iq_plus/common/constants/user_role.dart';
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
            ).push(AppRoutes.NCRFormPage); // navigate using GoRouter
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
                  roleId: roleId, // 👈 ADD THIS
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NCRFormPage(ncrData: ncr),
                      ),
                    );
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

class NcrListCard extends StatefulWidget {
  final Map<String, dynamic> ncr;
  final VoidCallback onTap;
  final String roleId; // 👈 Use enum

  const NcrListCard({
    super.key,
    required this.ncr,
    required this.onTap,
    required this.roleId,
  });

  @override
  State<NcrListCard> createState() => _NcrListCardState();
}

class _NcrListCardState extends State<NcrListCard> {
  late String status;

  @override
  void initState() {
    super.initState();
    status = widget.ncr['status'] ?? AppConst.openNCRStatusKey;
  }

  // List<String> allowedStatusChanges() {
  //   switch (widget.userRole) {
  //     case UserRole.consultant:
  //       return status == AppConst.openNCRStatusKey ? [AppConst.inProgressNCRStatusKey] : [];
  //     case UserRole.admin:
  //     case UserRole.superAdmin:
  //       if (status == AppConst.openNCRStatusKey) return [AppConst.inProgressNCRStatusKey, AppConst.closedNCRStatusKey];
  //       if (status == AppConst.inProgressNCRStatusKey) return [AppConst.closedNCRStatusKey];
  //       return [];
  //     case UserRole.customer:
  //     default:
  //       return [];
  //   }
  // }
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
  

  // Future<void> _updateStatus(String newStatus) async {
  //   final docId = widget.ncr['id'];
  //   if (docId == null) return;

  //   await FirebaseFirestore.instance.collection('ncr').doc(docId).update({'status': newStatus});

  //   setState(() {
  //     status = newStatus;
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    final process = widget.ncr['process'] ?? 'N/A';
    final createdAt = widget.ncr['createdAt'] != null
        ? (widget.ncr['createdAt'] as Timestamp).toDate()
        : null;

    return Card(
      color: AppColors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              /// Left status icon
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: Utility.getNCRStatusColor(status).withOpacity(0.2),
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

              /// Middle: process + date
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
                    if (createdAt != null) const SizedBox(height: 4),
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
              // Padding(
              //   padding: const EdgeInsets.only(left: 8),
              //   child: widget.userRole == UserRole.consultant
              //       ? Row(
              //           mainAxisSize: MainAxisSize.min,
              //           children: [AppConst.openNCRStatusKey, AppConst.inProgressNCRStatusKey, AppConst.closedNCRStatusKey].map((s) {
              //             return Padding(
              //               padding: const EdgeInsets.only(left: 6),
              //               child: ElevatedButton(
              //                 style: ElevatedButton.styleFrom(
              //                   backgroundColor: Utility.getNCRStatusColor(s),
              //                   minimumSize: const Size(36, 36),
              //                   padding: const EdgeInsets.symmetric(
              //                     horizontal: 8,
              //                   ),
              //                 ),
              //                 onPressed: () async {
              //                   final docId = widget.ncr['id'];
              //                   if (docId == null) return;

              //                   await FirebaseFirestore.instance
              //                       .collection('ncr')
              //                       .doc(docId)
              //                       .update({'status': s});

              //                   setState(() => status = s);
              //                 },
              //                 child: Text(
              //                   _statusText(s),
              //                   style: const TextStyle(
              //                     fontSize: 11,
              //                     color: Colors.white,
              //                   ),
              //                 ),
              //               ),
              //             );
              //           }).toList(),
              //         )
              //       : _statusTag(),
              // ),

                            Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _statusTag(),
              ),
              /// Right: status buttons
              // Row(
              //   children: allowedStatusChanges().map((s) {
              //     return Padding(
              //       padding: const EdgeInsets.only(left: 8),
              //       child: ElevatedButton(
              //         style: ElevatedButton.styleFrom(
              //           backgroundColor: Utility.getNCRStatusColor(s),
              //         ),
              //         onPressed: () => _updateStatus(s),
              //         child: Text(_statusText(s), style: const TextStyle(color: Colors.white)),
              //       ),
              //     );
              //   }).toList(),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
