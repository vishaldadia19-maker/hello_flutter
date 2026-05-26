import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/site_visit_summary_model.dart';

class SummaryService {
static const String baseUrl = "https://backoffice.thecubeclub.co/apis";

  static Future<List<SummaryModel>> fetchSummary({
    required String userId,
    String? fromDate,
    String? toDate,
  }) async {
    final uri = Uri.parse(
      "$baseUrl/site_visit_date_summary.php?user_id=$userId"
      "&from_date=${fromDate ?? ''}&to_date=${toDate ?? ''}",
    );

    final res = await http.get(uri);

    final data = json.decode(res.body);

    if (data['success']) {
      return (data['data'] as List)
          .map((e) => SummaryModel.fromJson(e))
          .toList();
    } else {
      throw Exception("Failed to load summary");
    }
  }
}