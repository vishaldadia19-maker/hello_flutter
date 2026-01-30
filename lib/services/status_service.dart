import 'dart:convert';
import 'package:http/http.dart' as http;

class StatusService {
  static List<String>? _cachedStatuses;
  static DateTime? _lastFetched;

  static Future<List<String>> getStatuses() async {
    // ✅ Return cached if already loaded
    if (_cachedStatuses != null) {
      return _cachedStatuses!;
    }

    final response = await http.post(
      Uri.parse('https://backoffice.thecubeclub.co/apis/status_list.php'),
      headers: {'Content-Type': 'application/json'},
    );

    final data = jsonDecode(response.body);

    _cachedStatuses = List<String>.from(data['data']);
    _lastFetched = DateTime.now();

    return _cachedStatuses!;
  }

  /// Optional: force refresh (admin use)
  static Future<void> refresh() async {
    _cachedStatuses = null;
    await getStatuses();
  }
}
