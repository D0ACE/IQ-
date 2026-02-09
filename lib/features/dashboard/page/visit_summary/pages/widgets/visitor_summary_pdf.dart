import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class VisitorSummaryPdf {
  static Future<Uint8List> generate(Map<String, dynamic> p,
      {bool isUpdated = false}) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(24),
          theme: pw.ThemeData.withFont(
            base: pw.Font.helvetica(),
            bold: pw.Font.helveticaBold(),
          ),
        ),
        build: (context) =>
        [
          _card(
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _title(isUpdated),
                _desc(isUpdated),
                pw.Divider(),

                _sectionTitle('Company Details'),
                _kv('Company Name', p['customerName']),
                _kv('Company Email', p['customerEmail']),

                _sectionTitle('Consultant Details'),
                _kv('Consultant Name', p['consultantName']),
                _kv('Consultant Email', p['consultantEmail']),

                pw.Divider(),

                _sectionTitle('Visit Details'),
                _kv('Client Name', p['clientName']),
                _kv('Location', p['location']),
                _kv('Date of Visit', p['visitDate']),
                _kv('Time', '${p['fromTime']} – ${p['toTime']}'),
                _kv('Purpose', p['purpose']),
                _kv('Compliance Officer', p['officerName']),
                _kv('Department / Process', p['department']),

                pw.Divider(),

                _sectionTitle('Scope of Review'),
                _box(p['scopeOfReview']),

                _sectionTitle('Observations'),
                _box(p['observations']),

                pw.Divider(),

                _sectionTitle('Compliance Status'),
                _kv('Status', p['complianceStatus']),
                pw.Text(p['complianceComments'] ?? ''),

                _sectionTitle('Non-Compliances / Gaps'),
                _box(p['nonCompliances']),

                _sectionTitle('Corrective & Preventive Actions (CAPA)'),
                _box(p['capas']),

                pw.Divider(),

                _sectionTitle('Client Feedback'),
                pw.Text(p['clientFeedback'] ?? ''),

                _sectionTitle('Overall Assessment'),
                pw.Text(p['overallAssessment'] ?? '',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),

                pw.Divider(),

                _sectionTitle('Sign-Off'),
                _kv('Officer Name', p['signOfficerName']),
                _kv('Officer Signature', p['signOfficerSign']),
                pw.SizedBox(height: 8),
                _kv('Client Name', p['signClientName']),
                _kv('Client Signature', p['signClientSign']),
                pw.SizedBox(height: 8),
                _kv('Date', p['signDate']),
              ],
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _title(bool updated) =>
      pw.Text(
        updated
            ? 'Visitor Summary Report (Updated)'
            : 'Visitor Summary Report',
        style: pw.TextStyle(
          fontSize: 22,
          fontWeight: pw.FontWeight.bold,
          color: updated ? PdfColors.orange800 : PdfColor.fromHex('#2E86C1'),
        ),
      );

  static pw.Widget _desc(bool updated) =>
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 8, bottom: 12),
        child: pw.Text(
          updated
              ? 'This report has been updated. Please review the latest visit summary and compliance details.'
              : 'Please review the visit summary and compliance details.',
          style: pw.TextStyle(color: PdfColors.grey700),
        ),
      );

  static pw.Widget _sectionTitle(String t) =>
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 14, bottom: 6),
        child: pw.Text(
          t,
          style: pw.TextStyle(
              fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
      );

  static pw.Widget _kv(String k, String? v) =>
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.RichText(
          text: pw.TextSpan(
            text: '$k: ',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            children: [
              pw.TextSpan(
                  text: v ?? '',
                  style:
                  pw.TextStyle(fontWeight: pw.FontWeight.normal)),
            ],
          ),
        ),
      );

  static pw.Widget _box(String? text) =>
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(10),
        margin: const pw.EdgeInsets.only(bottom: 8),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Text(text ?? ''),
      );

  static pw.Widget _card(pw.Widget child) =>
      pw.Container(
        padding: const pw.EdgeInsets.all(18),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: child,
      );
}
