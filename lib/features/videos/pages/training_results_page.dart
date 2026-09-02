import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/common/widgets/common_app_bar.dart';
import 'package:iq_plus/core/local_storage/hive_service.dart';
import 'package:iq_plus/di/service_locator.dart';
import 'package:iq_plus/features/videos/cubit/video_cubit.dart';
import 'package:iq_plus/features/videos/cubit/video_state.dart';
import 'package:iq_plus/features/videos/models/video_model.dart';
import 'package:iq_plus/features/videos/models/video_enrollment_model.dart';
import 'package:excel_plus/excel_plus.dart' as excel_pkg;
import 'dart:typed_data';
import 'package:universal_html/html.dart' as html;

class TrainingResultsPage extends StatefulWidget {
  final String? userId;
  final String? userName;
  final String? customerId; // 🚀 Added customerId parameter
  const TrainingResultsPage({super.key, this.userId, this.userName, this.customerId});

  @override
  State<TrainingResultsPage> createState() => _TrainingResultsPageState();
}

class _TrainingResultsPageState extends State<TrainingResultsPage> {
  final _currentUser = getIt<HiveService>().getUser();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final targetUserId = widget.userId ?? _currentUser?.userId;
    // Use the passed customerId or fallback to current user's customerId
    final customerId = widget.customerId ?? _currentUser?.customerId;

    if (targetUserId != null && customerId != null) {
      context.read<VideoCubit>().loadVideos(
        customerId: customerId,
        userId: targetUserId,
      );
    } else {
      debugPrint("TrainingResultsPage: Missing targetUserId ($targetUserId) or customerId ($customerId)");
    }
  }

  Future<void> _exportToExcel(List<AwarenessVideoModel> videos, List<VideoEnrollmentModel> enrollments) async {
    final completedEnrollments = enrollments.where((e) => e.status == 'completed').toList();
    
    if (completedEnrollments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No completed trainings to export")),
      );
      return;
    }

    var excel = excel_pkg.Excel.createExcel();
    // Use 'Sheet1' which is the default sheet created by the library
    var sheet = excel['Sheet1'];
    
    // Header with Bold Style
    final headerStyle = excel_pkg.CellStyle(bold: true);
    final headers = ['Video Title', 'Enroll Date', 'Completion Date', 'Score', 'Status'];
    
    for (int i = 0; i < headers.length; i++) {
      sheet.updateCell(
        excel_pkg.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
        excel_pkg.TextCellValue(headers[i]),
        cellStyle: headerStyle,
      );
    }

    for (var enrollment in completedEnrollments) {
      final video = videos.firstWhere((v) => v.videoId == enrollment.videoId, 
          orElse: () => AwarenessVideoModel(
            videoId: '', title: 'Unknown', videoUrl: '', fileName: '', 
            filePath: '', createdBy: '', questions: [], createdAt: DateTime.now()
          ));
      
      sheet.appendRow([
        excel_pkg.TextCellValue(video.title),
        excel_pkg.TextCellValue(DateFormat('dd MMM yyyy').format(enrollment.enrolledAt)),
        excel_pkg.TextCellValue(enrollment.completedAt != null ? DateFormat('dd MMM yyyy').format(enrollment.completedAt!) : 'N/A'),
        excel_pkg.TextCellValue("${enrollment.score ?? 0} / ${enrollment.totalQuestions ?? 0}"),
        excel_pkg.TextCellValue(enrollment.status.toUpperCase()),
      ]);
    }

    final List<int>? fileBytes = excel.encode();
    if (fileBytes != null) {
      final targetUserName = widget.userName ?? _currentUser?.userName ?? 'Employee';
      final blob = html.Blob([Uint8List.fromList(fileBytes)], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", "Training_Results_$targetUserName.xlsx")
        ..click();
      html.Url.revokeObjectUrl(url);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Exported to Excel successfully")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to generate Excel file"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.userName != null ? "${widget.userName}'s Training Results" : 'My Training Results';
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: CommonAppBar(title: title),
      body: BlocBuilder<VideoCubit, VideoState>(
        builder: (context, state) {
          if (state is VideoLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is VideoLoaded) {
            final cubit = context.read<VideoCubit>();
            final completedEnrollments = cubit.enrollments.where((e) => e.status == 'completed').toList();

            if (completedEnrollments.isEmpty) {
              return const Center(child: Text("No completed trainings found."));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Completed Trainings",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _exportToExcel(state.videos, cubit.enrollments),
                        icon: const Icon(Icons.file_download),
                        label: const Text("Export Training"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.purple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(AppColors.purple.withValues(alpha: 0.1)),
                        columns: const [
                          DataColumn(label: Text('Video Title', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Enroll Date', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Score', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Completion Date', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: completedEnrollments.map((enrollment) {
                          final video = state.videos.firstWhere((v) => v.videoId == enrollment.videoId, 
                            orElse: () => AwarenessVideoModel(
                              videoId: '', title: 'Unknown', videoUrl: '', fileName: '', 
                              filePath: '', createdBy: '', questions: [], createdAt: DateTime.now()
                            ));
                          
                          return DataRow(cells: [
                            DataCell(Text(video.title)),
                            DataCell(Text(DateFormat('dd MMM yyyy').format(enrollment.enrolledAt))),
                            DataCell(Text("${enrollment.score} / ${enrollment.totalQuestions}")),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text("COMPLETED", style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            DataCell(Text(enrollment.completedAt != null ? DateFormat('dd MMM yyyy').format(enrollment.completedAt!) : '-')),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          if (state is VideoError) {
            return Center(child: Text(state.message));
          }

          return const SizedBox();
        },
      ),
    );
  }
}
