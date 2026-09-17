import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:iq_plus/features/auth/model/customer_model.dart';
import 'package:iq_plus/features/auth/model/user_model.dart';
import 'package:iq_plus/features/dashboard/page/visit_summary/pages/widgets/visitor_summary_pdf.dart';
import 'package:iq_plus/common/utility/utility.dart';

class BrevoEmailService {
  // 🚀 Firebase Function URL (Option 1: Fixed Backend Proxy)
  // Note: If you changed the region or used v1 functions, adjust this URL accordingly.
  static const String _firebaseProxyUrl =
      'https://us-central1-iq-plush-dc0e6.cloudfunctions.net/triggerBrevoEmail';

  /// 🔹 Basic Email Validation
  static bool _isValidEmail(String email) {
    if (email.isEmpty) return false;
    return !Utility.emailValidationPattern(value: email);
  }

  /// 🔹 Helper to dispatch email via Firebase Cloud Function
  /// This bypasses IP whitelisting issues because the request comes from Google's IP.
  static Future<void> _sendViaFirebase({
    required int templateId,
    required String toEmail,
    required String toName,
    required Map<String, dynamic> params,
    List<Map<String, dynamic>>? attachments,
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
          "templateId": templateId,
          "to": toEmail,
          "toName": toName,
          "params": params,
          if (attachments != null) "attachment": attachments,
        }),
      );

      if (response.statusCode != 200) {
        debugPrint("🔥 Firebase Proxy Error: ${response.body}");
        throw Exception("Failed to dispatch email via backend");
      }
      
      debugPrint("✅ Email template $templateId sent to $toEmail via Firebase");
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
      },
    );
  }

  static Future<void> sendVisitorSummaryMailFromPayload({
    required String toEmail,
    required String toName,
    required CustomerModel? selectedCustomer,
    required UserModel? consultantUserModel,
    required Map<String, dynamic> payload,
    bool isUpdateVisitorSummary = false,
  }) async {
    final int templateId = isUpdateVisitorSummary ? 6 : 4;
    Map<String, dynamic> paramsData = {
      "customerName": selectedCustomer?.companyName,
      "customerEmail": selectedCustomer?.email,
      "consultantName": consultantUserModel?.userName,
      "consultantEmail": consultantUserModel?.email,
      "clientName": payload['clientName'] ?? "",
      "location": payload['location'] ?? '',
      "visitDate": payload['visitDate'] ?? '',
      "fromTime": payload['fromTime'] ?? '',
      "toTime": payload['toTime'] ?? '',
      "purpose": payload['purpose'] ?? '',
      "officerName": payload['officerName'] ?? '',
      "department": payload['department'] ?? '',
      "scopeOfReview": _formatMap(payload['scopeOfReview']),
      "observations": _formatList(payload['observations']),
      "complianceStatus": payload['complianceStatus'] ?? '',
      "complianceComments": payload['complianceComments'] ?? '',
      "nonCompliances": _formatList(payload['nonCompliances']),
      "capas": _formatList(payload['capas']),
      "clientFeedback": payload['clientFeedback'] ?? '',
      "overallAssessment": payload['overallAssessment'] ?? '',
      "signOfficerName": payload['signOff']?['officerName'] ?? '',
      "signOfficerSign": payload['signOff']?['officerSign'] ?? '',
      "signClientName": payload['signOff']?['clientName'] ?? '',
      "signClientSign": payload['signOff']?['clientSign'] ?? '',
      "signDate": payload['signOff']?['signDate'] ?? '',
    };

    final pdfBytes = await VisitorSummaryPdf.generate(
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
}
