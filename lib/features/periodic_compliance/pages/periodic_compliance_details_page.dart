import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:iq_plus/common/utility/app_validation.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/di/service_locator.dart';
import 'package:iq_plus/features/auth/model/customer_model.dart';
import 'package:iq_plus/features/auth/repository/auth_repository.dart';
import '../models/periodic_compliance_model.dart';

class PeriodicComplianceDetailsPage extends StatelessWidget {
  final PeriodicComplianceTask task;

  const PeriodicComplianceDetailsPage({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.titleText,
        title: const Text('Task Details', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _statusChip(task.effectiveStatus),
                      Text(
                        'Due: ${DateFormat('dd MMM yyyy').format(task.dueDate)}',
                        style: TextStyle(
                          color: task.isNonCompliant ? Colors.red : Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.titleText,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    task.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 24),
                  _infoRow(Icons.business_rounded, 'Assigned To', task.assignedCustomerName),
                  _buildLowerPersonSection(),
                  const SizedBox(height: 16),
                  _infoRow(Icons.person_rounded, 'Created By', task.createdByName),
                  const SizedBox(height: 16),
                  _infoRow(Icons.event_available_rounded, 'Created On', DateFormat('dd MMM yyyy HH:mm').format(task.createdAt)),
                  _buildAutoGenerateSection(),
                  _buildTargetAchievedSection(),
                  _buildCommentSection(),
                  _buildEvidenceDocumentSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoGenerateSection() {
    if (!task.isAutoGenerate) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _infoRow(
          Icons.autorenew_rounded,
          'Auto Generate',
          'Enabled (${task.frequency})',
        ),
      ],
    );
  }

  Widget _buildCommentSection() {
    if (task.comment.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        const Text(
          'Comments / Notes',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: AppColors.primary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.shade50.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amber.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.comment_rounded, color: Colors.amber.shade800, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  task.comment,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.titleText,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTargetAchievedSection() {
    if (task.target.isEmpty && task.achieved.isEmpty) {
      return const SizedBox.shrink();
    }

    final String displayTarget = task.targetType == 'Number'
        ? task.target.replaceAll('%', '')
        : (task.target.endsWith('%') ? task.target : '${task.target}%');
    final String displayAchieved = task.achievedType == 'Number'
        ? task.achieved.replaceAll('%', '')
        : (task.achieved.endsWith('%') ? task.achieved : '${task.achieved}%');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        const Text(
          'Target & Achieved',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: AppColors.primary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            if (task.target.isNotEmpty)
              Expanded(
                child: _infoCard('Target', displayTarget, Icons.track_changes_rounded, Colors.blue),
              ),
            if (task.target.isNotEmpty && task.achieved.isNotEmpty)
              const SizedBox(width: 16),
            if (task.achieved.isNotEmpty)
              Expanded(
                child: _infoCard('Achieved', displayAchieved, Icons.emoji_events_rounded, Colors.green),
              ),
          ],
        ),
      ],
    );
  }

  Widget _infoCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLowerPersonSection() {
    if (task.assignedCustomerLowLevelName.isNotEmpty ||
        task.assignedCustomerLowLevelEmail.isNotEmpty ||
        task.assignedCustomerLowLevelMobile.isNotEmpty) {
      return _lowerPersonCard(
        task.assignedCustomerLowLevelName,
        task.assignedCustomerLowLevelEmail,
        task.assignedCustomerLowLevelMobile,
      );
    }

    if (task.assignedCustomerId.isEmpty) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<CustomerModel?>(
      future: getIt<AuthRepository>().getCustomerById(task.assignedCustomerId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }
        final customer = snapshot.data!;
        return _lowerPersonCard(
          customer.lowLevelName,
          customer.lowLevelEmail,
          customer.lowLevelMobile,
        );
      },
    );
  }

  Widget _lowerPersonCard(String name, String email, String mobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _infoRow(Icons.person_outline_rounded, 'Lower Person Name', name.isNotEmpty ? name : 'N/A'),
        const SizedBox(height: 16),
        _infoRow(Icons.email_outlined, 'Lower Person Email', email.isNotEmpty ? email : 'N/A'),
        const SizedBox(height: 16),
        _infoRow(Icons.phone_android_rounded, 'Lower Person Phone', mobile.isNotEmpty ? AppValidation.formatPhoneForDisplay(mobile) : 'N/A'),
      ],
    );
  }

  Widget _statusChip(String status) {
    Color color = Colors.orange;
    String text = 'OPEN';
    IconData icon = Icons.lock_open_rounded;

    switch (status.toLowerCase()) {
      case 'completed':
        color = Colors.green;
        text = 'COMPLETED';
        icon = Icons.check_circle_rounded;
        break;
      case 'in_progress':
      case 'in progress':
        color = Colors.blue;
        text = 'IN PROGRESS';
        icon = Icons.autorenew_rounded;
        break;
      case 'non_compliant':
      case 'non compliant':
        color = Colors.red;
        text = 'NON COMPLIANT';
        icon = Icons.gpp_bad_rounded;
        break;
      case 'open':
      case 'pending':
      default:
        color = Colors.orange;
        text = 'OPEN';
        icon = Icons.lock_open_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.titleText),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEvidenceDocumentSection() {
    if (task.evidenceUrl.isEmpty) {
      return const SizedBox.shrink();
    }

    final urls = task.evidenceUrl.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final names = task.evidenceFileName.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        Text(
          'Evidence Documents (${urls.length})',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: AppColors.primary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),
        Column(
          children: List.generate(urls.length, (index) {
            final url = urls[index];
            final name = (index < names.length && names[index].isNotEmpty)
                ? names[index]
                : 'Evidence Document ${index + 1}';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () async {
                  final uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.description_rounded, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.titleText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Tap to open document',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.open_in_new_rounded, color: AppColors.primary, size: 20),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
