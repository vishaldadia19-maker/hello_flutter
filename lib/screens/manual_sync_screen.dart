import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import '../utils/user_session.dart';

class ManualSyncScreen extends StatefulWidget {
  const ManualSyncScreen({super.key});

  @override
  State<ManualSyncScreen> createState() => _ManualSyncScreenState();
}

class _ManualSyncScreenState extends State<ManualSyncScreen> {
  String? folderPath;
  int totalFiles = 0;
  int uploadedFiles = 0;
  int skippedFiles = 0;
  int failedFiles = 0;
  bool isSyncing = false;

  int get userId => UserSession.bdmId ?? 0;

  @override
  void initState() {
    super.initState();
    startSync();
  }

  // ✅ PERMISSION
  Future<bool> requestPermission() async {
    var status = await Permission.manageExternalStorage.request();

    if (status.isGranted) {
      print("Permission granted");
      return true;
    } else {
      print("Permission denied");
      return false;
    }
  }

  // ✅ MAIN SYNC
  Future<void> startSync() async {


    final prefs = await SharedPreferences.getInstance();

    //await prefs.remove("last_sync_time");


    bool granted = await requestPermission();
    if (!granted) {
      showMessage("Storage permission required");
      return;
    }

    folderPath = prefs.getString('recording_folder');

    print("DIR : $folderPath");

    if (folderPath == null || folderPath!.isEmpty) {
      showMessage("Folder not configured");
      return;
    }

    if (userId == 0) {
      showMessage("User not logged in");
      return;
    }

    final dir = Directory(folderPath!);

    print("DIR EXISTS: ${dir.existsSync()}");

    if (!dir.existsSync()) {
      showMessage("Folder not found");
      return;
    }

    setState(() {
      isSyncing = true;
      uploadedFiles = 0;
      skippedFiles = 0;
      failedFiles = 0;
    });

    List<File> files = dir
        .listSync(recursive: true)
        .whereType<File>()
        .toList();

    print("RAW LIST LENGTH: ${files.length}");

    for (var item in files) {
      print("ITEM: ${item.path}");
    }

    // ✅ LAST SYNC LOGIC (FIXED)
    final lastSync = prefs.getInt("last_sync_time");

    List<File> targetFiles;

    if (lastSync == null) {
      // First time → upload all
      targetFiles = files;
      print("FIRST SYNC → uploading all files");
    } else {
      targetFiles = files.where((file) {
        final modified =
            file.lastModifiedSync().millisecondsSinceEpoch;
        return modified > lastSync;
      }).toList();
    }

    totalFiles = targetFiles.length;

    print("FILES TO UPLOAD: $totalFiles");

    for (File file in targetFiles) {
      if (!file.existsSync()) {
        print("FILE NOT FOUND: ${file.path}");
        failedFiles++;
        continue;
      }

     


      // ✅ Skip large files (5MB)
      final size = file.lengthSync();
      if (size > 5 * 1024 * 1024) {
        print("SKIPPED (too large): ${file.path}");
        skippedFiles++;
        continue;
      }

      print("UPLOADING: ${file.path}");

      bool success = await uploadFile(file);

      if (success) {
        uploadedFiles++;
      } else {
        failedFiles++;
      }

      setState(() {});
    }

    if (targetFiles.isNotEmpty) {
        final latest = targetFiles
            .map((f) => f.lastModifiedSync().millisecondsSinceEpoch)
            .reduce((a, b) => a > b ? a : b);

        await prefs.setInt("last_sync_time", latest);

        print("UPDATED LAST SYNC: $latest");
      }


    // ✅ Update last sync time

    setState(() {
      isSyncing = false;
    });

    showMessage("Sync completed");
  }

  // ✅ FILE UPLOAD
  Future<bool> uploadFile(File file) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
            'https://backoffice.thecubeclub.co/apis/upload_call.php'),
      );

      request.files.add(
        await http.MultipartFile.fromPath('file', file.path),
      );

      request.fields['user_id'] = userId.toString();

      var response = await request.send();
      var body = await response.stream.bytesToString();

      print("UPLOAD RESPONSE: $body");

      var data = jsonDecode(body);

      return data['success'] == true;

    } catch (e) {
      print("UPLOAD ERROR: $e");
      return false;
    }
  }

  // ✅ MESSAGE
  void showMessage(String msg) {
    Future.delayed(Duration.zero, () {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    });
  }

  // ✅ UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sync Files"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            Text(
              isSyncing ? "Sync in progress..." : "Idle",
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 20),

            LinearProgressIndicator(
              value: totalFiles == 0
                  ? 0
                  : uploadedFiles / totalFiles,
            ),

            const SizedBox(height: 20),

            Text("Total Files: $totalFiles"),
            Text("Uploaded: $uploadedFiles"),
            Text("Skipped (large): $skippedFiles"),
            Text("Failed: $failedFiles"),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: isSyncing ? null : startSync,
              child: const Text("Sync Again"),
            ),
          ],
        ),
      ),
    );
  }
}