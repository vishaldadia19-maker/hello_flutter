import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hello_flutter/models/dashboard_model.dart';
import 'package:hello_flutter/utils/user_session.dart';


class DashboardApi {
  static const String apiUrl =
      'https://backoffice.thecubeclub.co/apis/dashboard_summary.php';

  static Future<DashboardModel> fetchDashboard(int bdmId) async {

    //print('Calling dashboard API with bdm_id = $bdmId');

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'bdm_id': bdmId.toString(),
      }),
    );

    //print('Dashboard API raw response: ${response.body}');


    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return DashboardModel.fromJson(jsonData);
    } else {
      throw Exception('Failed to load dashboard data');
    }
  }
}
