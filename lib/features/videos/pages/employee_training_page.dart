import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:iq_plus/common/routes/go_route.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/common/widgets/common_app_bar.dart';
import 'package:iq_plus/core/local_storage/hive_service.dart';
import 'package:iq_plus/di/service_locator.dart';
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
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
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

    final bool isPassed = enrollment.status == 'completed';
    final Color statusColor = isPassed ? Colors.green : Colors.red;
    final String statusText = isPassed ? "COMPLETED (PASSED)" : "FAILED (<80%)";

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(video.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _resultRow("Status", statusText, statusColor),
            _resultRow("Attempts Used", "${enrollment.attemptCount} / 3", Colors.black87),
            _resultRow("Enrolled On", DateFormat('dd MMM yyyy').format(enrollment.enrolledAt), Colors.black87),
            if (enrollment.completedAt != null)
              _resultRow("Completed On", DateFormat('dd MMM yyyy').format(enrollment.completedAt!), Colors.black87),
            if (enrollment.score != null)
              _resultRow("Score", "${enrollment.score} / ${enrollment.totalQuestions}", AppColors.purple),
            if (enrollment.score != null)
              _resultRow("Percentage", "${percentage.round()}%", statusColor),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CLOSE")),
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
      appBar: const CommonAppBar(
        title: 'My Training Videos',
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
            final rawVideosList = state.videos;
            final videosList = rawVideosList.where((v) {
              if (_user == null) return false;
              final bool matchesCustomer = v.customerId == null || v.customerId!.isEmpty || v.customerId == _user.customerId;
              final bool hasAccess = v.accessToOtherEmployees || v.assignedEmployeeIds.contains(_user.userId);
              return matchesCustomer && hasAccess;
            }).toList();
            final hasCompletedTraining = cubit.enrollments.any((e) => e.status == 'completed' || e.status == 'failed');

            final filteredVideosList = searchQuery.isEmpty
                ? videosList
                : videosList.where((v) {
                    final q = searchQuery.toLowerCase().trim();
                    return v.title.toLowerCase().contains(q) ||
                        v.fileName.toLowerCase().contains(q);
                  }).toList();

            if (videosList.isEmpty && !hasCompletedTraining) {
              return const Center(child: Text('No trainings available for you at this moment.'));
            }

            return ListView(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              children: [
                if (hasCompletedTraining) ...[
                  _resultsCompactTile(),
                  const SizedBox(height: 24),
                ],

                /// 🔍 SEARCH BAR
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: "Search course by title...",
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    prefixIcon: const Icon(Icons.search, color: AppColors.purple),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              searchController.clear();
                              setState(() {
                                searchQuery = '';
                              });
                            },
                          )
                        : null,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {
                      searchQuery = val;
                    });
                  },
                ),
                const SizedBox(height: 16),

                const Text(
                  "Assigned Courses",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.titleText,
                  ),
                ),
                const SizedBox(height: 16),
                if (filteredVideosList.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        "No matching courses found",
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                      ),
                    ),
                  )
                else
                  ...filteredVideosList.map((video) {
                    VideoEnrollmentModel? enrollment;
                    try {
                      enrollment = cubit.enrollments.firstWhere((e) => e.videoId == video.videoId);
                    } catch (_) {}

                    return _trainingCard(video, enrollment);
                  }),
              ],
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _resultsCompactTile() {
    const Color accentColor = Color(0xFF10B981); // Emerald
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accentColor.withValues(alpha: 0.1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              bottom: -10,
              child: Icon(
                Icons.assignment_turned_in_rounded,
                size: 80,
                color: accentColor.withValues(alpha: 0.06),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.push(AppRoutes.trainingResults),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.assignment_turned_in_rounded, color: accentColor, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "My Training Results",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: AppColors.titleText,
                              ),
                            ),
                            Text(
                              "View your scores and history",
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.subText.withValues(alpha: 0.6),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_forward_ios_rounded, color: accentColor, size: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _trainingCard(AwarenessVideoModel video, VideoEnrollmentModel? enrollment) {
    final bool isEnrolled = enrollment != null;
    final bool isCompleted = enrollment?.status == 'completed';
    final bool isFailed = enrollment?.status == 'failed';
    final bool isInProgress = enrollment?.status == 'enrolled';
    final int attempts = enrollment?.attemptCount ?? 0;
    final bool canRetry = attempts < 3 && !isCompleted;

    String statusLabel = "NOT STARTED";
    Color statusColor = AppColors.purple;

    if (isCompleted) {
      statusLabel = "COMPLETED";
      statusColor = Colors.green;
    } else if (isFailed) {
      statusLabel = "FAILED ($attempts/3)";
      statusColor = Colors.red;
    } else if (isInProgress) {
      statusLabel = "IN PROGRESS ($attempts/3)";
      statusColor = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              bottom: -10,
              child: Icon(
                Icons.video_library_rounded,
                size: 80,
                color: AppColors.purple.withValues(alpha: 0.04),
              ),
            ),
            Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.kPrimaryLightColor.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.video_library_rounded, color: AppColors.purple, size: 24),
                  ),
                  title: Text(
                    video.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: AppColors.titleText,
                      letterSpacing: -0.5,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      "Added on ${DateFormat('dd MMM yyyy').format(video.createdAt)}",
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.subText.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 🏷 Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: statusColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),

                      // 🚀 Action Buttons
                      Row(
                        children: [
                          if (isCompleted || isFailed)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: OutlinedButton.icon(
                                onPressed: () => _showResultDialog(video, enrollment!),
                                icon: const Icon(Icons.visibility_rounded, size: 14),
                                label: const Text("RESULT"),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.buttonYellow,
                                  side: const BorderSide(color: AppColors.purple),
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            ),
                          if (isCompleted)
                            const SizedBox.shrink()
                          else if (isInProgress)
                            ElevatedButton.icon(
                              onPressed: () => _playVideo(video.videoUrl, video.title, video),
                              icon: const Icon(Icons.play_arrow_rounded, size: 16),
                              label: const Text("CONTINUE"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.buttonDarkGreen,
                                foregroundColor: AppColors.buttonYellow,
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            )
                          else if (!isEnrolled)
                            ElevatedButton.icon(
                              onPressed: () async {
                                await context.read<VideoCubit>().enrollInVideo(
                                      videoId: video.videoId,
                                      employeeId: _user!.userId,
                                      customerId: _user.customerId!,
                                    );
                                if (mounted) _playVideo(video.videoUrl, video.title, video);
                              },
                              icon: const Icon(Icons.add_task_rounded, size: 16),
                              label: const Text("ENROLL NOW"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.buttonDarkGreen,
                                foregroundColor: AppColors.buttonYellow,
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            )
                          else if (isFailed && canRetry)
                            ElevatedButton.icon(
                              onPressed: () async {
                                await context.read<VideoCubit>().enrollInVideo(
                                      videoId: video.videoId,
                                      employeeId: _user!.userId,
                                      customerId: _user.customerId!,
                                    );
                                if (mounted) _playVideo(video.videoUrl, video.title, video);
                              },
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: Text("RETRY (${3 - attempts} LEFT)"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.buttonDarkGreen,
                                foregroundColor: AppColors.buttonYellow,
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            )
                          else if (isFailed && !canRetry)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                "Max Retries Reached",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
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
          ],
        ),
      ),
    );
  }
}
