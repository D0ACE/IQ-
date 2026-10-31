import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/features/dashboard/page/visit_summary/model/visitor_summary_model.dart';

class VisitorSummaryDetailsDialog extends StatelessWidget {
  final VisitorSummaryModel model;

  const VisitorSummaryDetailsDialog({
    super.key,
    required this.model,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 800,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _header(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Visit Details'),
                    _keyValue('Location', model.location),
                    _keyValue('Visit Date', model.visitDate ?? ''),
                    _keyValue('Login Time', model.loginTime),
                    _keyValue('Logout Time', model.logoutTime),
                    _keyValue('Purpose', model.purpose),
                    _keyValue('Consultant Coach Name', model.consultantCoachName),
                    _keyValue('Department', model.department),

                    _divider(),

                    _sectionTitle('Scope of Review'),
                    if (model.scopeOfReview.isEmpty)
                      const Text('No scope items specified')
                    else
                      for (final item in model.scopeOfReview)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_outline, size: 16, color: AppColors.kPrimaryColor),
                              const SizedBox(width: 8),
                              Expanded(child: Text(item, style: const TextStyle(fontSize: 14))),
                            ],
                          ),
                        ),

                    _divider(),



                    _sectionTitle('Compliance'),
                    _statusChip(model.complianceStatus),
                    _keyValue('Comments', model.complianceComments),

                    _divider(),

                    _sectionTitle('Non-Compliances'),
                    if (model.nonCompliances.isEmpty)
                      const Text('No non-compliances found'),
                    ...model.nonCompliances.map(
                          (n) => _cardBlock(
                        title: 'NC: ${n.gap}',
                        children: [
                          _keyValue('Category of NC', n.category),
                          if (n.actionRequired.isNotEmpty)
                            _keyValue('Action Required', n.actionRequired),
                          if (n.responsible.isNotEmpty)
                            _keyValue('Responsible', n.responsible),
                          if ((n.targetDate ?? '').isNotEmpty)
                            _keyValue('Target Date', n.targetDate!),
                        ],
                      ),
                    ),

                    _divider(),

                    _sectionTitle('Corrective Actions (CAPA)'),
                    ...model.capas.map(
                          (c) => _cardBlock(
                        title: 'Action Taken: ${c.action}',
                        children: [
                          _keyValue('Root Cause', c.rootCause),
                          _keyValue('Date of Action Taken', c.date ?? ''),
                          if (c.actionTakenBy.isNotEmpty)
                            _keyValue('Action Taken By', c.actionTakenBy),
                          if (c.evidence.isNotEmpty)
                            _evidenceWidget('Supporting Evidence', c.evidence),
                        ],
                      ),
                    ),

                    _divider(),

                    _sectionTitle('Client Feedback'),
                    Text(model.clientFeedback),

                    _divider(),

                    _sectionTitle('Sign Off'),
                    _keyValue('Consultant Coach Name', model.signOff.consultantCoachName.isNotEmpty ? model.signOff.consultantCoachName : model.consultantCoachName),
                    _keyValue('Client Name', model.signOff.clientName),
                    _keyValue('Signed On', model.signOff.signDate ?? ''),
                  ],
                ),
              ),
            ),
            _footer(context),
          ],
        ),
      ),
    );
  }

  // ===================== UI Helpers =====================

  Widget _header(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.kPrimaryColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Visitor Summary Details',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _footer(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Align(
        alignment: Alignment.centerRight,
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _keyValue(String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              key,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _evidenceWidget(String key, String evidence) {
    final bool isUrl = evidence.startsWith('http://') || evidence.startsWith('https://');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              key,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () async {
                final Uri? uri = Uri.tryParse(evidence);
                if (uri != null) {
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    await launchUrl(uri);
                  }
                }
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isUrl ? Icons.download : Icons.attach_file,
                    size: 18,
                    color: AppColors.kPrimaryColor,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      evidence,
                      style: TextStyle(
                        color: isUrl ? AppColors.kPrimaryColor : Colors.black87,
                        decoration: isUrl ? TextDecoration.underline : TextDecoration.none,
                        fontWeight: isUrl ? FontWeight.w600 : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.kPrimaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.file_download, size: 14, color: AppColors.kPrimaryColor),
                        SizedBox(width: 4),
                        Text(
                          'Download / Open',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.kPrimaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Padding(
    padding: EdgeInsets.symmetric(vertical: 12),
    child: Divider(),
  );

  Widget _cardBlock({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'satisfactory':
      case 'compliant':
        color = Colors.green;
        break;
      case 'partially compliant':
        color = Colors.orange;
        break;
      default:
        color = Colors.red;
    }

    return Chip(
      label: Text(status),
      backgroundColor: color.withValues(alpha:0.15),
      labelStyle: TextStyle(color: color),
    );
  }
}
