import 'dart:convert';
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

    /// IMPORTANT:
    /// your API returns:
    /// { region, summary, details }
    return AwsResourcesModel.fromJson(decoded);
  }
}
