import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/site_visit_model.dart';

class SiteVisitService {

  static const String baseUrl = "https://backoffice.thecubeclub.co/apis/";

  static Future<List<SiteVisitModel>> fetchVisits({
    required int page,
    int? userId,
    String? fromDate,
    String? toDate,
  }) async {


    final url =
        "${baseUrl}get_site_visit_list.php?page=$page&limit=20"
        "${userId != null ? "&user_id=$userId" : ""}"
        "${fromDate != null ? "&from_date=$fromDate" : ""}"
        "${toDate != null ? "&to_date=$toDate" : ""}";   



    final res = await http.get(Uri.parse(url));

    final jsonData = json.decode(res.body);

    if (jsonData['success']) {
      return (jsonData['data'] as List)
          .map((e) => SiteVisitModel.fromJson(e))
          .toList();
    } else {
      return [];
    }
  }
  

  static Future<void> deleteVisit(int id) async {

    final res = await http.post(
      Uri.parse("${baseUrl}delete_site_visit.php"),
      body: {
        "id": id.toString(),
      },
    );

    print("DELETE RESPONSE: ${res.body}");

    if (res.body.isEmpty) {
      throw Exception("Empty delete response");
    }

    final data = json.decode(res.body);


    if (!data['success']) {
      throw Exception("Delete failed");
    }
  }
}
