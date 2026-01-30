import 'dart:convert';
import 'package:http/http.dart' as http;

class LostReasonService {
  static List<String>? _cachedReasons;

  static Future<List<String>> getReasons() async {
    // ✅ Return cached data if already loaded
    if (_cachedReasons != null) {
      return _cachedReasons!;
    }

    final response = await http.post(
      Uri.parse('https://backoffice.thecubeclub.co/apis/lost_reasons.php'),
      headers: {'Content-Type': 'application/json'},
    );

    final data = jsonDecode(response.body);

    _cachedReasons = List<String>.from(data['data']);
    return _cachedReasons!;
  }
}
