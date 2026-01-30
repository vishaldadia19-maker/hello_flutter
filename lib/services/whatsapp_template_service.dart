import 'dart:convert';
import 'package:http/http.dart' as http;

class WhatsAppTemplateService {
  static List<Map<String, dynamic>>? _cachedTemplates;
  static bool _isFetching = false;

  static Future<List<Map<String, dynamic>>> getTemplates() async {
    // ✅ Return cached data
    if (_cachedTemplates != null) {
      return _cachedTemplates!;
    }

    // 🔒 Prevent parallel calls
    if (_isFetching) {
      while (_cachedTemplates == null) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _cachedTemplates!;
    }

    _isFetching = true;

    try {
      final res = await http.post(
        Uri.parse(
          'https://backoffice.thecubeclub.co/apis/wa_template_list.php',
        ),
      );

      final decoded = jsonDecode(res.body);

      if (decoded['success'] != true || decoded['data'] == null) {
        throw Exception('Invalid template API response');
      }

      // ✅ THIS IS THE KEY FIX
      _cachedTemplates =
          List<Map<String, dynamic>>.from(decoded['data']);

      return _cachedTemplates!;
    } finally {
      _isFetching = false;
    }
  }

  static void clearCache() {
    _cachedTemplates = null;
  }
}
