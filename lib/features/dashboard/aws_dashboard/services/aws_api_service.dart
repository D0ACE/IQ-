import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../models/aws_resources_model.dart';

class AwsApiService {
  static const String _url =
      "https://listallawsresources-55nvf36tca-uc.a.run.app";

  Future<AwsResourcesModel> fetchAwsResources() async {
    final response = await http.post(
      Uri.parse(_url),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "region": "us-east-1", // N. Virginia
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        "Failed: ${response.statusCode} → ${response.body}",
      );
    }

    final decoded = jsonDecode(response.body);

    /// 2️⃣ Fetch billing from Firestore (latest daily doc)
    final billingSnapshot = await FirebaseFirestore.instance
        .collection('aws_billing_daily')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    final billingData = billingSnapshot.docs.isNotEmpty? billingSnapshot.docs.first.data():null;
    final finalBillingData=billingData?['billing'] ?? [];
    decoded['details']['billing']=finalBillingData;
    /// IMPORTANT:
    /// your API returns:
    /// { region, summary, details }
    return AwsResourcesModel.fromJson(decoded);
  }
}
