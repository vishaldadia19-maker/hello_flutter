import 'dart:io';
import 'package:phone_state/phone_state.dart';
import 'package:call_log/call_log.dart';
import 'package:permission_handler/permission_handler.dart';

class CallTrackerService {
  bool callConnected = false;

  Future<void> init({
    required String phone,
    required Function onNotConnected,
    required Function(int duration) onConnected,
  }) async {

    if (!Platform.isAndroid) return;

    await Permission.phone.request();
    await Permission.callLog.request();

    PhoneState.phoneStateStream.listen((event) async {
      if (event == PhoneStateStatus.CALL_STARTED) {
        callConnected = true;
      }

      if (event == PhoneStateStatus.CALL_ENDED) {
        if (!callConnected) {
          onNotConnected();
        } else {
          int duration = await _getLastCallDuration(phone);
          onConnected(duration);
        }
        callConnected = false;
      }
    });
  }

  Future<int> _getLastCallDuration(String phone) async {
    Iterable<CallLogEntry> logs = await CallLog.get();
    for (var log in logs) {
      if (log.number == phone && log.duration != null) {
        return log.duration!;
      }
    }
    return 0;
  }
}
