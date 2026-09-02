import 'dart:ui';
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
    final hive = getIt<HiveService>();
    final customer = hive.getCustomer();
    final user = hive.getUser();

    // 🚀 Determine customerId from either Customer or Employee session
    final String? effectiveCustomerId = customer?.customerId ?? user?.customerId;

    context.read<DocumentCubit>().loadDocuments(
      customerId: effectiveCustomerId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const CommonAppBar(title: 'My Policies & Procedures'),
      body: Stack(
        children: [
          // 🎨 Optimized Dot Pattern Background (Non-interactive)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _DotPatternPainter(
                  dotColor: AppColors.kPrimaryColor.withValues(alpha: 0.05),
                ),
              ),
            ),
          ),

          BlocBuilder<DocumentCubit, DocumentState>(
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  physics: const BouncingScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: _neoModernPolicyCard(doc),
                    );
                  },
                );
              }
              return const SizedBox();
            },
          ),
        ],
      ),
    );
  }

  Widget _neoModernPolicyCard(dynamic doc) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () => context.push(AppRoutes.customerPolicyDetail, extra: doc.docId),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(_getFileIcon(doc.fileType), color: const Color(0xFF6366F1), size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doc.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              color: AppColors.titleText,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.kPrimaryLightColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "${doc.currentVersion}",
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.kPrimaryColor,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Prepared on ${DateFormat('dd MMM').format(doc.createdAt)}",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.subText.withValues(alpha: 0.6),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.history_rounded, color: AppColors.subText),
                      onPressed: () => _showVersionHistoryDialog(context, doc.docId, doc.title),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Divider(color: Colors.black12, height: 1),
                ),
                Row(
                  children: [
                    Expanded(child: _auditItemModern("Prepared By", doc.createdBy, Icons.edit_note_rounded)),
                    Expanded(child: _auditItemModern("Reviewed By", doc.reviewedBy ?? "N/A", Icons.rate_review_rounded)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _auditItemModern(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.subText.withValues(alpha: 0.4)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: AppColors.subText.withValues(alpha: 0.5),
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.titleText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showVersionHistoryDialog(BuildContext context, String docId, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Version History',
              style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.titleText),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.subText.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: FutureBuilder<List<VersionHistoryModel>>(
            future: DocumentRepository().getVersionHistory(docId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }
              final history = snapshot.data ?? [];
              if (history.isEmpty) {
                return const SizedBox(
                  height: 100,
                  child: Center(child: Text("No history found")),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: history.length,
                separatorBuilder: (ctx, index) => const SizedBox(height: 16),
                itemBuilder: (ctx, index) {
                  final v = history[index];
                  final isActive = v.status == 'active';
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.purple.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    v.versionNo,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.purple,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (isActive ? Colors.green : Colors.orange).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    v.status.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: isActive ? Colors.green : Colors.orange,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              DateFormat('dd MMM yyyy').format(v.performedDate),
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.subText.withValues(alpha: 0.6),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          v.changeDescription,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.titleText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "by ${v.performedBy}",
                          style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: AppColors.subText.withValues(alpha: 0.7),
                          ),
                        ),
                        if (isActive && v.approvedBy != null)
                          Container(
                            margin: const EdgeInsets.only(top: 10),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.verified_rounded, color: Colors.green, size: 14),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Approved by ${v.approvedBy}",
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.green,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Close',
              style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.purple),
            ),
          ),
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

class _DotPatternPainter extends CustomPainter {
  final Color dotColor;
  _DotPatternPainter({required this.dotColor});

  @override
  void paint(Canvas canvas, Size size) {
    const double spacing = 30.0;
    final paint = Paint()
      ..color = dotColor
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final List<Offset> points = [];
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        points.add(Offset(x, y));
      }
    }
    canvas.drawPoints(PointMode.points, points, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
