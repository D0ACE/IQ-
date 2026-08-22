import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/common/widgets/common_app_bar.dart';
import 'package:iq_plus/features/admin/customers/cubit/customer_list_cubit.dart';
import 'package:iq_plus/features/admin/customers/cubit/customer_list_state.dart';
import 'package:iq_plus/features/videos/models/video_model.dart';

class VideoDetailsPage extends StatelessWidget {
  final AwarenessVideoModel video;
  const VideoDetailsPage({super.key, required this.video});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: CommonAppBar(title: 'Training Module Details'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🎥 Video Header
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: AppColors.mainGradient,
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.video_collection, color: Colors.white, size: 40),
                    const SizedBox(height: 12),
                    Text(
                      video.title,
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            /// 🏢 Assigned Company Section
            const Text("Assigned To", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            BlocBuilder<CustomerListCubit, CustomerListState>(
              builder: (context, state) {
                String companyName = "All Customers (Public)";
                if (video.customerId != null && state is CustomerListLoaded) {
                  try {
                    companyName = state.customers
                        .firstWhere((c) => c.customerId == video.customerId)
                        .companyName;
                  } catch (_) {
                    companyName = "Unknown Customer";
                  }
                }
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.business, color: AppColors.purple, size: 20),
                      const SizedBox(width: 12),
                      Text(companyName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 32),

            /// 📝 MCQs Section
            Row(
              children: [
                const Text("MCQ Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.purple.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text("${video.questions.length}", style: const TextStyle(color: AppColors.purple, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (video.questions.isEmpty)
              const Center(child: Text("No questions added for this video", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey))),
            
            ...List.generate(video.questions.length, (index) {
              final q = video.questions[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Question ${index + 1}", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(q.question, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const Divider(height: 24),
                      ...List.generate(q.options.length, (optIdx) {
                        final isCorrect = optIdx == q.correctOptionIndex;
                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isCorrect ? Colors.green.shade50 : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isCorrect ? Colors.green.shade200 : Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Text("${String.fromCharCode(65 + optIdx)}.", style: TextStyle(fontWeight: FontWeight.bold, color: isCorrect ? Colors.green : Colors.grey)),
                              const SizedBox(width: 10),
                              Expanded(child: Text(q.options[optIdx], style: TextStyle(color: isCorrect ? Colors.green.shade800 : Colors.black87, fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal))),
                              if (isCorrect) const Icon(Icons.check_circle, color: Colors.green, size: 16),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
