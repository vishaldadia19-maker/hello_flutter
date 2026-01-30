import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hello_flutter/models/lead_model.dart';
import 'package:hello_flutter/utils/user_session.dart';

class LeadService {

  // ✅ FETCH LEADS (UNCHANGED)
  static Future<List<LeadModel>> fetchLeads({    
    required int offset,
    int limit = 10,
    String? reportType,
    String? reportStatus,
  }) async {

    final int bdmId = UserSession.bdmId!;

    final response = await http.post(
      Uri.parse("https://backoffice.thecubeclub.co/apis/lead_listing.php"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "bdm_id": bdmId.toString(),
        "limit": limit,
        "offset": offset,
        "report_type": reportType,
        "report_status": reportStatus,
      }),
    );

    final jsonData = jsonDecode(response.body);

    if (jsonData['status'] == 'success') {
      return (jsonData['data'] as List)
          .map((e) => LeadModel.fromJson(e))
          .toList();
    } else {
      throw Exception("Failed to load leads");
    }
  }

  // ✅ AUTO FOLLOW-UP (MOVED OUT, STATIC)
  static Future<void> autoFollowup({
    required int leadId,
    required String activity,
    required String status,
    required int duration,
  }) async {
    await http.post(
      Uri.parse('https://backoffice.thecubeclub.co/apis/add_followup.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "lead_id": leadId,
        "bdm_id": UserSession.bdmId,
        "call_activity": activity,
        "status": status,
        "call_minutes": duration ~/ 60,
        "call_seconds": duration % 60,
      }),
    );
  }
}