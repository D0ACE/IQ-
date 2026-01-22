import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:iq_plus/features/auth/model/customer_model.dart';
import 'package:iq_plus/features/auth/model/user_model.dart';

class BrevoEmailService {
  static const String _apiKey = 'REMOVED_BREVO_KEY';

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
          {
            "email": email,
            "name": companyName,
          }
        ],
        "templateId": templateId,
        "params": {
          "companyName": companyName,
          "email": email,
        }
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
          {"email": email, "name": companyName}
        ],
        "templateId": templateId,
        "params": {
          "companyName": companyName,
          "email": email,
          "password": password,
        }
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
  }) async {
    const int templateId = 4; // Brevo template ID
    Map<String, dynamic> paramsData={

      // ✅ Customer
      "customerName": selectedCustomer?.companyName,
      "customerEmail":selectedCustomer?.email ,

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
          {"email": toEmail, "name": toName}
        ],
        "params": paramsData
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
    return list.asMap().entries.map((e) {
      final i = e.key + 1;
      final v = e.value as Map;
      return "$i) ${v.entries.map((x) => "${x.key}: ${x.value}").join(', ')}";
    }).join('\n');
  }
}
