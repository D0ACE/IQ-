import 'package:flutter/material.dart';
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
                    _keyValue('Client', model.clientName),
                    _keyValue('Location', model.location),
                    _keyValue('Visit Date', model.visitDate ?? ''),
                    _keyValue('Time', '${model.fromTime} - ${model.toTime}'),
                    _keyValue('Purpose', model.purpose),
                    _keyValue('Officer', model.officerName),
                    _keyValue('Department', model.department),

                    _divider(),

                    _sectionTitle('Scope of Review'),
                    ...model.scopeOfReview.entries.map(
                          (e) => _keyValue(e.key, e.value.toString()),
                    ),

                    _divider(),

                    _sectionTitle('Observations'),
                    ...model.observations.map(
                          (o) => _cardBlock(
                        title: o.process,
                        children: [
                          _keyValue('Observation', o.obs),
                          _keyValue('Severity', o.severity),
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
                        title: 'Gap',
                        children: [
                          _keyValue('Gap', n.gap),
                          _keyValue('Root Cause', n.root),
                          _keyValue('Impact', n.impact),
                        ],
                      ),
                    ),

                    _divider(),

                    _sectionTitle('Corrective Actions (CAPA)'),
                    ...model.capas.map(
                          (c) => _cardBlock(
                        title: c.action,
                        children: [
                          _keyValue('Owner', c.owner),
                          _keyValue('Target Date', c.date ?? ''),
                        ],
                      ),
                    ),

                    _divider(),

                    _sectionTitle('Client Feedback'),
                    Text(model.clientFeedback),

                    const SizedBox(height: 12),

                    _sectionTitle('Overall Assessment'),
                    _statusChip(model.overallAssessment),

                    _divider(),

                    _sectionTitle('Sign Off'),
                    _keyValue('Officer Name', model.signOff.officerName),
                    _keyValue('Officer Signature', model.signOff.officerSign),
                    _keyValue('Client Name', model.signOff.clientName),
                    _keyValue('Client Signature', model.signOff.clientSign),
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
      backgroundColor: color.withOpacity(0.15),
      labelStyle: TextStyle(color: color),
    );
  }
}
