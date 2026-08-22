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
import 'package:iq_plus/features/admin/customers/cubit/customer_list_cubit.dart';
import 'package:iq_plus/features/admin/customers/cubit/customer_list_state.dart';
import 'package:iq_plus/features/videos/cubit/video_cubit.dart';
import 'package:iq_plus/features/videos/cubit/video_state.dart';

class VideoListPage extends StatefulWidget {
  const VideoListPage({super.key});

  @override
  State<VideoListPage> createState() => _VideoListPageState();
}

class _VideoListPageState extends State<VideoListPage> {
  final _user = getIt<HiveService>().getUser();
  final _customer = getIt<HiveService>().getCustomer();

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  void _loadVideos() {
    context.read<VideoCubit>().loadVideos(
      customerId: _customer?.customerId ?? _user?.customerId,
      userId: _user?.userId ?? _customer?.customerId, 
      createdBy: Utility.isConsultant(_user?.roleId) ? _user?.userId : null,
    );
    // 🚀 Fetch customers to resolve names in tiles
    context.read<CustomerListCubit>().fetchApprovedCustomers(null);
  }

  void _playVideo(String url, String title) {
    context.push(AppRoutes.videoPlayer, extra: {
      'videoUrl': url,
      'title': title,
    });
  }

  @override
  Widget build(BuildContext context) {
    final String? roleId = _user?.roleId ?? _customer?.roleId;
    final bool canUpload = Utility.isAdmin(roleId) || Utility.isConsultant(roleId) || Utility.isSuperAdmin(roleId);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: const CommonAppBar(title: 'Training & Awareness Videos'),
      floatingActionButton: canUpload
          ? FloatingActionButton(
              onPressed: () async {
                await context.push(AppRoutes.videoUpload);
                _loadVideos(); 
              },
              backgroundColor: AppColors.purple,
              child: const Icon(Icons.video_call, color: Colors.white),
            )
          : null,
      body: BlocBuilder<VideoCubit, VideoState>(
        builder: (context, state) {
          if (state is VideoLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is VideoError) {
            return Center(child: Text(state.message));
          }
          if (state is VideoLoaded) {
            final videos = state.videos;
            if (videos.isEmpty) {
              return const Center(child: Text('No videos found'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: videos.length,
              itemBuilder: (context, index) {
                final video = videos[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.kPrimaryLightColor,
                          child: Icon(Icons.play_circle_fill, color: AppColors.purple),
                        ),
                        title: Text(video.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            BlocBuilder<CustomerListCubit, CustomerListState>(
                              builder: (context, customerState) {
                                String companyName = "All Customers (Public)";
                                if (video.customerId != null) {
                                  if (customerState is CustomerListLoaded) {
                                    try {
                                      companyName = customerState.customers
                                          .firstWhere((c) => c.customerId == video.customerId)
                                          .companyName;
                                    } catch (_) {
                                      companyName = "Unknown Company";
                                    }
                                  } else if (customerState is CustomerListLoading) {
                                    companyName = "Fetching...";
                                  }
                                }
                                return Row(
                                  children: [
                                    const Icon(Icons.business, size: 14, color: Colors.blueGrey),
                                    const SizedBox(width: 6),
                                    Text(
                                      companyName,
                                      style: const TextStyle(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 4),
                            Text("Added on: ${DateFormat('dd MMM yyyy').format(video.createdAt)}", style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'View Details',
                              icon: const Icon(Icons.info_outline, color: Colors.blueAccent),
                              onPressed: () => context.push(AppRoutes.videoDetails, extra: video),
                            ),
                            IconButton(
                              icon: const Icon(Icons.play_arrow, color: Colors.green),
                              onPressed: () => _playVideo(video.videoUrl, video.title),
                            ),
                            if (canUpload)
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _confirmDelete(video.videoId, video.filePath),
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

  void _confirmDelete(String videoId, String filePath) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Video'),
        content: const Text('Are you sure you want to delete this video?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              context.read<VideoCubit>().deleteVideo(videoId, filePath);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
