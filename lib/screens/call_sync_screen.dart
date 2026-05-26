import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import '../utils/user_session.dart';

class CallSyncScreen extends StatefulWidget {
  const CallSyncScreen({super.key});

  @override
  State<CallSyncScreen> createState() => _CallSyncScreenState();
}

class _CallSyncScreenState extends State<CallSyncScreen> {
  String? folderPath;
  int totalFiles = 0;
  int uploadedFiles = 0;
  int pendingFiles = 0;
  bool isSyncing = false;

  List<String> uploadedList = [];

  int get userId => UserSession.bdmId ?? 0;

  @override
  void initState() {
    super.initState();
    loadFolder();
  }

  Future<void> loadFolder() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      folderPath = prefs.getString('recording_folder');
      uploadedList = prefs.getStringList('uploaded_files') ?? [];
    });
  }

  Future<void> pickFolder() async {
    String? path = await FilePicker.platform.getDirectoryPath();

    if (path != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('recording_folder', path);

      setState(() {
        folderPath = path;
      });
    }
  }

  Future<bool> requestPermission() async {
    var status = await Permission.manageExternalStorage.request();
    return status.isGranted;
  }

  // ✅ SAVE FOLDER PATH
  Future<void> savePathsToDB() async {
    if (folderPath == null || folderPath!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select folder first")),
      );
      return;
    }

    if (userId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not logged in")),
      );
      return;
    }

    var response = await http.post(
      Uri.parse('https://backoffice.thecubeclub.co/apis/update_recording_path.php'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": userId,
        "file_path": folderPath
      }),
    );

    print("SAVE STATUS: ${response.statusCode}");
    print("SAVE BODY: ${response.body}");

    var data = jsonDecode(response.body);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(data['message'] ?? "Done")),
    );
  }

  // ✅ SYNC FILES
  Future<void> syncFiles() async {
    if (folderPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select folder first")),
      );
      return;
    }

    if (userId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not logged in")),
      );
      return;
    }

    bool granted = await requestPermission();
    if (!granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Storage permission required")),
      );
      return;
    }

    print("FOLDER PATH: $folderPath");

    setState(() {
      isSyncing = true;
      totalFiles = 0;
      uploadedFiles = 0;
      pendingFiles = 0;
    });

    final dir = Directory(folderPath!);

    if (!dir.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Folder not found")),
      );
      return;
    }

    List<File> files = dir
        .listSync(recursive: true)
        .whereType<File>()
        .toList();

    print("TOTAL FILES FOUND: ${files.length}");

    if (files.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No files found in folder")),
      );
    }

    totalFiles = files.length;

    for (File file in files) {
      if (!file.existsSync()) {
        print("FILE NOT FOUND: ${file.path}");
        continue;
      }

      //if (uploadedList.contains(file.path)) continue;

      print("UPLOADING: ${file.path}");

      pendingFiles++;

      bool success = await uploadFile(file);

      if (success) {
        uploadedFiles++;
        uploadedList.add(file.path);
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('uploaded_files', uploadedList);

    setState(() {
      isSyncing = false;
    });
  }

  // ✅ FILE UPLOAD
  Future<bool> uploadFile(File file) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://backoffice.thecubeclub.co/apis/upload_call.php'),
      );

      request.files.add(
        await http.MultipartFile.fromPath('file', file.path),
      );

      request.fields['user_id'] = userId.toString();

      var response = await request.send();
      var body = await response.stream.bytesToString();

      print("UPLOAD STATUS: ${response.statusCode}");
      print("UPLOAD BODY: $body");

      return response.statusCode == 200;

    } catch (e) {
      print("UPLOAD ERROR: $e");
      return false;
    }
  }

  Widget infoCard(String title, int value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 6),
            Text(title),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Call Recording Sync")),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Selected Folder",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(folderPath ?? "No folder selected"),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: pickFolder,
                    child: const Text("Select Folder"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            Row(
              children: [
                infoCard("Total", totalFiles, Colors.blue),
                infoCard("Uploaded", uploadedFiles, Colors.green),
              ],
            ),
            Row(
              children: [
                infoCard("Pending", pendingFiles, Colors.orange),
              ],
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: savePathsToDB,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.grey,
              ),
              child: const Text("Save Paths Only"),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: isSyncing ? null : syncFiles,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Text(isSyncing ? "Syncing..." : "Sync Now"),
            ),
          ],
        ),
      ),
    );
  }
}