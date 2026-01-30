import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hello_flutter/models/followup_history_model.dart';

class FollowupHistoryApi {
  static Future<List<FollowupHistoryModel>> fetchHistory(int leadId) async {
    final response = await http.post(
      Uri.parse(
        'https://backoffice.thecubeclub.co/apis/lead_followup_history.php',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"lead_id": leadId}),
    );

    final decoded = jsonDecode(response.body);

    final List list = decoded['data'] ?? [];
    return list
        .map((e) => FollowupHistoryModel.fromJson(e))
        .toList();
  }
}
