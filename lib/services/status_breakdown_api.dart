import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hello_flutter/models/status_breakdown_model.dart';

class StatusBreakdownApi {
  static Future<List<StatusBreakdownModel>> fetchStatusBreakdown(int bdmId) async {
    final response = await http.post(
      Uri.parse('https://backoffice.thecubeclub.co/apis/status_breakdown.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"bdm_id": bdmId}),
    );

    final decoded = jsonDecode(response.body);

    final List list = decoded['data'] ?? [];

    return list
        .map((e) => StatusBreakdownModel.fromJson(e))
        .toList();
  }
}
