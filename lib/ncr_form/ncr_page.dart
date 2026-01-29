import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:iq_plus/common/constants/user_role.dart';
import 'package:iq_plus/common/routes/go_route.dart';
import 'package:iq_plus/ncr_form/ncr_form_page.dart';
import 'package:iq_plus/ncr_form/ncr_provider.dart';

import 'package:provider/provider.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/common/themes/app_theme_data.dart';

class NcrPage extends StatefulWidget {
  const NcrPage({super.key});

  @override
  State<NcrPage> createState() => _NcrPageState();
}

class _NcrPageState extends State<NcrPage> {
  UserRole userRole = UserRole.customer;

  @override
  void initState() {
    super.initState();
    context.read<NcrProvider>().listenToNcrs();
    _fetchUserRole();
  }

 Future<void> _fetchUserRole() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();

  setState(() {
    userRole = mapUserRole((doc.data()?['role'] ?? '').toString().toUpperCase());
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteTextColor,
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      floatingActionButton: Padding(
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
                  userRole: userRole, // 👈 ADD THIS
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
  final UserRole userRole; // 👈 Use enum

  const NcrListCard({
    super.key,
    required this.ncr,
    required this.onTap,
    required this.userRole,
  });

  @override
  State<NcrListCard> createState() => _NcrListCardState();
}

class _NcrListCardState extends State<NcrListCard> {
  late String status;

  @override
  void initState() {
    super.initState();
    status = widget.ncr['status'] ?? 'open';
  }

  List<String> allowedStatusChanges() {
    switch (widget.userRole) {
      case UserRole.consultant:
        return status == 'open' ? ['in_progress'] : [];
      case UserRole.admin:
      case UserRole.superAdmin:
        if (status == 'open') return ['in_progress', 'closed'];
        if (status == 'in_progress') return ['closed'];
        return [];
      case UserRole.customer:
      default:
        return [];
    }
  }
  /// Status tag widget
Widget _statusTag() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: _statusColor(status), // Orange, Blue, Green
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      _statusText(status),
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
    ),
  );
}


  /// Status color
  Color _statusColor(String status) {
    switch (status) {
      case 'open':
        return AppColors.orange;
      case 'in_progress':
        return AppColors.blue;
      case 'closed':
        return AppColors.green;
      default:
        return Colors.grey;
    }
  }

  String _statusText(String status) {
    switch (status) {
      case 'open':
        return 'Open';
      case 'in_progress':
        return 'In Progress';
      case 'closed':
        return 'Closed';
      default:
        return 'Unknown';
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    final docId = widget.ncr['id'];
    if (docId == null) return;

    await FirebaseFirestore.instance.collection('ncr').doc(docId).update({'status': newStatus});

    setState(() {
      status = newStatus;
    });
  }

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
                  color: _statusColor(status).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    status == 'open'
                        ? Icons.pending_actions
                        : status == 'in_progress'
                            ? Icons.autorenew
                            : Icons.check_circle,
                    color: _statusColor(status),
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
                    if (createdAt != null)
                      const SizedBox(height: 4),
                    if (createdAt != null)
                      Text(
                        "Created: ${DateFormat('dd MMM yyyy').format(createdAt)}",
                        style: TextStyle(fontSize: 12, color: AppColors.greyTextColor),
                      ),
                  ],
                ),
              ),
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
              //           backgroundColor: _statusColor(s),
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


