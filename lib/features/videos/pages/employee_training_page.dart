import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:iq_plus/common/routes/go_route.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/common/widgets/common_app_bar.dart';
import 'package:iq_plus/core/local_storage/hive_service.dart';
import 'package:iq_plus/di/service_locator.dart';
import 'package:iq_plus/common/utility/utility.dart';
import 'package:iq_plus/features/videos/cubit/video_cubit.dart';
import 'package:iq_plus/features/videos/cubit/video_state.dart';
import 'package:iq_plus/features/videos/models/video_model.dart';
import 'package:iq_plus/features/videos/models/video_enrollment_model.dart';

class EmployeeTrainingPage extends StatefulWidget {
  const EmployeeTrainingPage({super.key});

  @override
  State<EmployeeTrainingPage> createState() => _EmployeeTrainingPageState();
}

class _EmployeeTrainingPageState extends State<EmployeeTrainingPage> {
  final _user = getIt<HiveService>().getUser();
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    if (_user != null) {
      context.read<VideoCubit>().loadVideos(
        customerId: _user.customerId,
        userId: _user.userId,
      );
    }
  }

  void _playVideo(String url, String title, AwarenessVideoModel video) {
    context.push(AppRoutes.videoPlayer, extra: {
      'videoUrl': url,
      'title': title,
      'onVideoEnd': () {
        context.pushReplacement(AppRoutes.videoQuiz, extra: video);
      },
    });
  }

  void _showResultDialog(AwarenessVideoModel video, VideoEnrollmentModel enrollment) {
    double percentage = 0;
    if (enrollment.score != null && enrollment.totalQuestions != null && enrollment.totalQuestions! > 0) {
      percentage = (enrollment.score! / enrollment.totalQuestions!) * 100;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(video.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _resultRow("Status", enrollment.status.toUpperCase(), Colors.green),
            _resultRow("Enrolled On", DateFormat('dd MMM yyyy').format(enrollment.enrolledAt), Colors.black87),
            if (enrollment.completedAt != null)
              _resultRow("Completed On", DateFormat('dd MMM yyyy').format(enrollment.completedAt!), Colors.black87),
            if (enrollment.score != null)
              _resultRow("Score", "${enrollment.score} / ${enrollment.totalQuestions}", AppColors.purple),
            if (enrollment.score != null)
              _resultRow("Percentage", "${percentage.round()}%", Colors.blue),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close")),
        ],
      ),
    );
  }

  Widget _resultRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: valueColor, fontSize: 14)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: CommonAppBar(
        title: 'Available Trainings',
        actions: [
          BlocBuilder<VideoCubit, VideoState>(
            builder: (context, state) {
              final cubit = context.read<VideoCubit>();
              final hasCompletedTraining = cubit.enrollments.any((e) => e.status == 'completed');
              if (hasCompletedTraining) {
                return TextButton.icon(
                  onPressed: () => context.push(AppRoutes.trainingResults),
                  icon: const Icon(Icons.assignment_turned_in, color: Colors.white, size: 18),
                  label: const Text(
                    "View Training Results",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocConsumer<VideoCubit, VideoState>(
        listener: (context, state) {
          if (state is VideoOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
          if (state is VideoError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state is VideoLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final cubit = context.read<VideoCubit>();

          if (state is VideoLoaded) {
            final videosList = state.videos;
            if (videosList.isEmpty) {
              return const Center(child: Text('No trainings available for you at this moment.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: videosList.length,
              itemBuilder: (context, index) {
                final video = videosList[index];
                
                VideoEnrollmentModel? enrollment;
                try {
                  enrollment = cubit.enrollments.firstWhere((e) => e.videoId == video.videoId);
                } catch (_) {}

                final bool isEnrolled = enrollment != null;
                final bool isCompleted = enrollment?.status == 'completed';

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.kPrimaryLightColor,
                          child: Icon(Icons.video_library, color: AppColors.purple),
                        ),
                        title: Text(video.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Added on: ${DateFormat('dd MMM yyyy').format(video.createdAt)}", style: const TextStyle(fontSize: 12)),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: SizedBox(
                          width: double.infinity,
                          child: isCompleted
                              ? ElevatedButton.icon(
                                  onPressed: () => _showResultDialog(video, enrollment!),
                                  icon: const Icon(Icons.assignment_turned_in),
                                  label: const Text("View Training Results"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueAccent,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                )
                              : isEnrolled
                                  ? ElevatedButton.icon(
                                      onPressed: () => _playVideo(video.videoUrl, video.title, video),
                                      icon: const Icon(Icons.play_circle_fill),
                                      label: const Text("Start Training"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    )
                                  : ElevatedButton.icon(
                                      onPressed: () async {
                                        await context.read<VideoCubit>().enrollInVideo(
                                          videoId: video.videoId,
                                          employeeId: _user!.userId,
                                          customerId: _user.customerId!,
                                        );
                                        if(mounted) {
                                           _playVideo(video.videoUrl, video.title, video);
                                        }
                                      },
                                      icon: const Icon(Icons.add_task),
                                      label: const Text("Enroll in Training"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.purple,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
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
}
