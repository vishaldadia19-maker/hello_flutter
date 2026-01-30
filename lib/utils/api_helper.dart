import 'user_session.dart';

class ApiHelper {
  static const String _baseUrl =
      'https://backoffice.thecubeclub.co/apis/';

  static String getUrl(String endpoint) {
    if (UserSession.isVoiceUser) {
      return '$_baseUrl$endpoint?vti=yes';
    }
    return '$_baseUrl$endpoint';
  }
}
