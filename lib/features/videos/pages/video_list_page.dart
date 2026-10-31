import 'package:cloud_firestore/cloud_firestore.dart';
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
import 'package:iq_plus/features/users/models/employe_user.dart';
import 'package:iq_plus/features/users/repository/user_repository.dart';
import 'package:iq_plus/features/videos/cubit/video_cubit.dart';
import 'package:iq_plus/features/videos/cubit/video_state.dart';
import 'package:iq_plus/features/videos/models/video_model.dart';
import 'package:iq_plus/features/videos/models/video_enrollment_model.dart';
import 'package:iq_plus/features/videos/repository/video_repository.dart';
import 'package:excel_plus/excel_plus.dart' as excel_pkg;
import 'dart:typed_data';
import 'package:universal_html/html.dart' as html;

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
    // ≡ƒÜÇ Fetch customers to resolve names in tiles (assigned customers for consultant, all for admin/superadmin)
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

  void _showAssignEmployeesDialog(AwarenessVideoModel video) async {
    final videoCubit = context.read<VideoCubit>();
    final customerId = _customer?.customerId ?? _user?.customerId ?? video.customerId;
    if (customerId == null || customerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Customer ID not found.")),
      );
      return;
    }

    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    List<EmployeeUserModel> employees = [];
    try {
      employees = await UserRepository(FirebaseFirestore.instance)
          .fetchEmployees(customerIds: [customerId]);
    } catch (e) {
      debugPrint("Error fetching employees: $e");
    }

    if (!mounted) return;
    navigator.pop(); // Close loading dialog

    if (employees.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("No Employees Found"),
          content: const Text("Please add employees to your company first before assigning training videos."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return;
    }

    List<String> selectedIds = List.from(video.assignedEmployeeIds);

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isAllSelected = selectedIds.length == employees.length;

            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.group_add_rounded, color: AppColors.purple),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Assign Employees",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.titleText,
                          ),
                        ),
                        Text(
                          video.title,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () {
                              setDialogState(() {
                                if (isAllSelected) {
                                  selectedIds.clear();
                                } else {
                                  selectedIds = employees.map((e) => e.userId).toList();
                                }
                              });
                            },
                            child: Text(
                              isAllSelected ? "Clear All" : "Select All",
                              style: const TextStyle(
                                color: AppColors.purple,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            "${selectedIds.length} selected",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      ...employees.map((emp) {
                        final isChecked = selectedIds.contains(emp.userId);
                        return CheckboxListTile(
                          activeColor: AppColors.purple,
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          title: Text(
                            emp.userName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isChecked ? FontWeight.bold : FontWeight.normal,
                              color: isChecked ? AppColors.titleText : Colors.black87,
                            ),
                          ),
                          subtitle: emp.designation != null && emp.designation!.isNotEmpty
                              ? Text(emp.designation!, style: const TextStyle(fontSize: 11))
                              : null,
                          value: isChecked,
                          onChanged: (bool? checked) {
                            setDialogState(() {
                              if (checked == true) {
                                if (!selectedIds.contains(emp.userId)) {
                                  selectedIds.add(emp.userId);
                                }
                              } else {
                                selectedIds.remove(emp.userId);
                              }
                            });
                          },
                        );
                      }),
                    ],
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    "Cancel",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonDarkGreen,
                    foregroundColor: AppColors.buttonYellow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    videoCubit.assignEmployeesToVideo(
                          videoId: video.videoId,
                          employeeIds: selectedIds,
                        );
                  },
                  child: const Text(
                    "Save Assignment",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSearchAndFilters(
      List<CustomerModel> customerList, bool isCustomerUser) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ≡ƒöì SEARCH BAR
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

          /// ≡ƒÅó COMPANY / ACCESS FILTER DROPDOWN
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
      appBar: const CommonAppBar(title: 'Awareness Training'),
      floatingActionButton: canUpload
          ? FloatingActionButton(
              onPressed: () async {
                await context.push(AppRoutes.videoUpload);
                _loadVideos();
              },
              backgroundColor: AppColors.buttonDarkGreen,
              child: const Icon(Icons.video_call, color: AppColors.buttonYellow),
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
                    /// ≡ƒöì SEARCH & FILTERS
                    _buildSearchAndFilters(customerList, isCustomerUser),

                    /// ≡ƒôï VIDEO LIST
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
                                            if (video.assignedEmployeeIds.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.group_rounded,
                                                    size: 14,
                                                    color: AppColors.purple,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    "Assigned to ${video.assignedEmployeeIds.length} employee(s)",
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: AppColors.purple,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
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
                                            IconButton(
                                              tooltip: 'View Enrolled Results',
                                              icon: const Icon(
                                                Icons.assessment_rounded,
                                                color: AppColors.purple,
                                              ),
                                              onPressed: () =>
                                                  _showVideoResultsDialog(video),
                                            ),
                                            if (isCustomerUser) ...[
                                              IconButton(
                                                tooltip: 'Assign Employees',
                                                icon: const Icon(
                                                  Icons.group_add_rounded,
                                                  color: AppColors.purple,
                                                ),
                                                onPressed: () =>
                                                    _showAssignEmployeesDialog(video),
                                              ),
                                            ],
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

  Future<void> _showVideoResultsDialog(AwarenessVideoModel video) async {
    final customerId = _customer?.customerId ?? _user?.customerId ?? video.customerId;
    if (customerId == null || customerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Customer ID not found.")),
      );
      return;
    }

    final navigator = Navigator.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    List<EmployeeUserModel> employees = [];
    Map<String, VideoEnrollmentModel?> enrollmentsMap = {};

    try {
      employees = await UserRepository(FirebaseFirestore.instance)
          .fetchEmployees(customerIds: [customerId]);

      for (final emp in employees) {
        final enrollments = await VideoRepository().getVideoEnrollments(
          employeeId: emp.userId,
          customerId: customerId,
        );
        final match = enrollments.where((e) => e.videoId == video.videoId).firstOrNull;
        enrollmentsMap[emp.userId] = match;
      }
    } catch (e) {
      debugPrint("Error loading employee results: $e");
    }

    final enrolledEmployees = employees.where((emp) {
      final enrollment = enrollmentsMap[emp.userId];
      return enrollment != null;
    }).toList();

    if (!mounted) return;
    navigator.pop(); // Pop loading

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.assessment_rounded, color: AppColors.purple),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Employee Training Results",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.titleText,
                    ),
                  ),
                  Text(
                    video.title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 600,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _exportVideoResultsToExcel(video, enrolledEmployees, enrollmentsMap),
                    icon: const Icon(Icons.file_download, size: 16),
                    label: const Text("Export Results"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonDarkGreen,
                      foregroundColor: AppColors.buttonYellow,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 400),
                child: enrolledEmployees.isEmpty
                    ? const Center(child: Text("No enrolled employees found."))
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: enrolledEmployees.length,
                        itemBuilder: (context, index) {
                          final emp = enrolledEmployees[index];
                          final enrollment = enrollmentsMap[emp.userId];
                          final status = enrollment?.status ?? 'assigned';
                          final isCompleted = status == 'completed';
                          final isFailed = status == 'failed';
                          final statusColor = isCompleted ? Colors.green : (isFailed ? Colors.red : Colors.orange);

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: statusColor.withValues(alpha: 0.1),
                              child: Icon(
                                isCompleted ? Icons.check_circle : (isFailed ? Icons.cancel : Icons.hourglass_top),
                                color: statusColor,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              emp.userName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            subtitle: Text(
                              "${emp.email} ΓÇó Status: ${status.toUpperCase()}",
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                            trailing: Text(
                              enrollment?.score != null ? "${enrollment?.score}/${enrollment?.totalQuestions ?? 0}" : "N/A",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            onTap: () {
                              _showEmployeeResultDetailDialog(context, emp, enrollment, video.title);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Close", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEmployeeResultDetailDialog(
      BuildContext context, EmployeeUserModel emp, VideoEnrollmentModel? enrollment, String videoTitle) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Result Details: ${emp.userName}",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildResultDetailRow("Video Title", videoTitle),
            _buildResultDetailRow("Employee Name", emp.userName),
            _buildResultDetailRow("Email", emp.email),
            _buildResultDetailRow("Designation", emp.designation ?? 'N/A'),
            _buildResultDetailRow("Status", (enrollment?.status ?? 'Not Enrolled').toUpperCase()),
            _buildResultDetailRow("Score", enrollment?.score != null ? "${enrollment?.score} / ${enrollment?.totalQuestions ?? 0}" : 'N/A'),
            _buildResultDetailRow("Attempt Count", "${enrollment?.attemptCount ?? 0} / 3"),
            _buildResultDetailRow("Enrolled At", enrollment != null ? DateFormat('dd MMM yyyy, hh:mm a').format(enrollment.enrolledAt) : 'N/A'),
            _buildResultDetailRow("Completed At", enrollment?.completedAt != null ? DateFormat('dd MMM yyyy, hh:mm a').format(enrollment!.completedAt!) : 'N/A'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Close", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildResultDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              "$label:",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.titleText, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportVideoResultsToExcel(
    AwarenessVideoModel video,
    List<EmployeeUserModel> employees,
    Map<String, VideoEnrollmentModel?> enrollmentsMap,
  ) async {
    var excel = excel_pkg.Excel.createExcel();
    var sheet = excel['Sheet1'];
    final headerStyle = excel_pkg.CellStyle(bold: true);
    final headers = ['Employee Name', 'Email', 'Designation', 'Status', 'Score', 'Attempts', 'Enrolled Date', 'Completion Date'];

    for (int i = 0; i < headers.length; i++) {
      sheet.updateCell(
        excel_pkg.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
        excel_pkg.TextCellValue(headers[i]),
        cellStyle: headerStyle,
      );
    }

    for (var emp in employees) {
      final enrollment = enrollmentsMap[emp.userId];
      final status = enrollment?.status ?? 'Not Enrolled';
      final score = enrollment != null && enrollment.score != null
          ? "${enrollment.score} / ${enrollment.totalQuestions ?? 0}"
          : 'N/A';
      final attempts = enrollment?.attemptCount.toString() ?? '0';
      final enrolledDate = enrollment != null
          ? DateFormat('dd MMM yyyy').format(enrollment.enrolledAt)
          : 'N/A';
      final completionDate = enrollment?.completedAt != null
          ? DateFormat('dd MMM yyyy').format(enrollment!.completedAt!)
          : 'N/A';

      sheet.appendRow([
        excel_pkg.TextCellValue(emp.userName),
        excel_pkg.TextCellValue(emp.email),
        excel_pkg.TextCellValue(emp.designation ?? ''),
        excel_pkg.TextCellValue(status.toUpperCase()),
        excel_pkg.TextCellValue(score),
        excel_pkg.TextCellValue(attempts),
        excel_pkg.TextCellValue(enrolledDate),
        excel_pkg.TextCellValue(completionDate),
      ]);
    }

    final List<int>? fileBytes = excel.encode();
    if (fileBytes != null) {
      final blob = html.Blob([Uint8List.fromList(fileBytes)], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", "Training_Results_${video.title.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}.xlsx")
        ..click();
      html.Url.revokeObjectUrl(url);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Exported training results to Excel successfully")),
      );
    }
  }
}
