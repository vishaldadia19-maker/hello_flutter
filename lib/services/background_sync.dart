import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:phone_state/phone_state.dart';


void startCallListener() async {
  final prefs = await SharedPreferences.getInstance();

  PhoneState.stream.listen((event) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    if (event.status == PhoneStateStatus.CALL_STARTED) {
      await prefs.setInt("call_start_time", now);
      await prefs.setString("call_number", event.number ?? "");
    }

    print("EVENT: ${event.status} - ${event.number}");

    if (event.status == PhoneStateStatus.CALL_ENDED) {
      final start = prefs.getInt("call_start_time") ?? now;

      if (start == null) return; // ✅ prevent duplicate

      final number = prefs.getString("call_number") ?? "";

      final duration = (now - start) ~/ 1000;

      List<String> logs = prefs.getStringList("call_logs") ?? [];

      logs.add(jsonEncode({
        "number": number,
        "timestamp": start,
        "duration": duration,
        "type": "call",
      }));

      await prefs.setStringList("call_logs", logs);
      await prefs.remove("call_start_time"); // ✅ reset

    }
  });
}





@pragma('vm:entry-point')
Future<void> backgroundSync() async {
  print("🔁 Background Sync Triggered");

  final prefs = await SharedPreferences.getInstance();

  final folderPath = prefs.getString('recording_folder');
  final userId = prefs.getInt('user_id') ?? 0;
  final lastSync = prefs.getInt("last_sync_time") ?? 0;

  if (folderPath == null || userId == 0) {
    print("❌ Missing config");
    return;
  }

  final dir = Directory(folderPath);

  if (!dir.existsSync()) {
    print("❌ Folder does not exist");
    return;
  }

  // =========================
  // 📁 STEP 1: Get Recordings
  // =========================
  final allFiles = dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith(".m4a"))
      .toList();

  final newFiles = allFiles.where((f) {
    return f.lastModifiedSync().millisecondsSinceEpoch > lastSync;
  }).toList();

  print("📁 Found ${newFiles.length} new recordings");

  List<Map<String, dynamic>> recordings = [];

  for (final file in newFiles) {
    final stat = file.statSync();

    recordings.add({
      "path": file.path,
      "file_name": file.uri.pathSegments.last,
      "created": stat.modified.millisecondsSinceEpoch,
      "size": stat.size,
    });
  }

  // =========================
  // 📞 STEP 2: Get Call Logs
  // =========================
  List<Map<String, dynamic>> callLogs = [];

  try {
    final stored = prefs.getStringList("call_logs") ?? [];

    for (var item in stored) {
      callLogs.add(jsonDecode(item));
    }

    print("📞 Found ${callLogs.length} stored call logs");
  } catch (e) {
    print("❌ Error fetching stored logs: $e");
  }


  // =========================
  // 🚀 STEP 3: Send Metadata
  // =========================
  try {

    print("CALL LOGS SENT: $callLogs");


    final response = await http.post(
      Uri.parse('https://backoffice.thecubeclub.co/apis/sync_calls.php'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": userId,
        "device_id": "DEVICE_${userId}",
        "calls": callLogs,
        "recordings": recordings,
      }),
    );

    if (response.statusCode == 200) {
      final resBody = jsonDecode(response.body);

      if (resBody['success'] == true) {
        print("✅ Metadata synced");
        await prefs.remove("call_logs"); // clear sent logs

      } else {
        print("❌ Metadata sync failed");
      }
    }    
    
  } catch (e) {
    print("❌ Metadata error: $e");
  }

  // =========================
  // 📤 STEP 4: Upload Files
  // =========================
  for (final file in newFiles) {
    await Future.delayed(Duration(milliseconds: 500));
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://backoffice.thecubeclub.co/apis/upload_call.php'),
      );

      request.files.add(
        await http.MultipartFile.fromPath('file', file.path),
      );

      request.fields['user_id'] = userId.toString();

      final response = await request.send();
      final body = await response.stream.bytesToString();

      final data = jsonDecode(body);

      if (data['success'] == true) {
        print("✅ Uploaded: ${file.path}");
      } else {
        print("❌ Upload failed: ${file.path}");
      }
    } catch (e) {
      print("❌ Upload error: $e");
    }
  }

  // =========================
  // ⏱ STEP 5: Update Sync Time
  // =========================
  if (newFiles.isNotEmpty || callLogs.isNotEmpty) {
    int latestTime = DateTime.now().millisecondsSinceEpoch;

    await prefs.setInt("last_sync_time", latestTime);

    print("⏱ Sync time updated");
  }

  print("✅ Background Sync Completed");
}

