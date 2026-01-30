import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  static int? bdmId;
  static String? userName;
  static String? token; // future use
  static bool isVoiceUser = false; // 👈 NEW


  static int? pendingLeadId;
  static const String _keyIsVoiceUser = 'is_voice_user';



  // 🔹 SAVE SESSION (CALL AFTER LOGIN)
  static Future<void> save({
    required int bdmId,
    required String userName,
    required bool isVoiceUser, // 👈 NEW

  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('bdm_id', bdmId);
    await prefs.setString('user_name', userName);
    await prefs.setBool(_keyIsVoiceUser, isVoiceUser);


    UserSession.bdmId = bdmId;
    UserSession.userName = userName;
    UserSession.isVoiceUser = isVoiceUser;

  }

  static Future<void> setPendingLead(int leadId) async {
    pendingLeadId = leadId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('pending_lead_id', leadId);
  }

  static Future<int?> consumePendingLead() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('pending_lead_id');
    if (id != null) {
      await prefs.remove('pending_lead_id');
    }
    pendingLeadId = null;
    return id;
  }


  // 🔹 RESTORE SESSION (CALL ON APP START)
  static Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();

    bdmId = prefs.getInt('bdm_id');
    userName = prefs.getString('user_name');
    isVoiceUser = prefs.getBool(_keyIsVoiceUser) ?? false;


    if (bdmId != null) {
       print(
            '✅ UserSession restored: bdmId=$bdmId, isVoiceUser=$isVoiceUser',
          );
    } else {
      print('⚠️ No saved session found');
    }
  }

  // 🔹 CLEAR SESSION (LOGOUT)
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    bdmId = null;
    userName = null;
    pendingLeadId = null;
    isVoiceUser = false;


  }
}
