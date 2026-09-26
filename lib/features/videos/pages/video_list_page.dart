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
import 'package:iq_plus/features/auth/model/customer_model.dart';
import 'package:iq_plus/features/videos/cubit/video_cubit.dart';
import 'package:iq_plus/features/videos/cubit/video_state.dart';
import 'package:iq_plus/features/videos/models/video_model.dart';

class VideoListPage extends StatefulWidget {
  const VideoListPage({super.key});

  @override
  State<VideoListPage> createState() => _VideoListPageState();
}

class _VideoListPageState extends State<VideoListPage> {
  final _user = getIt<HiveService>().getUser();
  final _customer = getIt<HiveService>().getCustomer();

  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  String selectedCompanyFilter = 'all'; // 'all', 'public', or specific customerId

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _loadVideos() {
    final bool isConsultant = Utility.isConsultant(_user?.roleId);
    final String? consultantIdFilter = isConsultant ? _user?.userId : null;

    context.read<VideoCubit>().loadVideos(
          customerId: _customer?.customerId ?? _user?.customerId,
          userId: _user?.userId ?? _customer?.customerId,
          createdBy: consultantIdFilter,
          isConsultant: isConsultant,
        );
    // 🚀 Fetch customers to resolve names in tiles (assigned customers for consultant, all for admin/superadmin)
    context.read<CustomerListCubit>().fetchApprovedCustomers(consultantIdFilter);
  }

  void _playVideo(String url, String title) {
    context.push(AppRoutes.videoPlayer, extra: {
      'videoUrl': url,
      'title': title,
    });
  }

  bool _isCompanyValid(String value, List<CustomerModel> customerList) {
    if (value == 'all') return true;
    return customerList.any((c) => c.customerId == value);
  }

  List<AwarenessVideoModel> _getFilteredList(
    List<AwarenessVideoModel> originalList,
    List<CustomerModel> customerList,
  ) {
    return originalList.where((video) {
      // 1. Company Filter
      if (selectedCompanyFilter != 'all') {
        if (video.customerId != selectedCompanyFilter) {
          return false;
        }
      }

      // 2. Search Query
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase().trim();
        final title = video.title.toLowerCase();
        final fileName = video.fileName.toLowerCase();

        String companyName = 'all customers (public)';
        if (video.customerId != null && video.customerId!.isNotEmpty) {
          for (final c in customerList) {
            if (c.customerId == video.customerId) {
              companyName = c.companyName.toLowerCase();
              break;
            }
          }
        }

        final matches = title.contains(q) ||
            fileName.contains(q) ||
            companyName.contains(q);

        if (!matches) return false;
      }

      return true;
    }).toList();
  }

  Widget _buildSearchAndFilters(
      List<CustomerModel> customerList, bool isCustomerUser) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🔍 SEARCH BAR
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: "Search video by title or organization...",
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              prefixIcon:
                  const Icon(Icons.search, color: AppColors.purple),
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

          /// 🏢 COMPANY / ACCESS FILTER DROPDOWN
          if (!isCustomerUser) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _isCompanyValid(selectedCompanyFilter, customerList)
                      ? selectedCompanyFilter
                      : 'all',
                  isExpanded: true,
                  icon: const Icon(
                    Icons.business_rounded,
                    color: AppColors.purple,
                    size: 20,
                  ),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: 'all',
                      child: Text('All Training Videos'),
                    ),
                    ...customerList.map((customer) {
                      return DropdownMenuItem(
                        value: customer.customerId,
                        child: Text(
                          customer.companyName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedCompanyFilter = value;
                      });
                    }
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? roleId = _user?.roleId ?? _customer?.roleId;
    final bool canUpload = Utility.isAdmin(roleId) ||
        Utility.isConsultant(roleId) ||
        Utility.isSuperAdmin(roleId);
    final bool isCustomerUser = Utility.isCustomer(roleId);

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
      body: BlocBuilder<CustomerListCubit, CustomerListState>(
        builder: (context, customerState) {
          List<CustomerModel> customerList = [];
          if (customerState is CustomerListLoaded) {
            customerList = customerState.customers;
          }

          return BlocBuilder<VideoCubit, VideoState>(
            builder: (context, state) {
              if (state is VideoLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is VideoError) {
                return Center(child: Text(state.message));
              }
              if (state is VideoLoaded) {
                final videos = state.videos;
                final filteredVideos =
                    _getFilteredList(videos, customerList);

                return Column(
                  children: [
                    /// 🔍 SEARCH & FILTERS
                    _buildSearchAndFilters(customerList, isCustomerUser),

                    /// 📋 VIDEO LIST
                    Expanded(
                      child: filteredVideos.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off_rounded,
                                    size: 48,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    videos.isEmpty
                                        ? 'No videos found'
                                        : 'No matching videos found',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (searchQuery.isNotEmpty ||
                                      selectedCompanyFilter != 'all') ...[
                                    const SizedBox(height: 12),
                                    TextButton.icon(
                                      icon: const Icon(Icons.refresh),
                                      label: const Text("Clear Filters"),
                                      onPressed: () {
                                        searchController.clear();
                                        setState(() {
                                          searchQuery = '';
                                          selectedCompanyFilter = 'all';
                                        });
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              itemCount: filteredVideos.length,
                              itemBuilder: (context, index) {
                                final video = filteredVideos[index];

                                String companyName = "All Customers (Public)";
                                if (video.customerId != null &&
                                    video.customerId!.isNotEmpty) {
                                  for (final c in customerList) {
                                    if (c.customerId == video.customerId) {
                                      companyName = c.companyName;
                                      break;
                                    }
                                  }
                                  if (companyName.isEmpty &&
                                      customerState is CustomerListLoading) {
                                    companyName = "Fetching...";
                                  }
                                }

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  child: Column(
                                    children: [
                                      ListTile(
                                        contentPadding:
                                            const EdgeInsets.all(16),
                                        leading: const CircleAvatar(
                                          backgroundColor:
                                              AppColors.kPrimaryLightColor,
                                          child: Icon(
                                            Icons.play_circle_fill,
                                            color: AppColors.purple,
                                          ),
                                        ),
                                        title: Text(
                                          video.title,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.business,
                                                  size: 14,
                                                  color: Colors.blueGrey,
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    companyName,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.blueGrey,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "Added on: ${DateFormat('dd MMM yyyy').format(video.createdAt)}",
                                              style: const TextStyle(
                                                  fontSize: 12),
                                            ),
                                          ],
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              tooltip: 'View Details',
                                              icon: const Icon(
                                                  Icons.info_outline,
                                                  color: Colors.blueAccent),
                                              onPressed: () => context.push(
                                                  AppRoutes.videoDetails,
                                                  extra: video),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.play_arrow,
                                                  color: Colors.green),
                                              onPressed: () => _playVideo(
                                                  video.videoUrl, video.title),
                                            ),
                                            if (canUpload) ...[
                                              IconButton(
                                                tooltip: 'Edit Video',
                                                icon: const Icon(
                                                    Icons.edit_note_rounded,
                                                    color: Colors.blue),
                                                onPressed: () async {
                                                  await context.push(
                                                      AppRoutes.videoUpload,
                                                      extra: video);
                                                  _loadVideos();
                                                },
                                              ),
                                              IconButton(
                                                tooltip: 'Delete Video',
                                                icon: const Icon(Icons.delete,
                                                    color: Colors.red),
                                                onPressed: () => _confirmDelete(
                                                    video.videoId,
                                                    video.filePath),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              }
              return const SizedBox();
            },
          );
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
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel")),
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
