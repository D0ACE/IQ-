import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iq_plus/common/routes/go_route.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/common/widgets/common_app_bar.dart';
import 'package:iq_plus/core/local_storage/hive_service.dart';
import 'package:iq_plus/di/service_locator.dart';
import 'package:iq_plus/features/superadmin/models/version_history_model.dart';
import 'package:iq_plus/features/superadmin/repository/document_repository.dart';
import 'package:iq_plus/features/superadmin/cubit/document_cubit.dart';
import 'package:iq_plus/features/superadmin/cubit/document_state.dart';
import 'package:intl/intl.dart';

class CustomerPolicyListPage extends StatefulWidget {
  const CustomerPolicyListPage({super.key});

  @override
  State<CustomerPolicyListPage> createState() => _CustomerPolicyListPageState();
}

class _CustomerPolicyListPageState extends State<CustomerPolicyListPage> {
  @override
  void initState() {
    super.initState();
    final customer = getIt<HiveService>().getCustomer();
    context.read<DocumentCubit>().loadDocuments(
      customerId: customer?.customerId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: const CommonAppBar(title: 'My Policies & Procedures'),
      body: BlocBuilder<DocumentCubit, DocumentState>(
        builder: (context, state) {
          if (state is DocumentLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is DocumentError) {
            return Center(child: Text(state.message));
          }
          if (state is DocumentLoaded) {
            final docs = state.documents;
            if (docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.policy_outlined, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text('No policies assigned yet', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: AppColors.kPrimaryLightColor,
                            child: Icon(_getFileIcon(doc.fileType), color: AppColors.purple, size: 20),
                          ),
                          title: Text(doc.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          subtitle: Text("Version: ${doc.currentVersion}", style: const TextStyle(fontSize: 13, color: AppColors.purple, fontWeight: FontWeight.w600)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Version History',
                                icon: const Icon(Icons.history, color: Colors.blueGrey, size: 20),
                                onPressed: () => _showVersionHistoryDialog(context, doc.docId, doc.title),
                              ),
                              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                            ],
                          ),
                          onTap: () {
                            context.push(AppRoutes.customerPolicyDetail, extra: doc);
                          },
                        ),
                        const Divider(),
                        Row(
                          children: [
                            Expanded(child: _auditItem("Prepared By", doc.createdBy)),
                            Expanded(child: _auditItem("Prepared Date", DateFormat('dd MMM yyyy').format(doc.createdAt))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: _auditItem("Reviewed By", doc.reviewedBy ?? "N/A")),
                            Expanded(child: _auditItem("Reviewed Date", doc.reviewedDate != null ? DateFormat('dd MMM yyyy').format(doc.reviewedDate!) : "N/A")),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _auditItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  void _showVersionHistoryDialog(BuildContext context, String docId, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Version History'),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: FutureBuilder<List<VersionHistoryModel>>(
            future: DocumentRepository().getVersionHistory(docId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }
              final history = snapshot.data ?? [];
              if (history.isEmpty) {
                return const Center(child: Text("No history found"));
              }

              return ListView.separated(
                shrinkWrap: true,
                itemCount: history.length,
                separatorBuilder: (ctx, index) => const Divider(),
                itemBuilder: (ctx, index) {
                  final v = history[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(v.versionNo, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.purple)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (v.status == 'active' ? Colors.green : Colors.orange).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  v.status.toUpperCase(),
                                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: v.status == 'active' ? Colors.green : Colors.orange),
                                ),
                              ),
                            ],
                          ),
                          Text(DateFormat('dd MMM yyyy, hh:mm a').format(v.performedDate), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text("Description of the change: ${v.changeDescription}", style: const TextStyle(fontSize: 13)),
                      const SizedBox(height: 4),
                      Text("Performed By: ${v.performedBy}", style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
                      if (v.status == 'draft' && v.assignedReviewerName != null) 
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text("Pending Review by: ${v.assignedReviewerName} on ${DateFormat('dd MMM yyyy').format(v.performedDate)}", 
                               style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                        ),
                      if (v.status == 'active' && v.approvedBy != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text("Approved by: ${v.approvedBy} on ${v.approvedDate != null ? DateFormat('dd MMM yyyy').format(v.approvedDate!) : 'N/A'}", 
                               style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  IconData _getFileIcon(String type) {
    final t = type.toLowerCase();
    if (t.contains('pdf')) return Icons.picture_as_pdf;
    if (t.contains('doc')) return Icons.description;
    if (t.contains('xls')) return Icons.table_chart;
    if (t.contains('quill')) return Icons.edit_note;
    return Icons.insert_drive_file;
  }
}
