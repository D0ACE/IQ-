import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:iq_plus/common/routes/go_route.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/features/dashboard/page/visit_summary/cubit/visitor_summary_cubit.dart';
import 'package:iq_plus/features/dashboard/page/visit_summary/cubit/visitor_summary_state.dart';
import 'package:iq_plus/features/dashboard/page/visit_summary/pages/widgets/visitor_summary_details_dialog.dart';

class VisitorSummaryListPage extends StatefulWidget {
  const VisitorSummaryListPage({super.key});

  @override
  State<VisitorSummaryListPage> createState() =>
      _VisitorSummaryListPageState();
}

class _VisitorSummaryListPageState extends State<VisitorSummaryListPage> {

  @override
  void initState() {
    super.initState();
    context.read<VisitorSummaryCubit>().loadVisitorSummaries();
  }

  String _formatDate(dynamic value) {
    if (value == null) return '-';

    if (value.runtimeType.toString() == 'Timestamp') {
      return DateFormat('dd MMM yyyy').format(value.toDate());
    }

    if (value is DateTime) {
      return DateFormat('dd MMM yyyy').format(value);
    }

    if (value is String) {
      return value;
    }

    return '-';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Visitor Summary'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push(AppRoutes.visitorSummary);
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Visit'),
      ),
      body: BlocBuilder<VisitorSummaryCubit, VisitorSummaryState>(
        builder: (context, state) {
          if (state is VisitorSummaryLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is VisitorSummaryLoaded) {
            if (state.list.isEmpty) {
              return const Center(
                child: Text(
                  'No visitor summaries found',
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, index) {
                final item = state.list[index];

                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => VisitorSummaryDetailsDialog(model: item),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [

                        /// ─── DATE BADGE ─────────────────────────
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: AppColors.kPrimaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              _formatDate(item.visitDate),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.kPrimaryColor,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 14),

                        /// ─── DETAILS ───────────────────────────
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.clientName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      item.location,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 13,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        /// ─── DELETE ────────────────────────────
                        IconButton(
                          icon: const Icon(
                            Icons.edit_outlined,
                            color:AppColors.kPrimaryColor,
                          ),
                          onPressed: () {
                            context.push(
                              AppRoutes.visitorSummary,
                              extra: {
                                'id': item.id,
                                'visitorSummaryModel': item,
                              },
                            );
                          },
                        ),
                         /// ─── DELETE ────────────────────────────
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            _showDeleteDialog(context, item.id);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }

          if (state is VisitorSummaryError) {
            return Center(
              child: Text(
                state.error,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          return const SizedBox();
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Visitor Summary'),
        content: const Text(
          'Are you sure you want to delete this visitor summary?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              context
                  .read<VisitorSummaryCubit>()
                  .deleteVisitorSummary(id);
              Navigator.pop(context);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
