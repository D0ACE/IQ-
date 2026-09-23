import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/common/widgets/common_app_bar.dart';
import 'package:iq_plus/core/local_storage/hive_service.dart';
import 'package:iq_plus/di/service_locator.dart';
import 'package:iq_plus/features/superadmin/cubit/document_cubit.dart';
import 'package:iq_plus/features/superadmin/cubit/document_state.dart';
import 'package:iq_plus/common/utility/utility.dart';

class GlobalVersionHistoryPage extends StatefulWidget {
  const GlobalVersionHistoryPage({super.key});

  @override
  State<GlobalVersionHistoryPage> createState() => _GlobalVersionHistoryPageState();
}

class _GlobalVersionHistoryPageState extends State<GlobalVersionHistoryPage> {
  @override
  void initState() {
    super.initState();
    final user = getIt<HiveService>().getUser();
    final customer = getIt<HiveService>().getCustomer();
    
    context.read<DocumentCubit>().loadGlobalVersionHistory(
      userId: user?.userId,
      isConsultant: Utility.isConsultant(user?.roleId),
      customerId: customer?.customerId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: const CommonAppBar(title: 'All Policies Version History'),
      body: BlocBuilder<DocumentCubit, DocumentState>(
        builder: (context, state) {
          if (state is DocumentLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is DocumentError) {
            return Center(child: Text(state.message));
          }
          if (state is GlobalVersionHistoryLoaded) {
            final hive = getIt<HiveService>();
            final user = hive.getUser();
            final customer = hive.getCustomer();
            final String? roleId = user?.roleId ?? customer?.roleId;
            final bool isEmployee = Utility.isEmployee(roleId);

            final history = isEmployee 
                ? state.history.where((v) => v.status == 'active').toList() 
                : state.history;

            if (history.isEmpty) {
              return Center(child: Text(isEmployee ? 'No active policy history found' : 'No version history found'));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final v = history[index];
                final isRejected = v.status == 'rejected' || v.status == 'reject';
                final statusColor = v.status == 'active'
                    ? Colors.green
                    : isRejected
                        ? Colors.red
                        : Colors.orange;

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                v.docTitle ?? "Document History",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.purple),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                v.status.toUpperCase(),
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text("Version: ", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            Text(v.versionNo, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.purple)),
                            const Spacer(),
                            Text(
                              DateFormat('dd MMM yyyy, hh:mm a').format(v.performedDate),
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Text(
                          "Description of the change: ${v.changeDescription}",
                          style: const TextStyle(fontSize: 13, height: 1.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Performed By: ${v.performedBy} on ${DateFormat('dd MMM yyyy').format(v.performedDate)}",
                          style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.blueGrey),
                        ),
                        if (v.status == 'active' && v.approvedBy != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              "Approved by: ${v.approvedBy} on ${v.approvedDate != null ? DateFormat('dd MMM yyyy').format(v.approvedDate!) : 'N/A'}",
                              style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold),
                            ),
                          ),
                        if (isRejected && (v.rejectionReason != null || v.rejectedBy != null))
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Rejected by: ${v.rejectedBy ?? v.performedBy}",
                                  style: const TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold),
                                ),
                                if (v.rejectionReason != null && v.rejectionReason!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    "Reason: ${v.rejectionReason}",
                                    style: TextStyle(fontSize: 11, color: Colors.red.shade900, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ],
                            ),
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
}
