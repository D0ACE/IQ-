import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iq_plus/common/routes/go_route.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/common/widgets/common_app_bar.dart';
import 'package:iq_plus/features/superadmin/cubit/document_cubit.dart';
import 'package:iq_plus/features/superadmin/cubit/document_state.dart';
import 'package:iq_plus/features/admin/customers/cubit/customer_list_cubit.dart';
import 'package:iq_plus/features/admin/customers/cubit/customer_list_state.dart';
import 'package:iq_plus/common/utility/utility.dart';
import 'package:iq_plus/core/local_storage/hive_service.dart';
import 'package:iq_plus/di/service_locator.dart';
import 'package:iq_plus/features/superadmin/models/version_history_model.dart';
import 'package:iq_plus/features/superadmin/repository/document_repository.dart';
import 'package:intl/intl.dart';

class DocumentListPage extends StatefulWidget {
  const DocumentListPage({super.key});

  @override
  State<DocumentListPage> createState() => _DocumentListPageState();
}

class _DocumentListPageState extends State<DocumentListPage> {
  @override
  void initState() {
    super.initState();
    final user = getIt<HiveService>().getUser();
    final isConsultant = Utility.isConsultant(user?.roleId);
    context.read<DocumentCubit>().loadDocuments(
      userId: user?.userId,
      isConsultant: isConsultant,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: const CommonAppBar(title: 'Policies & Procedures'),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOptions(context),
        backgroundColor: AppColors.purple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
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
              return const Center(child: Text('No documents found'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final isRichDoc = doc.content != null;
                final isDocx = doc.fileName.toLowerCase().endsWith('.docx');

                final user = getIt<HiveService>().getUser();
                final bool isCreator = doc.createdByUserId == user?.userId;
                final bool isSystemAdmin = Utility.isSuperAdmin(user?.roleId) || Utility.isAdmin(user?.roleId);

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.kPrimaryLightColor,
                          child: Text(
                            doc.id.toString(),
                            style: const TextStyle(fontSize: 10, color: AppColors.purple, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(doc.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Version: ${doc.currentVersion}",
                              style: const TextStyle(fontSize: 12),
                            ),
                            if (doc.customerId != null)
                              BlocBuilder<CustomerListCubit, CustomerListState>(
                                builder: (context, customerState) {
                                  String customerName = doc.customerId!;
                                  if (customerState is CustomerListLoaded) {
                                    try {
                                      customerName = customerState.customers
                                          .firstWhere((c) => c.customerId == doc.customerId)
                                          .companyName;
                                    } catch (_) {}
                                  }
                                  return Text(
                                    "Customer: $customerName",
                                    style: const TextStyle(fontSize: 10, color: Colors.blueGrey, fontWeight: FontWeight.w600),
                                  );
                                },
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSystemAdmin || isCreator)
                              IconButton(
                                tooltip: (isRichDoc || isDocx) ? 'Edit / Read Content' : 'Edit (Rich Text)',
                                icon: Icon(
                                  isDocx ? Icons.chrome_reader_mode : Icons.edit_note, 
                                  color: Colors.blue
                                ),
                                onPressed: () {
                                  if (doc.fileType.toLowerCase() == '.xlsx'){
                                    context.push(AppRoutes.excelEditor, extra: doc);
                                  } else {
                                    context.push(AppRoutes.documentEditor, extra: doc);
                                  }
                                },
                              ),
                            IconButton(
                              tooltip: 'Status',
                              icon: Icon(
                                doc.status == 'active' ? Icons.task_alt : Icons.pending,
                                color: doc.status == 'active' ? Colors.green : Colors.orange,
                              ),
                              onPressed: () {
                                // Allow status change if user is Admin/SuperAdmin OR created the doc OR is assigned reviewer
                                final user = getIt<HiveService>().getUser();
                                final isAllowed = Utility.isSuperAdmin(user?.roleId) || 
                                                 Utility.isAdmin(user?.roleId) ||
                                                 doc.createdByUserId == user?.userId ||
                                                 doc.assignedReviewerId == user?.userId;
                                
                                if (isAllowed) {
                                  if (doc.status == 'active') {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("This policy is already Active.")),
                                    );
                                  } else {
                                    _showStatusDialog(context, doc.docId, doc.status);
                                  }
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("You are not authorized to change this policy status.")),
                                  );
                                }
                              },
                            ),
                            IconButton(
                              tooltip: 'Version History',
                              icon: const Icon(Icons.history, color: Colors.blueGrey),
                              onPressed: () => _showVersionHistoryDialog(context, doc.docId, doc.title),
                            ),
                            if (isSystemAdmin || isCreator)
                              IconButton(
                                tooltip: 'Delete',
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _confirmDelete(context, doc.docId, doc.filePath),
                              ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(child: _auditItem("Prepared By", doc.createdBy)),
                                Expanded(child: _auditItem("Prepared Date", DateFormat('dd MMM yyyy').format(doc.createdAt))),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(child: _auditItem("Reviewer Assigned", doc.assignedReviewerName ?? "Not Assigned")),
                                Expanded(child: _auditItem("Reviewed By", doc.reviewedBy ?? "N/A")),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(child: _auditItem("Reviewed Date", doc.reviewedDate != null ? DateFormat('dd MMM yyyy').format(doc.reviewedDate!) : "N/A")),
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: doc.status == 'active' ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        doc.status.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: doc.status == 'active' ? Colors.green : Colors.orange,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
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

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Create New Policy", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.edit_note, color: Colors.white)),
              title: const Text("Rich Text Document"),
              subtitle: const Text("Create a policy with text, images and formatting"),
              onTap: () {
                Navigator.pop(ctx);
                context.push(AppRoutes.documentEditor);
              },
            ),
            const Divider(),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.table_chart, color: Colors.white)),
              title: const Text("Excel Spreadsheet"),
              subtitle: const Text("Create a policy in a row and column grid format"),
              onTap: () {
                Navigator.pop(ctx);
                context.push(AppRoutes.excelEditor);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusDialog(BuildContext context, String docId, String currentStatus) {
    if (currentStatus == 'active') return; // Should not reach here based on UI logic

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve & Activate Policy?'),
        content: const Text('Are you sure you want to mark this policy as ACTIVE? This will increment the version number in history.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              context.read<DocumentCubit>().updateStatus(docId, 'active');
              Navigator.pop(ctx);
            },
            child: const Text('Approve', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
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
                      Text("Performed By: ${v.performedBy} on ${DateFormat('dd MMM yyyy').format(v.performedDate)}", 
                           style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
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

  void _confirmDelete(BuildContext context, String docId, String? filePath) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Document'),
        content: const Text('Are you sure you want to delete this document?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              context.read<DocumentCubit>().deleteDocument(docId, filePath);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
