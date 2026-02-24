
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/followup_report_model.dart';

class FollowupReportService {
  static const String baseUrl =
      "https://backoffice.thecubeclub.co/apis/follouwp_report_api.php";

  static Future<FollowupReportModel?> fetchReport({
    required int bdmId,
    required String startDate,
    required String endDate,
  }) async {
    try {
      final requestBody = {
        "bdm_id": bdmId,
        "start_date": startDate,
        "end_date": endDate,
      };

      debugPrint("📤 BODY: ${jsonEncode(requestBody)}");

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(requestBody),
      );

      debugPrint("📥 RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData["status"] == true) {
          return FollowupReportModel.fromJson(jsonData);
        }
      }
      return null;
    } catch (e) {
      debugPrint("🔥 ERROR: $e");
      return null;
    }
  }
}
