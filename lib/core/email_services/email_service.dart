import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:iq_plus/features/auth/model/customer_model.dart';
import 'package:iq_plus/features/auth/model/user_model.dart';
import 'package:iq_plus/features/dashboard/page/visit_summary/pages/widgets/visitor_summary_pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class BrevoEmailService {
  static const String _apiKey =
      'REMOVED_BREVO_KEY';

  static Future<void> sendCustomerCreatedMail({
    required String companyName,
    required String email,
  }) async {
    final int templateId = 2;
    final url = Uri.parse('https://api.brevo.com/v3/smtp/email');

    final response = await http.post(
      url,
      headers: {
        'api-key': _apiKey,
        'Content-Type': 'application/json',
        'accept': 'application/json',
      },
      body: jsonEncode({
        "to": [
          {"email": email, "name": companyName},
        ],
        "templateId": templateId,
        "params": {"companyName": companyName, "email": email},
      }),
    );

    if (response.statusCode != 201) {
      debugPrint("Brevo Email Error: ${response.body}");
      throw Exception("Failed to send email");
    }
  }

  static Future<void> sendCustomerApprovedMail({
    required String companyName,
    required String email,
    required String password,
  }) async {
    final int templateId = 3;
    final url = Uri.parse('https://api.brevo.com/v3/smtp/email');

    final response = await http.post(
      url,
      headers: {
        'api-key': _apiKey,
        'Content-Type': 'application/json',
        'accept': 'application/json',
      },
      body: jsonEncode({
        "to": [
          {"email": email, "name": companyName},
        ],
        "templateId": templateId,
        "params": {
          "companyName": companyName,
          "email": email,
          "password": password,
        },
      }),
    );

    if (response.statusCode != 201) {
      throw Exception("Approval email failed");
    }
  }

  static Future<void> sendVisitorSummaryMailFromPayload({
    required String toEmail,
    required String toName,
    required CustomerModel? selectedCustomer,
    required UserModel? consultantUserModel,
    required Map<String, dynamic> payload,
    bool isUpdateVisitorSummary = false,
  }) async {
    final int templateId = isUpdateVisitorSummary ? 6 : 4; // Brevo template ID
    Map<String, dynamic> paramsData = {
      // ✅ Customer
      "customerName": selectedCustomer?.companyName,
      "customerEmail": selectedCustomer?.email,

      // ✅ Consultant
      "consultantName": consultantUserModel?.userName,
      "consultantEmail": consultantUserModel?.email,

      // Visit Details
      "clientName": payload['clientName'] ?? "",
      "location": payload['location'] ?? '',
      "visitDate": payload['visitDate'] ?? '',
      "fromTime": payload['fromTime'] ?? '',
      "toTime": payload['toTime'] ?? '',
      "purpose": payload['purpose'] ?? '',
      "officerName": payload['officerName'] ?? '',
      "department": payload['department'] ?? '',

      // Sections
      "scopeOfReview": _formatMap(payload['scopeOfReview']),
      "observations": _formatList(payload['observations']),
      "complianceStatus": payload['complianceStatus'] ?? '',
      "complianceComments": payload['complianceComments'] ?? '',
      "nonCompliances": _formatList(payload['nonCompliances']),
      "capas": _formatList(payload['capas']),
      "clientFeedback": payload['clientFeedback'] ?? '',
      "overallAssessment": payload['overallAssessment'] ?? '',

      // Sign Off
      "signOfficerName": payload['signOff']?['officerName'] ?? '',
      "signOfficerSign": payload['signOff']?['officerSign'] ?? '',
      "signClientName": payload['signOff']?['clientName'] ?? '',
      "signClientSign": payload['signOff']?['clientSign'] ?? '',
      "signDate": payload['signOff']?['signDate'] ?? '',
    };

    /// 🔥 Generate PDF
    final pdfBytes = await VisitorSummaryPdf.generate(
      paramsData,
      isUpdated: isUpdateVisitorSummary,
    );

    final response = await http.post(
      Uri.parse('https://api.brevo.com/v3/smtp/email'),
      headers: {
        'api-key': _apiKey,
        'Content-Type': 'application/json',
        'accept': 'application/json',
      },
      body: jsonEncode({
        "templateId": templateId,
        "to": [
          {"email": toEmail, "name": toName},
        ],
        "params": paramsData,
        "attachment": [
          {
            "content": base64Encode(pdfBytes),
            "name": isUpdateVisitorSummary
                ? "Visitor_Summary_Updated.pdf"
                : "Visitor_Summary.pdf",
          },
        ],
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Visitor Summary Email failed: ${response.body}');
    }
  }

  static String _formatMap(Map map) {
    return map.entries.map((e) => "${e.key}: ${e.value}").join('\n');
  }

  static String _formatList(List list) {
    if (list.isEmpty) return 'None';
    return list
        .asMap()
        .entries
        .map((e) {
          final i = e.key + 1;
          final v = e.value as Map;
          return "$i) ${v.entries.map((x) => "${x.key}: ${x.value}").join(', ')}";
        })
        .join('\n');
  }

  static Future<void> sendNextVisitDateAssignedMail({
    required CustomerModel customer,
    required UserModel? consultant,
    required String nextVisitDate,
  }) async {
    const int templateId = 5; // Brevo template ID

    final response = await http.post(
      Uri.parse('https://api.brevo.com/v3/smtp/email'),
      headers: {
        'api-key': _apiKey,
        'Content-Type': 'application/json',
        'accept': 'application/json',
      },
      body: jsonEncode({
        "templateId": templateId,

        /// Send to both customer & consultant
        "to": [
          {"email": customer.email, "name": customer.companyName},
          {"email": consultant?.email, "name": consultant?.userName},
        ],

        "params": {
          // Customer
          "customerName": customer.companyName,
          "customerEmail": customer.email,

          // Consultant
          "consultantName": consultant?.userName,
          "consultantEmail": consultant?.email,

          // Visit Info
          "nextVisitDate": nextVisitDate,
        },
      }),
    );

    if (response.statusCode != 201) {
      debugPrint("Next Visit Date Email Error: ${response.body}");
      throw Exception("Failed to send Next Visit Date email");
    }
  }

  static Future<String> generateVisitorSummaryPdfBase64({
    required Map<String, dynamic> params,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text(
            'Visitor Summary Report',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),

          pw.Text('Company: ${params["customerName"]}'),
          pw.Text('Consultant: ${params["consultantName"]}'),
          pw.SizedBox(height: 10),

          pw.Text('Client Name: ${params["clientName"]}'),
          pw.Text('Location: ${params["location"]}'),
          pw.Text('Visit Date: ${params["visitDate"]}'),
          pw.Text('Time: ${params["fromTime"]} - ${params["toTime"]}'),

          pw.SizedBox(height: 10),
          pw.Text('Scope of Review'),
          pw.Text(params["scopeOfReview"] ?? ''),

          pw.SizedBox(height: 10),
          pw.Text('Observations'),
          pw.Text(params["observations"] ?? ''),

          pw.SizedBox(height: 10),
          pw.Text('Compliance Status: ${params["complianceStatus"]}'),
          pw.Text(params["complianceComments"] ?? ''),
        ],
      ),
    );

    final bytes = await pdf.save();
    return base64Encode(bytes);
  }
}
