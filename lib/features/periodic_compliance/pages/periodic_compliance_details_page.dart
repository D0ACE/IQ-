import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
    final bool isPending = task.status == 'pending';

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
                      _statusChip(isPending),
                      Text(
                        'Due: ${DateFormat('dd MMM yyyy').format(task.dueDate)}',
                        style: TextStyle(
                          color: isPending && task.dueDate.isBefore(DateTime.now()) ? Colors.red : Colors.grey,
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
                ],
              ),
            ),
          ],
        ),
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
        _infoRow(Icons.phone_android_rounded, 'Lower Person Phone', mobile.isNotEmpty ? mobile : 'N/A'),
      ],
    );
  }

  Widget _statusChip(bool isPending) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: (isPending ? Colors.orange : Colors.green).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPending ? Icons.pending_actions_rounded : Icons.check_circle_rounded,
            size: 14,
            color: isPending ? Colors.orange : Colors.green,
          ),
          const SizedBox(width: 8),
          Text(
            task.status.toUpperCase(),
            style: TextStyle(
              color: isPending ? Colors.orange : Colors.green,
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
}
