import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:iq_plus/features/auth/model/customer_model.dart';
import 'package:iq_plus/features/auth/model/user_model.dart';
import 'package:iq_plus/features/dashboard/page/visit_summary/pages/widgets/visitor_summary_pdf.dart';
import 'package:iq_plus/common/utility/utility.dart';

class BrevoEmailService {
  static const String _brevoApiKey =
      'REMOVED_BREVO_KEY';
  static const String _brevoApiUrl = 'https://api.brevo.com/v3/smtp/email';
  // 🚀 Firebase Function URL (Option 1: Fixed Backend Proxy)
  // Note: If you changed the region or used v1 functions, adjust this URL accordingly.
  static const String _firebaseProxyUrl =
      'https://us-central1-iq-plush-dc0e6.cloudfunctions.net/triggerBrevoEmail';

  /// 🔹 Basic Email Validation
  static bool _isValidEmail(String email) {
    final clean = email.trim();
    if (clean.isEmpty) return false;
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(clean);
  }

  /// 🔹 Helper to dispatch email via Firebase Cloud Function
  /// This bypasses IP whitelisting issues because the request comes from Google's IP.
  static Future<void> _sendViaFirebase({
    int? templateId,
    required String toEmail,
    required String toName,
    Map<String, dynamic>? params,
    List<Map<String, dynamic>>? attachments,
    String? subject,
    String? htmlContent,
  }) async {
    // 🛑 Validate email before dispatching to prevent backend 400/500 errors
    if (!_isValidEmail(toEmail)) {
      debugPrint("⚠️ Skipping email dispatch: Invalid/Empty email address '$toEmail'");
      return; 
    }

    final url = Uri.parse(_firebaseProxyUrl);

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'accept': 'application/json',
        },
        body: jsonEncode({
          if (templateId != null) "templateId": templateId,
          "to": toEmail,
          "toName": toName,
          if (params != null) "params": params,
          if (attachments != null) "attachment": attachments,
          if (subject != null) "subject": subject,
          if (htmlContent != null) "htmlContent": htmlContent,
        }),
      );

      if (response.statusCode != 200) {
        debugPrint("🔥 Firebase Proxy Error: ${response.body}");
        throw Exception("Failed to dispatch email via backend");
      }
      
      debugPrint("✅ Email (${templateId != null ? 'template $templateId' : 'custom HTML'}) sent to $toEmail via Firebase");
    } catch (e) {
      debugPrint("❌ Email Dispatch Failed: $e");
      rethrow;
    }
  }

  static Future<void> sendCustomerCreatedMail({
    required String companyName,
    required String email,
  }) async {
    await _sendViaFirebase(
      templateId: 2,
      toEmail: email,
      toName: companyName,
      params: {"companyName": companyName, "email": email},
    );
  }

  static Future<void> sendCustomerApprovedMail({
    required String companyName,
    required String email,
    required String password,
  }) async {
    await _sendViaFirebase(
      templateId: 3,
      toEmail: email,
      toName: companyName,
      params: {
        "companyName": companyName,
        "email": email,
        "password": password,
        "loginLink": "https://iq-plush-dc0e6.web.app",
        "url": "https://iq-plush-dc0e6.web.app",
        "link": "https://iq-plush-dc0e6.web.app",
        "loginUrl": "https://iq-plush-dc0e6.web.app",
      },
    );
  }

  static Future<void> sendEmployeeCreatedMail({
    required String userName,
    required String email,
    required String password,
    required String companyName,
  }) async {
    await _sendViaFirebase(
      templateId: 7,
      toEmail: email,
      toName: userName,
      params: {
        "userName": userName,
        "email": email,
        "password": password,
        "companyName": companyName,
        "loginLink": "https://iq-plush-dc0e6.web.app",
        "url": "https://iq-plush-dc0e6.web.app",
        "link": "https://iq-plush-dc0e6.web.app",
        "loginUrl": "https://iq-plush-dc0e6.web.app",
      },
    );
  }

  static Future<Uint8List> generateVisitorSummaryPdfBytes({
    required CustomerModel? selectedCustomer,
    required UserModel? consultantUserModel,
    required Map<String, dynamic> payload,
    bool isUpdateVisitorSummary = false,
  }) async {
    Map<String, dynamic> paramsData = {
      "customerName": selectedCustomer?.companyName,
      "customerEmail": selectedCustomer?.email,
      "consultantName": consultantUserModel?.userName,
      "consultantEmail": consultantUserModel?.email,
      "location": payload['location'] ?? '',
      "visitDate": payload['visitDate'] ?? '',
      "loginTime": payload['loginTime'] ?? payload['fromTime'] ?? '',
      "logoutTime": payload['logoutTime'] ?? payload['toTime'] ?? '',
      "purpose": payload['purpose'] ?? '',
      "consultantCoachName": payload['consultantCoachName'] ?? payload['officerName'] ?? '',
      "department": payload['department'] ?? '',
      "scopeOfReview": _formatScope(payload['scopeOfReview']),
      "observations": _formatList(payload['observations']),
      "complianceStatus": payload['complianceStatus'] ?? '',
      "complianceComments": payload['complianceComments'] ?? '',
      "nonCompliances": _formatNonCompliances(payload['nonCompliances']),
      "capas": _formatCapas(payload['capas']),
      "clientFeedback": payload['clientFeedback'] ?? '',
      "overallAssessment": payload['overallAssessment'] ?? '',
      "signConsultantCoachName": payload['signOff']?['consultantCoachName'] ?? payload['signOff']?['officerName'] ?? '',
      "signOfficerSign": payload['signOff']?['officerSign'] ?? '',
      "signClientName": payload['signOff']?['clientName'] ?? '',
      "signClientSign": payload['signOff']?['clientSign'] ?? '',
      "signDate": payload['signOff']?['signDate'] ?? '',
    };

    return await VisitorSummaryPdf.generate(
      paramsData,
      isUpdated: isUpdateVisitorSummary,
    );
  }

  static Future<void> sendVisitorSummaryMailFromPayload({
    required String toEmail,
    required String toName,
    required CustomerModel? selectedCustomer,
    required UserModel? consultantUserModel,
    required Map<String, dynamic> payload,
    bool isUpdateVisitorSummary = false,
    Uint8List? existingPdfBytes,
  }) async {
    final int templateId = isUpdateVisitorSummary ? 6 : 4;
    Map<String, dynamic> paramsData = {
      "customerName": selectedCustomer?.companyName,
      "customerEmail": selectedCustomer?.email,
      "consultantName": consultantUserModel?.userName,
      "consultantEmail": consultantUserModel?.email,
      "location": payload['location'] ?? '',
      "visitDate": payload['visitDate'] ?? '',
      "loginTime": payload['loginTime'] ?? payload['fromTime'] ?? '',
      "logoutTime": payload['logoutTime'] ?? payload['toTime'] ?? '',
      "purpose": payload['purpose'] ?? '',
      "consultantCoachName": payload['consultantCoachName'] ?? payload['officerName'] ?? '',
      "department": payload['department'] ?? '',
      "scopeOfReview": _formatScope(payload['scopeOfReview']),
      "observations": _formatList(payload['observations']),
      "complianceStatus": payload['complianceStatus'] ?? '',
      "complianceComments": payload['complianceComments'] ?? '',
      "nonCompliances": _formatNonCompliances(payload['nonCompliances']),
      "capas": _formatCapas(payload['capas']),
      "clientFeedback": payload['clientFeedback'] ?? '',
      "overallAssessment": payload['overallAssessment'] ?? '',
      "signConsultantCoachName": payload['signOff']?['consultantCoachName'] ?? payload['signOff']?['officerName'] ?? '',
      "signOfficerSign": payload['signOff']?['officerSign'] ?? '',
      "signClientName": payload['signOff']?['clientName'] ?? '',
      "signClientSign": payload['signOff']?['clientSign'] ?? '',
      "signDate": payload['signOff']?['signDate'] ?? '',
    };

    final pdfBytes = existingPdfBytes ?? await VisitorSummaryPdf.generate(
      paramsData,
      isUpdated: isUpdateVisitorSummary,
    );

    await _sendViaFirebase(
      templateId: templateId,
      toEmail: toEmail,
      toName: toName,
      params: paramsData,
      attachments: [
        {
          "content": base64Encode(pdfBytes),
          "name": isUpdateVisitorSummary
              ? "Visitor_Summary_Updated.pdf"
              : "Visitor_Summary.pdf",
        }
      ],
    );
  }

  static String _formatScope(dynamic scope) {
    if (scope == null) return 'None';
    if (scope is List) {
      if (scope.isEmpty) return 'None';
      return scope.map((e) => "- $e").join('\n');
    }
    if (scope is Map) {
      if (scope.isEmpty) return 'None';
      return scope.keys.map((k) => "- $k").join('\n');
    }
    return scope.toString();
  }

  static String _formatNonCompliances(dynamic list) {
    if (list == null || list is! List || list.isEmpty) return 'None';
    return list.asMap().entries.map((e) {
      final i = e.key + 1;
      final Map item = e.value as Map;
      final gap = item['gap'] ?? '';
      final category = item['category'] ?? item['root'] ?? 'Minor';
      final actionRequired = item['actionRequired'] ?? item['impact'] ?? '';
      final responsible = item['responsible'] ?? '';
      final targetDate = item['targetDate'] ?? '';

      final parts = <String>[];
      if (gap.toString().isNotEmpty) parts.add("Description: $gap");
      if (category.toString().isNotEmpty) parts.add("Category: $category");
      if (actionRequired.toString().isNotEmpty) parts.add("Action Required: $actionRequired");
      if (responsible.toString().isNotEmpty) parts.add("Responsible: $responsible");
      if (targetDate.toString().isNotEmpty) parts.add("Target Date: $targetDate");

      return "$i) ${parts.join(', ')}";
    }).join('\n');
  }

  static String _formatCapas(dynamic list) {
    if (list == null || list is! List || list.isEmpty) return 'None';
    return list.asMap().entries.map((e) {
      final i = e.key + 1;
      final Map item = e.value as Map;
      final action = item['action'] ?? '';
      final rootCause = item['rootCause'] ?? item['owner'] ?? '';
      final date = item['date'] ?? '';
      final actionTakenBy = item['actionTakenBy'] ?? '';
      final evidence = item['evidence'] ?? '';

      final parts = <String>[];
      if (action.toString().isNotEmpty) parts.add("Action Taken: $action");
      if (rootCause.toString().isNotEmpty) parts.add("Root Cause: $rootCause");
      if (date.toString().isNotEmpty) parts.add("Date of Action Taken: $date");
      if (actionTakenBy.toString().isNotEmpty) parts.add("Action Taken By: $actionTakenBy");
      if (evidence.toString().isNotEmpty) parts.add("Evidence: $evidence");

      return "$i) ${parts.join(', ')}";
    }).join('\n');
  }

  static String _formatMap(Map map) {
    return map.entries.map((e) => "${e.key}: ${e.value}").join('\n');
  }

  static String _formatList(List list) {
    if (list.isEmpty) return 'None';
    return list.asMap().entries.map((e) {
      final i = e.key + 1;
      final v = e.value as Map;
      return "$i) ${v.entries.map((x) => "${x.key}: ${x.value}").join(', ')}";
    }).join('\n');
  }

  static Future<void> sendNextVisitDateAssignedMail({
    required CustomerModel customer,
    required UserModel? consultant,
    required String nextVisitDate,
  }) async {
    await _sendViaFirebase(
      templateId: 5,
      toEmail: customer.email,
      toName: customer.companyName,
      params: {
        "customerName": customer.companyName,
        "customerEmail": customer.email,
        "consultantName": consultant?.userName,
        "consultantEmail": consultant?.email,
        "nextVisitDate": nextVisitDate,
      },
    );
    
    // Also notify consultant if email is different
    if (consultant != null && consultant.email != customer.email) {
       await _sendViaFirebase(
        templateId: 5,
        toEmail: consultant.email,
        toName: consultant.userName,
        params: {
          "customerName": customer.companyName,
          "customerEmail": customer.email,
          "consultantName": consultant.userName,
          "consultantEmail": consultant.email,
          "nextVisitDate": nextVisitDate,
        },
      );
    }
  }

  static Future<void> sendPolicyCreatedMail({
    required String customerEmail,
    required String customerName,
    required String policyTitle,
    required String createdBy,
  }) async {
    final String subject = "New Policy & Procedure Created: $policyTitle";
    final String htmlContent = '''
      <html lang="en">
        <body style="font-family: Arial, sans-serif; color: #333; line-height: 1.6;">
          <div style="max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 8px;">
            <h2 style="color: #6c5ce7;">New Policy & Procedure Created</h2>
            <p>Hello <strong>$customerName</strong>,</p>
            <p>A new policy & procedure document <strong>"$policyTitle"</strong> has been created by <strong>$createdBy</strong>.</p>
            <p>Please log in to your IQ + application to view and approve the document.</p>
            <br>
            <p>Best regards,<br><strong>IQ + Team</strong></p>
          </div>
        </body>
      </html>
    ''';

    await _sendViaFirebase(
      toEmail: customerEmail,
      toName: customerName,
      params: {
        "customerName": customerName,
        "policyTitle": policyTitle,
        "createdBy": createdBy,
        "action": "created",
      },
      subject: subject,
      htmlContent: htmlContent,
    );
  }

  static Future<void> sendPolicyUpdatedMail({
    required String customerEmail,
    required String customerName,
    required String policyTitle,
    required String updatedBy,
    required String changeDescription,
  }) async {
    final String subject = "Policy & Procedure Updated: $policyTitle";
    final String htmlContent = '''
      <html lang="en">
        <body style="font-family: Arial, sans-serif; color: #333; line-height: 1.6;">
          <div style="max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 8px;">
            <h2 style="color: #6c5ce7;">Policy & Procedure Updated</h2>
            <p>Hello <strong>$customerName</strong>,</p>
            <p>The policy & procedure document <strong>"$policyTitle"</strong> has been updated by <strong>$updatedBy</strong>.</p>
            <div style="background-color: #f8f9fa; padding: 15px; border-left: 4px solid #6c5ce7; margin: 20px 0;">
              <p style="margin: 0; font-size: 14px;"><strong>Change Description:</strong> $changeDescription</p>
            </div>
            <p>Please log in to your IQ + application to view and approve the document.</p>
            <br>
            <p>Best regards,<br><strong>IQ + Team</strong></p>
          </div>
        </body>
      </html>
    ''';

    await _sendViaFirebase(
      toEmail: customerEmail,
      toName: customerName,
      params: {
        "customerName": customerName,
        "policyTitle": policyTitle,
        "updatedBy": updatedBy,
        "changeDescription": changeDescription,
        "action": "updated",
      },
      subject: subject,
      htmlContent: htmlContent,
    );
  }

  static Future<void> sendVideoAssignedMail({
    required String employeeEmail,
    required String employeeName,
    required String videoTitle,
    String? companyName,
  }) async {
    final String subject = "New Training Assigned: $videoTitle";
    final String htmlContent = '''
      <html lang="en">
        <body style="font-family: Arial, sans-serif; color: #333; line-height: 1.6;">
          <div style="max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 8px;">
            <h2 style="color: #6c5ce7;">New Training Assigned</h2>
            <p>Hello <strong>$employeeName</strong>,</p>
            <p>A new training has been assigned to you on the IQ + portal.</p>
            <div style="background-color: #f8f9fa; padding: 15px; border-left: 4px solid #6c5ce7; margin: 20px 0;">
              <p style="margin: 0; font-size: 16px;"><strong>Video Title:</strong> $videoTitle</p>
              ${companyName != null && companyName.isNotEmpty ? '<p style="margin: 5px 0 0 0; font-size: 14px; color: #666;"><strong>Company:</strong> $companyName</p>' : ''}
            </div>
            <p>Please log in to your IQ + account to watch the video and complete the training.</p>
            <br>
            <p>Best regards,<br><strong>IQ + Team</strong></p>
          </div>
        </body>
      </html>
    ''';

    await _sendViaFirebase(
      toEmail: employeeEmail,
      toName: employeeName,
      params: {
        "userName": employeeName,
        "employeeName": employeeName,
        "videoTitle": videoTitle,
        "companyName": companyName ?? "",
      },
      subject: subject,
      htmlContent: htmlContent,
    );
  }

  static Future<void> sendNcrAssignedMail({
    required String employeeEmail,
    required String employeeName,
    required String companyName,
    required String ncrNo,
    required String process,
    required bool isUpdate,
  }) async {
    final String subject = isUpdate ? "NCR Updated: $ncrNo ($process)" : "New NCR Added: $ncrNo ($process)";
    final String htmlContent = '''
      <html lang="en">
        <body style="font-family: Arial, sans-serif; color: #333; line-height: 1.6;">
          <div style="max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 8px;">
            <h2 style="color: #6c5ce7;">${isUpdate ? "NCR Updated" : "New NCR Added"}</h2>
            <p>Hello <strong>$employeeName</strong>,</p>
            <p>${isUpdate ? "An NCR has been updated" : "A New NCR has been added"}.</p>
            <div style="background-color: #f8f9fa; padding: 15px; border-left: 4px solid #6c5ce7; margin: 20px 0;">
              <p style="margin: 0; font-size: 16px;"><strong>NCR No:</strong> $ncrNo</p>
              <p style="margin: 5px 0 0 0; font-size: 14px; color: #666;"><strong>Process:</strong> $process</p>
              <p style="margin: 5px 0 0 0; font-size: 14px; color: #666;"><strong>Company:</strong> $companyName</p>
            </div>
            <p>Please log in to your IQ + account to view details and take necessary corrective actions.</p>
            <br>
            <p>Best regards,<br><strong>IQ + Team</strong></p>
          </div>
        </body>
      </html>
    ''';

    await _sendViaFirebase(
      toEmail: employeeEmail,
      toName: employeeName,
      params: {
        "userName": employeeName,
        "employeeName": employeeName,
        "companyName": companyName,
        "ncrNo": ncrNo,
        "process": process,
      },
      subject: subject,
      htmlContent: htmlContent,
    );
  }
  static Future<bool> sendAuditResultMail({
    required String auditeeEmail,
    required String auditeeName,
    required String clause,
    required String requirement,
    required String result,
    required String comments,
    required String auditor,
  }) async {
    final cleanEmail = auditeeEmail.trim();
    if (!_isValidEmail(cleanEmail)) {
      debugPrint("⚠️ Skipping email dispatch: Invalid/Empty email address '$cleanEmail'");
      return false;
    }

    final subject = "Audit Report Result: ${clause.isNotEmpty ? clause : 'Requirement'} - $result";
    final htmlContent = '''
      <!DOCTYPE html>
      <html lang="en">
        <head>
          <meta charset="utf-8">
          <style>
            body { font-family: Arial, sans-serif; color: #333; line-height: 1.6; background-color: #f4f6f8; margin: 0; padding: 20px; }
            .container { max-width: 600px; margin: 0 auto; background: #ffffff; padding: 24px; border-radius: 8px; border: 1px solid #e0e0e0; }
            .header { border-bottom: 2px solid #6c5ce7; padding-bottom: 12px; margin-bottom: 20px; }
            .header h2 { color: #2d3436; margin: 0; }
            .badge { display: inline-block; padding: 4px 10px; font-weight: bold; border-radius: 4px; font-size: 13px; }
            .badge-complied { background-color: #e8f5e9; color: #2e7d32; }
            .badge-nc { background-color: #ffebee; color: #c62828; }
            .badge-na { background-color: #eceff1; color: #455a64; }
            .badge-other { background-color: #fff8e1; color: #f57f17; }
            .info-table { width: 100%; border-collapse: collapse; margin: 20px 0; }
            .info-table td { padding: 10px; border-bottom: 1px solid #eee; vertical-align: top; }
            .info-table td.label { font-weight: bold; color: #555; width: 35%; }
            .footer { margin-top: 24px; font-size: 12px; color: #888; border-top: 1px solid #eee; padding-top: 12px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h2>Audit Report Result</h2>
            </div>
            <p>Hello <strong>$auditeeName</strong>,</p>
            <p>An audit item has been evaluated and recorded for your area. Here are the audit details:</p>
            
            <table class="info-table">
              <tr>
                <td class="label">Clause:</td>
                <td><strong>${clause.isNotEmpty ? clause : 'N/A'}</strong></td>
              </tr>
              <tr>
                <td class="label">Requirement:</td>
                <td>$requirement</td>
              </tr>
              <tr>
                <td class="label">Result:</td>
                <td>
                  <span class="badge ${result.toLowerCase().contains('complied') ? 'badge-complied' : (result.toLowerCase().contains('nc') ? 'badge-nc' : (result.toLowerCase().contains('na') ? 'badge-na' : 'badge-other'))}">
                    $result
                  </span>
                </td>
              </tr>
              <tr>
                <td class="label">Comments / Evidence:</td>
                <td>${comments.isNotEmpty ? comments : 'None'}</td>
              </tr>
              <tr>
                <td class="label">Auditor:</td>
                <td>${auditor.isNotEmpty ? auditor : 'N/A'}</td>
              </tr>
            </table>

            <p>Please log in to your IQ + account if any corrective action or review is required.</p>
            
            <div class="footer">
              <p>Best regards,<br><strong>IQ + Audit Team</strong></p>
            </div>
          </div>
        </body>
      </html>
    ''';

    // 1. Try Firebase Proxy first (vital for Flutter Web to avoid browser CORS blocks)
    try {
      await _sendViaFirebase(
        toEmail: cleanEmail,
        toName: auditeeName,
        subject: subject,
        htmlContent: htmlContent,
      );
      debugPrint("✅ Audit email dispatched via Firebase proxy to $cleanEmail");
      return true;
    } catch (e) {
      debugPrint("⚠️ Firebase proxy error: $e. Trying direct Brevo API...");
    }

    // 2. Direct Brevo API fallback (for Mobile/Desktop platforms)
    try {
      final url = Uri.parse(_brevoApiUrl);
      final response = await http.post(
        url,
        headers: {
          'api-key': _brevoApiKey,
          'Content-Type': 'application/json',
          'accept': 'application/json',
        },
        body: jsonEncode({
          "sender": {
            "name": "IQ Plus",
            "email": "iqplusproject@gmail.com",
          },
          "to": [
            {"email": cleanEmail, "name": auditeeName}
          ],
          "subject": subject,
          "htmlContent": htmlContent,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint("✅ Audit email sent directly via Brevo API to $cleanEmail");
        return true;
      } else {
        debugPrint("❌ Direct Brevo API error (${response.statusCode}): ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Direct Brevo API exception: $e");
      return false;
    }
  }
}
